import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/localization/app_strings.dart';
import '../providers/production_provider.dart';
import 'app_svg_icon.dart';

/// Data model representing a printable voucher / slip
class PrintSlipData {
  final String title;
  final String voucherNo;
  final DateTime dateTime;
  final String companyName;
  final String companyAddress;
  final String employeeName;
  final int? employeeId;
  final String role;
  final String phone;
  final double monthlySalary;
  final double currentAmount;
  final double totalPendingUpad;
  final double netPayable;
  final String notes;
  final String voucherType; // 'advance', 'settlement', 'statement'
  final bool isOverdraft;

  PrintSlipData({
    required this.title,
    required this.voucherNo,
    required this.dateTime,
    this.companyName = 'OM MAVTAR GROUP',
    this.companyAddress = 'Embroidery Jobwork • Surat, Gujarat',
    required this.employeeName,
    this.employeeId,
    required this.role,
    this.phone = '',
    required this.monthlySalary,
    required this.currentAmount,
    required this.totalPendingUpad,
    required this.netPayable,
    this.notes = '',
    this.voucherType = 'advance',
    this.isOverdraft = false,
  });
}

/// Dialog to preview, print (Thermal 80mm or A4), and copy physical vouchers
class PrintSlipDialog extends StatelessWidget {
  final PrintSlipData data;

  const PrintSlipDialog({super.key, required this.data});

  static Future<void> show(BuildContext context, PrintSlipData data) {
    return showDialog(
      context: context,
      builder: (ctx) => PrintSlipDialog(data: data),
    );
  }

  static String generateTextReceipt(PrintSlipData d) {
    final currencyFmt = NumberFormat('#,##,##0.00', 'en_IN');
    final dateStr = DateFormat('dd-MM-yyyy hh:mm a').format(d.dateTime);

    return '''
========================================
       ${d.companyName.toUpperCase()}
   ${d.companyAddress}
========================================
VAUCHER NO: ${d.voucherNo}
DATE & TIME: $dateStr
TITLE: ${d.title}
----------------------------------------
WORKER DETAILS:
Name: ${d.employeeName} (${d.role})
Employee ID: #${d.employeeId ?? 100}
Phone: ${d.phone.isNotEmpty ? d.phone : 'N/A'}
----------------------------------------
FINANCIAL BREAKDOWN:
• Base Monthly Salary: ₹${currencyFmt.format(d.monthlySalary)}
• Current Amount:     ₹${currencyFmt.format(d.currentAmount)}
• Total Advance:       ₹${currencyFmt.format(d.totalPendingUpad)}
• Net Remaining / Pay: ₹${currencyFmt.format(d.netPayable)}
${d.notes.isNotEmpty ? '• Notes / Reason:      ${d.notes}\n' : ''}----------------------------------------
${d.isOverdraft ? 'NOTICE: Excess Advance carried forward to next month.\n----------------------------------------\n' : ''}
SIGNATURES:


____________________      ____________________
Worker Sign / Thumb        Authorized Manager
========================================
     THANK YOU • OM MAVTAR GROUP
========================================
'''.trim();
  }

