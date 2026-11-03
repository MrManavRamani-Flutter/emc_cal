import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../providers/production_provider.dart';

class ManageRolesDialog extends StatefulWidget {
  const ManageRolesDialog({super.key});

  @override
  State<ManageRolesDialog> createState() => _ManageRolesDialogState();
}

class _ManageRolesDialogState extends State<ManageRolesDialog> {
  final TextEditingController _newRoleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _newRoleController.dispose();
    super.dispose();
  }

  void _addRole(ProductionProvider provider) async {
    final lang = provider.settings.appLanguage;
    final text = _newRoleController.text.trim();
    if (text.isEmpty) return;

    if (provider.employeeRoles.any((r) => r.toLowerCase() == text.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t(lang,
              en: 'Role "$text" already exists!',
              gu: 'રોલ "$text" પહેલેથી અસ્તિત્વમાં છે!',
              hi: 'भूमिका "$text" पहले से मौजूद है!')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    await provider.addEmployeeRole(text);
    _newRoleController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t(lang,
              en: 'New role "$text" added successfully!',
              gu: 'નવો રોલ "$text" સફળતાપૂર્વક ઉમેરાયો!',
              hi: 'नई भूमिका "$text" सफलतापूर्वक जोड़ी गई!')),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  void _editRoleDialog(BuildContext context, String currentRole, ProductionProvider provider) {
    final lang = provider.settings.appLanguage;
    final editController = TextEditingController(text: currentRole);
    final isDark = AppTheme.isDark(context);
    final cardBg = isDark ? AppTheme.darkCardBg : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B);
    final textMuted = isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B);
    final surfaceSubtle = isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit_rounded, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5), size: 22),
            const SizedBox(width: 10),
            Text(
              AppStrings.t(lang, en: 'Edit Role: $currentRole', gu: 'રોલ બદલો: $currentRole', hi: 'भूमिका बदलें: $currentRole'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t(lang,
                  en: 'Enter new name. All assigned employees will be updated automatically.',
                  gu: 'રોલનું નવું નામ દાખલ કરો. તમામ કર્મચારીઓનો રોલ આપમેળે અપડેટ થઈ જશે.',
                  hi: 'नया नाम दर्ज करें। सभी कर्मचारियों की भूमिका स्वतः अपडेट हो जाएगी।'),
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: editController,
              autofocus: true,
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: AppStrings.t(lang, en: 'New Role Name', gu: 'નવું નામ', hi: 'नया नाम'),
                labelStyle: TextStyle(color: textMuted, fontSize: 13),
                filled: true,
                fillColor: surfaceSubtle,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें'), style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newName = editController.text.trim();
              if (newName.isNotEmpty && newName != currentRole) {
                final messenger = ScaffoldMessenger.of(context);
                await provider.updateEmployeeRole(currentRole, newName);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.t(lang,
                          en: 'Role "$currentRole" renamed to "$newName"!',
                          gu: 'રોલ "$currentRole" બદલીને "$newName" કરવામાં આવ્યો!',
                          hi: 'भूमिका "$currentRole" बदलकर "$newName" की गई!')),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                }
              }
            },
            child: Text(AppStrings.t(lang, en: 'Update', gu: 'અપડેટ કરો', hi: 'अपडेट करें')),
          ),
        ],
      ),
    );
  }

  void _deleteRole(String role, ProductionProvider provider) async {
    final lang = provider.settings.appLanguage;
    final assignedCount = provider.employees.where((e) => e.role == role).length;
    final isDark = AppTheme.isDark(context);
    final cardBg = isDark ? AppTheme.darkCardBg : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B);
    final textSecondary = isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569);
    final textMuted = isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B);

    if (assignedCount > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
              const SizedBox(width: 8),
              Text(AppStrings.t(lang, en: 'Role in Use', gu: 'ચેતવણી (રોલ વપરાશમાં છે)', hi: 'भूमिका उपयोग में है'), style: TextStyle(color: textPrimary)),
            ],
          ),
          content: Text(
            AppStrings.t(lang,
                en: 'This role is currently assigned to $assignedCount employee(s). Do you really want to remove "$role"?',
                gu: 'આ રોલ હાલમાં $assignedCount કર્મચારી(ઓ) સાથે જોડાયેલ છે. શું તમે ખરેખર રોલ "$role" લિસ્ટમાંથી હટાવવા માંગો છો?',
                hi: 'यह भूमिका वर्तमान में $assignedCount कर्मचारी(यों) को सौंपी गई है। क्या आप वास्तव में "$role" हटाना चाहते हैं?'),
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'ના', hi: 'रद्द करें'), style: TextStyle(color: textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppStrings.t(lang, en: 'Yes, Delete', gu: 'હા, હટાવો', hi: 'हाँ, हटाएं')),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    await provider.deleteEmployeeRole(role);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t(lang, en: 'Role "$role" removed.', gu: 'રોલ "$role" હટાવવામાં આવ્યો.', hi: 'भूमिका "$role" हटा दी गई।')),
          backgroundColor: const Color(0xFF334155),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final roles = provider.employeeRoles;
    final isDark = AppTheme.isDark(context);

    final cardBg = isDark ? AppTheme.darkCardBg : Colors.white;
    final surfaceSubtle = isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);
    final inputBorder = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B);
    final textSecondary = isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569);
    final textMuted = isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3730A3) : const Color(0xFF4F46E5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.badge_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t(lang, en: 'Manage Employee Roles', gu: 'રોલ / પદવી મેનેજ કરો', hi: 'कर्मचारी भूमिकाएं प्रबंधित करें'),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.t(lang, en: 'Add, edit or delete employee roles', gu: 'નવા રોલ ઉમેરો, સુધારો અથવા ડિલીટ કરો', hi: 'नई भूमिकाएं जोड़ें, संपादित करें या हटाएं'),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
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

            // Add Role Input Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newRoleController,
                        onSubmitted: (_) => _addRole(provider),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.t(lang,
                              en: 'e.g. Supervisor, Thread Cutter, Folder...',
                              gu: 'દા.ત. Supervisor, Thread Cutter, Folder...',
                              hi: 'उदा. Supervisor, Thread Cutter, Folder...'),
                          hintStyle: TextStyle(color: textMuted, fontSize: 13),
                          labelText: AppStrings.t(lang, en: 'Add New Role', gu: 'નવો રોલ ઉમેરો', hi: 'नई भूमिका जोड़ें'),
                          labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                          prefixIcon: Icon(Icons.work_outline_rounded, size: 20, color: textMuted),
                          filled: true,
                          fillColor: surfaceSubtle,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _addRole(provider),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(AppStrings.t(lang, en: '+ Add', gu: '+ ઉમેરો', hi: '+ जोड़ें'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            Divider(height: 1, thickness: 1, color: borderColor),

            // Roles List
            Expanded(
              child: roles.isEmpty
                  ? Center(
                      child: Text(AppStrings.t(lang, en: 'No roles available.', gu: 'કોઈ રોલ ઉપલબ્ધ નથી.', hi: 'कोई भूमिका उपलब्ध नहीं है।'), style: TextStyle(color: textMuted)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      itemCount: roles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final role = roles[index];
                        final employeeCount = provider.employees.where((e) => e.role == role).length;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: surfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      role,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      employeeCount > 0
                                          ? '$employeeCount ${AppStrings.t(lang, en: 'employees working', gu: 'કર્મચારીઓ કાર્યરત', hi: 'कर्मचारी कार्यरत')}'
                                          : AppStrings.t(lang, en: 'Empty (No employees assigned)', gu: 'ખાલી (કોઈ કર્મચારી નથી)', hi: 'रिक्त (कोई कर्मचारी नहीं)'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: employeeCount > 0 ? const Color(0xFF10B981) : textMuted,
                                        fontWeight: employeeCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Edit Button
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                                ),
                                tooltip: AppStrings.t(lang, en: 'Edit Role', gu: 'રોલ સુધારો', hi: 'भूमिका संपादित करें'),
                                onPressed: () => _editRoleDialog(context, role, provider),
                              ),
                              // Delete Button
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                tooltip: AppStrings.t(lang, en: 'Delete Role', gu: 'રોલ હટાવો', hi: 'भूमिका हटाएं'),
                                onPressed: () => _deleteRole(role, provider),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      side: BorderSide(color: borderColor),
                    ),
                    onPressed: () async {
                      await provider.resetEmployeeRolesToDefault();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.t(lang,
                                en: 'Roles reset to defaults!',
                                gu: 'રોલ ડિફૉલ્ટ લિસ્ટ પર રીસેટ થયા!',
                                hi: 'भूमिकाएं डिफ़ॉल्ट पर रीसेट हुईं!')),
                            backgroundColor: const Color(0xFF334155),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: Text(
                      AppStrings.t(lang, en: 'Reset to Defaults', gu: 'ડિફૉલ્ટ રીસેટ', hi: 'डिफ़ॉल्ट रीसेट'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppStrings.t(lang, en: 'Done', gu: 'પૂર્ણ', hi: 'पूर्ण')),
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
