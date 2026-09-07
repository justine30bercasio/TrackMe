import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/core/receipt_parser.dart';

void main() {
  final parser = ReceiptParser();

  group('ReceiptParser.parse', () {
    test('extracts total from a total line', () {
      final r = parser.parse('SM Supermarket\nDate: 2024-05-08\nTOTAL: ₱1,234.50');
      expect(r.total, 1234.5);
    });

    test('extracts total from a PHP amount', () {
      final r = parser.parse('Grand Total\nPHP 500.00');
      expect(r.total, 500.0);
    });

    test('falls back to the largest amount without a total marker', () {
      final r = parser.parse("Robinson's Fresh\n250.00\n120.00\n640.00");
      expect(r.total, 640.0);
    });

    test('extracts ISO date', () {
      final r = parser.parse('Date: 2024-05-08\nTOTAL: 100.00');
      expect(r.date, DateTime(2024, 5, 8));
    });

    test('extracts slash date', () {
      final r = parser.parse('12/25/2023\nTOTAL 100.00');
      expect(r.date, DateTime(2023, 12, 25));
    });

    test('extracts month-name date', () {
      final r = parser.parse('May 5, 2024\nTOTAL 100.00');
      expect(r.date, DateTime(2024, 5, 5));
    });

    test('extracts merchant from the first non-generic line', () {
      final r = parser.parse('SM Supermarket\nDate: 2024-05-08\nTOTAL: ₱1,234.50');
      expect(r.merchant, 'SM Supermarket');
    });

    test('detects payment method hints', () {
      expect(parser.parse('Paid via GCash\nTOTAL 100.00').paymentMethodCode, 'gcash');
      expect(parser.parse('Cash payment\nTOTAL 100.00').paymentMethodCode, 'cash');
      expect(parser.parse('Bank transfer\nTOTAL 100.00').paymentMethodCode, 'bank_transfer');
    });

    test('collects item lines while skipping the total', () {
      final r = parser.parse(
        'TOTAL: ₱55.00\n'
        'Coca-Cola 25.00\n'
        'Bread 20.00\n'
        'Chips 10.00\n',
      );
      expect(r.items, containsAll(['Coca-Cola 25.00', 'Bread 20.00', 'Chips 10.00']));
      expect(r.items, isNot(contains('TOTAL: ₱55.00')));
    });
  });
}