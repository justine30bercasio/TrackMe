import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';

class IncomeFormScreen extends StatefulWidget {
  final Income? income;
  final String? initialPaymentMethod;
  const IncomeFormScreen({super.key, this.income, this.initialPaymentMethod});

  @override
  State<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends State<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late bool _isEdit;
  DateTime _date = DateTime.now();
  String _paymentMethod = 'bank_transfer';
  String _currency = 'USD';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.income != null;
    final i = widget.income;
    if (i != null) {
      _sourceController.text = i.source;
      _amountController.text = i.amount.toStringAsFixed(2);
      _notesController.text = i.notes;
      _date = DateTime.tryParse(i.incomeDate) ?? DateTime.now();
      _paymentMethod = i.paymentMethod;
    } else if (widget.initialPaymentMethod != null) {
      _paymentMethod = widget.initialPaymentMethod!;
    }
    _load();
  }

  Future<void> _load() async {
    final user = await AppRepository.instance.getUser();
    if (!mounted) return;
    setState(() =>
        _currency = widget.income?.currencyCode ?? user.preferredCurrency);
  }

  @override
  void dispose() {
    _sourceController.dispose();
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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final repo = AppRepository.instance;
    try {
      await repo.saveIncome(
        id: widget.income?.id,
        source: _sourceController.text.trim(),
        amount: double.parse(_amountController.text),
        incomeDate: _dateStr(),
        notes: _notesController.text.trim(),
        paymentMethod: _paymentMethod,
        currencyCode: _currency,
      );
      if (!mounted) return;
      context.read<AppState>().bumpData();
      Navigator.pop(context, true);
    } on DuplicateTransactionException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Duplicate income'),
          content: Text(
              '${e.message}\n\nTap "Save anyway" to confirm this duplicate.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save anyway')),
          ],
        ),
      );
      if (confirm == true) {
        setState(() => _saving = true);
        await repo.saveIncome(
          id: widget.income?.id,
          source: _sourceController.text.trim(),
          amount: double.parse(_amountController.text),
          incomeDate: _dateStr(),
          notes: _notesController.text.trim(),
          paymentMethod: _paymentMethod,
          currencyCode: _currency,
          ignoreDuplicate: true,
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  String _dateStr() {
    return '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Income' : 'Add Income')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            BrandHeroCard(
              tone: HeroCardTone.income,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount',
                      style: TextStyle(
                          color: AppColors.onHeroMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currencySymbol(_currency),
                          style: const TextStyle(
                              color: AppColors.onHero,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(
                              color: AppColors.onHero,
                              fontSize: 32,
                              fontWeight: FontWeight.w800),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                                color:
                                    AppColors.onHero.withValues(alpha: 0.55)),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Source',
                prefixIcon: Icon(Icons.work_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a source' : null,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in AppStrings.incomeSources)
                  ChoiceChip(
                    label: Text(s),
                    selected: _sourceController.text.trim() == s,
                    onSelected: (_) =>
                        setState(() => _sourceController.text = s),
                  ),
              ],
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
                    items: AppStrings.incomePaymentMethods
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
                        setState(() => _paymentMethod = v ?? 'bank_transfer'),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981)),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white))
                  : Text(_isEdit ? 'Save Changes' : 'Save Income'),
            ),
          ],
        ),
      ),
    );
  }
}
