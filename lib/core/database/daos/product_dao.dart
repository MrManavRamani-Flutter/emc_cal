import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../models/material_product.dart';
import 'base_dao.dart';

/// OOP DAO for Material Products Master Table
class ProductDao extends BaseDao<MaterialProduct> {
  ProductDao(Database db) : super(db, 'material_products');

  @override
  MaterialProduct fromMap(Map<String, dynamic> map) => MaterialProduct.fromMap(map);

  @override
  Map<String, dynamic> toMap(MaterialProduct entity) => entity.toMap();

  /// Retrieve products by category
  Future<List<MaterialProduct>> getByCategory(String category) async {
    final results = await db.query(
      tableName,
      where: 'category = ? AND is_active = 1',
      whereArgs: [category],
      orderBy: 'product_name ASC',
    );
    return results.map((m) => fromMap(m)).toList();
  }
}
