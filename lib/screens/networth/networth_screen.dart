import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/providers/app_state.dart';

class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  int _year = DateTime.now().year;
  late Future<NetWorthData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<NetWorthData> _load() => AppRepository.instance.getNetWorth(_year);

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _exportCsv(NetWorthData data) async {
    try {
      final rows = <List<Object>>[
        ['TrackMe Net Worth', _year],
        ['Item', 'Amount'],
        ['Current net worth', data.currentNetWorth],
        ['All-time income', data.totalIncome],
        ['All-time expenses', data.totalExpenses],
        [''],
        ['Month', 'Income', 'Expenses', 'Net'],
        ...data.breakdown.map((b) => <Object>[b.label, b.income, b.expenses, b.net]),
      ];
      final bytes = utf8.encode('\uFEFF${const ListToCsvConverter().convert(rows)}');
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'text/csv', name: 'net_worth_$_year.csv')],
        text: 'TrackMe net worth $_year',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not export CSV: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Net Worth'),
        actions: [
          IconButton(
            onPressed: () async {
              final data = await _future;
              await _exportCsv(data);
            },
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
          ),
          IconButton(
            onPressed: () {
              setState(() => _year--);
              _reload();
            },
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: () {
              setState(() => _year++);
              _reload();
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: FutureBuilder<NetWorthData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final currency = context.watch<AppState>().currencyCode;
          final positive = data.currentNetWorth >= 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF334155)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current net worth · $_year', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      '${positive ? '' : '-'}${currencySymbol(currency)}${data.currentNetWorth.abs().toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(label: 'All-time income', value: formatMoney(data.totalIncome, currency), color: const Color(0xFF7CFFD8)),
                        ),
                        Expanded(
                          child: _MiniStat(label: 'All-time expenses', value: formatMoney(data.totalExpenses, currency), color: const Color(0xFFFFB7C5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('$_year monthly breakdown', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendDot(color: AppColors.income, label: 'Income'),
                    const SizedBox(height: 8),
                    _LegendDot(color: AppColors.expense, label: 'Expenses'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _MonthlyChart(breakdown: data.breakdown, currency: currency),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('Monthly detail', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...data.breakdown.map((b) => AppCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(b.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Flexible(
                          child: Text(formatMoney(b.income, currency), style: const TextStyle(fontSize: 12, color: AppColors.income), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(formatMoney(b.expenses, currency), style: const TextStyle(fontSize: 12, color: AppColors.expense), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          child: Text(
                            formatMoney(b.net, currency),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: b.net >= 0 ? AppColors.income : AppColors.expense,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<MonthlyBreakdown> breakdown;
  final String currency;
  const _MonthlyChart({required this.breakdown, required this.currency});

  @override
  Widget build(BuildContext context) {
    final maxVal = breakdown.fold<double>(0, (m, b) => [m, b.income, b.expenses].reduce((a, c) => a > c ? a : c));
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: safeMax / 3,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF262C38) : const Color(0xFFF0F2F7),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : value.toStringAsFixed(0),
                style: TextStyle(fontSize: 9.5, color: Theme.of(context).textTheme.bodySmall!.color),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= breakdown.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(breakdown[i].label.split(' ').first, style: TextStyle(fontSize: 9.5, color: Theme.of(context).textTheme.bodySmall!.color)),
                );
              },
            ),
          ),
        ),
        maxY: safeMax * 1.1,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final b = breakdown[group.x];
              return BarTooltipItem(
                '${b.label}\n${rodIndex == 0 ? 'Income' : 'Expense'}: ${formatMoney(rod.toY, currency)}',
                TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 11, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        barGroups: List.generate(breakdown.length, (i) => BarChartGroupData(
              x: i,
              barsSpace: 2,
              barRods: [
                BarChartRodData(toY: breakdown[i].income, color: AppColors.income, width: 5, borderRadius: const BorderRadius.all(Radius.circular(2))),
                BarChartRodData(toY: breakdown[i].expenses, color: AppColors.expense, width: 5, borderRadius: const BorderRadius.all(Radius.circular(2))),
              ],
            )),
      ),
    );
  }
}