import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/providers/app_state.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late Future<Insights> _future;
  int _lastVersion = -1;

  Future<Insights> _load() => AppRepository.instance.computeInsights();

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final version = context.watch<AppState>().dataVersion;
    if (_lastVersion != version) {
      _lastVersion = version;
      _future = _load();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<Insights>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final insights = snapshot.data!;
            final currency = context.watch<AppState>().currencyCode;
            final noData =
                insights.currentMonthTotal == 0 && insights.lastMonthTotal == 0;

            if (noData && insights.monthlyTrend.every((t) => t.total == 0)) {
              return EmptyState(
                icon: Icons.insights_outlined,
                title: 'No insights yet',
                message:
                    'Add some transactions and come back for smart analysis of your spending.',
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _ScoreCard(insights: insights, currency: currency),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'This month',
                        value: MoneyText(insights.currentMonthTotal, currency,
                            fontSize: 15, color: AppColors.expense),
                        icon: Icons.calendar_month,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        label: 'Last month',
                        value: MoneyText(insights.lastMonthTotal, currency,
                            fontSize: 15),
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                  ],
                ),
                if (insights.lastMonthTotal > 0) ...[
                  const SizedBox(height: 10),
                  _ChangeCard(insights: insights, currency: currency),
                ],
                if (insights.averageLast3Months > 0) ...[
                  const SizedBox(height: 10),
                  StatTile(
                    label: 'Avg. monthly spending (3 mo)',
                    value: MoneyText(insights.averageLast3Months, currency,
                        fontSize: 15),
                    icon: Icons.stacked_line_chart,
                  ),
                ],
                if (insights.categoryBreakdown.isNotEmpty) ...[
                  SectionTitle(
                    'This month by category',
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                  ),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final r in insights.categoryBreakdown)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      color: AppColors.colorFromHex(r.color),
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 100,
                                  child: Text(r.category,
                                      style: const TextStyle(fontSize: 12.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Expanded(
                                  child: SizedBox(
                                    height: 6,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: (r.percentage / 100)
                                            .clamp(0.0, 1.0),
                                        backgroundColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppColors.surfaceDark2
                                                : const Color(0xFFE9EBF2),
                                        valueColor: AlwaysStoppedAnimation(
                                            AppColors.colorFromHex(r.color)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(formatMoney(r.total, currency),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                SizedBox(
                                  width: 34,
                                  child: Text(
                                      '${r.percentage.toStringAsFixed(0)}%',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .color)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (insights.monthlyTrend.isNotEmpty) ...[
                  SectionTitle('12-month trend',
                      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10)),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 180,
                      child:
                          _TrendChart(insights: insights, currency: currency),
                    ),
                  ),
                ],
                if (insights.forecast != null) ...[
                  SectionTitle('Spending forecast',
                      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10)),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              insights.forecast!.trend == 'increasing'
                                  ? Icons.trending_up
                                  : insights.forecast!.trend == 'decreasing'
                                      ? Icons.trending_down
                                      : Icons.trending_flat,
                              color: insights.forecast!.trend == 'increasing'
                                  ? AppColors.expense
                                  : insights.forecast!.trend == 'decreasing'
                                      ? AppColors.income
                                      : AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                insights.forecast!.trend == 'increasing'
                                    ? 'Spending is projected to increase'
                                    : insights.forecast!.trend == 'decreasing'
                                        ? 'Spending is projected to decrease'
                                        : 'Spending is projected to stay steady',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 130,
                          child: _ForecastChart(
                              insights: insights, currency: currency),
                        ),
                      ],
                    ),
                  ),
                ],
                if (insights.dayOfWeekAnalysis.any((d) => d.total > 0)) ...[
                  SectionTitle('Spending by day of week',
                      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10)),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: _DayOfWeekBar(
                        rows: insights.dayOfWeekAnalysis, currency: currency),
                  ),
                ],
                if (insights.anomalies.isNotEmpty) ...[
                  SectionTitle('Unusual spending',
                      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10)),
                  ...insights.anomalies
                      .take(6)
                      .map((a) => _AnomalyCard(anomaly: a, currency: currency)),
                ],
                if (insights.topCategories.isNotEmpty) ...[
                  SectionTitle('Top categories (3 months)',
                      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10)),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final r in insights.topCategories)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                CategoryAvatar(
                                    name: r.category, color: r.color, size: 30),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(r.category,
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Text(formatMoney(r.total, currency),
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final Insights insights;
  final String currency;
  const _ScoreCard({required this.insights, required this.currency});

  @override
  Widget build(BuildContext context) {
    final score = insights.spendingScore;
    final color = score >= 80
        ? AppColors.income
        : score >= 60
            ? AppColors.secondary
            : score >= 40
                ? AppColors.warning
                : AppColors.danger;
    final label = insights.scoreRating.toUpperCase();

    return BrandHeroCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(AppColors.onHero),
                ),
              ),
              Column(
                children: [
                  Text('$score',
                      style: const TextStyle(
                          color: AppColors.onHero,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  Text('/ 100',
                      style: const TextStyle(
                          color: AppColors.onHeroMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spending Score',
                    style: const TextStyle(
                        color: AppColors.onHeroMuted, fontSize: 13)),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.onHero,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                          '${insights.currentMonthTotal.toStringAsFixed(2)} spent this month',
                          style: const TextStyle(
                              color: AppColors.onHeroMuted, fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeCard extends StatelessWidget {
  final Insights insights;
  final String currency;
  const _ChangeCard({required this.insights, required this.currency});

  @override
  Widget build(BuildContext context) {
    final up = insights.changePercent > 0;
    final color = up ? AppColors.expense : AppColors.income;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(up ? Icons.trending_up : Icons.trending_down, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              up
                  ? 'Spending increased vs last month'
                  : 'Spending decreased vs last month',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
          Text(
            '${up ? '+' : ''}${insights.changePercent.toStringAsFixed(1)}%',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final Insights insights;
  final String currency;
  const _TrendChart({required this.insights, required this.currency});

  @override
  Widget build(BuildContext context) {
    final rows = insights.monthlyTrend;
    final maxVal = rows.fold<double>(0, (m, r) => r.total > m ? r.total : m);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: safeMax / 3,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF262C38)
                : const Color(0xFFF0F2F7),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value >= 1000
                    ? '${(value / 1000).toStringAsFixed(0)}k'
                    : value.toStringAsFixed(0),
                style: TextStyle(
                    fontSize: 9.5,
                    color: Theme.of(context).textTheme.bodySmall!.color),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= rows.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(rows[i].label,
                      style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).textTheme.bodySmall!.color)),
                );
              },
            ),
          ),
        ),
        minY: 0,
        maxY: safeMax * 1.15,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceDark2
                    : Colors.white,
            getTooltipItems: (spots) => spots.map((s) {
              final row = rows[s.x.toInt()];
              return LineTooltipItem(
                '${row.label}\n${formatMoney(row.total, currency)}',
                TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 12),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < rows.length; i++)
                FlSpot(i.toDouble(), rows[i].total),
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastChart extends StatelessWidget {
  final Insights insights;
  final String currency;
  const _ForecastChart({required this.insights, required this.currency});

  @override
  Widget build(BuildContext context) {
    final forecast = insights.forecast!;
    final history = forecast.historyValues;
    final future = forecast.values;
    final allVals = [...history, ...future];
    final maxVal = allVals.fold<double>(0, (m, v) => v > m ? v : m);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    final historySpots = [
      for (var i = 0; i < history.length; i++) FlSpot(i.toDouble(), history[i])
    ];
    final futureSpots = [
      for (var i = 0; i < future.length; i++)
        FlSpot((history.length - 1 + i).toDouble(), future[i]),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: safeMax / 3,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF262C38)
                : const Color(0xFFF0F2F7),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                value >= 1000
                    ? '${(value / 1000).toStringAsFixed(0)}k'
                    : value.toStringAsFixed(0),
                style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).textTheme.bodySmall!.color),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i.isOdd) return const SizedBox();
                if (i < history.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(forecast.historyLabels[i],
                        style: TextStyle(
                            fontSize: 9,
                            color:
                                Theme.of(context).textTheme.bodySmall!.color)),
                  );
                }
                final idx = i - history.length + 1;
                if (idx >= 0 && idx < forecast.labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(forecast.labels[idx],
                        style:
                            TextStyle(fontSize: 9, color: AppColors.secondary)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        minY: 0,
        maxY: safeMax * 1.15,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceDark2
                    : Colors.white,
            getTooltipItems: (spots) => spots.map((s) {
              final x = s.x.toInt();
              String label;
              if (x < history.length) {
                label = forecast.historyLabels[x];
              } else {
                label = forecast.labels[x - history.length + 1];
              }
              return LineTooltipItem(
                '$label\n${formatMoney(s.y, currency)}',
                TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 12),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: historySpots,
            isCurved: true,
            color: AppColors.textSecondaryDark,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: futureSpots,
            isCurved: true,
            color: AppColors.secondary,
            barWidth: 2.5,
            dotData: FlDotData(
                show: true,
                getDotPainter: (s, p, rod, index) => FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.secondary,
                      strokeWidth: 0,
                    )),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.secondary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayOfWeekBar extends StatelessWidget {
  final List<DayOfWeekRow> rows;
  final String currency;
  const _DayOfWeekBar({required this.rows, required this.currency});

  @override
  Widget build(BuildContext context) {
    final maxVal = rows.fold<double>(0, (m, r) => r.total > m ? r.total : m);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 74,
                  child: Text(r.day,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: SizedBox(
                    height: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (r.total / safeMax).clamp(0.0, 1.0),
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.surfaceDark2
                                : const Color(0xFFE9EBF2),
                        valueColor: AlwaysStoppedAnimation(
                            r.day == 'Sunday' || r.day == 'Saturday'
                                ? AppColors.warning
                                : AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: Text(formatMoney(r.total, currency),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AnomalyCard extends StatelessWidget {
  final SpendingAnomaly anomaly;
  final String currency;
  const _AnomalyCard({required this.anomaly, required this.currency});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(anomaly.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text('${anomaly.category} · ',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall!.color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(formatMoney(anomaly.amount, currency),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger)),
              Flexible(
                child: Text(
                    ' vs avg ${formatMoney(anomaly.average, currency)} (${anomaly.ratio.toStringAsFixed(1)}x)',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall!.color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