  static String generateHtmlReceipt(PrintSlipData d, [String lang = 'en']) {
    final currencyFmt = NumberFormat('#,##,##0.00', 'en_IN');
    final dateStr = DateFormat('dd-MM-yyyy hh:mm a').format(d.dateTime);

    return '''
<!DOCTYPE html>
<html lang="$lang">
<head>
  <meta charset="UTF-8">
  <title>${d.voucherNo} - ${d.companyName}</title>
  <style>
    @media print {
      body { margin: 0; padding: 0; }
      .no-print { display: none !important; }
    }
    body {
      font-family: 'Courier New', Courier, monospace, system-ui;
      background: #f1f5f9;
      color: #0f172a;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 20px;
    }
    .slip {
      background: #ffffff;
      width: 320px;
      padding: 16px 20px;
      border: 1px dashed #94a3b8;
      box-shadow: 0 4px 12px rgba(0,0,0,0.08);
      border-radius: 4px;
    }
    .center { text-align: center; }
    .company { font-size: 17px; font-weight: 900; letter-spacing: 0.5px; }
    .subhead { font-size: 11px; color: #475569; margin-bottom: 6px; }
    .divider { border-top: 1px dashed #64748b; margin: 8px 0; }
    .title-badge {
      display: inline-block;
      font-size: 11px;
      font-weight: bold;
      background: #e2e8f0;
      padding: 3px 8px;
      border-radius: 4px;
      margin: 4px 0;
    }
    .row { display: flex; justify-content: space-between; font-size: 12px; margin: 4px 0; }
    .bold { font-weight: bold; }
    .highlight {
      background: #f8fafc;
      border: 1px solid #cbd5e1;
      padding: 6px;
      margin: 8px 0;
      border-radius: 4px;
    }
    .sign-row { display: flex; justify-content: space-between; margin-top: 36px; font-size: 10.5px; }
    .sign-box { text-align: center; width: 45%; border-top: 1px solid #000; padding-top: 4px; }
    .actions { margin-top: 20px; display: flex; gap: 10px; }
    .btn {
      background: #0066FF;
      color: white;
      border: none;
      padding: 10px 18px;
      font-weight: bold;
      border-radius: 6px;
      cursor: pointer;
      font-size: 13px;
    }
    .btn:hover { background: #0052cc; }
  </style>
  <script>
    window.onload = function() {
      // Auto trigger print when loaded in browser
      setTimeout(function() { window.print(); }, 400);
    };
  </script>
</head>
<body>
  <div class="slip">
    <div class="center">
      <div class="company">${d.companyName}</div>
      <div class="subhead">${d.companyAddress}</div>
      <div class="title-badge">${d.title}</div>
    </div>
    <div class="divider"></div>
    <div class="row"><span>Voucher No:</span><span class="bold">${d.voucherNo}</span></div>
    <div class="row"><span>Date & Time:</span><span>$dateStr</span></div>
    <div class="divider"></div>
    <div class="row"><span>Worker:</span><span class="bold">${d.employeeName}</span></div>
    <div class="row"><span>Role:</span><span>${d.role}</span></div>
    <div class="row"><span>Employee ID:</span><span>#${d.employeeId ?? 100}</span></div>
    ${d.phone.isNotEmpty ? '<div class="row"><span>Phone:</span><span>${d.phone}</span></div>' : ''}
    <div class="divider"></div>
    <div class="row"><span>Monthly Base Salary:</span><span class="bold">₹${currencyFmt.format(d.monthlySalary)}</span></div>
    <div class="row"><span>Current Amount:</span><span class="bold">₹${currencyFmt.format(d.currentAmount)}</span></div>
    <div class="row"><span>Total Pending Advance:</span><span>₹${currencyFmt.format(d.totalPendingUpad)}</span></div>
    <div class="highlight">
      <div class="row"><span class="bold">Net Hand Balance:</span><span class="bold" style="font-size:14px; color:#059669;">₹${currencyFmt.format(d.netPayable)}</span></div>
    </div>
    ${d.notes.isNotEmpty ? '<div style="font-size:11px; margin:4px 0;"><strong>Notes:</strong> ${d.notes}</div>' : ''}
    ${d.isOverdraft ? '<div style="font-size:10.5px; color:#dc2626; margin:4px 0; font-weight:bold;">* Advance exceeded salary. Remaining carry-forwarded to next month.</div>' : ''}
    <div class="sign-row">
      <div class="sign-box">${lang == 'gu' ? 'કારીગર સહી / અંગૂઠો' : (lang == 'hi' ? 'कारीगर हस्ताक्षर / अंगूठा' : 'Worker Sign / Thumb')}</div>
      <div class="sign-box">${lang == 'gu' ? 'ઓથોરાઇઝ્ડ મેનેજર સહી' : (lang == 'hi' ? 'अधिकृत व्यवस्थापक हस्ताक्षर' : 'Authorized Manager')}</div>
    </div>
    <div class="divider"></div>
    <div class="center" style="font-size:9.5px; color:#64748b;">
      System Generated Voucher • OM MAVTAR GROUP
    </div>
  </div>

  <div class="actions no-print">
    <button class="btn" onclick="window.print()">${lang == 'gu' ? 'પ્રિન્ટ કરો' : (lang == 'hi' ? 'प्रिंट करें' : 'Print Slip')}</button>
    <button class="btn" style="background:#64748b;" onclick="window.close()">${lang == 'gu' ? 'બંધ કરો' : (lang == 'hi' ? 'बंद करें' : 'Close')}</button>
  </div>
</body>
</html>
'''.trim();
  }

