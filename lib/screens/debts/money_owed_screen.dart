import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/debts/debt_form_sheet.dart';
import 'package:track_me/screens/debts/debt_payment_sheet.dart';

class MoneyOwedScreen extends StatefulWidget {
  const MoneyOwedScreen({super.key});

  @override
  State<MoneyOwedScreen> createState() => _MoneyOwedScreenState();
}

class _MoneyOwedScreenState extends State<MoneyOwedScreen> {
  List<Debt> _debts = [];
  Map<String, double> _totals = {};
  bool _loading = true;
  String _direction = 'owed_to_me';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = AppRepository.instance;
    final debts = await repo.getDebts();
    final totals = await repo.debtTotals();
    if (!mounted) return;
    setState(() {
      _debts = debts;
      _totals = totals;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DebtFormSheet(initialDirection: _direction),
    );
    if (created == true) {
      context.read<AppState>().bumpData();
      await _load();
    }
  }

  Future<void> _edit(Debt debt) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DebtFormSheet(debt: debt),
    );
    if (changed == true) {
      context.read<AppState>().bumpData();
      await _load();
    }
  }

  Future<void> _recordPayment(Debt debt) async {
    final paid = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DebtPaymentSheet(debt: debt),
    );
    if (paid != null && paid > 0) {
      await AppRepository.instance.recordDebtPayment(debt.id!, paid);
      context.read<AppState>().bumpData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recorded ₱${paid.toStringAsFixed(2)} payment.')),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppState>().currencyCode;
    final visible = _debts
        .where((d) => d.direction == _direction && !d.isFullyPaid)
        .toList();
    final paid = _debts
        .where((d) => d.direction == _direction && d.isFullyPaid)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Money owed')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Owed to me',
                          value: formatMoney(_totals['owed_to_me'] ?? 0, currency),
                          color: AppColors.income,
                          icon: Icons.south_west,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'I owe',
                          value: formatMoney(_totals['owed_by_me'] ?? 0, currency),
                          color: AppColors.warning,
                          icon: Icons.north_east,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'owed_to_me',
                          label: Text('Owed to me'),
                          icon: Icon(Icons.south_west),
                        ),
                        ButtonSegment(
                          value: 'owed_by_me',
                          label: Text('I owe'),
                          icon: Icon(Icons.north_east),
                        ),
                      ],
                      selected: {_direction},
                      onSelectionChanged: (s) =>
                          setState(() => _direction = s.first),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (visible.isEmpty && paid.isEmpty)
                    EmptyState(
                      icon: Icons.handshake_outlined,
                      title: _direction == 'owed_to_me'
                          ? 'Nothing owed to you'
                          : 'You owe nothing',
                      message: 'Tap + to record money lent or borrowed, '
                          'grouped by person.',
                    )
                  else ...[
                    if (visible.isNotEmpty) ...[
                      for (final d in visible)
                        _DebtTile(
                          debt: d,
                          currency: currency,
                          onTap: () => _showActions(d),
                        ),
                      if (paid.isNotEmpty) const SizedBox(height: 14),
                    ],
                    if (paid.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                        child: Text('Settled',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      for (final d in paid)
                        _DebtTile(
                          debt: d,
                          currency: currency,
                          settled: true,
                          onTap: () => _showActions(d),
                        ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  void _showActions(Debt debt) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Record payment'),
              onTap: () {
                Navigator.pop(ctx);
                _recordPayment(debt);
              },
            ),
            if (debt.isFullyPaid && debt.status != 'active')
              ListTile(
                leading: const Icon(Icons.replay_outlined),
                title: const Text('Reopen'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await AppRepository.instance.updateDebt(debt.id!,
                      status: 'active');
                  context.read<AppState>().bumpData();
                  await _load();
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                _edit(debt);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Delete', style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: Text('Delete record for ${debt.person}?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger),
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await AppRepository.instance.deleteDebt(debt.id!);
                  context.read<AppState>().bumpData();
                  await _load();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A small arrow picked up by the reader at a glance.
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall!.color)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  final Debt debt;
  final String currency;
  final bool settled;
  final VoidCallback onTap;

  const _DebtTile(
      {required this.debt,
      required this.currency,
      this.settled = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).textTheme.bodySmall!.color!;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (settled ? secondary : AppColors.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              debt.person.isEmpty ? '?' : debt.person.characters.first.toUpperCase(),
              style: TextStyle(
                  color: settled ? secondary : AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(debt.person,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  [
                    if (debt.description.isNotEmpty) debt.description,
                    if (debt.dueDate != null && debt.dueDate!.isNotEmpty)
                      'Due ${formatDateShort(debt.dueDate!)}',
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(debt.remainingAmount, currency),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  decoration: settled ? TextDecoration.lineThrough : null,
                  color: settled
                      ? secondary
                      : Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
              if (!settled)
                Text('of ${formatMoney(debt.amount, currency)}',
                    style: TextStyle(fontSize: 11, color: secondary)),
            ],
          ),
        ],
      ),
    );
  }
}