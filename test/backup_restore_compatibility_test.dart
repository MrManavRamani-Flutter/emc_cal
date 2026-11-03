import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/data/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Backup & Restore Backward Compatibility and Strict Filtering Tests', () {
    final dbHelper = DatabaseHelper.instance;

    setUp(() async {
      await dbHelper.resetToSampleData();
    });

    test('1. Old version backup with legacy keys, missing fields, and camelCase aliases imports cleanly', () async {
      // Legacy JSON where:
      // - 'records' is used instead of 'production_records'
      // - 'materials' is used instead of 'material_items'
      // - CamelCase keys: designNo, totalStitch, machineNo, challanNo, supplierName, itemType
      // - Missing payment_status (should default to 'Pending')
      // - Legacy account names ('250 Area Khatu') and category ('daga')
      // - Extra unwanted fields: 'temp_debug_id', 'created_by', 'sync_tag' (must be ignored)
      final legacyPayload = {
        'version': '0.9.0',
        'records': [
          {
            'id': 101,
            'date': '15-10-2026',
            'designNo': 'LEGACY-001',
            'machineNo': 'M-02',
            'totalStitch': 24000,
            'heads': 12,
            'rate': 1.5,
            'account': '250 Area Khatu',
            'temp_debug_id': 'junk_value_123',
            'created_by': 'old_system_v1'
          }
        ],
        'materials': [
          {
            'id': 201,
            'challanNo': 'CH-LEGACY-88',
            'supplierName': 'Old Vendor Textiles',
            'date': '16/10/2026',
            'category': 'daga',
            'productName': 'Old Cotton Dhaga',
            'itemType': 'box',
            'qty': 50,
            'rate': 120,
            'amount': 6000,
            'sync_tag': 'should_be_ignored'
          }
        ],
        'settings': {
          'companyName': 'Om Mavtar Group',
          'isDarkMode': true,
          'autoRefreshSeconds': '120',
          'extra_unwanted_setting': 'discard_me'
        }
      };

      final jsonStr = jsonEncode(legacyPayload);
      await dbHelper.restoreFromJson(jsonStr);

      // Verify production records
      final records = await dbHelper.getRecords();
      final rec = records.firstWhere((r) => r.designNo == 'LEGACY-001');
      expect(rec.machineNo, 'M-02');
      expect(rec.totalStitch, 24000);
      expect(rec.finalStitch, 24.0); // 24000 / 1000
      expect(rec.rate, 1.5);
      expect(rec.accountName, '250 Area'); // Normalized from '250 Area Khatu'
      expect(rec.shift, 'Day'); // Safe default
      expect(rec.date.year, 2026);
      expect(rec.date.month, 10);
      expect(rec.date.day, 15);

      // Verify material items
      final materials = await dbHelper.getMaterialItems();
      final mat = materials.firstWhere((m) => m.challanNo == 'CH-LEGACY-88');
      expect(mat.supplierName, 'Old Vendor Textiles');
      expect(mat.category, 'Thread'); // Normalized from 'daga' / 'dhaga'
      expect(mat.productName, 'Old Cotton Dhaga');
      expect(mat.itemType, 'box');
      expect(mat.qty, 50.0);
      expect(mat.rate, 120.0);
      expect(mat.amount, 6000.0);
      expect(mat.paymentStatus, 'Pending'); // Default fallback for old version
      expect(mat.isPaid, isFalse);
      expect(mat.date.year, 2026);

      // Verify settings
      final settings = await dbHelper.getSettings();
      expect(settings.companyName, 'OM MAVTAR GROUP');
      expect(settings.isDarkMode, isTrue);
      expect(settings.appLanguage, 'en'); // Default fallback preserved as English
      expect(settings.fontScale, 1.0); // Default fallback preserved

      // Verify factory machines and default accounts are preserved/seeded
      final machines = await dbHelper.getMachines();
      expect(machines.isNotEmpty, isTrue);
      expect(machines.any((m) => m.machineNo == 'M-01'), isTrue);

      final accounts = await dbHelper.getAccounts();
      expect(accounts.isNotEmpty, isTrue);
      expect(accounts.any((a) => a.name == '250 Area'), isTrue);
    });

    test('2. String numbers, boolean values, and date formats are properly sanitized', () async {
      final stringPayload = {
        'production_records': [
          {
            'id': '301',
            'date': '2026-11-01T10:30:00Z',
            'design_no': 'STR-TEST-99',
            'machine_no': 'M-03',
            'total_stitch': '35000',
            'heads': '14',
            'rate': '1.75',
            'account_name': '400 Area',
            'shift': 'night'
          }
        ],
        'material_items': [
          {
            'id': '401',
            'challan_no': 'CH-STR-01',
            'supplier_name': 'String Supplier',
            'date': '01-11-2026',
            'category': 'Sequence',
            'product_name': 'Sequins 5mm',
            'item_type': 'packet',
            'qty': '25.5',
            'rate': '80.0',
            'payment_status': 'paid',
            'payment_date': '02-11-2026'
          }
        ],
        'machines': [
          {
            'machine_no': 'M-99',
            'name': 'Special Dahao',
            'head_capacity': '16',
            'is_active': true // JSON boolean instead of 1
          }
        ]
      };

      final jsonStr = jsonEncode(stringPayload);
      await dbHelper.restoreFromJson(jsonStr);

      final records = await dbHelper.getRecords();
      final rec = records.firstWhere((r) => r.designNo == 'STR-TEST-99');
      expect(rec.totalStitch, 35000);
      expect(rec.heads, 14);
      expect(rec.rate, 1.75);
      expect(rec.shift, 'Night'); // Normalized

      final materials = await dbHelper.getMaterialItems();
      final mat = materials.firstWhere((m) => m.challanNo == 'CH-STR-01');
      expect(mat.qty, 25.5);
      expect(mat.rate, 80.0);
      expect(mat.amount, 25.5 * 80.0);
      expect(mat.paymentStatus, 'Paid');
      expect(mat.isPaid, isTrue);

      final machines = await dbHelper.getMachines();
      final machine = machines.firstWhere((m) => m.machineNo == 'M-99');
      expect(machine.headCapacity, 16);
      expect(machine.isActive, isTrue);
    });

    test('3. Root list format (single array of records) restores without error', () async {
      final listPayload = [
        {
          'design_no': 'ARRAY-REC-1',
          'machine_no': 'M-01',
          'total_stitch': 12000,
          'rate': 1.25,
          'heads': 12,
          'date': '2026-11-01'
        },
        {
          'design_no': 'ARRAY-REC-2',
          'machine_no': 'M-02',
          'total_stitch': 18000,
          'rate': 1.50,
          'heads': 12,
          'date': '2026-11-01'
        }
      ];

      final jsonStr = jsonEncode(listPayload);
      await dbHelper.restoreFromJson(jsonStr);

      final records = await dbHelper.getRecords();
      expect(records.any((r) => r.designNo == 'ARRAY-REC-1'), isTrue);
      expect(records.any((r) => r.designNo == 'ARRAY-REC-2'), isTrue);

      // Starter master accounts and machines are still seeded
      final accounts = await dbHelper.getAccounts();
      expect(accounts.isNotEmpty, isTrue);
    });

    test('4. Completely blank or corrupt rows in imported tables are safely skipped', () async {
      final corruptPayload = {
        'production_records': [
          {}, // Empty row
          {'random_trash': 9999}, // No design, machine, or stitches
          {
            'design_no': 'VALID-01',
            'machine_no': 'M-01',
            'total_stitch': 10000,
            'heads': 12,
            'rate': 1.25,
            'date': '2026-11-01'
          }
        ],
        'material_items': [
          {}, // Empty
          {
            'challan_no': 'VALID-CH',
            'supplier_name': 'Valid Supplier',
            'product_name': 'Valid Item',
            'category': 'Beads',
            'qty': 10,
            'rate': 50,
            'date': '2026-11-01'
          }
        ]
      };

      final jsonStr = jsonEncode(corruptPayload);
      await dbHelper.restoreFromJson(jsonStr);

      final records = await dbHelper.getRecords();
      expect(records.length, 1);
      expect(records.first.designNo, 'VALID-01');

      final materials = await dbHelper.getMaterialItems();
      expect(materials.length, 1);
      expect(materials.first.challanNo, 'VALID-CH');
    });

    test('5. exportBackupJson exports all necessary tables and metadata cleanly', () async {
      final exportedJson = await dbHelper.exportBackupJson();
      final decoded = jsonDecode(exportedJson) as Map<String, dynamic>;

      expect(decoded['app'], 'OM MAVTAR GROUP');
      expect(decoded['version'], isNotEmpty);
      expect(decoded['exported_at'], isNotEmpty);
      expect(decoded['accounts'], isA<List>());
      expect(decoded['machines'], isA<List>());
      expect(decoded['production_records'], isA<List>());
      expect(decoded['records'], isA<List>()); // Legacy key included
      expect(decoded['material_items'], isA<List>());
      expect(decoded['materials'], isA<List>()); // Legacy key included
      expect(decoded['material_products'], isA<List>());
      expect(decoded['suppliers'], isA<List>());
      expect(decoded['settings'], isA<Map>());
    });
  });
}
