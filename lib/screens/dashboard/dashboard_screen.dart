import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/assistant/assistant_screen.dart';
import 'package:track_me/screens/budgets/budget_form_screen.dart';
import 'package:track_me/screens/goals/goal_form_screen.dart';
import 'package:track_me/screens/insights/insights_screen.dart';
import 'package:track_me/screens/loans/loans_screen.dart';
import 'package:track_me/screens/networth/networth_screen.dart';
import 'package:track_me/screens/notifications/notification_center_screen.dart';
import 'package:track_me/screens/receipts/scan_receipt_screen.dart';
import 'package:track_me/screens/reports/reports_screen.dart';
import 'package:track_me/screens/transactions/expense_form_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future;
  int _lastVersion = -1;

  static const List<String> _shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  Future<_DashboardData> _load() async {
    final repo = AppRepository.instance;
    final user = await repo.getUser();

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
    final monthEnd = DateTime(now.year, now.month + 1, 0).toIso8601String().substring(0, 10);

    final allExpenses = await repo.getExpenses();
    final allIncomes = await repo.getIncomes();
    final monthExpenses = allExpenses.where((e) => e.expenseDate.compareTo(monthStart) >= 0 && e.expenseDate.compareTo(monthEnd) <= 0).toList();
    final monthIncomes = allIncomes.where((i) => i.incomeDate.compareTo(monthStart) >= 0 && i.incomeDate.compareTo(monthEnd) <= 0).toList();

    final totalMonthExpense = monthExpenses.fold(0.0, (s, e) => s + e.amount);
    final totalMonthIncome = monthIncomes.fold(0.0, (s, i) => s + i.amount);
    final totalIncomeAll = allIncomes.fold(0.0, (s, i) => s + i.amount);
    final totalExpenseAll = allExpenses.fold(0.0, (s, e) => s + e.amount);

    // monthly trend for last 12 months
    final monthlyIncome = await repo.monthlyIncomeByKey(12);
    final monthlyExpense = await repo.monthlyExpenseByKey(12);
    final trend = <_TrendPoint>[];
    for (var i = 11; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = '${d.year}' + d.month.toString().padLeft(2, '0');
      trend.add(_TrendPoint('${_shortMonths[d.month - 1]}', monthlyIncome[key] ?? 0, monthlyExpense[key] ?? 0));
    }

    // category breakdown current month
    final catMap = <String, List<double>>{};
    final catColors = <String, String>{};
    for (final e in monthExpenses) {
      final name = e.categoryName ?? 'Uncategorized';
      catMap[name] = [(catMap[name]?[0] ?? 0) + e.amount, (catMap[name]?[1] ?? 0) + 1];
      catColors[name] = e.categoryColor ?? '#6b7280';
    }
    final categories = catMap.entries
        .map((e) => _CategorySlice(e.key, e.value[0], e.value[1].toInt(), catColors[e.key] ?? '#6b7280'))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final recent = (monthExpenses.isNotEmpty ? monthExpenses : allExpenses.take(5)).isNotEmpty
        ? (monthExpenses.isNotEmpty ? monthExpenses : allExpenses.take(5).toList())
        : <Expense>[];

    final activeGoals = await repo.getGoals(status: 'active');
    final budgets = await repo.getBudgetSpendings();

    final upcoming = await repo.upcomingLoanPayments(withinDays: 30);
    final loans = await repo.getLoans();
    final loanNames = {for (final l in loans) l.id: l.name};
    final upcomingRepayments = [
      for (final p in upcoming) _UpcomingRepayment(p, loanNames[p.loanId] ?? 'Loan'),
    ];

    final lastMonthStart = DateTime(now.year, now.month - 1, 1).toIso8601String().substring(0, 10);
    final lastMonthEnd = DateTime(now.year, now.month, 0).toIso8601String().substring(0, 10);
    final lastMonthExpenses = allExpenses
        .where((e) => e.expenseDate.compareTo(lastMonthStart) >= 0 && e.expenseDate.compareTo(lastMonthEnd) <= 0)
        .fold(0.0, (s, e) => s + e.amount);

    return _DashboardData(
      user: user,
      totalMonthExpense: totalMonthExpense,
      totalMonthIncome: totalMonthIncome,
      totalIncomeAll: totalIncomeAll,
      totalExpenseAll: totalExpenseAll,
      netWorth: totalIncomeAll - totalExpenseAll,
      averageExpense: monthExpenses.isEmpty ? 0 : totalMonthExpense / monthExpenses.length,
      lastMonthExpense: lastMonthExpenses,
      trend: trend,
      categories: categories,
      recent: recent,
      activeGoals: activeGoals,
      budgetSpendings: budgets,
      upcomingRepayments: upcomingRepayments,
    );
  }

  @override
  Widget build(BuildContext context) {
    final version = context.watch<AppState>().dataVersion;
    if (_lastVersion != version) {
      _lastVersion = version;
      _future = _load();
    }

    void reload() {
      setState(() {
        _future = _load();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reports',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
            icon: const Icon(Icons.bar_chart),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationCenterScreen()));
              reload();
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => reload(),
        child: FutureBuilder<_DashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            return _DashboardBody(data: snapshot.data!, onChanged: reload);
          },
        ),
      ),
    );
  }
}

