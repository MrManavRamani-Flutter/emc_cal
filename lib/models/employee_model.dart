class EmployeeModel {
  final int? id;
  final String name;
  final String role; // 'Operator', 'Master', 'Karigar', 'Helper', 'Designer', 'Checker'
  final String phone;
  final String gender; // 'Male', 'Female', 'Other'
  final DateTime joiningDate;
  final double monthlySalary;
  final bool isActive;
  final String notes;

  EmployeeModel({
    this.id,
    required this.name,
    this.role = 'Operator',
    this.phone = '',
    this.gender = 'Male',
    DateTime? joiningDate,
    required this.monthlySalary,
    this.isActive = true,
    this.notes = '',
  }) : joiningDate = joiningDate ?? DateTime.now();

  EmployeeModel copyWith({
    int? id,
    String? name,
    String? role,
    String? phone,
    String? gender,
    DateTime? joiningDate,
    double? monthlySalary,
    bool? isActive,
    String? notes,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      joiningDate: joiningDate ?? this.joiningDate,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name.trim(),
      'role': role.trim(),
      'phone': phone.trim(),
      'gender': gender.trim(),
      'joining_date': joiningDate.toIso8601String().split('T').first,
      'monthly_salary': monthlySalary,
      'is_active': isActive ? 1 : 0,
      'notes': notes.trim(),
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      final dateStr = map['joining_date']?.toString();
      parsedDate = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return EmployeeModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? 'Operator',
      phone: map['phone'] as String? ?? '',
      gender: map['gender'] as String? ?? 'Male',
      joiningDate: parsedDate,
      monthlySalary: (map['monthly_salary'] as num?)?.toDouble() ?? 0.0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      notes: map['notes'] as String? ?? '',
    );
  }
}
