import 'package:flutter/material.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  int _tab = 0;
  List<Expense> _trashedExpenses = [];
  List<Income> _trashedIncomes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = AppRepository.instance;
    final exps = await repo.getExpenses(withTrashed: true);
    final incs = await repo.getIncomes(withTrashed: true);
    if (!mounted) return;
    setState(() {
      _trashedExpenses = exps;
      _trashedIncomes = incs;
      _loading = false;
    });
  }

  Future<void> _restoreExpense(Expense e) async {
    await AppRepository.instance.restoreExpense(e.id!);
    _load();
  }

  Future<void> _forceExpense(Expense e) async {
    final ok = await _confirm('Permanently delete "${e.description}"? This cannot be undone.');
    if (ok) {
      await AppRepository.instance.forceDeleteExpense(e.id!);
      _load();
    }
  }

  Future<void> _restoreIncome(Income i) async {
    await AppRepository.instance.restoreIncome(i.id!);
    _load();
  }

  Future<void> _forceIncome(Income i) async {
    final ok = await _confirm('Permanently delete income "${i.source}"? This cannot be undone.');
    if (ok) {
      await AppRepository.instance.forceDeleteIncome(i.id!);
      _load();
    }
  }

  Future<bool> _confirm(String msg) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(msg),
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
    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trash')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  height: 30,
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : const Color(0xFFECEEF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Tab(label: 'Expenses (${_trashedExpenses.length})', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                      ),
                      Expanded(
                        child: _Tab(label: 'Income (${_trashedIncomes.length})', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _tab == 0
                      ? _buildExpenses()
                      : _buildIncomes(),
                ),
              ],
            ),
    );
  }

  Widget _buildExpenses() {
    if (_trashedExpenses.isEmpty) {
      return const EmptyState(icon: Icons.delete_sweep_outlined, title: 'Trash is empty', message: 'Deleted expenses will appear here so you can restore them.');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _trashedExpenses.length,
      itemBuilder: (context, i) {
        final e = _trashedExpenses[i];
        return AppCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CategoryAvatar(name: e.categoryName, color: e.categoryColor, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.description, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(e.categoryName ?? 'Uncategorized', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Restore',
                icon: const Icon(Icons.settings_backup_restore, color: AppColors.primary),
                onPressed: () => _restoreExpense(e),
              ),
              IconButton(
                tooltip: 'Delete forever',
                icon: const Icon(Icons.delete_forever, color: AppColors.danger),
                onPressed: () => _forceExpense(e),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomes() {
    if (_trashedIncomes.isEmpty) {
      return const EmptyState(icon: Icons.delete_sweep_outlined, title: 'Trash is empty', message: 'Deleted income will appear here so you can restore them.');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _trashedIncomes.length,
      itemBuilder: (context, i) {
        final inc = _trashedIncomes[i];
        return AppCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CategoryAvatar(name: 'income', size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inc.source, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(inc.notes.isNotEmpty ? inc.notes : inc.paymentMethod, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Restore',
                icon: const Icon(Icons.settings_backup_restore, color: AppColors.primary),
                onPressed: () => _restoreIncome(inc),
              ),
              IconButton(
                tooltip: 'Delete forever',
                icon: const Icon(Icons.delete_forever, color: AppColors.danger),
                onPressed: () => _forceIncome(inc),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : Theme.of(context).textTheme.bodySmall!.color,
          ),
        ),
      ),
    );
  }
}