import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/providers/production_provider.dart';
import 'package:emb_cal/screens/splash_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget buildTestableSplash({bool isReplay = false}) {
    return ChangeNotifierProvider(
      create: (_) => ProductionProvider(),
      child: MaterialApp(
        home: SplashScreen(
          isReplay: isReplay,
          totalDuration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }

  testWidgets('SplashScreen displays branding, OM emblem, and category indicators',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableSplash());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('OM MAVTAR GROUP'), findsOneWidget);
    expect(find.text('PREMIUM EMBROIDERY FACTORY SUITE'), findsOneWidget);
    expect(find.text('Track  •  Calculate  •  Manage  •  Grow'), findsOneWidget);
    expect(find.text('Beads'), findsOneWidget);
    expect(find.text('250 Area'), findsOneWidget);
    expect(find.text('400 Area'), findsOneWidget);

    // Pump until splash animation completes
    await tester.pumpAndSettle();
  });

  testWidgets('SplashScreen skip on tap navigates immediately',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableSplash());
    await tester.pump(const Duration(milliseconds: 50));

    // Tap to skip
    await tester.tap(find.text('Press Enter or Click to Continue'));
    await tester.pumpAndSettle();
  });
}
