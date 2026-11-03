import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../models/machine_model.dart';
import 'base_dao.dart';

/// OOP DAO for Machines Table
class MachineDao extends BaseDao<MachineModel> {
  MachineDao(Database db) : super(db, 'machines');

  @override
  MachineModel fromMap(Map<String, dynamic> map) => MachineModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(MachineModel entity) => entity.toMap();

  /// Retrieve active machines ordered by machine number
  Future<List<MachineModel>> getActiveMachines() async {
    final results = await db.query(
      tableName,
      where: 'is_active = 1',
      orderBy: 'machine_no ASC',
    );
    return results.map((m) => fromMap(m)).toList();
  }
}
