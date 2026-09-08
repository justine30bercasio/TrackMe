import 'package:flutter/material.dart';

import 'package:track_me/data/models.dart';

class DebtPaymentSheet extends StatefulWidget {
  final Debt debt;

  const DebtPaymentSheet({super.key, required this.debt});

  @override
  State<DebtPaymentSheet> createState() => _DebtPaymentSheetState();
}

class _DebtPaymentSheetState extends State<DebtPaymentSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_controller.text) ?? 0;
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.debt.remainingAmount;
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
            Text('Record payment',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '${widget.debt.person} · ${remaining.toStringAsFixed(2)} remaining',
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall!.color),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount paid',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (v) {
                final a = double.tryParse(v ?? '');
                if (a == null || a <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Save payment'),
            ),
          ],
        ),
      ),
    );
  }
}