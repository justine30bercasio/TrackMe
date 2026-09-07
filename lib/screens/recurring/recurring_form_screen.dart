import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';

class RecurringFormScreen extends StatefulWidget {
  final RecurringTransaction? recurring;
  final int? initialCategoryId;
  final int? initialBillCategoryId;
  final String? initialDescription;
  final double? initialAmount;
  final String? initialPaymentMethod;
  final String? initialNotes;
  final int? initialDayOfMonth;
  const RecurringFormScreen({
    super.key,
    this.recurring,
    this.initialCategoryId,
    this.initialBillCategoryId,
    this.initialDescription,
    this.initialAmount,
    this.initialPaymentMethod,
    this.initialNotes,
    this.initialDayOfMonth,
  });

  @override
  State<RecurringFormScreen> createState() => _RecurringFormScreenState();
}

class _RecurringFormScreenState extends State<RecurringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  List<Category> _categories = [];
  List<BillCategory> _billCategories = [];
  int? _categoryId;
  int? _billCategoryId;
  String _frequency = 'monthly';
  int _dayOfMonth = 1;
  String _nextDueDate = _today();
  String? _endDate;
  String _paymentMethod = 'cash';
  final _maxOccController = TextEditingController();
  bool _saving = false;
  static String _today() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    final r = widget.recurring;
    if (r != null) {
      _categoryId = r.categoryId;
      _billCategoryId = r.billCategoryId;
      _descriptionController.text = r.description;
      _amountController.text = r.amount.toStringAsFixed(2);
      _frequency = r.frequency;
      _dayOfMonth = r.dayOfMonth ?? 1;
      _nextDueDate = r.nextDueDate;
      _endDate = r.endDate;
      _paymentMethod = r.paymentMethod;
      _notesController.text = r.notes;
      _maxOccController.text = r.maxOccurrences?.toString() ?? '';
    } else if (widget.initialAmount != null || widget.initialDescription != null) {
      _categoryId = widget.initialCategoryId;
      _billCategoryId = widget.initialBillCategoryId;
      _descriptionController.text = widget.initialDescription ?? '';
      _amountController.text = widget.initialAmount?.toStringAsFixed(2) ?? '';
      _paymentMethod = widget.initialPaymentMethod ?? 'cash';
      _notesController.text = widget.initialNotes ?? '';
      _dayOfMonth = widget.initialDayOfMonth ?? _todayDay();
    }
    _load();
  }

  static int _todayDay() => DateTime.now().day;

  Future<void> _load() async {
    final repo = AppRepository.instance;
    final cats = await repo.getCategories();
    final bills = await repo.getBillCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _billCategories = bills;
        if (_categoryId == null && cats.isNotEmpty) _categoryId = cats.first.id;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _maxOccController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate() == false) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a category.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await AppRepository.instance.saveRecurringTransaction(
        id: widget.recurring?.id,
        categoryId: _categoryId!,
        billCategoryId: _billCategoryId,
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.replaceAll(',', '')),
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim(),
        frequency: _frequency,
        dayOfMonth: _frequency == 'monthly' ? _dayOfMonth : null,
        nextDueDate: _nextDueDate,
        endDate: _endDate,
        maxOccurrences: int.tryParse(_maxOccController.text),
      );
      context.read<AppState>().bumpData();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_nextDueDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Next due date',
    );
    if (picked != null && mounted) {
      setState(() {
        _nextDueDate = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_endDate ?? '') ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'End date (optional)',
    );
    if (picked != null && mounted) {
      setState(() {
        _endDate = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.recurring != null;
    final cur = context.watch<AppState>().currencyCode;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Recurring' : 'New Recurring')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Description', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(hintText: 'e.g. Netflix subscription'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a description' : null,
            ),
            const SizedBox(height: 18),
            Text('Amount ($cur)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(prefixText: '${currencySymbol(cur)} '),
              validator: (v) {
                final val = double.tryParse((v ?? '').replaceAll(',', ''));
                if (val == null || val <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 18),
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _categoryId,
              isExpanded: true,
              items: [
                for (final c in _categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        CategoryAvatar(name: c.name, color: c.color, size: 24),
                        const SizedBox(width: 10),
                        Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
              decoration: const InputDecoration(hintText: 'Choose category'),
            ),
            const SizedBox(height: 18),
            Text('Bill type (optional)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _billCategoryId,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                for (final b in _billCategories)
                  DropdownMenuItem(value: b.id, child: Text(b.name)),
              ],
              onChanged: (v) => setState(() => _billCategoryId = v),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 18),
            Text('Frequency', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: [
                  for (var i = 0; i < AppStrings.recurringFrequencies.length; i++)
                    ButtonSegment(value: AppStrings.recurringFrequencies[i], label: Text(AppStrings.recurringFrequencyLabels[i])),
                ],
                selected: {_frequency},
                onSelectionChanged: (s) {
                  setState(() {
                    _frequency = s.first;
                    _dayOfMonth = DateTime.tryParse(_nextDueDate)?.day ?? DateTime.now().day;
                  });
                },
              ),
            ),
            if (_frequency == 'monthly') ...[
              const SizedBox(height: 14),
              Text('Day of month', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var d = 1; d <= 31; d++)
                    ChoiceChip(
                      label: Text('$d'),
                      selected: _dayOfMonth == d,
                      onSelected: (_) => setState(() => _dayOfMonth = d),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Text('Next due date', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : const Color(0xFFF0F1F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(formatDateShort(_nextDueDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End date (optional)', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickEndDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : const Color(0xFFF0F1F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _endDate != null ? formatDateShort(_endDate!) : 'None',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_endDate != null)
                                GestureDetector(
                                  onTap: () => setState(() => _endDate = null),
                                  child: const Icon(Icons.close, size: 16),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Max occurrences', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _maxOccController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Unlimited'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
            const SizedBox(height: 18),
            Text('Notes', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Optional notes'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_saving ? 'Saving...' : isEdit ? 'Update Recurring' : 'Create Recurring'),
            ),
          ],
        ),
      ),
    );
  }
}