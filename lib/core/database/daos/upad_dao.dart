import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../models/employee_upad_model.dart';
import 'base_dao.dart';

/// OOP DAO for Employee Upad (Advance) Table
class UpadDao extends BaseDao<EmployeeUpadModel> {
  UpadDao(Database db) : super(db, 'employee_upad');

  @override
  EmployeeUpadModel fromMap(Map<String, dynamic> map) => EmployeeUpadModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(EmployeeUpadModel entity) => entity.toMap();

  /// Retrieve all upads for a specific employee
  Future<List<EmployeeUpadModel>> getUpadsForEmployee(int employeeId) async {
    final results = await db.query(
      tableName,
      where: 'employee_id = ?',
      whereArgs: [employeeId],
      orderBy: 'date DESC, id DESC',
    );
    return results.map((m) => fromMap(m)).toList();
  }

  /// Total sum of upad taken by an employee
  Future<double> getTotalUpadForEmployee(int employeeId) async {
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM $tableName WHERE employee_id = ?',
      [employeeId],
    );
    if (result.isEmpty) return 0.0;
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
