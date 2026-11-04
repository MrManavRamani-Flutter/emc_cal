import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/data/database_helper.dart';
import 'package:emb_cal/data/pdf_exporter.dart';
import 'package:emb_cal/models/expense_model.dart';
import 'package:emb_cal/models/settings_model.dart';
import 'package:emb_cal/providers/production_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Expense Categories Dynamic Management Tests', () {
    test('Default expense categories contains all 18 authentic embroidery categories + OTHER', () {
      final defaults = SettingsModel.defaultExpenseCategories;
      expect(defaults.length, 19);
      expect(defaults.contains('PETTY_CASH'), isTrue);
      expect(defaults.contains('TRANSPORT_TEMPO'), isTrue);
      expect(defaults.contains('CLIENT_HOSPITALITY'), isTrue);
      expect(defaults.contains('OFFICE_EXPENSE'), isTrue);
      expect(defaults.contains('CURTAINS_COVERS'), isTrue);
      expect(defaults.contains('BOBBIN_ACCESSORIES'), isTrue);
      expect(defaults.contains('WATER_EXPENSE'), isTrue);
      expect(defaults.contains('PETROL_CONVEYANCE'), isTrue);
      expect(defaults.contains('MACHINE_REPAIR'), isTrue);
      expect(defaults.contains('THREAD_CUTTING'), isTrue);
      expect(defaults.contains('RENT'), isTrue);
      expect(defaults.contains('LIGHT_BILL'), isTrue);
      expect(defaults.contains('TEA_SNACKS'), isTrue);
      expect(defaults.contains('IRONING_FOLDING'), isTrue);
      expect(defaults.contains('COMPUTER_WIFI'), isTrue);
      expect(defaults.contains('ELECTRIC_MAINTENANCE'), isTrue);
      expect(defaults.contains('NEW_MACHINERY'), isTrue);
      expect(defaults.contains('MACHINE_OIL'), isTrue);
      expect(defaults.contains('OTHER'), isTrue);
    });

    test('ExpenseCategories.getLabel provides Gujarati, Hindi, English labels and falls back gracefully', () {
      // Gujarati
      expect(ExpenseCategories.getLabel('PETTY_CASH', 'gu'), contains('અંદરનો'));
      expect(ExpenseCategories.getLabel('TRANSPORT_TEMPO', 'gu'), contains('ટેમ્પો ભાડું'));
      expect(ExpenseCategories.getLabel('BOBBIN_ACCESSORIES', 'gu'), contains('બોબીન'));
      expect(ExpenseCategories.getLabel('WATER_EXPENSE', 'gu'), contains('પાણી'));
      expect(ExpenseCategories.getLabel('THREAD_CUTTING', 'gu'), contains('દોરા કટિંગ'));

      // Hindi
      expect(ExpenseCategories.getLabel('PETTY_CASH', 'hi'), contains('दैनिक फुटकर खर्च'));
      expect(ExpenseCategories.getLabel('LIGHT_BILL', 'hi'), contains('बिजली'));

      // English
      expect(ExpenseCategories.getLabel('PETTY_CASH', 'en'), contains('Petty Cash'));
      expect(ExpenseCategories.getLabel('MACHINE_REPAIR', 'en'), contains('Machine Repairs'));

      // Custom category fallback
      expect(ExpenseCategories.getLabel('CUSTOM_PACKING_BOX', 'en'), 'CUSTOM PACKING BOX');
    });

    test('Provider adds, updates, deletes, and resets expense categories', () async {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      // Clean DB
      await db.delete('settings');
      await db.delete('expenses');

      final provider = ProductionProvider();
      await provider.init();

      expect(provider.expenseCategories.isNotEmpty, isTrue);
      final initialCount = provider.expenseCategories.length;

      // 1. Add a custom category
      await provider.addExpenseCategory('NEEDLES_PACK');
      expect(provider.expenseCategories.contains('NEEDLES_PACK'), isTrue);
      expect(provider.expenseCategories.length, initialCount + 1);

      // Verify persistence in SettingsModel
      final settings = await dbHelper.getSettings();
      expect(settings.expenseCategories.contains('NEEDLES_PACK'), isTrue);

      // 2. Add an expense with a new category dynamically
      final exp = ExpenseModel(
        title: 'Special Grease Oil',
        amount: 850.0,
        category: 'SPECIAL_GREASE',
        date: DateTime.now(),
        notes: 'Gearbox grease',
      );
      await provider.addExpense(exp);

      // It should auto-register in expenseCategories
      expect(provider.expenseCategories.contains('SPECIAL_GREASE'), isTrue);

      // 3. Delete a category
      await provider.deleteExpenseCategory('NEEDLES_PACK');
      expect(provider.expenseCategories.contains('NEEDLES_PACK'), isFalse);

      // 4. Reset to defaults
      await provider.resetExpenseCategoriesToDefault();
      expect(provider.expenseCategories.contains('SPECIAL_GREASE'), isFalse);
      expect(provider.expenseCategories.length, SettingsModel.defaultExpenseCategories.length);
    });

    test('PdfExporter generates non-empty PDF bytes for Grouped and Itemized Expense reports', () async {
      final sampleExpenses = [
        ExpenseModel(
          id: 1,
          title: 'Torrent Power Electricity Bill',
          amount: 14500.0,
          category: 'LIGHT_BILL',
          paymentMode: 'Bank / UPI',
          paidTo: 'Torrent Power',
          notes: 'Factory meter 1024 units',
          date: DateTime(2026, 11, 1),
        ),
        ExpenseModel(
          id: 2,
          title: 'Tempo Freight for Sequence Delivery',
          amount: 650.0,
          category: 'TRANSPORT_TEMPO',
          paymentMode: 'Cash',
          paidTo: 'Ramesh Tempo',
          notes: 'Challan #4043',
          date: DateTime(2026, 11, 2),
        ),
        ExpenseModel(
          id: 3,
          title: 'Machine Lubrication Oil Can',
          amount: 1200.0,
          category: 'MACHINE_OIL',
          paymentMode: 'Cash',
          paidTo: 'Shreeji Spares',
          notes: 'Servo 20L Oil',
          date: DateTime(2026, 11, 3),
        ),
      ];

      // 1. Grouped by Category Report
      final groupedPdf = await PdfExporter.generateExpenseReportPdf(
        expenses: sampleExpenses,
        isGroupedByCategory: true,
        companyName: 'OM MAVTAR GROUP',
        periodTitle: 'November 2026',
      );
      expect(groupedPdf, isNotEmpty);
      expect(groupedPdf.length, greaterThan(1000));

      // 2. Detailed Itemized Register Report
      final itemizedPdf = await PdfExporter.generateExpenseReportPdf(
        expenses: sampleExpenses,
        isGroupedByCategory: false,
        companyName: 'OM MAVTAR GROUP',
        periodTitle: 'November 2026',
      );
      expect(itemizedPdf, isNotEmpty);
      expect(itemizedPdf.length, greaterThan(1000));
    });
  });
}
