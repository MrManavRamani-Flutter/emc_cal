import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/data/database_helper.dart';
import 'package:emb_cal/data/sample_data.dart';
import 'package:emb_cal/models/account_model.dart';
import 'package:emb_cal/models/machine_model.dart';
import 'package:emb_cal/models/material_item.dart';
import 'package:emb_cal/models/material_product.dart';
import 'package:emb_cal/models/supplier.dart';
import 'package:emb_cal/providers/production_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('1. Dummy Data Removal Verification', () {
    test('Initial sample records and materials are completely empty', () {
      expect(SampleData.getInitialRecords(), isEmpty);
      expect(SampleData.getInitialMaterials(), isEmpty);
    });

    test('Master setup retains essential machine catalogs and default accounts', () {
      final accounts = SampleData.getInitialAccounts();
      final machines = SampleData.getMachines();

      expect(accounts.length, 3);
      expect(accounts.map((a) => a.name), containsAll(['250 Area', '400 Area', 'Beads']));
      expect(machines.length, 8);
      expect(machines.first.machineNo, 'M-01');
      expect(machines.last.machineNo, 'M-08');
    });

    test('ProductionProvider initializes without dummy records or dummy bills', () async {
      final provider = ProductionProvider();
      await provider.init();
      await provider.clearAllDummyData();

      // Check no dummy records exist
      final dummyDesignMatches = provider.allRecords.where((r) =>
        r.designNo == '11131' ||
        r.designNo == '11010' ||
        r.designNo == '724' ||
        r.designNo == '257 TOP.DH' ||
        r.designNo == '10151 KALI'
      ).toList();
      expect(dummyDesignMatches, isEmpty);

      final dummyChallanMatches = provider.materials.where((m) =>
        m.challanNo == '1086' ||
        m.challanNo == 'CH-4091' ||
        m.challanNo == 'CH-4120'
      ).toList();
      expect(dummyChallanMatches, isEmpty);
    });
  });

  group('2. Recycle Bin & Restoration across all 6 Entity Tables', () {
    late ProductionProvider provider;

    setUp(() async {
      provider = ProductionProvider();
      await provider.init();
      await provider.emptyRecycleBin();
    });

    test('Production Record: Delete archives to Recycle Bin & Restore returns to records table', () async {
      await provider.addRecord(
        date: DateTime(2026, 10, 28),
        designNo: 'TEST-REC-001',
        machineNo: 'M-01',
        totalStitch: 25000,
        rate: 0.65,
        heads: 1,
        accountName: '250 Area',
      );

      final added = provider.allRecords.firstWhere((r) => r.designNo == 'TEST-REC-001');
      expect(added.id, isNotNull);

      // Delete record -> should archive to recycle bin
      await provider.deleteRecord(added.id!);
      expect(provider.allRecords.any((r) => r.designNo == 'TEST-REC-001'), isFalse);
      expect(provider.deletedRecords.any((d) => d.recordTitle.contains('TEST-REC-001')), isTrue);

      final deletedItem = provider.deletedRecords.firstWhere((d) => d.recordTitle.contains('TEST-REC-001'));
      expect(deletedItem.recordType, 'production_record');
      expect(deletedItem.originalId, added.id);

      // Restore record -> should return to production_records
      await provider.restoreDeletedRecord(deletedItem.id!);
      expect(provider.deletedRecords.any((d) => d.id == deletedItem.id), isFalse);
      expect(provider.allRecords.any((r) => r.designNo == 'TEST-REC-001'), isTrue);

      final restored = provider.allRecords.firstWhere((r) => r.designNo == 'TEST-REC-001');
      expect(restored.totalStitch, 25000);
      expect(restored.accountName, '250 Area');

      // Cleanup
      await provider.deleteRecord(restored.id!);
      await provider.emptyRecycleBin();
    });

    test('Material Item: Delete archives to Recycle Bin & Restore returns to materials table', () async {
      final testMaterial = MaterialItem(
        challanNo: 'CH-TEST-888',
        supplierName: 'TEST SUPPLIER',
        date: DateTime(2026, 10, 28),
        category: 'Sequence',
        productName: 'TEST MATERIAL',
        itemType: 'cd',
        mtr: 100.0,
        mm: 5.0,
        qty: 50.0,
        rate: 80.0,
        amount: 4000.0,
      );

      await provider.insertMaterialItem(testMaterial);
      final added = provider.materials.firstWhere((m) => m.challanNo == 'CH-TEST-888');
      expect(added.id, isNotNull);

      // Delete item
      await provider.deleteMaterialItem(added.id!);
      expect(provider.materials.any((m) => m.challanNo == 'CH-TEST-888'), isFalse);
      expect(provider.deletedRecords.any((d) => d.recordTitle.contains('CH-TEST-888')), isTrue);

      final deletedItem = provider.deletedRecords.firstWhere((d) => d.recordTitle.contains('CH-TEST-888'));
      expect(deletedItem.recordType, 'material_item');

      // Restore item
      await provider.restoreDeletedRecord(deletedItem.id!);
      expect(provider.deletedRecords.any((d) => d.id == deletedItem.id), isFalse);
      expect(provider.materials.any((m) => m.challanNo == 'CH-TEST-888'), isTrue);

      final restored = provider.materials.firstWhere((m) => m.challanNo == 'CH-TEST-888');
      expect(restored.amount, 4000.0);

      // Cleanup
      await provider.deleteMaterialItem(restored.id!);
      await provider.emptyRecycleBin();
    });

    test('Machine: Delete archives to Recycle Bin & Restore returns to machines table', () async {
      final testMachine = MachineModel(
        machineNo: 'M-TEST-99',
        name: 'M-TEST-99',
        headCapacity: 32,
        notes: 'Test Unit',
      );

      await provider.addMachine(testMachine);
      final added = provider.machines.firstWhere((m) => m.machineNo == 'M-TEST-99');
      expect(added.id, isNotNull);

      // Delete machine
      await provider.deleteMachine(added.id!);
      expect(provider.machines.any((m) => m.machineNo == 'M-TEST-99'), isFalse);
      expect(provider.deletedRecords.any((d) => d.recordTitle.contains('M-TEST-99')), isTrue);

      final deletedItem = provider.deletedRecords.firstWhere((d) => d.recordTitle.contains('M-TEST-99'));
      expect(deletedItem.recordType, 'machine');

      // Restore machine
      await provider.restoreDeletedRecord(deletedItem.id!);
      expect(provider.deletedRecords.any((d) => d.id == deletedItem.id), isFalse);
      expect(provider.machines.any((m) => m.machineNo == 'M-TEST-99'), isTrue);

      final restored = provider.machines.firstWhere((m) => m.machineNo == 'M-TEST-99');
      expect(restored.headCapacity, 32);

      // Cleanup
      await provider.deleteMachine(restored.id!);
      await provider.emptyRecycleBin();
    });

    test('Account: Delete archives to Recycle Bin & Restore returns to accounts table', () async {
      final testAccount = AccountModel(
        name: 'Custom Khata Test',
        area: 'Test Khata Area',
        notes: 'Temporary testing account',
      );

      await provider.addAccount(testAccount);
      final added = provider.accounts.firstWhere((a) => a.name == 'Custom Khata Test');
      expect(added.id, isNotNull);

      // Delete account
      await provider.deleteAccount(added.id!);
      expect(provider.accounts.any((a) => a.name == 'Custom Khata Test'), isFalse);
      expect(provider.deletedRecords.any((d) => d.recordTitle.contains('Custom Khata Test')), isTrue);

      final deletedItem = provider.deletedRecords.firstWhere((d) => d.recordTitle.contains('Custom Khata Test'));
      expect(deletedItem.recordType, 'account');

      // Restore account
      await provider.restoreDeletedRecord(deletedItem.id!);
      expect(provider.deletedRecords.any((d) => d.id == deletedItem.id), isFalse);
      expect(provider.accounts.any((a) => a.name == 'Custom Khata Test'), isTrue);

      final restored = provider.accounts.firstWhere((a) => a.name == 'Custom Khata Test');
      expect(restored.area, 'Test Khata Area');

      // Cleanup
      await provider.deleteAccount(restored.id!);
      await provider.emptyRecycleBin();
    });

    test('Material Product: Delete archives & Restore returns to product catalog', () async {
      final testProd = MaterialProduct(
        name: 'Special Silk Thread Gold',
        category: 'Daga',
        unit: 'cone',
        defaultRate: 350.0,
      );

      await provider.insertMaterialProduct(testProd);
      final added = provider.materialProducts.firstWhere((p) => p.name == 'Special Silk Thread Gold');
      expect(added.id, isNotNull);

      // Delete product
      await provider.deleteMaterialProduct(added.id!);
      expect(provider.materialProducts.any((p) => p.name == 'Special Silk Thread Gold'), isFalse);
      expect(provider.deletedRecords.any((d) => d.recordTitle.contains('Special Silk Thread Gold')), isTrue);

      final deletedItem = provider.deletedRecords.firstWhere((d) => d.recordTitle.contains('Special Silk Thread Gold'));
      expect(deletedItem.recordType, 'material_product');

      // Restore product
      await provider.restoreDeletedRecord(deletedItem.id!);
      expect(provider.deletedRecords.any((d) => d.id == deletedItem.id), isFalse);
      expect(provider.materialProducts.any((p) => p.name == 'Special Silk Thread Gold'), isTrue);

      final restored = provider.materialProducts.firstWhere((p) => p.name == 'Special Silk Thread Gold');
      expect(restored.defaultRate, 350.0);

      // Cleanup
      await provider.deleteMaterialProduct(restored.id!);
      await provider.emptyRecycleBin();
    });

    test('Supplier: Delete archives & Restore returns to suppliers directory', () async {
      final testSupp = Supplier(
        name: 'Om Embroidery Suppliers Ltd',
        phone: '9876543210',
        city: 'Surat',
      );

      await provider.insertSupplier(testSupp);
      final added = provider.suppliers.firstWhere((s) => s.name == 'Om Embroidery Suppliers Ltd');
      expect(added.id, isNotNull);

      // Delete supplier
      await provider.deleteSupplier(added.id!);
      expect(provider.suppliers.any((s) => s.name == 'Om Embroidery Suppliers Ltd'), isFalse);
      expect(provider.deletedRecords.any((d) => d.recordTitle.contains('Om Embroidery Suppliers Ltd')), isTrue);

      final deletedItem = provider.deletedRecords.firstWhere((d) => d.recordTitle.contains('Om Embroidery Suppliers Ltd'));
      expect(deletedItem.recordType, 'supplier');

      // Restore supplier
      await provider.restoreDeletedRecord(deletedItem.id!);
      expect(provider.deletedRecords.any((d) => d.id == deletedItem.id), isFalse);
      expect(provider.suppliers.any((s) => s.name == 'Om Embroidery Suppliers Ltd'), isTrue);

      // Cleanup
      await provider.deleteSupplier(added.id!);
      await provider.emptyRecycleBin();
    });

    test('Permanent delete and Restore All operate cleanly across multiple items', () async {
      await provider.addRecord(
        date: DateTime.now(),
        designNo: 'MULTI-01',
        machineNo: 'M-01',
        totalStitch: 1000,
        rate: 1.0,
        heads: 1,
      );
      await provider.addRecord(
        date: DateTime.now(),
        designNo: 'MULTI-02',
        machineNo: 'M-02',
        totalStitch: 2000,
        rate: 1.0,
        heads: 1,
      );

      final addedR1 = provider.allRecords.firstWhere((r) => r.designNo == 'MULTI-01');
      final addedR2 = provider.allRecords.firstWhere((r) => r.designNo == 'MULTI-02');

      await provider.deleteRecord(addedR1.id!);
      await provider.deleteRecord(addedR2.id!);

      expect(provider.deletedRecords.length, 2);

      // Test Restore All
      await provider.restoreAllDeletedRecords();
      expect(provider.deletedRecords, isEmpty);
      expect(provider.allRecords.any((r) => r.designNo == 'MULTI-01'), isTrue);
      expect(provider.allRecords.any((r) => r.designNo == 'MULTI-02'), isTrue);

      // Test Permanent Delete
      final backR1 = provider.allRecords.firstWhere((r) => r.designNo == 'MULTI-01');
      await provider.deleteRecord(backR1.id!);
      final trashItem = provider.deletedRecords.firstWhere((d) => d.recordTitle.contains('MULTI-01'));
      await provider.permanentlyDeleteRecord(trashItem.id!);

      expect(provider.deletedRecords.any((d) => d.id == trashItem.id), isFalse);
      expect(provider.allRecords.any((r) => r.designNo == 'MULTI-01'), isFalse);

      // Cleanup remaining
      final backR2 = provider.allRecords.firstWhere((r) => r.designNo == 'MULTI-02');
      await provider.deleteRecord(backR2.id!);
      await provider.emptyRecycleBin();
    });
  });

  group('3. Backup & Restore End-to-End Tests', () {
    test('Export backup includes all 8 tables and metadata', () async {
      final dbHelper = DatabaseHelper.instance;
      final jsonString = await dbHelper.exportBackupJson();

      expect(jsonString, isNotEmpty);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(data.containsKey('app'), isTrue);
      expect(data['app'], 'OM MAVTAR GROUP');
      expect(data.containsKey('backup_timestamp'), isTrue);

      // Verify all tables are present
      expect(data.containsKey('accounts'), isTrue);
      expect(data.containsKey('machines'), isTrue);
      expect(data.containsKey('production_records'), isTrue);
      expect(data.containsKey('records'), isTrue); // alias for backward-compatibility
      expect(data.containsKey('material_items'), isTrue);
      expect(data.containsKey('materials'), isTrue); // alias
      expect(data.containsKey('material_products'), isTrue);
      expect(data.containsKey('suppliers'), isTrue);
      expect(data.containsKey('deleted_records'), isTrue);
      expect(data.containsKey('settings'), isTrue);
    });

    test('Restore from backup JSON successfully restores data and relationships', () async {
      final dbHelper = DatabaseHelper.instance;

      // Create a test backup payload
      final backupPayload = {
        'app': 'Embroidery Production Calculator',
        'version': '1.0.0',
        'backup_timestamp': DateTime.now().toIso8601String(),
        'accounts': [
          {'id': 100, 'name': 'Backup Test Account', 'area': 'Backup Area', 'rate': 0.7, 'is_active': 1}
        ],
        'machines': [
          {'id': 100, 'machine_no': 'M-BACKUP', 'name': 'M-BACKUP', 'head_capacity': 24, 'is_active': 1}
        ],
        'production_records': [
          {
            'id': 200,
            'date': '2026-10-28',
            'design_no': 'BKP-DESIGN-01',
            'machine_no': 'M-BACKUP',
            'account_name': 'Backup Test Account',
            'total_stitch': 50000,
            'final_stitch': 50000,
            'rate': 0.7,
            'amount': 350.0,
            'heads': 1,
            'final_amount': 350.0
          }
        ],
        'material_items': [
          {
            'id': 300,
            'challan_no': 'BKP-CH-999',
            'supplier_name': 'BKP SUPPLIER',
            'date': '2026-10-28',
            'category': 'Daga',
            'product_name': 'BKP Gold Thread',
            'item_type': 'cone',
            'qty': 10.0,
            'rate': 100.0,
            'amount': 1000.0
          }
        ],
        'material_products': [
          {'id': 400, 'name': 'BKP Product', 'category': 'Daga', 'default_rate': 100.0}
        ],
        'suppliers': [
          {'id': 500, 'name': 'BKP Supplier', 'city': 'Surat'}
        ],
        'deleted_records': [
          {
            'id': 600,
            'record_type': 'production_record',
            'record_title': 'TRASH-01',
            'record_subtitle': 'Deleted in test',
            'original_id': 999,
            'original_data': '{"designNo":"TRASH-01"}',
            'deleted_at': DateTime.now().toIso8601String()
          }
        ],
        'settings': {'company_name': 'Om Mavtar Group', 'is_dark_mode': 1}
      };

      final jsonStr = jsonEncode(backupPayload);
      await dbHelper.restoreFromJson(jsonStr);

      // Verify that the restored records are in the database
      final records = await dbHelper.getRecords();
      expect(records.any((r) => r.designNo == 'BKP-DESIGN-01'), isTrue);

      final materials = await dbHelper.getMaterialItems();
      expect(materials.any((m) => m.challanNo == 'BKP-CH-999'), isTrue);

      final accounts = await dbHelper.getAccounts();
      expect(accounts.any((a) => a.name == 'Backup Test Account'), isTrue);

      final machines = await dbHelper.getMachines();
      expect(machines.any((m) => m.machineNo == 'M-BACKUP'), isTrue);

      final products = await dbHelper.getMaterialProducts();
      expect(products.any((p) => p.name == 'BKP Product'), isTrue);

      final suppliers = await dbHelper.getSuppliers();
      expect(suppliers.any((s) => s.name == 'BKP Supplier'), isTrue);

      final deleted = await dbHelper.getDeletedRecords();
      expect(deleted.any((d) => d.recordTitle == 'TRASH-01'), isTrue);

      // Clean up after test by resetting to master sample data
      await dbHelper.resetToSampleData();
    });
  });
}
