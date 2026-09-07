import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/loan_math.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/loans/loan_detail_screen.dart';
import 'package:track_me/screens/loans/loan_form_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoanCardData {
  final Loan loan;
  final List<LoanPayment> payments;
  List<LoanScheduleRow> schedule = const [];
  _LoanCardData(this.loan, this.payments);

  double get monthlyPayment {
    if (schedule.isEmpty) return 0;
    return schedule.first.payment;
  }

  double get totalPaid {
    var sum = 0.0;
    for (final p in payments.where((p) => p.status == 'paid')) {
      sum += p.principalPaid;
    }
    return sum;
  }

  double get balance {
    var remaining = 0.0;
    for (final r in schedule) {
      remaining += r.principal;
    }
    for (final p in payments.where((p) => p.status == 'paid')) {
      remaining -= p.principalPaid;
    }
    return remaining < 0.005 ? 0 : remaining;
  }

  LoanPayment? get nextPayment {
    for (final p in payments) {
      if (p.status == 'upcoming') return p;
    }
    return null;
  }
}

class _LoansScreenState extends State<LoansScreen> {
  late Future<List<_LoanCardData>> _future;
  int _lastVersion = -1;

  Future<List<_LoanCardData>> _load() async {
    final repo = AppRepository.instance;
    final loans = await repo.getLoans();
    final results = <_LoanCardData>[];
    for (final loan in loans) {
      final payments = await repo.getLoanPayments(loan.id!);
      final data = _LoanCardData(loan, payments);
      data.schedule = loanSchedule(
        principal: loan.principal,
        annualRate: loan.annualInterestRate,
        termMonths: loan.termMonths,
        startMonth: DateTime.tryParse(loan.startDate) ?? DateTime.now(),
        paymentDay: loan.paymentDay,
      );
      results.add(data);
    }
    return results;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final version = context.watch<AppState>().dataVersion;
    if (_lastVersion != version) {
      _lastVersion = version;
      _future = _load();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Loans & repayments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoanFormScreen()));
          _refresh();
          context.read<AppState>().bumpData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add loan'),
      ),
      body: FutureBuilder<List<_LoanCardData>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.request_quote_outlined,
              title: 'No loans yet',
              message: 'Add a loan and we will schedule repayments on your salary day so you never miss one.',
            );
          }
          final active = items.where((d) => !d.loan.paidOff).toList();
          final paidOff = items.where((d) => d.loan.paidOff).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              for (final d in active) _LoanCard(data: d, onChanged: _refresh),
              if (paidOff.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Paid off', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final d in paidOff) _LoanCard(data: d, onChanged: _refresh),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final _LoanCardData data;
  final VoidCallback onChanged;
  const _LoanCard({required this.data, required this.onChanged});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete loan'),
        content: Text('Delete "${data.loan.name}" and its repayment schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AppRepository.instance.deleteLoan(data.loan.id!);
      context.read<AppState>().bumpData();
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = data.loan;
    final cur = context.watch<AppState>().currencyCode;
    final next = data.nextPayment;
    final progress = loan.principal == 0 ? 0.0 : data.totalPaid / loan.principal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoanDetailScreen(loanId: loan.id!)));
          onChanged();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PaymentMethodBadge(code: loan.paymentMethod, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loan.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        loan.lender == null || loan.lender!.isEmpty ? 'Every ${loan.paymentDay} of the month' : '${loan.lender} · Every ${loan.paymentDay}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color),
                      ),
                    ],
                  ),
                ),
                if (loan.paidOff)
                  Pill('Paid off', AppColors.income)
                else
                  Flexible(
                    child: Text(formatMoney(data.monthlyPayment, cur), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.more_vert, size: 18, color: Theme.of(context).textTheme.bodySmall!.color),
                  onSelected: (v) {
                    if (v == 'delete') _confirmDelete(context);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('${formatMoney(data.balance, cur)} remaining', style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall!.color), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Flexible(child: Text('${formatMoney(data.totalPaid, cur)} paid', style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall!.color), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 6),
            ProgressBar(fraction: progress.clamp(0, 1), color: loan.paidOff ? AppColors.income : AppColors.primary),
            if (next != null && !loan.paidOff) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 16, color: Theme.of(context).textTheme.bodySmall!.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Next repayment: ${formatDateShort(next.dueDate)}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Flexible(
                  child: Text(
                    formatMoney(next.amountDue, cur),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}