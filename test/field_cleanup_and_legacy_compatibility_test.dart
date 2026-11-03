import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/data/database_helper.dart';
import 'package:emb_cal/models/material_item.dart';
import 'package:emb_cal/models/supplier.dart';
import 'package:emb_cal/models/employee_model.dart';
import 'package:emb_cal/models/production_record.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Field Cleanup & Legacy Compatibility Tests', () {
    test('MaterialItem, Supplier, Employee can be instantiated with minimal essential fields', () {
      final item = MaterialItem(
        challanNo: 'CH-101',
        supplierName: 'Om Test Supplier',
        date: DateTime.now(),
        category: 'Sequence',
        productName: 'GOLD 5MM',
        itemType: 'piece',
        qty: 10,
        rate: 50,
        amount: 500,
      );
      expect(item.notes, isEmpty);
      expect(item.amount, 500.0);

      final supplier = Supplier(
        name: 'Om Supplier',
        phone: '9999999999',
      );
      expect(supplier.gstNo, isEmpty);
      expect(supplier.notes, isEmpty);

      final emp = EmployeeModel(
        name: 'Ramesh Patel',
        role: 'Operator',
        gender: 'Male',
        phone: '9898989898',
        joiningDate: DateTime(2025, 1, 1),
        monthlySalary: 15000,
      );
      expect(emp.notes, isEmpty);

      final rec = ProductionRecord(
        date: DateTime(2026, 11, 2),
        designNo: 'D-501',
        machineNo: 'M-01',
        totalStitch: 100000,
        finalStitch: 100.0,
        heads: 12,
        rate: 1.25,
        amount: 125.0,
        finalAmount: 1500.0,
        accountName: '250 Area',
        shift: 'Day',
      );
      expect(rec.notes, isEmpty);
      expect(rec.finalAmount, 1500.0);
    });

    test('Old backup JSON with legacy/extra fields (GST, address, notes, random keys) restores cleanly', () async {
      final dbHelper = DatabaseHelper.instance;

      final legacyBackup = {
        'version': '0.9.0',
        'exported_at': '2024-01-01T00:00:00.000',
        'suppliers': [
          {
            'name': 'Old Surat Supplier',
            'phone': '9876543210',
            'address': 'Ring Road, Surat',
            'gst_no': '24AAAAA0000A1Z5',
            'notes': 'Old supplier notes',
            'random_extra_field': 'ignore_me_gracefully',
          }
        ],
        'material_items': [
          {
            'challan_no': 'OLD-CH-99',
            'supplier_name': 'Old Surat Supplier',
            'date': '2024-01-05',
            'category': 'Dhaga',
            'product_name': 'WHITE THREAD',
            'item_type': 'cone',
            'qty': 20,
            'rate': 85,
            'amount': 1700,
            'notes': 'Old material notes',
            'unknown_legacy_col': 'skip',
          }
        ],
        'production_records': [
          {
            'date': '2024-01-05',
            'design_no': 'LEGACY-01',
            'machine_no': 'M-02',
            'total_stitch': 50000,
            'heads': 12,
            'rate': 1.25,
            'account_name': '250 Area',
            'shift': 'Day',
            'notes': 'Old production note',
            'old_unused_tax': 18,
          }
        ],
        'employees': [
          {
            'name': 'Kanti Bhai',
            'role': 'Master',
            'gender': 'Male',
            'phone': '9123456780',
            'joining_date': '2023-05-01',
            'monthly_salary': 25000,
            'address': 'Katargam, Surat',
            'notes': 'Experienced master',
          }
        ],
      };

      final jsonStr = jsonEncode(legacyBackup);

      // Restore should succeed without any format or column exceptions
      await dbHelper.restoreFromJson(jsonStr);

      final suppliers = await dbHelper.getSuppliers();
      expect(suppliers.any((s) => s.name == 'Old Surat Supplier'), isTrue);

      final materials = await dbHelper.getMaterialItems();
      expect(materials.any((m) => m.challanNo == 'OLD-CH-99'), isTrue);

      final records = await dbHelper.getRecords();
      expect(records.any((r) => r.designNo == 'LEGACY-01'), isTrue);

      final employees = await dbHelper.getEmployees();
      expect(employees.any((e) => e.name == 'Kanti Bhai'), isTrue);
    });
  });
}
