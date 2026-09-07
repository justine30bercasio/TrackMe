import 'package:track_me/core/payment_methods.dart';

class AppStrings {
  AppStrings._();

  static const String appName = 'TrackMe';
  static const String appTagline = 'Your money, finally under control.';

  // Expense payment methods (cash, cards, banks, e-wallets)
  static List<String> get expensePaymentMethods => expensePaymentMethodCodes;
  // Income payment methods
  static List<String> get incomePaymentMethods => incomePaymentMethodCodes;

  static const List<String> incomeSources = [
    'Salary', 'Freelance', 'Allowance', 'Business', 'Investment', 'Bonus', 'Other',
  ];

  static const List<String> budgetPeriods = ['monthly', 'quarterly', 'yearly'];
  static const List<String> budgetPeriodLabels = ['Monthly', 'Quarterly', 'Yearly'];

  static const List<String> goalStatuses = ['active', 'completed', 'paused'];
  static const List<String> goalStatusLabels = ['Active', 'Completed', 'Paused'];

  static const List<String> recurringFrequencies = ['daily', 'weekly', 'monthly', 'yearly'];
  static const List<String> recurringFrequencyLabels = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  static const List<String> recurringStatuses = ['active', 'paused', 'completed'];

  static const List<Map<String, String>> billCategories = [
    {'name': 'Electricity', 'description': 'Power and electric bills'},
    {'name': 'Water', 'description': 'Water utility bills'},
    {'name': 'Internet', 'description': 'Internet connection bills'},
    {'name': 'Phone', 'description': 'Mobile phone bills'},
    {'name': 'Gas', 'description': 'Gas utility bills'},
    {'name': 'Rent', 'description': 'Rent and leasing'},
    {'name': 'Insurance', 'description': 'Insurance premiums'},
    {'name': 'Property Tax', 'description': 'Property related taxes'},
    {'name': 'Subscription', 'description': 'Recurring subscriptions'},
    {'name': 'Healthcare', 'description': 'Medical and health care'},
    {'name': 'Loan Payment', 'description': 'Loan installments'},
    {'name': 'Education', 'description': 'Tuition and school fees'},
    {'name': 'Transportation', 'description': 'Fares and transport'},
    {'name': 'Other', 'description': 'Other bills'},
  ];

  static const List<Map<String, String>> defaultCategories = [
    {'name': 'Food', 'color': '#FF6B6B'},
    {'name': 'Transportation', 'color': '#4ECDC4'},
    {'name': 'Bills', 'color': '#FFE66D'},
    {'name': 'Shopping', 'color': '#95E1D3'},
    {'name': 'Salary', 'color': '#A8E6CF'},
    {'name': 'Savings', 'color': '#C7CEEA'},
    {'name': 'Entertainment', 'color': '#A855F7'},
    {'name': 'Healthcare', 'color': '#FB6467'},
    {'name': 'Education', 'color': '#3B82F6'},
    {'name': 'Other', 'color': '#6B7280'},
  ];

  static const Map<String, String> currencyNames = {
    'USD': 'US Dollar', 'EUR': 'Euro', 'GBP': 'British Pound', 'JPY': 'Japanese Yen',
    'PHP': 'Philippine Peso', 'AUD': 'Australian Dollar', 'CAD': 'Canadian Dollar',
    'SGD': 'Singapore Dollar', 'HKD': 'Hong Kong Dollar', 'INR': 'Indian Rupee',
    'THB': 'Thai Baht', 'MYR': 'Malaysian Ringgit', 'IDR': 'Indonesian Rupiah',
    'VND': 'Vietnamese Dong', 'CNY': 'Chinese Yuan', 'CHF': 'Swiss Franc',
    'SEK': 'Swedish Krona', 'NOK': 'Norwegian Krone', 'DKK': 'Danish Krone',
    'BRL': 'Brazilian Real', 'MXN': 'Mexican Peso', 'NZD': 'New Zealand Dollar',
    'KRW': 'South Korean Won', 'TWD': 'Taiwan Dollar', 'AED': 'UAE Dirham',
    'SAR': 'Saudi Riyal', 'ZAR': 'South African Rand', 'ARS': 'Argentine Peso',
  };

  static const Map<String, String> currencySymbols = {
    'USD': r'$', 'EUR': '€', 'GBP': '£', 'JPY': '¥', 'PHP': '₱',
    'AUD': r'A$', 'CAD': r'C$', 'SGD': r'S$', 'HKD': r'HK$', 'INR': '₹',
    'THB': '฿', 'MYR': 'RM', 'IDR': 'Rp', 'VND': '₫', 'CNY': '¥',
    'CHF': 'Fr', 'SEK': 'kr', 'NOK': 'kr', 'DKK': 'kr', 'BRL': r'R$',
    'MXN': r'$', 'NZD': r'NZ$', 'KRW': '₩', 'TWD': r'NT$', 'AED': 'د.إ',
    'SAR': '﷼', 'ZAR': 'R', 'ARS': r'$',
  };

  static const List<String> supportedCurrencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'PHP', 'AUD', 'CAD', 'SGD', 'HKD', 'INR',
    'THB', 'MYR', 'IDR', 'VND', 'CNY', 'CHF', 'SEK', 'NOK', 'DKK', 'BRL',
    'MXN', 'NZD', 'KRW', 'TWD', 'AED', 'SAR', 'ZAR', 'ARS',
  ];

  static const Map<String, String> countryNames = {
    'PH': 'Philippines', 'US': 'United States', 'GB': 'United Kingdom', 'CA': 'Canada',
    'AU': 'Australia', 'JP': 'Japan', 'IN': 'India', 'SG': 'Singapore', 'TH': 'Thailand',
    'MY': 'Malaysia', 'ID': 'Indonesia', 'VN': 'Vietnam', 'KR': 'South Korea',
    'TW': 'Taiwan', 'DE': 'Germany', 'FR': 'France', 'IT': 'Italy', 'ES': 'Spain',
    'BR': 'Brazil', 'MX': 'Mexico', 'AE': 'United Arab Emirates', 'SA': 'Saudi Arabia',
    'CH': 'Switzerland', 'SE': 'Sweden', 'NO': 'Norway', 'NL': 'Netherlands',
  };

  static const Map<String, String> countryCurrencies = {
    'PH': 'PHP', 'US': 'USD', 'GB': 'GBP', 'CA': 'CAD', 'AU': 'AUD', 'JP': 'JPY',
    'IN': 'INR', 'SG': 'SGD', 'TH': 'THB', 'MY': 'MYR', 'ID': 'IDR', 'VN': 'VND',
    'KR': 'KRW', 'TW': 'TWD', 'DE': 'EUR', 'FR': 'EUR', 'IT': 'EUR', 'ES': 'EUR',
    'BR': 'BRL', 'MX': 'MXN', 'AE': 'AED', 'SA': 'SAR', 'CH': 'CHF', 'SE': 'SEK',
    'NO': 'NOK', 'NL': 'EUR',
  };

  static const Map<String, String> languages = {
    'en': 'English', 'fil': 'Filipino', 'es': 'Español', 'ja': '日本語',
    'zh': '中文', 'hi': 'हिन्दी', 'ar': 'العربية', 'fr': 'Français', 'de': 'Deutsch', 'pt': 'Português',
  };
}

String paymentMethodLabel(String method) => paymentMethodShape(method);

String frequencyLabel(String frequency) {
  switch (frequency) {
    case 'daily':
      return 'Daily';
    case 'weekly':
      return 'Weekly';
    case 'monthly':
      return 'Monthly';
    case 'yearly':
      return 'Yearly';
    default:
      return frequency;
  }
}