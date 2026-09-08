import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/payment_methods.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/wallet/account_detail_screen.dart';

const List<String> _groupOrder = [
  'Cash',
  'E-Wallets',
  'Banks',
  'Credit',
  'Other'
];

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  /// Maps a payment method code to its Wallet group label.
  static String groupFor(String code) {
    if (code == 'cash') return 'Cash';
    if (code == 'credit_card') return 'Credit';
    final info = paymentMethodInfo(code);
    if (info?.group == 'wallet') return 'E-Wallets';
    if (info?.group == 'bank' ||
        code == 'bank_transfer' ||
        code == 'debit_card' ||
        code == 'check') {
      return 'Banks';
    }
    return 'Other';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: FutureBuilder<Map<String, PaymentMethodStat>>(
        future: AppRepository.instance.paymentMethodStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child:
                    Text('We couldn\'t load your accounts. Please try again.'));
          }
          final stats = snapshot.data!;
          final currency = context.watch<AppState>().currencyCode;
          final hide = context.watch<AppState>().hideBalances;
          if (stats.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No accounts yet',
              message:
                  'Add your first expense or income and TrackMe will organize your money here by Cash, E-Wallets, Banks and Credit.',
            );
          }

          final total =
              stats.values.fold<double>(0, (sum, s) => sum + s.balance);
          final grouped = <String, List<MapEntry<String, PaymentMethodStat>>>{};
          for (final entry in stats.entries) {
            final group = groupFor(entry.key);
            grouped.putIfAbsent(group, () => []).add(entry);
          }

          return RefreshIndicator(
            onRefresh: () async {
              final appState = context.read<AppState>();
              appState.bumpData();
              await Future<void>.delayed(const Duration(milliseconds: 400));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                BrandHeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total balance',
                          style: TextStyle(
                              color: AppColors.onHeroMuted, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        visibleOrMasked(total, currency, hide),
                        style: const TextStyle(
                            color: AppColors.onHero,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${stats.length} account${stats.length == 1 ? '' : 's'} · ${stats.values.fold<int>(0, (sum, s) => sum + s.count)} transactions',
                        style: TextStyle(
                            color: AppColors.onHeroMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                for (final group in _groupOrder)
                  if (grouped[group] != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                      child: Text(group,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    for (final entry in (grouped[group]!)
                      ..sort(
                          (a, b) => b.value.balance.compareTo(a.value.balance)))
                      _AccountTile(
                          code: entry.key,
                          stat: entry.value,
                          currency: currency),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final String code;
  final PaymentMethodStat stat;
  final String currency;

  const _AccountTile(
      {required this.code, required this.stat, required this.currency});

  @override
  Widget build(BuildContext context) {
    final label = paymentMethodLabel(code);
    final hide = context.watch<AppState>().hideBalances;
    final color = stat.balance > 0
        ? AppColors.income
        : stat.balance < 0
            ? AppColors.expense
            : Theme.of(context).textTheme.bodySmall!.color;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => AccountDetailScreen(paymentMethodCode: code)),
      ),
      child: Row(
        children: [
          PaymentMethodBadge(code: code, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${stat.count} transaction${stat.count == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall!.color)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            visibleOrMasked(stat.balance, currency, hide),
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right,
              size: 20, color: Theme.of(context).textTheme.bodySmall!.color),
        ],
      ),
    );
  }
}
