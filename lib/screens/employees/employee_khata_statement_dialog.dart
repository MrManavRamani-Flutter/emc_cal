import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../core/whatsapp_service.dart';
import '../../models/employee_model.dart';
import '../../models/employee_upad_model.dart';
import '../../providers/production_provider.dart';
import 'add_upad_dialog.dart';
import 'employee_settlement_dialog.dart';
import 'whatsapp_history_dialog.dart';
import '../../widgets/print_slip_dialog.dart';
import '../../widgets/app_snack_bar.dart';

class EmployeeKhataStatementDialog extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeKhataStatementDialog({super.key, required this.employee});

  @override
  State<EmployeeKhataStatementDialog> createState() => _EmployeeKhataStatementDialogState();
}

class _EmployeeKhataStatementDialogState extends State<EmployeeKhataStatementDialog> {
  String _statusFilter = 'All'; // 'All', 'Pending', 'Settled'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddUpad(EmployeeModel employee, double pendingUpad) async {
    final provider = context.read<ProductionProvider>();
    final result = await showDialog<EmployeeUpadModel>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddUpadDialog(
        employees: [employee],
        preselectedEmployee: employee,
        currentPendingUpad: pendingUpad,
      ),
    );

    if (result != null && mounted) {
      await provider.addEmployeeUpad(result);
      if (mounted) {
        final lang = provider.settings.appLanguage;
        AppSnackBar.showSuccess(
          context,
          title: AppStrings.t(lang, en: 'Advance Recorded', gu: 'ઉપાડ નોંધાયો', hi: 'अग्रिम दर्ज हुआ'),
          message: AppStrings.t(lang,
              en: '₹${result.amount.toStringAsFixed(0)} advance recorded successfully!',
              gu: '₹${result.amount.toStringAsFixed(0)} નો ઉપાડ સફળતાપૂર્વક નોંધાયો!',
              hi: '₹${result.amount.toStringAsFixed(0)} का अग्रिम सफलतापूर्वक दर्ज हुआ!'),
        );
      }
    }
  }

  void _openSettlement(EmployeeModel employee, List<EmployeeUpadModel> pendingUpads) async {
    final provider = context.read<ProductionProvider>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EmployeeSettlementDialog(
        employee: employee,
        pendingUpads: pendingUpads,
        onSettleConfirmed: () async {
          if (employee.id != null) {
            await provider.settleEmployeeUpads(employee.id!);
            if (mounted) {
              final lang = provider.settings.appLanguage;
              AppSnackBar.showSuccess(
                context,
                title: AppStrings.t(lang, en: 'Salary Settlement Completed', gu: 'પગાર સેટલમેન્ટ પૂર્ણ', hi: 'वेतन हिसाब पूरा हुआ'),
                message: AppStrings.t(lang,
                    en: 'Salary account settled successfully for ${employee.name}!',
                    gu: '${employee.name} નો પગાર હિસાબ સફળતાપૂર્વક સેટલ થયો!',
                    hi: '${employee.name} का वेतन हिसाब सफलतापूर्वक सेटल हुआ!'),
              );
            }
          }
        },
      ),
    );
  }

  void _sendSingleUpadWhatsApp(EmployeeModel emp, EmployeeUpadModel upad, double pendingUpad) async {
    final provider = context.read<ProductionProvider>();

    final senderPhone = await WhatsAppService.ensureSenderPhone(context, provider);
    if (!mounted || senderPhone == null || senderPhone.isEmpty) return;

    final empPhone = await WhatsAppService.ensureEmployeePhone(context, emp, provider);
    if (!mounted || empPhone == null || empPhone.isEmpty) return;

    final remaining = emp.monthlySalary - pendingUpad;
    final message = WhatsAppService.generateUpadMessage(
      language: provider.settings.whatsappMessageLanguage,
      companyName: provider.settings.companyName,
      employeeName: emp.name,
      role: emp.role,
      gender: emp.gender,
      upadAmount: upad.amount,
      date: DateFormat('dd/MM/yyyy').format(upad.date),
      notes: upad.notes,
      monthlySalary: emp.monthlySalary,
      totalPendingUpad: pendingUpad,
      remainingSalary: remaining,
      senderPhone: senderPhone,
    );

    final launched = await WhatsAppService.launchWhatsAppUrl(recipientPhone: empPhone, message: message);
    if (launched) {
      await provider.logWhatsAppMessage(
        employeeId: emp.id,
        employeeName: emp.name,
        recipientPhone: empPhone,
        senderPhone: senderPhone,
        message: message,
        messageType: 'upad_receipt',
        amount: upad.amount,
      );
    }
    if (mounted && !launched) {
      final lang = provider.settings.appLanguage;
      AppSnackBar.showWarning(
        context,
        title: AppStrings.t(lang, en: 'WhatsApp Offline', gu: 'WhatsApp ઑફલાઇન', hi: 'WhatsApp ऑफलाइन'),
        message: AppStrings.t(lang,
            en: 'Could not open WhatsApp. Receipt copied to clipboard!',
            gu: 'WhatsApp ખોલી શકાયું નથી. રસીદ મેસેજ Clipboard પર કોપી થઈ ગયો છે!',
            hi: 'WhatsApp नहीं खोला जा सका। रसीद संदेश क्लिपबोर्ड पर कॉपी हो गया है!'),
      );
    }
  }

  void _shareStatementWhatsApp(EmployeeModel emp, double pendingUpad, double remainingSalary) async {
    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;

    final senderPhone = await WhatsAppService.ensureSenderPhone(context, provider);
    if (!mounted || senderPhone == null || senderPhone.isEmpty) return;

    final empPhone = await WhatsAppService.ensureEmployeePhone(context, emp, provider);
    if (!mounted || empPhone == null || empPhone.isEmpty) return;

    final company = provider.settings.companyName.trim().isNotEmpty
        ? provider.settings.companyName.trim()
        : 'OM MAVTAR GROUP';
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    String message;
    if (lang == 'gu') {
      final salutation = WhatsAppService.getHindiSalutation(emp.gender, emp.name);
      message = '''
💐 *$company - કર્મચારી પગાર અને ઉપાડ ખાતાવહી પત્રક* 💐
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
*નમસ્તે $salutation,*

તમારા પગાર અને ઉપાડ ખાતાની સંપૂર્ણ વિગતવાર સ્થિતિ નીચે મુજબ છે:

📋 *કર્મચારી વિગત:*
• *નામ:* ${emp.name} (${emp.role})
• *સંબોધન:* ${emp.gender}
• *મોબાઇલ:* ${emp.phone.isEmpty ? 'નોંધાયેલ નથી' : emp.phone}

💰 *ખાતાવહી સારાંશ:*
• *માસિક મૂળ પગાર:* ₹${fmt.format(emp.monthlySalary)}
• *ચાલુ બાકી ઉપાડ:* ₹${fmt.format(pendingUpad)}
• *ચોખ્ખો બાકી પગાર:* ₹${fmt.format(remainingSalary)}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 કોઈપણ પ્રશ્ન અથવા વેરિફિકેશન માટે કૃપા કરીને ઓફિસનો સંપર્ક કરો.
📞 *ઓફિસ સંપર્ક:* $senderPhone
🏢 *$company - એમ્બ્રોઇડરી પ્રોડક્શન મેનેજમેન્ટ*
'''.trim();
    } else if (lang == 'hi') {
      final salutation = WhatsAppService.getHindiSalutation(emp.gender, emp.name);
      message = '''
💐 *$company - कर्मचारी वेतन व उपाड़ खाता विवरण* 💐
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
*नमस्ते $salutation,*

आपके वेतन व उपाड़ खाते की संपूर्ण अद्यतन स्थिति नीचे दी गई है:

📋 *कर्मचारी विवरण:*
• *नाम:* ${emp.name} (${emp.role})
• *संबोधन:* ${emp.gender}
• *मोबाइल:* ${emp.phone.isEmpty ? 'दर्ज नहीं' : emp.phone}

💰 *खाता सारांश:*
• *मासिक मूल वेतन:* ₹${fmt.format(emp.monthlySalary)}
• *वर्तमान बकाया उपाड़:* ₹${fmt.format(pendingUpad)}
• *अनुमानित शेष वेतन:* ₹${fmt.format(remainingSalary)}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 किसी भी प्रश्न या सत्यापन के लिए कृपया व्यवस्थापक से संपर्क करें।
📞 *व्यवस्थापक संपर्क:* $senderPhone
🏢 *$company - कढ़ाई उत्पादन प्रबंधन*
'''.trim();
    } else {
      final engSalutation = WhatsAppService.getEnglishSalutation(emp.gender, emp.name);
      message = '''
💐 *$company - Employee Salary & Advance Account Statement* 💐
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
*Dear $engSalutation,*

Please find below the complete up-to-date statement of your salary and advance account:

📋 *Employee Profile:*
• *Name:* ${emp.name} (${emp.role})
• *Gender:* ${emp.gender}
• *Phone:* ${emp.phone.isEmpty ? 'Not registered' : emp.phone}

💰 *Financial Ledger Summary:*
• *Monthly Base Salary:* ₹${fmt.format(emp.monthlySalary)}
• *Current Outstanding Advance:* ₹${fmt.format(pendingUpad)}
• *Estimated Net Balance:* ₹${fmt.format(remainingSalary)}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 For any query or verification, please contact the administration office.
📞 *Contact:* $senderPhone
🏢 *$company - Embroidery Production Management*
'''.trim();
    }

    final launched = await WhatsAppService.launchWhatsAppUrl(recipientPhone: empPhone, message: message);
    if (launched) {
      await provider.logWhatsAppMessage(
        employeeId: emp.id,
        employeeName: emp.name,
        recipientPhone: empPhone,
        senderPhone: senderPhone,
        message: message,
        messageType: 'statement',
        amount: pendingUpad,
      );
    }
    if (mounted && !launched) {
      AppSnackBar.showWarning(
        context,
        title: AppStrings.t(lang, en: 'WhatsApp Offline', gu: 'WhatsApp ઑફલાઇન', hi: 'WhatsApp ऑफलाइन'),
        message: AppStrings.t(lang,
            en: 'Could not open WhatsApp. Statement message copied to clipboard!',
            gu: 'WhatsApp ખોલી શકાયું નથી. ખાતાવહી મેસેજ Clipboard પર કોપી થઈ ગયો છે!',
            hi: 'WhatsApp नहीं खोला जा सका। विवरण संदेश क्लिपबोर्ड पर कॉपी हो गया है!'),
      );
    }
  }

  void _printSingleUpadSlip(EmployeeModel emp, EmployeeUpadModel upad, double totalPendingUpad) {
    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final remaining = emp.monthlySalary - totalPendingUpad;
    final data = PrintSlipData(
      title: AppStrings.t(lang, en: 'Advance Voucher', gu: 'ઉપાડ પાવતી', hi: 'उपाड वाउचर'),
      voucherNo: 'UPD-${upad.id ?? DateTime.now().millisecondsSinceEpoch % 10000}',
      dateTime: upad.date,
      companyName: provider.settings.companyName.isEmpty ? 'OM MAVTAR GROUP' : provider.settings.companyName,
      employeeName: emp.name,
      employeeId: emp.id,
      role: emp.role,
      phone: emp.phone,
      monthlySalary: emp.monthlySalary,
      currentAmount: upad.amount,
      totalPendingUpad: totalPendingUpad,
      netPayable: remaining,
      notes: upad.notes,
      voucherType: 'advance',
      isOverdraft: remaining < 0,
    );
    PrintSlipDialog.show(context, data);
  }

  void _printKhataStatementSlip(EmployeeModel emp, List<EmployeeUpadModel> statementList, double totalPendingUpad, double remainingSalary) {
    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final summaryNotes = '${AppStrings.t(lang, en: 'Total entries', gu: 'કુલ એન્ટ્રીઓ', hi: 'कुल प्रविष्टियाँ')}: ${statementList.length} | ${AppStrings.t(lang, en: 'Pending Advance', gu: 'પેન્ડિંગ ઉપાડ', hi: 'बकाया उपाड')}: ₹${totalPendingUpad.toStringAsFixed(0)} | ${AppStrings.t(lang, en: 'Remaining Salary', gu: 'બાકી પગાર', hi: 'शेष वेतन')}: ₹${remainingSalary.toStringAsFixed(0)}';
    final data = PrintSlipData(
      title: AppStrings.t(lang, en: 'Statement Voucher', gu: 'ખાતાવહી સ્ટેટમેન્ટ પાવતી', hi: 'खाताबही विवरण वाउचर'),
      voucherNo: 'STMT-${emp.id ?? 1}-${DateFormat('MMyy').format(DateTime.now())}',
      dateTime: DateTime.now(),
      companyName: provider.settings.companyName.isEmpty ? 'OM MAVTAR GROUP' : provider.settings.companyName,
      employeeName: emp.name,
      employeeId: emp.id,
      role: emp.role,
      phone: emp.phone,
      monthlySalary: emp.monthlySalary,
      currentAmount: totalPendingUpad,
      totalPendingUpad: totalPendingUpad,
      netPayable: remainingSalary,
      notes: summaryNotes,
      voucherType: 'statement',
      isOverdraft: remainingSalary < 0,
    );
    PrintSlipDialog.show(context, data);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    // Fetch latest instance of employee from provider if updated
    final emp = provider.employees.firstWhere(
      (e) => e.id == widget.employee.id,
      orElse: () => widget.employee,
    );

    final allUpads = emp.id != null ? provider.getUpadsForEmployee(emp.id!) : <EmployeeUpadModel>[];
    allUpads.sort((a, b) => b.date.compareTo(a.date)); // Most recent first

    final allTimeUpad = emp.id != null ? provider.getEmployeeAllTimeTotalUpad(emp.id!) : 0.0;
    final settledUpad = emp.id != null ? provider.getEmployeeSettledUpad(emp.id!) : 0.0;
    final pendingUpad = emp.id != null ? provider.getEmployeeTotalUpad(emp.id!, unsettledOnly: true) : 0.0;
    final remainingSalary = provider.getEmployeeRemainingSalary(emp);
    final pendingUpadsList = allUpads.where((u) => !u.isSettled).toList();

    // Filtered upads
    final filteredUpads = allUpads.where((u) {
      if (_statusFilter == 'Pending' && u.isSettled) return false;
      if (_statusFilter == 'Settled' && !u.isSettled) return false;
      if (_searchController.text.trim().isNotEmpty) {
        final q = _searchController.text.trim().toLowerCase();
        final matchNotes = u.notes.toLowerCase().contains(q);
        final matchAmt = u.amount.toString().contains(q);
        if (!matchNotes && !matchAmt) return false;
      }
      return true;
    }).toList();

    final isOverdrawn = (emp.monthlySalary - pendingUpad) < 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 960,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'E',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              emp.name,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF818CF8)),
                              ),
                              child: Text(
                                emp.role,
                                style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: emp.isActive
                                    ? const Color(0xFF059669).withValues(alpha: 0.2)
                                    : const Color(0xFFDC2626).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                emp.isActive
                                    ? AppStrings.t(lang, en: 'Active', gu: 'સક્રિય', hi: 'सक्रिय')
                                    : AppStrings.t(lang, en: 'Inactive', gu: 'છૂટા થયેલ', hi: 'निष्क्रिय'),
                                style: TextStyle(
                                  color: emp.isActive ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${AppStrings.t(lang, en: 'Phone', gu: 'ફોન', hi: 'फोन')}: ${emp.phone.isEmpty ? AppStrings.t(lang, en: 'N/A', gu: 'નથી', hi: 'नहीं') : emp.phone} | ${AppStrings.t(lang, en: 'Joining Date', gu: 'જોઈનિંગ તારીખ', hi: 'कार्यग्रहण तिथि')}: ${DateFormat('dd-MM-yyyy').format(emp.joiningDate)}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Financial Summary Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  _summaryPill(
                    label: AppStrings.t(lang, en: 'Monthly Base Salary', gu: 'માસિક ફિક્સ પગાર', hi: 'मासिक मूल वेतन'),
                    amount: emp.monthlySalary,
                    color: const Color(0xFF2563EB),
                    icon: Icons.payments_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _summaryPill(
                    label: AppStrings.t(lang, en: 'All-Time Total Advance', gu: 'કુલ ઐતિહાસિક ઉપાડ', hi: 'कुल ऐतिहासिक उपाड'),
                    amount: allTimeUpad,
                    color: const Color(0xFF7C3AED),
                    icon: Icons.history_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _summaryPill(
                    label: AppStrings.t(lang, en: 'Previously Settled', gu: 'અગાઉ સેટલ થયેલ', hi: 'पूर्व में सेटल'),
                    amount: settledUpad,
                    color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B),
                    icon: Icons.check_circle_outline_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _summaryPill(
                    label: AppStrings.t(lang, en: 'Current Pending Advance', gu: 'ચાલુ પેન્ડિંગ ઉપાડ', hi: 'चालू बकाया उपाड'),
                    amount: pendingUpad,
                    color: const Color(0xFFD97706),
                    icon: Icons.pending_actions_rounded,
                    isWarning: pendingUpad > 0,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _summaryPill(
                    label: isOverdrawn
                        ? AppStrings.t(lang, en: 'Excess Advance', gu: 'વધારાનો ઉપાડ', hi: 'अतिरिक्त उपाड')
                        : AppStrings.t(lang, en: 'Net Remaining Salary', gu: 'ચોખ્ખો બાકી પગાર', hi: 'शुद्ध शेष वेतन'),
                    amount: isOverdrawn ? (pendingUpad - emp.monthlySalary) : remainingSalary,
                    color: isOverdrawn ? const Color(0xFFDC2626) : const Color(0xFF059669),
                    icon: isOverdrawn ? Icons.warning_rounded : Icons.account_balance_wallet_rounded,
                    isHighlight: true,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            Divider(height: 1, thickness: 1, color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),

            // Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Text(
                    AppStrings.t(lang, en: 'Advance Ledger:', gu: 'ઉપાડ હિસાબ પત્રક:', hi: 'उपाड हिसाब बही:'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Filter Chips
                  _statusFilterChip('${AppStrings.t(lang, en: 'All', gu: 'તમામ', hi: 'सभी')} (${allUpads.length})', 'All', null, isDark),
                  const SizedBox(width: 6),
                  _statusFilterChip('${AppStrings.t(lang, en: 'Pending', gu: 'ચાલુ પેન્ડિંગ', hi: 'चालू बकाया')} (${allUpads.where((u) => !u.isSettled).length})', 'Pending', const Color(0xFFD97706), isDark),
                  const SizedBox(width: 6),
                  _statusFilterChip('${AppStrings.t(lang, en: 'Settled', gu: 'સેટલ થયેલ', hi: 'सेटल')} (${allUpads.where((u) => u.isSettled).length})', 'Settled', const Color(0xFF059669), isDark),
                  const Spacer(),
                  // Search
                  SizedBox(
                    width: 220,
                    height: 38,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: AppStrings.t(lang, en: 'Search note or amount...', gu: 'નોંધ અથવા રકમ શોધો...', hi: 'नोट या राशि खोजें...'),
                        hintStyle: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.search_rounded, size: 16, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Ledger Table
            Expanded(
              child: filteredUpads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: isDark ? AppTheme.darkBorder : Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            allUpads.isEmpty
                                ? AppStrings.t(
                                    lang,
                                    en: 'No advance records found for this employee.',
                                    gu: 'આ કર્મચારી માટે કોઈ ઉપાડ નોંધાયેલ નથી.',
                                    hi: 'इस कर्मचारी के लिए कोई अग्रिम रिकॉर्ड नहीं मिला।',
                                  )
                                : AppStrings.t(
                                    lang,
                                    en: 'No records match the filter.',
                                    gu: 'ફિલ્ટર મુજબ કોઈ રેકોર્ડ મળ્યો નથી.',
                                    hi: 'फ़िल्टर के अनुसार कोई रिकॉर्ड नहीं मिला।',
                                  ),
                            style: TextStyle(color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9)),
                            headingTextStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF334155),
                            ),
                            dataRowMinHeight: 48,
                            dataRowMaxHeight: 52,
                            horizontalMargin: 16,
                            columnSpacing: 20,
                            columns: [
                              const DataColumn(label: Text('#')),
                              DataColumn(label: Text(AppStrings.t(lang, en: 'Date', gu: 'તારીખ', hi: 'तारीख'))),
                              DataColumn(label: Text(AppStrings.t(lang, en: 'Advance Amount (₹)', gu: 'ઉપાડ રકમ (₹)', hi: 'अग्रिम राशि (₹)'))),
                              DataColumn(label: Text(AppStrings.t(lang, en: 'Notes / Reason', gu: 'વિગત / કારણ', hi: 'विवरण / कारण'))),
                              DataColumn(label: Text(AppStrings.t(lang, en: 'Status', gu: 'સ્થિતિ', hi: 'स्थिति'))),
                              DataColumn(label: Text(AppStrings.t(lang, en: 'Action', gu: 'એક્શન', hi: 'एक्शन'))),
                            ],
                            rows: filteredUpads.asMap().entries.map((entry) {
                              final index = entry.key;
                              final upad = entry.value;

                              return DataRow(
                                color: WidgetStateProperty.resolveWith<Color?>((states) {
                                  if (index.isOdd) {
                                    return isDark
                                        ? AppTheme.darkSurfaceSubtle.withValues(alpha: 0.6)
                                        : const Color(0xFFF8FAFC);
                                  }
                                  return null;
                                }),
                                cells: [
                                  DataCell(Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                                    ),
                                  )),
                                  DataCell(Text(
                                    DateFormat('dd-MM-yyyy').format(upad.date),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF334155),
                                    ),
                                  )),
                                  DataCell(
                                    Text(
                                      '₹${upad.amount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      upad.notes.isEmpty ? '—' : upad.notes,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? AppTheme.darkTextMuted : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: upad.isSettled
                                            ? const Color(0xFF059669).withValues(alpha: 0.15)
                                            : const Color(0xFFD97706).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: upad.isSettled ? const Color(0xFF059669) : const Color(0xFFD97706),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        upad.isSettled
                                            ? AppStrings.t(lang, en: 'Settled', gu: 'ચૂકતે', hi: 'निपटारा')
                                            : AppStrings.t(lang, en: 'Pending', gu: 'ચાલુ પેન્ડિંગ', hi: 'बकाया'),
                                        style: TextStyle(
                                          color: upad.isSettled ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.print_rounded, size: 19, color: Color(0xFF6366F1)),
                                          tooltip: AppStrings.t(lang, en: 'Print Advance Slip', gu: 'ઉપાડ સ્લિપ પ્રિન્ટ કરો', hi: 'अग्रिम पर्ची प्रिंट करें'),
                                          onPressed: () => _printSingleUpadSlip(emp, upad, pendingUpad),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chat_bubble_rounded, size: 19, color: Color(0xFF25D366)),
                                          tooltip: AppStrings.t(lang, en: 'Send Receipt on WhatsApp', gu: 'WhatsApp પર રસીદ મોકલો', hi: 'WhatsApp पर रसीद भेजें'),
                                          onPressed: () => _sendSingleUpadWhatsApp(emp, upad, pendingUpad),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                          tooltip: AppStrings.t(lang, en: 'Delete Advance', gu: 'ઉપાડ ડિલીટ કરો', hi: 'अग्रिम हटाएं'),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                title: Text(
                                                  AppStrings.t(lang, en: 'Delete Advance Record?', gu: 'ઉપાડ રદ કરો', hi: 'अग्रिम रद्द करें?'),
                                                  style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                                                ),
                                                content: Text(
                                                  AppStrings.t(
                                                    lang,
                                                    en: 'Do you want to move ₹${upad.amount.toStringAsFixed(0)} advance to Recycle Bin?',
                                                    gu: 'શું તમે ₹${upad.amount.toStringAsFixed(0)} નો ઉપાડ રીસાયકલ બિનમાં મોકલવા માંગો છો?',
                                                    hi: 'क्या आप ₹${upad.amount.toStringAsFixed(0)} का अग्रिम रीसायकल बिन में भेजना चाहते हैं?',
                                                  ),
                                                  style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(ctx).pop(false),
                                                    child: Text(
                                                      AppStrings.t(lang, en: 'Cancel', gu: 'ના', hi: 'नहीं'),
                                                      style: TextStyle(color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                                                    onPressed: () => Navigator.of(ctx).pop(true),
                                                    child: Text(AppStrings.t(lang, en: 'Yes, Delete', gu: 'હા, રદ કરો', hi: 'हाँ, हटाएं')),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true && upad.id != null) {
                                              await provider.deleteEmployeeUpad(upad.id!);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),

            // Footer Actions Bar (Responsive & Fits without overflow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? AppTheme.darkTextPrimary : const Color(0xFF475569),
                          side: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: Text(AppStrings.t(lang, en: 'Close', gu: 'બંધ કરો', hi: 'बंद करें')),
                      ),
                      const SizedBox(width: 8),
                      // Employee Message History Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                          side: BorderSide(color: isDark ? const Color(0xFF6366F1).withValues(alpha: 0.5) : const Color(0xFF93C5FD)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => WhatsAppHistoryDialog(initialEmployeeId: emp.id),
                          );
                        },
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: Text(AppStrings.t(lang, en: 'Message History', gu: 'મેસેજ હિસ્ટ્રી', hi: 'मैसेज हिस्ट्री')),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Print Statement Slip Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                          side: BorderSide(color: isDark ? const Color(0xFF6366F1).withValues(alpha: 0.5) : const Color(0xFF818CF8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onPressed: () => _printKhataStatementSlip(emp, filteredUpads, pendingUpad, remainingSalary),
                        icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF6366F1), size: 16),
                        label: Text(AppStrings.t(lang, en: 'Print Statement', gu: 'સ્લિપ પ્રિન્ટ', hi: 'पर्ची प्रिंट')),
                      ),
                      const SizedBox(width: 8),
                      // WhatsApp Statement Share Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: BorderSide(color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFF25D366)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onPressed: () => _shareStatementWhatsApp(emp, pendingUpad, remainingSalary),
                        icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 16),
                        label: Text(AppStrings.t(lang, en: 'WhatsApp Statement', gu: 'WhatsApp ખાતાવહી', hi: 'WhatsApp खाता')),
                      ),
                      const SizedBox(width: 8),
                      // Add Upad Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF59E0B),
                          side: BorderSide(color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.5) : const Color(0xFFD97706)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onPressed: () => _openAddUpad(emp, pendingUpad),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(AppStrings.t(lang, en: 'Add Advance', gu: 'ઉપાડ નોંધો', hi: 'अग्रिम जोड़ें')),
                      ),
                      const SizedBox(width: 8),
                      // Settle Salary Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () => _openSettlement(emp, pendingUpadsList),
                        icon: const Icon(Icons.price_check_rounded, size: 18),
                        label: Text(AppStrings.t(lang, en: 'Settle Salary', gu: 'પગાર હિસાબ સેટલ', hi: 'वेतन निपटारा')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryPill({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    bool isWarning = false,
    bool isHighlight = false,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlight
              ? color
              : (isDark ? AppTheme.darkCardBg : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlight
                ? color
                : (isWarning
                    ? const Color(0xFFFBBF24)
                    : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
            width: isHighlight || isWarning ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isHighlight
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: isHighlight ? Colors.white : color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isHighlight
                          ? Colors.white70
                          : (isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isHighlight ? Colors.white : (isDark ? AppTheme.darkTextPrimary : color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusFilterChip(String label, String value, Color? color, bool isDark) {
    final isSelected = _statusFilter == value;
    final activeColor = color ?? const Color(0xFF4F46E5);

    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
