import 'package:flutter/material.dart';
import '../widgets/app_svg_icon.dart';

class DeletedRecordItem {
  final int? id;
  final String recordType;
  final String recordTitle;
  final String recordSubtitle;
  final int? originalId;
  final String originalData;
  final DateTime deletedAt;
  final int isArchived;

  DeletedRecordItem({
    this.id,
    required this.recordType,
    required this.recordTitle,
    required this.recordSubtitle,
    this.originalId,
    required this.originalData,
    required this.deletedAt,
    this.isArchived = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'record_type': recordType,
      'record_title': recordTitle,
      'record_subtitle': recordSubtitle,
      'original_id': originalId,
      'original_data': originalData,
      'deleted_at': deletedAt.toIso8601String(),
      'is_archived': isArchived,
    };
  }

  factory DeletedRecordItem.fromMap(Map<String, dynamic> map) {
    return DeletedRecordItem(
      id: map['id'] as int?,
      recordType: map['record_type'] as String? ?? 'production_record',
      recordTitle: map['record_title'] as String? ?? 'Deleted Record',
      recordSubtitle: map['record_subtitle'] as String? ?? '',
      originalId: map['original_id'] as int?,
      originalData: map['original_data'] as String? ?? '{}',
      deletedAt: DateTime.tryParse(map['deleted_at'] as String? ?? '') ?? DateTime.now(),
      isArchived: (map['is_archived'] as int?) ?? 0,
    );
  }

  String get typeDisplayName {
    switch (recordType) {
      case 'production_record':
        return 'Production Record';
      case 'material_item':
        return 'Material / Challan';
      case 'machine':
        return 'Machine';
      case 'account':
        return 'Account / Khata';
      case 'material_product':
        return 'Product Master';
      case 'supplier':
        return 'Supplier Master';
      case 'employee':
        return 'Employee';
      case 'employee_upad':
        return 'Employee Upad / Advance';
      default:
        return 'Record';
    }
  }

  String get typeGujaratiName {
    switch (recordType) {
      case 'production_record':
        return 'ઉત્પાદન રેકોર્ડ';
      case 'material_item':
        return 'મટીરીયલ ચલણ';
      case 'machine':
        return 'મશીન';
      case 'account':
        return 'ખાતું';
      case 'material_product':
        return 'પ્રોડક્ટ માસ્ટર';
      case 'supplier':
        return 'વેપારી';
      case 'employee':
        return 'કર્મચારી';
      case 'employee_upad':
        return 'કર્મચારી ઉપાડ';
      default:
        return 'રેકોર્ડ';
    }
  }

  String get typeHindiName {
    switch (recordType) {
      case 'production_record':
        return 'उत्पादन रिकॉर्ड';
      case 'material_item':
        return 'सामग्री चालान';
      case 'machine':
        return 'मशीन';
      case 'account':
        return 'खाता';
      case 'material_product':
        return 'उत्पाद मास्टर';
      case 'supplier':
        return 'सप्लायर';
      case 'employee':
        return 'कर्मचारी';
      case 'employee_upad':
        return 'कर्मचारी उपाड़';
      default:
        return 'रिकॉर्ड';
    }
  }

  String localizedTypeName(String langCode) {
    final en = typeDisplayName;
    final gu = typeGujaratiName;
    final hi = typeHindiName;
    switch (langCode) {
      case 'gu':
        return gu;
      case 'hi':
        return hi;
      case 'en':
      default:
        return en;
    }
  }

  Color get typeColor {
    switch (recordType) {
      case 'production_record':
        return const Color(0xFF2563EB); // Royal Blue
      case 'material_item':
        return const Color(0xFFD97706); // Warm Amber
      case 'machine':
        return const Color(0xFF7C3AED); // Vivid Purple
      case 'account':
        return const Color(0xFF059669); // Emerald Green
      case 'material_product':
        return const Color(0xFF0891B2); // Cyan
      case 'supplier':
        return const Color(0xFFE11D48); // Rose
      case 'employee':
        return const Color(0xFF4F46E5); // Indigo
      case 'employee_upad':
        return const Color(0xFF0D9488); // Teal
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  IconData get typeIcon {
    switch (recordType) {
      case 'production_record':
        return Icons.precision_manufacturing_rounded;
      case 'material_item':
        return Icons.receipt_long_rounded;
      case 'machine':
        return Icons.settings_suggest_rounded;
      case 'account':
        return Icons.account_balance_wallet_rounded;
      case 'material_product':
        return Icons.category_rounded;
      case 'supplier':
        return Icons.store_rounded;
      case 'employee':
        return Icons.badge_rounded;
      case 'employee_upad':
        return Icons.payments_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  Widget getSvgIcon({double size = 20, Color? color}) {
    final effectiveColor = color ?? typeColor;
    switch (recordType) {
      case 'production_record':
        return AppSvgIcon.production(size: size, color: effectiveColor);
      case 'material_item':
      case 'material_product':
      case 'supplier':
        return AppSvgIcon.materials(size: size, color: effectiveColor);
      case 'machine':
        return AppSvgIcon.machines(size: size, color: effectiveColor);
      case 'account':
        return AppSvgIcon.accounts(size: size, color: effectiveColor);
      case 'employee':
      case 'employee_upad':
        return AppSvgIcon.employees(size: size, color: effectiveColor);
      default:
        return AppSvgIcon.production(size: size, color: effectiveColor);
    }
  }
}
