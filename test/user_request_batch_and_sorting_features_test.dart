import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/models/production_record.dart';
import 'package:emb_cal/widgets/table_pagination_bar.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('User Request Features Test Suite', () {
    test('1. ProductionRecord separates production date and created_at', () {
      final workDate = DateTime(2026, 11, 4);
      final createdTime = DateTime(2026, 11, 4, 18, 30, 45);

      final record = ProductionRecord(
        date: workDate,
        createdAt: createdTime,
        designNo: 'D-999',
        machineNo: 'M-01',
        totalStitch: 150000,
        finalStitch: 150.0,
        rate: 1.25,
        amount: 187.5,
        heads: 12,
        finalAmount: 2250.0,
        accountName: '250 Area',
        shift: 'Day',
      );

      final map = record.toMap();
      expect(map['date'], equals('2026-11-04'));
      expect(map['created_at'], contains('2026-11-04T18:30:45'));

      final restored = ProductionRecord.fromMap(map);
      expect(restored.date.year, equals(2026));
      expect(restored.date.month, equals(11));
      expect(restored.date.day, equals(4));
      expect(restored.createdAt, isNotNull);
      expect(restored.createdAt!.hour, equals(18));
      expect(restored.createdAt!.minute, equals(30));
    });

    testWidgets('2. TablePaginationBar supports Show All option (-1)', (WidgetTester tester) async {
      int selectedRows = 10;
      int selectedPage = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TablePaginationBar(
                  currentPage: selectedPage,
                  totalPages: selectedRows <= 0 ? 1 : 10,
                  totalItems: 100,
                  rowsPerPage: selectedRows,
                  rowsPerPageOptions: const [10, 25, 50, -1],
                  onPageChanged: (p) => setState(() => selectedPage = p),
                  onRowsPerPageChanged: (r) => setState(() => selectedRows = r),
                );
              },
            ),
          ),
        ),
      );

      // Verify dropdown shows '10' initially and label shows Showing 1-10 of 100 entries
      expect(find.text('Showing 1-10 of 100 entries'), findsOneWidget);
      expect(find.text('Page 1 of 10'), findsOneWidget);

      // Tap rows per page dropdown
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();

      // Verify 'Show All' is in the dropdown
      expect(find.text('Show All'), findsOneWidget);

      // Select 'Show All'
      await tester.tap(find.text('Show All').last);
      await tester.pumpAndSettle();

      // When Show All is selected (-1), range should be 1-100 of 100 entries, Page 1 of 1
      expect(find.text('Showing 1-100 of 100 entries'), findsOneWidget);
      expect(find.text('Page 1 of 1'), findsOneWidget);
    });
  });
}

