import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/budgets/budget_form_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late Future<List<BudgetSpending>> _future;
  int _lastVersion = -1;

  Future<List<BudgetSpending>> _load() => AppRepository.instance.getBudgetSpendings();

  void _reload() {
    setState(() {
      _future = _load();
    });
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
        title: const Text('Budgets'),
        actions: [
          IconButton(
            tooltip: 'Add budget',
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetFormScreen()));
              _reload();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<BudgetSpending>>(
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
                icon: Icons.pie_chart_outline,
                title: 'No budgets yet',
                message: 'Create a budget for a category to track your spending and avoid surprises.',
                action: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetFormScreen()));
                    _reload();
                  },
                  child: const Text('Create Budget'),
                ),
              );
            }

            var totalLimit = 0.0;
            var totalSpent = 0.0;
            for (final bs in list) {
              totalLimit += bs.budget.effectiveLimit;
              totalSpent += bs.spent;
            }
            final currency = context.watch<AppState>().currencyCode;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total budget', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(formatMoney(totalSpent, currency), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('of ${formatMoney(totalLimit, currency)}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text('${totalLimit <= 0 ? 0 : (totalSpent / totalLimit * 100).clamp(0, 999).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                ],
                              ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ProgressBar(fraction: totalLimit <= 0 ? 0 : totalSpent / totalLimit, color: AppColors.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...list.map((bs) {
                  return _BudgetCard(
                    spending: bs,
                    currency: currency,
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => BudgetFormScreen(budget: bs.budget)));
                      _reload();
                    },
                    onDelete: () async {
                      final ok = await _confirmDelete(bs.budget.categoryName ?? 'budget');
                      if (ok == true) {
                        await AppRepository.instance.deleteBudget(bs.budget.id!);
                        context.read<AppState>().bumpData();
                        _reload();
                      }
                    },
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete budget'),
        content: Text('Delete the budget for "$name"?'),
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

class _BudgetCard extends StatelessWidget {
  final BudgetSpending spending;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BudgetCard({required this.spending, required this.currency, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final b = spending.budget;
    final effective = b.effectiveLimit;
    final percent = effective <= 0 ? 0.0 : spending.spent / effective * 100;
    final exceeded = percent >= 100;
    final color = exceeded ? AppColors.danger : (percent > 80 ? AppColors.warning : AppColors.primary);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              CategoryAvatar(name: b.categoryName, color: b.categoryColor, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.categoryName ?? 'Category', style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      '${frequencyLabel(b.period)} · ${_periodLabel(b)}',
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
                    Text(formatMoney(spending.spent, currency), style: const TextStyle(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      'of ${formatMoney(effective, currency)}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 20,
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.danger), SizedBox(width: 8), Text('Delete')])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ProgressBar(fraction: (percent / 100).clamp(0.0, 1.0), color: color)),
              const SizedBox(width: 10),
              Text('${percent.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
            ],
          ),
          if (b.carryoverEnabled && b.carryoverAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.forward, size: 14, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text('Included ${formatMoney(b.carryoverAmount, currency)} carryover', style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _periodLabel(Budget b) {
    if (b.period == 'yearly') return '${b.year}';
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${b.month != null ? names[b.month! - 1] : ''} ${b.year}';
  }
}