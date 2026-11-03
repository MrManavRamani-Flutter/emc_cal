import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../models/employee_model.dart';
import 'base_dao.dart';

/// OOP DAO for Employees Table
class EmployeeDao extends BaseDao<EmployeeModel> {
  EmployeeDao(Database db) : super(db, 'employees');

  @override
  EmployeeModel fromMap(Map<String, dynamic> map) => EmployeeModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(EmployeeModel entity) => entity.toMap();

  /// Retrieve active employees ordered by name
  Future<List<EmployeeModel>> getActiveEmployees() async {
    final results = await db.query(
      tableName,
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
    return results.map((m) => fromMap(m)).toList();
  }

  /// Get distinct roles list
  Future<List<String>> getDistinctRoles() async {
    final results = await db.rawQuery(
      'SELECT DISTINCT role FROM $tableName WHERE role IS NOT NULL AND role != "" ORDER BY role ASC',
    );
    return results.map((r) => r['role'] as String).toList();
  }
}
