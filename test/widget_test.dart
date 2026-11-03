import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App launches successfully', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const EmbroideryCalculatorApp());
    await tester.pumpAndSettle();
    expect(find.byType(EmbroideryCalculatorApp), findsOneWidget);

    // Tap on Settings sidebar item
    await tester.tap(find.textContaining('Settings').first);
    await tester.pumpAndSettle();
    expect(find.text('General Settings'), findsOneWidget);
  });
}
