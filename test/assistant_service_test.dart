import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/services/assistant_service.dart';

void main() {
  final service = AssistantService(salaryDay: 15);

  group('AssistantService.respond', () {
    test('logs an expense with a strong signal', () {
      final i = service.respond('I paid 100 pesos for food');
      expect(i.kind, 'expense');
      expect(i.autoPost, true);
      expect(i.draft!.type, 'expense');
      expect(i.draft!.amount, 100);
      expect(i.draft!.categoryKeyword, 'Food');
    });

    test('handles the misspelled currency "pesso"', () {
      final i = service.respond('I pay for food about 100 pesso');
      expect(i.draft!.type, 'expense');
      expect(i.draft!.amount, 100);
    });

    test('logs income from a salary message', () {
      final i = service.respond('I received my salary of 25000');
      expect(i.kind, 'income');
      expect(i.autoPost, true);
      expect(i.draft!.type, 'income');
      expect(i.draft!.amount, 25000);
    });

    test('detects a payment method and category', () {
      final i = service.respond('Paid 50 gcash for load');
      expect(i.draft!.paymentMethod, 'gcash');
      expect(i.draft!.categoryKeyword, 'Bills');
    });

    test('detects a past date', () {
      final i = service.respond('I paid 100 pesos for food yesterday');
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(i.draft!.date.day, yesterday.day);
    });

    test('greets when it cannot detect a transaction', () {
      final i = service.respond('hello');
      expect(i.kind, 'text');
      expect(i.reply, contains('assistant'));
    });

    test('shows help', () {
      final i = service.respond('help');
      expect(i.kind, 'help');
    });

    test('answers salary day questions', () {
      final i = service.respond('when is my salary');
      expect(i.kind, 'text');
      expect(i.reply, contains('15th'));
    });

    test('answers loan questions', () {
      final i = service.respond('when is my loan due');
      expect(i.kind, 'loan');
    });

    test('asks for the amount when missing', () {
      final i = service.respond('I paid for lunch');
      expect(i.kind, 'text');
      expect(i.reply, contains("didn't catch a transaction"));
    });
  });
}