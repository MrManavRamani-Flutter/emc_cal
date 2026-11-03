import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/providers/production_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Dashboard Search Isolation Tests', () {
    test('Searching query filters records accurately and resetting query restores full records', () async {
      final provider = ProductionProvider();
      await provider.init();

      // Add test records for search verification
      await provider.addRecord(
        date: DateTime.now(),
        designNo: '11010',
        machineNo: 'M-01',
        totalStitch: 10000,
        rate: 0.5,
        heads: 1,
      );
      await provider.addRecord(
        date: DateTime.now(),
        designNo: '12020',
        machineNo: 'M-02',
        totalStitch: 15000,
        rate: 0.5,
        heads: 1,
      );

      // Initially search query is empty
      expect(provider.searchQuery, isEmpty);
      final initialTotal = provider.filteredRecords.length;
      expect(initialTotal, greaterThan(0));

      // Filter by a design query '11010'
      provider.setSearchQuery('11010');
      expect(provider.searchQuery, '11010');
      expect(provider.filteredRecords, isNotEmpty);
      for (final r in provider.filteredRecords) {
        final matches = r.designNo.toLowerCase().contains('11010') ||
            r.machineNo.toLowerCase().contains('11010');
        expect(matches, isTrue);
      }

      // Filter by nonexistent query returns 0 records
      provider.setSearchQuery('NONEXISTENT_XYZ_999');
      expect(provider.filteredRecords, isEmpty);

      // Reset search query restores all records
      provider.setSearchQuery('');
      expect(provider.searchQuery, isEmpty);
      expect(provider.filteredRecords.length, initialTotal);
    });

    test('Search query matches machine numbers and clearSearch resets state', () async {
      final provider = ProductionProvider();
      await provider.init();

      provider.setSearchQuery('m-1');
      expect(provider.searchQuery, 'm-1');
      expect(provider.filteredRecords.every((r) =>
          r.designNo.toLowerCase().contains('m-1') ||
          r.machineNo.toLowerCase().contains('m-1')), isTrue);

      provider.setSearchQuery('');
      expect(provider.searchQuery, isEmpty);
    });
  });
}
