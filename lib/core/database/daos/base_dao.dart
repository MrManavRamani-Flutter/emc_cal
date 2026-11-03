import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Generic OOP Data Access Object (DAO) Interface for SQLite Entities
abstract class BaseDao<T> {
  final Database db;
  final String tableName;

  BaseDao(this.db, this.tableName);

  /// Convert SQLite Map to typed domain Entity
  T fromMap(Map<String, dynamic> map);

  /// Convert typed domain Entity to SQLite Map
  Map<String, dynamic> toMap(T entity);

  /// Insert a single entity
  Future<int> insert(T entity) async {
    return await db.insert(
      tableName,
      toMap(entity),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Bulk insert entities within a transaction
  Future<void> insertAll(List<T> entities) async {
    final batch = db.batch();
    for (final entity in entities) {
      batch.insert(
        tableName,
        toMap(entity),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Update an existing entity by primary key id
  Future<int> update(T entity, int id) async {
    return await db.update(
      tableName,
      toMap(entity),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete an entity by primary key id
  Future<int> delete(int id) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Retrieve an entity by primary key id
  Future<T?> getById(int id) async {
    final results = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  /// Retrieve all entities ordered optionally
  Future<List<T>> getAll({String? orderBy}) async {
    final results = await db.query(
      tableName,
      orderBy: orderBy,
    );
    return results.map((map) => fromMap(map)).toList();
  }

  /// Total count of records in table
  Future<int> count() async {
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM $tableName');
    if (result.isEmpty) return 0;
    return (result.first['cnt'] as num?)?.toInt() ?? 0;
  }
}
