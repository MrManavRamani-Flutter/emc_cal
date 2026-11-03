class WhatsAppLogModel {
  final int? id;
  final int? employeeId;
  final String employeeName;
  final String recipientPhone;
  final String senderPhone;
  final String message;
  final String messageType; // 'upad_receipt', 'statement', 'custom'
  final double amount;
  final DateTime createdAt;
  final String status;

  WhatsAppLogModel({
    this.id,
    this.employeeId,
    required this.employeeName,
    required this.recipientPhone,
    required this.senderPhone,
    required this.message,
    this.messageType = 'upad_receipt',
    this.amount = 0.0,
    DateTime? createdAt,
    this.status = 'Sent',
  }) : createdAt = createdAt ?? DateTime.now();

  WhatsAppLogModel copyWith({
    int? id,
    int? employeeId,
    String? employeeName,
    String? recipientPhone,
    String? senderPhone,
    String? message,
    String? messageType,
    double? amount,
    DateTime? createdAt,
    String? status,
  }) {
    return WhatsAppLogModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      senderPhone: senderPhone ?? this.senderPhone,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName.trim(),
      'recipient_phone': recipientPhone.trim(),
      'sender_phone': senderPhone.trim(),
      'message': message.trim(),
      'message_type': messageType.trim(),
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'status': status.trim(),
    };
  }

  factory WhatsAppLogModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      final dateStr = map['created_at']?.toString();
      parsedDate = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return WhatsAppLogModel(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? ''),
      employeeId: map['employee_id'] is int
          ? map['employee_id'] as int
          : int.tryParse(map['employee_id']?.toString() ?? ''),
      employeeName: (map['employee_name'] ?? '').toString(),
      recipientPhone: (map['recipient_phone'] ?? '').toString(),
      senderPhone: (map['sender_phone'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      messageType: (map['message_type'] ?? 'upad_receipt').toString(),
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      createdAt: parsedDate,
      status: (map['status'] ?? 'Sent').toString(),
    );
  }
}
