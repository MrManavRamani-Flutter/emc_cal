import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/challan_summary.dart';
import '../models/material_item.dart';

class PdfExporter {
  /// Generates a PDF byte document for a supplier's complete statement and order ledger
  static Future<Uint8List> generateSupplierStatementPdf({
    required String supplierName,
    required List<MaterialItem> items,
    String? companyName,
    String? phone,
    String? city,
    String currencySymbol = '₹',
  }) async {
    final pdf = pw.Document();

    final totalAmount = items.fold(0.0, (sum, i) => sum + i.amount);
    final totalQty = items.fold(0.0, (sum, i) => sum + i.qty);
    final paidAmount = items.where((i) => i.isPaid).fold(0.0, (sum, i) => sum + i.amount);
    final pendingAmount = items.where((i) => !i.isPaid).fold(0.0, (sum, i) => sum + i.amount);
    final uniqueChallans = items.map((i) => i.challanNo).where((n) => n.isNotEmpty).toSet().length;

    // Use built-in standard font
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return [
            // 1. Company & Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey900,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        (companyName ?? 'OM MAVTAR GROUP').toUpperCase(),
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Buyer / Purchaser: ${(companyName ?? 'OM MAVTAR GROUP')}',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.blueGrey200,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'RAW MATERIAL PURCHASES & PAYMENT LEDGER',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 10.5,
                          color: PdfColors.amber300,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Date: ${DateFormat("dd-MMM-yyyy hh:mm a").format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // 2. Supplier & Ledger Information Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
                color: PdfColors.grey100,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SUPPLIER / PARTY DETAILS:',
                        style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        supplierName.isEmpty ? 'All Registered Suppliers' : supplierName,
                        style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blueGrey900),
                      ),
                      if (phone != null && phone.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('Phone: $phone', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      ],
                      if (city != null && city.isNotEmpty) ...[
                        pw.SizedBox(height: 1),
                        pw.Text('City: $city', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total Challans: $uniqueChallans', style: pw.TextStyle(font: fontBold, fontSize: 9.5)),
                      pw.SizedBox(height: 2),
                      pw.Text('Total Items Recorded: ${items.length}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // 3. Financial KPI Strip (Total Purchases, Paid, Pending Due)
            pw.Row(
              children: [
                // Total Amount
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue200),
                      borderRadius: pw.BorderRadius.circular(5),
                      color: PdfColors.blue50,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total Purchases', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.blue800)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Rs. ${NumberFormat("#,##,###.00").format(totalAmount)}',
                          style: pw.TextStyle(font: fontBold, fontSize: 11.5, color: PdfColors.blue900),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Paid Amount
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.green200),
                      borderRadius: pw.BorderRadius.circular(5),
                      color: PdfColors.green50,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Paid to Supplier (Chukte)', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.green800)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Rs. ${NumberFormat("#,##,###.00").format(paidAmount)}',
                          style: pw.TextStyle(font: fontBold, fontSize: 11.5, color: PdfColors.green900),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Pending Amount
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: pendingAmount > 0 ? PdfColors.red200 : PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(5),
                      color: pendingAmount > 0 ? PdfColors.red50 : PdfColors.grey100,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Payable Due to Supplier (Baki)', style: pw.TextStyle(fontSize: 8.5, color: pendingAmount > 0 ? PdfColors.red800 : PdfColors.grey700)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Rs. ${NumberFormat("#,##,###.00").format(pendingAmount)}',
                          style: pw.TextStyle(font: fontBold, fontSize: 11.5, color: pendingAmount > 0 ? PdfColors.red900 : PdfColors.grey800),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // 4. Itemized Orders Table
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Date', 'Challan #', 'Cat.', 'Product Name', 'Qty / Unit', 'Rate (Rs)', 'Amount (Rs)', 'Status'],
              data: List<List<dynamic>>.generate(items.length, (index) {
                final item = items[index];
                return [
                  (index + 1).toString(),
                  item.formattedDate,
                  item.challanNo.isEmpty ? '—' : '#${item.challanNo}',
                  item.category,
                  '${item.productName}${item.mm > 0 ? " (${item.mm.toStringAsFixed(0)}mm)" : ""}',
                  '${item.qty.toStringAsFixed(0)} ${item.itemType}',
                  NumberFormat('#,##,###.00').format(item.rate),
                  NumberFormat('#,##,###.00').format(item.amount),
                  item.isPaid ? 'PAID' : 'PENDING',
                ];
              }),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.centerRight,
                7: pw.Alignment.centerRight,
                8: pw.Alignment.center,
              },
              headerAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.centerRight,
                7: pw.Alignment.centerRight,
                8: pw.Alignment.center,
              },
            ),
            pw.SizedBox(height: 10),

            // 5. Grand Totals Summary Row
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'GRAND TOTAL (${items.length} Items, ${totalQty.toStringAsFixed(0)} Units)',
                    style: pw.TextStyle(font: fontBold, fontSize: 9.5),
                  ),
                  pw.Text(
                    'Rs. ${NumberFormat("#,##,###.00").format(totalAmount)}',
                    style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blueGrey900),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 28),

