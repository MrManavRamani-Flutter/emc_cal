import 'package:intl/intl.dart';

/// Represents a customer/party for whom embroidery job work or orders are manufactured
class CustomerModel {
  final int? id;
  final String name;
  final String phone;
  final String city;
  final String gstNo;
  final String notes;
  final bool isActive;
  final DateTime createdAt;

  CustomerModel({
    this.id,
    required this.name,
    this.phone = '',
    String city = '',
    String address = '',
    String gstNo = '',
    String gstin = '',
    this.notes = '',
    this.isActive = true,
    DateTime? createdAt,
  })  : city = address.isNotEmpty ? address : city,
        gstNo = gstin.isNotEmpty ? gstin : gstNo,
        createdAt = createdAt ?? DateTime.now();

  String get address => city;
  String get gstin => gstNo;

  String get formattedDate => DateFormat('dd-MM-yyyy').format(createdAt);

  CustomerModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? city,
    String? gstNo,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CustomerModel(
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
      'name': name.trim(),
      'phone': phone.trim(),
      'city': city.trim(),
      'gst_no': gstNo.trim(),
      'notes': notes.trim(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedCreated;
    try {
      final cStr = map['created_at'] as String? ?? '';
      parsedCreated = DateTime.parse(cStr);
    } catch (_) {
      parsedCreated = DateTime.now();
    }

    return CustomerModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      city: map['city'] as String? ?? '',
      gstNo: map['gst_no'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: parsedCreated,
    );
  }
}
