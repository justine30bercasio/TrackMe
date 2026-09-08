import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/payment_methods.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/transfers/transfer_form_screen.dart';

class TransfersListScreen extends StatefulWidget {
  const TransfersListScreen({super.key});

  @override
  State<TransfersListScreen> createState() => _TransfersListScreenState();
}

class _TransfersListScreenState extends State<TransfersListScreen> {
  List<Transfer> _transfers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final transfers = await AppRepository.instance.getTransfers();
    if (!mounted) return;
    setState(() {
      _transfers = transfers;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TransferFormScreen()),
    );
    if (created == true) {
      context.read<AppState>().bumpData();
      await _load();
    }
  }

  Future<void> _confirmDelete(Transfer t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transfer?'),
        content: Text(
            'This moves ₱${t.amount.toStringAsFixed(2)} back between ${paymentMethodLabel(t.fromMethod)} and ${paymentMethodLabel(t.toMethod)}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AppRepository.instance.deleteTransfer(t.id!);
    context.read<AppState>().bumpData();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppState>().currencyCode;
    return Scaffold(
      appBar: AppBar(title: const Text('Transfers')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transfers.isEmpty
              ? const EmptyState(
                  icon: Icons.swap_horiz,
                  title: 'No transfers yet',
                  message:
                      'Move money between your accounts — e.g. BDO to GCash — and it will show up here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                  itemCount: _transfers.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final t = _transfers[index];
                    return AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      onLongPress: () => _confirmDelete(t),
                      child: Row(
                        children: [
                          PaymentMethodBadge(code: t.fromMethod, size: 36),
                          const SizedBox(width: 10),
                          Icon(Icons.arrow_forward,
                              size: 18,
                              color:
                                  Theme.of(context).textTheme.bodySmall!.color),
                          const SizedBox(width: 10),
                          PaymentMethodBadge(code: t.toMethod, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${paymentMethodLabel(t.fromMethod)} → ${paymentMethodLabel(t.toMethod)}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatDateShort(t.transferDate),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .color),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatMoney(t.amount, currency),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: AppColors.expense,
                            onPressed: () => _confirmDelete(t),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}