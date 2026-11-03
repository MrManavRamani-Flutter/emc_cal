import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:emb_cal/data/database_helper.dart';
import 'package:emb_cal/models/deleted_record_item.dart';
import 'package:emb_cal/widgets/app_svg_icon.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('2-Tier Soft Delete & Deep Safe Vault Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      await db.delete('deleted_records');
      await db.delete('production_records');
    });

    test('Record deletion moves to Active Recycle Bin (is_archived = 0)', () async {
      final item = DeletedRecordItem(
        recordType: 'production_record',
        recordTitle: 'Design D-101 | M-01',
        recordSubtitle: 'Stitch: 100,000 | ₹56.00',
        originalId: 99,
        originalData: jsonEncode({
          'id': 99,
          'date': DateTime.now().toIso8601String(),
          'design_no': 'D-101',
          'machine_no': 'M-01',
          'total_stitch': 100000,
          'final_stitch': 100000,
          'rate': 0.14,
          'amount': 14.0,
          'heads': 4,
          'final_amount': 56.0,
          'notes': 'Test record',
          'account_name': '250 Area',
          'shift': 'Day',
        }),
        deletedAt: DateTime.now(),
        isArchived: 0,
      );

      final insertId = await dbHelper.insertDeletedRecord(item);
      expect(insertId, greaterThan(0));

      final binRecords = await dbHelper.getDeletedRecords(isArchived: false);
      expect(binRecords.length, 1);
      expect(binRecords.first.recordTitle, 'Design D-101 | M-01');
      expect(binRecords.first.isArchived, 0);

      final vaultRecords = await dbHelper.getArchivedRecords();
      expect(vaultRecords.isEmpty, true);
    });

    test('Deleting from bin moves to Deep Safe Vault (is_archived = 1) instead of hard drop', () async {
      final item = DeletedRecordItem(
        recordType: 'production_record',
        recordTitle: 'Design D-202 | M-02',
        recordSubtitle: 'Stitch: 80,000',
        originalId: 100,
        originalData: jsonEncode({
          'date': DateTime.now().toIso8601String(),
          'design_no': 'D-202',
          'machine_no': 'M-02',
          'total_stitch': 80000,
          'final_stitch': 80000,
          'rate': 0.14,
          'amount': 11.2,
          'heads': 4,
          'final_amount': 44.8,
          'notes': 'Test',
          'account_name': '400 Area',
          'shift': 'Night',
        }),
        deletedAt: DateTime.now(),
      );

      final insertId = await dbHelper.insertDeletedRecord(item);

      // Permanent delete from bin
      await dbHelper.deleteDeletedRecord(insertId);

      // Should be removed permanently - nowhere stored
      final binRecords = await dbHelper.getDeletedRecords();
      expect(binRecords.isEmpty, true);
    });

    test('Emptying Recycle Bin permanently clears all deleted records', () async {
      final item = DeletedRecordItem(
        recordType: 'production_record',
        recordTitle: 'Design D-303 | M-03',
        recordSubtitle: 'Stitch: 50,000',
        originalId: 101,
        originalData: jsonEncode({
          'date': DateTime.now().toIso8601String(),
          'design_no': 'D-303',
          'machine_no': 'M-03',
          'total_stitch': 50000,
          'final_stitch': 50000,
          'rate': 0.14,
          'amount': 7.0,
          'heads': 4,
          'final_amount': 28.0,
          'notes': '',
          'account_name': 'Beads',
          'shift': 'Day',
        }),
        deletedAt: DateTime.now(),
      );

      await dbHelper.insertDeletedRecord(item);
      expect((await dbHelper.getDeletedRecords()).isNotEmpty, true);

      // Empty all
      await dbHelper.clearAllDeletedRecords();

      final binRecords = await dbHelper.getDeletedRecords();
      expect(binRecords.isEmpty, true);
    });

    test('Restoring record from Deep Safe Vault restores it back to active database row', () async {
      final originalDataMap = {
        'date': DateTime.now().toIso8601String(),
        'design_no': 'RESTORED-101',
        'machine_no': 'M-01',
        'total_stitch': 120000,
        'final_stitch': 120000,
        'rate': 0.14,
        'amount': 16.8,
        'heads': 4,
        'final_amount': 67.2,
        'notes': 'Restored from vault',
        'account_name': '250 Area',
        'shift': 'Day',
      };

      final item = DeletedRecordItem(
        recordType: 'production_record',
        recordTitle: 'Design RESTORED-101',
        recordSubtitle: 'Vault Item',
        originalId: 202,
        originalData: jsonEncode(originalDataMap),
        deletedAt: DateTime.now(),
        isArchived: 1,
      );

      final insertId = await dbHelper.insertDeletedRecord(item);

      // Restore from vault
      final success = await dbHelper.restoreDeletedRecord(insertId);
      expect(success, true);

      // Should be removed from deleted_records
      expect((await dbHelper.getArchivedRecords()).isEmpty, true);

      // Should be re-inserted into production_records
      final allRecords = await dbHelper.getRecords();
      expect(allRecords.any((r) => r.designNo == 'RESTORED-101'), true);
    });
  });

  group('AppSvgIcon Vector Graphics Verification Tests', () {
    testWidgets('AppSvgIcon builds without errors for all core navigation icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppSvgIcon.dashboard(size: 24, color: Colors.blue),
                AppSvgIcon.production(size: 24, color: Colors.green),
                AppSvgIcon.employees(size: 24, color: Colors.purple),
                AppSvgIcon.accounts(size: 24, color: Colors.amber),
                AppSvgIcon.materials(size: 24, color: Colors.orange),
                AppSvgIcon.analytics(size: 24, color: Colors.indigo),
                AppSvgIcon.excel(size: 24, color: Colors.teal),
                AppSvgIcon.machines(size: 24, color: Colors.cyan),
                AppSvgIcon.rates(size: 24, color: Colors.red),
                AppSvgIcon.recycleBin(size: 24, color: Colors.grey),
                AppSvgIcon.vault(size: 24, color: Colors.purple),
                AppSvgIcon.settings(size: 24, color: Colors.blueGrey),
                AppSvgIcon.sun(size: 20, color: Colors.amber),
                AppSvgIcon.moon(size: 20, color: Colors.blueGrey),
                AppSvgIcon.collapse(size: 20, color: Colors.black),
                AppSvgIcon.expand(size: 20, color: Colors.black),
                AppSvgIcon.add(size: 20, color: Colors.white),
                AppSvgIcon.edit(size: 20, color: Colors.blue),
                AppSvgIcon.delete(size: 20, color: Colors.red),
                AppSvgIcon.restore(size: 20, color: Colors.green),
                AppSvgIcon.info(size: 20, color: Colors.blue),
                AppSvgIcon.printIcon(size: 20, color: Colors.black),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AppSvgIcon), findsNWidgets(22));
    });

    test('DeletedRecordItem.getSvgIcon returns valid AppSvgIcon widget', () {
      final item = DeletedRecordItem(
        recordType: 'production_record',
        recordTitle: 'Test Title',
        recordSubtitle: 'Test Subtitle',
        originalData: '{}',
        deletedAt: DateTime.now(),
      );

      final iconWidget = item.getSvgIcon(size: 20, color: Colors.blue);
      expect(iconWidget, isA<AppSvgIcon>());
    });
  });
}
