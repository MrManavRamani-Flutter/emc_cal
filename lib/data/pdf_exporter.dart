import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/challan_summary.dart';
import '../models/material_item.dart';
import '../models/expense_model.dart';
import 'database_helper.dart';

class PdfExporter {
  /// Converts a numeric amount to English words (Indian numbering system)
  static String amountInWords(double amount) {
    if (amount.isNaN || amount.isInfinite) return 'Zero Rupees Only';
    final rounded = amount.abs();
    final rupees = rounded.floor();
    final paise = ((rounded - rupees) * 100).round();

    final rupeesWords = _convertNumberToWords(rupees);
    if (paise > 0) {
      final paiseWords = _convertNumberToWords(paise);
      return '$rupeesWords Rupees And $paiseWords Paise Only';
    }
    return '$rupeesWords Rupees Only';
  }

  static String _convertNumberToWords(int n) {
    if (n == 0) return 'Zero';

    const units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];

    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String convertLessThanThousand(int num) {
      String str = '';
      if (num % 100 < 20) {
        str = units[num % 100];
        num ~/= 100;
      } else {
        str = units[num % 10];
        num ~/= 10;
        final t = tens[num % 10];
        str = t.isNotEmpty ? (str.isNotEmpty ? '$t $str' : t) : str;
        num ~/= 10;
      }
      if (num == 0) return str;
      final h = '${units[num]} Hundred';
      return str.isNotEmpty ? '$h $str' : h;
    }

    final crores = n ~/ 10000000;
    n %= 10000000;
    final lakhs = n ~/ 100000;
    n %= 100000;
    final thousands = n ~/ 1000;
    n %= 1000;
    final remainder = n;

    final parts = <String>[];
    if (crores > 0) {
      parts.add('${convertLessThanThousand(crores)} Crore');
    }
    if (lakhs > 0) {
      parts.add('${convertLessThanThousand(lakhs)} Lakh');
    }
    if (thousands > 0) {
      parts.add('${convertLessThanThousand(thousands)} Thousand');
    }
    if (remainder > 0) {
      parts.add(convertLessThanThousand(remainder));
    }