            // 6. Signatures and Authorizations
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 4),
                    pw.Text('Supplier Signature / Stamp', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a PDF byte document for a single Challan
  static Future<Uint8List> generateChallanInvoicePdf({
    required ChallanSummary challan,
    String? companyName,
    String? supplierPhone,
    String? supplierCity,
    String currencySymbol = '₹',
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey900,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          (companyName ?? 'OM MAVTAR GROUP').toUpperCase(),
                          style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.white),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('Raw Material Purchase Inward Challan Bill (Buyer Copy)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey200)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('PURCHASE CHALLAN #${challan.challanNo}', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.amber300)),
                        pw.SizedBox(height: 2),
                        pw.Text('Inward Date: ${challan.formattedDate}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Supplier Info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                  color: PdfColors.grey100,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SUPPLIER / VENDOR (SELLER):', style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text(challan.supplierName.isEmpty ? '—' : challan.supplierName, style: pw.TextStyle(font: fontBold, fontSize: 12.5)),
                        if (supplierPhone != null && supplierPhone.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text('Phone: $supplierPhone', style: const pw.TextStyle(fontSize: 8.5)),
                        ],
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Payment to Supplier: ${challan.isPaid ? "PAID TO SUPPLIER" : "PAYABLE / DUE"}',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 10,
                              color: challan.isPaid ? PdfColors.green800 : PdfColors.red800,
                            )),
                        pw.SizedBox(height: 2),
                        pw.Text('Total Items: ${challan.itemCount}', style: const pw.TextStyle(fontSize: 8.5)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Items Table
              pw.TableHelper.fromTextArray(
                headers: ['#', 'Category', 'Product Name', 'Form', 'MM', 'Meters', 'Purchased Qty', 'Rate (Rs)', 'Purchase Amount (Rs)'],
                data: List<List<dynamic>>.generate(challan.items.length, (index) {
                  final item = challan.items[index];
                  return [
                    (index + 1).toString(),
                    item.category,
                    item.productName,
                    item.itemType,
                    item.mm > 0 ? '${item.mm.toStringAsFixed(0)}mm' : '—',
                    item.mtr > 0 ? '${item.mtr.toStringAsFixed(0)}m' : '—',
                    '${item.qty.toStringAsFixed(0)} ${item.itemType}',
                    NumberFormat('#,##,###.00').format(item.rate),
                    NumberFormat('#,##,###.00').format(item.amount),
                  ];
                }),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                  6: pw.Alignment.centerRight,
                  7: pw.Alignment.centerRight,
                  8: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 12),

              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL PURCHASE BILL PAYABLE TO SUPPLIER', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                    pw.Text(
                      'Rs. ${NumberFormat("#,##,###.00").format(challan.totalAmount)}',
                      style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blueGrey900),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text('Buyer Signature (OM MAVTAR GROUP)', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text('Supplier / Vendor Stamp & Sign', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Opens the native print and PDF preview/save dialog
  static Future<void> printOrPreviewSupplierStatement({
    required String supplierName,
    required List<MaterialItem> items,
    String? companyName,
    String? phone,
    String? city,
  }) async {
    final pdfBytes = await generateSupplierStatementPdf(
      supplierName: supplierName,
      items: items,
      companyName: companyName,
      phone: phone,
      city: city,
    );

    try {
      await Printing.layoutPdf(
        name: 'Supplier_Statement_${supplierName.replaceAll(" ", "_")}',
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (_) {
      await _fallbackSaveAndOpenPdf(
        pdfBytes: pdfBytes,
        filename: 'Supplier_Statement_${supplierName.replaceAll(" ", "_")}_${DateFormat("yyyyMMdd_HHmmss").format(DateTime.now())}.pdf',
      );
    }
  }

  /// Fallback: saves PDF to Documents/PDF_Statements and opens in system default viewer (Preview)
  static Future<String?> _fallbackSaveAndOpenPdf({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${docs.path}/EmbroideryProductionCalculator/PDF_Statements');
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }
      final file = File('${pdfDir.path}/$filename');
      await file.writeAsBytes(pdfBytes);
      if (Platform.isMacOS) {
        await Process.run('open', [file.path]);
      }
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Exports Challan Invoice directly to disk and opens in Preview
  static Future<String?> exportAndOpenChallanInvoicePdf({
    required ChallanSummary challan,
    String? companyName,
    String? supplierPhone,
    String? supplierCity,
  }) async {
    final pdfBytes = await generateChallanInvoicePdf(
      challan: challan,
      companyName: companyName,
      supplierPhone: supplierPhone,
      supplierCity: supplierCity,
    );
    final filename = 'Challan_Bill_${challan.challanNo.replaceAll(RegExp(r'[\\/*?:\[\]\s]'), '_')}_${DateFormat("yyyyMMdd_HHmmss").format(DateTime.now())}.pdf';
    return await _fallbackSaveAndOpenPdf(
      pdfBytes: pdfBytes,
      filename: filename,
    );
  }

  /// Direct Save to disk with FilePicker
  static Future<String?> saveSupplierPdfToFile({
    required String supplierName,
    required List<MaterialItem> items,
    String? companyName,
    String? phone,
    String? city,
  }) async {
    final pdfBytes = await generateSupplierStatementPdf(
      supplierName: supplierName,
      items: items,
      companyName: companyName,
      phone: phone,
      city: city,
    );

    final cleanName = supplierName.isEmpty ? 'All_Suppliers' : supplierName.replaceAll(RegExp(r'[\\/*?:\[\]\s]'), '_');
    final filename = 'Supplier_Statement_${cleanName}_${DateFormat("yyyyMMdd").format(DateTime.now())}.pdf';

    String? targetPath;
    try {
      final uri = await FilePicker.saveFile(
        fileName: filename,
        bytes: pdfBytes,
        dialogTitle: 'Save Supplier PDF Statement',
      );
      if (uri != null) {
        targetPath = uri.toFilePath();
      }
    } catch (_) {
      final docs = await getApplicationDocumentsDirectory();
      targetPath = '${docs.path}/$filename';
      final file = File(targetPath);
      await file.writeAsBytes(pdfBytes);
    }

    targetPath ??= '${(await getApplicationDocumentsDirectory()).path}/$filename';
    return targetPath;
  }

  /// Opens native print and PDF preview/save dialog for a single challan bill
  static Future<void> printOrPreviewChallanInvoice({
    required ChallanSummary challan,
    String? companyName,
    String? supplierPhone,
    String? supplierCity,
  }) async {
    final pdfBytes = await generateChallanInvoicePdf(
      challan: challan,
      companyName: companyName,
      supplierPhone: supplierPhone,
      supplierCity: supplierCity,
    );
    try {
      await Printing.layoutPdf(
        name: 'Challan_Bill_${challan.challanNo}',
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (_) {
      await _fallbackSaveAndOpenPdf(
        pdfBytes: pdfBytes,
        filename: 'Challan_Bill_${challan.challanNo}_${DateFormat("yyyyMMdd_HHmmss").format(DateTime.now())}.pdf',
      );
    }
  }
}
