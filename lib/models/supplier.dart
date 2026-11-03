/// Represents a material supplier / vendor in the system.
class Supplier {
  final int? id;
  final String name; // e.g. 'Radha Raman', 'SN TEX', 'Khushi Fashion'
  final String phone;
  final String city;
  final String gstNo;
  final String notes;
  final bool isActive;
  final DateTime createdAt;

  Supplier({
    this.id,
    required this.name,
    this.phone = '',
    this.city = 'Surat',
    this.gstNo = '',
    this.notes = '',
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Supplier copyWith({
    int? id,
    String? name,
    String? phone,
    String? city,
    String? gstNo,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      gstNo: gstNo ?? this.gstNo,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'city': city,
      'gst_no': gstNo,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      city: map['city'] as String? ?? '',
      gstNo: map['gst_no'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
