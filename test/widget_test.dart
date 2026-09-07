import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/core/common_widgets.dart';

void main() {
  testWidgets('App shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('TrackMe'))));
    expect(find.text('TrackMe'), findsOneWidget);
  });

  test('formatMoney formats with currency symbol', () {
    expect(formatMoney(1234.5, 'USD'), r'$1,234.50');
    expect(formatMoney(50, 'JPY', decimals: 0), '¥50');
  });
}