import 'dart:convert';
import 'dart:math';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/loan_math.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/database_helper.dart';
import 'package:track_me/data/models.dart';
import 'package:sqflite/sqflite.dart';

class DuplicateTransactionException implements Exception {
  final String message;
  DuplicateTransactionException(this.message);

  @override
  String toString() => message;
}

class CategoryInUseException implements Exception {
  final String message;
  CategoryInUseException(this.message);
  @override
  String toString() => message;
}

class ExpenseBudgetResult {
  final Expense expense;
  final Budget? exceededBudget;
  ExpenseBudgetResult(this.expense, this.exceededBudget);
}

class GoalProgressResult {
  final SavingsGoal goal;
  final List<int> milestonesCrossed;
  final bool completed;
  GoalProgressResult(this.goal, this.milestonesCrossed, this.completed);
}

class ReportData {
  final double totalIncome;
  final double totalExpenses;
  final double netAmount;
  final List<MapEntry<String, double>> expensesByCategory;
  final List<MapEntry<String, double>> incomeBySource;
  final double ytdIncome;
  final double ytdExpenses;
  final String startOfMonth;
  ReportData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netAmount,
    required this.expensesByCategory,
    required this.incomeBySource,
    required this.ytdIncome,
    required this.ytdExpenses,
    required this.startOfMonth,
  });
}

class MonthlyBreakdown {
  final String label;
  final double income;
  final double expenses;
  final double net;
  MonthlyBreakdown(this.label, this.income, this.expenses, this.net);
}

class NetWorthData {
  final double currentNetWorth;
  final double totalIncome;
  final double totalExpenses;
  final List<MonthlyBreakdown> breakdown;
  NetWorthData(this.currentNetWorth, this.totalIncome, this.totalExpenses, this.breakdown);
}

class Insights {
  final DateTime month;
  final double currentMonthTotal;
  final double lastMonthTotal;
  final double changePercent;
  final String trend;
  final double averageLast3Months;
  final List<SpendingAnomaly> anomalies;
  final ForecastData? forecast;
  final List<CategoryBreakdownRow> categoryBreakdown;
  final List<DayOfWeekRow> dayOfWeekAnalysis;
  final Map<String, TimeOfDayRow> timeOfDayAnalysis;
  final int spendingScore;
  final String scoreRating;
  final List<MonthlyTrendRow> monthlyTrend;
  final List<CategoryBreakdownRow> topCategories;
  Insights({
    required this.month,
    required this.currentMonthTotal,
    required this.lastMonthTotal,
    required this.changePercent,
    required this.trend,
    required this.averageLast3Months,
    required this.anomalies,
    this.forecast,
    required this.categoryBreakdown,
    required this.dayOfWeekAnalysis,
    required this.timeOfDayAnalysis,
    required this.spendingScore,
    required this.scoreRating,
    required this.monthlyTrend,
    required this.topCategories,
  });
}

class SpendingAnomaly {
  final String description;
  final String category;
  final double amount;
  final double average;
  final double ratio;
  SpendingAnomaly(this.description, this.category, this.amount, this.average, this.ratio);
}

class ForecastData {
  final List<String> labels;
  final List<double> values;
  final double slope;
  final String trend;
  final List<String> historyLabels;
  final List<double> historyValues;
  ForecastData(this.labels, this.values, this.slope, this.trend, this.historyLabels, this.historyValues);
}

class CategoryBreakdownRow {
  final String category;
  final String color;
  final double total;
  final int count;
  double percentage;
  CategoryBreakdownRow(this.category, this.color, this.total, this.count, double this.percentage);
}

class DayOfWeekRow {
  final String day;
  final double total;
  final int count;
  final double average;
  DayOfWeekRow(this.day, this.total, this.count, this.average);
}

class TimeOfDayRow {
  final String period;
  final double total;
  final int count;
  TimeOfDayRow(this.period, this.total, this.count);
}

class MonthlyTrendRow {
  final String label;
  final double total;
  MonthlyTrendRow(this.label, this.total);
}

class BudgetSpending {
  final Budget budget;
  final double spent;
  BudgetSpending(this.budget, this.spent);
}

/// Aggregate net balance + transaction count for a payment method (account).
class PaymentMethodStat {
  final double balance;
  final int count;
  const PaymentMethodStat(this.balance, this.count);
}

class AppRepository {
  AppRepository._();
  static final AppRepository instance = AppRepository._();

  // ---------------------------------------------------------------------
  // User / profile
  // ---------------------------------------------------------------------

