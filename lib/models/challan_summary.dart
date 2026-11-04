import 'material_item.dart';

/// Represents an aggregated summary of a single Challan (which can contain multiple material items)
class ChallanSummary {
  final String challanNo;
  final DateTime date;
  final String supplierName;
  final List<MaterialItem> items;

  ChallanSummary({
    required this.challanNo,
    required this.date,
    required this.supplierName,
    required this.items,
  });

  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.amount);
  double get totalQty => items.fold(0.0, (sum, item) => sum + item.qty);
  int get itemCount => items.length;
  List<String> get categories => items.map((i) => i.category).toSet().toList();

  double get paidAmount => items.fold(0.0, (sum, i) => sum + i.paidAmount);
  double get pendingAmount => (totalAmount - paidAmount).clamp(0.0, double.infinity);

  bool get isPaid => items.isNotEmpty && paidAmount >= totalAmount && totalAmount > 0;
  bool get isPartiallyPaid => paidAmount > 0 && paidAmount < totalAmount;
  String get paymentStatus => isPaid ? 'Paid' : (isPartiallyPaid ? 'Partial' : 'Pending');
  DateTime? get paymentDate => items.any((i) => i.paymentDate != null)
      ? items.firstWhere((i) => i.paymentDate != null).paymentDate
      : null;

  String get formattedDate => items.isNotEmpty ? items.first.formattedDate : '';

  ChallanSummary copyWith({
    String? challanNo,
    DateTime? date,
    String? supplierName,
    List<MaterialItem>? items,
  }) {
    return ChallanSummary(
      challanNo: challanNo ?? this.challanNo,
      date: date ?? this.date,
      supplierName: supplierName ?? this.supplierName,
      items: items ?? this.items,
    );
  }
}
