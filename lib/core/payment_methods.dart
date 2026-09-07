import 'package:flutter/material.dart';

class PaymentMethodInfo {
  final String code;
  final String label;
  final String group;
  final Color brandColor;
  final String? monogram;
  final IconData? icon;

  const PaymentMethodInfo({
    required this.code,
    required this.label,
    this.group = 'other',
    required this.brandColor,
    this.monogram,
    this.icon,
  });
}

const List<PaymentMethodInfo> paymentMethods = [
  PaymentMethodInfo(code: 'cash', label: 'Cash', group: 'core', brandColor: Color(0xFF16A34A), monogram: 'C', icon: Icons.payments),
  PaymentMethodInfo(code: 'credit_card', label: 'Credit Card', group: 'core', brandColor: Color(0xFF2563EB), monogram: 'CC', icon: Icons.credit_card),
  PaymentMethodInfo(code: 'debit_card', label: 'Debit Card', group: 'core', brandColor: Color(0xFF0F766E), monogram: 'DC', icon: Icons.credit_card),
  PaymentMethodInfo(code: 'bank_transfer', label: 'Bank Transfer', group: 'core', brandColor: Color(0xFF334155), icon: Icons.account_balance),
  PaymentMethodInfo(code: 'check', label: 'Check', group: 'core', brandColor: Color(0xFF7C3AED), monogram: '✓', icon: Icons.note_alt),
  PaymentMethodInfo(code: 'other', label: 'Other', group: 'core', brandColor: Color(0xFF6B7280), monogram: '…', icon: Icons.more_horiz),

  PaymentMethodInfo(code: 'gcash', label: 'GCash', group: 'wallet', brandColor: Color(0xFF007DFE), monogram: 'G'),
  PaymentMethodInfo(code: 'maya', label: 'Maya', group: 'wallet', brandColor: Color(0xFF22A7F0), monogram: 'M'),
  PaymentMethodInfo(code: 'coins_ph', label: 'Coins.ph', group: 'wallet', brandColor: Color(0xFFFFC107), monogram: 'c'),
  PaymentMethodInfo(code: 'shopeepay', label: 'ShopeePay', group: 'wallet', brandColor: Color(0xFFEE4D2D), monogram: 'SP'),
  PaymentMethodInfo(code: 'grabpay', label: 'GrabPay', group: 'wallet', brandColor: Color(0xFF00B14F), monogram: 'G'),
  PaymentMethodInfo(code: 'paypal', label: 'PayPal', group: 'wallet', brandColor: Color(0xFF003087), monogram: 'P'),
  PaymentMethodInfo(code: 'lazada_wallet', label: 'Lazada Wallet', group: 'wallet', brandColor: Color(0xFF0F1568), monogram: 'L'),
  PaymentMethodInfo(code: 'g_shop', label: 'GShope', group: 'wallet', brandColor: Color(0xFF42B549), monogram: 'GS'),
  PaymentMethodInfo(code: 'shopee_voucher', label: 'Shopee Voucher', group: 'wallet', brandColor: Color(0xFFFF8F00), monogram: 'V'),

  PaymentMethodInfo(code: 'bpi', label: 'BPI', group: 'bank', brandColor: Color(0xFF1E88E5), monogram: 'BPI'),
  PaymentMethodInfo(code: 'bdo', label: 'BDO', group: 'bank', brandColor: Color(0xFF0F69BA), monogram: 'BDO'),
  PaymentMethodInfo(code: 'unionbank', label: 'UnionBank', group: 'bank', brandColor: Color(0xFFEE0E08), monogram: 'UB'),
  PaymentMethodInfo(code: 'gotyme', label: 'GoTyme', group: 'bank', brandColor: Color(0xFF00AD4B), monogram: 'GT'),
  PaymentMethodInfo(code: 'rcbc', label: 'RCBC', group: 'bank', brandColor: Color(0xFF0052A5), monogram: 'RCBC'),
  PaymentMethodInfo(code: 'eastwest', label: 'EastWest', group: 'bank', brandColor: Color(0xFFFFC72C), monogram: 'EW'),
  PaymentMethodInfo(code: 'security_bank', label: 'Security Bank', group: 'bank', brandColor: Color(0xFFF07818), monogram: 'SB'),
  PaymentMethodInfo(code: 'metrobank', label: 'Metrobank', group: 'bank', brandColor: Color(0xFF003767), monogram: 'MB'),
  PaymentMethodInfo(code: 'landbank', label: 'Landbank', group: 'bank', brandColor: Color(0xFFE4002B), monogram: 'LBP'),
  PaymentMethodInfo(code: 'pnb', label: 'PNB', group: 'bank', brandColor: Color(0xFFC8102E), monogram: 'PNB'),
  PaymentMethodInfo(code: 'psbank', label: 'PSBank', group: 'bank', brandColor: Color(0xFF00477C), monogram: 'PS', icon: Icons.account_balance),
  PaymentMethodInfo(code: 'chinabank', label: 'China Bank', group: 'bank', brandColor: Color(0xFFD50032), monogram: 'CB'),
  PaymentMethodInfo(code: 'cimb', label: 'CIMB', group: 'bank', brandColor: Color(0xFFFF8900), monogram: 'CIMB'),
  PaymentMethodInfo(code: 'tonik', label: 'Tonik', group: 'bank', brandColor: Color(0xFF3AA0FF), monogram: 'T'),
  PaymentMethodInfo(code: 'banko', label: 'Banko', group: 'bank', brandColor: Color(0xFF7C4A2D), monogram: 'BO'),
  PaymentMethodInfo(code: 'coop_bank', label: 'Coop Bank', group: 'bank', brandColor: Color(0xFF2E7D32), monogram: 'CB'),
];

PaymentMethodInfo? paymentMethodInfo(String code) {
  for (final m in paymentMethods) {
    if (m.code == code) return m;
  }
  return null;
}

List<String> get expensePaymentMethodCodes =>
    paymentMethods.map((m) => m.code).toList();

List<String> get incomePaymentMethodCodes =>
    paymentMethods.map((m) => m.code).toList();

String paymentMethodLabel(String code) {
  final info = paymentMethodInfo(code);
  if (info != null) return info.label;
  final parts = code.split('_');
  return parts.map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)).join(' ');
}

String paymentMethodShape(String code) => paymentMethodLabel(code);