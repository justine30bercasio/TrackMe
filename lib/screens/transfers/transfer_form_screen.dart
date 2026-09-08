import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/payment_methods.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';

class TransferFormScreen extends StatefulWidget {
  final Transfer? transfer;
  final String? initialFromMethod;

  const TransferFormScreen({super.key, this.transfer, this.initialFromMethod});

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late bool _isEdit;
  late String _fromMethod;
  late String _toMethod;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.transfer != null;
    final t = widget.transfer;
    if (t != null) {
      _fromMethod = t.fromMethod;
      _toMethod = t.toMethod;
      _amountController.text = t.amount.toStringAsFixed(2);
      _date = DateTime.tryParse(t.transferDate) ?? DateTime.now();
      _notesController.text = t.notes;
    } else {
      _fromMethod = widget.initialFromMethod ?? 'cash';
      _toMethod = expensePaymentMethodCodes
          .firstWhere((m) => m != _fromMethod, orElse: () => 'gcash');
    }
  }

  @override
  void dispose() {
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

  String get _dateStr => _date.toIso8601String().substring(0, 10);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromMethod == _toMethod) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose two different accounts.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (_isEdit) {
        await AppRepository.instance.updateTransfer(
          widget.transfer!.id!,
          fromMethod: _fromMethod,
          toMethod: _toMethod,
          amount: amount,
          transferDate: _dateStr,
          notes: _notesController.text,
        );
      } else {
        await AppRepository.instance.addTransfer(
          fromMethod: _fromMethod,
          toMethod: _toMethod,
          amount: amount,
          transferDate: _dateStr,
          notes: _notesController.text,
        );
      }
      if (!mounted) return;
      context.read<AppState>().bumpData();
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'We couldn\'t save this transfer. Your information has not been lost.'),
        ),
      );
    }
  }

  Widget _methodField({
    required String label,
    required IconData icon,
    required String value,
    required ValueChanged<String> onChanged,
    required List<String> options,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
      items: options.map((m) {
        return DropdownMenuItem<String>(
          value: m,
          child: Row(
            children: [
              PaymentMethodBadge(code: m, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(paymentMethodLabel(m),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) => onChanged(v ?? value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = expensePaymentMethodCodes;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit transfer' : 'New transfer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₱ ',
                prefixIcon: Icon(Icons.currency_exchange),
              ),
              validator: (v) {
                final a = double.tryParse(v ?? '');
                if (a == null || a <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _methodField(
              label: 'From account',
              icon: Icons.unfold_more,
              value: _fromMethod,
              onChanged: (v) => setState(() => _fromMethod = v),
              options: options,
            ),
            const SizedBox(height: 14),
            _methodField(
              label: 'To account',
              icon: Icons.call_received,
              value: _toMethod,
              onChanged: (v) => setState(() => _toMethod = v),
              options: options,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surfaceDark2
                      : const Color(0xFFF0F1F6),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 20,
                        color: Theme.of(context).textTheme.bodySmall!.color),
                    const SizedBox(width: 10),
                    Text(formatDateShort(_dateStr),
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.sticky_note_2_outlined)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_isEdit ? 'Save changes' : 'Save transfer'),
            ),
            const SizedBox(height: 12),
            Text(
              'Transfers move money between your accounts. They are never counted as income or expense.',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall!.color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}