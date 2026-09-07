import 'package:flutter/material.dart';

import 'package:track_me/core/theme.dart';
import 'package:track_me/screens/assistant/assistant_screen.dart';
import 'package:track_me/screens/receipts/receipts_screen.dart';
import 'package:track_me/screens/receipts/scan_receipt_screen.dart';
import 'package:track_me/screens/recurring/recurring_form_screen.dart';
import 'package:track_me/screens/transactions/expense_form_screen.dart';
import 'package:track_me/screens/transactions/income_form_screen.dart';

class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: screen is AssistantScreen
            ? const RouteSettings(name: AssistantScreen.routeName)
            : null,
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
            Text('Quick add', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    label: 'Expense',
                    icon: Icons.remove_circle_outline,
                    color: AppColors.expense,
                    onTap: () => _open(context, const ExpenseFormScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    label: 'Income',
                    icon: Icons.add_circle_outline,
                    color: AppColors.income,
                    onTap: () => _open(context, const IncomeFormScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    label: 'Recurring',
                    icon: Icons.autorenew,
                    color: AppColors.secondary,
                    onTap: () => _open(context, const RecurringFormScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    label: 'Receipts',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.accent,
                    onTap: () => _open(context, const ReceiptsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    label: 'Scan receipt',
                    icon: Icons.document_scanner_outlined,
                    color: AppColors.primary,
                    onTap: () => _open(context, const ScanReceiptScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    label: 'Assistant',
                    icon: Icons.smart_toy_outlined,
                    color: AppColors.secondary,
                    onTap: () => _open(context, const AssistantScreen()),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 10),
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}