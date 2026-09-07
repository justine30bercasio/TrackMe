import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';

class BudgetFormScreen extends StatefulWidget {
  final Budget? budget;
  const BudgetFormScreen({super.key, this.budget});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  List<Category> _categories = [];
  int? _categoryId;
  String _period = 'monthly';
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _carryover = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    if (b != null) {
      _categoryId = b.categoryId;
      _period = b.period;
      _amountController.text = b.limitAmount.toStringAsFixed(2);
      _notesController.text = b.notes;
      _carryover = b.carryoverEnabled;
      _month = b.month ?? DateTime.now().month;
      _year = b.year ?? DateTime.now().year;
    }
    _load();
  }

  Future<void> _load() async {
    final cats = await AppRepository.instance.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        if (widget.budget == null || !cats.any((c) => c.id == _categoryId)) {
          if (cats.isNotEmpty) _categoryId = cats.first.id;
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
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
      await AppRepository.instance.saveBudget(
        id: widget.budget?.id,
        categoryId: _categoryId!,
        limitAmount: double.parse(_amountController.text),
        period: _period,
        month: _period == 'yearly' ? null : _month,
        year: _year,
        notes: _notesController.text,
        carryoverEnabled: _carryover,
      );
      if (!mounted) return;
      context.read<AppState>().bumpData();
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickDate() async {
    final initial = DateTime(_year, _month, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Budget period start',
    );
    if (picked != null && mounted) {
      setState(() {
        _month = picked.month;
        _year = picked.year;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.budget != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Budget' : 'New Budget')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _categoryId,
              isExpanded: true,
              items: [
                for (final c in _categories)
                  DropdownMenuItem(value: c.id, child: _CategoryOption(c)),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
              decoration: const InputDecoration(hintText: 'Choose category'),
            ),
            const SizedBox(height: 18),
            Text('Monthly limit ($currencyCode)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(prefixText: '${currencySymbol(currencyCode)} '),
              validator: (v) {
                final val = double.tryParse((v ?? '').replaceAll(',', ''));
                if (val == null || val <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 18),
            Text('Period', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (var i = 0; i < AppStrings.budgetPeriods.length; i++)
                  ButtonSegment(value: AppStrings.budgetPeriods[i], label: Text(AppStrings.budgetPeriodLabels[i])),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
            const SizedBox(height: 18),
            Text('Period start', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            InkWell(
              onTap: _period == 'yearly' ? null : _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : const Color(0xFFF0F1F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(_period == 'yearly' ? '$_year' : '${_monthName(_month)} $_year'),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodySmall!.color),
                  ],
                ),
              ),
            ),
            if (_period == 'yearly') ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _year = _year - 1),
                      child: const Text('‹ Previous'),
                    ),
                  ),
                  Text('$_year', style: Theme.of(context).textTheme.titleMedium),
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _year = _year + 1),
                      child: const Text('Next ›'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Carry over unused budget'),
              subtitle: const Text('Surplus from this period rolls into the next one'),
              value: _carryover,
              onChanged: (v) => setState(() => _carryover = v),
            ),
            const SizedBox(height: 18),
            Text('Notes', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Optional notes'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_saving ? 'Saving...' : isEdit ? 'Update Budget' : 'Create Budget'),
            ),
          ],
        ),
      ),
    );
  }

  String get currencyCode => context.watch<AppState>().currencyCode;

  String _monthName(int m) {
    const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return names[m - 1];
  }
}

class _CategoryOption extends StatelessWidget {
  final Category category;
  const _CategoryOption(this.category);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CategoryAvatar(name: category.name, color: category.color, size: 26),
        const SizedBox(width: 10),
        Expanded(child: Text(category.name, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}