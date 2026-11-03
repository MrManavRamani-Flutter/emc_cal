import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emb_cal/widgets/widgets.dart';

void main() {
  group('Modular Reusable Widgets Tests', () {
    testWidgets('ShiftBadge displays Day shift with sun icon and Night shift with moon icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ShiftBadge(shift: 'Day'),
                ShiftBadge(shift: 'Night', isDark: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Night'), findsOneWidget);
      expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
      expect(find.byIcon(Icons.nightlight_round), findsOneWidget);
    });

    testWidgets('AccountBadge displays category name and optional area tag', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AccountBadge(accountName: 'Beads', color: Colors.teal),
                AccountBadge(accountName: '250 Area', area: '250', color: Colors.blue),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Beads'), findsOneWidget);
      expect(find.text('250 Area'), findsOneWidget);
      expect(find.text('(250)'), findsOneWidget);
    });

    testWidgets('KpiMetricCard and ShiftSummaryPill render metric values accurately', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                KpiMetricCard(
                  title: 'Total Revenue',
                  value: '₹1,50,000.00',
                  icon: Icons.currency_rupee,
                  color: Colors.green,
                  isDark: false,
                ),
                ShiftSummaryPill(
                  label: 'Day Shift ☀️',
                  batches: 12,
                  stitches: 450000,
                  amount: 25000.0,
                  currency: '₹',
                  color: Colors.amber,
                  isDark: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('₹1,50,000.00'), findsOneWidget);
      expect(find.text('Day Shift ☀️'), findsOneWidget);
    });

    testWidgets('AppEmptyState displays icon, title, message, and triggers action callback', (WidgetTester tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Empty State Title',
              message: 'Helpful message explaining the empty list.',
              actionLabel: 'Refresh Items',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Empty State Title'), findsOneWidget);
      expect(find.text('Helpful message explaining the empty list.'), findsOneWidget);
      expect(find.text('Refresh Items'), findsOneWidget);

      await tester.tap(find.text('Refresh Items'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('TablePaginationBar navigates pages correctly', (WidgetTester tester) async {
      int activePage = 1;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: TablePaginationBar(
                  currentPage: activePage,
                  totalPages: 5,
                  totalItems: 50,
                  rowsPerPage: 10,
                  onPageChanged: (newPage) => setState(() => activePage = newPage),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Showing 1-10 of 50 entries'), findsOneWidget);
      expect(find.text('Page 1 of 5'), findsOneWidget);

      // Tap Next Page button
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();

      expect(activePage, 2);
      expect(find.text('Showing 11-20 of 50 entries'), findsOneWidget);
      expect(find.text('Page 2 of 5'), findsOneWidget);
    });
  });
}
