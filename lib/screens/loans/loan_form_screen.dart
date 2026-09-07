import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/loan_math.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';

class LoanFormScreen extends StatefulWidget {
  final Loan? loan;
  const LoanFormScreen({super.key, this.loan});

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  static const List<int> _quickTerms = [6, 12, 24, 36, 48, 60];

  late final TextEditingController _nameController;
  late final TextEditingController _lenderController;
  late final TextEditingController _principalController;
  late final TextEditingController _rateController;
  late final TextEditingController _termController;
  late final TextEditingController _notesController;
  DateTime _startDate = DateTime.now();
  int _paymentDay = 15;
  String _paymentMethod = 'bank_transfer';
  double _averageIncome = 0;
  bool _saving = false;

  static DateTime _defaultStart(int paymentDay) {
    final now = DateTime.now();
    if (now.day > paymentDay) return DateTime(now.year, now.month + 1, 1);
    return DateTime(now.year, now.month, 1);
  }

  @override
  void initState() {
    super.initState();
    final loan = widget.loan;
    final user = context.read<AppState>().user;
    _paymentDay = loan?.paymentDay ?? user.salaryDay;
    _startDate = loan != null ? DateTime.tryParse(loan.startDate) ?? _defaultStart(_paymentDay) : _defaultStart(_paymentDay);
    _paymentMethod = loan?.paymentMethod ?? 'bank_transfer';
    _nameController = TextEditingController(text: loan?.name ?? '');
    _lenderController = TextEditingController(text: loan?.lender ?? '');
    _principalController = TextEditingController(text: loan == null ? '' : loan.principal.toStringAsFixed(2));
    _rateController = TextEditingController(text: loan == null ? '' : loan.annualInterestRate.toStringAsFixed(2));
    _termController = TextEditingController(text: loan?.termMonths.toString() ?? '12');
    _notesController = TextEditingController(text: loan?.notes ?? '');
    _loadAverageIncome();
  }

