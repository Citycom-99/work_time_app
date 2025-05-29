// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:work_time_app/screens/overview_page.dart';
import '../lib/main.dart';           // falls nötig, je nach Struktur

void main() {
  testWidgets('WorkTimePage shows basic UI elements', (WidgetTester tester) async {
    // Baue das Widget
    await tester.pumpWidget(
      MaterialApp(
        home: OverviewPage(),
      ),
    );

    // Prüfe, ob die Seite bestimmte Texte/Widgets enthält
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget); // falls du eine Tabelle verwendest
  });
}
