const _expenseVerbs = [
  'paid',
  'pay',
  'spent',
  'spend',
  'spends',
  'spending',
  'bought',
  'buy',
  'buys',
  'purchased',
  'purchase',
  'cost',
  'costs',
  'billed',
  'charge',
  'charged',
  'bayad',
  'bayaran',
  'gastos',
  'gumastos',
  'namili',
  'bili',
  'bumili',
  'kumain',
  'kain',
  'ubos',
  'ginastos',
  'swipe',
  'settle',
  'refill',
];

const _incomeVerbs = [
  'salary',
  'sweldo',
  'sahod',
  'earned',
  'earn',
  'receives',
  'receive',
  'received',
  'bonus',
  'allowance',
  'commission',
  'payout',
  'sold',
  'sell',
  'benta',
  'refund',
  'profit',
  'income',
  'kita',
  'prize',
  'won',
];

const _moneyAnchors = ['pesos', 'peso', 'pesso', 'piso', 'php', '₱'];

const _paymentHints = [
  (word: 'gcash', code: 'gcash'),
  (word: 'maya', code: 'maya'),
  (word: 'coins', code: 'coins_ph'),
  (word: 'shopeepay', code: 'shopeepay'),
  (word: 'grab', code: 'grabpay'),
  (word: 'paypal', code: 'paypal'),
  (word: 'bpi', code: 'bpi'),
  (word: 'bdo', code: 'bdo'),
  (word: 'unionbank', code: 'unionbank'),
  (word: 'bank', code: 'bank_transfer'),
  (word: 'debit', code: 'debit_card'),
  (word: 'credit', code: 'credit_card'),
  (word: 'cash', code: 'cash'),
  (word: 'check', code: 'check'),
];

class AssistantDraft {
  final String type;
  final double amount;
  final String description;
  final String categoryKeyword;
  final String? paymentMethod;
  final DateTime date;

  const AssistantDraft({
    required this.type,
    required this.amount,
    required this.description,
    this.categoryKeyword = '',
    this.paymentMethod,
    required this.date,
  });
}

class AssistantIntent {
  final String kind;
  final String reply;
  final AssistantDraft? draft;
  final bool autoPost;

  const AssistantIntent({
    required this.kind,
    required this.reply,
    this.draft,
    this.autoPost = false,
  });
}

class AssistantService {
  AssistantService({required int salaryDay}) : _salaryDay = salaryDay;

  final int _salaryDay;

  static const helpText =
      "I can add transactions for you just by chatting. Try:\n\n"
      "\"I paid 100 pesos for food\" — logs an expense\n"
      "\"Bought groceries worth 500 via gcash\" — logs an expense\n"
      "\"I received my salary of 25000\" — logs income\n"
      "\"Paid 50 cash for gustos sa jeep\" — logs an expense\n\n"
      "Mention a payment method (cash, gcash, maya, bank…) and I'll use it. Tap Undo on any message I logged to remove it.";

  AssistantIntent respond(String rawMessage) {
    final message = rawMessage.trim();
    if (message.isEmpty) {
      return const AssistantIntent(
          kind: 'text',
          reply:
              'Hi! Tell me something like "I paid 100 pesos for food" and I will log it for you.');
    }
    final lower = message.toLowerCase();

    if (_isGreeting(lower)) {
      return AssistantIntent(
        kind: 'text',
        reply:
            'Hi! I\'m your TrackMe assistant. Just tell me what you paid or received — e.g. "I paid 100 pesos for food" — and I\'ll add it to your expenses automatically. Type "help" to see what I can do.',
      );
    }

    if (_isHelp(lower)) {
      return const AssistantIntent(kind: 'help', reply: helpText);
    }

    if (_isSalaryLoanQuestion(lower)) {
      return AssistantIntent(
        kind: 'loan',
        reply:
            'Your salary day is set to the ${_ordinal(_salaryDay)} of the month in Profile. Loan repayments are scheduled right on that day so you always have funds on payday.',
      );
    }

    if (_isSalaryInfo(lower)) {
      return AssistantIntent(
        kind: 'text',
        reply:
            'Your salary day is the ${_ordinal(_salaryDay)} of each month. I use it to schedule loan repayments and remind you about payday. You can change it in Settings > Profile.',
      );
    }

    final amount = _findAmount(message);
    final payment = _findPaymentMethod(lower);
    final type = amount != null ? _detectType(lower) : null;
    final category = _detectCategory(lower);
    final date = _detectDate(lower);

    if (amount == null) {
      if (type == null) {
        return const AssistantIntent(
          kind: 'text',
          reply:
              'I didn\'t catch a transaction there. Tell me something like:\n\n• "I paid 100 pesos for food"\n• "I received my salary 25000"\n\nType "help" to see more examples.',
        );
      }
      return AssistantIntent(
        kind: type,
        reply:
            'I see you want to log as ${type == 'expense' ? 'an expense' : 'income'}, but I couldn\'t find an amount. Example: "I paid 100 pesos for food".',
      );
    }

    if (type == null) {
      return AssistantIntent(
        kind: 'text',
        reply:
            'I found ₱${amount.toStringAsFixed(2)}, but I couldn\'t tell if it\'s an expense or income. Try "I paid X for Y" or "I received X".',
      );
    }

    final description = _buildDescription(lower, type, category);

    final draft = AssistantDraft(
      type: type,
      amount: amount,
      description: description,
      categoryKeyword: category,
      paymentMethod: payment,
      date: date,
    );

    final currencyNote =
        payment != null ? ' via ${_paymentLabel(payment)}' : '';

    if (!_hasStrongSignal(lower, amount)) {
      return AssistantIntent(
        kind: type,
        autoPost: false,
        draft: draft,
        reply:
            'Should I log ${type == 'expense' ? 'an expense of' : 'income of'} ₱${amount.toStringAsFixed(2)}'
            '${payment != null ? ' via ${_paymentLabel(payment)}' : ''}'
            '${category.isNotEmpty ? ' under ${_titleCase(category)}' : ''} for ${_dateLabel(date)}? '
            'Reply "yes" to confirm.',
      );
    }

    return AssistantIntent(
      kind: type,
      autoPost: true,
      draft: draft,
      reply:
          'Done! I logged ${type == 'expense' ? 'an expense of' : 'income of'} '
          '₱${amount.toStringAsFixed(2)}${currencyNote}'
          '${category.isNotEmpty ? ' under "${_titleCase(category)}"' : ''} for ${_dateLabel(date)}. '
          'It\'s now in your records. Tap "Undo" below to remove it.',
    );
  }

