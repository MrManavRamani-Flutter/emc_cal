import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../models/production_record.dart';
import 'base_dao.dart';

/// OOP DAO for Production Records Table
class ProductionDao extends BaseDao<ProductionRecord> {
  ProductionDao(Database db) : super(db, 'production_records');

  @override
  ProductionRecord fromMap(Map<String, dynamic> map) => ProductionRecord.fromMap(map);

  @override
  Map<String, dynamic> toMap(ProductionRecord entity) => entity.toMap();

  /// Retrieve records filtered by date range, machine, shift, or account
  Future<List<ProductionRecord>> getFilteredRecords({
    String? startDate,
    String? endDate,
    String? machineNo,
    String? accountName,
    String? shift,
  }) async {
    final conditions = <String>[];
    final args = <dynamic>[];

    if (startDate != null && endDate != null) {
      conditions.add('date >= ? AND date <= ?');
      args.addAll([startDate, endDate]);
    } else if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate);
    }

    if (machineNo != null && machineNo.isNotEmpty && machineNo != 'All') {
      conditions.add('machine_no = ?');
      args.add(machineNo);
    }

    if (accountName != null && accountName.isNotEmpty && accountName != 'All') {
      conditions.add('account_name = ?');
      args.add(accountName);
    }

    if (shift != null && shift.isNotEmpty && shift != 'All') {
      conditions.add('shift = ?');
      args.add(shift);
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

  /// Fast aggregation queries (zero UI thread load)
  Future<Map<String, num>> getAggregates({String? accountName, String? date}) async {
    final conditions = <String>[];
    final args = <dynamic>[];

    if (accountName != null && accountName != 'All') {
      conditions.add('account_name = ?');
      args.add(accountName);
    }
    if (date != null) {
      conditions.add('date = ?');
      args.add(date);
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final query = '''
      SELECT 
        COUNT(*) as total_records,
        COALESCE(SUM(total_stitch), 0) as total_stitches,
        COALESCE(SUM(final_amount), 0) as total_amount
      FROM $tableName $whereClause
    ''';

    final result = await db.rawQuery(query, args);
    if (result.isEmpty) {
      return {'total_records': 0, 'total_stitches': 0, 'total_amount': 0};
    }
    final row = result.first;
    return {
      'total_records': (row['total_records'] as num?) ?? 0,
      'total_stitches': (row['total_stitches'] as num?) ?? 0,
      'total_amount': (row['total_amount'] as num?) ?? 0,
    };
  }
}
