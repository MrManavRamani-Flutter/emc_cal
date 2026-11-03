class EmployeeUpadModel {
  final int? id;
  final int employeeId;
  final String employeeName;
  final double amount;
  final DateTime date;
  final String notes;
  final bool isSettled;

  EmployeeUpadModel({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    DateTime? date,
    this.notes = '',
    this.isSettled = false,
  }) : date = date ?? DateTime.now();

  EmployeeUpadModel copyWith({
    int? id,
    int? employeeId,
    String? employeeName,
    double? amount,
    DateTime? date,
    String? notes,
    bool? isSettled,
  }) {
    return EmployeeUpadModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isSettled: isSettled ?? this.isSettled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName.trim(),
      'amount': amount,
      'date': date.toIso8601String().split('T').first,
      'notes': notes.trim(),
      'is_settled': isSettled ? 1 : 0,
    };
  }

  factory EmployeeUpadModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      final dateStr = map['date']?.toString();
      parsedDate = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return EmployeeUpadModel(
      id: map['id'] as int?,
      employeeId: (map['employee_id'] as num?)?.toInt() ?? 0,
      employeeName: map['employee_name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: parsedDate,
      notes: map['notes'] as String? ?? '',
      isSettled: (map['is_settled'] as int? ?? 0) == 1,
    );
  }
}
