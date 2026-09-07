import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';

class CurrenciesScreen extends StatefulWidget {
  const CurrenciesScreen({super.key});

  @override
  State<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends State<CurrenciesScreen> {
  late Future<List<UserCurrency>> _future;
  int _lastVersion = -1;

  Future<List<UserCurrency>> _load() => AppRepository.instance.getCurrencies();

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _addCurrency() async {
    final existing = await AppRepository.instance.getCurrencies();
    final existingCodes = existing.map((c) => c.currencyCode).toSet();
    final available = AppStrings.supportedCurrencies.where((c) => !existingCodes.contains(c)).toList();
    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All supported currencies are already added.')));
      }
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Add currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            for (final c in available)
              ListTile(
                leading: Text(currencySymbol(c), style: const TextStyle(fontSize: 18)),
                title: Text('$c - ${AppStrings.currencyNames[c] ?? c}'),
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await AppRepository.instance.addCurrency(picked);
      context.read<AppState>().bumpData();
      _reload();
    }
  }

  Future<void> _setPrimary(UserCurrency currency) async {
    await AppRepository.instance.setPrimaryCurrency(currency.currencyCode);
    context.read<AppState>().reloadUser();
    context.read<AppState>().bumpData();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final version = context.watch<AppState>().dataVersion;
    if (_lastVersion != version) {
      _lastVersion = version;
      _future = _load();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currencies'),
        actions: [
          IconButton(tooltip: 'Add currency', onPressed: _addCurrency, icon: const Icon(Icons.add)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Exchange rates are used to convert amounts. Update them manually for offline use.',
              style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall!.color),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserCurrency>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.currency_exchange,
                    title: 'No currencies',
                    message: 'Add a currency to start converting.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c.isPrimary ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceDark2.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Center(
                              child: Text(currencySymbol(c.currencyCode), style: TextStyle(color: c.isPrimary ? AppColors.primary : Theme.of(context).textTheme.bodySmall!.color, fontWeight: FontWeight.w800, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('${c.currencyCode} - ${AppStrings.currencyNames[c.currencyCode] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    if (c.isPrimary) ...[
                                      const SizedBox(width: 6),
                                      const Pill('Primary', AppColors.primary),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: c.isPrimary ? null : () => _editRate(c),
                                  child: Row(
                                    children: [
                                      Text('1 USD = ', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color)),
                                      Flexible(
                                        child: Text(
                                          '${c.exchangeRate.toStringAsFixed(4)} ${c.currencyCode}',
                                          style: TextStyle(fontSize: 12, color: c.isPrimary ? Theme.of(context).textTheme.bodySmall!.color : AppColors.primary, fontWeight: c.isPrimary ? null : FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!c.isPrimary) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.edit, size: 12, color: AppColors.primary),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!c.isPrimary)
                            TextButton(
                              onPressed: () => _setPrimary(c),
                              child: const Text('Make primary'),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editRate(UserCurrency currency) async {
    final controller = TextEditingController(text: currency.exchangeRate.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Exchange rate ${currency.currencyCode}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: '1 USD equals how many?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      await AppRepository.instance.updateCurrencyRate(currency.currencyCode, result);
      context.read<AppState>().bumpData();
      _reload();
    }
  }
}