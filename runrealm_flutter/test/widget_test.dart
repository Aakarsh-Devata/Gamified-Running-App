// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runrealm_flutter/main.dart';
import 'package:runrealm_flutter/providers/auth_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final authProvider = AuthProvider();
    await tester.pumpWidget(MyApp(authProvider: authProvider));

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that our app starts without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
