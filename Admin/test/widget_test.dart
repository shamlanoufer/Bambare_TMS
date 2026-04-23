import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:user_tws/screens/admin_login_screen.dart';

void main() {
  testWidgets('Dark login shows Welcome and LOGIN', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminLoginScreen()),
    );

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.textContaining('Bambare'), findsOneWidget);
  });
}
