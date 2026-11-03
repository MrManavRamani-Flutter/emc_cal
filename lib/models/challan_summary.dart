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

  bool get isPaid => items.isNotEmpty && items.every((i) => i.isPaid);
  bool get isPartiallyPaid => !isPaid && items.any((i) => i.isPaid);
  String get paymentStatus => isPaid ? 'Paid' : (isPartiallyPaid ? 'Partial' : 'Pending');
  double get paidAmount => items.where((i) => i.isPaid).fold(0.0, (sum, i) => sum + i.amount);
  double get pendingAmount => items.where((i) => !i.isPaid).fold(0.0, (sum, i) => sum + i.amount);
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
