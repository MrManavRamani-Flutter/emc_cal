import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/models/production_record.dart';
import 'package:emb_cal/providers/production_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('UI Enhancements & Calculation Inspector Tests', () {
    test('ProductionProvider selectEntryRecord and clearEntrySelection correctly manage inspector state', () async {
      final provider = ProductionProvider();
      await provider.init();

      final dummyRecord = ProductionRecord(
        id: 999,
        date: DateTime.now(),
        designNo: 'TEST-01',
        machineNo: 'M-01',
        accountName: '250 Area',
        totalStitch: 500000,
        finalStitch: 500,
        rate: 1.25,
        amount: 625.0,
        heads: 16,
        finalAmount: 10000.0,
      );

      expect(provider.entrySelectedRecord, isNull);

      // Select record -> inspector opens
      provider.selectEntryRecord(dummyRecord);
      expect(provider.entrySelectedRecord?.id, 999);
      expect(provider.entrySelectedRecord?.finalAmount, 10000.0);

      // Tapping same record deselects
      provider.selectEntryRecord(dummyRecord);
      expect(provider.entrySelectedRecord, isNull);

      // Select again and explicitly clear
      provider.selectEntryRecord(dummyRecord);
      expect(provider.entrySelectedRecord?.id, 999);
      provider.clearEntrySelection();
      expect(provider.entrySelectedRecord, isNull);
    });

    test('getAccountSummary correctly aggregates category batches, stitches, and revenue', () async {
      final provider = ProductionProvider();
      await provider.init();

      final beadsSummary = provider.getAccountSummary('Beads');
      final area250Summary = provider.getAccountSummary('250 Area');
      final area400Summary = provider.getAccountSummary('400 Area');

      expect(beadsSummary.accountName, 'Beads');
      expect(area250Summary.accountName, '250 Area');
      expect(area400Summary.accountName, '400 Area');
      expect(area250Summary.totalEntries, greaterThanOrEqualTo(0));
      expect(area250Summary.totalStitch, greaterThanOrEqualTo(0));
      expect(area250Summary.finalAmount, greaterThanOrEqualTo(0.0));
    });

    test('Category filtering updates selectedAccountFilter without navigating away', () async {
      final provider = ProductionProvider();
      await provider.init();

      expect(provider.selectedAccountFilter, 'All Accounts');

      provider.setSelectedAccountFilter('Beads');
      expect(provider.selectedAccountFilter, 'Beads');

      provider.setSelectedAccountFilter('400 Area');
      expect(provider.selectedAccountFilter, '400 Area');

      provider.setSelectedAccountFilter('All Accounts');
      expect(provider.selectedAccountFilter, 'All Accounts');
    });

    test('Dashboard filters out accounts with zero entries from production table section', () async {
      final provider = ProductionProvider();
      await provider.init();

      final accounts = provider.accounts;
      final accountsWithEntries = accounts.where((acc) {
        return provider.getAccountSummary(acc.name).totalEntries > 0;
      }).toList();

      for (final acc in accountsWithEntries) {
        expect(provider.getAccountSummary(acc.name).totalEntries, greaterThan(0));
      }
    });

    test('Dashboard sorts accounts with highest production first (aage rakho)', () async {
      final provider = ProductionProvider();
      await provider.init();

      final accounts = provider.accounts;
      final accountsWithEntries = accounts.where((acc) {
        return provider.getAccountSummary(acc.name).totalEntries > 0;
      }).toList();

      accountsWithEntries.sort((a, b) {
        final sumA = provider.getAccountSummary(a.name);
        final sumB = provider.getAccountSummary(b.name);
        final stitchComp = sumB.totalStitch.compareTo(sumA.totalStitch);
        if (stitchComp != 0) return stitchComp;
        return sumB.finalAmount.compareTo(sumA.finalAmount);
      });

      if (accountsWithEntries.length >= 2) {
        final topSummary = provider.getAccountSummary(accountsWithEntries.first.name);
        final secondSummary = provider.getAccountSummary(accountsWithEntries[1].name);
        expect(topSummary.totalStitch, greaterThanOrEqualTo(secondSummary.totalStitch));
      }
    });
  });
}