class _TrendPoint {
  final String label;
  final double income;
  final double expense;
  _TrendPoint(this.label, this.income, this.expense);
}

class _CategorySlice {
  final String name;
  final double total;
  final int count;
  final String color;
  _CategorySlice(this.name, this.total, this.count, this.color);
}

class _UpcomingRepayment {
  final LoanPayment payment;
  final String loanName;
  _UpcomingRepayment(this.payment, this.loanName);
}

class _DashboardData {
  final AppUser user;
  final double totalMonthExpense;
  final double totalMonthIncome;
  final double totalIncomeAll;
  final double totalExpenseAll;
  final double netWorth;
  final double averageExpense;
  final double lastMonthExpense;
  final List<_TrendPoint> trend;
  final List<_CategorySlice> categories;
  final List<Expense> recent;
  final List<SavingsGoal> activeGoals;
  final List<BudgetSpending> budgetSpendings;
  final List<_UpcomingRepayment> upcomingRepayments;

  _DashboardData({
    required this.user,
    required this.totalMonthExpense,
    required this.totalMonthIncome,
    required this.totalIncomeAll,
    required this.totalExpenseAll,
    required this.netWorth,
    required this.averageExpense,
    required this.lastMonthExpense,
    required this.trend,
    required this.categories,
    required this.recent,
    required this.activeGoals,
    required this.budgetSpendings,
    required this.upcomingRepayments,
  });
}

class _DashboardBody extends StatefulWidget {
  final _DashboardData data;
  final VoidCallback onChanged;
  const _DashboardBody({required this.data, required this.onChanged});

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final cur = d.user.preferredCurrency;
    final isNewUser = d.totalExpenseAll == 0 && d.totalIncomeAll == 0;
    final months = _monthName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _BalanceHero(data: d, currency: cur),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Spent this month',
                value: MoneyText(d.totalMonthExpense, cur, fontSize: 15, color: AppColors.expense),
                icon: Icons.trending_down,
                iconColor: AppColors.expense,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: 'Earned this month',
                value: MoneyText(d.totalMonthIncome, cur, fontSize: 15, color: AppColors.income),
                icon: Icons.trending_up,
                iconColor: AppColors.income,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Daily average',
                value: MoneyText(d.averageExpense, cur, fontSize: 15),
                icon: Icons.stacked_line_chart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: 'Last month',
                value: MoneyText(d.lastMonthExpense, cur, fontSize: 15),
                icon: Icons.calendar_today_outlined,
                iconColor: AppColors.secondary,
              ),
            ),
          ],
        ),
        if (isNewUser) ...[
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.rocket_launch_outlined, size: 40, color: AppColors.primary),
                const SizedBox(height: 12),
                Text('Welcome to ${AppStrings.appName}!', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('Add your first expense or income using the + button below.',
                    textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        Text('This year overview', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _LegendDot(color: AppColors.income, label: 'Income'),
                  const SizedBox(width: 16),
                  _LegendDot(color: AppColors.expense, label: 'Expenses'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: _MonthlyTrendChart(points: d.trend, currency: cur),
              ),
            ],
          ),
        ),
        if (d.categories.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Spending by category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (d.categories.length > 1)
                  SizedBox(width: 108, height: 108, child: _DonutChart(slices: d.categories))
                else
                  SizedBox(
                    width: 108,
                    height: 108,
                    child: Center(child: Icon(Icons.pie_chart_outline, size: 44, color: Theme.of(context).textTheme.bodySmall!.color)),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (final c in d.categories.take(6))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.colorFromHex(c.color), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(c.name, style: const TextStyle(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              Flexible(
                                child: Text(
                                  formatMoney(c.total, cur),
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (d.budgetSpendings.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Budgets this period', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...d.budgetSpendings.take(4).map((bs) {
            final percent = bs.budget.limitAmount == 0 ? 0.0 : bs.spent / bs.budget.limitAmount * 100;
            final exceeded = percent >= 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => BudgetFormScreen(budget: bs.budget)));
                  widget.onChanged();
                },
                child: Column(
                  children: [
                    Row(
                      children: [
                        CategoryAvatar(name: bs.budget.categoryName, color: bs.budget.categoryColor, size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(bs.budget.categoryName ?? 'Category', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text('${formatMoney(bs.spent, cur)} of ${formatMoney(bs.budget.limitAmount, cur)}', style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodySmall!.color)),
                            ],
                          ),
                        ),
                        Pill(exceeded ? 'Over' : '${percent.toStringAsFixed(0)}%', exceeded ? AppColors.danger : (percent > 80 ? AppColors.warning : AppColors.income)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ProgressBar(fraction: percent / 100, color: exceeded ? AppColors.danger : (percent > 80 ? AppColors.warning : AppColors.primary)),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 22),
        if (d.upcomingRepayments.isNotEmpty) ...[
          Text('Loan repayments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...d.upcomingRepayments.take(3).map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoansScreen()));
                    widget.onChanged();
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.request_quote_outlined, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.loanName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(
                              'Due ${formatDateShort(u.payment.dueDate)} · on your salary day',
                              style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodySmall!.color),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Text(formatMoney(u.payment.amountDue, cur), style: const TextStyle(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(child: Text('Recent activity', style: Theme.of(context).textTheme.titleMedium)),
            Text(months, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodySmall!.color)),
          ],
        ),
        if (d.recent.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text('No recent transactions yet.', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color)),
            ),
          )
        else
          ...d.recent.take(6).map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: e)));
                      widget.onChanged();
                    },
                    child: Row(
                      children: [
                        CategoryAvatar(name: e.categoryName, color: e.categoryColor, size: 38),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(formatDate(e.expenseDate), style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodySmall!.color)),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Text('-${formatMoney(e.amount, e.currencyCode.isEmpty ? cur : e.currencyCode)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.expense), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        if (d.activeGoals.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Savings goals', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...d.activeGoals.take(3).map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GoalFormScreen(goal: g)));
                      widget.onChanged();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(g.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            Text('${g.progressPercentage.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ProgressBar(fraction: g.progressPercentage / 100, color: AppColors.primary),
                        const SizedBox(height: 8),
                        Text('${formatMoney(g.currentAmount, cur)} of ${formatMoney(g.targetAmount, cur)}',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color)),
                      ],
                    ),
                  ),
                ),
              ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QuickLinkCard(
                icon: Icons.assessment_outlined,
                label: 'Net Worth',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NetWorthScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickLinkCard(
                icon: Icons.request_quote_outlined,
                label: 'Loans',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoansScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickLinkCard(
                icon: Icons.insights_outlined,
                label: 'Insights',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InsightsScreen())),
              ),
            ),
            const SizedBox(width: 12),