  bool _hasStrongSignal(String lower, double amount) {
    if (_expenseVerbs.any(lower.contains) || _incomeVerbs.any(lower.contains))
      return true;
    if (_moneyAnchors.any(lower.contains)) return true;
    return false;
  }

  bool _isGreeting(String lower) {
    return RegExp(
                r'\b(hi+|hello+|hey+|good\s*(morning|afternoon|evening)|kumusta|musta|kumusta)\b')
            .hasMatch(lower) &&
        lower.length < 60;
  }

  bool _isHelp(String lower) {
    return RegExp(
            r'\b(help|commands|what can you do|anong kaya mo|how to use|manual)\b')
        .hasMatch(lower);
  }

  bool _isSalaryLoanQuestion(String lower) {
    final salaryRelated = lower.split(' ').any((w) =>
        ['salary', 'sweldo', 'sahod', 'payday', 'due', 'emi'].contains(w));
    final loanRelated = [
      'loan',
      'utang',
      'repayment',
      'bayad ng loan',
      'amortization'
    ].any(lower.contains);
    return salaryRelated && loanRelated;
  }

  bool _isSalaryInfo(String lower) {
    return RegExp(
            r'\b(salary day|payday|sweldo|sahod|when.*salary|kelan.*sahod)\b')
        .hasMatch(lower);
  }

  String? _findPaymentMethod(String lower) {
    for (final hint in _paymentHints) {
      if (RegExp('\\b${hint.word}\\b').hasMatch(lower)) return hint.code;
    }
    return null;
  }

  String _detectType(String lower) {
    int expenseScore = 0;
    int incomeScore = 0;
    for (final v in _expenseVerbs) {
      if (RegExp('\\b$v\\b').hasMatch(lower)) expenseScore++;
    }
    for (final v in _incomeVerbs) {
      if (RegExp('\\b$v\\b').hasMatch(lower)) incomeScore++;
    }
    if (incomeScore > expenseScore) return 'income';
    if (expenseScore > 0) return 'expense';
    if (RegExp(r'paid|gastos|bayad|namili|kumain|bili').hasMatch(lower))
      return 'expense';
    return 'text';
  }

  String _detectCategory(String lower) {
    const map = [
      (
        keys: [
          'food',
          'lunch',
          'dinner',
          'breakfast',
          'merienda',
          'snack',
          'kain',
          'kumain',
          'coffee',
          'cafe',
          'restaurant',
          'grocery',
          'groceries',
          'mango'
        ],
        cat: 'Food'
      ),
      (
        keys: [
          'transport',
          'transpo',
          'fare',
          'gas',
          'fuel',
          'grab',
          'taxi',
          'jeep',
          'bus',
          'train',
          'toll',
          'parking'
        ],
        cat: 'Transportation'
      ),
      (
        keys: [
          'bills',
          'bill',
          'electric',
          'kuryente',
          'water',
          'tubig',
          'internet',
          'wifi',
          'broadband',
          'phone',
          'load',
          'rent',
          'utility'
        ],
        cat: 'Bills'
      ),
      (
        keys: [
          'shopping',
          'shirt',
          'clothes',
          'clothing',
          'mall',
          'store',
          'gadget',
          'shoe',
          'shoes'
        ],
        cat: 'Shopping'
      ),
      (
        keys: [
          'movie',
          'cinema',
          'concert',
          'netflix',
          'spotify',
          'game',
          'gaming',
          'music'
        ],
        cat: 'Entertainment'
      ),
      (
        keys: [
          'medicine',
          'gamot',
          'doctor',
          'dentist',
          'hospital',
          'clinic',
          'pharmacy',
          'medical',
          'checkup'
        ],
        cat: 'Healthcare'
      ),
      (
        keys: ['school', 'tuition', 'books', 'classes', 'course'],
        cat: 'Education'
      ),
      (
        keys: [
          'salary',
          'sweldo',
          'sahod',
          'bonus',
          'allowance',
          'income',
          'commission'
        ],
        cat: 'Income'
      ),
    ];
    for (final entry in map) {
      for (final key in entry.keys) {
        if (lower.contains(key)) return entry.cat;
      }
    }
    return 'Other';
  }

