class AccountModel {
  final int? id;
  final String name;
  final String area;
  final int displayOrder;
  final String colorHex;
  final bool isActive;
  final String notes;

  AccountModel({
    this.id,
    required this.name,
    this.area = '',
    this.displayOrder = 0,
    this.colorHex = '#2563EB',
    this.isActive = true,
    this.notes = '',
  });

  AccountModel copyWith({
    int? id,
    String? name,
    String? area,
    int? displayOrder,
    String? colorHex,
    bool? isActive,
    String? notes,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      displayOrder: displayOrder ?? this.displayOrder,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'display_order': displayOrder,
      'color_hex': colorHex,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      area: map['area'] as String? ?? '',
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      colorHex: map['color_hex'] as String? ?? '#2563EB',
      isActive: (map['is_active'] as int?) != 0,
      notes: map['notes'] as String? ?? '',
    );
  }
}
