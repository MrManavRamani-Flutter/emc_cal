import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../core/whatsapp_service.dart';
import '../../models/employee_model.dart';
import '../../models/employee_upad_model.dart';
import '../../providers/production_provider.dart';
import '../../widgets/print_slip_dialog.dart';
import '../../widgets/app_snack_bar.dart';

class AddUpadDialog extends StatefulWidget {
  final List<EmployeeModel> employees;
  final EmployeeModel? preselectedEmployee;
  final double currentPendingUpad;

  const AddUpadDialog({
    super.key,
    required this.employees,
    this.preselectedEmployee,
    this.currentPendingUpad = 0.0,
  });

  @override
  State<AddUpadDialog> createState() => _AddUpadDialogState();
}

class _AddUpadDialogState extends State<AddUpadDialog> {
  final _formKey = GlobalKey<FormState>();

  EmployeeModel? _selectedEmployee;
  late TextEditingController _amountController;
  late DateTime _selectedDate;

  double _enteredAmount = 0.0;
  bool _sendWhatsApp = false;
  String _messageLanguage = 'Both';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployee = widget.preselectedEmployee ??
        (widget.employees.isNotEmpty ? widget.employees.first : null);
    _amountController = TextEditingController();
    _selectedDate = DateTime.now();

    _amountController.addListener(() {
      final val = double.tryParse(_amountController.text.trim()) ?? 0.0;
      if (val != _enteredAmount) {
        setState(() => _enteredAmount = val);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final settings = context.read<ProductionProvider>().settings;
      _sendWhatsApp = settings.whatsappAutoSend;
      _messageLanguage = settings.whatsappMessageLanguage;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<bool> _triggerWhatsApp() async {
    final lang = context.read<ProductionProvider>().settings.appLanguage;
    if (!_formKey.currentState!.validate()) return false;
    if (_selectedEmployee == null || _selectedEmployee!.id == null) {
      AppSnackBar.showWarning(
        context,
        title: AppStrings.t(lang, en: 'Employee Required', gu: 'કર્મચારી પસંદ કરો', hi: 'कर्मचारी चुनें'),
        message: AppStrings.t(lang, en: 'Please select an employee first.', gu: 'કૃપા કરીને કર્મચારી પસંદ કરો', hi: 'कृपया पहले एक कर्मचारी चुनें'),
      );
      return false;
    }

    final provider = context.read<ProductionProvider>();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final baseSalary = _selectedEmployee!.monthlySalary;
    final totalPending = widget.currentPendingUpad + amount;
    final remainingSalary = baseSalary - totalPending;

    // 1. Ensure Sender Phone (Prompt if missing)
    final senderPhone = await WhatsAppService.ensureSenderPhone(context, provider);
    if (!mounted || senderPhone == null || senderPhone.isEmpty) return false;

    // 2. Ensure Employee Phone (Prompt if missing)
    final empPhone = await WhatsAppService.ensureEmployeePhone(context, _selectedEmployee!, provider);
    if (!mounted || empPhone == null || empPhone.isEmpty) return false;

    // 3. Generate Message
    final message = WhatsAppService.generateUpadMessage(
      language: _messageLanguage,
      companyName: provider.settings.companyName,
      employeeName: _selectedEmployee!.name,
      role: _selectedEmployee!.role,
      gender: _selectedEmployee!.gender,
      upadAmount: amount,
      date: DateFormat('dd/MM/yyyy').format(_selectedDate),
      notes: '',
      monthlySalary: baseSalary,
      totalPendingUpad: totalPending,
      remainingSalary: remainingSalary,
      senderPhone: senderPhone,
    );

    // 4. Launch WhatsApp URL
    final launched = await WhatsAppService.launchWhatsAppUrl(
      recipientPhone: empPhone,
      message: message,
    );

    if (launched) {
      await provider.logWhatsAppMessage(
        employeeId: _selectedEmployee?.id,
        employeeName: _selectedEmployee?.name ?? 'Employee',
        recipientPhone: empPhone,
        senderPhone: senderPhone,
        message: message,
        messageType: 'upad_receipt',
        amount: amount,
      );
    }

    if (mounted && !launched) {
      AppSnackBar.showWarning(
        context,
        title: AppStrings.t(lang, en: 'WhatsApp Offline', gu: 'WhatsApp ઑફલાઇન', hi: 'व्हाट्सएप ऑफ़लाइन'),
        message: AppStrings.t(lang,
            en: 'Could not open WhatsApp. Receipt copied to Clipboard!',
            gu: 'WhatsApp ખોલી શકાયું નથી. રસીદ મેસેજ Clipboard પર કોપી થઈ ગયો છે!',
            hi: 'व्हाट्सएप नहीं खोला जा सका। रसीद संदेश क्लिपबोर्ड पर कॉपी हो गया है!'),
      );
    }
    return launched;
  }

  void _previewWhatsAppMessage() {
    final lang = context.read<ProductionProvider>().settings.appLanguage;
    final provider = context.read<ProductionProvider>();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final empName = _selectedEmployee?.name ?? AppStrings.t(lang, en: 'Employee', gu: 'કર્મચારી', hi: 'कर्मचारी');
    final role = _selectedEmployee?.role ?? 'Operator';
    final gender = _selectedEmployee?.gender ?? 'Male';
    final baseSalary = _selectedEmployee?.monthlySalary ?? 0.0;
    final totalPending = widget.currentPendingUpad + amount;
    final remainingSalary = baseSalary - totalPending;
    final sender = provider.settings.senderPhone.isNotEmpty
        ? provider.settings.senderPhone
        : AppStrings.t(lang, en: '(Admin number not set)', gu: '(વ્યવસ્થાપક નંબર સેટ નથી)', hi: '(व्यवस्थापक नंबर सेट नहीं)');

    final message = WhatsAppService.generateUpadMessage(
      language: _messageLanguage,
      companyName: provider.settings.companyName,
      employeeName: empName,
      role: role,
      gender: gender,
      upadAmount: amount > 0 ? amount : 1000,
      date: DateFormat('dd/MM/yyyy').format(_selectedDate),
      notes: '',
      monthlySalary: baseSalary,
      totalPendingUpad: totalPending,
      remainingSalary: remainingSalary,
      senderPhone: sender,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
              const SizedBox(width: 10),
              Text(
                AppStrings.t(lang, en: 'WhatsApp Receipt Preview', gu: 'WhatsApp રસીદ પ્રીવ્યૂ', hi: 'व्हाट्सएप रसीद पूर्वावलोकन'),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          content: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 450),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECE5DD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1D7DB)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                message,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  color: Color(0xFF111B21),
                  height: 1.4,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.t(lang, en: 'Close', gu: 'બંધ કરો', hi: 'बंद करें')),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(AppStrings.t(lang, en: 'Send Now', gu: 'હમણાં મોકલો', hi: 'अभी भेजें')),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
              onPressed: () {
                Navigator.of(ctx).pop();
                _triggerWhatsApp();
              },
            ),
          ],
        );
      },
    );
  }

  void _save() async {
    final lang = context.read<ProductionProvider>().settings.appLanguage;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null || _selectedEmployee!.id == null) {
      AppSnackBar.showWarning(
        context,
        title: AppStrings.t(lang, en: 'Employee Required', gu: 'કર્મચારી પસંદ કરો', hi: 'कर्मचारी चुनें'),
        message: AppStrings.t(lang, en: 'Please select an employee', gu: 'કૃપા કરીને કર્મચારી પસંદ કરો', hi: 'कृपया कर्मचारी चुनें'),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final upad = EmployeeUpadModel(
      employeeId: _selectedEmployee!.id!,
      employeeName: _selectedEmployee!.name,
      amount: amount,
      date: _selectedDate,
      notes: '',
      isSettled: false,
    );

    if (_sendWhatsApp) {
      await _triggerWhatsApp();
    }

    if (mounted) {
      Navigator.of(context).pop(upad);
    }
  }

  void _printSlipPreview() {
    if (_selectedEmployee == null) return;
    final lang = context.read<ProductionProvider>().settings.appLanguage;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final baseSalary = _selectedEmployee!.monthlySalary;
    final totalUpadAfter = widget.currentPendingUpad + amount;
    final remainingSalary = baseSalary - totalUpadAfter;

    PrintSlipDialog.show(
      context,
      PrintSlipData(
        title: AppStrings.t(lang, en: 'Salary Advance Slip', gu: 'અગ્રિમ પગાર / ઉપાડ પાવતી સ્લિપ', hi: 'अग्रिम वेतन रसीद स्लिप'),
        voucherNo: 'VCH-UPD-${DateTime.now().millisecondsSinceEpoch % 1000000}',
        dateTime: _selectedDate,
        employeeName: _selectedEmployee!.name,
        employeeId: _selectedEmployee!.id,
        role: _selectedEmployee!.role,
        phone: _selectedEmployee!.phone,
        monthlySalary: baseSalary,
        currentAmount: amount,
        totalPendingUpad: totalUpadAfter,
        netPayable: remainingSalary,
        notes: '',
        voucherType: 'advance',
        isOverdraft: remainingSalary < 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<ProductionProvider>().settings.appLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.darkTextPrimary : const Color(0xFF334155);
    final fieldBg = isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC);
    final fieldBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);
    final textStyle = TextStyle(color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A), fontSize: 13.5);

    final baseSalary = _selectedEmployee?.monthlySalary ?? 0.0;
    final totalUpadAfter = widget.currentPendingUpad + _enteredAmount;
    final remainingSalary = baseSalary - totalUpadAfter;
    final isNegative = remainingSalary < 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFD97706), // Warm Amber
                    Color(0xFFF59E0B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payments_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t(lang, en: 'Record Advance', gu: 'ઉપાડ નોંધણી', hi: 'अग्रिम दर्ज करें'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          AppStrings.t(lang,
                              en: 'Record advance payment given to employee',
                              gu: 'કર્મચારીને આપેલ એડવાન્સ ઉપાડની રકમ નોંધો',
                              hi: 'कर्मचारी को दी गई अग्रिम राशि दर्ज करें'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee Selection
                      Text(
                        AppStrings.t(lang, en: 'Select Employee *', gu: 'કર્મચારી પસંદ કરો *', hi: 'कर्मचारी चुनें *'),
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelColor),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<EmployeeModel>(
                        initialValue: _selectedEmployee,
                        isExpanded: true,
                        style: textStyle,
                        dropdownColor: isDark ? AppTheme.darkCardBg : Colors.white,
                        selectedItemBuilder: (context) {
                          return widget.employees.map((emp) {
                            return Row(
                              children: [
                                Text(
                                  emp.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    emp.role,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${AppStrings.t(lang, en: 'Salary', gu: 'પગાર', hi: 'वेतन')}: ₹${emp.monthlySalary.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.badge_outlined, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                          filled: true,
                          fillColor: fieldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: fieldBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: fieldBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5),
                          ),
                        ),
                        items: widget.employees.map((emp) {
                          return DropdownMenuItem(
                            value: emp,
                            child: Row(
                              children: [
                                Text(
                                  emp.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    emp.role,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${AppStrings.t(lang, en: 'Salary', gu: 'પગાર', hi: 'वेतन')}: ₹${emp.monthlySalary.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: widget.preselectedEmployee == null
                            ? (val) => setState(() => _selectedEmployee = val)
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Upad Amount & Date
                      Row(
                        children: [
                          // Amount
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.t(lang, en: 'Advance Amount (₹) *', gu: 'ઉપાડ રકમ (₹) *', hi: 'अग्रिम राशि (₹) *'),
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelColor),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: textStyle,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: AppStrings.t(lang, en: 'e.g. 2000', gu: 'દા.ત. 2000', hi: 'उदा. 2000'),
                                    hintStyle: TextStyle(color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8), fontSize: 13),
                                    prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFFD97706)),
                                    filled: true,
                                    fillColor: fieldBg,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: fieldBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: fieldBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return AppStrings.t(lang, en: 'Please enter advance amount', gu: 'ઉપાડ રકમ દાખલ કરો', hi: 'अग्रिम राशि दर्ज करें');
                                    }
                                    final numVal = double.tryParse(val.trim());
                                    if (numVal == null || numVal <= 0) {
                                      return AppStrings.t(lang, en: 'Please enter valid amount (> 0)', gu: 'માન્ય રકમ (> 0) દાખલ કરો', hi: 'मान्य राशि (> 0) दर्ज करें');
                                    }
                                    if (numVal > 5000000) {
                                      return AppStrings.t(lang,
                                          en: 'Advance amount up to ₹50,00,000 allowed',
                                          gu: 'ઉપાડ રકમ મહત્તમ ₹50,00,000 સુધી જ માન્ય છે',
                                          hi: 'अग्रिम राशि अधिकतम ₹50,00,000 तक मान्य है');
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.t(lang, en: 'Advance Date', gu: 'ઉપાડ તારીખ', hi: 'अग्रिम तारीख'),
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelColor),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                                    decoration: BoxDecoration(
                                      color: fieldBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: fieldBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 18, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                                        const SizedBox(width: 10),
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                                          style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),


                      // Real-time Salary & Upad Computation Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (isNegative ? const Color(0xFF451A1A) : const Color(0xFF064E3B).withValues(alpha: 0.4))
                              : (isNegative ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? (isNegative ? const Color(0xFFDC2626) : const Color(0xFF059669))
                                : (isNegative ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isNegative ? Icons.warning_amber_rounded : Icons.calculate_rounded,
                                  color: isNegative ? const Color(0xFFDC2626) : (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A)),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.t(lang, en: 'Salary & Advance Balance', gu: 'પગાર અને ઉપાડ ગણતરી', hi: 'वेतन एवं अग्रिम संतुलन'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: isDark
                                        ? (isNegative ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC))
                                        : (isNegative ? const Color(0xFF991B1B) : const Color(0xFF166534)),
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 14, color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppStrings.t(lang, en: 'Base Monthly Salary:', gu: 'મૂળ માસિક પગાર:', hi: 'मूल मासिक वेतन:'),
                                    style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569))),
                                Text(
                                  '₹${baseSalary.toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppStrings.t(lang, en: 'Existing Advance:', gu: 'હાલનો બાકી ઉપાડ:', hi: 'मौजूदा बकाया अग्रिम:'),
                                    style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569))),
                                Text(
                                  '- ₹${widget.currentPendingUpad.toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppStrings.t(lang, en: 'New Advance:', gu: 'નવો ઉપાડ:', hi: 'नया अग्रिम:'),
                                    style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569))),
                                Text(
                                  '- ₹${_enteredAmount.toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                            Divider(height: 14, color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.t(lang, en: 'Remaining Salary Balance:', gu: 'ઉપાડ બાદ બાકી પગાર:', hi: 'अग्रिम बाद शेष वेतन:'),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                                ),
                                Text(
                                  '₹${remainingSalary.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: isNegative ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)) : (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.black26 : Colors.white70),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      AppStrings.t(lang,
                                          en: 'Rule: This advance is deducted directly from payroll, not recovered in cash.',
                                          gu: 'નિયમ: આ ઉપાડ કર્મચારી પાસેથી રોકડો પાછો લેવાનો નથી. તે આગામી પગારમાંથી સીધો કટ થશે.',
                                          hi: 'नियम: यह अग्रिम नकद वापस नहीं लेना है, यह अगले वेतन से काटा जाएगा।'),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isNegative) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 14,
                                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      AppStrings.t(lang,
                                          en: 'Warning: Total advance exceeds base salary!',
                                          gu: 'ચેતવણી: કુલ ઉપાડ મૂળ પગાર કરતાં વધી ગયો છે!',
                                          hi: 'चेतावनी: कुल अग्रिम मूल वेतन से अधिक हो गया है!'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // WhatsApp Notification Settings Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF25D366).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppStrings.t(lang, en: 'Send WhatsApp Receipt', gu: 'WhatsApp રસીદ મોકલો', hi: 'व्हाट्सएप रसीद भेजें'),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                            color: isDark ? Colors.white : const Color(0xFF14532D),
                                          ),
                                        ),
                                        Text(
                                          AppStrings.t(lang,
                                              en: 'Employee will receive an instant WhatsApp receipt upon saving',
                                              gu: 'ઉપાડ નોંધતાં જ કર્મચારીને સીધો WhatsApp મેસેજ જશે',
                                              hi: 'अग्रिम दर्ज करते ही कर्मचारी को तुरंत व्हाट्सएप संदेश जाएगा'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Switch.adaptive(
                                  value: _sendWhatsApp,
                                  activeTrackColor: const Color(0xFF25D366).withValues(alpha: 0.5),
                                  activeThumbColor: const Color(0xFF25D366),
                                  onChanged: (val) => setState(() => _sendWhatsApp = val),
                                ),
                              ],
                            ),
                            if (_sendWhatsApp) ...[
                              Divider(height: 12, color: isDark ? const Color(0xFF059669).withValues(alpha: 0.4) : const Color(0xFF86EFAC)),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppStrings.t(lang, en: 'Language:', gu: 'ભાષા:', hi: 'भाषा:'),
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534)),
                                      ),
                                      const SizedBox(width: 6),
                                      ChoiceChip(
                                        label: Text(AppStrings.t(lang, en: 'Both', gu: 'બંને', hi: 'दोनों')),
                                        selected: _messageLanguage == 'Both',
                                        selectedColor: const Color(0xFF25D366).withValues(alpha: 0.25),
                                        backgroundColor: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9),
                                        labelStyle: TextStyle(
                                          color: _messageLanguage == 'Both'
                                              ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534))
                                              : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
                                          fontWeight: _messageLanguage == 'Both' ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 11,
                                        ),
                                        side: BorderSide(color: _messageLanguage == 'Both' ? const Color(0xFF25D366) : fieldBorder),
                                        onSelected: (val) {
                                          if (val) setState(() => _messageLanguage = 'Both');
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      ChoiceChip(
                                        label: const Text('Hindi'),
                                        selected: _messageLanguage == 'Hindi',
                                        selectedColor: const Color(0xFF25D366).withValues(alpha: 0.25),
                                        backgroundColor: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9),
                                        labelStyle: TextStyle(
                                          color: _messageLanguage == 'Hindi'
                                              ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534))
                                              : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
                                          fontWeight: _messageLanguage == 'Hindi' ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 11,
                                        ),
                                        side: BorderSide(color: _messageLanguage == 'Hindi' ? const Color(0xFF25D366) : fieldBorder),
                                        onSelected: (val) {
                                          if (val) setState(() => _messageLanguage = 'Hindi');
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      ChoiceChip(
                                        label: const Text('English'),
                                        selected: _messageLanguage == 'English',
                                        selectedColor: const Color(0xFF25D366).withValues(alpha: 0.25),
                                        backgroundColor: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9),
                                        labelStyle: TextStyle(
                                          color: _messageLanguage == 'English'
                                              ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534))
                                              : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
                                          fontWeight: _messageLanguage == 'English' ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 11,
                                        ),
                                        side: BorderSide(color: _messageLanguage == 'English' ? const Color(0xFF25D366) : fieldBorder),
                                        onSelected: (val) {
                                          if (val) setState(() => _messageLanguage = 'English');
                                        },
                                      ),
                                    ],
                                  ),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.remove_red_eye_outlined, size: 15, color: Color(0xFF25D366)),
                                    label: Text(
                                      AppStrings.t(lang, en: 'Preview', gu: 'પ્રીવ્યૂ', hi: 'पूर्वावलोकन'),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: _previewWhatsAppMessage,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _triggerWhatsApp,
                    icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 16),
                    label: Text(
                      AppStrings.t(lang, en: 'Send WhatsApp', gu: 'WhatsApp મોકલો', hi: 'व्हाट्सएप भेजें'),
                      style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _printSlipPreview,
                    icon: const Icon(Icons.print_rounded, color: Color(0xFF0066FF), size: 16),
                    label: Text(
                      AppStrings.t(lang, en: 'Print Slip', gu: 'સ્લિપ પ્રિન્ટ કરો', hi: 'स्लिप प्रिंट करें'),
                      style: const TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0066FF), width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'રદ કરેં'),
                      style: TextStyle(color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: Text(AppStrings.t(lang, en: 'Save Advance', gu: 'ઉપાડ નોંધો', hi: 'अग्रिम सहेजें'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
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
}
