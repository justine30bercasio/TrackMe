import 'dart:math' as math;

class LoanScheduleRow {
  final DateTime dueDate;
  final double payment;
  final double principal;
  final double interest;
  final double balanceAfter;

  const LoanScheduleRow({
    required this.dueDate,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balanceAfter,
  });
}

double loanMonthlyPayment({
  required double principal,
  required double annualRate,
  required int termMonths,
}) {
  if (termMonths <= 0 || principal <= 0) return 0;
  final r = annualRate / 100 / 12;
  if (r == 0) return principal / termMonths;
  return principal * r * math.pow(1 + r, termMonths).toDouble() /
      (math.pow(1 + r, termMonths).toDouble() - 1);
}

DateTime monthWithDay(int year, int month, int day) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day.clamp(1, daysInMonth));
}

List<LoanScheduleRow> loanSchedule({
  required double principal,
  required double annualRate,
  required int termMonths,
  required DateTime startMonth,
  required int paymentDay,
}) {
  if (termMonths <= 0 || principal <= 0) return const [];
  final r = annualRate / 100 / 12;
  final base = loanMonthlyPayment(principal: principal, annualRate: annualRate, termMonths: termMonths);
  final rows = <LoanScheduleRow>[];
  var balance = principal;
  var cursor = DateTime(startMonth.year, startMonth.month);
  for (var i = 0; i < termMonths; i++) {
    final interest = balance * r;
    final payment = i == termMonths - 1 ? balance + interest : base;
    var principalPart = payment - interest;
    if (principalPart > balance && i == termMonths - 1) {
      principalPart = balance;
    }
    final rowPayment = principalPart + interest;
    balance -= principalPart;
    rows.add(LoanScheduleRow(
      dueDate: monthWithDay(cursor.year, cursor.month, paymentDay),
      payment: rowPayment,
      principal: principalPart,
      interest: interest,
      balanceAfter: balance,
    ));
    cursor = DateTime(cursor.year, cursor.month + 1);
  }
  return rows;
}

double totalInterest(List<LoanScheduleRow> rows) {
  return rows.fold(0.0, (sum, r) => sum + r.interest);
}

double remainingBalance(List<LoanScheduleRow> schedule, int paidCount) {
  if (schedule.isEmpty) return 0;
  double total = 0;
  for (final r in schedule) {
    total += r.principal;
  }
  final paid = paidCount.clamp(0, schedule.length);
  for (var i = 0; i < paid; i++) {
    total -= schedule[i].principal;
  }
  return total < 0.005 ? 0 : total;
}