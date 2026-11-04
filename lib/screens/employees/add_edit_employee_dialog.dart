import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../models/employee_model.dart';
import '../../providers/production_provider.dart';
import 'manage_roles_dialog.dart';

class AddEditEmployeeDialog extends StatefulWidget {
  final EmployeeModel? employee;

  const AddEditEmployeeDialog({super.key, this.employee});

  @override
  State<AddEditEmployeeDialog> createState() => _AddEditEmployeeDialogState();
}

class _AddEditEmployeeDialogState extends State<AddEditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _salaryController;

  late String _selectedRole;
  late String _selectedGender;
  late DateTime _selectedDate;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _nameController = TextEditingController(text: emp?.name ?? '');
    _phoneController = TextEditingController(text: emp?.phone ?? '');
    _salaryController = TextEditingController(
      text: emp != null && emp.monthlySalary > 0
          ? emp.monthlySalary.toStringAsFixed(0)
          : '',
    );

    _selectedRole = (emp?.role ?? 'OPERATOR').trim().toUpperCase();
    _selectedGender = emp?.gender ?? 'Male';
    _selectedDate = emp?.joiningDate ?? DateTime.now();
    _isActive = emp?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final salary = double.tryParse(_salaryController.text.trim()) ?? 0.0;
    final emp = EmployeeModel(
      id: widget.employee?.id,
      name: _nameController.text.trim(),
      role: _selectedRole.trim().toUpperCase(),
      gender: _selectedGender,
      phone: _phoneController.text.trim(),
      joiningDate: _selectedDate,
      monthlySalary: salary,
      isActive: _isActive,
      notes: '',
    );

    Navigator.of(context).pop(emp);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<ProductionProvider>().settings.appLanguage;
    final isEdit = widget.employee != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.darkTextPrimary : const Color(0xFF334155);
    final fieldBg = isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC);
    final fieldBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);
    final textStyle = TextStyle(color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A), fontSize: 13.5);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4F46E5), // Indigo
                    Color(0xFF6366F1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.badge_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isEdit
                                  ? AppStrings.t(lang, en: 'Edit Employee', gu: 'કર્મચારી સુધારો', hi: 'कर्मचारी संपादित करें')
                                  : AppStrings.t(lang, en: 'Add Employee', gu: 'નવો કર્મચારી ઉમેરો', hi: 'नया कर्मचारी जोड़ें'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isEdit && widget.employee?.id != null) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  '#EMP-${widget.employee!.id}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEdit
                              ? AppStrings.t(lang,
                                  en: 'Update employee details and base salary',
                                  gu: 'કર્મચારીની વિગત અને મૂળ પગાર અપડેટ કરો',
                                  hi: 'कर्मचारी विवरण और मूल वेतन अपडेट करें')
                              : AppStrings.t(lang,
                                  en: 'Enter employee details and monthly salary',
                                  gu: 'કર્મચારીની સંપૂર્ણ વિગત અને માસિક પગાર નોંધો',
                                  hi: 'कर्मचारी विवरण और मासिक वेतन दर्ज करें'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
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

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee Name
                      Text(
                        AppStrings.t(lang, en: 'Employee Name *', gu: 'કર્મચારીનું નામ *', hi: 'कर्मचारी का नाम *'),
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelColor),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: textStyle,
                        decoration: InputDecoration(
                          hintText: AppStrings.t(lang, en: 'e.g. Ramesh Bhai Patel', gu: 'દા.ત. રમેશભાઈ પટેલ', hi: 'उदा. रमेश भाई पटेल'),
                          hintStyle: TextStyle(color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: Icon(Icons.person_outline_rounded, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
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
                            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return AppStrings.t(lang,
                                en: 'Please enter name',
                                gu: 'કૃપા કરીને નામ દાખલ કરો',
                                hi: 'कृपया नाम दर्ज करें');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Gender / Salutation Selector
                      Row(
                        children: [
                          Text(
                            AppStrings.t(lang, en: 'Gender / Salutation:', gu: 'લિંગ / સંબોધન:', hi: 'लिंग / संबोधन:'),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelColor),
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.male_rounded, size: 16),
                                const SizedBox(width: 4),
                                Text(AppStrings.t(lang, en: 'Male (Mr.)', gu: 'પુરુષ (ભાઈ)', hi: 'पुरुष (श्री)')),
                              ],
                            ),
                            selected: _selectedGender == 'Male',
                            selectedColor: isDark
                                ? const Color(0xFF4F46E5).withValues(alpha: 0.35)
                                : const Color(0xFF4F46E5).withValues(alpha: 0.15),
                            backgroundColor: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: _selectedGender == 'Male'
                                  ? (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5))
                                  : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
                              fontWeight: _selectedGender == 'Male' ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: _selectedGender == 'Male'
                                  ? const Color(0xFF4F46E5)
                                  : fieldBorder,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedGender = 'Male');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.female_rounded, size: 16),
                                const SizedBox(width: 4),
                                Text(AppStrings.t(lang, en: 'Female (Ms.)', gu: 'સ્ત્રી (બહેન)', hi: 'महिला (सुश्री)')),
                              ],
                            ),
                            selected: _selectedGender == 'Female',
                            selectedColor: isDark
                                ? const Color(0xFFEC4899).withValues(alpha: 0.35)
                                : const Color(0xFFEC4899).withValues(alpha: 0.15),
                            backgroundColor: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: _selectedGender == 'Female'
                                  ? (isDark ? const Color(0xFFF472B6) : const Color(0xFFEC4899))
                                  : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
                              fontWeight: _selectedGender == 'Female' ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: _selectedGender == 'Female'
                                  ? const Color(0xFFEC4899)
                                  : fieldBorder,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedGender = 'Female');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Role and Phone Row
                      Row(
                        children: [
                          // Role Dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppStrings.t(lang, en: 'Role / Designation *', gu: 'રોલ / પદવી *', hi: 'भूमिका / पद *'),
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelColor),
                                    ),
                                    InkWell(
                                      onTap: () => showDialog(
                                        context: context,
                                        builder: (_) => const ManageRolesDialog(),
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.tune_rounded, size: 13, color: Color(0xFF4F46E5)),
                                            const SizedBox(width: 3),
                                            Text(
                                              AppStrings.t(lang, en: 'Manage', gu: 'મેનેજ કરો', hi: 'प्रबंधित करें'),
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (context) {
                                    final provider = context.watch<ProductionProvider>();
                                    final roleSet = <String>{};
                                    for (final r in provider.employeeRoles) {
                                      if (r.trim().isNotEmpty) roleSet.add(r.trim().toUpperCase());
                                    }
                                    if (_selectedRole.isNotEmpty) roleSet.add(_selectedRole.trim().toUpperCase());
                                    final dynamicRoles = roleSet.toList();
                                    final currentValue = dynamicRoles.firstWhere(
                                      (r) => r.trim().toUpperCase() == _selectedRole.trim().toUpperCase(),
                                      orElse: () => dynamicRoles.isNotEmpty ? dynamicRoles.first : 'OPERATOR',
                                    );

                                    return DropdownButtonFormField<String>(
                                      initialValue: currentValue,
                                      style: textStyle,
                                      dropdownColor: isDark ? AppTheme.darkCardBg : Colors.white,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(Icons.work_outline_rounded, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
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
                                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                                        ),
                                      ),
                                      items: dynamicRoles.map((r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(r.trim().toUpperCase(), style: textStyle),
                                      )).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedRole = val.trim().toUpperCase());
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Phone
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.t(lang, en: 'Mobile No.', gu: 'મોબાઇલ નંબર', hi: 'मोबाइल नंबर'),
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelColor),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: textStyle,
                                  decoration: InputDecoration(
                                    hintText: AppStrings.t(lang, en: 'e.g. 9876543210', gu: 'દા.ત. 9876543210', hi: 'उदा. 9876543210'),
                                    hintStyle: TextStyle(color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8), fontSize: 13),
                                    prefixIcon: Icon(Icons.phone_outlined, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
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
                                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Monthly Base Salary and Joining Date
                      Row(
                        children: [
                          // Base Salary
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.t(lang, en: 'Monthly Base Salary (₹) *', gu: 'માસિક મૂળ પગાર (₹) *', hi: 'मासिक मूल वेतन (₹) *'),
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelColor),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _salaryController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: textStyle,
                                  decoration: InputDecoration(
                                    hintText: AppStrings.t(lang, en: 'e.g. 20000', gu: 'દા.ત. 20000', hi: 'उदा. 20000'),
                                    hintStyle: TextStyle(color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8), fontSize: 13),
                                    prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF059669)),
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
                                      borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return AppStrings.t(lang, en: 'Please enter salary', gu: 'પગાર દાખલ કરો', hi: 'कृपया वेतन दर्ज करें');
                                    }
                                    final numVal = double.tryParse(val.trim());
                                    if (numVal == null || numVal < 0) {
                                      return AppStrings.t(lang, en: 'Please enter a valid amount', gu: 'માન્ય રકમ દાખલ કરો', hi: 'मान्य राशि दर्ज करें');
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Joining Date Picker
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.t(lang, en: 'Joining Date', gu: 'જોડાવાની તારીખ', hi: 'शामिल होने की तारीख'),
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
                      const SizedBox(height: 16),

                      // Status Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: fieldBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isActive ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                                  color: _isActive ? const Color(0xFF059669) : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isActive
                                          ? AppStrings.t(lang, en: 'Active Employee', gu: 'સક્રિય કર્મચારી', hi: 'सक्रिय कर्मचारी')
                                          : AppStrings.t(lang, en: 'Inactive Employee', gu: 'નિષ્ક્રિય કર્મચારી', hi: 'निष्क्रिय कर्मचारी'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      _isActive
                                          ? AppStrings.t(lang, en: 'Currently active at factory', gu: 'હાલમાં ફેક્ટરીમાં કામ ચાલુ છે', hi: 'वर्तमान में कारखाने में कार्यरत')
                                          : AppStrings.t(lang, en: 'Inactive / Relieved', gu: 'કામ બંધ / છૂટા થયેલ', hi: 'कार्य बंद / कार्यमुक्त'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: _isActive,
                              activeTrackColor: const Color(0xFF4F46E5).withValues(alpha: 0.5),
                              activeThumbColor: const Color(0xFF4F46E5),
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें'),
                      style: TextStyle(color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      isEdit
                          ? AppStrings.t(lang, en: 'Update', gu: 'અપડેટ કરો', hi: 'अपडेट करें')
                          : AppStrings.t(lang, en: 'Save Employee', gu: 'સાચવો', hi: 'कर्मचारी सहेजें'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
