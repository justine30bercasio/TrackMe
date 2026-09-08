import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/payment_methods.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/transactions/expense_form_screen.dart';
import 'package:track_me/screens/transactions/income_form_screen.dart';
import 'package:track_me/screens/transfers/transfer_form_screen.dart';

class AccountDetailScreen extends StatefulWidget {
  final String paymentMethodCode;

  const AccountDetailScreen({super.key, required this.paymentMethodCode});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  List<Expense> _expenses = [];
  List<Income> _incomes = [];
  List<Transfer> _transfers = [];
  PaymentMethodStat? _stat;
  bool _loading = true;

  String get _label => paymentMethodLabel(widget.paymentMethodCode);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = AppRepository.instance;
    final stats = await repo.paymentMethodStats();
    final expenses =
        await repo.getExpenses(paymentMethod: widget.paymentMethodCode);
    final incomes =
        await repo.getIncomes(paymentMethod: widget.paymentMethodCode);
    final transfers =
        await repo.getTransfersForMethod(widget.paymentMethodCode);
    if (!mounted) return;
    setState(() {
      _stat = stats[widget.paymentMethodCode] ?? const PaymentMethodStat(0, 0);
      _expenses = expenses;
      _incomes = incomes;
      _transfers = transfers;
      _loading = false;
    });
  }

  Future<void> _openForm(Widget form) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => form));
    if (!mounted) return;
    context.read<AppState>().bumpData();
    await _load();
  }

  List<_ActivityItem> _buildItems() {
    final items = <_ActivityItem>[
      for (final t in _transfers)
        _ActivityItem(
          type: 'transfer',
          id: t.id ?? 0,
          title: t.fromMethod == widget.paymentMethodCode
              ? 'To ${paymentMethodLabel(t.toMethod)}'
              : 'From ${paymentMethodLabel(t.fromMethod)}',
          subtitle: 'Transfer',
          colorHex: null,
          dateIso: t.transferDate,
          createdAt: t.createdAt,
          amount: t.amount,
          isOutgoing: t.fromMethod == widget.paymentMethodCode,
        ),
      for (final e in _expenses)
        _ActivityItem(
          type: 'expense',
          id: e.id ?? 0,
          title: e.description.isEmpty ? 'Expense' : e.description,
          subtitle: e.categoryName ?? '',
          colorHex: e.categoryColor,
          dateIso: e.expenseDate,
          createdAt: e.createdAt,
          amount: e.amount,
        ),
      for (final i in _incomes)
        _ActivityItem(
          type: 'income',
          id: i.id ?? 0,
          title: i.source.isEmpty ? 'Income' : i.source,
          subtitle: 'Income',
          colorHex: null,
          dateIso: i.incomeDate,
          createdAt: i.createdAt,
          amount: i.amount,
        ),
    ];
    items.sort((a, b) {
      final byDate = b.dateIso.compareTo(a.dateIso);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppState>().currencyCode;
    final incomeTotal = _incomes.fold<double>(0, (s, i) => s + i.amount);
    final expenseTotal = _expenses.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(title: Text(_label)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  BrandHeroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PaymentMethodBadge(
                                code: widget.paymentMethodCode, size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_label,
                                      style: const TextStyle(
                                          color: AppColors.onHeroMuted,
                                          fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatMoney(_stat?.balance ?? 0, currency),
                                    style: const TextStyle(
                                        color: AppColors.onHero,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                  label: 'Income',
                                  value: formatMoney(incomeTotal, currency),
                                  color: const Color(0xFF7CFFD8)),
                            ),
                            Container(
                                width: 1,
                                height: 30,
                                color: Colors.white.withValues(alpha: 0.25)),
                            Expanded(
                              child: _MiniStat(
                                  label: 'Expenses',
                                  value: formatMoney(expenseTotal, currency),
                                  color: const Color(0xFFFFB7C5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          label: 'Add expense',
                          icon: Icons.remove_circle_outline,
                          color: AppColors.expense,
                          onTap: () => _openForm(ExpenseFormScreen(
                              initialPaymentMethod: widget.paymentMethodCode)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionCard(
                          label: 'Add income',
                          icon: Icons.add_circle_outline,
                          color: AppColors.income,
                          onTap: () => _openForm(IncomeFormScreen(
                              initialPaymentMethod: widget.paymentMethodCode)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionCard(
                          label: 'Transfer',
                          icon: Icons.swap_horiz,
                          color: AppColors.secondary,
                          onTap: () => _openForm(TransferFormScreen(
                              initialFromMethod: widget.paymentMethodCode)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('Recent activity',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  if (_expenses.isEmpty && _incomes.isEmpty && _transfers.isEmpty)
                    EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No activity yet',
                      message:
                          'Expenses, income and transfers using $_label will show up here.',
                    )
                  else
                    ..._buildItems().take(60).map((item) =>
                        _ActivityTile(item: item, currency: currency)),
                ],
              ),
            ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.onHeroMuted, fontSize: 11)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: color, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem {
  final String type;
  final int id;
  final String title;
  final String subtitle;
  final String? colorHex;
  final String dateIso;
  final String createdAt;
  final double amount;
  final bool isOutgoing;

  const _ActivityItem({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    this.colorHex,
    required this.dateIso,
    required this.createdAt,
    required this.amount,
    this.isOutgoing = false,
  });
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItem item;
  final String currency;

  const _ActivityTile({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == 'income';
    final isTransfer = item.type == 'transfer';
    final amountColor = isIncome
        ? AppColors.income
        : isTransfer
            ? AppColors.secondary
            : AppColors.expense;
    final badgeColor = isIncome
        ? AppColors.income
        : isTransfer
            ? AppColors.secondary
            : AppColors.colorFromHex(item.colorHex ?? '',
                fallback: AppColors.primary);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isTransfer
                  ? (item.isOutgoing
                      ? Icons.call_made
                      : Icons.call_received)
                  : (isIncome ? Icons.south_west : categoryIcon(item.subtitle)),
              color: badgeColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${item.subtitle} · ${formatDateShort(item.dateIso)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall!.color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isTransfer && item.isOutgoing ? '-' : isIncome ? '+' : ''}${formatMoney(item.amount, currency)}',
            style: TextStyle(
                color: amountColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
