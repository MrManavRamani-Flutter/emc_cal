import 'package:intl/intl.dart';

/// Represents a payment received from a customer (cash in hand / bank)
class CustomerPaymentModel {
  final int? id;
  final int? billId;
  final int? customerId;
  final String customerName;
  final double amount;
  final DateTime date;
  final String paymentMode; // 'Cash', 'Bank / UPI', 'Cheque'
  final String notes;
  final DateTime createdAt;

  CustomerPaymentModel({
    this.id,
    this.billId,
    this.customerId,
    required this.customerName,
    required this.amount,
    required this.date,
    this.paymentMode = 'Cash',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get formattedDate => DateFormat('dd-MM-yyyy').format(date);
  String get isoDate => DateFormat('yyyy-MM-dd').format(date);

  CustomerPaymentModel copyWith({
    int? id,
    int? billId,
    int? customerId,
    String? customerName,
    double? amount,
    DateTime? date,
    String? paymentMode,
    String? notes,
    DateTime? createdAt,
  }) {
    return CustomerPaymentModel(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'bill_id': billId,
      'customer_id': customerId,
      'customer_name': customerName.trim(),
      'amount': amount,
      'date': isoDate,
      'payment_mode': paymentMode.trim(),
      'notes': notes.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomerPaymentModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      final dStr = map['date'] as String? ?? '';
      parsedDate = DateTime.parse(dStr);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    DateTime parsedCreated;
    try {
      final cStr = map['created_at'] as String? ?? '';
      parsedCreated = DateTime.parse(cStr);
    } catch (_) {
      parsedCreated = DateTime.now();
    }

    return CustomerPaymentModel(
      id: map['id'] as int?,
      billId: map['bill_id'] as int?,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: parsedDate,
      paymentMode: map['payment_mode'] as String? ?? 'Cash',
      notes: map['notes'] as String? ?? '',
      createdAt: parsedCreated,
    );
  }
}

