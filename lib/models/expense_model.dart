import 'package:intl/intl.dart';

/// Represents a general factory operating overhead or expense
class ExpenseModel {
  final int? id;
  final DateTime date;
  final String category; // 'ELECTRICITY', 'REPAIRS_MAINTENANCE', 'RENT', 'TEA_SNACKS', 'TRANSPORT', 'NEEDLES_SPARES', 'OTHER'
  final double amount;
  final String paymentMode; // 'Cash', 'Bank / UPI', 'Cheque'
  final String paidTo;
  final String notes;
  final DateTime createdAt;

  static const List<String> categories = [
    'ELECTRICITY',
    'REPAIRS_MAINTENANCE',
    'RENT',
    'TEA_SNACKS',
    'TRANSPORT',
    'NEEDLES_SPARES',
    'PETTY_CASH',
    'OTHER',
  ];

  ExpenseModel({
    this.id,
    DateTime? date,
    required this.category,
    required this.amount,
    this.paymentMode = 'Cash',
    String paidTo = '',
    String paidBy = '',
    String title = '',
    this.notes = '',
    DateTime? createdAt,
  })  : date = date ?? DateTime.now(),
        paidTo = title.isNotEmpty ? title : (paidBy.isNotEmpty ? paidBy : paidTo),
        createdAt = createdAt ?? DateTime.now();

  String get title => paidTo.isNotEmpty ? paidTo : category;
  String get paidBy => paidTo;

  String get formattedDate => DateFormat('dd-MM-yyyy').format(date);
  String get isoDate => DateFormat('yyyy-MM-dd').format(date);

  ExpenseModel copyWith({
    int? id,
    DateTime? date,
    String? category,
    double? amount,
    String? paymentMode,
    String? paidTo,
    String? notes,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      paidTo: paidTo ?? this.paidTo,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': isoDate,
      'category': category.trim().toUpperCase(),
      'amount': amount,
      'payment_mode': paymentMode.trim(),
      'paid_to': paidTo.trim(),
      'notes': notes.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
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

    return ExpenseModel(
      id: map['id'] as int?,
      date: parsedDate,
      category: (map['category'] as String? ?? 'OTHER').trim().toUpperCase(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['payment_mode'] as String? ?? 'Cash',
      paidTo: map['paid_to'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: parsedCreated,
    );
  }
}

class ExpenseCategories {
  static const List<String> all = ExpenseModel.categories;
  static String format(String category) {
    return category.replaceAll('_', ' ');
  }
}
