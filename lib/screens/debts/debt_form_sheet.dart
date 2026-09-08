import 'package:flutter/material.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';

class DebtFormSheet extends StatefulWidget {
  final Debt? debt;
  final String initialDirection;

  const DebtFormSheet({super.key, this.debt, this.initialDirection = 'owed_to_me'});

  @override
  State<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late bool _isEdit;
  late String _direction;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.debt != null;
    final d = widget.debt;
    if (d != null) {
      _personController.text = d.person;
      _amountController.text = d.amount.toStringAsFixed(2);
      _descriptionController.text = d.description;
      _direction = d.direction;
      _dueDate = DateTime.tryParse(d.dueDate ?? '');
    } else {
      _direction = widget.initialDirection;
    }
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final amount = double.tryParse(_amountController.text) ?? 0;
      final due = _dueDate?.toIso8601String().substring(0, 10);
      if (_isEdit) {
        await AppRepository.instance.updateDebt(
          widget.debt!.id!,
          person: _personController.text.trim(),
          direction: _direction,
          amount: amount,
          description: _descriptionController.text.trim(),
          dueDate: due,
        );
      } else {
        await AppRepository.instance.addDebt(
          person: _personController.text.trim(),
          direction: _direction,
          amount: amount,
          description: _descriptionController.text.trim(),
          dueDate: due,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('We couldn\'t save this record. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(_isEdit ? 'Edit record' : 'New money record',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'owed_to_me',
                    label: Text('Owed to me'),
                    icon: Icon(Icons.south_west)),
                ButtonSegment(
                    value: 'owed_by_me',
                    label: Text('I owe'),
                    icon: Icon(Icons.north_east)),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _personController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Person',
                hintText: 'e.g. Mark',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.currency_exchange),
              ),
              validator: (v) {
                final a = double.tryParse(v ?? '');
                if (a == null || a <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDueDate,
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
                    Text(
                      _dueDate == null
                          ? 'Due date (optional)'
                          : formatDateShort(
                              _dueDate!.toIso8601String()),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'What was it for? (optional)',
                prefixIcon: Icon(Icons.sticky_note_2_outlined),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_isEdit ? 'Save changes' : 'Add record'),
            ),
          ],
        ),
      ),
    );
  }
}