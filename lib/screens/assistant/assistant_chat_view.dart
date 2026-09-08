import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/services/assistant_service.dart';

/// Self-contained chat body for the TrackMe assistant. Used both as the full
/// assistant page body and inside the floating chat panel.
class AssistantChatView extends StatefulWidget {
  const AssistantChatView({super.key});

  @override
  State<AssistantChatView> createState() => AssistantChatViewState();
}

class AssistantChatViewState extends State<AssistantChatView> {
  static final DateFormat _dayFormat = DateFormat('EEE, MMM d');

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  AssistantDraft? _pendingDraft;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final messages = await AppRepository.instance.getChatMessages();
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _loading = false;
    });
    _scrollToBottom();
  }

  /// Reloads the persisted conversation (used after clearing the chat).
  Future<void> reload() => _load();

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    _inputController.clear();
    await _handleUserMessage(text);
  }

  Future<void> _handleUserMessage(String text) async {
    final appState = context.read<AppState>();
    setState(() => _sending = true);
    final repo = AppRepository.instance;
    final user = await repo.getUser();
    final service = AssistantService(salaryDay: user.salaryDay);

    await repo.addChatMessage(role: 'user', text: text);

    String? payload;
    String kind = 'text';
    String reply;

    if (_isConfirmation(text) && _pendingDraft != null) {
      final draft = _pendingDraft;
      _pendingDraft = null;
      if (draft == null) {
        reply = 'Nothing to confirm. Try "I paid 100 pesos for food".';
      } else {
        try {
          final logged = await _logDraft(repo, draft, user.preferredCurrency);
          payload = jsonEncode(logged);
          kind = draft.type;
          reply =
              'Saved. I logged ${draft.type == 'expense' ? 'expense' : 'income'} of ${formatMoney(draft.amount, user.preferredCurrency)} — "${draft.description}". Tap Undo to remove it.';
          appState.bumpData();
        } catch (e) {
          reply = 'I couldn\'t save that. Please try again.';
        }
      }
    } else {
      final intent = service.respond(text);
      kind = intent.kind;
      reply = intent.reply;
      if (intent.autoPost && intent.draft != null) {
        try {
          final logged =
              await _logDraft(repo, intent.draft!, user.preferredCurrency);
          payload = jsonEncode(logged);
          appState.bumpData();
        } catch (e) {
          kind = 'text';
          reply =
              'I understood your intent but couldn\'t save it. Make sure you have at least one category set up (Settings > Categories), then try again.';
        }
      } else if (intent.draft != null) {
        _pendingDraft = intent.draft;
      }
    }

    await repo.addChatMessage(
        role: 'assistant', kind: kind, text: reply, payload: payload);
    final messages = await repo.getChatMessages();
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _sending = false;
    });
    _scrollToBottom();
  }

  bool _isConfirmation(String text) {
    final lower = text.trim().toLowerCase();
    return RegExp(r'^(yes|yeah|yep|ok|okay|sige|oo|go|sure)\b').hasMatch(lower);
  }

  Future<Map<String, dynamic>> _logDraft(
      AppRepository repo, AssistantDraft draft, String currencyCode) async {
    final dateStr =
        '${draft.date.year.toString().padLeft(4, '0')}-${draft.date.month.toString().padLeft(2, '0')}-${draft.date.day.toString().padLeft(2, '0')}';

    if (draft.type == 'income') {
      final income = await repo.saveIncome(
        source: draft.description,
        amount: draft.amount,
        incomeDate: dateStr,
        notes: 'Added via TrackMe Assistant',
        paymentMethod: draft.paymentMethod ?? 'bank_transfer',
        currencyCode: currencyCode,
        ignoreDuplicate: true,
      );
      await repo.addNotification(
        type: 'assistant',
        title: 'TrackMe Assistant',
        body:
            'Logged income ${formatMoney(draft.amount, currencyCode)} — ${draft.description}',
      );
      await repo.logActivity('assistant',
          "Assistant logged income '$draft.description' ($currencyCode ${draft.amount.toStringAsFixed(2)})");
      return {
        'id': income.id,
        'type': 'income',
        'amount': draft.amount,
        'description': draft.description
      };
    }

    int? categoryId;
    if (draft.categoryKeyword.isNotEmpty) {
      final byName = await repo.getCategoryByName(draft.categoryKeyword);
      categoryId = byName?.id;
    }
    categoryId ??= await repo.autoCategorize(draft.description);
    if (categoryId == null) {
      final categories = await repo.getCategories();
      if (categories.isEmpty) throw Exception('No categories found');
      categoryId = categories.first.id;
    }
    if (categoryId == null) throw Exception('No categories found');

    final result = await repo.saveExpense(
      categoryId: categoryId,
      description: draft.description,
      amount: draft.amount,
      expenseDate: dateStr,
      notes: 'Added via TrackMe Assistant',
      paymentMethod: draft.paymentMethod ?? 'cash',
      currencyCode: currencyCode,
      ignoreDuplicate: true,
    );
    await repo.addNotification(
      type: 'assistant',
      title: 'TrackMe Assistant',
      body:
          'Logged expense ${formatMoney(draft.amount, currencyCode)} — ${draft.description}',
    );
    await repo.logActivity('assistant',
        "Assistant logged expense '$draft.description' ($currencyCode ${draft.amount.toStringAsFixed(2)})");
    return {
      'id': result.expense.id,
      'type': 'expense',
      'amount': draft.amount,
      'description': draft.description
    };
  }

  Future<void> _handleUndo(ChatMessage message) async {
    final appState = context.read<AppState>();
    final payload = message.payload;
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final id = (data['id'] as num).toInt();
      final type = data['type'] as String? ?? 'expense';
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final description = data['description'] as String? ?? '';
      final repo = AppRepository.instance;
      if (type == 'income') {
        await repo.forceDeleteIncome(id);
      } else {
        await repo.forceDeleteExpense(id);
      }
      await repo.addNotification(
        type: 'assistant',
        title: 'TrackMe Assistant',
        body: '$description (${amount.toStringAsFixed(2)}) was removed.',
      );
      await repo.logActivity(
          'assistant', "Assistant undid $type '$description'");
      await repo.addChatMessage(
        role: 'assistant',
        kind: type,
        text:
            'Done! I removed "$description" (${formatMoney(amount, await _currency())}). Anything else?',
      );
      appState.bumpData();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not undo: $e')));
    }
  }

  Future<String> _currency() async {
    final user = await AppRepository.instance.getUser();
    return user.preferredCurrency;
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Today';
    if (today.difference(day).inDays == 1) return 'Yesterday';
    return _dayFormat.format(day);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  List<Widget> _buildMessageItems() {
    final items = <Widget>[];
    DateTime? lastDay;
    for (final m in _messages) {
      final dt = DateTime.tryParse(m.createdAt);
      if (dt != null) {
        final day = DateTime(dt.year, dt.month, dt.day);
        if (day != lastDay) {
          items.add(_DayDivider(label: _dayLabel(day)));
          lastDay = day;
        }
      }
      items.add(_MessageBubble(message: m, onUndo: () => _handleUndo(m)));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildMessageItems();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: items.length,
                      itemBuilder: (context, i) => items[i],
                    ),
        ),
        if (_sending)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('tracking…',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall!.color)),
            ),
          ),
        _buildInputBar(context),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    void suggest(String text) {
      _handleUserMessage(text);
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.brandGradient),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_outlined,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(height: 18),
            Text('Hello! I can add your spendings for you.',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Just chat to me like a support agent:\n"I paid 100 pesos for food" — and I will log it automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Theme.of(context).textTheme.bodySmall!.color),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _SuggestionChip(
                    text: 'I paid 100 pesos for food',
                    onTap: () => suggest('I paid 100 pesos for food')),
                _SuggestionChip(
                    text: 'Bought groceries ₱500 via gcash',
                    onTap: () => suggest('Bought groceries ₱500 via gcash')),
                _SuggestionChip(
                    text: 'I received my salary 25000',
                    onTap: () => suggest('I received my salary 25000')),
                _SuggestionChip(text: 'Help', onTap: () => suggest('Help')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'e.g. "I paid 100 for food"…',
                isDense: true,
                filled: true,
                prefixIcon: Icon(Icons.chat_bubble_outline, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  final String label;
  const _DayDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark2
                : const Color(0xFFE9EBF2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodySmall!.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      onPressed: onTap,
      labelStyle: const TextStyle(fontSize: 12.5),
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onUndo;
  static final DateFormat _timeFormat = DateFormat.jm();

  const _MessageBubble({required this.message, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isPost =
        !isUser && (message.kind == 'expense' || message.kind == 'income');
    final time = _timeOfDay(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.brandGradient),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_outlined,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : Theme.of(context).brightness == Brightness.dark
                        ? AppColors.surfaceDark2
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF262C38)
                            : const Color(0xFFE8EAF1),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: isUser
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  if (isPost) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: onUndo,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.undo,
                                    size: 14, color: AppColors.danger),
                                SizedBox(width: 5),
                                Text('Undo',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.danger)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            time.isEmpty ? 'Added just now' : 'Added · $time',
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ] else if (time.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: (isUser
                                    ? Colors.white
                                    : Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color ??
                                        Colors.grey)
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeOfDay(String iso) {
    final dt = DateTime.tryParse(iso);
    return dt != null ? _timeFormat.format(dt) : '';
  }
}
