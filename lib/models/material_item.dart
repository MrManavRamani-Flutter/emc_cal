import 'package:intl/intl.dart';

/// Represents an inward stock/challan material item (Daga, Sequence, Beads)
class MaterialItem {
  final int? id;
  final String challanNo;
  final String supplierName;
  final DateTime date;
  final String category; // 'Daga', 'Sequence', 'Beads'
  final String productName; // e.g. 'L L CHIKKU'
  final String itemType; // 'cd', 'firka', 'cone', 'packet', 'roll'
  final double mtr; // Meters per unit or total meters
  final double mm; // Size in mm (e.g. 3.0, 5.0)
  final double qty; // Quantity received in challan
  final double rate; // Rate per unit in ₹
  final double amount; // Total amount (qty * rate)
  final double usedQty; // Stock consumed so far
  final String notes;
  final String paymentStatus; // 'Paid', 'Partial' or 'Pending' (default 'Pending')
  final double paidAmount; // Actual amount paid to supplier
  final DateTime? paymentDate;

  MaterialItem({
    this.id,
    this.challanNo = '',
    this.supplierName = '',
    required this.date,
    required this.category,
    required this.productName,
    required this.itemType,
    this.mtr = 0.0,
    this.mm = 0.0,
    required this.qty,
    required this.rate,
    double? amount,
    this.usedQty = 0.0,
    this.notes = '',
    double? paidAmount,
    String? paymentStatus,
    this.paymentDate,
  })  : amount = amount ?? (qty * rate),
        paidAmount = (paidAmount ?? (paymentStatus?.toLowerCase() == 'paid' ? (amount ?? (qty * rate)) : 0.0)).clamp(0.0, double.infinity),
        paymentStatus = paymentStatus ??
            ((paidAmount ?? 0.0) >= (amount ?? (qty * rate)) && (amount ?? (qty * rate)) > 0
                ? 'Paid'
                : ((paidAmount ?? 0.0) > 0 ? 'Partial' : 'Pending'));

  bool get isPaid => paidAmount >= amount && amount > 0;
  bool get isPartiallyPaid => paidAmount > 0 && paidAmount < amount;
  double get remainingAmount => (amount - paidAmount).clamp(0.0, double.infinity);
  double get balanceQty => (qty - usedQty).clamp(0.0, double.infinity);
  double get balanceAmount => balanceQty * rate;
  double get usagePercent => qty > 0 ? ((usedQty / qty) * 100).clamp(0.0, 100.0) : 0.0;
  bool get isOutOfStock => balanceQty <= 0.001;
  bool get isLowStock => balanceQty > 0 && balanceQty < (qty * 0.20);

  String get formattedDate => DateFormat('dd-MM-yyyy').format(date);
  String get isoDate => DateFormat('yyyy-MM-dd').format(date);
  String? get formattedPaymentDate => paymentDate != null ? DateFormat('dd-MM-yyyy').format(paymentDate!) : null;

  MaterialItem copyWith({
    int? id,
    String? challanNo,
    String? supplierName,
    DateTime? date,
    String? category,
    String? productName,
    String? itemType,
    double? mtr,
    double? mm,
    double? qty,
    double? rate,
    double? amount,
    double? usedQty,
    String? notes,
    double? paidAmount,
    String? paymentStatus,
    DateTime? paymentDate,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      challanNo: challanNo ?? this.challanNo,
      supplierName: supplierName ?? this.supplierName,
      date: date ?? this.date,
      category: category ?? this.category,
      productName: productName ?? this.productName,
      itemType: itemType ?? this.itemType,
      mtr: mtr ?? this.mtr,
      mm: mm ?? this.mm,
      qty: qty ?? this.qty,
      rate: rate ?? this.rate,
      amount: amount ?? (qty != null && rate != null ? qty * rate : this.amount),
      usedQty: usedQty ?? this.usedQty,
      notes: notes ?? this.notes,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'challan_no': challanNo,
      'supplier_name': supplierName,
      'date': isoDate,
      'category': category,
      'product_name': productName,
      'item_type': itemType,
      'mtr': mtr,
      'mm': mm,
      'qty': qty,
      'rate': rate,
      'amount': amount,
      'used_qty': usedQty,
      'notes': notes,
      'paid_amount': paidAmount,
      'payment_status': paymentStatus,
      'payment_date': paymentDate?.toIso8601String(),
    };
  }

  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      final dateStr = map['date'] as String? ?? '';
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts[0].length == 4) {
          parsedDate = DateTime.parse(dateStr);
        } else {
          parsedDate = DateFormat('dd-MM-yyyy').parse(dateStr);
        }
      } else {
        parsedDate = DateTime.now();
      }
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

    final parsedQty = (map['qty'] as num?)?.toDouble() ?? (double.tryParse(map['qty']?.toString() ?? '') ?? 0.0);
    final parsedRate = (map['rate'] as num?)?.toDouble() ?? (double.tryParse(map['rate']?.toString() ?? '') ?? 0.0);
    final rawAmount = (map['amount'] as num?)?.toDouble() ?? (double.tryParse(map['amount']?.toString() ?? '') ?? 0.0);
    final itemAmount = rawAmount > 0 ? rawAmount : (parsedQty * parsedRate);

    final rawStatus = (map['payment_status'] as String? ?? 'Pending').trim();
    final rawPaid = (map['paid_amount'] as num?)?.toDouble() ?? (double.tryParse(map['paid_amount']?.toString() ?? '') ?? (rawStatus.toLowerCase() == 'paid' ? itemAmount : 0.0));

    return MaterialItem(
      id: map['id'] != null ? (map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString())) : null,
      challanNo: map['challan_no'] as String? ?? '',
      supplierName: map['supplier_name'] as String? ?? '',
      date: parsedDate,
      category: map['category'] as String? ?? 'Sequence',
      productName: map['product_name'] as String? ?? '',
      itemType: map['item_type'] as String? ?? 'cd',
      mtr: (map['mtr'] as num?)?.toDouble() ?? (double.tryParse(map['mtr']?.toString() ?? '') ?? 0.0),
      mm: (map['mm'] as num?)?.toDouble() ?? (double.tryParse(map['mm']?.toString() ?? '') ?? 0.0),
      qty: parsedQty,
      rate: parsedRate,
      amount: itemAmount,
      usedQty: (map['used_qty'] as num?)?.toDouble() ?? (double.tryParse(map['used_qty']?.toString() ?? '') ?? 0.0),
      notes: map['notes'] as String? ?? '',
      paidAmount: rawPaid,
      paymentStatus: rawStatus,
      paymentDate: parsedPaymentDate,
    );
  }
}
