import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/recurring/recurring_form_screen.dart';

class RecurringListScreen extends StatefulWidget {
  const RecurringListScreen({super.key});

  @override
  State<RecurringListScreen> createState() => _RecurringListScreenState();
}

class _RecurringListScreenState extends State<RecurringListScreen> {
  late Future<List<RecurringTransaction>> _future;
  int _lastVersion = -1;
  String _status = 'all';
  bool _generating = false;

  Future<List<RecurringTransaction>> _load() async {
    final list = await AppRepository.instance.getRecurringTransactions();
    if (_status == 'all') return list;
    return list.where((r) => r.status == _status).toList();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _generateDue() async {
    setState(() => _generating = true);
    final due = await AppRepository.instance.generateDueRecurring();
    context.read<AppState>().bumpData();
    if (mounted) {
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(due.isEmpty
            ? 'No recurring transactions are due right now.'
            : 'Created ${due.length} expense(s) from recurring transactions.'),
      ));
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = context.watch<AppState>().dataVersion;
    if (_lastVersion != version) {
      _lastVersion = version;
      _future = _load();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        actions: [
          IconButton(
            tooltip: 'Add recurring',
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecurringFormScreen()));
              _reload();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _generating ? null : _generateDue,
                      icon: _generating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.playlist_add_check, size: 20),
                      label: const Text('Generate due'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'paused', child: Text('Paused')),
                  ],
                  onChanged: (v) {
                    setState(() => _status = v ?? 'all');
                    _reload();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<RecurringTransaction>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.autorenew,
                    title: 'No recurring transactions',
                    message: 'Set up bills or subscriptions that repeat automatically.',
                    action: ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecurringFormScreen()));
                        _reload();
                      },
                      child: const Text('Add Recurring'),
                    ),
                  );
                }
                final currency = context.watch<AppState>().currencyCode;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _RecurringCard(
                    recurring: list[i],
                    currency: currency,
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecurringFormScreen(recurring: list[i])));
                      _reload();
                    },
                    onToggle: () async {
                      final r = list[i];
                      if (r.status == 'active') {
                        await AppRepository.instance.pauseRecurring(r.id!);
                      } else if (r.status == 'paused') {
                        await AppRepository.instance.resumeRecurring(r.id!);
                      }
                      context.read<AppState>().bumpData();
                      _reload();
                    },
                    onDelete: () async {
                      final ok = await _confirmDelete(list[i].description);
                      if (ok == true) {
                        await AppRepository.instance.deleteRecurring(list[i].id!);
                        context.read<AppState>().bumpData();
                        _reload();
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(String description) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recurring'),
        content: Text('Delete "$description"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  final RecurringTransaction recurring;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _RecurringCard({
    required this.recurring,
    required this.currency,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final r = recurring;
    final statusColor = r.status == 'active' ? AppColors.income : (r.status == 'paused' ? AppColors.warning : AppColors.textSecondaryDark);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          CategoryAvatar(name: r.categoryName, color: r.categoryColor, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.description, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  '${frequencyLabel(r.frequency)} · next ${formatDateShort(r.nextDueDate)}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('-${formatMoney(r.amount, currency)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.expense, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Pill(
                  r.status == 'active' ? 'Active' : (r.status == 'paused' ? 'Paused' : 'Done'),
                  statusColor,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            iconSize: 20,
            onSelected: (v) {
              if (v == 'toggle') onToggle();
              if (v == 'edit') onTap();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              if (r.status == 'active')
                const PopupMenuItem(value: 'toggle', child: Row(children: [Icon(Icons.pause_outlined, size: 18), SizedBox(width: 8), Text('Pause')]))
              else if (r.status == 'paused')
                const PopupMenuItem(value: 'toggle', child: Row(children: [Icon(Icons.play_arrow_outlined, size: 18), SizedBox(width: 8), Text('Resume')])),
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.danger), SizedBox(width: 8), Text('Delete')])),
            ],
          ),
        ],
      ),
    );
  }
}