Expanded(
                  child: _QuickLinkCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'Reports',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickLinkCard(
                    icon: Icons.smart_toy_outlined,
                    label: 'Assistant',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssistantScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickLinkCard(
                    icon: Icons.document_scanner_outlined,
                    label: 'Scan receipt',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanReceiptScreen())),
                  ),
                ),
              ],
            ),
          ],
      );
    }

  String get _monthName {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[DateTime.now().month - 1];
  }
}

class _BalanceHero extends StatelessWidget {
  final _DashboardData data;
  final String currency;
  const _BalanceHero({required this.data, required this.currency});

  @override
  Widget build(BuildContext context) {
    final positive = data.netWorth >= 0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.heroGradient),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total balance', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      '${positive ? '' : '-'}${currencySymbol(currency)}${data.netWorth.abs().toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.wallet, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroStat(label: 'Income (all time)', amount: data.totalIncomeAll, currency: currency, color: const Color(0xFF7CFFD8)),
              ),
              Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.25)),
              Expanded(
                child: _HeroStat(label: 'Expenses (all time)', amount: data.totalExpenseAll, currency: currency, color: const Color(0xFFFFB7C5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  const _HeroStat({required this.label, required this.amount, required this.currency, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          formatMoney(amount, currency),
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  final List<_TrendPoint> points;
  final String currency;
  const _MonthlyTrendChart({required this.points, required this.currency});

  @override
  Widget build(BuildContext context) {
    final maxVal = points.fold<double>(0, (m, p) => [m, p.income, p.expense].reduce((a, b) => a > b ? a : b));
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: safeMax / 3,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF262C38) : const Color(0xFFF0F2F7),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value <= 0) return const SizedBox();
                return Text(
                  _compactNumber(value),
                  style: TextStyle(fontSize: 9.5, color: Theme.of(context).textTheme.bodySmall!.color),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox();
                if (i % 2 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(points[i].label, style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall!.color)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        maxY: safeMax * 1.1,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final p = points[group.x];
              return BarTooltipItem(
                '${rodIndex == 0 ? 'Income' : 'Expense'}\n${p.label} · ${formatMoney(rod.toY, currency)}',
                TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.w700),
              );
            },
          ),
        ),
        barGroups: List.generate(points.length, (i) {
          return BarChartGroupData(
            x: i,
            barsSpace: 3,
            barRods: [
              BarChartRodData(toY: points[i].income, color: AppColors.income, width: 7, borderRadius: const BorderRadius.all(Radius.circular(3))),
              BarChartRodData(toY: points[i].expense, color: AppColors.expense, width: 7, borderRadius: const BorderRadius.all(Radius.circular(3))),
            ],
          );
        }),
      ),
    );
  }

  String _compactNumber(double v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')}k';
    }
    return v.toStringAsFixed(0);
  }
}

class _DonutChart extends StatelessWidget {
  final List<_CategorySlice> slices;
  const _DonutChart({required this.slices});

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (s, c) => s + c.total);
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 34,
        sections: slices.map((s) {
          return PieChartSectionData(
            value: total <= 0 ? 1 : s.total,
            radius: 44,
            color: AppColors.colorFromHex(s.color),
            showTitle: false,
          );
        }).toList(),
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLinkCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}