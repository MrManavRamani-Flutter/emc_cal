import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../models/supplier.dart';
import 'base_dao.dart';

/// OOP DAO for Suppliers Table
class SupplierDao extends BaseDao<Supplier> {
  SupplierDao(Database db) : super(db, 'suppliers');

  @override
  Supplier fromMap(Map<String, dynamic> map) => Supplier.fromMap(map);

  @override
  Map<String, dynamic> toMap(Supplier entity) => entity.toMap();

  /// Retrieve active suppliers ordered by name
  Future<List<Supplier>> getActiveSuppliers() async {
    final results = await db.query(
      tableName,
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
    return results.map((m) => fromMap(m)).toList();
  }
}
