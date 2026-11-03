import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../models/deleted_record_item.dart';
import 'base_dao.dart';

/// OOP DAO for Recycle Bin Table
class RecycleBinDao extends BaseDao<DeletedRecordItem> {
  RecycleBinDao(Database db) : super(db, 'deleted_records');

  @override
  DeletedRecordItem fromMap(Map<String, dynamic> map) => DeletedRecordItem.fromMap(map);

  @override
  Map<String, dynamic> toMap(DeletedRecordItem entity) => entity.toMap();

  /// Retrieve all deleted items ordered by deletion time
  Future<List<DeletedRecordItem>> getDeletedItems({String? recordType}) async {
    String? whereClause;
    List<dynamic>? whereArgs;

    if (recordType != null && recordType.isNotEmpty && recordType != 'All') {
      whereClause = 'record_type = ?';
      whereArgs = [recordType];
    }

    final results = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'deleted_at DESC, id DESC',
    );
    return results.map((m) => fromMap(m)).toList();
  }

  /// Permanently delete item
  Future<int> permanentlyDelete(int id) async {
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Empty all items in recycle bin
  Future<int> emptyRecycleBin() async {
    return await db.delete(tableName);
  }
}
