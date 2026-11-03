import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/data/sample_data.dart';
import 'package:emb_cal/models/production_record.dart';
import 'package:emb_cal/providers/production_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Khata & Account Feature Verification Tests', () {
    test('Default accounts include Beads, 250 Area, and 400 Area', () {
      final accountNames = SampleData.getInitialAccounts().map((a) => a.name).toList();
      expect(accountNames, contains('Beads'));
      expect(accountNames, contains('250 Area'));
      expect(accountNames, contains('400 Area'));
    });

    test('ProductionRecord constructor defaults to 250 Area and supports custom khata', () {
      final defaultRecord = ProductionRecord(
        date: DateTime.now(),
        designNo: 'D-101',
        machineNo: 'M-1',
        totalStitch: 10000,
        finalStitch: 10000,
        rate: 0.5,
        amount: 50.0,
        heads: 1,
        finalAmount: 50.0,
      );
      expect(defaultRecord.accountName, '250 Area');

      final beadsRecord = ProductionRecord(
        date: DateTime.now(),
        designNo: 'D-102',
        machineNo: 'M-2',
        accountName: 'Beads',
        totalStitch: 15000,
        finalStitch: 15000,
        rate: 0.6,
        amount: 90.0,
        heads: 1,
        finalAmount: 90.0,
      );
      expect(beadsRecord.accountName, 'Beads');
    });

    test('ProductionProvider getTrendSummary calculates separate trends per account', () async {
      final provider = ProductionProvider();
      await provider.init();

      final allSummary = provider.getTrendSummary(TrendPeriod.day);
      final beadsSummary = provider.getTrendSummary(TrendPeriod.day, 'Beads');
      final area250Summary = provider.getTrendSummary(TrendPeriod.day, '250 Area');
      final area400Summary = provider.getTrendSummary(TrendPeriod.day, '400 Area');

      expect(allSummary, isNotNull);
      expect(beadsSummary, isNotNull);
      expect(area250Summary, isNotNull);
      expect(area400Summary, isNotNull);
    });

    test('ProductionProvider filters records correctly when selectedAccountFilter is set', () async {
      final provider = ProductionProvider();
      await provider.init();

      provider.setSelectedAccountFilter('Beads');
      expect(provider.selectedAccountFilter, 'Beads');
      for (final r in provider.filteredRecords) {
        expect(r.accountName, 'Beads');
      }

      provider.setSelectedAccountFilter('All Accounts');
      expect(provider.selectedAccountFilter, 'All Accounts');
    });

    test('Initial production records start empty by default', () {
      expect(SampleData.getInitialRecords(), isEmpty);
    });

    test('All 8 Dahao machines (M-01 to M-08) are present in SampleData and database', () async {
      final machines = SampleData.getMachines();
      expect(machines.length, 8);
      expect(machines.map((m) => m.machineNo).toList(), [
        'M-01', 'M-02', 'M-03', 'M-04', 'M-05', 'M-06', 'M-07', 'M-08'
      ]);

      final provider = ProductionProvider();
      await provider.init();
      expect(provider.machines.length, greaterThanOrEqualTo(8));
      final dbMachineNos = provider.machines.map((m) => m.machineNo).toSet();
      expect(dbMachineNos, containsAll(['M-01', 'M-02', 'M-03', 'M-04', 'M-05', 'M-06', 'M-07', 'M-08']));
    });
  });
}
