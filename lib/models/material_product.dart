/// Represents a master material product with a predefined category, unit, and default rate.
class MaterialProduct {
  final int? id;
  final String name; // e.g. 'Open Cut', 'Navrang', 'Regular', 'Sonavale 1500'
  final String category; // 'Sequence', 'Beads', 'Dhaga'
  final double defaultRate; // e.g. 18.0, 85.0, 600.0
  final String unit; // 'piece', 'cd', 'firka', 'cone', 'packet', 'box', 'kg'
  final double defaultMtr;
  final double defaultMm;
  final String notes;
  final bool isActive;

  MaterialProduct({
    this.id,
    required this.name,
    required this.category,
    required this.defaultRate,
    this.unit = 'piece',
    this.defaultMtr = 0.0,
    this.defaultMm = 0.0,
    this.notes = '',
    this.isActive = true,
  });

  MaterialProduct copyWith({
    int? id,
    String? name,
    String? category,
    double? defaultRate,
    String? unit,
    double? defaultMtr,
    double? defaultMm,
    String? notes,
    bool? isActive,
  }) {
    return MaterialProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      defaultRate: defaultRate ?? this.defaultRate,
      unit: unit ?? this.unit,
      defaultMtr: defaultMtr ?? this.defaultMtr,
      defaultMm: defaultMm ?? this.defaultMm,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'default_rate': defaultRate,
      'unit': unit,
      'default_mtr': defaultMtr,
      'default_mm': defaultMm,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory MaterialProduct.fromMap(Map<String, dynamic> map) {
    return MaterialProduct(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Sequence',
      defaultRate: (map['default_rate'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'piece',
      defaultMtr: (map['default_mtr'] as num?)?.toDouble() ?? 0.0,
      defaultMm: (map['default_mm'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String? ?? '',
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}
