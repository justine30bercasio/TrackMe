import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/providers/app_state.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  int _type = 0; // 0 expenses, 1 income
  bool _importing = false;
  String? _lastResult;

  Future<void> _pickAndImport() async {
    setState(() => _importing = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _importing = false);
        return;
      }
      final file = result.files.single;
      final path = file.path;
      if (path == null) {
        if (mounted) setState(() => _importing = false);
        return;
      }
      final content = await File(path).readAsString();
      final rows = const CsvToListConverter(shouldParseNumbers: false).convert(content);
      if (rows.isEmpty) {
        _finish(null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data rows found in the CSV file.')));
        }
        return;
      }

      final header = rows.first.map((e) => e.toString().toLowerCase()).toList();
      final dataRows = rows.skip(1).map((r) => r.map((e) => e.toString()).toList()).toList();

      int imported = 0;
      int failed = 0;
      final repo = AppRepository.instance;
      for (final row in dataRows) {
        try {
          final map = _rowToMap(header, row);
          if (_type == 0) {
            final description = map['description'] ?? map['title'] ?? map['name'] ?? '';
            final amount = double.tryParse(_num(map['amount'] ?? map['value'] ?? ''));
            final date = _parseDate(map['date'] ?? map['expense_date'] ?? map['expense date'] ?? '');
            if (description.isEmpty || amount == null || amount <= 0 || date == null) {
              failed++;
              continue;
            }
            String? categoryName = map['category'] ?? map['category_name'] ?? map['category name'];
            if (categoryName != null) categoryName = categoryName.trim();
            int categoryId;
            final existing = await repo.getCategoryByName(categoryName ?? 'Other');
            if (existing != null && existing.id != null) {
              categoryId = existing.id!;
            } else {
              final created = await repo.addCategory(categoryName ?? 'Other');
              categoryId = created.id!;
            }
            final payment = _paymentMethod(map['payment_method'] ?? map['payment method'] ?? 'cash');
            await repo.saveExpense(
              categoryId: categoryId,
              description: description,
              amount: amount,
              expenseDate: date,
              notes: map['notes'] ?? '',
              paymentMethod: payment,
              currencyCode: (map['currency'] ?? map['currency_code'] ?? '').toString().toUpperCase().isEmpty ? 'USD' : (map['currency'] ?? map['currency_code'] ?? '').toString().toUpperCase(),
              ignoreDuplicate: true,
            );
            imported++;
          } else {
            final source = map['source'] ?? map['income_source'] ?? map['source name'] ?? 'Other';
            final amount = double.tryParse(_num(map['amount'] ?? map['value'] ?? ''));
            final date = _parseDate(map['date'] ?? map['income_date'] ?? map['income date'] ?? '');
            if (source.isEmpty || amount == null || amount <= 0 || date == null) {
              failed++;
              continue;
            }
            final payment = _paymentMethod(map['payment_method'] ?? map['payment method'] ?? 'bank_transfer');
            await repo.saveIncome(
              source: source,
              amount: amount,
              incomeDate: date,
              notes: map['notes'] ?? '',
              paymentMethod: payment,
              currencyCode: (map['currency'] ?? map['currency_code'] ?? '').toString().toUpperCase().isEmpty ? 'USD' : (map['currency'] ?? map['currency_code'] ?? '').toString().toUpperCase(),
              ignoreDuplicate: true,
            );
            imported++;
          }
        } catch (_) {
          failed++;
        }
      }
      _finish('Imported $imported record(s)${failed > 0 ? ', $failed failed' : ''} from ${file.name}.');
    } catch (e) {
      _finish(null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import error: $e')));
      }
    }
  }

  void _finish(String? result) {
    if (!mounted) return;
    setState(() {
      _importing = false;
      _lastResult = result;
    });
    if (result != null) {
      context.read<AppState>().bumpData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  String _num(String v) => v.replaceAll(',', '').replaceAll(' ', '').replaceAll(r'$', '');

  String? _parseDate(String v) {
    final trimmed = v.trim();
    if (trimmed.isEmpty) return null;
    final fmts = [
      'yyyy-MM-dd', 'MM/dd/yyyy', 'dd/MM/yyyy', 'MMM d, yyyy', 'yyyy/MM/dd',
    ];
    for (final f in fmts) {
      try {
        final dt = DateTime.parse(trimmed);
        return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {
        try {
          final parsed = DateFormat(f).parseStrict(trimmed);
          return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  String _paymentMethod(String v) {
    final s = v.trim().toLowerCase().replaceAll(' ', '_');
    const valid = {'cash', 'credit_card', 'bank_transfer', 'check', 'other'};
    return valid.contains(s) ? s : 'other';
  }

  Map<String, String> _rowToMap(List<String> header, List<String> row) {
    final map = <String, String>{};
    for (var i = 0; i < header.length && i < row.length; i++) {
      map[header[i]] = row[i];
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import CSV')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Import type', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Expenses')),
              ButtonSegment(value: 1, label: Text('Income')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_type == 0 ? 'Expense CSV columns' : 'Income CSV columns', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(_type == 0
                    ? 'description, amount, date, category, payment_method, notes, currency\nDate formats accepted: yyyy-MM-dd, MM/dd/yyyy, dd/MM/yyyy'
                    : 'source, amount, date, payment_method, notes, currency\nDate formats accepted: yyyy-MM-dd, MM/dd/yyyy, dd/MM/yyyy'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _importing ? null : _pickAndImport,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(_importing ? 'Importing...' : 'Choose CSV file'),
          ),
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            Text(_lastResult!, style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          Text(
            'Duplicate records are skipped automatically.',
            style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall!.color),
          ),
        ],
      ),
    );
  }
}