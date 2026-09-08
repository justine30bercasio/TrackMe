import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';

class CashFlowScreen extends StatefulWidget {
  const CashFlowScreen({super.key});

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
  final _affordController = TextEditingController();
  List<CashFlowEvent> _events = [];
  double _balance = 0;
  bool _loading = true;
  AffordabilityResult? _afford;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _affordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = AppRepository.instance;
    final events = await repo.getCashFlowForecast();
    final balance = await repo.totalBalance();
    if (!mounted) return;
    setState(() {
      _events = events;
      _balance = balance;
      _loading = false;
    });
  }

  Future<void> _check() async {
    final amount = double.tryParse(_affordController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount to check.')),
      );
      return;
    }
    setState(() => _checking = true);
    final result =
        await AppRepository.instance.checkAffordability(amount);
    if (!mounted) return;
    setState(() {
      _afford = result;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppState>().currencyCode;
    final projectedEnd =
        _events.fold(_balance, (sum, e) => sum + e.amount);
    final outgoing = _events.where((e) => !e.isIncome).fold<double>(
        0, (sum, e) => sum + e.amount.abs());
    final incoming = _events.where((e) => e.isIncome).fold<double>(
        0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Cash-flow forecast')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current balance',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .color)),
                        const SizedBox(height: 4),
                        Text(formatMoney(_balance, currency),
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .color)),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _Stat(
                                  label: 'Upcoming in',
                                  value: formatMoney(incoming, currency),
                                  color: AppColors.income),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _Stat(
                                  label: 'Obligations',
                                  value: formatMoney(-outgoing, currency),
                                  color: AppColors.danger),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _Stat(
                                  label: 'Projected',
                                  value: formatMoney(projectedEnd, currency),
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildAffordabilityCard(currency),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('Upcoming 45 days',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (_events.isEmpty)
                    EmptyState(
                      icon: Icons.event_repeat_outlined,
                      title: 'No scheduled money movements',
                      message: 'Add recurring bills, loan payments or debts '
                          'to see what\'s coming.',
                    )
                  else
                    _Timeline(events: _events, balance: _balance),
                ],
              ),
            ),
    );
  }

  Widget _buildAffordabilityCard(String currency) {
    final secondary = Theme.of(context).textTheme.bodySmall!.color!;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_outlined, size: 18),
              SizedBox(width: 8),
              Text('Can I afford this?',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _affordController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: 'e.g. 2500',
                    prefixText: '$currency ',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _check(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _checking ? null : _check,
                child: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Check'),
              ),
            ],
          ),
          if (_afford != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_afford!.affordable ? AppColors.income : AppColors.danger)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    _afford!.affordable
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: _afford!.affordable
                        ? AppColors.income
                        : AppColors.danger,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _afford!.affordable
                          ? 'You can afford this. Projected lowest balance is '
                              '${formatMoney(_afford!.projectedLowest, currency)} '
                              'over the next 45 days.'
                          : 'Careful: your projected balance would dip to '
                              '${formatMoney(_afford!.projectedLowest, currency)} '
                              'over the next 45 days.',
                      style: TextStyle(
                          fontSize: 13,
                          color: _afford!.affordable
                              ? AppColors.income
                              : AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'End balance: '
              '${formatMoney(_afford!.projectedEnd, currency)} '
              '(est.)',
              style: TextStyle(fontSize: 12, color: secondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).textTheme.bodySmall!.color!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: secondary)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<CashFlowEvent> events;
  final double balance;

  const _Timeline({required this.events, required this.balance});

  @override
  Widget build(BuildContext context) {
    String? currentKey;
    var running = balance;
    final chunks = <Widget>[];

    for (final e in events) {
      running += e.amount;
      final key = '${e.date.year}-${e.date.month}-${e.date.day}';
      if (key != currentKey) {
        currentKey = key;
        chunks.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
          child: Text(formatDateShort(e.date.toIso8601String()),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodySmall!.color)),
        ));
      }
      chunks.add(AppCard(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (e.isIncome ? AppColors.income : AppColors.danger)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                e.isIncome ? Icons.south_west : Icons.north_east,
                size: 18,
                color: e.isIncome ? AppColors.income : AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(_kindLabel(e.kind),
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .color)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${e.isIncome ? '+' : '-'}'
                  '${e.amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: e.isIncome ? AppColors.income : AppColors.danger,
                  ),
                ),
                const SizedBox(height: 2),
                Text('→ ${running.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall!.color)),
              ],
            ),
          ],
        ),
      ));
    }
    return Column(children: chunks);
  }

  String _kindLabel(String kind) {
    switch (kind) {
      case 'recurring':
        return 'Recurring bill';
      case 'loan':
        return 'Loan payment';
      case 'debt':
        return 'Debt';
      case 'custom':
        return 'Hypothetical';
      default:
        return 'Scheduled';
    }
  }
}