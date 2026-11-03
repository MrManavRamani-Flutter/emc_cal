import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emb_cal/widgets/app_snack_bar.dart';

void main() {
  group('AppSnackBar Tests', () {
    testWidgets('AppSnackBar.showSuccess shows snack bar with title and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppSnackBar.showSuccess(
                    context,
                    title: 'સફળતા',
                    message: 'રેકોર્ડ સેવ થઈ ગયો!',
                  );
                },
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('સફળતા'), findsOneWidget);
      expect(find.text('રેકોર્ડ સેવ થઈ ગયો!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('AppSnackBar.showWarning shows warning snack bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppSnackBar.showWarning(
                    context,
                    title: 'ચેતવણી',
                    message: 'WhatsApp ઑફલાઇન છે!',
                  );
                },
                child: const Text('Show Warning'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Warning'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ચેતવણી'), findsOneWidget);
      expect(find.text('WhatsApp ઑફલાઇન છે!'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
