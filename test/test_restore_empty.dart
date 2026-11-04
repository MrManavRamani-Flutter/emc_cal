import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/data/database_helper.dart';
import 'package:emb_cal/models/material_item.dart';
import 'package:emb_cal/providers/production_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Restore Empty System & Smart Merge Tests', () {
    final dbHelper = DatabaseHelper.instance;

    setUp(() async {
      final db = await dbHelper.database;
      await db.delete('production_records');
      await db.delete('material_items');
      await db.delete('machines');
      await db.delete('accounts');
      await db.delete('material_products');
      await db.delete('suppliers');
      await db.delete('employees');
      await db.delete('employee_upads');
      await db.delete('whatsapp_logs');
      await db.delete('deleted_records');
    });

    test('1. Empty system with merge=true directly sets full data from backup', () async {
      final provider = ProductionProvider();
      await provider.init();

      expect(provider.allRecords.length, 0);
      expect(provider.materials.length, 0);
      expect(await provider.isDatabaseEmpty(), isTrue);

      final backupData = {
        'production_records': [
          {
            'id': 1,
            'date': '2026-11-04',
            'created_at': '2026-11-04T12:00:00',
            'design_no': 'D-101',
            'machine_no': 'M-01',
            'total_stitch': 50000,
            'final_stitch': 50.0,
            'rate': 1.25,
            'amount': 62.5,
            'heads': 12,
            'final_amount': 750.0,
            'account_name': '400 Area',
            'shift': 'Day'
          },
          {
            'id': 2,
            'date': '2026-11-04',
            'created_at': '2026-11-04T12:05:00',
            'design_no': 'D-102',
            'machine_no': 'M-02',
            'total_stitch': 30000,
            'final_stitch': 30.0,
            'rate': 1.25,
            'amount': 37.5,
            'heads': 15,
            'final_amount': 562.5,
            'account_name': '400 Area',
            'shift': 'Day'
          }
        ],
        'material_items': [
          {
            'id': 1,
            'challan_no': 'CH-001',
            'supplier_name': 'Test Supplier',
            'date': '2026-11-04',
            'category': 'Sequence',
            'product_name': 'Seq 5mm',
            'item_type': 'pkt',
            'qty': 100,
            'rate': 10,
            'amount': 1000,
            'payment_status': 'Pending'
          }
        ],
        'machines': [
          {
            'machine_no': 'M-01',
            'name': 'Machine 1',
            'head_capacity': 12,
            'is_active': 1
          },
          {
            'machine_no': 'M-02',
            'name': 'Machine 2',
            'head_capacity': 15,
            'is_active': 1
          }
        ],
        'accounts': [
          {
            'name': '400 Area',
            'area': '400',
            'display_order': 1,
            'color_hex': '#2563EB',
            'is_active': 1
          }
        ]
      };

      final jsonStr = jsonEncode(backupData);
      // User clicked Option A (merge=true) on an EMPTY system
      await provider.restoreFromJson(jsonStr, merge: true);

      // Verify that full data is directly set!
      expect(provider.allRecords.length, 2);
      expect(provider.materials.length, 1);
      expect(provider.machines.length, 2);
      expect(provider.accounts.length, 1);
      expect(provider.allRecords.any((r) => r.designNo == 'D-101'), isTrue);
      expect(provider.allRecords.any((r) => r.designNo == 'D-102'), isTrue);
      expect(provider.materials.first.challanNo, 'CH-001');
    });

    test('2. Populated system with merge=true properly manages existing records and adds new backup records', () async {
      final provider = ProductionProvider();
      await provider.init();

      // Insert an existing current record
      await provider.addRecord(
        date: DateTime(2026, 11, 4),
        designNo: 'CURRENT-RECORD-1',
        machineNo: 'M-01',
        totalStitch: 40000,
        rate: 1.5,
        heads: 12,
        accountName: '250 Area',
        shift: 'Day',
      );

      // Insert an existing current material
      await provider.insertMaterialItem(MaterialItem(
        challanNo: 'CH-EXISTING-99',
        supplierName: 'Current Vendor',
        date: DateTime(2026, 11, 4),
        category: 'Beads',
        productName: 'Glass Beads',
        itemType: 'box',
        qty: 20,
        rate: 50,
        amount: 1000,
      ));

      expect(provider.allRecords.length, 1);
      expect(provider.materials.length, 1);
      expect(await provider.isDatabaseEmpty(), isFalse);

      // Now restore from a backup that has a DIFFERENT record and a duplicate
      final backupData = {
        'production_records': [
          // New record from backup
          {
            'id': 1, // ID collides with current record id=1, but content is different
            'date': '2026-11-04',
            'design_no': 'BACKUP-NEW-REC',
            'machine_no': 'M-02',
            'total_stitch': 60000,
            'heads': 14,
            'rate': 1.25,
            'account_name': '400 Area',
            'shift': 'Night'
          },
          // Duplicate of existing record (same business key)
          {
            'id': 2,
            'date': '2026-11-04',
            'design_no': 'CURRENT-RECORD-1',
            'machine_no': 'M-01',
            'total_stitch': 40000,
            'heads': 12,
            'rate': 1.75, // Updated rate
            'account_name': '250 Area',
            'shift': 'Day'
          }
        ],
        'material_items': [
          {
            'id': 1,
            'challan_no': 'CH-BACKUP-NEW',
            'supplier_name': 'Backup Supplier',
            'date': '2026-11-04',
            'category': 'Thread',
            'product_name': 'Gold Thread',
            'item_type': 'spool',
            'qty': 50,
            'rate': 30,
            'amount': 1500,
          }
        ]
      };

      final jsonStr = jsonEncode(backupData);
      await provider.restoreFromJson(jsonStr, merge: true);

      // System should now contain BOTH current and new records!
      expect(provider.allRecords.length, 2);
      expect(provider.allRecords.any((r) => r.designNo == 'BACKUP-NEW-REC'), isTrue);
      expect(provider.allRecords.any((r) => r.designNo == 'CURRENT-RECORD-1'), isTrue);

      // Duplicate record was updated (rate = 1.75)
      final updatedRec = provider.allRecords.firstWhere((r) => r.designNo == 'CURRENT-RECORD-1');
      expect(updatedRec.rate, 1.75);

      // Materials: both existing and backup items exist!
      expect(provider.materials.length, 2);
      expect(provider.materials.any((m) => m.challanNo == 'CH-EXISTING-99'), isTrue);
      expect(provider.materials.any((m) => m.challanNo == 'CH-BACKUP-NEW'), isTrue);
    });
  });
}
