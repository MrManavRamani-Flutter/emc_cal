import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../models/account_model.dart';
import 'base_dao.dart';

/// OOP DAO for Accounts Table
class AccountDao extends BaseDao<AccountModel> {
  AccountDao(Database db) : super(db, 'accounts');

  @override
  AccountModel fromMap(Map<String, dynamic> map) => AccountModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(AccountModel entity) => entity.toMap();

  /// Retrieve active accounts ordered by display order then name
  Future<List<AccountModel>> getActiveAccounts() async {
    final results = await db.query(
      tableName,
      where: 'is_active = 1',
      orderBy: 'display_order ASC, name ASC',
    );
    return results.map((m) => fromMap(m)).toList();
  }
}
