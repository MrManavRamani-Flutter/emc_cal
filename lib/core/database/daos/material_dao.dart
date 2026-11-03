import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../models/material_item.dart';
import 'base_dao.dart';

/// OOP DAO for Material Items Table
class MaterialDao extends BaseDao<MaterialItem> {
  MaterialDao(Database db) : super(db, 'material_items');

  @override
  MaterialItem fromMap(Map<String, dynamic> map) => MaterialItem.fromMap(map);

  @override
  Map<String, dynamic> toMap(MaterialItem entity) => entity.toMap();

  /// Retrieve materials filtered by category, date range, or supplier
  Future<List<MaterialItem>> getFilteredMaterials({
    String? category,
    String? supplierName,
    String? startDate,
    String? endDate,
  }) async {
    final conditions = <String>[];
    final args = <dynamic>[];

    if (category != null && category.isNotEmpty && category != 'All') {
      conditions.add('category = ?');
      args.add(category);
    }

    if (supplierName != null && supplierName.isNotEmpty && supplierName != 'All') {
      conditions.add('supplier_name = ?');
      args.add(supplierName);
    }

    if (startDate != null && endDate != null) {
      conditions.add('date >= ? AND date <= ?');
      args.addAll([startDate, endDate]);
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final results = await db.query(
      tableName,
      where: whereClause,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC, id DESC',
    );

    return results.map((m) => fromMap(m)).toList();
  }

  /// Total material spend summary
  Future<double> getTotalSpend({String? category}) async {
    String query = 'SELECT COALESCE(SUM(total_amount), 0.0) as total FROM $tableName';
    List<dynamic> args = [];
    if (category != null && category != 'All') {
      query += ' WHERE category = ?';
      args.add(category);
    }
    final result = await db.rawQuery(query, args);
    if (result.isEmpty) return 0.0;
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
