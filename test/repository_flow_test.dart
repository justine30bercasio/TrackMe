import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/database_helper.dart';

Future<void> _freshDb() async {
  DatabaseHelper.useInMemoryDatabase = true;
  await DatabaseHelper.reset();
  // Touch the database so it is created and seeded for this test.
  await DatabaseHelper.instance.database;
  await AppRepository.instance.createDefaultCategories();
}

String _today() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

String _futureDay([int addDays = 10]) {
  final n = DateTime.now().add(Duration(days: addDays));
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

void main() {
  final repo = AppRepository.instance;

  group('Transfers', () {
    setUp(_freshDb);

    test('records a transfer and updates account balances', () async {
      await repo.addTransfer(
        fromMethod: 'cash',
        toMethod: 'gcash',
        amount: 100,
        transferDate: _today(),
        notes: 'top up',
      );
      final stats = await repo.paymentMethodStats();
      expect(stats['cash']!.balance, -100);
      expect(stats['gcash']!.balance, 100);
    });

    test('rejects transfers between the same account', () async {
      expect(
        () => repo.addTransfer(
          fromMethod: 'cash',
          toMethod: 'cash',
          amount: 10,
          transferDate: _today(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('lists transfers and soft-deletes them', () async {
      final id = await repo.addTransfer(
        fromMethod: 'bdo',
        toMethod: 'maya',
        amount: 500,
        transferDate: _today(),
      );
      expect(id, greaterThan(0));
      expect(await repo.getTransfers(), hasLength(1));

      await repo.deleteTransfer(id);
      expect(await repo.getTransfers(), isEmpty);
      expect(await repo.getTransfers(withTrashed: true), hasLength(1));
    });
  });

  group('Money owed', () {
    setUp(_freshDb);

    test('adds a debt and reports outstanding totals', () async {
      await repo.addDebt(
        person: 'Mark',
        direction: 'owed_to_me',
        amount: 1500,
        dueDate: _futureDay(),
      );
      await repo.addDebt(
        person: 'Bank',
        direction: 'owed_by_me',
        amount: 8000,
        dueDate: _futureDay(),
      );
      final totals = await repo.debtTotals();
      expect(totals['owed_to_me'], 1500);
      expect(totals['owed_by_me'], 8000);
    });

    test('marks a debt as paid when fully settled', () async {
      final id = await repo.addDebt(
        person: 'Mark',
        direction: 'owed_to_me',
        amount: 1000,
        dueDate: _futureDay(),
      );
      await repo.recordDebtPayment(id, 400);
      var debts = await repo.getDebts();
      expect(debts.single.remainingAmount, 600);

      await repo.recordDebtPayment(id, 600);
      debts = await repo.getDebts();
      expect(debts.single.isFullyPaid, isTrue);
      expect(debts.single.status, 'paid');
    });
  });

  group('Cash-flow forecast', () {
    setUp(_freshDb);

    test('combines recurring, loan and debt obligations', () async {
      final cats = await repo.getCategories();
      final categoryId = cats.firstWhere((c) => c.name == 'Food').id!;

      await repo.saveRecurringTransaction(
        categoryId: categoryId,
        description: 'Netflix',
        amount: 450,
        frequency: 'monthly',
        nextDueDate: _today(),
      );

      final loan = await repo.saveLoan(
        name: 'Car loan',
        principal: 60000,
        annualInterestRate: 12,
        termMonths: 12,
        startDate: _today(),
        paymentDay: DateTime.now().day,
      );
      expect(loan.id, isNotNull);

      await repo.addDebt(
        person: 'Juan',
        direction: 'owed_by_me',
        amount: 2000,
        dueDate: _futureDay(5),
      );

      final events = await repo.getCashFlowForecast(days: 45);
      expect(events.any((e) => e.kind == 'recurring'), isTrue);
      expect(events.any((e) => e.kind == 'loan'), isTrue);
      expect(events.any((e) => e.kind == 'debt'), isTrue);
      expect(events.where((e) => !e.isIncome).length,
          greaterThanOrEqualTo(3));
    });
  });

  group('Global search', () {
    setUp(_freshDb);

    test('returns nothing for an empty term', () async {
      final results = await repo.globalSearch('  ');
      expect(results.isEmpty, isTrue);
    });

    test('finds expenses by description and categories by name', () async {
      final cats = await repo.getCategories();
      final food = cats.firstWhere((c) => c.name == 'Food');
      await repo.saveExpense(
        categoryId: food.id!,
        description: 'Lunch at Jollibee',
        amount: 250,
        expenseDate: _today(),
        paymentMethod: 'gcash',
        ignoreDuplicate: true,
      );

      final results = await repo.globalSearch('jollibee');
      expect(results.expenses, hasLength(1));
      expect(results.expenses.first.amount, 250);

      final byCategory = await repo.globalSearch('food');
      expect(
        byCategory.categories.any((c) => c.name.toLowerCase() == 'food'),
        isTrue,
      );
    });
  });
}