    return parts.join(' ').trim();
  }

  /// Generates a PDF byte document for an authentic Surat Textile / Embroidery Material Challan.
  /// Exactly follows the physical printed format of BHAGWATI JARI and KHUSHI FASHION challans.
  static Future<Uint8List> generateChallanInvoicePdf({
    required ChallanSummary challan,
    String? companyName,
    String? supplierPhone,
    String? supplierCity,
    String? supplierGst,
    String? buyerAddress,
    String? buyerPhone,
    String currencySymbol = 'Rs.',
  }) async {
    final pdf = pw.Document();

    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final fontItalic = pw.Font.helveticaOblique();

    final totalAmount = challan.totalAmount;
    final totalQty = challan.totalQty;
    final paidAmount = challan.paidAmount;
    final remainingAmount = challan.pendingAmount;

    final supplierName = challan.supplierName.trim().isNotEmpty
        ? challan.supplierName.trim()
        : 'RAW MATERIAL SUPPLIER';

    final buyerTitle = (companyName != null && companyName.trim().isNotEmpty)
        ? companyName.trim()
        : 'OM MAVTAR GROUP';

    final buyerAddr = (buyerAddress != null && buyerAddress.trim().isNotEmpty)
        ? buyerAddress.trim()
        : 'Plot.40, 1st Floor, Jay Ambey, Surat';

    final buyerMo = (buyerPhone != null && buyerPhone.trim().isNotEmpty)
        ? buyerPhone.trim()
        : '9726589118';

    final formattedDate = DateFormat('dd/MM/yyyy').format(challan.date);
    final formattedTime = DateFormat('HH:mm:ss').format(challan.date);

    final hasMtrOrMm = challan.items.any((i) => i.mtr > 0 || i.mm > 0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 1. Supplier / Vendor Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        supplierName.toUpperCase(),
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      if (supplierCity != null && supplierCity.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          supplierCity.trim(),
                          style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                      if (supplierPhone != null && supplierPhone.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          supplierPhone.trim().toLowerCase().startsWith('m')
                              ? supplierPhone.trim()
                              : 'M. ${supplierPhone.trim()}',
                          style: pw.TextStyle(font: fontBold, fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                // 2. Challan Title Bar (Centered with Original tag)
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.black, width: 1),
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        hasMtrOrMm ? 'SALES CHALLAN' : 'Challan',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Original',
                        style: pw.TextStyle(
                          font: fontItalic,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Buyer Details (M/s.) & Challan Meta
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left: M/s. OM MAVTAR GROUP
                      pw.Expanded(
                        flex: 6,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(color: PdfColors.black, width: 1),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'M/s. : ',
                                    style: pw.TextStyle(font: fontBold, fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Expanded(
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(
                                          buyerTitle.toUpperCase(),
                                          style: pw.TextStyle(font: fontBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                                        ),
                                        pw.Text(
                                          'URVISHBHAI',
                                          style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
                                        ),
                                        pw.Text(
                                          buyerAddr,
                                          style: pw.TextStyle(font: fontRegular, fontSize: 8),
                                        ),
                                        pw.Text(
                                          buyerMo,
                                          style: pw.TextStyle(font: fontBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text('MO:-', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                            ],
                          ),
                        ),
                      ),

                      // Right: Ch. No., Date, Time
                      pw.Expanded(
                        flex: 4,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                children: [
                                  pw.SizedBox(
                                    width: 52,
                                    child: pw.Text('Ch. No. :', style: pw.TextStyle(font: fontBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                  ),
                                  pw.Text(
                                    challan.challanNo.isEmpty ? '—' : challan.challanNo,
                                    style: pw.TextStyle(font: fontBold, fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 3),
                              pw.Row(
                                children: [
                                  pw.SizedBox(
                                    width: 52,
                                    child: pw.Text('Date    :', style: pw.TextStyle(font: fontBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                  ),
                                  pw.Text(
                                    formattedDate,
                                    style: pw.TextStyle(font: fontRegular, fontSize: 9),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 3),
                              pw.Row(
                                children: [
                                  pw.SizedBox(
                                    width: 52,
                                    child: pw.Text('Time    :', style: pw.TextStyle(font: fontBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                  ),
                                  pw.Text(
                                    formattedTime,
                                    style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Itemized Table (Custom grid with vertical and horizontal dividers)
                _buildChallanTable(
                  items: challan.items,
                  hasMtrOrMm: hasMtrOrMm,
                  fontRegular: fontRegular,
                  fontBold: fontBold,
                  totalAmount: totalAmount,
                  totalQty: totalQty,
                ),

                // 5. Amount in Words & Payment Line
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Rs. ${amountInWords(totalAmount)}',
                          style: pw.TextStyle(font: fontItalic, fontSize: 8.5),
                        ),
                      ),
                      if (paidAmount > 0 || remainingAmount > 0)
                        pw.Text(
                          'Paid: Rs. ${NumberFormat("#,##,###.00").format(paidAmount)}   |   Balance Due: Rs. ${NumberFormat("#,##,###.00").format(remainingAmount)}',
                          style: pw.TextStyle(font: fontBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                        )
                      else if (challan.isPaid)
                        pw.Text(
                          'Payment: PAID TO SUPPLIER',
                          style: pw.TextStyle(font: fontBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                        ),
                    ],
                  ),
                ),

                // 6. Terms & Condition + Signatures
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left: Terms & Receiver Sign
                      pw.Expanded(
                        flex: 6,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Terms & Condition :',
                              style: pw.TextStyle(font: fontBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 1),
                            pw.Text(
                              '1. Goods Once Sold Will Not Be Accepted.',
                              style: pw.TextStyle(font: fontRegular, fontSize: 7.5),
                            ),
                            pw.Text(
                              '2. E.&O.E.',
                              style: pw.TextStyle(font: fontRegular, fontSize: 7.5),
                            ),
                            if (hasMtrOrMm)
                              pw.Text(
                                '3. .NO DYING GURANTEE.',
                                style: pw.TextStyle(font: fontRegular, fontSize: 7.5),
                              ),
                            if (supplierGst != null && supplierGst.trim().isNotEmpty) ...[
                              pw.SizedBox(height: 1),
                              pw.Text(
                                'GST No.: ${supplierGst.trim()}',
                                style: pw.TextStyle(font: fontRegular, fontSize: 7.5),
                              ),
                            ],
                            pw.SizedBox(height: 28),
                            pw.Text(
                              'Receiver\'s Signature',
                              style: pw.TextStyle(font: fontBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      // Right: Supplier Signatory
                      pw.Expanded(
                        flex: 4,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'For, ${supplierName.toUpperCase()}',
                              style: pw.TextStyle(font: fontBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right,
                            ),
                            pw.SizedBox(height: 36),
                            pw.Text(
                              '(Authorised Signatory)',
                              style: pw.TextStyle(font: fontRegular, fontSize: 8),
                              textAlign: pw.TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Builds the itemized table with vertical column dividers matching Surat paper challans
  static pw.Widget _buildChallanTable({
    required List<MaterialItem> items,
    required bool hasMtrOrMm,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    required double totalAmount,
    required double totalQty,
  }) {
    final Map<int, pw.TableColumnWidth> columnWidths = hasMtrOrMm
        ? const {
            0: pw.FixedColumnWidth(28),
            1: pw.FlexColumnWidth(3.8),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(1.5),
            4: pw.FlexColumnWidth(1.2),
            5: pw.FlexColumnWidth(2.0),
            6: pw.FlexColumnWidth(1.8),
            7: pw.FlexColumnWidth(2.4),
          }
        : const {
            0: pw.FixedColumnWidth(28),
            1: pw.FlexColumnWidth(5.5),
            2: pw.FlexColumnWidth(2.2),
            3: pw.FlexColumnWidth(2.2),
            4: pw.FlexColumnWidth(2.0),
            5: pw.FlexColumnWidth(2.6),
          };

    final rows = <pw.TableRow>[];

    // Header Row
    if (hasMtrOrMm) {
      rows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
          ),
          children: [
            _cell('SrNo', font: fontBold, isHeader: true, align: pw.TextAlign.center),
            _cell('Product', font: fontBold, isHeader: true, align: pw.TextAlign.left),
            _cell('Item', font: fontBold, isHeader: true, align: pw.TextAlign.center),
            _cell('MTR', font: fontBold, isHeader: true, align: pw.TextAlign.right),
            _cell('MM', font: fontBold, isHeader: true, align: pw.TextAlign.right),
            _cell('Qty', font: fontBold, isHeader: true, align: pw.TextAlign.right),
            _cell('Rate', font: fontBold, isHeader: true, align: pw.TextAlign.right),
            _cell('Amt.', font: fontBold, isHeader: true, align: pw.TextAlign.right),
          ],
        ),
      );
    } else {
      rows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
          ),
          children: [
            _cell('Sr', font: fontBold, isHeader: true, align: pw.TextAlign.center),
            _cell('Product Name', font: fontBold, isHeader: true, align: pw.TextAlign.left),
            _cell('Shade No.', font: fontBold, isHeader: true, align: pw.TextAlign.center),
            _cell('Qty', font: fontBold, isHeader: true, align: pw.TextAlign.right),
            _cell('Rate', font: fontBold, isHeader: true, align: pw.TextAlign.right),
            _cell('Amount', font: fontBold, isHeader: true, align: pw.TextAlign.right),
          ],
        ),
      );
    }

    // Data Rows
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final qtyStr = item.qty.toStringAsFixed(3);
      final rateStr = item.rate.toStringAsFixed(2);
      final amtStr = NumberFormat('#,##,###.00').format(item.amount);

      if (hasMtrOrMm) {
        rows.add(
          pw.TableRow(
            children: [
              _cell('${i + 1}', font: fontRegular, align: pw.TextAlign.center),
              _cell(item.productName.toUpperCase(), font: fontBold, align: pw.TextAlign.left),
              _cell(item.itemType, font: fontRegular, align: pw.TextAlign.center),
              _cell(item.mtr > 0 ? item.mtr.toStringAsFixed(2) : '—', font: fontRegular, align: pw.TextAlign.right),
              _cell(item.mm > 0 ? item.mm.toStringAsFixed(2) : '—', font: fontRegular, align: pw.TextAlign.right),
              _cell(qtyStr, font: fontRegular, align: pw.TextAlign.right),
              _cell(rateStr, font: fontRegular, align: pw.TextAlign.right),
              _cell(amtStr, font: fontRegular, align: pw.TextAlign.right),
            ],
          ),
        );
      } else {
        rows.add(
          pw.TableRow(
            children: [
              _cell('${i + 1}', font: fontRegular, align: pw.TextAlign.center),
              _cell(item.productName.toUpperCase(), font: fontBold, align: pw.TextAlign.left),
              _cell(item.itemType.isNotEmpty ? item.itemType : '—', font: fontRegular, align: pw.TextAlign.center),
              _cell(qtyStr, font: fontRegular, align: pw.TextAlign.right),
              _cell(rateStr, font: fontRegular, align: pw.TextAlign.right),
              _cell(amtStr, font: fontRegular, align: pw.TextAlign.right),
            ],
          ),
        );
      }
    }

    // Fill empty rows if items < 6 to match paper bill format
    final emptyRowsNeeded = (6 - items.length).clamp(0, 5);
    for (int i = 0; i < emptyRowsNeeded; i++) {
      if (hasMtrOrMm) {
        rows.add(
          pw.TableRow(
            children: List.generate(8, (_) => _cell(' ', font: fontRegular)),
          ),
        );
      } else {
        rows.add(
          pw.TableRow(
            children: List.generate(6, (_) => _cell(' ', font: fontRegular)),
          ),
        );
      }
    }

    // Totals Row
    final totalQtyStr = totalQty.toStringAsFixed(3);
    final totalAmtStr = NumberFormat('#,##,###.00').format(totalAmount);

    if (hasMtrOrMm) {
      rows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.black, width: 1),
              bottom: pw.BorderSide(color: PdfColors.black, width: 1),
            ),
          ),
          children: [
            _cell('', font: fontBold),
            _cell('', font: fontBold),
            _cell('', font: fontBold),
            _cell('', font: fontBold),
            _cell('Total:', font: fontBold, align: pw.TextAlign.right),
            _cell(totalQtyStr, font: fontBold, align: pw.TextAlign.right),
            _cell('Total', font: fontBold, align: pw.TextAlign.center),
            _cell('Rs. $totalAmtStr', font: fontBold, align: pw.TextAlign.right),
          ],
        ),
      );
    } else {
      rows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.black, width: 1),
              bottom: pw.BorderSide(color: PdfColors.black, width: 1),
            ),
          ),
          children: [
            _cell('', font: fontBold),
            _cell('Total Qty: ', font: fontBold, align: pw.TextAlign.right),
            _cell('', font: fontBold),
            _cell(totalQtyStr, font: fontBold, align: pw.TextAlign.right),
            _cell('Total', font: fontBold, align: pw.TextAlign.center),
            _cell('Rs. $totalAmtStr', font: fontBold, align: pw.TextAlign.right),
          ],
        ),
      );
    }

    return pw.Table(
      columnWidths: columnWidths,
      border: pw.TableBorder(
        verticalInside: const pw.BorderSide(color: PdfColors.black, width: 0.8),
        horizontalInside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        bottom: const pw.BorderSide(color: PdfColors.black, width: 1),
      ),
      children: rows,
    );
  }

  static pw.Widget _cell(
    String text, {
    required pw.Font font,
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        vertical: isHeader ? 4.5 : 3.5,
        horizontal: 4,
      ),
      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : align == pw.TextAlign.right
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 8.5 : 8.0,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

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

    // Use built-in standard font for instant offline generation
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

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

  /// Exports Challan Invoice directly to disk and opens in Preview
  static Future<String?> exportAndOpenChallanInvoicePdf({
    required ChallanSummary challan,
    String? companyName,
    String? supplierPhone,
    String? supplierCity,
    String? supplierGst,
    String? buyerAddress,
    String? buyerPhone,
  }) async {
    final pdfBytes = await generateChallanInvoicePdf(
      challan: challan,
      companyName: companyName,
      supplierPhone: supplierPhone,
      supplierCity: supplierCity,
      supplierGst: supplierGst,
      buyerAddress: buyerAddress,
      buyerPhone: buyerPhone,
    );
    final filename = 'Challan_Bill_${challan.challanNo.replaceAll(RegExp(r'[\\/*?:\[\]\s]'), '_')}_${DateFormat("yyyyMMdd_HHmmss").format(DateTime.now())}.pdf';
    return await _fallbackSaveAndOpenPdf(
      pdfBytes: pdfBytes,
      filename: filename,
    );
  }

  /// Exports a single separate Material Item directly as a Challan PDF and opens in Preview
  static Future<String?> exportAndOpenMaterialItemPdf({
    required MaterialItem item,
    String? companyName,
    String? supplierPhone,
    String? supplierCity,
    String? supplierGst,
    String? buyerAddress,
    String? buyerPhone,
  }) async {
    final singleChallan = ChallanSummary(
      challanNo: item.challanNo.isNotEmpty ? item.challanNo : (item.id != null ? 'ITM-${item.id}' : 'CH-1'),
      date: item.date,
      supplierName: item.supplierName.isNotEmpty ? item.supplierName : 'RAW MATERIAL SUPPLIER',
      items: [item],
    );
    return await exportAndOpenChallanInvoicePdf(
      challan: singleChallan,
      companyName: companyName,
      supplierPhone: supplierPhone,
      supplierCity: supplierCity,
      supplierGst: supplierGst,
      buyerAddress: buyerAddress,
      buyerPhone: buyerPhone,
    );
  }

  /// Fallback: saves PDF to Storage/PDF_Statements and opens in system default viewer
  static Future<String?> _fallbackSaveAndOpenPdf({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    try {
      final baseDir = await DatabaseHelper.getStorageDirectory();
      final pdfDir = Directory(p.join(baseDir.path, 'PDF_Statements'));
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }
      final file = File(p.join(pdfDir.path, filename));
      await file.writeAsBytes(pdfBytes);
      if (Platform.isMacOS) {
        await Process.run('open', [file.path]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', file.path]);
      }
      return file.path;
    } catch (_) {
      return null;
    }
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

    if (Platform.isMacOS) {
      await _fallbackSaveAndOpenPdf(
        pdfBytes: pdfBytes,
        filename: 'Supplier_Statement_${supplierName.replaceAll(" ", "_")}_${DateFormat("yyyyMMdd_HHmmss").format(DateTime.now())}.pdf',
      );
      return;
    }
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
    String? supplierGst,
  }) async {
    final pdfBytes = await generateChallanInvoicePdf(
      challan: challan,
      companyName: companyName,
      supplierPhone: supplierPhone,
      supplierCity: supplierCity,
      supplierGst: supplierGst,
    );
    if (Platform.isMacOS) {
      await _fallbackSaveAndOpenPdf(
        pdfBytes: pdfBytes,
        filename: 'Challan_Bill_${challan.challanNo}_${DateFormat("yyyyMMdd_HHmmss").format(DateTime.now())}.pdf',
      );
      return;
    }
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

  /// Generates a PDF report for Expenses:
  /// either Category-Wise Grouped (`isGroupedByCategory = true`)
  /// or Detailed Chronological Item Register (`isGroupedByCategory = false`).
  static Future<Uint8List> generateExpenseReportPdf({
    required List<ExpenseModel> expenses,
    required bool isGroupedByCategory,
    String? companyName,
    String? periodTitle,
    String? searchKeyword,
    Set<String>? activeCategories,
  }) async {
    final pdf = pw.Document();

    final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalRecords = expenses.length;
    final cashAmount = expenses
        .where((e) => e.paymentMode.toLowerCase().contains('cash'))
        .fold(0.0, (sum, e) => sum + e.amount);
    final bankAmount = totalAmount - cashAmount;

    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final fontOblique = pw.Font.helveticaOblique();

    // Grouping map
    final Map<String, List<ExpenseModel>> grouped = {};
    for (final exp in expenses) {
      final cat = exp.category.toUpperCase().trim();
      grouped.putIfAbsent(cat, () => []).add(exp);
    }

    final sortedCategories = grouped.keys.toList()
      ..sort((a, b) {
        final sumA = grouped[a]!.fold(0.0, (s, e) => s + e.amount);
        final sumB = grouped[b]!.fold(0.0, (s, e) => s + e.amount);
        return sumB.compareTo(sumA);
      });

    final effectivePeriod = periodTitle ?? 'All Records';
    final orgName = (companyName ?? 'OM MAVTAR GROUP').toUpperCase();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                      orgName,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 15,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      isGroupedByCategory
                          ? 'FACTORY EXPENSES STATEMENT (CATEGORY-WISE GROUPED)'
                          : 'FACTORY DETAILED EXPENSE REGISTER (ITEMIZED STATEMENT)',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8.5,
                        color: PdfColors.amber300,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Period: $effectivePeriod',
                      style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.white),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Generated: ${DateFormat("dd-MMM-yyyy hh:mm a").format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey200),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'OM MAVTAR GROUP - Offline Production & Accounts Management System',
                  style: pw.TextStyle(font: fontOblique, fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Financial Strip
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.red300),
                      borderRadius: pw.BorderRadius.circular(5),
                      color: PdfColors.red50,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total Filtered Expenses', style: const pw.TextStyle(fontSize: 8, color: PdfColors.red800)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Rs. ${NumberFormat("#,##,###.00").format(totalAmount)}',
                          style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.red900),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
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
                        pw.Text('Total Entries', style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue800)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '$totalRecords Records',
                          style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.indigo200),
                      borderRadius: pw.BorderRadius.circular(5),
                      color: PdfColors.indigo50,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Categories Count', style: const pw.TextStyle(fontSize: 8, color: PdfColors.indigo800)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '${sortedCategories.length} Categories',
                          style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.indigo900),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
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
                        pw.Text('Cash / Bank Modes', style: const pw.TextStyle(fontSize: 8, color: PdfColors.green800)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Cash: Rs. ${NumberFormat("#,##,###").format(cashAmount)}',
                          style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.green900),
                        ),
                        pw.Text(
                          'Bank: Rs. ${NumberFormat("#,##,###").format(bankAmount)}',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            if (isGroupedByCategory) ...[
              // Summary distribution table
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'CATEGORY-WISE EXPENSE DISTRIBUTION SUMMARY',
                  style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.blueGrey900),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['#', 'Category Name', 'Items Count', 'Total Amount (Rs.)', '% Share'],
                data: List<List<dynamic>>.generate(sortedCategories.length, (idx) {
                  final cat = sortedCategories[idx];
                  final items = grouped[cat]!;
                  final catSum = items.fold(0.0, (s, e) => s + e.amount);
                  final pct = totalAmount > 0 ? (catSum / totalAmount * 100).toStringAsFixed(1) : '0.0';
                  return [
                    (idx + 1).toString(),
                    cat.replaceAll('_', ' '),
                    items.length.toString(),
                    'Rs. ${NumberFormat("#,##,###.00").format(catSum)}',
                    '$pct %',
                  ];
                }),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                headerAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 14),

              // Detailed items grouped by each category
              ...sortedCategories.map((cat) {
                final catItems = grouped[cat]!;
                final catSum = catItems.fold(0.0, (s, e) => s + e.amount);
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.blueGrey700,
                          borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(3)),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              cat.replaceAll('_', ' '),
                              style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.white),
                            ),
                            pw.Text(
                              '${catItems.length} Records  |  Subtotal: Rs. ${NumberFormat("#,##,###.00").format(catSum)}',
                              style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.amber200),
                            ),
                          ],
                        ),
                      ),
                      pw.TableHelper.fromTextArray(
                        headers: ['#', 'Date', 'Expense Title / Item', 'Payment Mode', 'Notes / Paid To', 'Amount (Rs.)'],
                        data: List<List<dynamic>>.generate(catItems.length, (idx) {
                          final e = catItems[idx];
                          return [
                            (idx + 1).toString(),
                            DateFormat('dd-MM-yyyy').format(e.date),
                            e.title,
                            e.paymentMode,
                            e.notes.isNotEmpty ? e.notes : (e.paidBy.isNotEmpty ? 'To: ${e.paidBy}' : '-'),
                            NumberFormat('#,##,###.00').format(e.amount),
                          ];
                        }),
                        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                        headerStyle: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.blueGrey900),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                        cellStyle: const pw.TextStyle(fontSize: 7),
                        cellAlignments: {
                          0: pw.Alignment.center,
                          1: pw.Alignment.center,
                          2: pw.Alignment.centerLeft,
                          3: pw.Alignment.center,
                          4: pw.Alignment.centerLeft,
                          5: pw.Alignment.centerRight,
                        },
                        headerAlignments: {
                          0: pw.Alignment.center,
                          1: pw.Alignment.center,
                          2: pw.Alignment.centerLeft,
                          3: pw.Alignment.center,
                          4: pw.Alignment.centerLeft,
                          5: pw.Alignment.centerRight,
                        },
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              // Detailed chronological item register
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'DETAILED CHRONOLOGICAL EXPENSES REGISTER',
                  style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.blueGrey900),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['#', 'Date', 'Expense Title', 'Category', 'Mode', 'Notes / Paid To', 'Amount (Rs.)'],
                data: List<List<dynamic>>.generate(expenses.length, (idx) {
                  final e = expenses[idx];
                  return [
                    (idx + 1).toString(),
                    DateFormat('dd-MM-yyyy').format(e.date),
                    e.title,
                    e.category.replaceAll('_', ' '),
                    e.paymentMode,
                    e.notes.isNotEmpty ? e.notes : (e.paidBy.isNotEmpty ? 'To: ${e.paidBy}' : '-'),
                    NumberFormat('#,##,###.00').format(e.amount),
                  ];
                }),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.center,
                  5: pw.Alignment.centerLeft,
                  6: pw.Alignment.centerRight,
                },
                headerAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.center,
                  5: pw.Alignment.centerLeft,
                  6: pw.Alignment.centerRight,
                },
              ),
            ],

            pw.SizedBox(height: 12),

            // Grand Total and Amount in Words Box
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'CUMULATIVE EXPENSES GRAND TOTAL:',
                        style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColors.blueGrey900),
                      ),
                      pw.Text(
                        'Rs. ${NumberFormat("#,##,###.00").format(totalAmount)}',
                        style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.red900),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Text('Amount in Words: ', style: pw.TextStyle(font: fontBold, fontSize: 8)),
                      pw.Expanded(
                        child: pw.Text(
                          amountInWords(totalAmount),
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 22),

            // Signatures Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 4),
                    pw.Text('Prepared By (Operator)', style: pw.TextStyle(font: fontBold, fontSize: 7.5)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 4),
                    pw.Text('Verified By (Supervisor)', style: pw.TextStyle(font: fontBold, fontSize: 7.5)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 4),
                    pw.Text('For, $orgName', style: pw.TextStyle(font: fontBold, fontSize: 7.5)),
                    pw.Text('(Authorised Signatory)', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
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

  /// Exports Expense Report directly to disk and opens in Preview
  static Future<String?> exportAndOpenExpenseReportPdf({
    required List<ExpenseModel> expenses,
    required bool isGroupedByCategory,
    String? companyName,
    String? periodTitle,
    String? searchKeyword,
    Set<String>? activeCategories,
  }) async {
    final pdfBytes = await generateExpenseReportPdf(
      expenses: expenses,
      isGroupedByCategory: isGroupedByCategory,
      companyName: companyName,
      periodTitle: periodTitle,
      searchKeyword: searchKeyword,
      activeCategories: activeCategories,
    );
    final typeName = isGroupedByCategory ? 'Grouped' : 'Itemized';
    final filename = 'Expense_Report_${typeName}_${DateFormat("yyyyMMdd_HHmmss").format(DateTime.now())}.pdf';
    return await _fallbackSaveAndOpenPdf(
      pdfBytes: pdfBytes,
      filename: filename,
    );
  }

  /// Opens native print and PDF preview/save dialog for Expense Report
  static Future<void> printOrPreviewExpenseReportPdf({
    required List<ExpenseModel> expenses,
    required bool isGroupedByCategory,
    String? companyName,
    String? periodTitle,
    String? searchKeyword,
    Set<String>? activeCategories,
  }) async {
    final pdfBytes = await generateExpenseReportPdf(
      expenses: expenses,
      isGroupedByCategory: isGroupedByCategory,
      companyName: companyName,
      periodTitle: periodTitle,
      searchKeyword: searchKeyword,
      activeCategories: activeCategories,
    );
    final typeName = isGroupedByCategory ? 'Grouped' : 'Itemized';
    if (Platform.isMacOS) {
      await _fallbackSaveAndOpenPdf(
        pdfBytes: pdfBytes,
        filename: 'Expense_Report_${typeName}_${DateFormat("yyyyMMdd_HHmmss").format(DateTime.now())}.pdf',
      );
      return;
    }
    try {
      await Printing.layoutPdf(
        name: 'Expense_Report_$typeName',
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (_) {
      await _fallbackSaveAndOpenPdf(
        pdfBytes: pdfBytes,
        filename: 'Expense_Report_${typeName}_${DateFormat("yyyyMMdd_HHmmss").format(DateTime.now())}.pdf',
      );
    }
  }
}
