import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../models/settings_model.dart';
import 'base_dao.dart';

/// OOP DAO for Settings Table
class SettingsDao extends BaseDao<SettingsModel> {
  SettingsDao(Database db) : super(db, 'settings');

  @override
  SettingsModel fromMap(Map<String, dynamic> map) => SettingsModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(SettingsModel entity) => entity.toMap();

  /// Retrieve the single settings row
  Future<SettingsModel> getSettings() async {
    final results = await db.query(tableName, where: 'id = 1', limit: 1);
    if (results.isEmpty) {
      return SettingsModel();
    }
    return fromMap(results.first);
  }

  /// Save or update settings
  Future<void> saveSettings(SettingsModel settings) async {
    final map = toMap(settings);
    map['id'] = 1;
    await db.insert(tableName, map, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
