class AppUser {
  final int? id;
  final String name;
  final String email;
  final String country;
  final String region;
  final String preferredCurrency;
  final String timezone;
  final String language;
  final int salaryDay;
  final bool notifyBudgetExceeded;
  final bool notifyGoalCompleted;
  final bool notifyGoalMilestones;
  final bool onboardingCompleted;
  final String avatar;

  AppUser({
    this.id,
    this.name = '',
    this.email = '',
    this.country = '',
    this.region = '',
    this.preferredCurrency = 'USD',
    this.timezone = '',
    this.language = 'en',
    this.salaryDay = 15,
    this.notifyBudgetExceeded = true,
    this.notifyGoalCompleted = true,
    this.notifyGoalMilestones = true,
    this.onboardingCompleted = false,
    this.avatar = '',
  });

  String get flagEmoji => _flagForCountry(country);

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      country: map['country'] as String? ?? '',
      region: map['region'] as String? ?? '',
      preferredCurrency: map['preferred_currency'] as String? ?? 'USD',
      timezone: map['timezone'] as String? ?? '',
      language: map['language'] as String? ?? 'en',
      salaryDay: (map['salary_day'] as num?)?.toInt() ?? 15,
      notifyBudgetExceeded: (map['notify_budget_exceeded'] as int? ?? 1) == 1,
      notifyGoalCompleted: (map['notify_goal_completed'] as int? ?? 1) == 1,
      notifyGoalMilestones: (map['notify_goal_milestones'] as int? ?? 1) == 1,
      onboardingCompleted: (map['onboarding_completed'] as int? ?? 0) == 1,
      avatar: map['avatar'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'country': country,
        'region': region,
        'preferred_currency': preferredCurrency,
        'timezone': timezone,
        'language': language,
        'salary_day': salaryDay,
        'notify_budget_exceeded': notifyBudgetExceeded ? 1 : 0,
        'notify_goal_completed': notifyGoalCompleted ? 1 : 0,
        'notify_goal_milestones': notifyGoalMilestones ? 1 : 0,
        'onboarding_completed': onboardingCompleted ? 1 : 0,
        'avatar': avatar,
      };
}

class Category {
  final int? id;
  final String name;
  final String description;
  final String color;
  final int? userId;

  Category({this.id, required this.name, this.description = '', this.color = '#5B4BF0', this.userId});

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        color: map['color'] as String? ?? '#5B4BF0',
        userId: map['user_id'] as int?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
        'color': color,
        'user_id': userId,
      };

  Category copyWith({int? id, String? name, String? description, String? color, int? userId}) => Category(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        color: color ?? this.color,
        userId: userId ?? this.userId,
      );
}

class BillCategory {
  final int? id;
  final String name;
  final String description;

  BillCategory({this.id, required this.name, this.description = ''});

  factory BillCategory.fromMap(Map<String, dynamic> map) => BillCategory(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
      };
}

class Expense {
  final int? id;
  final int categoryId;
  final int? billCategoryId;
  final String description;
  final double amount;
  final String expenseDate;
  final String notes;
  final String paymentMethod;
  final String currencyCode;
  final String? receiptImage;
  final String? billType;
  final String? deletedAt;
  final String createdAt;

  String? categoryName;
  String? categoryColor;