  Future<AppUser> getUser() async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query('app_settings', where: 'key = ?', whereArgs: ['profile']);
    if (rows.isEmpty) {
      return AppUser(name: '', preferredCurrency: 'USD', language: 'en');
    }
    final json = jsonDecode(rows.first['value'] as String) as Map<String, dynamic>;
    return AppUser.fromMap(json);
  }

  Future<void> saveUser(AppUser user) async {
    final database = await DatabaseHelper.instance.database;
    await database.insert('app_settings', {
      'key': 'profile',
      'value': jsonEncode(user.toMap()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProfile({
    String? name,
    String? country,
    String? region,
    String? preferredCurrency,
    String? timezone,
    String? language,
    int? salaryDay,
    bool? notifyBudgetExceeded,
    bool? notifyGoalCompleted,
    bool? notifyGoalMilestones,
    bool? onboardingCompleted,
    String? avatar,
  }) async {
    final user = await getUser();
    final updated = AppUser(
      id: null,
      name: name ?? user.name,
      email: user.email,
      country: country ?? user.country,
      region: region ?? user.region,
      preferredCurrency: preferredCurrency ?? user.preferredCurrency,
      timezone: timezone ?? user.timezone,
      language: language ?? user.language,
      salaryDay: salaryDay ?? user.salaryDay,
      notifyBudgetExceeded: notifyBudgetExceeded ?? user.notifyBudgetExceeded,
      notifyGoalCompleted: notifyGoalCompleted ?? user.notifyGoalCompleted,
      notifyGoalMilestones: notifyGoalMilestones ?? user.notifyGoalMilestones,
      onboardingCompleted: onboardingCompleted ?? user.onboardingCompleted,
      avatar: avatar ?? user.avatar,
    );
    await saveUser(updated);
  }

  // ---------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------

  Future<List<Category>> getCategories() async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query('categories', orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<Map<int, Category>> getCategoryMap() async {
    final cats = await getCategories();
    return {for (final c in cats) c.id!: c};
  }

  Future<Category?> getCategory(int id) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<Category?> getCategoryByName(String name) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query(
      'categories',
      where: 'LOWER(name) = ? COLLATE NOCASE',
      whereArgs: [name.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<Category> addCategory(String name, {String description = '', String? color}) async {
    final database = await DatabaseHelper.instance.database;
    final c = Category(
      name: name,
      description: description,
      color: color ?? _randomColor(),
    );
    final id = await database.insert('categories', {
      ...c.toMap(),
      'created_at': nowIso(),
    });
    await logActivity('category', 'Created category \'$name\'');
    return c.copyWith(id: id);
  }

  Future<void> updateCategory(Category category) async {
    final database = await DatabaseHelper.instance.database;
    await database.update('categories', {...category.toMap(), 'id': category.id}, where: 'id = ?', whereArgs: [category.id]);
    await logActivity('category', 'Updated category \'${category.name}\'');
  }

  Future<void> deleteCategory(int id) async {
    final database = await DatabaseHelper.instance.database;
    final expenseCount = Sqflite.firstIntValue(await database.rawQuery(
        'SELECT COUNT(*) FROM expenses WHERE category_id = ? AND deleted_at IS NULL', [id])) ??
        0;
    if (expenseCount > 0) {
      throw CategoryInUseException('This category is used by $expenseCount expense record(s). Move them to another category before deleting.');
    }
    final category = await getCategory(id);
    final name = category?.name ?? 'Unknown';
    await database.delete('category_keywords', where: 'category_id = ?', whereArgs: [id]);
    await database.delete('budgets', where: 'category_id = ?', whereArgs: [id]);
    await database.delete('categories', where: 'id = ?', whereArgs: [id]);
    await logActivity('category', 'Deleted category \'$name\'');
  }

  Future<void> createDefaultCategories() async {
    final existing = await getCategories();
    final existingNames = existing.map((c) => c.name.toLowerCase()).toSet();
    var created = 0;
    for (final cat in AppStrings.defaultCategories) {
      if (existingNames.contains(cat['name']!.toLowerCase())) continue;
      await addCategory(cat['name']!, color: cat['color']);
      created++;
    }
    if (created > 0) {
      await logActivity('settings', 'Created $created default categories');
    }
  }

  String _randomColor() {
    final random = Random();
    return AppColors.categoryColorPool[random.nextInt(AppColors.categoryColorPool.length)];
  }

  // ---------------------------------------------------------------------
  // Bill categories
  // ---------------------------------------------------------------------

  Future<List<BillCategory>> getBillCategories() async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query('bill_categories', orderBy: 'name ASC');
    return rows.map(BillCategory.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // Expenses
  // ---------------------------------------------------------------------

  Future<List<Expense>> getExpenses({
    String search = '',
    int? categoryId,
    String? dateFrom,
    String? dateTo,
    double? amountMin,
    double? amountMax,
    String? paymentMethod,
    bool withTrashed = false,
    int? limit,
  }) async {
    final database = await DatabaseHelper.instance.database;
    final conditions = <String>[];
    final args = <Object?>[];
    if (!withTrashed) conditions.add('e.deleted_at IS NULL');
    else conditions.add('e.deleted_at IS NOT NULL');
    if (search.isNotEmpty) {
      conditions.add('(e.description LIKE ? OR e.notes LIKE ?)');
      final s = '%$search%';
      args.add(s);
      args.add(s);
    }
    if (categoryId != null) {
      conditions.add('e.category_id = ?');
      args.add(categoryId);
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      conditions.add('e.expense_date >= ?');
      args.add(dateFrom);
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      conditions.add('e.expense_date <= ?');
      args.add(dateTo);
    }
    if (amountMin != null) {
      conditions.add('e.amount >= ?');
      args.add(amountMin);
    }
    if (amountMax != null) {
      conditions.add('e.amount <= ?');
      args.add(amountMax);
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      conditions.add('e.payment_method = ?');
      args.add(paymentMethod);
    }
    final where = conditions.join(' AND ');
    final orderBy = withTrashed ? 'e.deleted_at DESC' : 'e.expense_date DESC';
    final limitSql = limit != null ? ' LIMIT $limit' : '';
    final rows = await database.rawQuery('''
      SELECT e.*, c.name AS category_name, c.color AS category_color
      FROM expenses e
      LEFT JOIN categories c ON c.id = e.category_id
      WHERE $where
      ORDER BY $orderBy$limitSql
    ''', args);
    return rows.map(Expense.fromMap).toList();
  }

  Future<Expense?> getExpense(int id) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.rawQuery('''
      SELECT e.*, c.name AS category_name, c.color AS category_color
      FROM expenses e LEFT JOIN categories c ON c.id = e.category_id
      WHERE e.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    return Expense.fromMap(rows.first);
  }

  Future<ExpenseBudgetResult> saveExpense({
    int? id,
    required int categoryId,
    int? billCategoryId,
    required String description,
    required double amount,
    required String expenseDate,
    String notes = '',
    String paymentMethod = 'cash',
    String currencyCode = 'USD',
    String? receiptImage,
    String? billType,
    bool ignoreDuplicate = false,
  }) async {
    final database = await DatabaseHelper.instance.database;
    if (!ignoreDuplicate) {
      await _checkDuplicateExpense(database, categoryId, description, amount, expenseDate, excludeId: id);
    }
    final now = nowIso();
    final map = {
      'category_id': categoryId,
      'bill_category_id': billCategoryId,
      'description': description,
      'amount': amount,
      'expense_date': expenseDate,
      'notes': notes,
      'payment_method': paymentMethod,
      'currency_code': currencyCode,
      'receipt_image': receiptImage,
      'bill_type': billType,
    };
    int expenseId;
    if (id == null) {
      expenseId = await database.insert('expenses', {...map, 'created_at': now, 'updated_at': now});
    } else {
      await database.update('expenses', {...map, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
      expenseId = id;
    }
    await logActivity(
        'expense',
        id == null
            ? "Created expense '$description' ($currencyCode ${amount.toStringAsFixed(2)})"
            : "Updated expense '$description'");

    final budget = await _checkBudgetForCategory(categoryId);
    final expense = await getExpense(expenseId);
    return ExpenseBudgetResult(expense!, budget);
  }

  Future<void> _checkDuplicateExpense(Database database, int categoryId, String description, double amount, String expenseDate, {int? excludeId}) async {
    final rows = await database.rawQuery('''
      SELECT id FROM expenses WHERE deleted_at IS NULL
      AND LOWER(TRIM(description)) = ? AND amount = ? AND expense_date = ? AND category_id = ?
    ''', [description.trim().toLowerCase(), amount, expenseDate, categoryId]);
    if (rows.any((r) => r['id'] != excludeId)) {
      throw DuplicateTransactionException('A similar expense already exists. Submit again to confirm.');
    }
  }

  Future<Budget?> _checkBudgetForCategory(int categoryId) async {
    final budgets = await _getBudgetsByCategory(categoryId);
    if (budgets.isEmpty) return null;
    for (final budget in budgets) {
      final spent = await _budgetSpending(budget.categoryId, budget.period, budget.month, budget.year);
      if (spent > budget.limitAmount) {
        final catName = budget.categoryName ?? 'Category';
        final cur = await _preferredCurrencyCode();
        final overage = (spent - budget.limitAmount).toStringAsFixed(2);
        await addNotification(
          type: 'budget_exceeded',
          title: 'Budget Exceeded: $catName',
          body: 'You have spent ${formatMoney(spent, cur)} out of your ${budget.limitAmount.toStringAsFixed(2)} $cur budget for ${_budgetPeriodLabel(budget.period)}.',
          data: {'budget_id': budget.id, 'category_name': catName, 'overage': overage},
        );
        return budget;
      }
    }
    return null;
  }

  String _budgetPeriodLabel(String period) {
    switch (period) {
      case 'monthly':
        return 'month';
      case 'quarterly':
        return 'quarter';
      case 'yearly':
        return 'year';
      default:
        return 'period';
    }
  }

  Future<void> softDeleteExpenses(List<int> ids) async {
    final database = await DatabaseHelper.instance.database;
    for (final id in ids) {
      final expense = await getExpense(id);
      await database.update('expenses', {'deleted_at': nowIso()}, where: 'id = ?', whereArgs: [id]);
      await logActivity('expense', "Deleted expense '${expense?.description ?? ''}'");
    }
  }

  Future<void> restoreExpense(int id) async {
    final database = await DatabaseHelper.instance.database;
    final expense = await getExpense(id);
    await database.update('expenses', {'deleted_at': null}, where: 'id = ?', whereArgs: [id]);
    await logActivity('expense', "Restored expense '${expense?.description ?? ''}'");
  }

  Future<void> forceDeleteExpense(int id) async {
    final database = await DatabaseHelper.instance.database;
    final expense = await getExpense(id);
    await database.delete('receipts', where: 'expense_id = ?', whereArgs: [id]);
    await database.delete('expenses', where: 'id = ?', whereArgs: [id]);
    await logActivity('expense', "Permanently deleted expense '${expense?.description ?? ''}'");
  }

  // ---------------------------------------------------------------------
  // Income
  // ---------------------------------------------------------------------

  Future<List<Income>> getIncomes({
    String search = '',
    String? dateFrom,
    String? dateTo,
    double? amountMin,
    double? amountMax,
    String? paymentMethod,
    String? source,
    bool withTrashed = false,
    int? limit,
  }) async {
    final database = await DatabaseHelper.instance.database;
    final conditions = <String>[];
    final args = <Object?>[];
    if (!withTrashed) conditions.add('deleted_at IS NULL');
    else conditions.add('deleted_at IS NOT NULL');
    if (search.isNotEmpty) {
      conditions.add('(source LIKE ? OR notes LIKE ?)');
      final s = '%$search%';
      args.add(s);
      args.add(s);
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      conditions.add('income_date >= ?');
      args.add(dateFrom);
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      conditions.add('income_date <= ?');
      args.add(dateTo);
    }
    if (amountMin != null) {
      conditions.add('amount >= ?');
      args.add(amountMin);
    }
    if (amountMax != null) {
      conditions.add('amount <= ?');
      args.add(amountMax);
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      conditions.add('payment_method = ?');
      args.add(paymentMethod);
    }
    if (source != null && source.isNotEmpty) {
      conditions.add('source = ?');
      args.add(source);
    }
    final where = conditions.join(' AND ');
    final orderBy = withTrashed ? 'deleted_at DESC' : 'income_date DESC';
    final limitSql = limit != null ? ' LIMIT $limit' : '';
    final rows = await database.rawQuery('SELECT * FROM income WHERE $where ORDER BY $orderBy$limitSql', args);
    return rows.map(Income.fromMap).toList();
  }

  Future<Income?> getIncome(int id) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query('income', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Income.fromMap(rows.first);
  }

  Future<Income> saveIncome({
    int? id,
    required String source,
    required double amount,
    required String incomeDate,
    String notes = '',
    String paymentMethod = 'bank_transfer',
    String currencyCode = 'USD',
    bool ignoreDuplicate = false,
  }) async {
    final database = await DatabaseHelper.instance.database;
    if (!ignoreDuplicate) {
      final rows = await database.rawQuery('''
        SELECT id FROM income WHERE deleted_at IS NULL
        AND source = ? AND amount = ? AND income_date = ?
      ''', [source, amount, incomeDate]);
      if (rows.any((r) => r['id'] != id)) {
        throw DuplicateTransactionException('A similar income record already exists. Submit again to confirm.');
      }
    }
    final now = nowIso();
    final map = {
      'source': source,
      'amount': amount,
      'income_date': incomeDate,
      'notes': notes,
      'payment_method': paymentMethod,
      'currency_code': currencyCode,
    };
    int incomeId;
    if (id == null) {
      incomeId = await database.insert('income', {...map, 'created_at': now, 'updated_at': now});
    } else {
      await database.update('income', {...map, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
      incomeId = id;
    }
    await logActivity('income',
        id == null ? "Created income '$source' ($currencyCode ${amount.toStringAsFixed(2)})" : "Updated income '$source'");
    return (await getIncome(incomeId))!;
  }

  Future<void> softDeleteIncomes(List<int> ids) async {
    final database = await DatabaseHelper.instance.database;
    for (final id in ids) {
      final income = await getIncome(id);
      await database.update('income', {'deleted_at': nowIso()}, where: 'id = ?', whereArgs: [id]);
      await logActivity('income', "Deleted income '${income?.source ?? ''}'");
    }
  }

  Future<void> restoreIncome(int id) async {
    final database = await DatabaseHelper.instance.database;
    final income = await getIncome(id);
    await database.update('income', {'deleted_at': null}, where: 'id = ?', whereArgs: [id]);
    await logActivity('income', "Restored income '${income?.source ?? ''}'");
  }

  Future<void> forceDeleteIncome(int id) async {
    final database = await DatabaseHelper.instance.database;
    final income = await getIncome(id);
    await database.delete('income', where: 'id = ?', whereArgs: [id]);
    await logActivity('income', "Permanently deleted income '${income?.source ?? ''}'");
  }

  // ---------------------------------------------------------------------
  // Budgets
  // ---------------------------------------------------------------------

  Future<List<Budget>> _getBudgetsByCategory(int categoryId) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.rawQuery('''
      SELECT b.*, c.name AS category_name, c.color AS category_color
      FROM budgets b LEFT JOIN categories c ON c.id = b.category_id
      WHERE b.category_id = ?
    ''', [categoryId]);
    return rows.map(Budget.fromMap).toList();
  }

  Future<List<Budget>> getBudgets() async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.rawQuery('''
      SELECT b.*, c.name AS category_name, c.color AS category_color
      FROM budgets b LEFT JOIN categories c ON c.id = b.category_id
      ORDER BY c.name ASC
    ''');
    return rows.map(Budget.fromMap).toList();
  }

  Future<Budget?> getBudget(int id) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.rawQuery('''
      SELECT b.*, c.name AS category_name, c.color AS category_color
      FROM budgets b LEFT JOIN categories c ON c.id = b.category_id
      WHERE b.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
  }

  Future<Budget> saveBudget({
    int? id,
    required int categoryId,
    required double limitAmount,
    String period = 'monthly',
    int? month,
    int? year,
    String notes = '',
    bool carryoverEnabled = false,
  }) async {
    final database = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final effectiveYear = year ?? now.year;
    final map = {
      'category_id': categoryId,
      'limit_amount': limitAmount,
      'period': period,
      'month': month,
      'year': effectiveYear,
      'notes': notes,
      'carryover_enabled': carryoverEnabled ? 1 : 0,
      'carryover_amount': 0,
    };
    int budgetId;
    if (id == null) {
      budgetId = await database.insert('budgets', {...map, 'created_at': nowIso()});
      final cat = await getCategory(categoryId);
      await logActivity('budget', "Created budget '${cat?.name ?? 'Unknown'}' ($limitAmount)");
    } else {
      await database.update('budgets', map, where: 'id = ?', whereArgs: [id]);
      budgetId = id;
      final cat = await getCategory(categoryId);
      await logActivity('budget', "Updated budget '${cat?.name ?? 'Unknown'}'");
    }
    return (await getBudget(budgetId))!;
  }

  Future<void> deleteBudget(int id) async {
    final database = await DatabaseHelper.instance.database;
    final budget = await getBudget(id);
    await database.delete('budgets', where: 'id = ?', whereArgs: [id]);
    await logActivity('budget', "Deleted budget '${budget?.categoryName ?? 'Unknown'}'");
  }

  Future<double> _budgetSpending(int categoryId, String period, int? month, int? year) async {
    final database = await DatabaseHelper.instance.database;
    final args = <Object?>[categoryId];
    String dateClause = '';
    if (period == 'monthly' && month != null) {
      final y = year ?? DateTime.now().year;
      dateClause = 'AND date(expense_date) >= date(?) AND date(expense_date) <= date(?)';
      final start = DateTime(y, month, 1);
      final end = DateTime(y, month + 1, 0);
      args.add(start.toIso8601String().substring(0, 10));
      args.add(end.toIso8601String().substring(0, 10));
    }
    final res = await database.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total FROM expenses
      WHERE category_id = ? AND deleted_at IS NULL $dateClause
    ''', args);
    return (res.first['total'] as num).toDouble();
  }

  Future<List<BudgetSpending>> getBudgetSpendings() async {
    final budgets = await getBudgets();
    final result = <BudgetSpending>[];
    for (final b in budgets) {
      result.add(BudgetSpending(b, await _budgetSpending(b.categoryId, b.period, b.month, b.year)));
    }
    return result;
  }

  Future<void> applyRollovers() async {
    final database = await DatabaseHelper.instance.database;
    final budgets = await getBudgets();
    final now = DateTime.now();
    for (final b in budgets) {
      if (!b.carryoverEnabled) continue;
      final periodEnd = _periodEndDate(b);
      if (periodEnd == null || !now.isAfter(periodEnd)) continue;
      final spent = await _budgetSpending(b.categoryId, b.period, b.month, b.year);
      final surplus = max(0.0, b.effectiveLimit - spent);
      if (surplus <= 0) continue;
      final next = _nextPeriod(b);
      if (next == null) continue;
      await database.rawUpdate('''
        UPDATE budgets SET carryover_amount = ?, carried_over_from = ? 
        WHERE category_id = ? AND period = ? AND month = ? AND year = ?
      ''', [surplus, _todayStr(), b.categoryId, b.period, next['month'], next['year']]);
    }
  }

  DateTime? _periodEndDate(Budget b) {
    final year = b.year;
    if (year == null) return null;
    switch (b.period) {
      case 'monthly':
        return DateTime(year, (b.month ?? 1) + 1, 0);
      case 'quarterly':
        return DateTime(year, (b.month ?? 1) + 3, 0);
      case 'yearly':
        return DateTime(year, 12, 31);
      default:
        return null;
    }
  }

  Map<String, int>? _nextPeriod(Budget b) {
    final year = b.year;
    var month = b.month ?? 1;
    switch (b.period) {
      case 'monthly':
        var m = month + 1;
        var y = year ?? DateTime.now().year;
        if (m > 12) {
          m = 1;
          y++;
        }
        return {'month': m, 'year': y};
      case 'quarterly':
        var m = month + 3;
        var y = year ?? DateTime.now().year;
        if (m > 12) {
          m -= 12;
          y++;
        }
        return {'month': m, 'year': y};
      case 'yearly':
        return {'month': 1, 'year': (year ?? DateTime.now().year) + 1};
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------
  // Savings goals
  // ---------------------------------------------------------------------

  Future<List<SavingsGoal>> getGoals({String search = '', String? status}) async {
    final database = await DatabaseHelper.instance.database;
    final conditions = <String>['deleted_at IS NULL'];
    final args = <Object?>[];
    if (search.isNotEmpty) {
      conditions.add('(title LIKE ? OR description LIKE ?)');
      final s = '%$search%';
      args.add(s);
      args.add(s);
    }
    if (status != null && status.isNotEmpty) {
      conditions.add('status = ?');
      args.add(status);
    }
    final rows = await database.query(
      'savings_goals',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return rows.map(SavingsGoal.fromMap).toList();
  }

  Future<SavingsGoal?> getGoal(int id) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query('savings_goals', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return SavingsGoal.fromMap(rows.first);
  }

  Future<GoalProgressResult> saveGoal({
    int? id,
    required String title,
    String description = '',
    required double targetAmount,
    double? currentAmount,
    String? targetDate,
    String? category,
    String? status,
  }) async {
    final database = await DatabaseHelper.instance.database;
    final existing = id != null ? await getGoal(id) : null;
    final now = nowIso();
    final amount = currentAmount ?? (existing?.currentAmount ?? 0);
    var goalStatus = status ?? existing?.status ?? 'active';

    if (id == null) {
      final g = SavingsGoal(
        title: title,
        description: description,
        targetAmount: targetAmount,
        currentAmount: amount,
        targetDate: targetDate,
        category: category,
        status: goalStatus,
      );
      final newId = await database.insert('savings_goals', {...g.toMap(), 'id': null, 'created_at': now, 'updated_at': now});
      await logActivity('savings_goal', "Created savings goal '$title'");
      final created = SavingsGoal(
        id: newId,
        title: title,
        description: description,
        targetAmount: targetAmount,
        currentAmount: amount,
        targetDate: targetDate,
        category: category,
        status: goalStatus,
        createdAt: now,
      );
      final completed = created.isCompleted;
      if (completed) {
        await _ensureGoalStatus(newId, 'completed');
        await _notifyGoalCompleted(created);
        await logActivity('savings_goal', "Marked goal '$title' as completed");
      }
      return GoalProgressResult(created, completed ? [100] : [], completed);
    }

    final oldProgress = (existing?.progressPercentage ?? 0).floor();
    final goalMap = {
      'title': title,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': amount,
      'target_date': targetDate,
      'category': category,
      'status': goalStatus,
      'updated_at': now,
    };
    await database.update('savings_goals', goalMap, where: 'id = ?', whereArgs: [id]);
    await logActivity('savings_goal', "Updated savings goal '$title'");

    final updated = SavingsGoal(
      id: id,
      title: title,
      description: description,
      targetAmount: targetAmount,
      currentAmount: amount,
      targetDate: targetDate,
      category: category,
      status: goalStatus,
      createdAt: existing?.createdAt ?? now,
    );
    final newProgress = updated.progressPercentage.floor();
    final milestones = await _checkMilestones(oldProgress, newProgress, updated);

    var completed = false;
    if (updated.isCompleted && updated.status != 'completed') {
      await _ensureGoalStatus(id, 'completed');
      goalStatus = 'completed';
      completed = true;
      await _notifyGoalCompleted(updated);
      await logActivity('savings_goal', "Marked goal '$title' as completed");
    }
    return GoalProgressResult(updated, milestones, completed);
  }

  Future<GoalProgressResult> addGoalAmount(int goalId, double amount) async {
    final database = await DatabaseHelper.instance.database;
    final goal = await getGoal(goalId);
    if (goal == null) throw Exception('Goal not found');
    final oldProgress = goal.progressPercentage.floor();
    final newAmount = min(goal.currentAmount + amount, goal.targetAmount).toDouble();
    final newStatus = newAmount >= goal.targetAmount ? 'completed' : goal.status;
    await database.update('savings_goals', {
      'current_amount': newAmount,
      'status': newStatus,
      'updated_at': nowIso(),
    }, where: 'id = ?', whereArgs: [goalId]);
    final updated = SavingsGoal(
      id: goalId,
      title: goal.title,
      description: goal.description,
      targetAmount: goal.targetAmount,
      currentAmount: newAmount,
      targetDate: goal.targetDate,
      category: goal.category,
      status: newStatus,
      createdAt: goal.createdAt,
    );
    final milestones = await _checkMilestones(oldProgress, updated.progressPercentage.floor(), updated);
    await logActivity('savings_goal', "Added ${amount.toStringAsFixed(2)} to goal '${goal.title}'");
    final completed = newStatus == 'completed' && goal.status != 'completed';
    if (completed) {
      await _notifyGoalCompleted(updated);
    }
    return GoalProgressResult(updated, milestones, completed);
  }

  Future<void> subtractGoalAmount(int goalId, double amount) async {
    final database = await DatabaseHelper.instance.database;
    final goal = await getGoal(goalId);
    if (goal == null) throw Exception('Goal not found');
    final newAmount = max(0.0, goal.currentAmount - amount);
    await database.update('savings_goals', {
      'current_amount': newAmount,
      'updated_at': nowIso(),
    }, where: 'id = ?', whereArgs: [goalId]);
    await logActivity('savings_goal', "Subtracted ${amount.toStringAsFixed(2)} from goal '${goal.title}'");
  }

  Future<void> markGoalCompleted(int goalId) async {
    final database = await DatabaseHelper.instance.database;
    final goal = await getGoal(goalId);
    if (goal == null) return;
    if (goal.isCompleted && goal.status == 'completed') return;
    await database.update('savings_goals', {
      'status': 'completed',
      'current_amount': goal.targetAmount,
      'updated_at': nowIso(),
    }, where: 'id = ?', whereArgs: [goalId]);
    final updated = goal.copyWith(status: 'completed', currentAmount: goal.targetAmount);
    await _notifyGoalCompleted(updated);
    await logActivity('savings_goal', "Marked goal '${goal.title}' as completed");
  }

  Future<void> pauseGoal(int goalId) async {
    final database = await DatabaseHelper.instance.database;
    await database.update('savings_goals', {'status': 'paused', 'updated_at': nowIso()}, where: 'id = ?', whereArgs: [goalId]);
  }

  Future<void> resumeGoal(int goalId) async {
    final database = await DatabaseHelper.instance.database;
    await database.update('savings_goals', {'status': 'active', 'updated_at': nowIso()}, where: 'id = ?', whereArgs: [goalId]);
  }

  Future<void> _ensureGoalStatus(int id, String status) async {
    final database = await DatabaseHelper.instance.database;
    await database.update('savings_goals', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _notifyGoalCompleted(SavingsGoal goal) async {
    final cur = await _preferredCurrencyCode();
    await addNotification(
      type: 'goal_completed',
      title: 'Goal Completed: ${goal.title}',
      body: 'Congratulations! You have saved ${formatMoney(goal.targetAmount, cur)} towards ${goal.title}.',
      data: {'goal_id': goal.id, 'title': goal.title},
    );
  }

  Future<void> _notifyMilestone(int milestone, SavingsGoal goal) async {
    await addNotification(
      type: 'goal_milestone',
      title: '$milestone% of Goal Reached: ${goal.title}',
      body: 'You have reached $milestone% of your savings goal ${goal.title}. Keep it up!',
      data: {'goal_id': goal.id, 'milestone': milestone, 'title': goal.title},
    );
  }

  Future<List<int>> _checkMilestones(int oldProgress, int newProgress, SavingsGoal goal) async {
    const milestones = [50, 75, 100];
    final crossed = <int>[];
    for (final m in milestones) {
      if (oldProgress < m && newProgress >= m) {
        crossed.add(m);
        await _notifyMilestone(m, goal);
      }
    }
    return crossed;
  }

  Future<void> deleteGoal(int id) async {
    final database = await DatabaseHelper.instance.database;
    final goal = await getGoal(id);
    await database.update('savings_goals', {'deleted_at': nowIso()}, where: 'id = ?', whereArgs: [id]);
    await logActivity('savings_goal', "Deleted savings goal '${goal?.title ?? ''}'");
  }

  Future<void> restoreGoal(int id) async {
    final database = await DatabaseHelper.instance.database;
    await database.update('savings_goals', {'deleted_at': null}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> forceDeleteGoal(int id) async {
    final database = await DatabaseHelper.instance.database;
    await database.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // Recurring transactions
  // ---------------------------------------------------------------------

  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.rawQuery('''
      SELECT r.*, c.name AS category_name, c.color AS category_color
      FROM recurring_transactions r LEFT JOIN categories c ON c.id = r.category_id
      WHERE r.deleted_at IS NULL
      ORDER BY r.next_due_date ASC
    ''');
    return rows.map(RecurringTransaction.fromMap).toList();
  }

  Future<RecurringTransaction?> getRecurringTransaction(int id) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.rawQuery('''
      SELECT r.*, c.name AS category_name, c.color AS category_color
      FROM recurring_transactions r LEFT JOIN categories c ON c.id = r.category_id
      WHERE r.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    return RecurringTransaction.fromMap(rows.first);
  }

  Future<RecurringTransaction> saveRecurringTransaction({
    int? id,
    required int categoryId,
    int? billCategoryId,
    required String description,
    required double amount,
    String paymentMethod = 'cash',
    String notes = '',
    String frequency = 'monthly',
    int? dayOfMonth,
    required String nextDueDate,
    String? endDate,
    int? maxOccurrences,
  }) async {
    final database = await DatabaseHelper.instance.database;
    final now = nowIso();
    final map = {
      'category_id': categoryId,
      'bill_category_id': billCategoryId,
      'description': description,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'frequency': frequency,
      'day_of_month': dayOfMonth,
      'next_due_date': nextDueDate,
      'end_date': endDate,
      'max_occurrences': maxOccurrences,
    };
    int recurringId;
    if (id == null) {
      recurringId = await database.insert('recurring_transactions', {
        ...map,
        'status': 'active',
        'occurrences_generated': 0,
        'created_at': now,
        'updated_at': now,
      });
      await logActivity('recurring', "Created recurring transaction '$description'");
    } else {
      await database.update('recurring_transactions', {...map, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
      recurringId = id;
      await logActivity('recurring', "Updated recurring transaction '$description'");
    }
    return (await getRecurringTransaction(recurringId))!;
  }

  Future<void> pauseRecurring(int id) async {
    final database = await DatabaseHelper.instance.database;
    final rt = await getRecurringTransaction(id);
    await database.update('recurring_transactions', {'status': 'paused', 'updated_at': nowIso()}, where: 'id = ?', whereArgs: [id]);
    await logActivity('recurring', "Paused recurring transaction '${rt?.description ?? ''}'");
  }

  Future<void> resumeRecurring(int id) async {
    final database = await DatabaseHelper.instance.database;
    final rt = await getRecurringTransaction(id);
    await database.update('recurring_transactions', {'status': 'active', 'updated_at': nowIso()}, where: 'id = ?', whereArgs: [id]);
    await logActivity('recurring', "Resumed recurring transaction '${rt?.description ?? ''}'");
  }

  Future<void> deleteRecurring(int id) async {
    final database = await DatabaseHelper.instance.database;
    final rt = await getRecurringTransaction(id);
    await database.update('recurring_transactions', {'deleted_at': nowIso()}, where: 'id = ?', whereArgs: [id]);
    await logActivity('recurring', "Deleted recurring transaction '${rt?.description ?? ''}'");
  }

  bool isRecurringDue(RecurringTransaction rt, String today) {
    if (rt.status != 'active') return false;
    if (rt.nextDueDate.compareTo(today) > 0) return false;
    if (rt.endDate != null && rt.endDate!.compareTo(today) < 0) return false;
    if (rt.maxOccurrences != null && rt.occurrencesGenerated >= rt.maxOccurrences!) return false;
    return true;
  }

  String _nextDueDate(String current, String frequency) {
    final base = DateTime.tryParse(current);
    final date = (base ?? DateTime.now()).toLocal();
    switch (frequency) {
      case 'daily':
        return DateTime(date.year, date.month, date.day + 1).toIso8601String().substring(0, 10);
      case 'weekly':
        return DateTime(date.year, date.month, date.day + 7).toIso8601String().substring(0, 10);
      case 'yearly':
        return DateTime(date.year + 1, date.month, date.day).toIso8601String().substring(0, 10);
      case 'monthly':
      default:
        return DateTime(date.year, date.month + 1, date.day).toIso8601String().substring(0, 10);
    }
  }

  Future<List<RecurringTransaction>> generateDueRecurring() async {
    final database = await DatabaseHelper.instance.database;
    final today = _todayStr();
    final all = await getRecurringTransactions();
    final generated = <RecurringTransaction>[];
    for (final rt in all) {
      if (!isRecurringDue(rt, today)) continue;
      final expenseId = await database.insert('expenses', {
        'category_id': rt.categoryId,
        'bill_category_id': rt.billCategoryId,
        'description': rt.description,
        'amount': rt.amount,
        'expense_date': rt.nextDueDate,
        'notes': rt.notes,
        'payment_method': rt.paymentMethod,
        'currency_code': await _preferredCurrencyCode(),
        'created_at': nowIso(),
        'updated_at': nowIso(),
      });
      final newDue = _nextDueDate(rt.nextDueDate, rt.frequency);
      final newCount = rt.occurrencesGenerated + 1;
      var status = rt.status;
      if (rt.maxOccurrences != null && newCount >= rt.maxOccurrences!) status = 'completed';
      if (rt.endDate != null && newDue.compareTo(rt.endDate!) > 0) status = 'completed';
      await database.update('recurring_transactions', {
        'last_generated_date': rt.nextDueDate,
        'next_due_date': newDue,
        'occurrences_generated': newCount,
        'status': status,
        'last_expense_id': expenseId,
        'updated_at': nowIso(),
      }, where: 'id = ?', whereArgs: [rt.id]);
      await logActivity('recurring', "Generated expense '${rt.description}' from recurring transaction");
      final updated = await getRecurringTransaction(rt.id!);
      if (updated != null) generated.add(updated);
    }
    return generated;
  }

  // ---------------------------------------------------------------------
  // Receipts
  // ---------------------------------------------------------------------

  Future<List<Receipt>> getReceipts() async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.rawQuery('''
      SELECT r.*, e.description AS expense_description
      FROM receipts r LEFT JOIN expenses e ON e.id = r.expense_id
      WHERE r.deleted_at IS NULL
      ORDER BY r.created_at DESC
    ''');
    return rows.map(Receipt.fromMap).toList();
  }

  Future<Receipt?> getReceipt(int id) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.rawQuery('''
      SELECT r.*, e.description AS expense_description
      FROM receipts r LEFT JOIN expenses e ON e.id = r.expense_id
      WHERE r.id = ? LIMIT 1
    ''', [id]);
    if (rows.isEmpty) return null;
    return Receipt.fromMap(rows.first);
  }

  Future<Receipt> addReceipt({
    int? expenseId,
    required String filePath,
    required String fileName,
    int fileSize = 0,
    String mimeType = 'image/jpeg',
    String? ocrText,
  }) async {
    final database = await DatabaseHelper.instance.database;
    final hasOcr = ocrText != null && ocrText.trim().isNotEmpty;
    final id = await database.insert('receipts', {
      'expense_id': expenseId,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'ocr_text': hasOcr ? ocrText : null,
      'is_processed': hasOcr ? 1 : 0,
      'processing_status': hasOcr ? 'processed' : 'pending',
      'created_at': nowIso(),
    });
    await logActivity('receipt', "Saved receipt '$fileName'${hasOcr ? ' with OCR text' : ''}");
    return (await getReceipt(id))!;
  }

  Future<void> markReceiptProcessed(int id, {String? ocrText}) async {
    final database = await DatabaseHelper.instance.database;
    await database.update('receipts', {
      'is_processed': 1,
      'processing_status': 'processed',
      if (ocrText != null) 'ocr_text': ocrText,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteReceipt(int id) async {
    final database = await DatabaseHelper.instance.database;
    final receipt = await getReceipt(id);
    await database.update('receipts', {'deleted_at': nowIso()}, where: 'id = ?', whereArgs: [id]);
    await logActivity('receipt', "Deleted receipt '${receipt?.fileName ?? ''}'");
  }

  // ---------------------------------------------------------------------
  // TrackMe Assistant chat
  // ---------------------------------------------------------------------

  Future<List<ChatMessage>> getChatMessages() async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query('chat_messages', orderBy: 'created_at ASC, id ASC');
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<ChatMessage> addChatMessage({
    required String role,
    required String text,
    String kind = 'text',
    String? payload,
  }) async {
    final database = await DatabaseHelper.instance.database;
    final id = await database.insert('chat_messages', {
      'role': role,
      'kind': kind,
      'text': text,
      'payload': payload,
      'created_at': nowIso(),
    });
    final rows = await database.query('chat_messages', where: 'id = ?', whereArgs: [id], limit: 1);
    return ChatMessage.fromMap(rows.first);
  }

  Future<void> clearChat() async {
    final database = await DatabaseHelper.instance.database;
    await database.delete('chat_messages');
  }

  // ---------------------------------------------------------------------
  // Currencies (offline with manually editable rates)
  // ---------------------------------------------------------------------

  Future<List<UserCurrency>> getCurrencies() async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query('user_currencies', orderBy: 'is_primary DESC, currency_code ASC');
    return rows.map(UserCurrency.fromMap).toList();
  }

  Future<String> _preferredCurrencyCode() async {
    final user = await getUser();
    return user.preferredCurrency;
  }

  Future<void> addCurrency(String code) async {
    final database = await DatabaseHelper.instance.database;
    final c = code.toUpperCase();
    final existing = await database.query('user_currencies', where: 'currency_code = ?', whereArgs: [c], limit: 1);
    if (existing.isNotEmpty) return;
    await database.insert('user_currencies', {
      'currency_code': c,
      'exchange_rate': defaultRates[c] ?? 1.0,
      'is_primary': 0,
      'last_updated': nowIso(),
      'created_at': nowIso(),
    });
    await logActivity('currency', 'Added currency $c');
  }

  Future<void> setPrimaryCurrency(String code) async {
    final database = await DatabaseHelper.instance.database;
    final c = code.toUpperCase();
    await database.rawUpdate('UPDATE user_currencies SET is_primary = 0');
    final existing = await database.query('user_currencies', where: 'currency_code = ?', whereArgs: [c], limit: 1);
    if (existing.isEmpty) {
      await database.insert('user_currencies', {
        'currency_code': c,
        'exchange_rate': 1.0,
        'is_primary': 1,
        'last_updated': nowIso(),
        'created_at': nowIso(),
      });
    } else {
      await database.update('user_currencies', {'is_primary': 1}, where: 'currency_code = ?', whereArgs: [c]);
    }
    await updateProfile(preferredCurrency: c);
    await logActivity('currency', 'Set $c as primary currency');
  }

  Future<void> updateCurrencyRate(String code, double rate) async {
    final database = await DatabaseHelper.instance.database;
    await database.update('user_currencies', {
      'exchange_rate': rate,
      'last_updated': nowIso(),
    }, where: 'currency_code = ?', whereArgs: [code.toUpperCase()]);
  }

  Future<double> convert(double amount, String from, String to) async {
    if (from.toUpperCase() == to.toUpperCase()) return amount;
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query('user_currencies',
        where: 'currency_code IN (?, ?)', whereArgs: [from.toUpperCase(), to.toUpperCase()], orderBy: 'currency_code');
    double rateFrom = 1.0;
    double rateTo = 1.0;
    for (final r in rows) {
      final code = r['currency_code'] as String;
      final rate = (r['exchange_rate'] as num?)?.toDouble() ?? 1.0;
      if (code == from.toUpperCase()) rateFrom = rate;
      if (code == to.toUpperCase()) rateTo = rate;
    }
    if (!rows.any((r) => r['currency_code'] == from.toUpperCase()) && !rows.any((r) => r['currency_code'] == to.toUpperCase())) {
      final defaultFrom = defaultRates[from.toUpperCase()] ?? 1.0;
      final defaultTo = defaultRates[to.toUpperCase()] ?? 1.0;
      return double.parse((amount * defaultTo / defaultFrom).toStringAsFixed(2));
    }
    if (rateFrom <= 0) rateFrom = 1;
    if (rateTo <= 0) rateTo = 1;
    return double.parse((amount * rateTo / rateFrom).toStringAsFixed(2));
  }

  static const Map<String, double> defaultRates = {
    'USD': 1.0, 'EUR': 0.85, 'GBP': 0.73, 'JPY': 156.2, 'PHP': 56.4,
    'AUD': 1.38, 'CAD': 1.24, 'SGD': 1.27, 'HKD': 7.82, 'INR': 83.5,
    'THB': 36.2, 'MYR': 4.21, 'IDR': 16500.0, 'VND': 25400.0, 'CNY': 7.11,
    'CHF': 0.91, 'SEK': 10.9, 'NOK': 10.8, 'DKK': 6.34, 'BRL': 4.92,
    'MXN': 17.1, 'NZD': 1.51, 'KRW': 1380.0, 'TWD': 32.4, 'AED': 3.67,
    'SAR': 3.75, 'ZAR': 18.3, 'ARS': 900.0,
  };

  // ---------------------------------------------------------------------
  // Auto-categorization keywords
  // ---------------------------------------------------------------------

  Future<List<CategoryKeyword>> getKeywords() async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.rawQuery('''
      SELECT k.*, c.name AS category_name
      FROM category_keywords k LEFT JOIN categories c ON c.id = k.category_id
      ORDER BY k.priority DESC
    ''');
    return rows.map(CategoryKeyword.fromMap).toList();
  }

  Future<void> addKeyword(int categoryId, String keyword, {int priority = 5}) async {
    final database = await DatabaseHelper.instance.database;
    await database.insert('category_keywords', {
      'category_id': categoryId,
      'keyword': keyword.trim().toLowerCase(),
      'priority': priority,
      'created_at': nowIso(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    final cat = await getCategory(categoryId);
    await logActivity('auto-categorization', "Added keyword '${keyword.trim().toLowerCase()}' to ${cat?.name ?? 'category'}");
  }

  Future<void> updateKeyword(int id, int priority) async {
    final database = await DatabaseHelper.instance.database;
    await database.update('category_keywords', {
      'priority': priority,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> removeKeyword(int id) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query('category_keywords', where: 'id = ?', whereArgs: [id], limit: 1);
    final kw = rows.isNotEmpty ? rows.first['keyword'] : '';
    await database.delete('category_keywords', where: 'id = ?', whereArgs: [id]);
    await logActivity('auto-categorization', "Removed keyword '$kw'");
  }

  Future<int?> autoCategorize(String description) async {
    final database = await DatabaseHelper.instance.database;
    final text = description.trim().toLowerCase();
    if (text.isEmpty) return null;
    final words = text.split(RegExp(r'\s+'));
    final keywords = await database.query('category_keywords');
    final scores = <int, int>{};
    for (final row in keywords) {
      final categoryId = row['category_id'] as int;
      final keyword = (row['keyword'] as String).toLowerCase();
      final priority = (row['priority'] as num?)?.toInt() ?? 1;
      if (text.contains(keyword)) {
        scores[categoryId] = (scores[categoryId] ?? 0) + priority;
      }
      for (final word in words) {
        if (word == keyword) {
          scores[categoryId] = (scores[categoryId] ?? 0) + priority;
        }
      }
    }
    if (scores.isEmpty) return null;
    final sorted = scores.entries.toList()
      ..sort((a, b) {
        final byScore = b.value.compareTo(a.value);
        if (byScore != 0) return byScore;
        return 0;
      });
    return sorted.first.key;
  }

  Future<void> setupDefaultKeywords() async {
    const defaults = {
      'Food': ['restaurant', 'cafe', 'grocery', 'supermarket', 'pizza', 'burger', 'lunch', 'dinner', 'breakfast', 'food', 'market', 'bakery'],
      'Entertainment': ['movie', 'cinema', 'concert', 'game', 'music', 'spotify', 'netflix', 'entertainment', 'theater'],
      'Healthcare': ['doctor', 'pharmacy', 'medicine', 'hospital', 'health', 'dental', 'clinic', 'medical'],
      'Transportation': ['taxi', 'uber', 'bus', 'train', 'gas', 'fuel', 'parking', 'transport', 'metro', 'autobus'],
      'Bills': ['electric', 'water', 'internet', 'phone', 'utility', 'bill', 'broadband'],
      'Shopping': ['amazon', 'mall', 'store', 'shop', 'clothing', 'apparel', 'department', 'retail'],
    };
    final db = await DatabaseHelper.instance.database;
    for (final entry in defaults.entries) {
      final cat = await getCategoryByName(entry.key);
      if (cat == null || cat.id == null) continue;
      final keywords = entry.value;
      for (var i = 0; i < keywords.length; i++) {
        final existing = await db.query('category_keywords',
            where: 'keyword = ?', whereArgs: [keywords[i]], limit: 1);
        if (existing.isNotEmpty) continue;
        await db.insert('category_keywords', {
          'category_id': cat.id,
          'keyword': keywords[i],
          'priority': keywords.length - i,
          'created_at': nowIso(),
        });
      }
    }
    await logActivity('auto-categorization', 'Setup default keywords');
  }

  // ---------------------------------------------------------------------
  // Loans & repayments
  // ---------------------------------------------------------------------

  Future<List<Loan>> getLoans() async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query(
      'user_loans',
      where: 'deleted_at IS NULL',
      orderBy: 'paid_off ASC, start_date DESC',
    );
    return rows.map(Loan.fromMap).toList();
  }

  Future<Loan?> getLoan(int id) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query(
      'user_loans',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Loan.fromMap(rows.first);
  }

  Future<Loan> saveLoan({
    int? id,
    required String name,
    String? lender,
    required double principal,
    required double annualInterestRate,
    required int termMonths,
    required String startDate,
    required int paymentDay,
    String paymentMethod = 'bank_transfer',
    String notes = '',
    bool paidOff = false,
  }) async {
    final database = await DatabaseHelper.instance.database;
    final now = nowIso();
    final map = {
      'name': name,
      'lender': lender,
      'principal': principal,
      'annual_interest_rate': annualInterestRate,
      'term_months': termMonths,
      'start_date': startDate,
      'payment_day': paymentDay,
      'payment_method': paymentMethod,
      'notes': notes,
      'paid_off': paidOff ? 1 : 0,
    };
    int loanId;
    if (id == null) {
      loanId = await database.insert('user_loans', {...map, 'created_at': now, 'updated_at': now});
    } else {
      await database.update('user_loans', {...map, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
      loanId = id;
    }
    await _regenerateScheduleIfNeeded(database, loanId, termMonths);
    await logActivity('loan', id == null ? "Created loan '$name'" : "Updated loan '$name'");
    return (await getLoan(loanId))!;
  }

  Future<void> _regenerateScheduleIfNeeded(Database database, int loanId, int newTermMonths) async {
    final paid = await database.query(
      'loan_payments',
      where: 'loan_id = ? AND status = ?',
      whereArgs: [loanId, 'paid'],
    );
    if (paid.isNotEmpty) return;
    final loan = await getLoan(loanId);
    if (loan == null) return;
    await database.delete('loan_payments', where: 'loan_id = ?', whereArgs: [loanId]);
    final schedule = loanSchedule(
      principal: loan.principal,
      annualRate: loan.annualInterestRate,
      termMonths: loan.termMonths,
      startMonth: DateTime.tryParse(loan.startDate) ?? DateTime.now(),
      paymentDay: loan.paymentDay,
    );
    for (final row in schedule) {
      await database.insert('loan_payments', {
        'loan_id': loanId,
        'due_date': row.dueDate.toIso8601String().substring(0, 10),
        'amount_due': row.payment,
        'principal_paid': row.principal,
        'interest_paid': row.interest,
        'status': 'upcoming',
        'created_at': nowIso(),
      });
    }
  }

  Future<void> deleteLoan(int id) async {
    final database = await DatabaseHelper.instance.database;
    final loan = await getLoan(id);
    await database.update('user_loans', {'deleted_at': nowIso()}, where: 'id = ?', whereArgs: [id]);
    await logActivity('loan', "Deleted loan '${loan?.name}'");
  }

  Future<List<LoanPayment>> getLoanPayments(int loanId) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query(
      'loan_payments',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'due_date ASC',
    );
    return rows.map(LoanPayment.fromMap).toList();
  }

  Future<LoanPayment> markLoanPaymentPaid(int paymentId, {bool recordExpense = true}) async {
    final database = await DatabaseHelper.instance.database;
    final payment = await _getLoanPayment(paymentId);
    if (payment == null) throw StateError('Loan payment not found');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final updated = <String, dynamic>{
      'status': 'paid',
      'paid_date': today,
    };
    int? expenseId;
    if (recordExpense) {
      final loan = await getLoan(payment.loanId);
      if (loan != null) {
        final cat = await _loanPaymentCategory();
        final result = await saveExpense(
          categoryId: cat.id!,
          description: 'Loan payment: ${loan.name}',
          amount: payment.amountDue,
          expenseDate: today,
          paymentMethod: loan.paymentMethod,
          currencyCode: await _preferredCurrencyCode(),
          ignoreDuplicate: true,
        );
        expenseId = result.expense.id;
      }
    }
    if (expenseId != null) updated['expense_id'] = expenseId;
    await database.update('loan_payments', updated, where: 'id = ?', whereArgs: [paymentId]);

    final all = await getLoanPayments(payment.loanId);
    final paidCount = all.where((p) => p.status == 'paid').length;
    if (paidCount >= all.length && all.isNotEmpty) {
      await database.update('user_loans', {'paid_off': 1, 'updated_at': nowIso()},
          where: 'id = ?', whereArgs: [payment.loanId]);
      final loan = await getLoan(payment.loanId);
      if (loan != null) {
        await addNotification(
          type: 'loan',
          title: 'Loan paid off',
          body: 'Congratulations! "${loan.name}" is fully paid.',
          data: {'loan_id': loan.id, 'loan_name': loan.name},
        );
      }
    }
    await logActivity('loan', 'Recorded loan payment of ${payment.amountDue.toStringAsFixed(2)}');
    return (await _getLoanPayment(paymentId))!;
  }

  Future<void> undoLoanPayment(int paymentId) async {
    final database = await DatabaseHelper.instance.database;
    final payment = await _getLoanPayment(paymentId);
    if (payment == null) return;
    await database.update('loan_payments', {
      'status': 'upcoming',
      'paid_date': null,
      'expense_id': null,
    }, where: 'id = ?', whereArgs: [paymentId]);
    if (payment.expenseId != null) {
      final loan = await getLoan(payment.loanId);
      if (loan != null) {
        await database.update('user_loans', {'paid_off': 0, 'updated_at': nowIso()},
            where: 'id = ?', whereArgs: [payment.loanId]);
      }
    }
    await logActivity('loan', 'Undid loan payment');
  }

  Future<LoanPayment?> _getLoanPayment(int paymentId) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query('loan_payments', where: 'id = ?', whereArgs: [paymentId], limit: 1);
    if (rows.isEmpty) return null;
    return LoanPayment.fromMap(rows.first);
  }

  Future<Category> _loanPaymentCategory() async {
    final existing = await getCategoryByName('Loan Payment');
    if (existing != null) return existing;
    return addCategory('Loan Payment', color: '#B7791F');
  }

  Future<double> averageMonthlyIncome({int monthsBack = 6}) async {
    final database = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month - (monthsBack - 1), 1);
    final startStr = startOfMonth.toIso8601String().substring(0, 10);
    final rows = await database.rawQuery('''
      SELECT substr(income_date, 1, 7) AS ym, SUM(amount) AS total
      FROM income WHERE income_date >= ? AND deleted_at IS NULL
      GROUP BY ym
    ''', [startStr]);
    if (rows.isEmpty) return 0;
    var total = 0.0;
    for (final r in rows) {
      total += (r['total'] as num).toDouble();
    }
    return total / rows.length;
  }

  Future<List<LoanPayment>> upcomingLoanPayments({int withinDays = 30}) async {
    final database = await DatabaseHelper.instance.database;
    final today = DateTime.now();
    final horizon = today.add(Duration(days: withinDays));
    final rows = await database.rawQuery('''
      SELECT lp.* FROM loan_payments lp
      INNER JOIN user_loans l ON l.id = lp.loan_id
      WHERE lp.status = 'upcoming'
        AND lp.due_date >= ? AND lp.due_date <= ?
        AND l.deleted_at IS NULL AND l.paid_off = 0
      ORDER BY lp.due_date ASC
    ''', [today.toIso8601String().substring(0, 10), horizon.toIso8601String().substring(0, 10)]);
    return rows.map(LoanPayment.fromMap).toList();
  }

  Future<void> generateLoanDueNotifications() async {
    final database = await DatabaseHelper.instance.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await database.rawQuery('''
      SELECT lp.* FROM loan_payments lp
      INNER JOIN user_loans l ON l.id = lp.loan_id
      WHERE lp.status = 'upcoming' AND lp.due_date <= ?
        AND l.deleted_at IS NULL AND l.paid_off = 0
      ORDER BY lp.due_date ASC
    ''', [today]);
    for (final row in rows) {
      final payment = LoanPayment.fromMap(row);
      if (payment.id == null) continue;
      final loan = await getLoan(payment.loanId);
      if (loan == null) continue;
      final existing = await database.query(
        'app_notifications',
        where: 'type = ? AND data LIKE ?',
        whereArgs: ['loan_due', '%"loan_payment_id":${payment.id}%'],
        limit: 1,
      );
      if (existing.isNotEmpty) continue;
      final cur = await _preferredCurrencyCode();
      await addNotification(
        type: 'loan_due',
        title: 'Loan repayment due',
        body: '"${loan.name}" payment of ${formatMoney(payment.amountDue, cur)} is due. Set it aside on your salary day.',
        data: {'loan_id': loan.id, 'loan_payment_id': payment.id, 'loan_name': loan.name, 'amount': payment.amountDue},
      );
    }
  }

  Future<Database> database() => DatabaseHelper.instance.database;

  // ---------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------

  Future<List<AppNotification>> getNotifications() async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query('app_notifications', orderBy: 'created_at DESC', limit: 100);
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<int> unreadNotifications() async {
    final database = await DatabaseHelper.instance.database;
    final res = await database.rawQuery('SELECT COUNT(*) as c FROM app_notifications WHERE read = 0');
    return (res.first['c'] as num).toInt();
  }

  Future<void> addNotification({
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final database = await DatabaseHelper.instance.database;
    await database.insert('app_notifications', {
      'type': type,
      'title': title,
      'body': body,
      'data': data != null ? jsonEncode(data) : null,
      'read': 0,
      'created_at': nowIso(),
    });
  }

  Future<void> markNotificationRead(int id) async {
    final database = await DatabaseHelper.instance.database;
    await database.update('app_notifications', {'read': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAllNotificationsRead() async {
    final database = await DatabaseHelper.instance.database;
    await database.rawUpdate('UPDATE app_notifications SET read = 1');
  }

  Future<void> deleteNotification(int id) async {
    final database = await DatabaseHelper.instance.database;
    await database.delete('app_notifications', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // Activity log
  // ---------------------------------------------------------------------

  Future<void> logActivity(String logName, String description, {Map<String, dynamic>? properties}) async {
    final database = await DatabaseHelper.instance.database;
    await database.insert('activity_log', {
      'log_name': logName,
      'description': description,
      'properties': properties != null ? jsonEncode(properties) : null,
      'created_at': nowIso(),
    });
  }

  Future<List<ActivityLog>> getActivityLogs({int limit = 100}) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.query('activity_log', orderBy: 'created_at DESC', limit: limit);
    return rows.map(ActivityLog.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // Dashboard / analytics helpers
  // ---------------------------------------------------------------------

  Future<Map<String, double>> monthlyIncomeByKey(int monthsBack) async {
    final database = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month - (monthsBack - 1), 1);
    final startStr = startOfMonth.toIso8601String().substring(0, 10);
    final rows = await database.rawQuery('''
      SELECT substr(income_date, 1, 7) AS ym, SUM(amount) AS total
      FROM income WHERE income_date >= ? AND deleted_at IS NULL
      GROUP BY ym
    ''', [startStr]);
    return {for (final r in rows) r['ym'] as String: (r['total'] as num).toDouble()};
  }

  Future<Map<String, double>> monthlyExpenseByKey(int monthsBack) async {
    final database = await DatabaseHelper.instance.database;
    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month - (monthsBack - 1), 1);
    final startStr = startOfMonth.toIso8601String().substring(0, 10);
    final rows = await database.rawQuery('''
      SELECT substr(expense_date, 1, 7) AS ym, SUM(amount) AS total
      FROM expenses WHERE expense_date >= ? AND deleted_at IS NULL
      GROUP BY ym
    ''', [startStr]);
    return {for (final r in rows) r['ym'] as String: (r['total'] as num).toDouble()};
  }

  Future<List<Expense>> currentMonthExpenses() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
    final end = DateTime(now.year, now.month + 1, 0).toIso8601String().substring(0, 10);
    return getExpenses(dateFrom: start, dateTo: end);
  }

  Future<Map<String, double>> currentMonthExpensesByCategory() async {
    final database = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
    final end = DateTime(now.year, now.month + 1, 0).toIso8601String().substring(0, 10);
    final rows = await database.rawQuery('''
      SELECT e.category_id, c.name AS category_name, c.color AS category_color, SUM(e.amount) AS total, COUNT(*) AS cnt
      FROM expenses e LEFT JOIN categories c ON c.id = e.category_id
      WHERE e.expense_date >= ? AND e.expense_date <= ? AND e.deleted_at IS NULL
      GROUP BY e.category_id
      ORDER BY total DESC
    ''', [start, end]);
    return {for (final r in rows) (r['category_name'] as String? ?? 'Uncategorized'): (r['total'] as num).toDouble()};
  }

  Future<double> totalExpensesAllTime() async {
    final database = await DatabaseHelper.instance.database;
    final res = await database.rawQuery('SELECT COALESCE(SUM(amount),0) as t FROM expenses WHERE deleted_at IS NULL');
    return (res.first['t'] as num).toDouble();
  }

  Future<double> totalIncomeAllTime() async {
    final database = await DatabaseHelper.instance.database;
    final res = await database.rawQuery('SELECT COALESCE(SUM(amount),0) as t FROM income WHERE deleted_at IS NULL');
    return (res.first['t'] as num).toDouble();
  }

  /// Net balance and transaction count per payment method (account),
  /// computed as income - expenses. Grouped by SQL for large datasets.
  Future<Map<String, PaymentMethodStat>> paymentMethodStats() async {
    final database = await DatabaseHelper.instance.database;
    final map = <String, PaymentMethodStat>{};
    final expRows = await database.rawQuery(
        'SELECT payment_method AS pm, COALESCE(SUM(amount),0) AS t, COUNT(*) AS c FROM expenses WHERE deleted_at IS NULL GROUP BY payment_method');
    for (final r in expRows) {
      map[(r['pm'] as String? ?? 'other')] =
          PaymentMethodStat(-(r['t'] as num).toDouble(), (r['c'] as num).toInt());
    }
    final incRows = await database.rawQuery(
        'SELECT payment_method AS pm, COALESCE(SUM(amount),0) AS t, COUNT(*) AS c FROM income WHERE deleted_at IS NULL GROUP BY payment_method');
    for (final r in incRows) {
      final pm = r['pm'] as String? ?? 'other';
      final cur = map[pm];
      map[pm] = PaymentMethodStat(
        (cur?.balance ?? 0) + (r['t'] as num).toDouble(),
        (cur?.count ?? 0) + (r['c'] as num).toInt(),
      );
    }
    return map;
  }

  // ---------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------

  Future<ReportData> getReportData(int month, int year) async {
    final database = await DatabaseHelper.instance.database;
    final start = DateTime(year, month, 1).toIso8601String().substring(0, 10);
    final end = DateTime(year, month + 1, 0).toIso8601String().substring(0, 10);

    final expRows = await database.rawQuery('''
      SELECT c.name AS cat, SUM(e.amount) AS total, COUNT(*) AS cnt
      FROM expenses e LEFT JOIN categories c ON c.id = e.category_id
      WHERE e.expense_date >= ? AND e.expense_date <= ? AND e.deleted_at IS NULL
      GROUP BY e.category_id ORDER BY total DESC
    ''', [start, end]);
    final incRows = await database.rawQuery('''
      SELECT source AS src, SUM(amount) AS total, COUNT(*) AS cnt
      FROM income WHERE income_date >= ? AND income_date <= ? AND deleted_at IS NULL
      GROUP BY source ORDER BY total DESC
    ''', [start, end]);

    final ytdStart = DateTime(year, 1, 1).toIso8601String().substring(0, 10);
    final ytdExp = (await database.rawQuery(
        'SELECT COALESCE(SUM(amount),0) as t FROM expenses WHERE expense_date >= ? AND expense_date <= ? AND deleted_at IS NULL', [ytdStart, end])).first['t'] as num;
    final ytdInc = (await database.rawQuery(
        'SELECT COALESCE(SUM(amount),0) as t FROM income WHERE income_date >= ? AND income_date <= ? AND deleted_at IS NULL', [ytdStart, end])).first['t'] as num;

    final expensesByCat = expRows
        .map((r) => MapEntry(r['cat'] as String? ?? 'Uncategorized', (r['total'] as num).toDouble()))
        .toList();
    final incomeBySource = incRows
        .map((r) => MapEntry(r['src'] as String? ?? 'Other', (r['total'] as num).toDouble()))
        .toList();
    final expTotal = expensesByCat.fold(0.0, (s, e) => s + e.value);
    final incTotal = incomeBySource.fold(0.0, (s, e) => s + e.value);

    return ReportData(
      totalIncome: incTotal,
      totalExpenses: expTotal,
      netAmount: incTotal - expTotal,
      expensesByCategory: expensesByCat,
      incomeBySource: incomeBySource,
      ytdIncome: ytdInc.toDouble(),
      ytdExpenses: ytdExp.toDouble(),
      startOfMonth: start,
    );
  }

  Future<List<Expense>> expensesBetween(String start, String end) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.rawQuery('''
      SELECT e.*, c.name AS category_name, c.color AS category_color
      FROM expenses e LEFT JOIN categories c ON c.id = e.category_id
      WHERE e.expense_date >= ? AND e.expense_date <= ? AND e.deleted_at IS NULL
      ORDER BY e.expense_date DESC
    ''', [start, end]);
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<Income>> incomesBetween(String start, String end) async {
    final database = await DatabaseHelper.instance.database;
    final rows = await database.rawQuery('''
      SELECT * FROM income WHERE income_date >= ? AND income_date <= ? AND deleted_at IS NULL
      ORDER BY income_date DESC
    ''', [start, end]);
    return rows.map(Income.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // Net worth
  // ---------------------------------------------------------------------

  Future<NetWorthData> getNetWorth(int year) async {
    final database = await DatabaseHelper.instance.database;
    final start = DateTime(year, 1, 1).toIso8601String().substring(0, 10);
    final end = DateTime(year, 12, 31).toIso8601String().substring(0, 10);
    final incomeRows = await database.rawQuery('''
      SELECT substr(income_date,1,7) AS ym, SUM(amount) AS total FROM income
      WHERE income_date >= ? AND income_date <= ? AND deleted_at IS NULL GROUP BY ym
    ''', [start, end]);
    final expRows = await database.rawQuery('''
      SELECT substr(expense_date,1,7) AS ym, SUM(amount) AS total FROM expenses
      WHERE expense_date >= ? AND expense_date <= ? AND deleted_at IS NULL GROUP BY ym
    ''', [start, end]);
    final incMap = {for (final r in incomeRows) r['ym'] as String: (r['total'] as num).toDouble()};
    final expMap = {for (final r in expRows) r['ym'] as String: (r['total'] as num).toDouble()};

    final list = <MonthlyBreakdown>[];
    for (var m = 1; m <= 12; m++) {
      final key = '$year${m.toString().padLeft(2, '0')}';
      final i = incMap[key] ?? 0;
      final e = expMap[key] ?? 0;
      list.add(MonthlyBreakdown('${_monthNames[m - 1]} $year', i, e, i - e));
    }

    final totalIncome = await totalIncomeAllTime();
    final totalExpenses = await totalExpensesAllTime();
    return NetWorthData(totalIncome - totalExpenses, totalIncome, totalExpenses, list);
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _ym(DateTime d) => '${d.year}${d.month.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------
  // Insights
  // ---------------------------------------------------------------------

  Future<Insights> computeInsights() async {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 0).toIso8601String().substring(0, 10);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1).toIso8601String().substring(0, 10);
    final lastMonthEnd = DateTime(now.year, now.month, 0).toIso8601String().substring(0, 10);

    final thisExpenses = await getExpenses(dateFrom: thisMonthStart, dateTo: thisMonthEnd);
    final lastExpenses = await getExpenses(dateFrom: lastMonthStart, dateTo: lastMonthEnd);
    final thisIncomes = await getIncomes(dateFrom: thisMonthStart, dateTo: thisMonthEnd);

    final currentTotal = thisExpenses.fold(0.0, (s, e) => s + e.amount);
    final lastTotal = lastExpenses.fold(0.0, (s, e) => s + e.amount);
    final changePercent = lastTotal == 0 ? 0 : ((currentTotal - lastTotal) / lastTotal * 100).toDouble();
    final trend = changePercent > 5 ? 'increasing' : (changePercent < -5 ? 'decreasing' : 'stable');

    final threeMonthsAgoStart = DateTime(now.year, now.month - 3, 1).toIso8601String().substring(0, 10);
    final threeMonthsExpenses = await getExpenses(dateFrom: threeMonthsAgoStart, dateTo: thisMonthEnd);
    final monthTotals = <String, double>{};
    for (final e in threeMonthsExpenses) {
      final key = e.expenseDate.substring(0, 7);
      monthTotals[key] = (monthTotals[key] ?? 0) + e.amount;
    }
    final avg3 = monthTotals.values.isEmpty ? 0 : monthTotals.values.reduce((a, b) => a + b) / monthTotals.values.length;

    // anomalies over last 2 months
    final twoMonthsStart = DateTime(now.year, now.month - 2, 1).toIso8601String().substring(0, 10);
    final recent = await getExpenses(dateFrom: twoMonthsStart, dateTo: thisMonthEnd);
    final catTotals = <int, double>{};
    final catCounts = <int, int>{};
    for (final e in recent) {
      catTotals[e.categoryId] = (catTotals[e.categoryId] ?? 0) + e.amount;
      catCounts[e.categoryId] = (catCounts[e.categoryId] ?? 0) + 1;
    }
    final anomalies = <SpendingAnomaly>[];
    for (final e in recent) {
      final avg = catTotals[e.categoryId]! / catCounts[e.categoryId]!;
      final ratio = avg == 0 ? 999.0 : e.amount / avg;
      final isAnomaly = (avg > 0 && (ratio > 2.5 || ratio < 0.3)) || (avg == 0 && e.amount > 500);
      if (isAnomaly) {
        anomalies.add(SpendingAnomaly(e.description, e.categoryName ?? 'Uncategorized', e.amount, avg, ratio));
      }
    }
    anomalies.sort((a, b) => b.amount.compareTo(a.amount));
    if (anomalies.length > 10) anomalies.removeRange(10, anomalies.length);

    // forecast (linear regression last 12 months)
    ForecastData? forecast;
    final twelveMonths = await monthlyExpenseByKey(12);
    final recent12 = <double>[];
    final labels12 = <String>[];
    for (var i = 11; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = _ym(d);
      recent12.add(twelveMonths[key] ?? 0);
      labels12.add('${_monthShort[d.month - 1]} ${_shortYear(d.year)}');
    }
    if (recent12.where((v) => v > 0).length >= 3) {
      final n = recent12.length;
      var sx = 0.0, sy = 0.0, sxy = 0.0, sxx = 0.0;
      for (var i = 0; i < n; i++) {
        sx += i;
        sy += recent12[i];
        sxy += i * recent12[i];
        sxx += i * i;
      }
      final denom = n * sxx - sx * sx;
      final slope = denom == 0 ? 0.0 : (n * sxy - sx * sy) / denom;
      final intercept = denom == 0 ? (n == 0 ? 0 : sy / n) : (sy - slope * sx) / n;
      final labels = <String>[];
      final values = <double>[];
      for (var i = 1; i <= 6; i++) {
        final d = DateTime(now.year, now.month + i, 1);
        labels.add('${_monthShort[d.month - 1]} ${_shortYear(d.year)}');
        final v = slope * (n - 1 + i) + intercept;
        values.add(v < 0 ? 0 : double.parse(v.toStringAsFixed(2)));
      }
      final fTrend = slope > 0 ? 'increasing' : (slope < 0 ? 'decreasing' : 'stable');
      forecast = ForecastData(labels, values, slope, fTrend, labels12, recent12);
    }

    // category breakdown
    final catBreakdown = <CategoryBreakdownRow>[];
    final catRows = <String, List<double>>{};
    final catColors = <String, String>{};
    for (final e in thisExpenses) {
      final name = e.categoryName ?? 'Uncategorized';
      catRows[name] = [ (catRows[name]?[0] ?? 0) + e.amount, (catRows[name]?[1] ?? 0) + 1 ];
      catColors[name] = e.categoryColor ?? '#6b7280';
    }
    catRows.forEach((k, v) {
      catBreakdown.add(CategoryBreakdownRow(k, catColors[k] ?? '#6b7280', v[0], v[1].toInt(), 0));
    });
    catBreakdown.sort((a, b) => b.total.compareTo(a.total));
    final grandTotal = catBreakdown.fold(0.0, (s, r) => s + r.total);
    for (final r in catBreakdown) {
      r.percentage = grandTotal <= 0 ? 0 : double.parse((r.total / grandTotal * 100).toStringAsFixed(1));
    }

    // day of week (last 3 months)
    final threeMonthsStart = DateTime(now.year, now.month - 3, 1).toIso8601String().substring(0, 10);
    final threeMonthExp = await getExpenses(dateFrom: threeMonthsStart, dateTo: thisMonthEnd);
    final dow = <int, List<double>>{};
    for (var i = 0; i < 7; i++) {
      dow[i] = [0, 0];
    }
    for (final e in threeMonthExp) {
      final date = DateTime.tryParse(e.expenseDate) ?? now;
      dow[date.weekday % 7]![0] += e.amount;
      dow[date.weekday % 7]![1] += 1;
    }
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final dayAnalysis = <DayOfWeekRow>[];
    for (var i = 0; i < 7; i++) {
      final total = dow[i]![0];
      final count = dow[i]![1].toInt();
      final avg = count == 0 ? 0.0 : double.parse((total / count).toStringAsFixed(2));
      dayAnalysis.add(DayOfWeekRow(dayNames[i], total, count, avg));
    }

    // time of day (last 3 months) - using expense_date time is unavailable, use hour 12 default
    Map<String, TimeOfDayRow> timeOfDay = {
      'morning': TimeOfDayRow('Morning', 0, 0),
      'afternoon': TimeOfDayRow('Afternoon', 0, 0),
      'evening': TimeOfDayRow('Evening', 0, 0),
      'night': TimeOfDayRow('Night', 0, 0),
    };
    for (final e in threeMonthExp) {
      timeOfDay['afternoon'] = TimeOfDayRow('Afternoon', timeOfDay['afternoon']!.total + e.amount, timeOfDay['afternoon']!.count + 1);
    }

    // spending score
    final incomeTotal = thisIncomes.fold(0.0, (s, i) => s + i.amount);
    final savingsRate = incomeTotal > 0 ? (incomeTotal - currentTotal) / incomeTotal * 100 : 0.0;
    final budgets = await getBudgets();
    var adherenceSum = 0.0;
    for (final b in budgets) {
      final spent = await _budgetSpending(b.categoryId, b.period, b.month, b.year);
      adherenceSum += min(100.0, spent / b.limitAmount * 100);
    }
    final avgAdherence = budgets.isEmpty ? 100.0 : adherenceSum / budgets.length;
    var scoreParts = 0;
    if (savingsRate >= 20) scoreParts += 40;
    else if (savingsRate >= 10) scoreParts += 30;
    else if (savingsRate >= 0) scoreParts += 20;
    else scoreParts += 5;
    if (avgAdherence <= 100) scoreParts += 30;
    else if (avgAdherence <= 120) scoreParts += 20;
    else scoreParts += 10;
    if (currentTotal > 0) {
      final distinct = catRows.length;
      if (distinct <= 5) scoreParts += 20;
      else if (distinct <= 10) scoreParts += 15;
      else scoreParts += 10;
    }
    final score = max(0, min(100, scoreParts));
    final rating = score >= 80 ? 'excellent' : (score >= 60 ? 'good' : (score >= 40 ? 'fair' : (score >= 20 ? 'poor' : 'critical')));

    // monthly trend
    final trendRows = <MonthlyTrendRow>[];
    for (var i = 11; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = _ym(d);
      trendRows.add(MonthlyTrendRow('${_monthShort[d.month - 1]} ${_shortYear(d.year)}', twelveMonths[key] ?? 0));
    }

    // top categories last 3 months
    final topCatMap = <String, List<double>>{};
    final topCatColors = <String, String>{};
    for (final e in threeMonthExp) {
      final name = e.categoryName ?? 'Uncategorized';
      topCatMap[name] = [ (topCatMap[name]?[0] ?? 0) + e.amount, (topCatMap[name]?[1] ?? 0) + 1 ];
      topCatColors[name] = e.categoryColor ?? '#6b7280';
    }
    final topCats = <CategoryBreakdownRow>[];
    topCatMap.forEach((k, v) => topCats.add(CategoryBreakdownRow(k, topCatColors[k] ?? '#6b7280', v[0], v[1].toInt(), 0)));
    topCats.sort((a, b) => b.total.compareTo(a.total));
    final topGrand = topCats.fold(0.0, (s, r) => s + r.total);
    for (final r in topCats) {
      r.percentage = topGrand <= 0 ? 0 : double.parse((r.total / topGrand * 100).toStringAsFixed(1));
    }
    if (topCats.length > 5) topCats.removeRange(5, topCats.length);

    return Insights(
      month: now,
      currentMonthTotal: currentTotal,
      lastMonthTotal: lastTotal,
      changePercent: double.parse(changePercent.toStringAsFixed(1)),
      trend: trend,
      averageLast3Months: double.parse(avg3.toStringAsFixed(2)),
      anomalies: anomalies,
      forecast: forecast,
      categoryBreakdown: catBreakdown,
      dayOfWeekAnalysis: dayAnalysis,
      timeOfDayAnalysis: timeOfDay,
      spendingScore: score,
      scoreRating: rating,
      monthlyTrend: trendRows,
      topCategories: topCats,
    );
  }

  static const List<String> _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const List<String> _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  String _shortYear(int y) => y.toString().substring(2);

  // ---------------------------------------------------------------------
  // Backup & export
  // ---------------------------------------------------------------------

  Future<String> exportBackupJson() async {
    final database = await DatabaseHelper.instance.database;
    final tables = {
      'app_settings': ['key', 'value'],
      'categories': ['id', 'name', 'description', 'color', 'user_id'],
      'bill_categories': ['id', 'name', 'description'],
      'expenses': ['id', 'category_id', 'bill_category_id', 'description', 'amount', 'expense_date', 'notes', 'payment_method', 'currency_code', 'receipt_image', 'bill_type', 'created_at', 'updated_at', 'deleted_at'],
      'income': ['id', 'source', 'amount', 'income_date', 'notes', 'payment_method', 'currency_code', 'created_at', 'updated_at', 'deleted_at'],
      'budgets': ['id', 'category_id', 'limit_amount', 'period', 'month', 'year', 'notes', 'carryover_enabled', 'carryover_amount', 'carried_over_from', 'created_at'],
      'savings_goals': ['id', 'title', 'description', 'target_amount', 'current_amount', 'target_date', 'category', 'status', 'created_at', 'updated_at', 'deleted_at'],
      'category_keywords': ['id', 'category_id', 'keyword', 'priority', 'created_at'],
      'user_currencies': ['id', 'currency_code', 'exchange_rate', 'is_primary', 'last_updated', 'created_at'],
      'receipts': ['id', 'expense_id', 'file_path', 'file_name', 'file_size', 'mime_type', 'ocr_text', 'is_processed', 'processing_status', 'created_at', 'deleted_at'],
      'recurring_transactions': ['id', 'category_id', 'bill_category_id', 'description', 'amount', 'payment_method', 'notes', 'frequency', 'day_of_month', 'next_due_date', 'last_generated_date', 'end_date', 'max_occurrences', 'occurrences_generated', 'status', 'last_expense_id', 'created_at', 'deleted_at'],
      'app_notifications': ['id', 'type', 'title', 'body', 'data', 'read', 'created_at'],
      'activity_log': ['id', 'log_name', 'description', 'properties', 'created_at'],
    };
    final data = <String, dynamic>{};
    for (final entry in tables.entries) {
      final rows = await database.query(entry.key);
      final list = rows.map((r) {
        final m = <String, dynamic>{};
        for (final col in entry.value) {
          if (r.containsKey(col)) m[col] = r[col];
        }
        return m;
      }).toList();
      data[entry.key] = list;
    }
    return jsonEncode(data);
  }

  Future<void> importBackupJson(String content) async {
    final database = await DatabaseHelper.instance.database;
    final data = jsonDecode(content) as Map<String, dynamic>;
    final removing = [
      'app_settings', 'categories', 'expenses', 'income', 'budgets', 'savings_goals',
      'category_keywords', 'user_currencies', 'receipts', 'recurring_transactions',
      'app_notifications', 'activity_log',
    ];
    for (final t in removing) {
      await database.delete(t);
    }
    for (final entry in data.entries) {
      final table = entry.key;
      final rows = entry.value as List<dynamic>;
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        if (map.containsKey('id')) map.remove('id');
        await database.insert(table, map);
      }
    }
  }
}

// ---------------------------------------------------------------------
// Backup & export
// ---------------------------------------------------------------------