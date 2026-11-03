import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/material_item.dart';
import '../models/production_record.dart';

class ExcelExporter {
  static List<int>? generateProductionExcel({
    required List<ProductionRecord> records,
    String? title,
    String? dateRangeInfo,
    String currencySymbol = '₹',
    Map<String, bool>? selectedColumns,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Production Records';

    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    // Title Row
    sheet.appendRow([
      TextCellValue(title ?? 'Embroidery Production Calculator - Production Report')
    ]);

    // Subtitle / Date range
    sheet.appendRow([
      TextCellValue(
        dateRangeInfo ?? 'Generated on ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}',
      )
    ]);
    sheet.appendRow([]); // Blank row

    final bool incNo = selectedColumns?['No.'] ?? true;
    final bool incDate = selectedColumns?['Date'] ?? true;
    final bool incDesign = selectedColumns?['Design No.'] ?? true;
    final bool incMachine = selectedColumns?['Machine No.'] ?? true;
    final bool incTotalStitch = selectedColumns?['Total Stitch'] ?? true;
    final bool incFinalStitch = selectedColumns?['Final Stitch'] ?? true;
    final bool incRate = selectedColumns?['Rate'] ?? true;
    final bool incAmount = selectedColumns?['Amount'] ?? true;
    final bool incHeads = selectedColumns?['Heads'] ?? true;
    final bool incFinalAmount = selectedColumns?['Final Amount'] ?? true;

    // Table Headers
    final List<CellValue> headers = [];
    if (incNo) headers.add(TextCellValue('No.'));
    if (incDate) headers.add(TextCellValue('Date'));
    if (incDesign) headers.add(TextCellValue('Design No.'));
    if (incMachine) headers.add(TextCellValue('Machine No.'));
    if (incTotalStitch) headers.add(TextCellValue('Total Stitch'));
    if (incFinalStitch) headers.add(TextCellValue('Final Stitch'));
    if (incRate) headers.add(TextCellValue('Rate ($currencySymbol)'));
    if (incAmount) headers.add(TextCellValue('Amount ($currencySymbol)'));
    if (incHeads) headers.add(TextCellValue('Heads'));
    if (incFinalAmount) headers.add(TextCellValue('Final Amount ($currencySymbol)'));

    sheet.appendRow(headers);

    int grandTotalStitch = 0;
    double grandTotalAmount = 0.0;
    double grandFinalAmount = 0.0;

    // Data Rows
    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      grandTotalStitch += r.totalStitch;
      grandTotalAmount += r.amount;
      grandFinalAmount += r.finalAmount;

      final List<CellValue> rowCells = [];
      if (incNo) rowCells.add(IntCellValue(i + 1));
      if (incDate) rowCells.add(TextCellValue(r.formattedDate));
      if (incDesign) rowCells.add(TextCellValue(r.designNo));
      if (incMachine) rowCells.add(TextCellValue(r.machineNo));
      if (incTotalStitch) rowCells.add(IntCellValue(r.totalStitch));
      if (incFinalStitch) rowCells.add(DoubleCellValue(double.parse(r.finalStitch.toStringAsFixed(2))));
      if (incRate) rowCells.add(DoubleCellValue(double.parse(r.rate.toStringAsFixed(2))));
      if (incAmount) rowCells.add(DoubleCellValue(double.parse(r.amount.toStringAsFixed(2))));
      if (incHeads) rowCells.add(IntCellValue(r.heads));
      if (incFinalAmount) rowCells.add(DoubleCellValue(double.parse(r.finalAmount.toStringAsFixed(2))));

      sheet.appendRow(rowCells);
    }

    // Blank row before totals
    sheet.appendRow([]);

    // Grand Totals Row
    final List<CellValue> totalRowCells = [];
    if (incNo) totalRowCells.add(TextCellValue('Grand Total'));
    if (incDate) totalRowCells.add(TextCellValue('${records.length} Records'));
    if (incDesign) totalRowCells.add(TextCellValue(''));
    if (incMachine) totalRowCells.add(TextCellValue(''));
    if (incTotalStitch) totalRowCells.add(IntCellValue(grandTotalStitch));
    if (incFinalStitch) totalRowCells.add(TextCellValue(''));
    if (incRate) totalRowCells.add(TextCellValue(''));
    if (incAmount) totalRowCells.add(DoubleCellValue(double.parse(grandTotalAmount.toStringAsFixed(2))));
    if (incHeads) totalRowCells.add(TextCellValue(''));
    if (incFinalAmount) totalRowCells.add(DoubleCellValue(double.parse(grandFinalAmount.toStringAsFixed(2))));

    sheet.appendRow(totalRowCells);

    return excel.encode();
  }