  Expense({
    this.id,
    required this.categoryId,
    this.billCategoryId,
    required this.description,
    required this.amount,
    required this.expenseDate,
    this.notes = '',
    this.paymentMethod = 'cash',
    this.currencyCode = 'USD',
    this.receiptImage,
    this.billType,
    this.deletedAt,
    this.createdAt = '',
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    final e = Expense(
      id: map['id'] as int?,
      categoryId: (map['category_id'] as num?)?.toInt() ?? 0,
      billCategoryId: (map['bill_category_id'] as num?)?.toInt(),
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      expenseDate: map['expense_date'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      currencyCode: map['currency_code'] as String? ?? 'USD',
      receiptImage: map['receipt_image'] as String?,
      billType: map['bill_type'] as String?,
      deletedAt: map['deleted_at'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
    e.categoryName = map['category_name'] as String?;
    e.categoryColor = map['category_color'] as String?;
    return e;
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category_id': categoryId,
        'bill_category_id': billCategoryId,
        'description': description,
        'amount': amount,
        'expense_date': expenseDate,
        'notes': notes,
        'payment_method': paymentMethod,
        'currency_code': currencyCode,
        'receipt_image': receiptImage,
        'bill_type': billType,
        'deleted_at': deletedAt,
      };
}

class Income {
  final int? id;
  final String source;
  final double amount;
  final String incomeDate;
  final String notes;
  final String paymentMethod;
  final String currencyCode;
  final String? deletedAt;
  final String createdAt;

  Income({
    this.id,
    required this.source,
    required this.amount,
    required this.incomeDate,
    this.notes = '',
    this.paymentMethod = 'bank_transfer',
    this.currencyCode = 'USD',
    this.deletedAt,
    this.createdAt = '',
  });

  factory Income.fromMap(Map<String, dynamic> map) => Income(
        id: map['id'] as int?,
        source: map['source'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        incomeDate: map['income_date'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        paymentMethod: map['payment_method'] as String? ?? 'bank_transfer',
        currencyCode: map['currency_code'] as String? ?? 'USD',
        deletedAt: map['deleted_at'] as String?,
        createdAt: map['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'source': source,
        'amount': amount,
        'income_date': incomeDate,
        'notes': notes,
        'payment_method': paymentMethod,
        'currency_code': currencyCode,
        'deleted_at': deletedAt,
      };
}

class Budget {
  final int? id;
  final int categoryId;
  final double limitAmount;
  final String period;
  final int? month;
  final int? year;
  final String notes;
  final bool carryoverEnabled;
  final double carryoverAmount;
  final String? carriedOverFrom;
  final String createdAt;

  String? categoryName;
  String? categoryColor;

  Budget({
    this.id,
    required this.categoryId,
    required this.limitAmount,
    this.period = 'monthly',
    this.month,
    this.year,
    this.notes = '',
    this.carryoverEnabled = false,
    this.carryoverAmount = 0,
    this.carriedOverFrom,
    this.createdAt = '',
  });

  double get effectiveLimit => limitAmount + (carryoverEnabled ? carryoverAmount : 0);

  factory Budget.fromMap(Map<String, dynamic> map) {
    final b = Budget(
      id: map['id'] as int?,
      categoryId: (map['category_id'] as num?)?.toInt() ?? 0,
      limitAmount: (map['limit_amount'] as num?)?.toDouble() ?? 0,
      period: map['period'] as String? ?? 'monthly',
      month: (map['month'] as num?)?.toInt(),
      year: (map['year'] as num?)?.toInt(),
      notes: map['notes'] as String? ?? '',
      carryoverEnabled: (map['carryover_enabled'] as int? ?? 0) == 1,
      carryoverAmount: (map['carryover_amount'] as num?)?.toDouble() ?? 0,
      carriedOverFrom: map['carried_over_from'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
    b.categoryName = map['category_name'] as String?;
    b.categoryColor = map['category_color'] as String?;
    return b;
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category_id': categoryId,
        'limit_amount': limitAmount,
        'period': period,
        'month': month,
        'year': year,
        'notes': notes,
        'carryover_enabled': carryoverEnabled ? 1 : 0,
        'carryover_amount': carryoverAmount,
        'carried_over_from': carriedOverFrom,
      };
}

class SavingsGoal {
  final int? id;
  final String title;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final String? targetDate;
  final String? category;
  final String status;
  final String? deletedAt;
  final String createdAt;

  SavingsGoal({
    this.id,
    required this.title,
    this.description = '',
    required this.targetAmount,
    this.currentAmount = 0,
    this.targetDate,
    this.category,
    this.status = 'active',
    this.deletedAt,
    this.createdAt = '',
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount * 100).clamp(0, 100).toDouble();
  }

  double get remainingAmount => (targetAmount - currentAmount).clamp(0, double.infinity).toDouble();

  bool get isCompleted => status == 'completed' || currentAmount >= targetAmount;

  SavingsGoal copyWith({String? status, double? currentAmount}) => SavingsGoal(
        id: id,
        title: title,
        description: description,
        targetAmount: targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        targetDate: targetDate,
        category: category,
        status: status ?? this.status,
        deletedAt: deletedAt,
        createdAt: createdAt,
      );

  factory SavingsGoal.fromMap(Map<String, dynamic> map) => SavingsGoal(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        targetAmount: (map['target_amount'] as num?)?.toDouble() ?? 0,
        currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0,
        targetDate: map['target_date'] as String?,
        category: map['category'] as String?,
        status: map['status'] as String? ?? 'active',
        deletedAt: map['deleted_at'] as String?,
        createdAt: map['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'target_date': targetDate,
        'category': category,
        'status': status,
        'deleted_at': deletedAt,
      };
}

class CategoryKeyword {
  final int? id;
  final int categoryId;
  final String keyword;
  final int priority;

  String? categoryName;

  CategoryKeyword({this.id, required this.categoryId, required this.keyword, this.priority = 5});

  factory CategoryKeyword.fromMap(Map<String, dynamic> map) {
    final k = CategoryKeyword(
      id: map['id'] as int?,
      categoryId: (map['category_id'] as num?)?.toInt() ?? 0,
      keyword: map['keyword'] as String? ?? '',
      priority: (map['priority'] as num?)?.toInt() ?? 5,
    );
    k.categoryName = map['category_name'] as String?;
    return k;
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category_id': categoryId,
        'keyword': keyword,
        'priority': priority,
      };
}

class UserCurrency {
  final int? id;
  final String currencyCode;
  final double exchangeRate;
  final bool isPrimary;
  final String? lastUpdated;

  UserCurrency({
    this.id,
    required this.currencyCode,
    this.exchangeRate = 1.0,
    this.isPrimary = false,
    this.lastUpdated,
  });

  factory UserCurrency.fromMap(Map<String, dynamic> map) => UserCurrency(
        id: map['id'] as int?,
        currencyCode: map['currency_code'] as String? ?? '',
        exchangeRate: (map['exchange_rate'] as num?)?.toDouble() ?? 1.0,
        isPrimary: (map['is_primary'] as int? ?? 0) == 1,
        lastUpdated: map['last_updated'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'currency_code': currencyCode,
        'exchange_rate': exchangeRate,
        'is_primary': isPrimary ? 1 : 0,
        'last_updated': lastUpdated,
      };
}

class Receipt {
  final int? id;
  final int? expenseId;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String? ocrText;
  final bool isProcessed;
  final String processingStatus;
  final String? deletedAt;
  final String createdAt;

  String? expenseDescription;

  Receipt({
    this.id,
    this.expenseId,
    required this.filePath,
    required this.fileName,
    this.fileSize = 0,
    this.mimeType = 'image/jpeg',
    this.ocrText,
    this.isProcessed = false,
    this.processingStatus = 'pending',
    this.deletedAt,
    this.createdAt = '',
  });

  factory Receipt.fromMap(Map<String, dynamic> map) {
    final r = Receipt(
      id: map['id'] as int?,
      expenseId: (map['expense_id'] as num?)?.toInt(),
      filePath: map['file_path'] as String? ?? '',
      fileName: map['file_name'] as String? ?? '',
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      mimeType: map['mime_type'] as String? ?? 'image/jpeg',
      ocrText: map['ocr_text'] as String?,
      isProcessed: (map['is_processed'] as int? ?? 0) == 1,
      processingStatus: map['processing_status'] as String? ?? 'pending',
      deletedAt: map['deleted_at'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
    r.expenseDescription = map['expense_description'] as String?;
    return r;
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'expense_id': expenseId,
        'file_path': filePath,
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': mimeType,
        'ocr_text': ocrText,
        'is_processed': isProcessed ? 1 : 0,
        'processing_status': processingStatus,
        'deleted_at': deletedAt,
      };
}

class RecurringTransaction {
  final int? id;
  final int categoryId;
  final int? billCategoryId;
  final String description;
  final double amount;
  final String paymentMethod;
  final String notes;
  final String frequency;
  final int? dayOfMonth;
  final String nextDueDate;
  final String? lastGeneratedDate;
  final String? endDate;
  final int? maxOccurrences;
  final int occurrencesGenerated;
  final String status;
  final int? lastExpenseId;
  final String? deletedAt;
  final String createdAt;

  String? categoryName;
  String? categoryColor;

  RecurringTransaction({
    this.id,
    required this.categoryId,
    this.billCategoryId,
    required this.description,
    required this.amount,
    this.paymentMethod = 'cash',
    this.notes = '',
    this.frequency = 'monthly',
    this.dayOfMonth,
    required this.nextDueDate,
    this.lastGeneratedDate,
    this.endDate,
    this.maxOccurrences,
    this.occurrencesGenerated = 0,
    this.status = 'active',
    this.lastExpenseId,
    this.deletedAt,
    this.createdAt = '',
  });

  bool get isPaused => status == 'paused';
  bool get isCompletedState => status == 'completed';

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    final r = RecurringTransaction(
      id: map['id'] as int?,
      categoryId: (map['category_id'] as num?)?.toInt() ?? 0,
      billCategoryId: (map['bill_category_id'] as num?)?.toInt(),
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      notes: map['notes'] as String? ?? '',
      frequency: map['frequency'] as String? ?? 'monthly',
      dayOfMonth: (map['day_of_month'] as num?)?.toInt(),
      nextDueDate: map['next_due_date'] as String? ?? '',
      lastGeneratedDate: map['last_generated_date'] as String?,
      endDate: map['end_date'] as String?,
      maxOccurrences: (map['max_occurrences'] as num?)?.toInt(),
      occurrencesGenerated: (map['occurrences_generated'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'active',
      lastExpenseId: (map['last_expense_id'] as num?)?.toInt(),
      deletedAt: map['deleted_at'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
    r.categoryName = map['category_name'] as String?;
    r.categoryColor = map['category_color'] as String?;
    return r;
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category_id': categoryId,
        'bill_category_id': billCategoryId,
        'description': description,
        'amount': amount,
        'payment_method': paymentMethod,
        'notes': notes,
        'frequency': frequency,
        'day_of_month': dayOfMonth,
        'next_due_date': nextDueDate,
        'last_generated_date': lastGeneratedDate,
        'end_date': endDate,
        'max_occurrences': maxOccurrences,
        'occurrences_generated': occurrencesGenerated,
        'status': status,
        'last_expense_id': lastExpenseId,
        'deleted_at': deletedAt,
      };
}

class AppNotification {
  final int? id;
  final String type;
  final String title;
  final String body;
  final String? dataJson;
  final bool read;
  final String createdAt;

  AppNotification({
    this.id,
    required this.type,
    required this.title,
    required this.body,
    this.dataJson,
    this.read = false,
    this.createdAt = '',
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] as int?,
        type: map['type'] as String? ?? 'info',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        dataJson: map['data'] as String?,
        read: (map['read'] as int? ?? 0) == 1,
        createdAt: map['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type,
        'title': title,
        'body': body,
        'data': dataJson,
        'read': read ? 1 : 0,
      };
}

class ActivityLog {
  final int? id;
  final String logName;
  final String description;
  final String? properties;
  final String createdAt;

  ActivityLog({this.id, required this.logName, required this.description, this.properties, this.createdAt = ''});

  factory ActivityLog.fromMap(Map<String, dynamic> map) => ActivityLog(
        id: map['id'] as int?,
        logName: map['log_name'] as String? ?? 'default',
        description: map['description'] as String? ?? '',
        properties: map['properties'] as String?,
        createdAt: map['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'log_name': logName,
        'description': description,
        'properties': properties,
      };
}

class Loan {
  final int? id;
  final String name;
  final String? lender;
  final double principal;
  final double annualInterestRate;
  final int termMonths;
  final String startDate;
  final int paymentDay;
  final String paymentMethod;
  final String notes;
  final bool paidOff;
  final String? deletedAt;
  final String createdAt;

  Loan({
    this.id,
    required this.name,
    this.lender,
    required this.principal,
    this.annualInterestRate = 0,
    required this.termMonths,
    required this.startDate,
    this.paymentDay = 15,
    this.paymentMethod = 'bank_transfer',
    this.notes = '',
    this.paidOff = false,
    this.deletedAt,
    this.createdAt = '',
  });

  factory Loan.fromMap(Map<String, dynamic> map) => Loan(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        lender: map['lender'] as String?,
        principal: (map['principal'] as num?)?.toDouble() ?? 0,
        annualInterestRate: (map['annual_interest_rate'] as num?)?.toDouble() ?? 0,
        termMonths: (map['term_months'] as num?)?.toInt() ?? 1,
        startDate: map['start_date'] as String? ?? '',
        paymentDay: (map['payment_day'] as num?)?.toInt() ?? 15,
        paymentMethod: map['payment_method'] as String? ?? 'bank_transfer',
        notes: map['notes'] as String? ?? '',
        paidOff: (map['paid_off'] as int? ?? 0) == 1,
        deletedAt: map['deleted_at'] as String?,
        createdAt: map['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'lender': lender,
        'principal': principal,
        'annual_interest_rate': annualInterestRate,
        'term_months': termMonths,
        'start_date': startDate,
        'payment_day': paymentDay,
        'payment_method': paymentMethod,
        'notes': notes,
        'paid_off': paidOff ? 1 : 0,
        'deleted_at': deletedAt,
      };
}

class LoanPayment {
  final int? id;
  final int loanId;
  final String dueDate;
  final double amountDue;
  final double principalPaid;
  final double interestPaid;
  final String status;
  final String? paidDate;
  final int? expenseId;

  LoanPayment({
    this.id,
    required this.loanId,
    required this.dueDate,
    required this.amountDue,
    this.principalPaid = 0,
    this.interestPaid = 0,
    this.status = 'upcoming',
    this.paidDate,
    this.expenseId,
  });

  factory LoanPayment.fromMap(Map<String, dynamic> map) => LoanPayment(
        id: map['id'] as int?,
        loanId: (map['loan_id'] as num?)?.toInt() ?? 0,
        dueDate: map['due_date'] as String? ?? '',
        amountDue: (map['amount_due'] as num?)?.toDouble() ?? 0,
        principalPaid: (map['principal_paid'] as num?)?.toDouble() ?? 0,
        interestPaid: (map['interest_paid'] as num?)?.toDouble() ?? 0,
        status: map['status'] as String? ?? 'upcoming',
        paidDate: map['paid_date'] as String?,
        expenseId: (map['expense_id'] as num?)?.toInt(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'loan_id': loanId,
        'due_date': dueDate,
        'amount_due': amountDue,
        'principal_paid': principalPaid,
        'interest_paid': interestPaid,
        'status': status,
        'paid_date': paidDate,
        'expense_id': expenseId,
      };
}

class ChatMessage {
  final int? id;
  final String role;
  final String kind;
  final String text;
  final String? payload;
  final String createdAt;

  ChatMessage({
    this.id,
    required this.role,
    this.kind = 'text',
    required this.text,
    this.payload,
    this.createdAt = '',
  });

  bool get isUser => role == 'user';

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] as int?,
        role: map['role'] as String? ?? 'assistant',
        kind: map['kind'] as String? ?? 'text',
        text: map['text'] as String? ?? '',
        payload: map['payload'] as String?,
        createdAt: map['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'role': role,
        'kind': kind,
        'text': text,
        'payload': payload,
        'created_at': createdAt,
      };
}

String _flagForCountry(String code) {
  const flags = {
    'PH': '🇵🇭', 'US': '🇺🇸', 'GB': '🇬🇧', 'CA': '🇨🇦', 'AU': '🇦🇺', 'JP': '🇯🇵', 'IN': '🇮🇳',
    'SG': '🇸🇬', 'TH': '🇹🇭', 'MY': '🇲🇾', 'ID': '🇮🇩', 'VN': '🇻🇳', 'KR': '🇰🇷', 'TW': '🇹🇼',
    'DE': '🇩🇪', 'FR': '🇫🇷', 'IT': '🇮🇹', 'ES': '🇪🇸', 'BR': '🇧🇷', 'MX': '🇲🇽', 'AE': '🇦🇪',
    'SA': '🇸🇦', 'CH': '🇨🇭', 'SE': '🇸🇪', 'NO': '🇳🇴', 'NL': '🇳🇱',
  };
  return flags[code] ?? '';
}