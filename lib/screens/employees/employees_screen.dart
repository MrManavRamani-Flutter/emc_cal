import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/whatsapp_service.dart';
import '../../models/employee_model.dart';
import '../../models/employee_upad_model.dart';
import '../../providers/production_provider.dart';
import 'add_edit_employee_dialog.dart';
import 'add_upad_dialog.dart';
import 'employee_khata_statement_dialog.dart';
import 'employee_settlement_dialog.dart';
import 'manage_roles_dialog.dart';
import 'whatsapp_history_dialog.dart';
import '../../widgets/app_snack_bar.dart';
import '../../core/localization/app_strings.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _upadSearchController = TextEditingController();

  // Active view tab: 0 = Employee Directory / Cards, 1 = Master Payroll & Upad Register, 2 = All Upads History & Ledger
  int _activeViewTab = 0;

  // Filters for Tab 2 (All Upads History)
  int? _upadEmployeeFilter; // null = all
  String _upadStatusFilter = 'All'; // 'All', 'Pending', 'Settled'
  DateTime? _upadFromDate;
  DateTime? _upadToDate;

  // Sorting state for Master Register & Upad Ledger
  int _empSortColumnIndex = 1;
  bool _empSortAscending = true;
  int _upadSortColumnIndex = 1;
  bool _upadSortAscending = false;

  @override
  void dispose() {
    _searchController.dispose();
    _upadSearchController.dispose();
    super.dispose();
  }

  void _openAddEmployeeDialog([EmployeeModel? employee]) async {
    final result = await showDialog<EmployeeModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditEmployeeDialog(employee: employee),
    );

    if (result != null && mounted) {
      final provider = context.read<ProductionProvider>();
      final lang = provider.settings.appLanguage;
      if (employee == null) {
        await provider.addEmployee(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.t(lang,
                    en: 'Employee "${result.name}" added successfully!',
                    gu: 'કર્મચારી "${result.name}" સફળતાપૂર્વક ઉમેરાયા!',
                    hi: 'कर्मचारी "${result.name}" सफलतापूर्वक जोड़ा गया!'),
              ),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        }
      } else {
        await provider.updateEmployee(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.t(lang,
                    en: 'Employee "${result.name}" updated successfully!',
                    gu: 'કર્મચારી "${result.name}" ની વિગત અપડેટ થઈ!',
                    hi: 'कर्मचारी "${result.name}" का विवरण अपडेट हो गया!'),
              ),
              backgroundColor: const Color(0xFF2563EB),
            ),
          );
        }
      }
    }
  }

  void _openAddUpadDialog([EmployeeModel? preselected]) async {
    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    if (provider.employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.t(lang,
                en: 'Please add an employee first',
                gu: 'પહેલાં કર્મચારી ઉમેરો',
                hi: 'कृपया पहले एक कर्मचारी जोड़ें'),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    final targetEmp = preselected ?? provider.employees.first;
    final currentUpad = targetEmp.id != null
        ? provider.getEmployeeTotalUpad(targetEmp.id!, unsettledOnly: true)
        : 0.0;

    final result = await showDialog<EmployeeUpadModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddUpadDialog(
        employees: provider.employees,
        preselectedEmployee: preselected,
        currentPendingUpad: currentUpad,
      ),
    );

    if (result != null && mounted) {
      await provider.addEmployeeUpad(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(lang,
                  en: 'Advance of ₹${result.amount.toStringAsFixed(0)} recorded for ${result.employeeName}!',
                  gu: '₹${result.amount.toStringAsFixed(0)} નો ઉપાડ ${result.employeeName} ના ખાતામાં નોંધાયો!',
                  hi: '₹${result.amount.toStringAsFixed(0)} का अग्रिम ${result.employeeName} के खाते में दर्ज हुआ!'),
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    }
  }

  void _openSettlementDialog(EmployeeModel employee) async {
    final provider = context.read<ProductionProvider>();
    final unsettledUpads = provider.employeeUpads
        .where((u) => u.employeeId == employee.id && !u.isSettled)
        .toList();

    final messenger = ScaffoldMessenger.of(context);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmployeeSettlementDialog(
        employee: employee,
        pendingUpads: unsettledUpads,
        onSettleConfirmed: () async {
          if (employee.id != null) {
            await provider.settleEmployeeUpads(employee.id!);
            if (mounted) {
              final lang = provider.settings.appLanguage;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    AppStrings.t(lang,
                        en: 'Salary settled for ${employee.name} and new month started!',
                        gu: '${employee.name} નો પગાર હિસાબ સેટલ થયો અને નવો મહિનો શરૂ થયો!',
                        hi: '${employee.name} का वेतन तय हुआ और नया महीना शुरू हुआ!'),
                  ),
                  backgroundColor: const Color(0xFF059669),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _sendUpadWhatsApp(EmployeeUpadModel upad) async {
    final provider = context.read<ProductionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final lang = provider.settings.appLanguage;

    final empList = provider.employees.where((e) => e.id == upad.employeeId).toList();
    if (empList.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.t(lang,
                en: 'Employee not found',
                gu: 'કર્મચારી મળી શક્યા નથી',
                hi: 'कर्मचारी नहीं मिला'),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }
    final emp = empList.first;

    final senderPhone = await WhatsAppService.ensureSenderPhone(context, provider);
    if (!mounted || senderPhone == null || senderPhone.isEmpty) return;

    final empPhone = await WhatsAppService.ensureEmployeePhone(context, emp, provider);
    if (!mounted || empPhone == null || empPhone.isEmpty) return;

    final pendingUpad = provider.getEmployeeTotalUpad(emp.id!, unsettledOnly: true);
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
        title: AppStrings.t(lang, en: 'WhatsApp Offline', gu: 'WhatsApp ઑફલાઇન', hi: 'व्हाट्सएप ऑफ़लाइन'),
        message: AppStrings.t(lang,
            en: 'WhatsApp could not be opened. Receipt message copied to clipboard!',
            gu: 'WhatsApp ખોલી શકાયું નથી. રસીદ મેસેજ Clipboard પર કોપી થઈ ગયો છે!',
            hi: 'व्हाट्सएप नहीं खोला जा सका। रसीद संदेश क्लिपबोर्ड पर कॉपी हो गया है!'),
      );
    }
  }

  void _openEmployeeKhata(EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (ctx) => EmployeeKhataStatementDialog(employee: employee),
    );
  }

  void _openManageRolesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const ManageRolesDialog(),
    );
  }

  void _openWhatsAppHistory([int? employeeId]) {
    showDialog(
      context: context,
      builder: (ctx) => WhatsAppHistoryDialog(initialEmployeeId: employeeId),
    );
  }

  void _confirmDeleteEmployee(EmployeeModel employee) async {
    final lang = context.read<ProductionProvider>().settings.appLanguage;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: Color(0xFFDC2626), size: 24),
            const SizedBox(width: 8),
            Text(AppStrings.t(lang,
                en: 'Delete Employee (${employee.name})',
                gu: 'કર્મચારી રદ કરો (${employee.name})',
                hi: 'कर्मचारी हटाएं (${employee.name})')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t(lang,
                  en: 'Are you sure you want to delete "${employee.name}" and send to Recycle Bin?',
                  gu: 'શું તમે ખરેખર "${employee.name}" ને ડિલીટ કરી રિસાયકલ બિનમાં મોકલવા માંગો છો?',
                  hi: 'क्या आप वास्तव में "${employee.name}" को हटाकर रीसायकल बिन में भेजना चाहते हैं?'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.t(lang,
                  en: 'Note: You can restore this employee from the Recycle Bin with 1 click if needed.',
                  gu: 'નોંધ: જરૂર પડે તમે આ કર્મચારીને રિસાયકલ બિનમાંથી ૧-ક્લિકમાં રીસ્ટોર કરી શકશો.',
                  hi: 'नोट: यदि आवश्यक हो तो आप इस कर्मचारी को 1 क्लिक में रीसायकल बिन से पुनर्स्थापित कर सकते हैं।'),
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'ના (રદ કરો)', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.t(lang, en: 'Yes, Delete', gu: 'હા, ડિલીટ કરો', hi: 'हाँ, हटाएं')),
          ),
        ],
      ),
    );

    if (confirm == true && mounted && employee.id != null) {
      final provider = context.read<ProductionProvider>();
      await provider.deleteEmployee(employee.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(lang,
                  en: 'Employee "${employee.name}" moved to Recycle Bin.',
                  gu: 'કર્મચારી "${employee.name}" રિસાયકલ બિનમાં ખસેડાયા.',
                  hi: 'कर्मचारी "${employee.name}" रीसायकल बिन में भेजा गया।'),
            ),
            backgroundColor: const Color(0xFF334155),
            action: SnackBarAction(
              label: AppStrings.t(lang, en: 'Undo', gu: 'પાછું લાવો', hi: 'वापस लें'),
              textColor: const Color(0xFF60A5FA),
              onPressed: () async {
                final bin = provider.deletedRecords.where((d) => d.recordType == 'employee').toList();
                if (bin.isNotEmpty) {
                  await provider.restoreDeletedRecord(bin.first.id!);
                }
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final employees = provider.filteredEmployees;
    final allRolesList = {
      'ALL ROLES',
      ...provider.employeeRoles.map((r) => r.trim().toUpperCase()),
    }.toList();
    final lang = provider.settings.appLanguage;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkScaffoldBg : const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Action Header Bar (Fully responsive to prevent button clipping)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1150;

                final headerTitle = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.t(lang,
                          en: 'Employee & Salary Management',
                          gu: 'કર્મચારી અને પગાર વ્યવસ્થાપન',
                          hi: 'कर्मचारी और वेतन प्रबंधन'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.t(lang,
                          en: 'Worker details, advances, consolidated payroll and khata ledger',
                          gu: 'કારીગરોની વિગત, ઉપાડ (Advance), સર્વગ્રાહી રજિસ્ટર અને સંપૂર્ણ ખાતાવહી હિસાબ',
                          hi: 'कारीगर विवरण, अग्रिम (Advance), समेकित रजिस्टर और पूर्ण खाता बही'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                );

                final actionButtons = Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: isWide ? WrapAlignment.end : WrapAlignment.start,
                  children: [
                    // Manage Roles Button
                    OutlinedButton.icon(
                      onPressed: _openManageRolesDialog,
                      icon: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF6366F1)),
                      label: Text(
                        AppStrings.t(lang, en: 'Manage Roles', gu: 'રોલ મેનેજ કરો', hi: 'भूमिकाएं प्रबंधित करें'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1), fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        side: BorderSide(color: isDark ? const Color(0xFF6366F1).withValues(alpha: 0.5) : const Color(0xFFC7D2FE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                      ),
                    ),
                    // WhatsApp Sent Message Logs Button
                    OutlinedButton.icon(
                      onPressed: () => _openWhatsAppHistory(),
                      icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFF16A34A)),
                      label: Text(
                        '${AppStrings.t(lang, en: 'WhatsApp Logs', gu: 'WhatsApp રેકોર્ડ', hi: 'व्हाट्सएप रिकॉर्ड')} (${context.watch<ProductionProvider>().whatsappLogs.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        side: BorderSide(color: isDark ? const Color(0xFF16A34A).withValues(alpha: 0.5) : const Color(0xFF86EFAC)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFF0FDF4),
                      ),
                    ),
                    // Add Upad Button
                    OutlinedButton.icon(
                      onPressed: () => _openAddUpadDialog(),
                      icon: const Icon(Icons.payments_rounded, size: 16, color: Color(0xFFD97706)),
                      label: Text(
                        AppStrings.t(lang, en: 'Add Advance', gu: 'ઉપાડ નોંધો', hi: 'अग्रिम दर्ज करें'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        side: BorderSide(color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.5) : const Color(0xFFFBBF24)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFFFBEB),
                      ),
                    ),
                    // Add Employee Button
                    ElevatedButton.icon(
                      onPressed: () => _openAddEmployeeDialog(),
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: Text(
                        AppStrings.t(lang, en: 'Add Employee', gu: 'નવો કર્મચારી', hi: 'नया कर्मचारी'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: headerTitle),
                      const SizedBox(width: 16),
                      actionButtons,
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headerTitle,
                      const SizedBox(height: 12),
                      actionButtons,
                    ],
                  );
                }
              },
            ),
          ),

          // Main View Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 4 Factory KPI Summary Cards (Responsive & Auto-wrapping)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useGrid = constraints.maxWidth < 950;
                      final kpi1 = _buildKpiCard(
                        title: AppStrings.t(lang,
                            en: 'Active Employees',
                            gu: 'કુલ સક્રિય કર્મચારીઓ',
                            hi: 'सक्रिय कर्मचारी'),
                        value: '${provider.totalActiveEmployees} ${AppStrings.t(lang, en: 'Workers', gu: 'કારીગરો', hi: 'कारीगर')}',
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFF4F46E5),
                        bgColor: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                        isDark: isDark,
                      );
                      final kpi2 = _buildKpiCard(
                        title: AppStrings.t(lang,
                            en: 'Monthly Base Payroll',
                            gu: 'માસિક કુલ પગાર',
                            hi: 'मासिक मूल वेतन'),
                        value: '₹${provider.totalMonthlyPayroll.toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF2563EB),
                        bgColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFFEFF6FF),
                        isDark: isDark,
                      );
                      final kpi3 = _buildKpiCard(
                        title: AppStrings.t(lang,
                            en: 'Total Advances (To Deduct)',
                            gu: 'કુલ આપેલ ઉપાડ (કપાત)',
                            hi: 'कुल अग्रिम (कटौती हेतु)'),
                        value: '₹${provider.totalPendingUpad.toStringAsFixed(0)}',
                        icon: Icons.payments_rounded,
                        color: const Color(0xFFD97706),
                        bgColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFFBEB),
                        isDark: isDark,
                      );
                      final kpi4 = _buildKpiCard(
                        title: AppStrings.t(lang,
                            en: 'Net Payable Salary',
                            gu: 'ચૂકવવાપાત્ર ચોખ્ખો પગાર',
                            hi: 'देय शुद्ध वेतन'),
                        value: '₹${provider.totalNetPayableSalary.toStringAsFixed(0)}',
                        icon: Icons.price_check_rounded,
                        color: const Color(0xFF059669),
                        bgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5),
                        isDark: isDark,
                      );

                      if (useGrid) {
                        return Column(
                          children: [
                            Row(children: [Expanded(child: kpi1), const SizedBox(width: 14), Expanded(child: kpi2)]),
                            const SizedBox(height: 14),
                            Row(children: [Expanded(child: kpi3), const SizedBox(width: 14), Expanded(child: kpi4)]),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(child: kpi1),
                            const SizedBox(width: 14),
                            Expanded(child: kpi2),
                            const SizedBox(width: 14),
                            Expanded(child: kpi3),
                            const SizedBox(width: 14),
                            Expanded(child: kpi4),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // View Mode Navigation Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: LayoutBuilder(
                      builder: (context, tabConstraints) {
                        final isNarrowTabs = tabConstraints.maxWidth < 820;
                        final tab0Title = AppStrings.t(lang, en: 'Employee Directory', gu: 'કર્મચારી ડિરેક્ટરી', hi: 'कर्मचारी निर्देशिका');
                        final tab1Title = AppStrings.t(lang, en: 'Master Payroll & Advance Register', gu: 'સર્વગ્રાહી પગાર & ઉપાડ રજિસ્ટર', hi: 'मास्टर वेतन और अग्रिम रजिस्टर');
                        final tab2Title = AppStrings.t(lang, en: 'All Advances History & Ledger', gu: 'તમામ ઉપાડ ઇતિહાસ & ખાતાવહી', hi: 'सभी अग्रिम इतिहास और बहीखाता');

                        if (isNarrowTabs) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _viewTabItem(
                                index: 0,
                                icon: Icons.grid_view_rounded,
                                title: tab0Title,
                                count: employees.length,
                                isDark: isDark,
                                expanded: false,
                              ),
                              _viewTabItem(
                                index: 1,
                                icon: Icons.table_chart_rounded,
                                title: tab1Title,
                                count: provider.employees.length,
                                isDark: isDark,
                                expanded: false,
                              ),
                              _viewTabItem(
                                index: 2,
                                icon: Icons.history_edu_rounded,
                                title: tab2Title,
                                count: provider.employeeUpads.length,
                                isDark: isDark,
                                expanded: false,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            _viewTabItem(
                              index: 0,
                              icon: Icons.grid_view_rounded,
                              title: tab0Title,
                              count: employees.length,
                              isDark: isDark,
                              expanded: true,
                            ),
                            const SizedBox(width: 8),
                            _viewTabItem(
                              index: 1,
                              icon: Icons.table_chart_rounded,
                              title: tab1Title,
                              count: provider.employees.length,
                              isDark: isDark,
                              expanded: true,
                            ),
                            const SizedBox(width: 8),
                            _viewTabItem(
                              index: 2,
                              icon: Icons.history_edu_rounded,
                              title: tab2Title,
                              count: provider.employeeUpads.length,
                              isDark: isDark,
                              expanded: true,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab View Render
                  if (_activeViewTab == 0)
                    _buildEmployeeCardsView(provider, employees, allRolesList, isDark)
                  else if (_activeViewTab == 1)
                    _buildMasterPayrollRegisterView(provider, allRolesList, isDark)
                  else
                    _buildAllUpadsHistoryView(provider, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewTabItem({
    required int index,
    required IconData icon,
    required String title,
    required int count,
    required bool isDark,
    bool expanded = true,
  }) {
    final isSelected = _activeViewTab == index;

    final itemWidget = Tooltip(
      message: title,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () => setState(() => _activeViewTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B))),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                    color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (expanded) {
      return Expanded(child: itemWidget);
    }
    return itemWidget;
  }
  // =========================================================================
  // VIEW 1: Employee Cards Directory
  // =========================================================================
  Widget _buildEmployeeCardsView(
    ProductionProvider provider,
    List<EmployeeModel> employees,
    List<String> allRolesList,
    bool isDark,
  ) {
    final lang = provider.settings.appLanguage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter & Search Controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Search Box
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                      onChanged: (val) => provider.setEmployeeSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: AppStrings.t(lang,
                            en: 'Search by employee name, role or phone...',
                            gu: 'કર્મચારીનું નામ, રોલ અથવા ફોન નંબરથી શોધો...',
                            hi: 'कर्मचारी का नाम, भूमिका या फ़ोन से खोजें...'),
                        hintStyle: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, size: 18, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setEmployeeSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Active Only Filter Switch
                  Row(
                    children: [
                      Switch.adaptive(
                        value: provider.employeeActiveOnlyFilter,
                        activeThumbColor: const Color(0xFF4F46E5),
                        onChanged: (val) => provider.setEmployeeActiveOnlyFilter(val),
                      ),
                      Text(
                        AppStrings.t(lang, en: 'Active Only', gu: 'માત્ર સક્રિય', hi: 'केवल सक्रिय'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Role Filter Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allRolesList.map((role) {
                  final roleUpper = role.trim().toUpperCase();
                  final isSelected = provider.selectedEmployeeRoleFilter.trim().toUpperCase() == roleUpper;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(roleUpper),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5))
                          : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
                    ),
                    backgroundColor: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                    selectedColor: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                    checkmarkColor: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                    side: BorderSide(
                      color: isSelected
                          ? (isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5))
                          : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                    ),
                    onSelected: (_) => provider.setEmployeeRoleFilter(roleUpper),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // List of Cards
        if (employees.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.badge_outlined, size: 64, color: isDark ? AppTheme.darkBorder : Colors.grey.shade400),
                const SizedBox(height: 14),
                Text(
                  AppStrings.t(lang,
                      en: 'No Employees Found',
                      gu: 'કોઈ કર્મચારી મળ્યા નથી',
                      hi: 'कोई कर्मचारी नहीं मिला'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.t(lang,
                      en: 'Click "Add Employee" button above to register worker or operator.',
                      gu: 'નવા કારીગર અથવા ઓપરેટર ઉમેરવા માટે ઉપર "નવો કર્મચારી" બટન દબાવો.',
                      hi: 'कारीगर या ऑपरेटर दर्ज करने के लिए ऊपर "नया कर्मचारी" बटन दबाएं।'),
                  style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _openAddEmployeeDialog(),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: Text(AppStrings.t(lang, en: 'Add Employee', gu: 'નવો કર્મચારી ઉમેરો', hi: 'नया कर्मचारी जोड़ें')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: employees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final emp = employees[index];
              final totalUpad = emp.id != null
                  ? provider.getEmployeeTotalUpad(emp.id!, unsettledOnly: true)
                  : 0.0;
              final remainingSalary = provider.getEmployeeRemainingSalary(emp);

              return _buildEmployeeCard(
                emp: emp,
                totalUpad: totalUpad,
                remainingSalary: remainingSalary,
                isDark: isDark,
              );
            },
          ),
      ],
    );
  }

  // =========================================================================
  // VIEW 2: Consolidated Master Payroll & Upad Register (સર્વગ્રાહી પત્રક)
  // =========================================================================
  Widget _buildMasterPayrollRegisterView(
    ProductionProvider provider,
    List<String> allRolesList,
    bool isDark,
  ) {
    final employees = List<EmployeeModel>.from(provider.filteredEmployees);
    employees.sort((a, b) {
      int cmp = 0;
      switch (_empSortColumnIndex) {
        case 0:
          cmp = (a.id ?? 0).compareTo(b.id ?? 0);
          break;
        case 1:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 2:
          cmp = a.role.trim().toUpperCase().compareTo(b.role.trim().toUpperCase());
          break;
        case 3:
          cmp = a.phone.toLowerCase().compareTo(b.phone.toLowerCase());
          break;
        case 4:
          cmp = a.monthlySalary.compareTo(b.monthlySalary);
          break;
        case 5:
          final upadA = a.id != null ? provider.getEmployeeAllTimeTotalUpad(a.id!) : 0.0;
          final upadB = b.id != null ? provider.getEmployeeAllTimeTotalUpad(b.id!) : 0.0;
          cmp = upadA.compareTo(upadB);
          break;
        case 6:
          final pendA = a.id != null ? provider.getEmployeeTotalUpad(a.id!, unsettledOnly: true) : 0.0;
          final pendB = b.id != null ? provider.getEmployeeTotalUpad(b.id!, unsettledOnly: true) : 0.0;
          cmp = pendA.compareTo(pendB);
          break;
        case 7:
          final netA = provider.getEmployeeRemainingSalary(a);
          final netB = provider.getEmployeeRemainingSalary(b);
          cmp = netA.compareTo(netB);
          break;
        case 8:
          cmp = (a.isActive ? 1 : 0).compareTo(b.isActive ? 1 : 0);
          break;
        default:
          cmp = a.name.compareTo(b.name);
      }
      return _empSortAscending ? cmp : -cmp;
    });

    final lang = provider.settings.appLanguage;

    final totalMonthlySalary = employees.fold<double>(0.0, (s, e) => s + e.monthlySalary);
    final totalAllTimeUpad = employees.fold<double>(
      0.0,
      (s, e) => s + (e.id != null ? provider.getEmployeeAllTimeTotalUpad(e.id!) : 0.0),
    );
    final totalPendingUpad = employees.fold<double>(
      0.0,
      (s, e) => s + (e.id != null ? provider.getEmployeeTotalUpad(e.id!, unsettledOnly: true) : 0.0),
    );
    final totalNetPayable = employees.fold<double>(
      0.0,
      (s, e) => s + provider.getEmployeeRemainingSalary(e),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Bar inside Register
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                    onChanged: (val) => provider.setEmployeeSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: AppStrings.t(lang,
                          en: 'Search employee name...',
                          gu: 'કર્મચારીનું નામ શોધો...',
                          hi: 'कर्मचारी का नाम खोजें...'),
                      hintStyle: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Role Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButton<String>(
                    value: allRolesList.firstWhere(
                      (r) => r.trim().toUpperCase() == provider.selectedEmployeeRoleFilter.trim().toUpperCase(),
                      orElse: () => 'ALL ROLES',
                    ),
                    dropdownColor: isDark ? AppTheme.darkCardBg : Colors.white,
                    underline: const SizedBox(),
                    items: allRolesList
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r.trim().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) provider.setEmployeeRoleFilter(val.trim().toUpperCase());
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Row(
                  children: [
                    Switch.adaptive(
                      value: provider.employeeActiveOnlyFilter,
                      activeThumbColor: const Color(0xFF4F46E5),
                      onChanged: (val) => provider.setEmployeeActiveOnlyFilter(val),
                    ),
                    Text(
                      AppStrings.t(lang, en: 'Active Only', gu: 'માત્ર સક્રિય', hi: 'केवल सक्रिय'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),

          // Master Table
          LayoutBuilder(
            builder: (context, constraints) {
              final dynamicSpacing = ((constraints.maxWidth - 750) / 10).clamp(10.0, 24.0);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    sortColumnIndex: _empSortColumnIndex,
                    sortAscending: _empSortAscending,
                    headingRowColor: WidgetStateProperty.all(isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9)),
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF334155),
                    ),
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 56,
                    columnSpacing: dynamicSpacing,
                    horizontalMargin: 12,
              columns: [
                DataColumn(
                  label: const Text('#'),
                  onSort: (idx, asc) => setState(() {
                    _empSortColumnIndex = idx;
                    _empSortAscending = asc;
                  }),
                ),
                DataColumn(
                  label: Text(AppStrings.t(lang, en: 'Employee Name', gu: 'કર્મચારી નામ', hi: 'कर्मचारी का नाम')),
                  onSort: (idx, asc) => setState(() {
                    _empSortColumnIndex = idx;
                    _empSortAscending = asc;
                  }),
                ),
                DataColumn(
                  label: Text(AppStrings.t(lang, en: 'Role', gu: 'રોલ', hi: 'भूमिका')),
                  onSort: (idx, asc) => setState(() {
                    _empSortColumnIndex = idx;
                    _empSortAscending = asc;
                  }),
                ),
                DataColumn(
                  label: Text(AppStrings.t(lang, en: 'Phone', gu: 'મોબાઇલ', hi: 'फ़ोन')),
                  onSort: (idx, asc) => setState(() {
                    _empSortColumnIndex = idx;
                    _empSortAscending = asc;
                  }),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(AppStrings.t(lang, en: 'Salary (₹)', gu: 'માસિક પગાર (₹)', hi: 'मासिक वेतन (₹)')),
                  onSort: (idx, asc) => setState(() {
                    _empSortColumnIndex = idx;
                    _empSortAscending = asc;
                  }),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(AppStrings.t(lang, en: 'Total All Advances (₹)', gu: 'કુલ ઐતિહાસિક ઉપાડ (₹)', hi: 'कुल अग्रिम (₹)')),
                  onSort: (idx, asc) => setState(() {
                    _empSortColumnIndex = idx;
                    _empSortAscending = asc;
                  }),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(AppStrings.t(lang, en: 'Salary Deduct Advance (₹)', gu: 'પગાર કપાત ઉપાડ (₹)', hi: 'वेतन कटौती अग्रिम (₹)')),
                  onSort: (idx, asc) => setState(() {
                    _empSortColumnIndex = idx;
                    _empSortAscending = asc;
                  }),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(AppStrings.t(lang, en: 'Net Due (₹)', gu: 'ચૂકવવાપાત્ર ચોખ્ખો પગાર (₹)', hi: 'देय शुद्ध वेतन (₹)')),
                  onSort: (idx, asc) => setState(() {
                    _empSortColumnIndex = idx;
                    _empSortAscending = asc;
                  }),
                ),
                DataColumn(
                  label: Text(AppStrings.t(lang, en: 'Status', gu: 'સ્ટેટસ', hi: 'स्थिति')),
                  onSort: (idx, asc) => setState(() {
                    _empSortColumnIndex = idx;
                    _empSortAscending = asc;
                  }),
                ),
                DataColumn(label: Text(AppStrings.t(lang, en: 'Action', gu: 'એક્શન', hi: 'कार्रवाई'))),
              ],
              rows: employees.asMap().entries.map((entry) {
                final index = entry.key;
                final emp = entry.value;

                final allTimeUpad = emp.id != null ? provider.getEmployeeAllTimeTotalUpad(emp.id!) : 0.0;
                final pendingUpad = emp.id != null ? provider.getEmployeeTotalUpad(emp.id!, unsettledOnly: true) : 0.0;
                final netSalary = provider.getEmployeeRemainingSalary(emp);
                final isNegative = (emp.monthlySalary - pendingUpad) < 0;

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
                    DataCell(
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'E',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            emp.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          emp.role.trim().toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(
                      emp.phone.isEmpty ? '—' : emp.phone,
                      style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                    )),
                    DataCell(
                      Text(
                        '₹${emp.monthlySalary.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF059669)),
                      ),
                    ),
                    DataCell(
                      Text(
                        '₹${allTimeUpad.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF7C3AED)),
                      ),
                    ),
                    DataCell(
                      Text(
                        '₹${pendingUpad.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD97706)),
                      ),
                    ),
                    DataCell(
                      Text(
                        '₹${netSalary.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: isNegative ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: emp.isActive
                              ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5))
                              : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEF2F2)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          emp.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: emp.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // View Khata
                          IconButton(
                            icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF6366F1), size: 18),
                            tooltip: AppStrings.t(lang, en: 'View Statement', gu: 'ખાતાવહી સ્ટેટમેન્ટ', hi: 'खाताबही विवरण'),
                            onPressed: () => _openEmployeeKhata(emp),
                          ),
                          // Add Upad
                          IconButton(
                            icon: const Icon(Icons.payments_rounded, color: Color(0xFFD97706), size: 18),
                            tooltip: AppStrings.t(lang, en: 'Add Advance', gu: 'ઉપાડ આપો', hi: 'अग्रिम दें'),
                            onPressed: () => _openAddUpadDialog(emp),
                          ),
                          // Settle
                          IconButton(
                            icon: const Icon(Icons.price_check_rounded, color: Color(0xFF059669), size: 18),
                            tooltip: AppStrings.t(lang, en: 'Settle Salary', gu: 'પગાર ચૂકવો અને હિસાબ કરો', hi: 'वेतन निपटान करें'),
                            onPressed: () => _openSettlementDialog(emp),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    ),

          // Grand Total Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppStrings.t(lang, en: 'Total Summary', gu: 'કુલ સરવાળો', hi: 'कुल योग')} (${employees.length} ${AppStrings.t(lang, en: 'Employees', gu: 'કર્મચારીઓ', hi: 'कर्मचारी')}):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B),
                  ),
                ),
                Row(
                  children: [
                    _footerStat(AppStrings.t(lang, en: 'Monthly Salary', gu: 'માસિક પગાર', hi: 'मासिक वेतन'), '₹${totalMonthlySalary.toStringAsFixed(0)}', const Color(0xFF059669), isDark),
                    const SizedBox(width: 20),
                    _footerStat(AppStrings.t(lang, en: 'Total All Advances', gu: 'કુલ ઐતિહાસિક ઉપાડ', hi: 'कुल अग्रिम'), '₹${totalAllTimeUpad.toStringAsFixed(0)}', const Color(0xFF7C3AED), isDark),
                    const SizedBox(width: 20),
                    _footerStat(AppStrings.t(lang, en: 'Deduction Advance', gu: 'આપેલ ઉપાડ (કપાત)', hi: 'कटौती अग्रिम'), '₹${totalPendingUpad.toStringAsFixed(0)}', const Color(0xFFD97706), isDark),
                    const SizedBox(width: 20),
                    _footerStat(AppStrings.t(lang, en: 'Net Due Salary', gu: 'ચૂકવવાપાત્ર પગાર', hi: 'देय शुद्ध वेतन'), '₹${totalNetPayable.toStringAsFixed(0)}', const Color(0xFF2563EB), isDark),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerStat(String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
        ),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)),
      ],
    );
  }

  // =========================================================================
  // VIEW 3: All Upads History & Ledger (તમામ ઉપાડ ઇતિહાસ)
  // =========================================================================
  Widget _buildAllUpadsHistoryView(ProductionProvider provider, bool isDark) {
    final allUpads = List<EmployeeUpadModel>.from(provider.employeeUpads);
    final lang = provider.settings.appLanguage;
    allUpads.sort((a, b) => b.date.compareTo(a.date)); // Newest first

    final filteredUpads = allUpads.where((u) {
      if (_upadEmployeeFilter != null && u.employeeId != _upadEmployeeFilter) return false;
      if (_upadStatusFilter == 'Pending' && u.isSettled) return false;
      if (_upadStatusFilter == 'Settled' && !u.isSettled) return false;
      if (_upadFromDate != null && u.date.isBefore(DateTime(_upadFromDate!.year, _upadFromDate!.month, _upadFromDate!.day))) {
        return false;
      }
      if (_upadToDate != null && u.date.isAfter(DateTime(_upadToDate!.year, _upadToDate!.month, _upadToDate!.day, 23, 59, 59))) {
        return false;
      }
      if (_upadSearchController.text.trim().isNotEmpty) {
        final q = _upadSearchController.text.trim().toLowerCase();
        final matchEmp = u.employeeName.toLowerCase().contains(q);
        final matchNotes = u.notes.toLowerCase().contains(q);
        final matchAmt = u.amount.toString().contains(q);
        if (!matchEmp && !matchNotes && !matchAmt) return false;
      }
      return true;
    }).toList();

    filteredUpads.sort((a, b) {
      int cmp = 0;
      switch (_upadSortColumnIndex) {
        case 0:
          cmp = (a.id ?? 0).compareTo(b.id ?? 0);
          break;
        case 1:
          cmp = a.date.compareTo(b.date);
          break;
        case 2:
          cmp = a.employeeName.toLowerCase().compareTo(b.employeeName.toLowerCase());
          break;
        case 3:
          cmp = a.amount.compareTo(b.amount);
          break;
        case 4:
          cmp = a.notes.toLowerCase().compareTo(b.notes.toLowerCase());
          break;
        case 5:
          cmp = (a.isSettled ? 1 : 0).compareTo(b.isSettled ? 1 : 0);
          break;
        default:
          cmp = a.date.compareTo(b.date);
      }
      return _upadSortAscending ? cmp : -cmp;
    });

    final totalFilteredUpad = filteredUpads.fold<double>(0.0, (s, u) => s + u.amount);
    final totalPendingFiltered = filteredUpads.where((u) => !u.isSettled).fold<double>(0.0, (s, u) => s + u.amount);
    final totalSettledFiltered = filteredUpads.where((u) => u.isSettled).fold<double>(0.0, (s, u) => s + u.amount);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _upadSearchController,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: AppStrings.t(lang,
                              en: 'Search by employee name, notes or amount...',
                              gu: 'કર્મચારી નામ, નોંધ અથવા રકમથી શોધો...',
                              hi: 'कर्मचारी नाम, विवरण या राशि से खोजें...'),
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Employee Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButton<int?>(
                        value: _upadEmployeeFilter,
                        dropdownColor: isDark ? AppTheme.darkCardBg : Colors.white,
                        underline: const SizedBox(),
                        hint: Text(
                          AppStrings.t(lang, en: 'All Employees', gu: 'બધા કર્મચારીઓ', hi: 'सभी कर्मचारी'),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              AppStrings.t(lang, en: 'All Employees', gu: 'બધા કર્મચારીઓ', hi: 'सभी कर्मचारी'),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          ...provider.employees.map((e) => DropdownMenuItem<int?>(
                                value: e.id,
                                child: Text(
                                  e.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                                  ),
                                ),
                              )),
                        ],
                        onChanged: (val) => setState(() => _upadEmployeeFilter = val),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Status Filter
                    Row(
                      children: [
                        _statusRadio(AppStrings.t(lang, en: 'All Advances', gu: 'બધા ઉપાડ', hi: 'सभी अग्रिम'), 'All', null, isDark),
                        const SizedBox(width: 6),
                        _statusRadio(AppStrings.t(lang, en: 'Unsettled', gu: 'ચાલુ મહિનાના (બાકી)', hi: 'अनिपटारा (बकाया)'), 'Pending', const Color(0xFFD97706), isDark),
                        const SizedBox(width: 6),
                        _statusRadio(AppStrings.t(lang, en: 'Settled', gu: 'પગારમાં કપાત (ચૂકતે)', hi: 'निपटारा (कटौती)'), 'Settled', const Color(0xFF059669), isDark),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),

          // Summary Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
            child: Row(
              children: [
                Text(
                  '${AppStrings.t(lang, en: 'Total Entries', gu: 'કુલ એન્ટ્રીઝ', hi: 'कुल प्रविष्टियां')}: ${filteredUpads.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF334155),
                  ),
                ),
                const Spacer(),
                _historyBadge(AppStrings.t(lang, en: 'Total Advances', gu: 'કુલ ઉપાડ', hi: 'कुल अग्रिम'), '₹${totalFilteredUpad.toStringAsFixed(0)}', const Color(0xFF7C3AED), isDark),
                const SizedBox(width: 16),
                _historyBadge(AppStrings.t(lang, en: 'Pending', gu: 'ચાલુ પેન્ડિંગ', hi: 'लंबित'), '₹${totalPendingFiltered.toStringAsFixed(0)}', const Color(0xFFD97706), isDark),
                const SizedBox(width: 16),
                _historyBadge(AppStrings.t(lang, en: 'Settled', gu: 'સેટલ થયેલ', hi: 'निपटारा'), '₹${totalSettledFiltered.toStringAsFixed(0)}', const Color(0xFF059669), isDark),
              ],
            ),
          ),

          // Ledger Table
          filteredUpads.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      AppStrings.t(lang,
                          en: 'No advance record found.',
                          gu: 'કોઈ ઉપાડ રેકોર્ડ મળ્યો નથી.',
                          hi: 'कोई अग्रिम रिकॉर्ड नहीं मिला।'),
                      style: TextStyle(color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final dynamicSpacing = ((constraints.maxWidth - 550) / 7).clamp(12.0, 32.0);
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          sortColumnIndex: _upadSortColumnIndex,
                          sortAscending: _upadSortAscending,
                          headingRowColor: WidgetStateProperty.all(isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9)),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF334155),
                          ),
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 52,
                          columnSpacing: dynamicSpacing,
                          horizontalMargin: 16,
                    columns: [
                      DataColumn(
                        label: const Text('#'),
                        onSort: (idx, asc) => setState(() {
                          _upadSortColumnIndex = idx;
                          _upadSortAscending = asc;
                        }),
                      ),
                      DataColumn(
                        label: Text(AppStrings.t(lang, en: 'Date', gu: 'તારીખ', hi: 'तारीख')),
                        onSort: (idx, asc) => setState(() {
                          _upadSortColumnIndex = idx;
                          _upadSortAscending = asc;
                        }),
                      ),
                      DataColumn(
                        label: Text(AppStrings.t(lang, en: 'Employee Name', gu: 'કર્મચારી નામ', hi: 'कर्मचारी नाम')),
                        onSort: (idx, asc) => setState(() {
                          _upadSortColumnIndex = idx;
                          _upadSortAscending = asc;
                        }),
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text(AppStrings.t(lang, en: 'Advance Amount (₹)', gu: 'ઉપાડ રકમ (₹)', hi: 'अग्रिम राशि (₹)')),
                        onSort: (idx, asc) => setState(() {
                          _upadSortColumnIndex = idx;
                          _upadSortAscending = asc;
                        }),
                      ),
                      DataColumn(
                        label: Text(AppStrings.t(lang, en: 'Notes / Reason', gu: 'વિગત / કારણ', hi: 'विवरण / कारण')),
                        onSort: (idx, asc) => setState(() {
                          _upadSortColumnIndex = idx;
                          _upadSortAscending = asc;
                        }),
                      ),
                      DataColumn(
                        label: Text(AppStrings.t(lang, en: 'Status', gu: 'સ્થિતિ', hi: 'स्थिति')),
                        onSort: (idx, asc) => setState(() {
                          _upadSortColumnIndex = idx;
                          _upadSortAscending = asc;
                        }),
                      ),
                      DataColumn(label: Text(AppStrings.t(lang, en: 'Action', gu: 'એક્શન', hi: 'कार्रवाई'))),
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
                            style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF334155)),
                          )),
                          DataCell(Text(
                            upad.employeeName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                            ),
                          )),
                          DataCell(
                            Text(
                              '₹${upad.amount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFD97706)),
                            ),
                          ),
                          DataCell(Text(
                            upad.notes.isEmpty ? '—' : upad.notes,
                            style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                          )),
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
                                    : AppStrings.t(lang, en: 'Pending', gu: 'પેન્ડિંગ', hi: 'लंबित'),
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
                                  icon: const Icon(Icons.chat_bubble_rounded, size: 19, color: Color(0xFF25D366)),
                                  tooltip: AppStrings.t(lang,
                                      en: 'Send Receipt via WhatsApp',
                                      gu: 'WhatsApp પર રસીદ મોકલો',
                                      hi: 'WhatsApp पर रसीद भेजें'),
                                  onPressed: () => _sendUpadWhatsApp(upad),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                  tooltip: AppStrings.t(lang, en: 'Delete Advance', gu: 'ઉપાડ રદ કરો', hi: 'अग्रिम हटाएं'),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: Text(AppStrings.t(lang, en: 'Delete Advance', gu: 'ઉપાડ રદ કરો', hi: 'अग्रिम हटाएं')),
                                        content: Text(AppStrings.t(lang,
                                            en: 'Do you want to move advance ₹${upad.amount.toStringAsFixed(0)} to Recycle Bin?',
                                            gu: 'શું તમે ₹${upad.amount.toStringAsFixed(0)} નો ઉપાડ રીસાયકલ બિનમાં મોકલવા માંગો છો?',
                                            hi: 'क्या आप ₹${upad.amount.toStringAsFixed(0)} का अग्रिम रीसायकल बिन में भेजना चाहते हैं?')),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: Text(AppStrings.t(lang, en: 'No', gu: 'ના', hi: 'नहीं')),
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
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _statusRadio(String label, String value, Color? color, bool isDark) {
    final isSelected = _upadStatusFilter == value;
    final activeColor = color ?? const Color(0xFF4F46E5);

    return InkWell(
      onTap: () => setState(() => _upadStatusFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _historyBadge(String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
        ),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }

  // =========================================================================
  // Employee Card Component
  // =========================================================================
  Widget _buildEmployeeCard({
    required EmployeeModel emp,
    required double totalUpad,
    required double remainingSalary,
    required bool isDark,
  }) {
    final isNegative = remainingSalary < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNegative
              ? const Color(0xFFFCA5A5)
              : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
          width: isNegative ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final lang = context.watch<ProductionProvider>().settings.appLanguage;
          final isNarrow = constraints.maxWidth < 900;

          final profileInfo = Row(
            mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: emp.isActive
                        ? [const Color(0xFF4F46E5), const Color(0xFF6366F1)]
                        : [const Color(0xFF94A3B8), const Color(0xFF64748B)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'E',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name, Role & Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            emp.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            emp.role.trim().toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                        if (!emp.isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (emp.phone.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_outlined, size: 13, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(emp.phone, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B))),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 13, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              '${AppStrings.t(lang, en: 'Joined', gu: 'તારીખ', hi: 'शामिल')}: ${DateFormat('dd/MM/yyyy').format(emp.joiningDate)}',
                              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final financialPills = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Monthly Base Salary
                Column(
                  children: [
                    Text(
                      AppStrings.t(lang, en: 'Monthly Salary', gu: 'માસિક પગાર', hi: 'मासिक वेतन'),
                      style: TextStyle(fontSize: 10, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${emp.monthlySalary.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF059669)),
                    ),
                  ],
                ),
                Container(width: 1, height: 24, color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),

                // Current Upad
                Column(
                  children: [
                    Text(
                      AppStrings.t(lang, en: 'Pending Advance', gu: 'બાકી ઉપાડ', hi: 'बकाया अग्रिम'),
                      style: TextStyle(fontSize: 10, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${totalUpad.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFD97706)),
                    ),
                  ],
                ),
                Container(width: 1, height: 24, color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),

                // Net Balance Salary
                Column(
                  children: [
                    Text(
                      AppStrings.t(lang, en: 'Net Due', gu: 'ચૂકવવાપાત્ર બાકી', hi: 'देय शेष'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${remainingSalary.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: isNegative ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final actionButtons = Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // View Khata Button
              ElevatedButton.icon(
                onPressed: () => _openEmployeeKhata(emp),
                icon: const Icon(Icons.receipt_long_rounded, size: 15),
                label: Text(AppStrings.t(lang, en: 'Statement', gu: 'ખાતાવહી', hi: 'खाताबही')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
              // Add Upad Button
              ElevatedButton.icon(
                onPressed: () => _openAddUpadDialog(emp),
                icon: const Icon(Icons.payments_rounded, size: 15),
                label: Text(AppStrings.t(lang, en: 'Advance', gu: 'ઉપાડ', hi: 'अग्रिम')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
              // Settle / Pay Button
              ElevatedButton.icon(
                onPressed: () => _openSettlementDialog(emp),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                label: Text(AppStrings.t(lang, en: 'Settle', gu: 'ચૂકવો', hi: 'निपटान')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
              // Edit Employee
              IconButton(
                icon: Icon(Icons.edit_outlined, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B), size: 19),
                tooltip: AppStrings.t(lang, en: 'Edit Employee', gu: 'કર્મચારી સુધારો', hi: 'कर्मचारी संपादित करें'),
                onPressed: () => _openAddEmployeeDialog(emp),
              ),
              // Delete Employee
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 19),
                tooltip: AppStrings.t(lang, en: 'Move to Bin', gu: 'ડિલીટ કરો', hi: 'हटाएं'),
                onPressed: () => _confirmDeleteEmployee(emp),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                profileInfo,
                const SizedBox(height: 12),
                financialPills,
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: actionButtons,
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(flex: 3, child: profileInfo),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: financialPills),
                const SizedBox(width: 14),
                actionButtons,
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
