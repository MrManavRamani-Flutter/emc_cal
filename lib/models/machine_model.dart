class MachineModel {
  final int? id;
  final String machineNo;
  final String name;
  final int headCapacity;
  final bool isActive;
  final String notes;

  MachineModel({
    this.id,
    required this.machineNo,
    required this.name,
    required this.headCapacity,
    this.isActive = true,
    this.notes = '',
  });

  MachineModel copyWith({
    int? id,
    String? machineNo,
    String? name,
    int? headCapacity,
    bool? isActive,
    String? notes,
  }) {
    return MachineModel(
      id: id ?? this.id,
      machineNo: machineNo ?? this.machineNo,
      name: name ?? this.name,
      headCapacity: headCapacity ?? this.headCapacity,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'machine_no': machineNo,
      'name': name,
      'head_capacity': headCapacity,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
    };
  }

  factory MachineModel.fromMap(Map<String, dynamic> map) {
    return MachineModel(
      id: map['id'] as int?,
      machineNo: map['machine_no'] as String? ?? '',
      name: map['name'] as String? ?? '',
      headCapacity: (map['head_capacity'] as num?)?.toInt() ?? 12,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      notes: map['notes'] as String? ?? '',
    );
  }
}
