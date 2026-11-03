import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:emb_cal/models/production_record.dart';
import 'package:emb_cal/providers/production_provider.dart';
import 'package:emb_cal/screens/production/production_entry_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Production Entry Table Sorting & Full-Width Tests', () {
    test('ProductionProvider sorts by all fields ascending and descending', () async {
      final provider = ProductionProvider();

      final r1 = ProductionRecord(
        id: 1,
        date: DateTime(2026, 11, 1),
        accountName: 'Beads',
        designNo: 'D10',
        machineNo: 'M-02',
        totalStitch: 100000,
        finalStitch: 100.0,
        rate: 0.50,
        amount: 50.0,
        heads: 20,
        finalAmount: 1000.0,
      );

      final r2 = ProductionRecord(
        id: 2,
        date: DateTime(2026, 11, 2),
        accountName: 'Area 250',
        designNo: 'D05',
        machineNo: 'M-01',
        totalStitch: 250000,
        finalStitch: 250.0,
        rate: 0.40,
        amount: 100.0,
        heads: 28,
        finalAmount: 2800.0,
      );

      final r3 = ProductionRecord(
        id: 3,
        date: DateTime(2026, 11, 3),
        accountName: 'Zari',
        designNo: 'D20',
        machineNo: 'M-05',
        totalStitch: 50000,
        finalStitch: 50.0,
        rate: 0.60,
        amount: 30.0,
        heads: 15,
        finalAmount: 450.0,
      );

      await provider.addBatchRecords([r1, r2, r3]);

      // 1. Sort by Date ascending
      provider.setSort('date');
      if (!provider.sortAscending) provider.setSort('date');
      expect(provider.sortColumn, 'date');
      expect(provider.sortAscending, true);
      var records = provider.filteredRecords;
      expect(records.first.id, 1);
      expect(records.last.id, 3);

      // Date descending
      provider.setSort('date');
      expect(provider.sortAscending, false);
      records = provider.filteredRecords;
      expect(records.first.id, 3);
      expect(records.last.id, 1);

      // 2. Sort by Category ascending ('Area 250' < 'Beads' < 'Zari')
      provider.setSort('category');
      records = provider.filteredRecords;
      expect(records.first.accountName, 'Area 250');
      expect(records.last.accountName, 'Zari');

      // Category descending
      provider.setSort('category');
      records = provider.filteredRecords;
      expect(records.first.accountName, 'Zari');
      expect(records.last.accountName, 'Area 250');

      // 3. Sort by Design No ascending ('D05' < 'D10' < 'D20')
      provider.setSort('designNo');
      records = provider.filteredRecords;
      expect(records.first.designNo, 'D05');
      expect(records.last.designNo, 'D20');

      // 4. Sort by Machine No ascending ('M-01' < 'M-02' < 'M-05')
      provider.setSort('machineNo');
      records = provider.filteredRecords;
      expect(records.first.machineNo, 'M-01');
      expect(records.last.machineNo, 'M-05');

      // 5. Sort by Total Stitch ascending (50,000 < 100,000 < 250,000)
      provider.setSort('totalStitch');
      records = provider.filteredRecords;
      expect(records.first.totalStitch, 50000);
      expect(records.last.totalStitch, 250000);

      // Total Stitch descending
      provider.setSort('totalStitch');
      records = provider.filteredRecords;
      expect(records.first.totalStitch, 250000);
      expect(records.last.totalStitch, 50000);

      // 6. Sort by Rate ascending (0.40 < 0.50 < 0.60)
      provider.setSort('rate');
      records = provider.filteredRecords;
      expect(records.first.rate, 0.40);
      expect(records.last.rate, 0.60);

      // 7. Sort by Final Amount ascending (450 < 1000 < 2800)
      provider.setSort('finalAmount');
      records = provider.filteredRecords;
      expect(records.first.finalAmount, 450.0);
      expect(records.last.finalAmount, 2800.0);

      // Final Amount descending
      provider.setSort('finalAmount');
      records = provider.filteredRecords;
      expect(records.first.finalAmount, 2800.0);
      expect(records.last.finalAmount, 450.0);
    });

    testWidgets('ProductionEntryScreen renders Category, dropdown, and no No./Heads', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final provider = ProductionProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: ProductionEntryScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));

      // 'No.' header must NOT exist in the whole screen
      expect(find.text('No.'), findsNothing);

      // 'Heads' column header must NOT exist
      expect(find.text('Heads'), findsNothing);

      // 'Khata / Category' must NOT exist (only 'Category')
      expect(find.text('Khata / Category'), findsNothing);

      // Dropdown says 'All Categories'
      expect(find.text('All Categories'), findsWidgets);
    });
  });
}
