import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/core/calculation_engine.dart';
import 'package:emb_cal/data/database_helper.dart';
import 'package:emb_cal/models/employee_model.dart';
import 'package:emb_cal/models/employee_upad_model.dart';
import 'package:emb_cal/providers/production_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Range Issues Fixes - Unit & Logic Verification', () {
    test('Issue 4: Design No allows up to 80 characters without error', () {
      final valid30 = 'D' * 30;
      final valid60 = 'SHREEJI-DUPATTA-BUTTI-D-1048-REV2-EMB-SPECIAL-SAMPLE-EDITION';
      final valid80 = 'A' * 80;
      final invalid81 = 'A' * 81;

      expect(ProductionProvider.validateDesignNo(valid30), isNull);
      expect(ProductionProvider.validateDesignNo(valid60), isNull);
      expect(ProductionProvider.validateDesignNo(valid80), isNull);
      expect(ProductionProvider.validateDesignNo(invalid81), isNotNull);
      expect(ProductionProvider.validateDesignNo(invalid81), contains('max 80 chars'));
    });

    test('Issue 8: Total Stitch validation allows 0 when allowZero is true (Breakdown mode)', () {
      // By default (allowZero: false), 0 must be rejected
      expect(ProductionProvider.validateTotalStitch('0'), isNotNull);
      expect(ProductionProvider.validateTotalStitch('0', allowZero: false), isNotNull);

      // In breakdown mode (allowZero: true), 0 is valid
      expect(ProductionProvider.validateTotalStitch('0', allowZero: true), isNull);

      // Negative numbers must always be rejected
      expect(ProductionProvider.validateTotalStitch('-100', allowZero: true), isNotNull);
      expect(ProductionProvider.validateTotalStitch('-100', allowZero: false), isNotNull);

      // Standard positive values are always valid
      expect(ProductionProvider.validateTotalStitch('250000', allowZero: false), isNull);
      expect(ProductionProvider.validateTotalStitch('250000', allowZero: true), isNull);
    });

    test('Issue 5: Rate formatting preserves 3 decimals when necessary', () {
      expect(CalculationEngine.formatRate(1.25), equals('1.25'));
      expect(CalculationEngine.formatRate(0.5), equals('0.50'));
      expect(CalculationEngine.formatRate(0.125), equals('0.125'));
      expect(CalculationEngine.formatRate(0.175), equals('0.175'));
      expect(CalculationEngine.formatRate(2.333), equals('2.333'));
    });

    test('Issue 2: Upad Settlement carries forward excess amount when Upad > Salary', () async {
      final dbHelper = DatabaseHelper.instance;

      // 1. Create a test employee with salary 15,000
      final empId = await dbHelper.insertEmployee(EmployeeModel(
        name: 'CarryForward Worker',
        role: 'Karigar',
        phone: '9876543210',
        monthlySalary: 15000.0,
      ));

      // 2. Add upads totaling 20,000 (12,000 + 8,000)
      await dbHelper.insertEmployeeUpad(EmployeeUpadModel(
        employeeId: empId,
        employeeName: 'CarryForward Worker',
        amount: 12000.0,
        date: DateTime.now(),
        notes: 'Emergency Advance 1',
      ));
      await dbHelper.insertEmployeeUpad(EmployeeUpadModel(
        employeeId: empId,
        employeeName: 'CarryForward Worker',
        amount: 8000.0,
        date: DateTime.now(),
        notes: 'Emergency Advance 2',
      ));

      // Verify unsettled upads total 20,000
      var activeUpads = await dbHelper.getEmployeeUpads(employeeId: empId, unsettledOnly: true);
      final totalBefore = activeUpads.fold<double>(0.0, (s, u) => s + u.amount);
      expect(totalBefore, 20000.0);

      // 3. Provider settlement calculates excess (20,000 - 15,000 = 5,000)
      final provider = ProductionProvider();
      await provider.init();
      await provider.settleEmployeeUpads(empId);

      // 4. Verify that the previous upads were marked settled, and exactly 5,000 excess is carried forward
      final unsettledAfter = await dbHelper.getEmployeeUpads(employeeId: empId, unsettledOnly: true);
      expect(unsettledAfter.length, 1);
      expect(unsettledAfter.first.amount, 5000.0);
      expect(unsettledAfter.first.notes, contains('Previous Month Excess Advance Carry-Forward'));

      // Clean up
      await dbHelper.deleteEmployee(empId);
    });
  });
}
