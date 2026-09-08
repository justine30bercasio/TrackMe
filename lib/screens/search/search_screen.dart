import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/payment_methods.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/budgets/budgets_screen.dart';
import 'package:track_me/screens/goals/goals_screen.dart';
import 'package:track_me/screens/loans/loan_detail_screen.dart';
import 'package:track_me/screens/recurring/recurring_list_screen.dart';
import 'package:track_me/screens/wallet/account_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  GlobalSearchResults _results = GlobalSearchResults();
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final term = value.trim();
      if (term.isEmpty) {
        setState(() {
          _results = GlobalSearchResults();
          _searched = false;
          _searching = false;
        });
        return;
      }
      setState(() => _searching = true);
      final res = await AppRepository.instance.globalSearch(term);
      if (!mounted) return;
      setState(() {
        _results = res;
        _searching = false;
        _searched = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppState>().currencyCode;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: 'Search transactions, accounts, loans\u2026',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        _debounce?.cancel();
                        setState(() {
                          _results = GlobalSearchResults();
                          _searched = false;
                          _searching = false;
                        });
                      },
                    ),
            ),
          ),
        ),
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator())
          : !_searched
              ? const EmptyState(
                  icon: Icons.travel_explore,
                  title: 'Search everything',
                  message:
                      'Find expenses, income, transfers, accounts, loans, '
                      'goals, budgets and recurring bills.',
                )
              : _results.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off,
                      title: 'No results',
                      message: 'Try a different keyword or amount.',
                    )
                  : _ResultList(results: _results, currency: currency),
    );
  }
}

class _ResultList extends StatelessWidget {
  final GlobalSearchResults results;
  final String currency;

  const _ResultList({required this.results, required this.currency});

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      if (results.expenses.isNotEmpty)
        _Section(
          title: 'Expenses',
          count: results.expenses.length,
          rows: results.expenses
              .take(8)
              .map((e) => _ExpenseRow(expense: e, currency: currency))
              .toList(),
        ),
      if (results.incomes.isNotEmpty)
        _Section(
          title: 'Income',
          count: results.incomes.length,
          rows: results.incomes
              .take(8)
              .map((i) => _IncomeRow(income: i, currency: currency))
              .toList(),
        ),
      if (results.transfers.isNotEmpty)
        _Section(
          title: 'Transfers',
          count: results.transfers.length,
          rows: results.transfers
              .take(8)
              .map((t) => _TransferRow(transfer: t, currency: currency))
              .toList(),
        ),
      if (results.accounts.isNotEmpty)
        _Section(
          title: 'Accounts',
          count: results.accounts.length,
          rows: results.accounts.map((entry) {
            final stat = entry.value as PaymentMethodStat;
            return ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(paymentMethodLabel(entry.key)),
              subtitle: Text(
                  'Balance ${formatMoney(stat.balance, currency)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AccountDetailScreen(paymentMethodCode: entry.key),
                ),
              ),
            );
          }).toList(),
        ),
      if (results.loans.isNotEmpty)
        _Section(
          title: 'Loans',
          count: results.loans.length,
          rows: results.loans.map((l) {
            return ListTile(
              leading: const Icon(Icons.request_quote_outlined),
              title: Text(l.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${l.lender ?? 'Loan'} \u00b7 ${formatMoney(l.principal, currency)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LoanDetailScreen(loanId: l.id!),
                ),
              ),
            );
          }).toList(),
        ),
      if (results.goals.isNotEmpty)
        _Section(
          title: 'Goals',
          count: results.goals.length,
          rows: results.goals.map((g) {
            return ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(g.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${formatMoney(g.currentAmount, currency)} of ${formatMoney(g.targetAmount, currency)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GoalsScreen()),
              ),
            );
          }).toList(),
        ),
      if (results.budgets.isNotEmpty)
        _Section(
          title: 'Budgets',
          count: results.budgets.length,
          rows: results.budgets.map((b) {
            return ListTile(
              leading: const Icon(Icons.pie_chart_outline),
              title: Text(b.categoryName ?? 'Budget',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle:
                  Text('Limit ${formatMoney(b.effectiveLimit, currency)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BudgetsScreen()),
              ),
            );
          }).toList(),
        ),
      if (results.recurring.isNotEmpty)
        _Section(
          title: 'Recurring',
          count: results.recurring.length,
          rows: results.recurring.map((r) {
            return ListTile(
              leading: const Icon(Icons.event_repeat_outlined),
              title: Text(r.description,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${r.amount.toStringAsFixed(2)} \u00b7 every ${r.frequency}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const RecurringListScreen()),
              ),
            );
          }).toList(),
        ),
      if (results.categories.isNotEmpty)
        _Section(
          title: 'Categories',
          count: results.categories.length,
          rows: results.categories.map((c) {
            return ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: Text(c.name),
              subtitle: const Text('Category'),
            );
          }).toList(),
        ),
    ];

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      children: sections,
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final int count;
  final List<Widget> rows;

  const _Section(
      {required this.title, required this.count, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Text(
            count > rows.length ? '$title ($count)' : title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...rows,
        const Divider(indent: 20, endIndent: 20),
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final Expense expense;
  final String currency;

  const _ExpenseRow({required this.expense, required this.currency});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).textTheme.bodySmall!.color!;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.north_east, size: 16, color: AppColors.danger),
      ),
      title: Text(expense.description,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${expense.categoryName ?? 'Expense'} \u00b7 ${formatDateShort(expense.expenseDate)} \u00b7 ${paymentMethodLabel(expense.paymentMethod)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: secondary),
      ),
      trailing: Text(
        '-${formatMoney(expense.amount, currency)}',
        style: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w700,
            fontSize: 14),
      ),
      onTap: () => _showDetail(
        context,
        title: expense.description,
        amount: '-${formatMoney(expense.amount, currency)}',
        color: AppColors.danger,
        lines: [
          'Category: ${expense.categoryName ?? 'Expense'}',
          'Account: ${paymentMethodLabel(expense.paymentMethod)}',
          'Date: ${formatDateShort(expense.expenseDate)}',
          if (expense.notes.isNotEmpty) 'Notes: ${expense.notes}',
        ],
      ),
    );
  }
}