  Future<void> _handlePrint(BuildContext context) async {
    final lang = context.read<ProductionProvider>().settings.appLanguage;
    try {
      final tempDir = await getTemporaryDirectory();
      final slipFile = File('${tempDir.path}/OM_MAVTAR_SLIP_${data.voucherNo}.html');
      await slipFile.writeAsString(generateHtmlReceipt(data, lang));
      final uri = Uri.file(slipFile.path);

      await launchUrl(uri);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(
                lang,
                en: 'Print voucher opened in browser. Select your printer to print.',
                gu: 'પ્રિન્ટ વાઉચર બ્રાઉઝરમાં ખૂલ્યું છે. પ્રિન્ટર પસંદ કરી પ્રિન્ટ કરો.',
                hi: 'प्रिंट वाउचर ब्राउज़र में खुल गया है। प्रिंटर चुनकर प्रिंट करें।',
              ),
            ),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.t(lang, en: 'Print error:', gu: 'પ્રિન્ટ એરર:', hi: 'प्रिंट त्रुटि:')} $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  void _handleCopyText(BuildContext context) {
    final lang = context.read<ProductionProvider>().settings.appLanguage;
    Clipboard.setData(ClipboardData(text: generateTextReceipt(data)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.t(
            lang,
            en: 'Full slip text receipt copied to clipboard!',
            gu: 'સ્લિપની સંપૂર્ણ ટેક્સ્ટ રસીદ ક્લિપબોર્ડ પર કોપી થઈ ગઈ છે!',
            hi: 'पर्ची की पूरी रसीद क्लिपबोर्ड पर कॉपी हो गई है!',
          ),
        ),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<ProductionProvider>().settings.appLanguage;
    final isDark = AppTheme.isDark(context);
    final cardBg = isDark ? AppTheme.darkCardBg : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A);
    final textSecondary = isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569);
    final textMuted = isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B);
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1);
    final currencyFmt = NumberFormat('#,##,##0.00', 'en_IN');
    final dateStr = DateFormat('dd-MM-yyyy hh:mm a').format(data.dateTime);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 720),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AppSvgIcon.printIcon(size: 18, color: const Color(0xFFDC2626)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.t(
                        lang,
                        en: 'Physical Voucher / Slip Preview',
                        gu: 'ફિઝિકલ વાઉચર / સ્લિપ પ્રીવ્યુ',
                        hi: 'भौतिक वाउचर / पर्ची पूर्वावलोकन',
                      ),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Paper Slip Visual Preview
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Thermal Header
                      Center(
                        child: Column(
                          children: [
                            Text(
                              data.companyName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.companyAddress,
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                data.title,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _dottedDivider(isDark),
                      const SizedBox(height: 6),

                      // Meta details
                      _slipRow(AppStrings.t(lang, en: 'Voucher No:', gu: 'વાઉચર નંબર:', hi: 'वाउचर नंबर:'), data.voucherNo, textPrimary, textMuted, boldVal: true),
                      _slipRow(AppStrings.t(lang, en: 'Date & Time:', gu: 'તારીખ & સમય:', hi: 'दिनांक और समय:'), dateStr, textPrimary, textMuted),
                      _slipRow(AppStrings.t(lang, en: 'Employee:', gu: 'કર્મચારી:', hi: 'कर्मचारी:'), data.employeeName, textPrimary, textMuted, boldVal: true),
                      _slipRow(AppStrings.t(lang, en: 'Role:', gu: 'પદવી / રોલ:', hi: 'पद / भूमिका:'), data.role, textPrimary, textMuted),
                      _slipRow(AppStrings.t(lang, en: 'Employee ID:', gu: 'કર્મચારી ID:', hi: 'कर्मचारी ID:'), '#${data.employeeId ?? 100}', textPrimary, textMuted),
                      if (data.phone.isNotEmpty) _slipRow(AppStrings.t(lang, en: 'Mobile:', gu: 'મોબાઈલ:', hi: 'मोबाइल:'), data.phone, textPrimary, textMuted),

                      const SizedBox(height: 6),
                      _dottedDivider(isDark),
                      const SizedBox(height: 6),

                      // Financial details
                      _slipRow(AppStrings.t(lang, en: 'Base Monthly Salary:', gu: 'માસિક મૂળ પગાર:', hi: 'मासिक मूल वेतन:'), '₹${currencyFmt.format(data.monthlySalary)}', textPrimary, textMuted),
                      _slipRow(
                        data.voucherType == 'settlement'
                            ? AppStrings.t(lang, en: 'Advance Deducted:', gu: 'આ મહિને આપેલ ઉપાડ:', hi: 'इस माह का अग्रिम:')
                            : AppStrings.t(lang, en: "Today's Advance:", gu: 'આજનો ઉપાડ:', hi: 'आज का अग्रिम:'),
                        '₹${currencyFmt.format(data.currentAmount)}',
                        const Color(0xFFD97706),
                        textMuted,
                        boldVal: true,
                      ),
                      _slipRow(AppStrings.t(lang, en: 'Total Pending Advance:', gu: 'કુલ બાકી ઉપાડ:', hi: 'कुल बकाया अग्रिम:'), '₹${currencyFmt.format(data.totalPendingUpad)}', textPrimary, textMuted),

                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              data.voucherType == 'settlement'
                                  ? AppStrings.t(lang, en: 'Net Salary Paid in Hand:', gu: 'હાથમાં ચૂકવેલ ચોખ્ખો પગાર:', hi: 'हाथ में शुद्ध भुगतान वेतन:')
                                  : AppStrings.t(lang, en: 'Estimated Remaining Salary:', gu: 'અંદાજિત બાકી પગાર:', hi: 'अनुमानित शेष वेतन:'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                              ),
                            ),
                            Text(
                              '₹${currencyFmt.format(data.netPayable)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (data.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${AppStrings.t(lang, en: 'Notes / Reason:', gu: 'નોંધ / વિગત:', hi: 'टिप्पणी / विवरण:')} ${data.notes}',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: textSecondary),
                        ),
                      ],

                      if (data.isOverdraft) ...[
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.t(
                            lang,
                            en: '* Advance exceeded salary. Remaining balance will carry forward to next month.',
                            gu: '* પગાર કરતાં વધુ ઉપાડ હોવાથી બાકી રકમ આવતા મહિનાના ખાતામાં આપમેળે ટ્રાન્સફર થશે.',
                            hi: '* वेतन से अधिक अग्रिम होने के कारण शेष राशि अगले महीने के खाते में स्वतः स्थानांतरित हो जाएगी।',
                          ),
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Signature lines
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Container(width: 120, height: 1, color: isDark ? Colors.white38 : Colors.black45),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.t(lang, en: 'Worker Sign / Thumb', gu: 'કારીગર સહી / અંગૂઠો', hi: 'कारीगर हस्ताक्षर / अंगूठा'),
                                style: TextStyle(fontSize: 10, color: textMuted),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Container(width: 120, height: 1, color: isDark ? Colors.white38 : Colors.black45),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.t(lang, en: 'Authorized Manager Sign', gu: 'ઓથોરાઇઝ્ડ મેનેજર સહી', hi: 'अधिकृत व्यवस्थापक हस्ताक्षर'),
                                style: TextStyle(fontSize: 10, color: textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _dottedDivider(isDark),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'OM MAVTAR GROUP • 100% Computerized Slip',
                          style: TextStyle(fontSize: 9.5, color: textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(
                      AppStrings.t(lang, en: 'Copy Text', gu: 'ટેક્સ્ટ કોપી કરો', hi: 'टेक्स्ट कॉपी करें'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _handleCopyText(context),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: Text(
                      AppStrings.t(lang, en: 'Print Voucher', gu: 'પ્રિન્ટ વાઉચર', hi: 'वाउचर प्रिंट करें'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _handlePrint(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _slipRow(String label, String value, Color textPrimary, Color textMuted, {bool boldVal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, color: textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: boldVal ? FontWeight.bold : FontWeight.w500,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _dottedDivider(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.constrainWidth() / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => Text('-', style: TextStyle(color: isDark ? Colors.white30 : Colors.black26, fontSize: 11)),
          ),
        );
      },
    );
  }
}
