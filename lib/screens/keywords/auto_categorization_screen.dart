import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';

class AutoCategorizationScreen extends StatefulWidget {
  const AutoCategorizationScreen({super.key});

  @override
  State<AutoCategorizationScreen> createState() => _AutoCategorizationScreenState();
}

class _AutoCategorizationScreenState extends State<AutoCategorizationScreen> {
  late Future<List<CategoryKeyword>> _future;
  int _lastVersion = -1;

  Future<List<CategoryKeyword>> _load() => AppRepository.instance.getKeywords();

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _addKeyword() async {
    final categories = await AppRepository.instance.getCategories();
    if (categories.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create some categories first.')));
      }
      return;
    }
    if (mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _AddKeywordSheet(categories: categories, onAdded: () {
          context.read<AppState>().bumpData();
          _reload();
        }),
      );
    }
  }

  Future<void> _setupDefaults() async {
    await AppRepository.instance.setupDefaultKeywords();
    context.read<AppState>().bumpData();
    _reload();
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
        title: const Text('Auto-categorization'),
        actions: [
          IconButton(tooltip: 'Add keyword', onPressed: _addKeyword, icon: const Icon(Icons.add)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Matching keywords suggest a category automatically when you type a description.',
                    style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall!.color),
                  ),
                ),
                OutlinedButton(
                  onPressed: _setupDefaults,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14)),
                  child: const Text('Set up defaults'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CategoryKeyword>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final keywords = snapshot.data ?? [];
                if (keywords.isEmpty) {
                  return EmptyState(
                    icon: Icons.auto_awesome,
                    title: 'No keywords yet',
                    message: 'Add keywords like "restaurant", "grocery" or "netflix" to auto-assign categories.',
                  );
                }

                final grouped = <String, List<CategoryKeyword>>{};
                for (final k in keywords) {
                  final key = k.categoryName ?? 'Uncategorized';
                  grouped.putIfAbsent(key, () => []).add(k);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    for (final entry in grouped.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key, style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 6),
                              for (final k in entry.value)
                                _KeywordRow(
                                  keyword: k,
                                  onPriority: (p) {
                                    AppRepository.instance.updateKeyword(k.id!, p);
                                    context.read<AppState>().bumpData();
                                    _reload();
                                  },
                                  onDelete: () async {
                                    await AppRepository.instance.removeKeyword(k.id!);
                                    context.read<AppState>().bumpData();
                                    _reload();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordRow extends StatefulWidget {
  final CategoryKeyword keyword;
  final ValueChanged<int> onPriority;
  final VoidCallback onDelete;
  const _KeywordRow({required this.keyword, required this.onPriority, required this.onDelete});

  @override
  State<_KeywordRow> createState() => _KeywordRowState();
}

class _KeywordRowState extends State<_KeywordRow> {
  late int _priority;

  @override
  void initState() {
    super.initState();
    _priority = widget.keyword.priority;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(child: Text(widget.keyword.keyword, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Pill('x$_priority', AppColors.accent),
            ],
          ),
        ),
        PopupMenuButton<int>(
          padding: EdgeInsets.zero,
          iconSize: 20,
          tooltip: 'Priority',
          onSelected: (v) {
            setState(() => _priority = v);
            widget.onPriority(v);
          },
          itemBuilder: (_) => [
            for (var p = 10; p >= 1; p--)
              PopupMenuItem(value: p, child: Text('Priority $p')),
          ],
        ),
        IconButton(
          tooltip: 'Remove',
          padding: EdgeInsets.zero,
          iconSize: 20,
          icon: const Icon(Icons.close, color: AppColors.danger),
          onPressed: widget.onDelete,
        ),
      ],
    );
  }
}

class _AddKeywordSheet extends StatefulWidget {
  final List<Category> categories;
  final VoidCallback onAdded;
  const _AddKeywordSheet({required this.categories, required this.onAdded});

  @override
  State<_AddKeywordSheet> createState() => _AddKeywordSheetState();
}

class _AddKeywordSheetState extends State<_AddKeywordSheet> {
  final _controller = TextEditingController();
  int? _categoryId;
  int _priority = 5;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categories.isNotEmpty ? widget.categories.first.id : null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final keyword = _controller.text.trim().toLowerCase();
    if (keyword.isEmpty || _categoryId == null) return;
    await AppRepository.instance.addKeyword(_categoryId!, keyword, priority: _priority);
    widget.onAdded();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 16),
            Text('Add keyword', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'keyword e.g. restaurant'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int?>(
              value: _categoryId,
              isExpanded: true,
              items: [
                for (final c in widget.categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        CategoryAvatar(name: c.name, color: c.color, size: 24),
                        const SizedBox(width: 10),
                        Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
              decoration: const InputDecoration(hintText: 'Category'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Priority: $_priority', style: const TextStyle(fontSize: 13.5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _priority.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$_priority',
                    onChanged: (v) => setState(() => _priority = v.round()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _save, child: const Text('Add Keyword')),
          ],
        ),
      ),
      ),
    );
  }
}