class _IncomeRow extends StatelessWidget {
  final Income income;
  final String currency;

  const _IncomeRow({required this.income, required this.currency});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).textTheme.bodySmall!.color!;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.income.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.south_west, size: 16, color: AppColors.income),
      ),
      title: Text(income.source,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        'Income \u00b7 ${formatDateShort(income.incomeDate)} \u00b7 ${paymentMethodLabel(income.paymentMethod)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: secondary),
      ),
      trailing: Text(
        '+${formatMoney(income.amount, currency)}',
        style: const TextStyle(
            color: AppColors.income,
            fontWeight: FontWeight.w700,
            fontSize: 14),
      ),
      onTap: () => _showDetail(
        context,
        title: income.source,
        amount: '+${formatMoney(income.amount, currency)}',
        color: AppColors.income,
        lines: [
          'Account: ${paymentMethodLabel(income.paymentMethod)}',
          'Date: ${formatDateShort(income.incomeDate)}',
          if (income.notes.isNotEmpty) 'Notes: ${income.notes}',
        ],
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  final Transfer transfer;
  final String currency;

  const _TransferRow({required this.transfer, required this.currency});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).textTheme.bodySmall!.color!;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.swap_horiz, size: 16, color: AppColors.primary),
      ),
      title: Text(
          '${paymentMethodLabel(transfer.fromMethod)} \u2192 ${paymentMethodLabel(transfer.toMethod)}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${formatDateShort(transfer.transferDate)}'
        '${transfer.notes.isNotEmpty ? ' \u00b7 ${transfer.notes}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: secondary),
      ),
      trailing: Text(
        formatMoney(transfer.amount, currency),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      onTap: () => _showDetail(
        context,
        title: 'Transfer',
        amount: formatMoney(transfer.amount, currency),
        color: AppColors.primary,
        lines: [
          'From: ${paymentMethodLabel(transfer.fromMethod)}',
          'To: ${paymentMethodLabel(transfer.toMethod)}',
          'Date: ${formatDateShort(transfer.transferDate)}',
          if (transfer.notes.isNotEmpty) 'Notes: ${transfer.notes}',
        ],
      ),
    );
  }
}

void _showDetail(BuildContext context,
    {required String title,
    required String amount,
    required Color color,
    required List<String> lines}) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(ctx).textTheme.headlineSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(amount,
                style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(l, style: const TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    ),
  );
}