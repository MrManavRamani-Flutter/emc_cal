import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/core/app_theme.dart';
import 'package:emb_cal/models/material_item.dart';
import 'package:emb_cal/providers/production_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('1. Khushi Fashion Demo Bill & Material Calculation Tests', () {
    test('Khushi Fashion Challan #1086 Item 1 (cd) auto-computes correct amount', () {
      final item1 = MaterialItem(
        challanNo: '1086',
        supplierName: 'KHUSHI FASHION',
        date: DateTime(2026, 10, 1),
        category: 'Sequence',
        productName: 'L L CHIKKU',
        itemType: 'cd',
        mtr: 190.00,
        mm: 5.00,
        qty: 150.00,
        rate: 87.40,
        amount: 150.00 * 87.40, // 13110.00
        usedQty: 0.0,
      );

      expect(item1.qty * item1.rate, equals(13110.00));
      expect(item1.amount, equals(13110.00));
      expect(item1.balanceQty, equals(150.00));
      expect(item1.balanceAmount, equals(13110.00));
      expect(item1.isOutOfStock, isFalse);
      expect(item1.usagePercent, equals(0.0));
    });

    test('Khushi Fashion Challan #1086 Item 2 (firka) auto-computes correct amount', () {
      final item2 = MaterialItem(
        challanNo: '1086',
        supplierName: 'KHUSHI FASHION',
        date: DateTime(2026, 10, 1),
        category: 'Sequence',
        productName: 'L L CHIKKU',
        itemType: 'firka',
        mtr: 500.00,
        mm: 3.00,
        qty: 96.00,
        rate: 150.00,
        amount: 96.00 * 150.00, // 14400.00
        usedQty: 0.0,
      );

      expect(item2.qty * item2.rate, equals(14400.00));
      expect(item2.amount, equals(14400.00));
      expect(item2.balanceQty, equals(96.00));
    });

    test('Total Challan Sum equals ₹27,510 (≈ ₹27,511 on bill)', () {
      final amt1 = 150.00 * 87.40; // 13110.0
      final amt2 = 96.00 * 150.00; // 14400.0
      final total = amt1 + amt2;

      expect(total, equals(27510.00));
    });

    test('Material consumption updates balanceQty, balanceAmount and flags stock status', () {
      final item = MaterialItem(
        date: DateTime(2026, 10, 1),
        category: 'Sequence',
        productName: 'L L CHIKKU',
        itemType: 'cd',
        mtr: 190.0,
        mm: 5.0,
        qty: 100.0,
        rate: 50.0,
        amount: 5000.0,
        usedQty: 85.0,
      );

      expect(item.balanceQty, equals(15.0));
      expect(item.balanceAmount, equals(750.0));
      expect(item.usagePercent, equals(85.0));
      expect(item.isLowStock, isTrue); // < 20% remaining
      expect(item.isOutOfStock, isFalse);

      final depleted = item.copyWith(usedQty: 100.0);
      expect(depleted.balanceQty, equals(0.0));
      expect(depleted.balanceAmount, equals(0.0));
      expect(depleted.isOutOfStock, isTrue);
    });

    test('Categories: Daga, Sequence, and Beads are handled separately', () {
      final daga = MaterialItem(date: DateTime(2026, 10, 1), category: 'Daga', productName: 'Gold Metallic Zari', itemType: 'cone', qty: 20, rate: 250);
      final seq = MaterialItem(date: DateTime(2026, 10, 1), category: 'Sequence', productName: 'L L CHIKKU', itemType: 'cd', qty: 150, rate: 87.4);
      final beads = MaterialItem(date: DateTime(2026, 10, 1), category: 'Beads', productName: 'Pearl White Round Moti', itemType: 'packet', qty: 40, rate: 95);

      expect(daga.category, equals('Daga'));
      expect(seq.category, equals('Sequence'));
      expect(beads.category, equals('Beads'));
      expect(daga.amount, equals(5000.0));
      expect(beads.amount, equals(3800.0));
    });
  });

  group('2. Theme System Contrast Safety & Palettes', () {
    test('Light theme colors return dark text for 100% label readability', () {
      // Soft Sky (#38BDF8)
      final sky = AppTheme.parseColor('#38BDF8');
      expect(AppTheme.isLightColor(sky), isTrue);
      expect(AppTheme.contrastText(sky), equals(const Color(0xFF0F172A)));

      // Golden Honey (#FBBF24)
      final golden = AppTheme.parseColor('#FBBF24');
      expect(AppTheme.isLightColor(golden), isTrue);
      expect(AppTheme.contrastText(golden), equals(const Color(0xFF0F172A)));

      // Mint Aqua (#34D399)
      final mint = AppTheme.parseColor('#34D399');
      expect(AppTheme.isLightColor(mint), isTrue);
      expect(AppTheme.contrastText(mint), equals(const Color(0xFF0F172A)));

      // Pure White (#FFFFFF)
      final white = AppTheme.parseColor('#FFFFFF');
      expect(AppTheme.contrastText(white), equals(const Color(0xFF0F172A)));
    });

    test('Dark theme colors return crisp white text', () {
      // Midnight Slate (#1E293B)
      final midnight = AppTheme.parseColor('#1E293B');
      expect(AppTheme.isLightColor(midnight), isFalse);
      expect(AppTheme.contrastText(midnight), equals(Colors.white));

      // Deep Navy (#1E3A8A)
      final navy = AppTheme.parseColor('#1E3A8A');
      expect(AppTheme.isLightColor(navy), isFalse);
      expect(AppTheme.contrastText(navy), equals(Colors.white));

      // Forest Emerald (#064E3B)
      final forest = AppTheme.parseColor('#064E3B');
      expect(AppTheme.isLightColor(forest), isFalse);
      expect(AppTheme.contrastText(forest), equals(Colors.white));
    });

    test('Preset palette contains both light and dark categorized entries', () {
      final presets = AppTheme.presetThemeColors;
      expect(presets.length, greaterThanOrEqualTo(20));

      final lightList = presets.where((p) => p['type'] == 'light').toList();
      final darkList = presets.where((p) => p['type'] == 'dark').toList();
      final vibrantList = presets.where((p) => p['type'] == 'vibrant').toList();

      expect(lightList.isNotEmpty, isTrue);
      expect(darkList.isNotEmpty, isTrue);
      expect(vibrantList.isNotEmpty, isTrue);
    });
  });

  group('3. Multi-Filter Production Analytics Tests with Provider', () {
    test('Simultaneous filtering by Khata, Machine, Date, and Shift works on dataset', () async {
      final provider = ProductionProvider();
      await provider.init();

      await provider.addRecord(
        date: DateTime.now(),
        designNo: 'D-001',
        machineNo: 'M-01',
        totalStitch: 10000,
        rate: 0.5,
        heads: 1,
        notes: 'Test note',
        accountName: '250 Area',
        shift: 'Day',
      );

      expect(provider.allRecords, isNotEmpty);

      // Verify records can be filtered by Machine
      final machineRecords = provider.getFilteredAnalyticsRecords(machineNo: 'M-01');
      expect(machineRecords, isNotEmpty);
      for (final r in machineRecords) {
        expect(r.machineNo, equals('M-01'));
      }

      // Verify filtering by Account
      final accountRecords = provider.getFilteredAnalyticsRecords(accountName: '250 Area');
      expect(accountRecords, isNotEmpty);
      for (final r in accountRecords) {
        expect(r.accountName, equals('250 Area'));
      }

      // Verify filtering by Account AND Machine together
      final comboRecords = provider.getFilteredAnalyticsRecords(
        accountName: '250 Area',
        machineNo: 'M-01',
      );
      expect(comboRecords, isNotEmpty);
      for (final r in comboRecords) {
        expect(r.accountName, equals('250 Area'));
        expect(r.machineNo, equals('M-01'));
      }

      // Verify filtering with Shift
      final dayRecords = provider.getFilteredAnalyticsRecords(shift: 'Day');
      for (final r in dayRecords) {
        expect(r.shift, equals('Day'));
      }
    });

    test('Material items filter and insert correctly in provider', () async {
      final provider = ProductionProvider();
      await provider.init();

      final testItem = MaterialItem(
        challanNo: '1086',
        supplierName: 'KHUSHI FASHION',
        productName: 'L L CHIKKU',
        category: 'Beads',
        itemType: 'cone',
        qty: 10.0,
        rate: 100.0,
        amount: 1000.0,
        date: DateTime.now(),
      );
      await provider.insertMaterialItem(testItem);

      expect(provider.materials, isNotEmpty);

      // Verify Khushi Fashion items exist in stock
      final khushiItems = provider.materials.where((m) => m.supplierName.toUpperCase().contains('KHUSHI')).toList();
      expect(khushiItems, isNotEmpty);
      expect(khushiItems.any((m) => m.challanNo == '1086'), isTrue);
      expect(khushiItems.any((m) => m.productName.contains('L L CHIKKU')), isTrue);
    });
  });
}
