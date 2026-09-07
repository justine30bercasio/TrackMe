import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/providers/app_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  late Future<ReportData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ReportData> _load() => AppRepository.instance.getReportData(_month, _year);

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _pickMonthYear() async {
    final result = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => _MonthYearPicker(initialMonth: _month, initialYear: _year),
    );
    if (result != null && mounted) {
      setState(() {
        _month = result.month;
        _year = result.year;
      });
      _reload();
    }
  }

  Future<void> _exportPdf(ReportData data, String currency) async {
    try {
      final doc = pw.Document();
      final monthName = _monthNames[_month - 1];
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text('TrackMe Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('$monthName $_year', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 18),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pdfStat('Income', data.totalIncome, currency),
                _pdfStat('Expenses', data.totalExpenses, currency),
                _pdfStat('Net', data.netAmount, currency),
              ],
            ),
            pw.SizedBox(height: 22),
            pw.Text('Expenses by category', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            for (final e in data.expensesByCategory) _pdfRow(e.key, e.value, currency),
            pw.SizedBox(height: 22),
            pw.Text('Income by source', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            for (final e in data.incomeBySource) _pdfRow(e.key, e.value, currency),
            pw.SizedBox(height: 22),
            pw.Text('Year to date', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _pdfRow('Income', data.ytdIncome, currency),
            _pdfRow('Expenses', data.ytdExpenses, currency),
            _pdfRow('Net', data.ytdIncome - data.ytdExpenses, currency),
          ],
        ),
      );
      final bytes = await doc.save();
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'application/pdf', name: 'expense_report_$_year-$_month.pdf')],
        text: 'TrackMe report $monthName $_year',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not export PDF: $e')));
      }
    }
  }

  Future<void> _exportCsv(ReportData data, String currency) async {
    try {
      final rows = <List<Object>>[
        ['TrackMe Report', '${_monthNames[_month - 1]} $_year'],
        ['Income', data.totalIncome],
        ['Expenses', data.totalExpenses],
        ['Net', data.netAmount],
        [''],
        ['Expenses by category'],
        ['Category', 'Amount'],
        ...data.expensesByCategory.map((e) => <Object>[e.key, e.value]),
        [''],
        ['Income by source'],
        ['Source', 'Amount'],
        ...data.incomeBySource.map((e) => <Object>[e.key, e.value]),
        [''],
        ['Year to date'],
        ['Income', data.ytdIncome],
        ['Expenses', data.ytdExpenses],
        ['Net', data.ytdIncome - data.ytdExpenses],
      ];
      final bytes = utf8.encode('\uFEFF${const ListToCsvConverter().convert(rows)}');
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'text/csv', name: 'expense_report_$_year-$_month.csv')],
        text: 'TrackMe report ${_monthNames[_month - 1]} $_year',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not export CSV: $e')));
      }
    }
  }

  pw.Widget _pdfStat(String label, double value, String currency) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
        pw.Text(formatMoney(value, currency), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _pdfRow(String label, double value, String currency) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(formatMoney(value, currency)),
        ],
      ),
    );
  }

  static const List<String> _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppState>().currencyCode;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: () async {
              final data = await _future;
              await _exportCsv(data, currency);
            },
            icon: const Icon(Icons.table_chart_outlined),
          ),
          IconButton(
            tooltip: 'Export PDF',
            onPressed: () async {
              final data = await _future;
              await _exportPdf(data, currency);
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                InkWell(
                  onTap: _pickMonthYear,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : const Color(0xFFF0F1F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text('${_monthNames[_month - 1]} $_year', style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: () {
                    var m = _month - 1;
                    var y = _year;
                    if (m == 0) {
                      m = 12;
                      y--;
                    }
                    setState(() {
                      _month = m;
                      _year = y;
                    });
                    _reload();
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: () {
                    var m = _month + 1;
                    var y = _year;
                    if (m > 12) {
                      m = 1;
                      y++;
                    }
                    setState(() {
                      _month = m;
                      _year = y;
                    });
                    _reload();
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<ReportData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final data = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            label: 'Income',
                            value: MoneyText(data.totalIncome, currency, fontSize: 15, color: AppColors.income),
                            icon: Icons.arrow_downward,
                            iconColor: AppColors.income,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatTile(
                            label: 'Expenses',
                            value: MoneyText(data.totalExpenses, currency, fontSize: 15, color: AppColors.expense),
                            icon: Icons.arrow_upward,
                            iconColor: AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StatTile(
                      label: 'Net savings',
                      value: MoneyText(data.netAmount, currency, fontSize: 16, color: data.netAmount >= 0 ? AppColors.income : AppColors.expense, showSign: true),
                      icon: Icons.savings_outlined,
                      iconColor: data.netAmount >= 0 ? AppColors.income : AppColors.expense,
                    ),
                    if (data.expensesByCategory.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Expenses by category', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            for (final e in data.expensesByCategory)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Text(formatMoney(e.value, currency), style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (data.incomeBySource.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Income by source', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            for (final e in data.incomeBySource)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Text(formatMoney(e.value, currency), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.income)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text('Year to date', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _YtdRow(label: 'Total income', value: data.ytdIncome, currency: currency, color: AppColors.income),
                          _YtdRow(label: 'Total expenses', value: data.ytdExpenses, currency: currency, color: AppColors.expense),
                          _YtdRow(
                            label: 'Net savings',
                            value: data.ytdIncome - data.ytdExpenses,
                            currency: currency,
                            color: data.ytdIncome - data.ytdExpenses >= 0 ? AppColors.income : AppColors.expense,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _YtdRow extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final Color color;
  const _YtdRow({required this.label, required this.value, required this.currency, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(formatMoney(value, currency), style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _MonthYearPicker extends StatefulWidget {
  final int initialMonth;
  final int initialYear;
  const _MonthYearPicker({required this.initialMonth, required this.initialYear});

  @override
  State<_MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<_MonthYearPicker> {
  late int _month;
  late int _year;

  static const List<String> months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth;
    _year = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select month'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => setState(() => _year--), icon: const Icon(Icons.chevron_left)),
                  Expanded(child: Text('$_year', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  IconButton(onPressed: () => setState(() => _year++), icon: const Icon(Icons.chevron_right)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var m = 1; m <= 12; m++)
                    ChoiceChip(
                      label: Text(months[m - 1]),
                      selected: _month == m,
                      onSelected: (_) => setState(() => _month = m),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, DateTime(_year, _month, 1)),
          child: const Text('Show Report'),
        ),
      ],
    );
  }
}