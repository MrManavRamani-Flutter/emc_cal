import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/data/database_helper.dart';
import 'package:emb_cal/models/employee_model.dart';
import 'package:emb_cal/models/employee_upad_model.dart';
import 'package:emb_cal/providers/production_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Employee & Upad Model Unit Tests', () {
    test('EmployeeModel serialization, copyWith and calculations', () {
      final now = DateTime(2026, 10, 25);
      final emp = EmployeeModel(
        id: 101,
        name: 'Ramesh Patel',
        role: 'Master',
        phone: '9876543210',
        joiningDate: now,
        monthlySalary: 28000.0,
        isActive: true,
        notes: 'Shift A Master',
      );

      final map = emp.toMap();
      expect(map['id'], 101);
      expect(map['name'], 'Ramesh Patel');
      expect(map['role'], 'Master');
      expect(map['phone'], '9876543210');
      expect(map['monthly_salary'], 28000.0);
      expect(map['is_active'], 1);
      expect(map['notes'], 'Shift A Master');

      final fromMap = EmployeeModel.fromMap(map);
      expect(fromMap.id, emp.id);
      expect(fromMap.name, emp.name);
      expect(fromMap.role, emp.role);
      expect(fromMap.monthlySalary, 28000.0);
      expect(fromMap.isActive, isTrue);

      final updated = emp.copyWith(monthlySalary: 30000.0, isActive: false);
      expect(updated.monthlySalary, 30000.0);
      expect(updated.isActive, isFalse);
      expect(updated.name, 'Ramesh Patel');
    });

    test('EmployeeUpadModel serialization and settlement status', () {
      final now = DateTime(2026, 10, 26);
      final upad = EmployeeUpadModel(
        id: 201,
        employeeId: 101,
        employeeName: 'Ramesh Patel',
        amount: 4500.0,
        date: now,
        notes: 'Diwali Advance',
        isSettled: false,
      );

      final map = upad.toMap();
      expect(map['id'], 201);
      expect(map['employee_id'], 101);
      expect(map['employee_name'], 'Ramesh Patel');
      expect(map['amount'], 4500.0);
      expect(map['notes'], 'Diwali Advance');
      expect(map['is_settled'], 0);

      final fromMap = EmployeeUpadModel.fromMap(map);
      expect(fromMap.id, upad.id);
      expect(fromMap.amount, 4500.0);
      expect(fromMap.isSettled, isFalse);

      final settled = upad.copyWith(isSettled: true);
      expect(settled.isSettled, isTrue);
    });
  });

  group('Database CRUD & Salary / Upad Calculation Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      // Clear test tables
      await db.delete('employees');
      await db.delete('employee_upads');
      await db.delete('deleted_records');
    });

    test('Insert and query employees in SQLite', () async {
      final emp1 = EmployeeModel(
        name: 'Suresh Kumar',
        role: 'Operator',
        phone: '9988776655',
        joiningDate: DateTime(2026, 1, 1),
        monthlySalary: 20000.0,
        isActive: true,
      );

      final emp2 = EmployeeModel(
        name: 'Mahesh Bhai',
        role: 'Karigar',
        phone: '9123456780',
        joiningDate: DateTime(2026, 2, 1),
        monthlySalary: 18000.0,
        isActive: true,
      );

      final id1 = await dbHelper.insertEmployee(emp1);
      final id2 = await dbHelper.insertEmployee(emp2);

      expect(id1, isPositive);
      expect(id2, isPositive);

      final list = await dbHelper.getEmployees();
      expect(list.length, 2);
      expect(list.any((e) => e.name == 'Suresh Kumar'), isTrue);
      expect(list.any((e) => e.name == 'Mahesh Bhai'), isTrue);

      // Update employee
      final updatedEmp1 = emp1.copyWith(id: id1, monthlySalary: 22000.0, role: 'Master');
      await dbHelper.updateEmployee(updatedEmp1);

      final listAfterUpdate = await dbHelper.getEmployees();
      final fetched = listAfterUpdate.firstWhere((e) => e.id == id1);
      expect(fetched.monthlySalary, 22000.0);
      expect(fetched.role, 'Master');
    });

    test('Upad recording, cumulative deduction and remaining salary balance', () async {
      final emp = EmployeeModel(
        name: 'Dinesh Solanki',
        role: 'Operator',
        monthlySalary: 25000.0,
        joiningDate: DateTime(2026, 1, 1),
      );
      final empId = await dbHelper.insertEmployee(emp);

      // Add Upad 1: ₹5,000
      final upad1 = EmployeeUpadModel(
        employeeId: empId,
        employeeName: emp.name,
        amount: 5000.0,
        date: DateTime(2026, 10, 5),
        notes: 'School fee',
      );
      await dbHelper.insertEmployeeUpad(upad1);

      // Add Upad 2: ₹3,500
      final upad2 = EmployeeUpadModel(
        employeeId: empId,
        employeeName: emp.name,
        amount: 3500.0,
        date: DateTime(2026, 10, 15),
        notes: 'Medical',
      );
      await dbHelper.insertEmployeeUpad(upad2);

      final upads = await dbHelper.getEmployeeUpads(employeeId: empId);
      expect(upads.length, 2);

      final totalUpad = upads.where((u) => !u.isSettled).fold<double>(0.0, (sum, u) => sum + u.amount);
      expect(totalUpad, 8500.0);

      final remainingSalary = emp.monthlySalary - totalUpad;
      expect(remainingSalary, 16500.0);
    });

    test('Monthly Settlement marks upads as settled and resets pending balance', () async {
      final emp = EmployeeModel(
        name: 'Ketan Patel',
        role: 'Master',
        monthlySalary: 30000.0,
        joiningDate: DateTime(2026, 1, 1),
      );
      final empId = await dbHelper.insertEmployee(emp);

      final upad = EmployeeUpadModel(
        employeeId: empId,
        employeeName: emp.name,
        amount: 10000.0,
        date: DateTime(2026, 10, 10),
      );
      await dbHelper.insertEmployeeUpad(upad);

      // Verify unsettled
      var activeUpads = await dbHelper.getEmployeeUpads(employeeId: empId, unsettledOnly: true);
      expect(activeUpads.length, 1);
      expect(activeUpads.first.amount, 10000.0);

      // Settle all upads for this employee
      await dbHelper.settleEmployeeUpads(empId);

      // Now unsettled upads should be 0
      activeUpads = await dbHelper.getEmployeeUpads(employeeId: empId, unsettledOnly: true);
      expect(activeUpads, isEmpty);

      // Total upads still in history (settled)
      final allUpads = await dbHelper.getEmployeeUpads(employeeId: empId, unsettledOnly: false);
      expect(allUpads.length, 1);
      expect(allUpads.first.isSettled, isTrue);
    });
  });

  group('Recycle Bin & 1-Click Restore for Employees & Upads', () {
    late ProductionProvider provider;

    setUp(() async {
      provider = ProductionProvider();
      await provider.init();
      await provider.emptyRecycleBin();
    });

    test('Deleting employee archives to recycle_bin and restore brings it back', () async {
      final emp = EmployeeModel(
        name: 'Ashok Bhai',
        role: 'Designer',
        monthlySalary: 35000.0,
        phone: '9898000000',
        joiningDate: DateTime(2026, 1, 1),
      );
      await provider.addEmployee(emp);

      final added = provider.employees.firstWhere((e) => e.name == 'Ashok Bhai');
      final empId = added.id!;

      // Delete employee -> archives to recycle bin
      await provider.deleteEmployee(empId);
      expect(provider.employees.any((e) => e.id == empId), isFalse);

      final deletedItems = provider.deletedRecords.where((d) => d.recordType == 'employee').toList();
      expect(deletedItems.isNotEmpty, isTrue);
      final binItem = deletedItems.first;
      expect(binItem.recordTitle, contains('Ashok Bhai'));
      expect(binItem.originalId, empId);

      // 1-Click Restore
      await provider.restoreDeletedRecord(binItem.id!);

      // Should be back in employees list
      expect(provider.employees.any((e) => e.id == empId), isTrue);
      final restored = provider.employees.firstWhere((e) => e.id == empId);
      expect(restored.name, 'Ashok Bhai');
      expect(restored.monthlySalary, 35000.0);

      // Cleanup
      await provider.deleteEmployee(empId);
      await provider.emptyRecycleBin();
    });

    test('Deleting upad archives to recycle_bin and restore brings it back', () async {
      final emp = EmployeeModel(
        name: 'Bhavin Vora',
        role: 'Helper',
        monthlySalary: 15000.0,
        joiningDate: DateTime(2026, 1, 1),
      );
      await provider.addEmployee(emp);
      final addedEmp = provider.employees.firstWhere((e) => e.name == 'Bhavin Vora');

      final upad = EmployeeUpadModel(
        employeeId: addedEmp.id!,
        employeeName: addedEmp.name,
        amount: 2500.0,
        date: DateTime(2026, 10, 20),
        notes: 'Festival Advance',
      );
      await provider.addEmployeeUpad(upad);

      final addedUpad = provider.employeeUpads.firstWhere((u) => u.employeeId == addedEmp.id!);
      final upadId = addedUpad.id!;

      // Delete upad -> archives to recycle bin
      await provider.deleteEmployeeUpad(upadId);
      expect(provider.employeeUpads.any((u) => u.id == upadId), isFalse);

      final deletedItems = provider.deletedRecords.where((d) => d.recordType == 'employee_upad').toList();
      expect(deletedItems.isNotEmpty, isTrue);
      final binItem = deletedItems.first;
      expect(binItem.recordTitle, contains('2500'));
      expect(binItem.originalId, upadId);

      // 1-Click Restore
      await provider.restoreDeletedRecord(binItem.id!);

      // Upad should be restored back
      expect(provider.employeeUpads.any((u) => u.id == upadId), isTrue);
      final restoredUpad = provider.employeeUpads.firstWhere((u) => u.id == upadId);
      expect(restoredUpad.amount, 2500.0);
      expect(restoredUpad.notes, 'Festival Advance');

      // Cleanup
      await provider.deleteEmployee(addedEmp.id!);
      await provider.emptyRecycleBin();
    });
  });

  group('Backup & Restore with Employees and Upads', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      await db.delete('employees');
      await db.delete('employee_upads');
    });

    test('Export backup includes employees & upads, and restore recovers them', () async {
      final emp = EmployeeModel(
        name: 'Sunil Rathod',
        role: 'Operator',
        monthlySalary: 21000.0,
        joiningDate: DateTime(2026, 3, 1),
      );
      final empId = await dbHelper.insertEmployee(emp);

      final upad = EmployeeUpadModel(
        employeeId: empId,
        employeeName: emp.name,
        amount: 3000.0,
        date: DateTime(2026, 10, 12),
        notes: 'Advance 1',
      );
      await dbHelper.insertEmployeeUpad(upad);

      // Export Backup
      final jsonString = await dbHelper.exportBackupJson();
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(decoded.containsKey('employees'), isTrue);
      expect(decoded.containsKey('employee_upads'), isTrue);

      final employeesJson = decoded['employees'] as List;
      final upadsJson = decoded['employee_upads'] as List;

      expect(employeesJson.length, 1);
      expect(employeesJson.first['name'], 'Sunil Rathod');
      expect(upadsJson.length, 1);
      expect(upadsJson.first['amount'], 3000.0);

      // Clear tables to simulate fresh device
      final db = await dbHelper.database;
      await db.delete('employees');
      await db.delete('employee_upads');

      expect(await dbHelper.getEmployees(), isEmpty);
      expect(await dbHelper.getEmployeeUpads(), isEmpty);

      // Restore from JSON
      await dbHelper.restoreFromJson(jsonString);

      // Verify restored data
      final restoredEmployees = await dbHelper.getEmployees();
      expect(restoredEmployees.length, 1);
      expect(restoredEmployees.first.name, 'Sunil Rathod');
      expect(restoredEmployees.first.monthlySalary, 21000.0);

      final restoredUpads = await dbHelper.getEmployeeUpads();
      expect(restoredUpads.length, 1);
      expect(restoredUpads.first.amount, 3000.0);
    });
  });

  group('ProductionProvider Employee State & Filter Tests', () {
    test('Provider filters by role, search text, and active status', () async {
      final provider = ProductionProvider();
      await provider.init();

      // Add test employees
      final emp1 = EmployeeModel(
        name: 'Hitesh Prajapati',
        role: 'Master',
        phone: '9870011223',
        monthlySalary: 28000.0,
        joiningDate: DateTime(2026, 1, 1),
        isActive: true,
      );
      final emp2 = EmployeeModel(
        name: 'Paresh Parmar',
        role: 'Operator',
        phone: '9870044556',
        monthlySalary: 20000.0,
        joiningDate: DateTime(2026, 2, 1),
        isActive: false, // inactive
      );
      final emp3 = EmployeeModel(
        name: 'Haresh Dabhi',
        role: 'Master',
        phone: '9870077889',
        monthlySalary: 26000.0,
        joiningDate: DateTime(2026, 3, 1),
        isActive: true,
      );

      await provider.addEmployee(emp1);
      await provider.addEmployee(emp2);
      await provider.addEmployee(emp3);

      final added1 = provider.employees.firstWhere((e) => e.name == 'Hitesh Prajapati');
      final added2 = provider.employees.firstWhere((e) => e.name == 'Paresh Parmar');
      final added3 = provider.employees.firstWhere((e) => e.name == 'Haresh Dabhi');

      // Reset filters
      provider.setEmployeeSearchQuery('');
      provider.setEmployeeRoleFilter('All Roles');
      provider.setEmployeeActiveOnlyFilter(false);

      expect(provider.filteredEmployees.length, greaterThanOrEqualTo(3));

      // Test Search Query
      provider.setEmployeeSearchQuery('Hitesh');
      expect(provider.filteredEmployees.length, 1);
      expect(provider.filteredEmployees.first.name, 'Hitesh Prajapati');

      // Test Role Filter
      provider.setEmployeeSearchQuery('');
      provider.setEmployeeRoleFilter('Master');
      final masterEmployees = provider.filteredEmployees.where((e) => e.role == 'Master').toList();
      expect(masterEmployees.length, 2);

      // Test Active Only Filter
      provider.setEmployeeRoleFilter('All Roles');
      provider.setEmployeeActiveOnlyFilter(true);
      expect(provider.filteredEmployees.any((e) => e.name == 'Paresh Parmar'), isFalse);

      // Test Upad & Net Remaining Salary
      final upad = EmployeeUpadModel(
        employeeId: added1.id!,
        employeeName: added1.name,
        amount: 6000.0,
        date: DateTime.now(),
      );
      await provider.addEmployeeUpad(upad);

      final totalUpad = provider.getEmployeeTotalUpad(added1.id!);
      expect(totalUpad, 6000.0);

      final remainingSalary = provider.getEmployeeRemainingSalary(added1);
      expect(remainingSalary, 22000.0); // 28000 - 6000

      // Cleanup
      await provider.deleteEmployee(added1.id!);
      await provider.deleteEmployee(added2.id!);
      await provider.deleteEmployee(added3.id!);
    });

    test('Dynamic Role Management: add, update, and cascade to employees', () async {
      final provider = ProductionProvider();
      await provider.init();

      // Ensure default roles exist
      expect(provider.employeeRoles, containsAll(['Operator', 'Master', 'Karigar', 'Helper', 'Designer', 'Checker', 'Manager', 'Other']));

      // 1. Add new role
      await provider.addEmployeeRole('Supervisor');
      expect(provider.employeeRoles, contains('Supervisor'));

      // 2. Add employee with new role
      final emp = EmployeeModel(
        name: 'Vipul Shah',
        role: 'Supervisor',
        monthlySalary: 32000.0,
        joiningDate: DateTime(2026, 1, 1),
      );
      await provider.addEmployee(emp);
      final addedEmp = provider.employees.firstWhere((e) => e.name == 'Vipul Shah');
      expect(addedEmp.role, 'Supervisor');

      // 3. Update role name -> should cascade to employee
      await provider.updateEmployeeRole('Supervisor', 'Senior Supervisor');
      expect(provider.employeeRoles, contains('Senior Supervisor'));
      expect(provider.employeeRoles, isNot(contains('Supervisor')));

      final reloadedEmp = provider.employees.firstWhere((e) => e.name == 'Vipul Shah');
      expect(reloadedEmp.role, 'Senior Supervisor');

      // 4. Delete role
      await provider.deleteEmployeeRole('Senior Supervisor');
      expect(provider.employeeRoles, isNot(contains('Senior Supervisor')));

      // 5. Reset to defaults
      await provider.resetEmployeeRolesToDefault();
      expect(provider.employeeRoles, containsAll(['Operator', 'Master', 'Karigar', 'Helper', 'Designer', 'Checker', 'Manager', 'Other']));

      // Cleanup
      await provider.deleteEmployee(addedEmp.id!);
    });

    test('All-Time Upad History & Multi-Employee Aggregations', () async {
      final provider = ProductionProvider();
      await provider.init();
      final db = await DatabaseHelper.instance.database;
      await db.delete('employee_upads');
      await provider.loadEmployeeUpads();

      final empA = EmployeeModel(
        name: 'Emp A',
        role: 'Operator',
        monthlySalary: 20000.0,
        joiningDate: DateTime(2026, 1, 1),
      );
      final empB = EmployeeModel(
        name: 'Emp B',
        role: 'Master',
        monthlySalary: 30000.0,
        joiningDate: DateTime(2026, 1, 1),
      );

      await provider.addEmployee(empA);
      await provider.addEmployee(empB);

      final idA = provider.employees.firstWhere((e) => e.name == 'Emp A').id!;
      final idB = provider.employees.firstWhere((e) => e.name == 'Emp B').id!;

      // Record Upads for Emp A: 3000 and 2000
      await provider.addEmployeeUpad(EmployeeUpadModel(
        employeeId: idA,
        employeeName: 'Emp A',
        amount: 3000.0,
        date: DateTime(2026, 9, 1),
        notes: 'Month 1 Upad',
      ));
      await provider.addEmployeeUpad(EmployeeUpadModel(
        employeeId: idA,
        employeeName: 'Emp A',
        amount: 2000.0,
        date: DateTime(2026, 10, 1),
        notes: 'Month 2 Upad',
      ));

      // Record Upad for Emp B: 8000
      await provider.addEmployeeUpad(EmployeeUpadModel(
        employeeId: idB,
        employeeName: 'Emp B',
        amount: 8000.0,
        date: DateTime(2026, 10, 5),
        notes: 'Festival Upad',
      ));

      // Before settlement: Emp A has 5000 all-time, 5000 pending, 0 settled
      expect(provider.getEmployeeAllTimeTotalUpad(idA), 5000.0);
      expect(provider.getEmployeeTotalUpad(idA, unsettledOnly: true), 5000.0);
      expect(provider.getEmployeeSettledUpad(idA), 0.0);

      // Total factory upads: 5000 + 8000 = 13000
      expect(provider.totalPendingUpad, 13000.0);
      expect(provider.totalAllTimeFactoryUpad, 13000.0);

      // Now settle Emp A
      await provider.settleEmployeeUpads(idA);

      // After settlement:
      // Emp A: all-time is STILL 5000 (history preserved!), pending is 0, settled is 5000!
      expect(provider.getEmployeeAllTimeTotalUpad(idA), 5000.0);
      expect(provider.getEmployeeTotalUpad(idA, unsettledOnly: true), 0.0);
      expect(provider.getEmployeeSettledUpad(idA), 5000.0);

      // Emp A remaining salary is now full 20,000 for the new month!
      final reloadedEmpA = provider.employees.firstWhere((e) => e.id == idA);
      expect(provider.getEmployeeRemainingSalary(reloadedEmpA), 20000.0);

      // Factory pending upad is now only Emp B's 8000
      expect(provider.totalPendingUpad, 8000.0);
      // But factory all-time upad still includes all 13000!
      expect(provider.totalAllTimeFactoryUpad, 13000.0);

      // Cleanup
      await provider.deleteEmployee(idA);
      await provider.deleteEmployee(idB);
    });
  });
}