  double? _findAmount(String message) {
    final anchored = RegExp(
        r'(?:₱|php|pesos?|pesso|piso|pisos?)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)|([0-9][0-9,]*(?:\.[0-9]{1,2})?)\s*(?:pesos?|pesso|piso|php)',
        caseSensitive: false);
    for (final m in anchored.allMatches(message.toLowerCase())) {
      for (var g = 1; g <= m.groupCount; g++) {
        final v = _parseNumber(m.group(g));
        if (v != null && v > 0) return v;
      }
    }

    final bare = RegExp(r'\b([0-9]{1,7}(?:\.[0-9]{1,2})?)\b');
    final candidates = <double>[];
    for (final m in bare.allMatches(message)) {
      final start = m.start;
      final end = m.end;
      final before = start > 0 ? message[start - 1] : '';
      final after = end < message.length ? message[end] : '';
      if (['/', '.', '-', ':'].contains(before) ||
          ['/', '.', '-', ':'].contains(after)) continue;
      final beforeWord = start > 0
          ? message
                  .substring(0, start)
                  .split(RegExp(r'\s+'))
                  .lastOrNull
                  ?.toLowerCase() ??
              ''
          : '';
      final v = _parseNumber(m.group(1));
      if (v == null || v <= 0) continue;
      candidates.add(v);
      if ([
        'about',
        'around',
        'approx',
        'approximately',
        'roughly',
        'nearly',
        'almost',
        'was',
        'is',
        'the'
      ].contains(beforeWord)) {
        return v;
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.last;
  }

  double? _parseNumber(String? raw) {
    if (raw == null) return null;
    final clean = raw.replaceAll(',', '');
    final v = double.tryParse(clean);
    return v;
  }

  DateTime _detectDate(String lower) {
    final now = DateTime.now();
    if (RegExp(r'\b(yesterday|kahapon|last night|kagabi)\b').hasMatch(lower)) {
      return now.subtract(const Duration(days: 1));
    }
    if (RegExp(r'\b(tomorrow|bukas)\b').hasMatch(lower)) {
      return now.add(const Duration(days: 1));
    }
    return now;
  }

  String _buildDescription(String lower, String type, String category) {
    if (type == 'income') {
      for (final v in _incomeVerbs) {
        final match = RegExp('\\b$v\\b').firstMatch(lower);
        if (match != null) {
          final after = lower.substring(match.end).trim();
          final frag = after.split(RegExp(r' (?:of|is|ng|na) ')).first;
          final cleaned = frag
              .replaceAll(RegExp(r'[0-9,.\s]+(?:pesos?|pesso|piso|php)?'), ' ')
              .replaceAll(RegExp(r'(?:pesos?|pesso|piso|php)'), ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          if (cleaned.isNotEmpty) return _titleCase(_clamp(cleaned, 24));
        }
      }
      return 'Salary';
    }
    if (category.isNotEmpty && category != 'Other') return category;
    for (final v in _expenseVerbs) {
      final match = RegExp('\\b$v\\b').firstMatch(lower);
      if (match != null) {
        final after = lower.substring(match.end).trim();
        final frag =
            after.split(RegExp(r' (?:via|through|using|ng|na) ')).first;
        final cleaned = frag
            .replaceAll(RegExp(r'[0-9,.\s]+(?:pesos?|pesso|piso|php)?'), ' ')
            .replaceAll(
                RegExp(r'(?:pesos?|pesso|piso|php|about|for|the|a)'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (cleaned.isNotEmpty) return _titleCase(_clamp(cleaned, 24));
      }
    }
    return 'Expense';
  }

  String _clamp(String s, int max) {
    if (s.length <= max) return s;
    return s.substring(0, max);
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day)
      return 'today';
    if (now.difference(d).inDays == 1) return 'yesterday';
    return '${_monthName(d.month)} ${d.day}';
  }

  String _monthName(int m) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[m];
  }

  String _paymentLabel(String code) {
    switch (code) {
      case 'gcash':
        return 'GCash';
      case 'maya':
        return 'Maya';
      case 'cash':
        return 'Cash';
      case 'credit_card':
        return 'Credit Card';
      case 'debit_card':
        return 'Debit Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'coins_ph':
        return 'Coins.ph';
      case 'shopeepay':
        return 'ShopeePay';
      case 'grabpay':
        return 'GrabPay';
      case 'paypal':
        return 'PayPal';
      case 'bpi':
        return 'BPI';
      case 'bdo':
        return 'BDO';
      case 'unionbank':
        return 'UnionBank';
      default:
        return code;
    }
  }

  String _ordinal(int n) {
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 20) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
