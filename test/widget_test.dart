import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_expense_app/main.dart';

void main() {
  testWidgets('App loads and shows navigation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TravelExpenseApp());

    // Verify that the Bottom Navigation items are present
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('BOOKINGS'), findsOneWidget);
    expect(find.text('MAP'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
  });
}
