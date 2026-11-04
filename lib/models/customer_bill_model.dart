import 'package:intl/intl.dart';

/// Represents a production job-work sales bill/invoice issued to a customer
class CustomerBillModel {
  final int? id;
  final String billNo;
  final int? customerId;
  final String customerName;
  final DateTime date;
  final double totalAmount;
  final double paidAmount;
  final String paymentStatus; // 'Unpaid', 'Partial', 'Paid'
  final DateTime? paymentDate;
  final String designDetails;
  final String notes;
  final DateTime createdAt;

  CustomerBillModel({
    this.id,
    required this.billNo,
    this.customerId,
    required this.customerName,
    required this.date,
    required this.totalAmount,
    double paidAmount = 0.0,
    String? paymentStatus,
    this.paymentDate,
    this.designDetails = '',
    this.notes = '',
    DateTime? createdAt,
  })  : paidAmount = paidAmount.clamp(0.0, double.infinity),
        paymentStatus = paymentStatus ??
            (paidAmount >= totalAmount && totalAmount > 0
                ? 'Paid'
                : (paidAmount > 0 ? 'Partial' : 'Unpaid')),
        createdAt = createdAt ?? DateTime.now();

  double get remainingAmount => (totalAmount - paidAmount).clamp(0.0, double.infinity);
  bool get isPaid => paidAmount >= totalAmount && totalAmount > 0;
  bool get isPartial => paidAmount > 0 && paidAmount < totalAmount;
  bool get isPartiallyPaid => isPartial;
  bool get isUnpaid => paidAmount <= 0;

  String get formattedDate => DateFormat('dd-MM-yyyy').format(date);
  String get isoDate => DateFormat('yyyy-MM-dd').format(date);
  String? get formattedPaymentDate => paymentDate != null ? DateFormat('dd-MM-yyyy').format(paymentDate!) : null;

  CustomerBillModel copyWith({
    int? id,
    String? billNo,
    int? customerId,
    String? customerName,
    DateTime? date,
    double? totalAmount,
    double? paidAmount,
    String? paymentStatus,
    DateTime? paymentDate,
    String? designDetails,
    String? notes,
    DateTime? createdAt,
  }) {
    return CustomerBillModel(
      id: id ?? this.id,
      billNo: billNo ?? this.billNo,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: paymentDate ?? this.paymentDate,
      designDetails: designDetails ?? this.designDetails,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'bill_no': billNo.trim(),
      'customer_id': customerId,
      'customer_name': customerName.trim(),
      'date': isoDate,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'payment_status': isPaid ? 'Paid' : (isPartial ? 'Partial' : 'Unpaid'),
      'payment_date': paymentDate?.toIso8601String(),
      'design_details': designDetails.trim(),
      'notes': notes.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomerBillModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      final dStr = map['date'] as String? ?? '';
      parsedDate = DateTime.parse(dStr);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    DateTime? parsedPaymentDate;
    try {
      final pDateStr = map['payment_date'] as String?;
      if (pDateStr != null && pDateStr.isNotEmpty) {
        parsedPaymentDate = DateTime.tryParse(pDateStr);
      }
    } catch (_) {}

    DateTime parsedCreated;
    try {
      final cStr = map['created_at'] as String? ?? '';
      parsedCreated = DateTime.parse(cStr);
    } catch (_) {
      parsedCreated = DateTime.now();
    }

    final total = (map['total_amount'] as num?)?.toDouble() ?? 0.0;
    final paid = (map['paid_amount'] as num?)?.toDouble() ?? 0.0;

    return CustomerBillModel(
      id: map['id'] as int?,
      billNo: map['bill_no'] as String? ?? '',
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String? ?? '',
      date: parsedDate,
      totalAmount: total,
      paidAmount: paid,
      paymentStatus: map['payment_status'] as String?,
      paymentDate: parsedPaymentDate,
      designDetails: map['design_details'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: parsedCreated,
    );
  }
}