  static Future<bool> saveExcelToFile({
    required String filePath,
    required List<ProductionRecord> records,
    String? title,
    String? dateRangeInfo,
    String currencySymbol = '₹',
    Map<String, bool>? selectedColumns,
  }) async {
    final bytes = generateProductionExcel(
      records: records,
      title: title,
      dateRangeInfo: dateRangeInfo,
      currencySymbol: currencySymbol,
      selectedColumns: selectedColumns,
    );

    if (bytes == null) return false;

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return true;
  }

  static List<int>? generateSupplierExcel({
    required String supplierName,
    required List<MaterialItem> items,
    String? companyName,
    String? phone,
    String? city,
    String currencySymbol = '₹',
  }) {
    final excel = Excel.createExcel();
    final sheetName = supplierName.isEmpty ? 'Supplier Statement' : supplierName.replaceAll(RegExp(r'[\\/*?:\[\]]'), '_');
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    final totalAmount = items.fold(0.0, (sum, i) => sum + i.amount);
    final totalQty = items.fold(0.0, (sum, i) => sum + i.qty);
    final paidAmount = items.where((i) => i.isPaid).fold(0.0, (sum, i) => sum + i.amount);
    final pendingAmount = items.where((i) => !i.isPaid).fold(0.0, (sum, i) => sum + i.amount);
    final uniqueChallans = items.map((i) => i.challanNo).where((n) => n.isNotEmpty).toSet().length;

    // Title Row
    sheet.appendRow([
      TextCellValue('${companyName ?? "OM MAVTAR GROUP"} - SUPPLIER ORDER STATEMENT & LEDGER')
    ]);

    // Supplier Info Subtitle
    final supplierSubtitle = 'Supplier: $supplierName'
        '${phone != null && phone.isNotEmpty ? " • Phone: $phone" : ""}'
        '${city != null && city.isNotEmpty ? " • City: $city" : ""}'
        ' • Generated: ${DateFormat("dd-MMM-yyyy hh:mm a").format(DateTime.now())}';
    sheet.appendRow([TextCellValue(supplierSubtitle)]);

    // Summary Metric Row
    final summaryText = 'Challans: $uniqueChallans | Total Items: ${items.length} | '
        'Total Purchases: $currencySymbol ${totalAmount.toStringAsFixed(2)} | '
        'Paid: $currencySymbol ${paidAmount.toStringAsFixed(2)} | '
        'Pending Due: $currencySymbol ${pendingAmount.toStringAsFixed(2)}';
    sheet.appendRow([TextCellValue(summaryText)]);
    sheet.appendRow([]); // Blank row

    // Table Headers
    sheet.appendRow([
      TextCellValue('No.'),
      TextCellValue('Date'),
      TextCellValue('Challan #'),
      TextCellValue('Category'),
      TextCellValue('Product Name'),
      TextCellValue('Unit / Form'),
      TextCellValue('MM'),
      TextCellValue('Meters'),
      TextCellValue('Quantity'),
      TextCellValue('Rate ($currencySymbol)'),
      TextCellValue('Total Amount ($currencySymbol)'),
      TextCellValue('Payment Status'),
      TextCellValue('Payment Date'),
      TextCellValue('Notes'),
    ]);

    // Data Rows
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(item.formattedDate),
        TextCellValue(item.challanNo.isEmpty ? '—' : item.challanNo),
        TextCellValue(item.category),
        TextCellValue(item.productName),
        TextCellValue(item.itemType),
        DoubleCellValue(item.mm),
        DoubleCellValue(item.mtr),
        DoubleCellValue(double.parse(item.qty.toStringAsFixed(2))),
        DoubleCellValue(double.parse(item.rate.toStringAsFixed(2))),
        DoubleCellValue(double.parse(item.amount.toStringAsFixed(2))),
        TextCellValue(item.isPaid ? 'PAID' : 'PENDING'),
        TextCellValue(item.formattedPaymentDate ?? '—'),
        TextCellValue(item.notes),
      ]);
    }

    // Blank row before totals
    sheet.appendRow([]);

    // Grand Totals Row
    sheet.appendRow([
      TextCellValue('Grand Total'),
      TextCellValue('${items.length} Items'),
      TextCellValue('$uniqueChallans Challans'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(double.parse(totalQty.toStringAsFixed(2))),
      TextCellValue(''),
      DoubleCellValue(double.parse(totalAmount.toStringAsFixed(2))),
      TextCellValue('Paid: $currencySymbol ${paidAmount.toStringAsFixed(2)} | Pending: $currencySymbol ${pendingAmount.toStringAsFixed(2)}'),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    return excel.encode();
  }

  static Future<bool> saveSupplierExcelToFile({
    required String filePath,
    required String supplierName,
    required List<MaterialItem> items,
    String? companyName,
    String? phone,
    String? city,
    String currencySymbol = '₹',
  }) async {
    final bytes = generateSupplierExcel(
      supplierName: supplierName,
      items: items,
      companyName: companyName,
      phone: phone,
      city: city,
      currencySymbol: currencySymbol,
    );

    if (bytes == null) return false;

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return true;
  }
}
