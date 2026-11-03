import 'package:intl/intl.dart';

class ProductionRecord {
  final int? id;
  final DateTime date;
  final String designNo;
  final String machineNo;
  final int totalStitch;
  final double finalStitch;
  final double rate;
  final double amount;
  final int heads;
  final double finalAmount;
  final String notes;
  final String accountName;
  final String shift; // 'Day' or 'Night'

  ProductionRecord({
    this.id,
    required this.date,
    required this.designNo,
    required this.machineNo,
    required this.totalStitch,
    required this.finalStitch,
    required this.rate,
    required this.amount,
    required this.heads,
    required this.finalAmount,
    this.notes = '',
    this.accountName = '250 Area',
    this.shift = 'Day',
  });

  ProductionRecord copyWith({
    int? id,
    DateTime? date,
    String? designNo,
    String? machineNo,
    int? totalStitch,
    double? finalStitch,
    double? rate,
    double? amount,
    int? heads,
    double? finalAmount,
    String? notes,
    String? accountName,
    String? shift,
  }) {
    return ProductionRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      designNo: designNo ?? this.designNo,
      machineNo: machineNo ?? this.machineNo,
      totalStitch: totalStitch ?? this.totalStitch,
      finalStitch: finalStitch ?? this.finalStitch,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      heads: heads ?? this.heads,
      finalAmount: finalAmount ?? this.finalAmount,
      notes: notes ?? this.notes,
      accountName: accountName ?? this.accountName,
      shift: shift ?? this.shift,
    );
  }

  String get formattedDate => DateFormat('dd-MM-yyyy').format(date);
  String get isoDate => DateFormat('yyyy-MM-dd').format(date);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': isoDate,
      'design_no': designNo,
      'machine_no': machineNo,
      'total_stitch': totalStitch,
      'final_stitch': finalStitch,
      'rate': rate,
      'amount': amount,
      'heads': heads,
      'final_amount': finalAmount,
      'notes': notes,
      'account_name': accountName,
      'shift': shift,
    };
  }

  factory ProductionRecord.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      final dateStr = map['date'] as String? ?? '';
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts[0].length == 4) {
          parsedDate = DateTime.parse(dateStr);
        } else {
          // dd-MM-yyyy
          parsedDate = DateFormat('dd-MM-yyyy').parse(dateStr);
        }
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return ProductionRecord(
      id: map['id'] as int?,
      date: parsedDate,
      designNo: map['design_no'] as String? ?? '',
      machineNo: map['machine_no'] as String? ?? '',
      totalStitch: (map['total_stitch'] as num?)?.toInt() ?? 0,
      finalStitch: (map['final_stitch'] as num?)?.toDouble() ?? 0.0,
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      heads: (map['heads'] as num?)?.toInt() ?? 0,
      finalAmount: (map['final_amount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String? ?? '',
      accountName: map['account_name'] as String? ?? (map['category'] as String? ?? '250 Area'),
      shift: map['shift'] as String? ?? 'Day',
    );
  }
}
