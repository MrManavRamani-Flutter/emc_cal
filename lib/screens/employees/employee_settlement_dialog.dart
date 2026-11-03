import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/app_dialog.dart';
import '../../models/employee_model.dart';
import '../../models/employee_upad_model.dart';
import '../../providers/production_provider.dart';
import '../../widgets/print_slip_dialog.dart';

/// Clean, theme-aware Dialog for Monthly Salary Payout & Upad Deduction
class EmployeeSettlementDialog extends StatelessWidget {
  final EmployeeModel employee;
  final List<EmployeeUpadModel> pendingUpads;
  final VoidCallback onSettleConfirmed;

  const EmployeeSettlementDialog({
    super.key,
    required this.employee,
    required this.pendingUpads,
    required this.onSettleConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<ProductionProvider>().settings.appLanguage;
    final isDark = AppTheme.isDark(context);
    final border = AppTheme.border(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    final totalUpad = pendingUpads.fold<double>(0.0, (s, u) => s + u.amount);
    final netPayable = (employee.monthlySalary - totalUpad).clamp(0.0, double.infinity);
    final isNegative = (employee.monthlySalary - totalUpad) < 0;

    return AppDialog(
      title: AppStrings.t(lang, en: 'Salary Settlement', gu: 'પગાર ચૂકવણી હિસાબ', hi: 'वेतन निपटान'),
      subtitle: '${employee.name} (${employee.role}) - ${AppStrings.t(lang, en: 'Monthly salary payout and advance deduction', gu: 'માસિક પગાર ચૂકવણી અને ઉપાડ કપાત', hi: 'मासिक वेतन भुगतान और अग्रिम कटौती')}',
      icon: Icons.price_check_rounded,
      maxWidth: 580,
      confirmLabel: AppStrings.t(lang, en: 'Confirm Settlement & Pay', gu: 'પગાર ચૂકવો અને હિસાબ કમ્પ્લીટ કરો', hi: 'वेतन भुगतान करें और निपटान पूरा करें'),
      onConfirm: () {
        Navigator.of(context).pop();
        onSettleConfirmed();
      },
      customActions: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0066FF),
            side: const BorderSide(color: Color(0xFF0066FF)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.print_rounded, size: 16),
          label: Text(
            AppStrings.t(lang, en: 'Print Salary Slip', gu: 'પગાર પાવતી સ્લિપ પ્રિન્ટ કરો', hi: 'वेतन रसीद स्लिप प्रिंट करें'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          onPressed: () {
            PrintSlipDialog.show(
              context,
              PrintSlipData(
                title: AppStrings.t(lang, en: 'Salary Settlement Receipt', gu: 'પગાર ચૂકવણી પાવતી', hi: 'वेतन निपटान रसीद'),
                voucherNo: 'VCH-STL-${DateTime.now().millisecondsSinceEpoch % 1000000}',
                dateTime: DateTime.now(),
                employeeName: employee.name,
                employeeId: employee.id,
                role: employee.role,
                phone: employee.phone,
                monthlySalary: employee.monthlySalary,
                currentAmount: totalUpad,
                totalPendingUpad: 0.0,
                netPayable: netPayable,
                voucherType: 'settlement',
                isOverdraft: isNegative,
                notes: isNegative
                    ? 'Excess advance of ₹${(totalUpad - employee.monthlySalary).toStringAsFixed(0)} carried forward to next month.'
                    : 'Monthly salary fully settled and paid.',
              ),
            );
          },
        ),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clear Factory Math Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.t(lang, en: '1. Base Monthly Salary:', gu: '૧. મૂળ માસિક પગાર:', hi: '१. मूल मासिक वेतन:'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF065F46),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${employee.monthlySalary.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.t(lang, en: '2. Advance Deducted This Month:', gu: '૨. આ મહિને આપેલ ઉપાડ (કપાત):', hi: '२. इस माह का अग्रिम (कटौती):'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '- ₹${totalUpad.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
                Divider(
                  height: 20,
                  color: isDark ? const Color(0xFF059669).withValues(alpha: 0.4) : const Color(0xFFA7F3D0),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.t(lang, en: 'Net Payout to Worker:', gu: 'હાથમાં ચૂકવવાપાત્ર ચોખ્ખો પગાર:', hi: 'श्रमिक को शुद्ध देय वेतन:'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                      ),
                    ),
                    Text(
                      '₹${netPayable.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
                if (isNegative) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerRedLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.dangerRed),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.dangerRed),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppStrings.t(lang,
                                en: 'Notice: Total advance exceeds salary by ₹${(totalUpad - employee.monthlySalary).toStringAsFixed(0)}. Excess advance carries forward to next month.',
                                gu: 'ધ્યાન આપો: આ મહિને લીધેલ કુલ ઉપાડ માસિક પગાર કરતાં ₹${(totalUpad - employee.monthlySalary).toStringAsFixed(0)} વધી ગયો છે. આ વધારાની રકમ આપોઆપ આવતા મહિનાના ઉપાડમાં કૅરી-ફૉરવર્ડ (બાકી ઉપાડ) તરીકે નોંધાશે.',
                                hi: 'ध्यान दें: कुल अग्रिम मासिक वेतन से ₹${(totalUpad - employee.monthlySalary).toStringAsFixed(0)} अधिक है। यह अतिरिक्त राशि अगले माह में अग्रिम के रूप में ले जाई जाएगी।'),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.dangerRedDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Business Rule Notice Card (As instructed by User)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF0284C7)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isNegative
                        ? AppStrings.t(lang,
                            en: 'Important Rule: Since advance exceeds salary by ₹${(totalUpad - employee.monthlySalary).toStringAsFixed(0)}, net payout is ₹0. Excess advance carries forward to next month.',
                            gu: 'મહત્વપૂર્ણ નિયમ: કર્મચારીનો ઉપાડ પગાર કરતાં ₹${(totalUpad - employee.monthlySalary).toStringAsFixed(0)} વધુ હોવાથી, આ મહિને હાથમાં કોઈ પગાર ચૂકવાશે નહીં (₹0). વધારાનો ઉપાડ આપોઆપ આગામી મહિનાના ખાતામાં કૅરી-ફૉરવર્ડ થઈ જશે જેથી હિસાબમાં કોઈ ખોટ ન આવે.',
                            hi: 'महत्वपूर्ण नियम: अग्रिम वेतन से ₹${(totalUpad - employee.monthlySalary).toStringAsFixed(0)} अधिक होने के कारण इस माह कोई भुगतान नहीं होगा (₹0)। अतिरिक्त अग्रिम अगले माह में कैरी-फॉरवर्ड होगा।')
                        : AppStrings.t(lang,
                            en: 'Important Rule: Advance is not recovered in cash; it is deducted directly from monthly payroll. Only net amount (₹${netPayable.toStringAsFixed(0)}) is payable.',
                            gu: 'મહત્વપૂર્ણ નિયમ: કર્મચારી પાસેથી ઉપાડ રોકડો પાછો લેવાનો નથી. ઉપાડ તેમના આ મહિનાના પગારમાંથી સીધો કટ થઈ ચૂક્યો છે. હવે તેમને માત્ર ચોખ્ખી રકમ (₹${netPayable.toStringAsFixed(0)}) જ હાથમાં ચૂકવવાની છે.',
                            hi: 'महत्वपूर्ण नियम: अग्रिम नकद वापस नहीं लेना है, यह वेतन से कट चुका है। अब केवल शुद्ध राशि (₹${netPayable.toStringAsFixed(0)}) ही देय है।'),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Upad History Items Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.t(lang, en: 'Advance Details This Month', gu: 'આ મહિને આપેલ ઉપાડ વિગતો', hi: 'इस माह का अग्रिम विवरण')} (${pendingUpads.length} ${AppStrings.t(lang, en: 'entries', gu: 'વખત', hi: 'प्रविष्टियां')})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: textPrimary,
                ),
              ),
              if (pendingUpads.isEmpty)
                Text(
                  AppStrings.t(lang, en: 'No advance taken', gu: 'કોઈ ઉપાડ લીધેલ નથી', hi: 'कोई अग्रिम नहीं लिया गया'),
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Upad Items List
          if (pendingUpads.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: Center(
                child: Text(
                  AppStrings.t(lang,
                      en: 'This employee has taken no advance this month. Full salary is payable.',
                      gu: 'આ કર્મચારીએ આ મહિને કોઈ ઉપાડ લીધેલ નથી. પૂરો પગાર ચૂકવવાપાત્ર છે.',
                      hi: 'इस कर्मचारी ने इस माह कोई अग्रिम नहीं लिया है। पूरा वेतन देय है।'),
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingUpads.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: border),
                itemBuilder: (context, index) {
                  final upad = pendingUpads[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.remove_circle_outline_rounded, size: 16, color: Color(0xFFD97706)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(upad.date),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: textPrimary,
                                ),
                              ),
                              if (upad.notes.isNotEmpty)
                                Text(
                                  upad.notes,
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${upad.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
