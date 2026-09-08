import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/recurring/recurring_form_screen.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;
  final int? initialCategoryId;
  final double? initialAmount;
  final String? initialDescription;
  final DateTime? initialDate;
  final String? initialPaymentMethod;
  final String? initialNotes;
  final String? initialReceiptPath;
  final String? receiptOcrText;
  const ExpenseFormScreen({
    super.key,
    this.expense,
    this.initialCategoryId,
    this.initialAmount,
    this.initialDescription,
    this.initialDate,
    this.initialPaymentMethod,
    this.initialNotes,
    this.initialReceiptPath,
    this.receiptOcrText,
  });

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late bool _isEdit;
  int? _categoryId;
  int? _billCategoryId;
  DateTime _date = DateTime.now();
  String _paymentMethod = 'cash';
  String _currency = 'USD';
  String? _receiptPath;
  bool _saving = false;
  bool _autoCategorized = false;

  List<Category> _categories = [];
  List<BillCategory> _billCategories = [];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.expense != null;
    final e = widget.expense;
    if (e != null) {
      _descriptionController.text = e.description;
      _amountController.text = e.amount.toStringAsFixed(2);
      _notesController.text = e.notes;
      _categoryId = e.categoryId;
      _billCategoryId = e.billCategoryId;
      _date = DateTime.tryParse(e.expenseDate) ?? DateTime.now();
      _paymentMethod = e.paymentMethod;
      _currency = e.currencyCode;
    } else if (widget.initialCategoryId != null) {
      _categoryId = widget.initialCategoryId;
    }
    if (widget.expense == null) {
      if (widget.initialAmount != null) {
        _amountController.text = widget.initialAmount!.toStringAsFixed(2);
      }
      if (widget.initialDescription != null) {
        _descriptionController.text = widget.initialDescription!;
      }
      if (widget.initialDate != null) {
        _date = widget.initialDate!;
      }
      if (widget.initialPaymentMethod != null) {
        _paymentMethod = widget.initialPaymentMethod!;
      }
      if (widget.initialNotes != null &&
          widget.initialNotes!.trim().isNotEmpty) {
        _notesController.text = widget.initialNotes!;
      }
      if (widget.initialReceiptPath != null) {
        _receiptPath = widget.initialReceiptPath;
      }
    }
    _load();
  }

  Future<void> _load() async {
    final repo = AppRepository.instance;
    final cats = await repo.getCategories();
    final bcs = await repo.getBillCategories();
    final user = await repo.getUser();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _billCategories = bcs;
      _currency = widget.expense?.currencyCode ?? user.preferredCurrency;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
    if (file == null) return;
    String? copiedPath;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(dir.path, 'receipts'));
      if (!await receiptsDir.exists())
        await receiptsDir.create(recursive: true);
      final dest = p.join(receiptsDir.path,
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}');
      await File(file.path).copy(dest);
      copiedPath = dest;
    } catch (_) {
      copiedPath = file.path;
    }
    if (!mounted) return;
    setState(() {
      _receiptPath = copiedPath;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category first.')),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = AppRepository.instance;
    try {
      final result = await repo.saveExpense(
        id: widget.expense?.id,
        categoryId: _categoryId!,
        billCategoryId: _billCategoryId,
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        expenseDate: _dateStr(),
        notes: _notesController.text.trim(),
        paymentMethod: _paymentMethod,
        currencyCode: _currency,
        receiptImage: _receiptPath,
      );
      if (result.exceededBudget != null) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Budget exceeded'),
            content: Text(
                'You have exceeded your budget for ${result.exceededBudget?.categoryName ?? 'this category'}.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
      if (!mounted) return;
      if (widget.receiptOcrText != null) {
        await _attachReceiptRecord(result.expense.id);
      }
      context.read<AppState>().bumpData();
      Navigator.pop(context, true);
    } on DuplicateTransactionException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Duplicate expense'),
          content: Text(
              '${e.message}\n\nTap "Save anyway" to confirm this duplicate.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save anyway'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        setState(() => _saving = true);
        final confirmedResult = await repo.saveExpense(
          id: widget.expense?.id,
          categoryId: _categoryId!,
          billCategoryId: _billCategoryId,
          description: _descriptionController.text.trim(),
          amount: double.parse(_amountController.text),
          expenseDate: _dateStr(),
          notes: _notesController.text.trim(),
          paymentMethod: _paymentMethod,
          currencyCode: _currency,
          receiptImage: _receiptPath,
          ignoreDuplicate: true,
        );
        if (!mounted) return;
        if (widget.receiptOcrText != null) {
          await _attachReceiptRecord(confirmedResult.expense.id);
        }
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  Future<void> _attachReceiptRecord(int? expenseId) async {
    final path = _receiptPath;
    if (path == null || expenseId == null) return;
    try {
      final file = File(path);
      final size = await file.length();
      await AppRepository.instance.addReceipt(
        expenseId: expenseId,
        filePath: path,
        fileName: p.basename(path),
        fileSize: size,
        mimeType: 'image/jpeg',
        ocrText: widget.receiptOcrText,
      );
    } catch (_) {}
  }

  Future<void> _onDescriptionChanged(String value) async {
    if (_categoryId != null) return;
    if (_autoCategorized) return;
    if (value.trim().length < 3) return;
    final repo = AppRepository.instance;
    final categoryId = await repo.autoCategorize(value);
    if (categoryId != null && mounted) {
      setState(() {
        _categoryId = categoryId;
        _autoCategorized = true;
      });
    }
  }

  String _dateStr() {
    return '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Expense' : 'Add Expense'),
        actions: [
          IconButton(
            tooltip: 'Make recurring',
            icon: const Icon(Icons.repeat),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RecurringFormScreen(
                  initialCategoryId: _categoryId,
                  initialBillCategoryId: _billCategoryId,
                  initialDescription: _descriptionController.text.trim().isEmpty
                      ? null
                      : _descriptionController.text.trim(),
                  initialAmount: double.tryParse(
                      _amountController.text.replaceAll(',', '')),
                  initialPaymentMethod: _paymentMethod,
                  initialNotes: _notesController.text.trim().isEmpty
                      ? null
                      : _notesController.text.trim(),
                  initialDayOfMonth: _date.day,
                ),
              ));
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _HeaderCard(
              hintText: 'e.g. Lunch with friends',
              bigField: _amountController,
              descriptionController: _descriptionController,
              currency: _currency,
              onDescriptionChanged: _onDescriptionChanged,
            ),
            const SizedBox(height: 16),
            Text('Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _CategorySelector(
              categories: _categories,
              selectedId: _categoryId,
              onSelect: (id) => setState(() => _categoryId = id),
              clearable: true,
              onClear: () => setState(() {
                _categoryId = null;
                _autoCategorized = false;
              }),
            ),
            const SizedBox(height: 18),
            Text('Bill type (optional)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            DropdownButtonFormField<int?>(
              value: _billCategoryId,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.receipt_long_outlined)),
              items: [
                const DropdownMenuItem<int?>(
                    value: null, child: Text('Not a bill')),
                ..._billCategories.map((b) =>
                    DropdownMenuItem<int?>(value: b.id, child: Text(b.name))),
              ],
              onChanged: (v) => setState(() => _billCategoryId = v),
            ),
            const SizedBox(height: 14),
            Text('Date & Payment',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.surfaceDark2
                            : const Color(0xFFF0F1F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 20,
                              color:
                                  Theme.of(context).textTheme.bodySmall!.color),
                          const SizedBox(width: 10),
                          Text(formatDateShort(_dateStr()),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.wallet_outlined)),
                    items: AppStrings.expensePaymentMethods
                        .map((m) => DropdownMenuItem<String>(
                              value: m,
                              child: Row(
                                children: [
                                  PaymentMethodBadge(code: m, size: 22),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(paymentMethodLabel(m),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _paymentMethod = v ?? 'cash'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.sticky_note_2_outlined)),
            ),
            const SizedBox(height: 14),
            if (_receiptPath == null)
              OutlinedButton.icon(
                onPressed: _pickReceipt,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Attach receipt'),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image_outlined, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(p.basename(_receiptPath!),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _receiptPath = null),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white))
                  : Text(_isEdit ? 'Save Changes' : 'Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final TextEditingController bigField;
  final TextEditingController descriptionController;
  final String currency;
  final String hintText;
  final ValueChanged<String> onDescriptionChanged;

  const _HeaderCard({
    required this.bigField,
    required this.descriptionController,
    required this.currency,
    required this.hintText,
    required this.onDescriptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BrandHeroCard(
      tone: HeroCardTone.brand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount',
              style: TextStyle(color: AppColors.onHeroMuted, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currencySymbol(currency),
                  style: const TextStyle(
                      color: AppColors.onHero,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: bigField,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      color: AppColors.onHero,
                      fontSize: 32,
                      fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                        color: AppColors.onHero.withValues(alpha: 0.55)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descriptionController,
            onChanged: onDescriptionChanged,
            style: const TextStyle(color: AppColors.onHero),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle:
                  TextStyle(color: AppColors.onHero.withValues(alpha: 0.65)),
              prefixIcon:
                  const Icon(Icons.edit_outlined, color: AppColors.onHeroMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide:
                    BorderSide(color: AppColors.onHero.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide:
                    BorderSide(color: AppColors.onHero.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide:
                    const BorderSide(color: AppColors.onHero, width: 1.6),
              ),
              filled: true,
              fillColor: AppColors.onHero.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int> onSelect;
  final bool clearable;
  final VoidCallback onClear;

  const _CategorySelector({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    this.clearable = false,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Text('Add categories first in Settings > Categories.');
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (clearable)
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selectedId == null
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: selectedId == null
                        ? AppColors.primary
                        : Colors.transparent),
              ),
              child: const Text('Auto',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ),
        for (final c in categories)
          InkWell(
            onTap: () => onSelect(c.id!),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selectedId == c.id
                    ? AppColors.colorFromHex(c.color).withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selectedId == c.id
                      ? AppColors.colorFromHex(c.color)
                      : Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF262C38)
                          : const Color(0xFFE8EAF1),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.55),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(categoryIcon(c.name),
                        size: 16, color: AppColors.colorFromHex(c.color)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(c.name,
                          style: TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
