import 'package:flutter/material.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';

class TransactionFilters {
  final int? categoryId;
  final String? dateFrom;
  final String? dateTo;
  final double? amountMin;
  final double? amountMax;
  final String? paymentMethod;
  final String? source;

  TransactionFilters({
    this.categoryId,
    this.dateFrom,
    this.dateTo,
    this.amountMin,
    this.amountMax,
    this.paymentMethod,
    this.source,
  });
}

class TransactionFiltersSheet extends StatefulWidget {
  final int tab;
  final int? initialCategoryId;
  final String? initialDateFrom;
  final String? initialDateTo;
  final double? initialAmountMin;
  final double? initialAmountMax;
  final String? initialPayment;
  final String? initialSource;

  const TransactionFiltersSheet({
    super.key,
    required this.tab,
    this.initialCategoryId,
    this.initialDateFrom,
    this.initialDateTo,
    this.initialAmountMin,
    this.initialAmountMax,
    this.initialPayment,
    this.initialSource,
  });

  @override
  State<TransactionFiltersSheet> createState() => _TransactionFiltersSheetState();
}

class _TransactionFiltersSheetState extends State<TransactionFiltersSheet> {
  List<Category> _categories = [];
  int? _categoryId;
  String? _payment;
  String? _source;
  DateTime? _from;
  DateTime? _to;
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _payment = widget.initialPayment;
    _source = widget.initialSource;
    if (widget.initialDateFrom != null) _from = DateTime.tryParse(widget.initialDateFrom!);
    if (widget.initialDateTo != null) _to = DateTime.tryParse(widget.initialDateTo!);
    if (widget.initialAmountMin != null) _minController.text = widget.initialAmountMin!.toString();
    if (widget.initialAmountMax != null) _maxController.text = widget.initialAmountMax!.toString();
    _load();
  }

  Future<void> _load() async {
    final cats = await AppRepository.instance.getCategories();
    if (mounted) setState(() => _categories = cats);
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final from = await _pickDate('From date', _from);
    if (!mounted || from == null) return;
    final to = await _pickDate('To date', _to);
    if (to == null) return;
    setState(() {
      if (from.isAfter(to)) {
        _from = to;
        _to = from;
      } else {
        _from = from;
        _to = to;
      }
    });
  }

  Future<DateTime?> _pickDate(String title, DateTime? initial) async {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: title,
    );
  }

  String _d(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _apply() {
    Navigator.pop(context, TransactionFilters(
      categoryId: widget.tab == 0 ? _categoryId : null,
      dateFrom: _from != null ? _d(_from!) : null,
      dateTo: _to != null ? _d(_to!) : null,
      amountMin: _minController.text.isNotEmpty ? double.tryParse(_minController.text) : null,
      amountMax: _maxController.text.isNotEmpty ? double.tryParse(_maxController.text) : null,
      paymentMethod: _payment,
      source: _source,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final methods = widget.tab == 0 ? AppStrings.expensePaymentMethods : AppStrings.incomePaymentMethods;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Filters', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            if (widget.tab == 0) _label('Category'),
            if (widget.tab == 0) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _categoryId == null,
                    onSelected: (_) => setState(() => _categoryId = null),
                  ),
                  ..._categories.map((c) => ChoiceChip(
                        label: Text(c.name),
                        selected: _categoryId == c.id,
                        onSelected: (_) => setState(() => _categoryId = c.id),
                      )),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (widget.tab == 1) _label('Source'),
            if (widget.tab == 1) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _source == null,
                    onSelected: (_) => setState(() => _source = null),
                  ),
                  ...AppStrings.incomeSources.map((s) => ChoiceChip(
                        label: Text(s),
                        selected: _source == s,
                        onSelected: (_) => setState(() => _source = s),
                      )),
                ],
              ),
              const SizedBox(height: 12),
            ],
            _label('Date range'),
            InkWell(
              onTap: _pickRange,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : const Color(0xFFF0F1F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 20, color: Theme.of(context).textTheme.bodySmall!.color),
                    const SizedBox(width: 10),
                    Text(_from != null && _to != null
                        ? '${_d(_from!)}  to  ${_d(_to!)}'
                        : 'Any time'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _label('Payment method'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _payment == null,
                  onSelected: (_) => setState(() => _payment = null),
                ),
                ...methods.map((m) => ChoiceChip(
                      avatar: PaymentMethodBadge(code: m, size: 20),
                      label: Text(paymentShape(m)),
                      selected: _payment == m,
                      onSelected: (_) => setState(() => _payment = m),
                    )),
              ],
            ),
            const SizedBox(height: 14),
            _label('Amount range'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'Min'),
                  ),
                ),
                const Padding(padding: EdgeInsets.all(8), child: Text('—')),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'Max'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, TransactionFilters());
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(onPressed: _apply, child: const Text('Apply Filters')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

String paymentShape(String m) => paymentMethodLabel(m);