  Future<void> _loadAverageIncome() async {
    final avg = await AppRepository.instance.averageMonthlyIncome();
    if (mounted) {
      setState(() => _averageIncome = avg);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lenderController.dispose();
    _principalController.dispose();
    _rateController.dispose();
    _termController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _principal => double.tryParse(_principalController.text.replaceAll(',', '').replaceAll(' ', '')) ?? 0;
  double get _rate => double.tryParse(_rateController.text.replaceAll(',', '').replaceAll(' ', '')) ?? 0;
  int get _term => int.tryParse(_termController.text.replaceAll(',', '')) ?? 0;
  double get _monthly => loanMonthlyPayment(principal: _principal, annualRate: _rate, termMonths: _term);

  List<LoanScheduleRow> get _schedule => loanSchedule(
        principal: _principal,
        annualRate: _rate,
        termMonths: _term,
        startMonth: _startDate,
        paymentDay: _paymentDay,
      );

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(DateTime.now().year - 1, 1, 1),
      lastDate: DateTime(DateTime.now().year + 10, 12, 31),
    );
    if (picked != null) {
      setState(() => _startDate = DateTime(picked.year, picked.month, 1));
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please give this loan a name.')));
      return;
    }
    if (_principal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the loan amount.')));
      return;
    }
    if (_term <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the loan term in months.')));
      return;
    }
    setState(() => _saving = true);
    await AppRepository.instance.saveLoan(
      id: widget.loan?.id,
      name: name,
      lender: _lenderController.text.trim().isEmpty ? null : _lenderController.text.trim(),
      principal: _principal,
      annualInterestRate: _rate.clamp(0, 100).toDouble(),
      termMonths: _term,
      startDate: _startDate.toIso8601String().substring(0, 10),
      paymentDay: _paymentDay,
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim(),
    );
    context.read<AppState>().bumpData();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cur = context.watch<AppState>().currencyCode;
    final schedule = _schedule;
    final monthly = _monthly;
    final interest = totalInterest(schedule);
    final totalPayable = schedule.isEmpty ? 0.0 : schedule.fold(0.0, (s, r) => s + r.payment);
    final ratio = _averageIncome <= 0 ? 0.0 : monthly / _averageIncome * 100;

    return Scaffold(
      appBar: AppBar(title: Text(widget.loan == null ? 'Add a loan' : 'Edit loan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Loan name', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'e.g. Car loan, Home loan, Personal loan'),
          ),
          const SizedBox(height: 14),
          Text('Lender (optional)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _lenderController,
            decoration: const InputDecoration(hintText: 'e.g. Bank, lending app, family'),
          ),
          const SizedBox(height: 14),
          Text('Amount borrowed', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _principalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(cur, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Annual interest %', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: 'e.g. 36'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Term (months)', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _termController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'e.g. 24'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _quickTerms)
                ChoiceChip(
                  label: Text('$t mo'),
                  selected: _term == t,
                  onSelected: (_) => setState(() => _termController.text = '$t'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Payment method', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in AppStrings.expensePaymentMethods)
                ChoiceChip(
                  avatar: PaymentMethodBadge(code: m, size: 20),
                  label: Text(paymentMethodLabel(m)),
                  selected: _paymentMethod == m,
                  onSelected: (_) => setState(() => _paymentMethod = m),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Repayment day', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _paymentDay > 28 ? 15 : _paymentDay,
            isExpanded: true,
            items: [
              for (var day = 1; day <= 28; day++)
                DropdownMenuItem(value: day, child: Text('Every ${_ordinal(day)} of the month')),
            ],
            onChanged: (v) => setState(() => _paymentDay = v ?? 15),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.event_repeat),
              helperText: 'Aligned with your salary day for automatic budgeting',
            ),
          ),
          const SizedBox(height: 14),
          Text('First payment month', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickStartDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : const Color(0xFFF0F1F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 20, color: Theme.of(context).textTheme.bodySmall!.color),
                  const SizedBox(width: 10),
                  Text('${formatDateShort(_startDate.toIso8601String().substring(0, 10))}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Notes (optional)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Any details about this loan'),
          ),
          const SizedBox(height: 18),
          if (_principal > 0 && _term > 0)
            AppCard(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : const Color(0xFFF6F7FB),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Monthly repayment', style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall!.color))),
                      Flexible(child: Text(formatMoney(_monthly, cur), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: Text('Total interest', style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall!.color))),
                      Flexible(child: Text('+${formatMoney(interest, cur)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: Text('Total to pay', style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall!.color))),
                      Flexible(child: Text(formatMoney(totalPayable, cur), style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'First due ${schedule.isEmpty ? '—' : formatDateShort(schedule.first.dueDate.toIso8601String().substring(0, 10))}',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall!.color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(child: Text('$_term payments', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  if (_averageIncome > 0 && monthly > 0) ...[
                    const Divider(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Vs. avg monthly income ${formatMoney(_averageIncome, cur, decimals: 0)}',
                            style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall!.color),
                          ),
                        ),
                        Pill(
                          ratio > 30 ? 'High · ${ratio.toStringAsFixed(0)}%' : 'OK · ${ratio.toStringAsFixed(0)}%',
                          ratio > 30 ? AppColors.danger : AppColors.income,
                        ),
                      ],
                    ),
                    if (ratio > 30)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'This eats more than 30% of your average income. Consider a lower amount or longer term.',
                          style: TextStyle(fontSize: 12, color: AppColors.danger),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(_saving ? 'Saving...' : (widget.loan == null ? 'Add loan' : 'Save changes')),
          ),
        ],
      ),
    );
  }

  String _ordinal(int n) {
    if (n == 1 || n == 21) return '${n}st';
    if (n == 2 || n == 22) return '${n}nd';
    if (n == 3 || n == 23) return '${n}rd';
    return '${n}th';
  }
}