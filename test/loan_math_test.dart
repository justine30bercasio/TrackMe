import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/core/loan_math.dart';

void main() {
  test('zero-interest loan splits principal evenly', () {
    final payment = loanMonthlyPayment(principal: 12000, annualRate: 0, termMonths: 12);
    expect(payment, closeTo(1000, 0.001));
  });

  test('interest loan payment matches standard amortization formula', () {
    final payment = loanMonthlyPayment(principal: 100000, annualRate: 12, termMonths: 24);
    expect(payment, closeTo(4707.35, 0.01));
  });

  test('schedule totals match principal and paid days are clamped', () {
    final schedule = loanSchedule(
      principal: 60000,
      annualRate: 10,
      termMonths: 6,
      startMonth: DateTime(2026, 2, 1),
      paymentDay: 31,
    );
    expect(schedule.length, 6);
    final principalSum = schedule.fold(0.0, (s, r) => s + r.principal);
    expect(principalSum, closeTo(60000, 0.01));
    expect(schedule.first.dueDate.day, 28);
    expect(DateTime(schedule.first.dueDate.year, schedule.first.dueDate.month).month, 2);
  });

  test('last payment closes remaining balance', () {
    final schedule = loanSchedule(
      principal: 50000,
      annualRate: 36,
      termMonths: 12,
      startMonth: DateTime(2026, 1, 1),
      paymentDay: 15,
    );
    final last = schedule.last;
    final paid = schedule.fold(0.0, (s, r) => s + r.principal);
    expect(paid, closeTo(50000, 0.01));
    expect(last.balanceAfter, closeTo(0, 0.01));
  });

  test('remainingBalance decreases by paid principal', () {
    final schedule = loanSchedule(
      principal: 6000,
      annualRate: 0,
      termMonths: 6,
      startMonth: DateTime(2026, 1, 1),
      paymentDay: 15,
    );
    expect(remainingBalance(schedule, 0), closeTo(6000, 0.001));
    expect(remainingBalance(schedule, 3), closeTo(3000, 0.001));
    expect(remainingBalance(schedule, 6), closeTo(0, 0.001));
  });
}