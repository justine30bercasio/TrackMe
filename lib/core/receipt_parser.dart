class ReceiptParseResult {
  final double? total;
  final DateTime? date;
  final String? merchant;
  final String? paymentMethodCode;
  final List<String> items;

  const ReceiptParseResult({
    this.total,
    this.date,
    this.merchant,
    this.paymentMethodCode,
    this.items = const [],
  });
}

class ReceiptParser {
  static final _moneyPattern = RegExp(
      r'(?:₱|P|p)\s?(\d{1,6}(?:[.,]\d{3})*(?:\.\d{1,2})?)|(?:PHP|Php|php|USD|US\$|pesos?|piso)\s?(\d{1,6}(?:[.,]\d{3})*(?:\.\d{1,2})?)|(\d{1,6}(?:[.,]\d{3})*(?:\.\d{2})\b)');

  static final _datePatterns = [
    RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
    RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2,4})'),
    RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{2,4})'),
    RegExp(
        r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sept|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2})(?:st|nd|rd|th)?[,]?\s+(\d{4})', caseSensitive: false),
    RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sept|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{4})', caseSensitive: false),
  ];

  static const _totalMarkers = [
    'total due',
    'grand total',
    'total amount',
    'amount due',
    'total:',
    'total',
    'amount',
    'net amount',
    'final total',
  ];

  static const _paymentHints = [
    (pattern: 'gcash', code: 'gcash'),
    (pattern: 'maya', code: 'maya'),
    (pattern: 'coins.ph', code: 'coins_ph'),
    (pattern: 'coins', code: 'coins_ph'),
    (pattern: 'shopeepay', code: 'shopeepay'),
    (pattern: 'grabpay', code: 'grabpay'),
    (pattern: 'grab', code: 'grabpay'),
    (pattern: 'paypal', code: 'paypal'),
    (pattern: 'bpi', code: 'bpi'),
    (pattern: 'bdo', code: 'bdo'),
    (pattern: 'unionbank', code: 'unionbank'),
    (pattern: 'bank transfer', code: 'bank_transfer'),
    (pattern: 'bank', code: 'bank_transfer'),
    (pattern: 'debit card', code: 'debit_card'),
    (pattern: 'credit card', code: 'credit_card'),
    (pattern: 'card', code: 'credit_card'),
    (pattern: 'cash', code: 'cash'),
  ];

  static const _genericLines = [
    'receipt',
    'invoice',
    'official receipt',
    'sales invoice',
    'order form',
    'order',
    'cashier',
    'thank',
    'visit us',
    'vat',
    'bep',
    'tin',
    'sold by',
    'tel no',
    'tel. no',
    'hotline',
    'store no',
    'branch',
    'qty',
    'item no',
    'serial',
    'no.',
    'date',
    'time',
    'or no',
    'transaction',
    'website',
    'www.',
  ];

  ReceiptParseResult parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final total = _extractTotal(lines);
    final date = _extractDate(lines);
    final merchant = _extractMerchant(lines, rawText);
    final payment = _extractPaymentMethod(rawText.toLowerCase());
    final items = _extractItems(lines);

    return ReceiptParseResult(
      total: total,
      date: date,
      merchant: merchant,
      paymentMethodCode: payment,
      items: items,
    );
  }

  double? _extractTotal(List<String> lines) {
    double? best;
    double? largest;

    for (final line in lines) {
      final lower = _clean(line.toLowerCase());
      final value = _firstAmountInLine(line);
      if (value == null) continue;

      if (largest == null || value > largest) largest = value;

      final isTotalLine = _totalMarkers.any((m) {
        final idx = lower.indexOf(m);
        if (idx < 0) return false;
        final afterLeft = lower.substring(idx + m.length);
        return afterLeft.length <= 20;
      });

      if (isTotalLine && (best == null || value > best)) best = value;
    }

    return best ?? largest;
  }

  double? _firstAmountInLine(String line) {
    for (final match in _moneyPattern.allMatches(line)) {
      for (var g = 1; g <= match.groupCount; g++) {
        final raw = match.group(g);
        if (raw == null) continue;
        try {
          final normalized = raw.replaceAll(RegExp(r'[^\d.]'), '');
          if (normalized.contains('.')) {
            final parts = normalized.split('.');
            if (parts.length == 2 && parts[1].length == 2) {
              return double.parse(normalized);
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  String _clean(String s) => s.replaceAll(RegExp('[^a-z0-9:,.: ]'), ' ');

  DateTime? _extractDate(List<String> lines) {
    final text = lines.join('\n');
    for (final pattern in _datePatterns) {
      final any = RegExp(pattern.pattern, caseSensitive: false);
      final m = any.firstMatch(text);
      if (m == null) continue;

      final isIso = pattern.pattern.startsWith(r'(\d{4})-');
      final includeWholeMonth = pattern.pattern.startsWith('(Jan');
      if (isIso) {
        final year = int.tryParse(m.group(1)!);
        final month = int.tryParse(m.group(2)!);
        final day = int.tryParse(m.group(3)!);
        if (year != null && day != null && month != null && _valid(day, month, year)) {
          return DateTime(year, month, day);
        }
      } else if (includeWholeMonth) {
        final month = _monthNumber(m.group(1)!);
        if (month == null) continue;
        final year = int.tryParse(m.group(3)!);
        final day = int.tryParse(m.group(2)!);
        if (year != null && day != null && _valid(day, month, year)) return DateTime(year, month, day);
      } else {
        final a = int.tryParse(m.group(1)!);
        final b = int.tryParse(m.group(2)!);
        var year = int.tryParse(m.group(3)!);
        if (year == null) continue;
        if (year < 100) year += 2000;
        if (a == null || b == null) continue;
        if (_valid(a, b, year)) return DateTime(year, b, a);
        if (_valid(b, a, year)) return DateTime(year, a, b);
      }
    }
    return null;
  }

  int? _monthNumber(String name) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'sept': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[name.toLowerCase().substring(0, 3)];
  }

  bool _valid(int day, int month, int year) {
    try {
      final d = DateTime(year, month, day);
      return d.year == year && d.month == month && d.day == day;
    } catch (_) {
      return false;
    }
  }

  String? _extractMerchant(List<String> lines, String rawText) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      final s = line.trim();
      if (s.length < 3) continue;
      if (_looksLikeDateLine(s)) continue;
      if (_firstAmountInLine(s) != null && line.length < 20) continue;
      final isGeneric = _genericLines.any((g) => lower.startsWith(g) || lower.contains(g));
      if (isGeneric) continue;
      if (RegExp(r'^\d+[\s.,/]').hasMatch(s)) continue;
      return _cleanupMerchant(s);
    }
    return null;
  }

  bool _looksLikeDateLine(String s) {
    for (final p in _datePatterns) {
      if (p.firstMatch(s) != null) return true;
    }
    return false;
  }

  String? _cleanupMerchant(String s) {
    var clean = s.trim();
    final commaIdx = clean.indexOf(',');
    if (commaIdx > 0) clean = clean.substring(0, commaIdx).trim();
    if (RegExp(r'^\d+').hasMatch(clean)) {
      final idx = clean.indexOf(' ');
      clean = idx > 0 ? clean.substring(idx + 1).trim() : clean;
    }
    return clean.isEmpty ? null : clean;
  }

  String? _extractPaymentMethod(String lowerText) {
    for (final hint in _paymentHints) {
      if (lowerText.contains(hint.pattern)) return hint.code;
    }
    return null;
  }

  List<String> _extractItems(List<String> lines) {
    final items = <String>[];

    for (final line in lines) {
      if (items.length >= 8) break;
      final s = line.trim();
      if (s.length < 5 || s.length > 60) continue;
      if (_looksLikeDateLine(s)) continue;
      if (_genericLines.any((g) => s.toLowerCase().contains(g))) continue;
      final hasNumber = _firstAmountInLine(s) != null || RegExp(r'\d').hasMatch(s);
      if (!hasNumber) continue;
      final lower = s.toLowerCase();
      final isTotal = _totalMarkers.any(lower.contains);
      if (isTotal) continue;
      final hasWords = RegExp(r'[A-Za-z]{2,}').hasMatch(s);
      if (!hasWords) continue;
      final cleaned = _cleanupMerchant(s);
      if (cleaned != null) items.add(cleaned);
    }

    return items.take(6).toList();
  }
}