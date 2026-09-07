import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/loan_math.dart';
import 'package:track_me/core/payment_methods.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/loans/loan_form_screen.dart';

class LoanDetailScreen extends StatefulWidget {
  final int loanId;
  const LoanDetailScreen({super.key, required this.loanId});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  late Future<(Loan?, List<LoanPayment>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(Loan?, List<LoanPayment>)> _load() async {
    final repo = AppRepository.instance;
    final loan = await repo.getLoan(widget.loanId);
    final payments = loan == null ? <LoanPayment>[] : await repo.getLoanPayments(loan.id!);
    return (loan, payments);
  }

  void _reload() {
    setState(() => _future = _load());
    context.read<AppState>().bumpData();
  }

  Future<void> _markPaid(LoanPayment payment, {required bool recordExpense}) async {
    await AppRepository.instance.markLoanPaymentPaid(payment.id!, recordExpense: recordExpense);
    _reload();
  }

  Future<void> _undo(LoanPayment payment) async {
    await AppRepository.instance.undoLoanPayment(payment.id!);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan details')),
      body: FutureBuilder<(Loan?, List<LoanPayment>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final (loan, payments) = snapshot.data ?? (null, const <LoanPayment>[]);
          if (loan == null) {
            return const EmptyState(
              icon: Icons.request_quote_outlined,
              title: 'Loan not found',
              message: 'This loan may have been deleted.',
            );
          }
          final cur = context.watch<AppState>().currencyCode;
          final schedule = loanSchedule(
            principal: loan.principal,
            annualRate: loan.annualInterestRate,
            termMonths: loan.termMonths,
            startMonth: DateTime.tryParse(loan.startDate) ?? DateTime.now(),
            paymentDay: loan.paymentDay,
          );
          final paidCount = payments.where((p) => p.status == 'paid').length;
          final totalPaid = payments.where((p) => p.status == 'paid').fold(0.0, (s, p) => s + p.principalPaid);
          final totalPayable = schedule.fold(0.0, (s, r) => s + r.payment);
          final interest = totalInterest(schedule);
          final balance = payments.where((p) => p.status != 'paid').fold(0.0, (s, p) => s + p.amountDue);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PaymentMethodBadge(code: loan.paymentMethod, size: 46),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loan.name, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(
                                loan.lender == null || loan.lender!.isEmpty ? paymentMethodLabel(loan.paymentMethod) : '${loan.lender!} · ${paymentMethodLabel(loan.paymentMethod)}',
                                style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall!.color),
                              ),
                            ],
                          ),
                        ),
                        if (loan.paidOff) Pill('Paid off', AppColors.income),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoanFormScreen(loan: loan)));
                              _reload();
                            } else if (v == 'delete') {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete loan'),
                                  content: Text('Delete "${loan.name}" and its repayment schedule?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await AppRepository.instance.deleteLoan(loan.id!);
                                context.read<AppState>().bumpData();
                                if (mounted) Navigator.of(context).pop();
                              }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit loan')),
                            PopupMenuItem(value: 'delete', child: Text('Delete loan')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Balance', style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall!.color)),
                    const SizedBox(height: 4),
                    Text(formatMoney(balance, cur), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    ProgressBar(
                      fraction: loan.principal == 0 ? 0 : (totalPaid / loan.principal).clamp(0.0, 1.0),
                      color: loan.paidOff ? AppColors.income : AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatMoney(totalPaid, cur)} of ${formatMoney(loan.principal, cur)} principal paid · $paidCount of ${payments.length} payments',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(label: 'Monthly', value: formatMoney(schedule.isEmpty ? 0 : schedule.first.payment, cur)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _SummaryTile(label: 'Interest', value: '+${formatMoney(interest, cur)}')),
                  const SizedBox(width: 10),
                  Expanded(child: _SummaryTile(label: 'Total', value: formatMoney(totalPayable, cur))),
                ],
              ),
              const SizedBox(height: 20),
              Text('Repayment schedule', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Due every ${_ordinal(loan.paymentDay)} of the month, aligned to your salary day.',
                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color),
              ),
              const SizedBox(height: 10),
              if (payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No repayment schedule yet.')),
                )
              else
                ...payments.map(
                  (p) => _PaymentRow(
                    payment: p,
                    currency: cur,
                    onMarkPaid: () => _confirmRecord(p, recordExpense: true),
                    onUndo: () => _confirmUndo(p),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmRecord(LoanPayment p, {required bool recordExpense}) async {
    final cur = context.read<AppState>().currencyCode;
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record payment'),
        content: Text('Mark the ${formatMoney(p.amountDue, cur)} repayment on ${formatDateShort(p.dueDate)} as paid?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'skip'), child: const Text('Skip expense')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'record'),
            child: const Text('Record & add expense'),
          ),
        ],
      ),
    );
    if (action != null) {
      await _markPaid(p, recordExpense: action == 'record');
    }
  }

  Future<void> _confirmUndo(LoanPayment p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Undo payment'),
        content: const Text('Mark this repayment as unpaid again?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Undo')),
        ],
      ),
    );
    if (ok == true) {
      await _undo(p);
    }
  }

  String _ordinal(int n) {
    if (n == 1 || n == 21) return '${n}st';
    if (n == 2 || n == 22) return '${n}nd';
    if (n == 3 || n == 23) return '${n}rd';
    return '${n}th';
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodySmall!.color)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final LoanPayment payment;
  final String currency;
  final VoidCallback onMarkPaid;
  final VoidCallback onUndo;

  const _PaymentRow({
    required this.payment,
    required this.currency,
    required this.onMarkPaid,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.status == 'paid';
    final due = DateTime.tryParse(payment.dueDate);
    final today = DateTime.now();
    final overdue = !isPaid && due != null && DateTime(due.year, due.month, due.day).isBefore(DateTime(today.year, today.month, today.day));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: isPaid ? onUndo : onMarkPaid,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isPaid
                    ? AppColors.income.withValues(alpha: 0.12)
                    : (overdue ? AppColors.danger.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.1)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPaid ? Icons.check : (overdue ? Icons.error_outline : Icons.radio_button_unchecked),
                size: 20,
                color: isPaid ? AppColors.income : (overdue ? AppColors.danger : AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDateShort(payment.dueDate),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatMoney(payment.principalPaid, currency)} principal · ${formatMoney(payment.interestPaid, currency)} interest',
                    style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodySmall!.color),
                  ),
                ],
              ),
            ),
Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(payment.amountDue, currency),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Pill(isPaid ? 'Paid' : (overdue ? 'Overdue' : 'Due'), isPaid ? AppColors.income : (overdue ? AppColors.danger : AppColors.primary)),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}