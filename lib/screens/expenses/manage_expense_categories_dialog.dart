import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../models/expense_model.dart';
import '../../models/settings_model.dart';
import '../../providers/production_provider.dart';

class ManageExpenseCategoriesDialog extends StatefulWidget {
  const ManageExpenseCategoriesDialog({super.key});

  @override
  State<ManageExpenseCategoriesDialog> createState() => _ManageExpenseCategoriesDialogState();
}

class _ManageExpenseCategoriesDialogState extends State<ManageExpenseCategoriesDialog> {
  final TextEditingController _newCategoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  void _addCategory(ProductionProvider provider) async {
    final lang = provider.settings.appLanguage;
    final text = _newCategoryController.text.trim();
    if (text.isEmpty) return;

    final upperKey = text.toUpperCase().replaceAll(' ', '_');
    if (provider.expenseCategories.any((c) => c.trim().toUpperCase() == upperKey || c.trim().toUpperCase() == text.toUpperCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t(lang,
              en: 'Category "$text" already exists!',
              gu: 'કેટેગરી "$text" પહેલેથી અસ્તિત્વમાં છે!',
              hi: 'श्रेणी "$text" पहले से मौजूद है!')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    await provider.addExpenseCategory(upperKey);
    _newCategoryController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t(lang,
              en: 'New expense category "$text" added successfully!',
              gu: 'નવી ખર્ચ કેટેગરી "$text" સફળતાપૂર્વક ઉમેરાઈ!',
              hi: 'नई खर्च श्रेणी "$text" सफलतापूर्वक जोड़ी गई!')),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  void _editCategoryDialog(BuildContext context, String currentCategory, ProductionProvider provider) {
    final lang = provider.settings.appLanguage;
    final editController = TextEditingController(text: currentCategory);
    final isDark = AppTheme.isDark(context);
    final cardBg = isDark ? AppTheme.darkCardBg : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit_rounded, color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 10),
            Text(
              AppStrings.t(lang, en: 'Edit Category', gu: 'કેટેગરી બદલો', hi: 'श्रेणी बदलें'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: ${ExpenseCategories.getLabel(currentCategory, lang)} ($currentCategory)',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: editController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppStrings.t(lang, en: 'New Name', gu: 'નવું નામ', hi: 'नया नाम'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = editController.text.trim().toUpperCase().replaceAll(' ', '_');
              if (newName.isNotEmpty && newName != currentCategory) {
                await provider.updateExpenseCategory(currentCategory, newName);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: Text(AppStrings.t(lang, en: 'Save', gu: 'સાચવો', hi: 'सहेजें')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, String category, int usageCount, ProductionProvider provider) async {
    final lang = provider.settings.appLanguage;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            const SizedBox(width: 8),
            Text(AppStrings.t(lang,
                en: 'Delete Category ($category)?',
                gu: 'કેટેગરી કાઢી નાખવી ($category)?',
                hi: 'श्रेणी हटाएं ($category)?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t(lang,
                  en: 'Are you sure you want to remove this category from the active list?',
                  gu: 'શું તમે આ કેટેગરીને લિસ્ટમાંથી કાઢી નાખવા માંગો છો?',
                  hi: 'क्या आप इस श्रेणी को सूची से हटाना चाहते हैं?'),
              style: const TextStyle(fontSize: 14),
            ),
            if (usageCount > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  'Note: $usageCount expense records are currently using this category. Existing records will remain safe.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.t(lang, en: 'Delete', gu: 'કાઢી નાખો', hi: 'हटाएं')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.deleteExpenseCategory(category);
    }
  }

  void _confirmResetDefaults(BuildContext context, ProductionProvider provider) async {
    final lang = provider.settings.appLanguage;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.restart_alt_rounded, color: Color(0xFFF59E0B), size: 24),
            const SizedBox(width: 8),
            Text(AppStrings.t(lang,
                en: 'Reset to Factory Defaults?',
                gu: 'મૂળ કેટેગરી રીસેટ કરવી?',
                hi: 'मूल श्रेणियों पर रीसेट करें?')),
          ],
        ),
        content: Text(
          AppStrings.t(lang,
              en: 'This will restore the 18 standard factory operating expense categories.',
              gu: 'આ કારખાનાની તમામ ૧૮ મૂળભૂત ખર્ચ કેટેગરીઝ ફરીથી સેટ કરશે.',
              hi: 'यह कारखाने की सभी 18 मानक खर्च श्रेणियों को पुनर्स्थापित करेगा।'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.t(lang, en: 'Reset Defaults', gu: 'રીસેટ કરો', hi: 'रीसेट करें')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.resetExpenseCategoriesToDefault();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final isDark = AppTheme.isDark(context);
    final cardBg = isDark ? AppTheme.darkCardBg : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B);
    final textMuted = isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B);
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);
    final surfaceSubtle = isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC);

    final categories = provider.expenseCategories;
    final expenses = provider.expenses;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.category_rounded, color: Color(0xFFEF4444), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t(lang,
                              en: 'Manage Expense Categories',
                              gu: 'કારખાના ખર્ચ કેટેગરીઝ',
                              hi: 'कारखाना खर्च श्रेणियां'),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.t(lang,
                              en: 'Add, edit, or customize operating expense categories for your factory',
                              gu: 'કારખાનાના તમામ દૈનિક ખર્ચાઓ માટે કેટેગરી ઉમેરો અથવા બદલો',
                              hi: 'कारखाने के दैनिक खर्चों के लिए श्रेणी जोड़ें या संपादित करें'),
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Add New Category Row
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _newCategoryController,
                        decoration: InputDecoration(
                          hintText: AppStrings.t(lang,
                              en: 'e.g. Generator Diesel, Packing Box...',
                              gu: 'દા.ત. જનરેટર ડીઝલ, પેકિંગ બોક્સ...',
                              hi: 'उदा. जनरेटर डीजल, पैकिंग बॉक्स...'),
                          prefixIcon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onFieldSubmitted: (_) => _addCategory(provider),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _addCategory(provider),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        AppStrings.t(lang, en: 'Add', gu: 'ઉમેરો', hi: 'जोड़ें'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Category List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppStrings.t(lang, en: 'Active Categories', gu: 'એક્ટિવ કેટેગરીઝ', hi: 'सक्रिय श्रेणियां')} (${categories.length})',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmResetDefaults(context, provider),
                    icon: const Icon(Icons.restore_rounded, size: 15),
                    label: Text(
                      AppStrings.t(lang, en: 'Reset Defaults', gu: 'મૂળ કેટેગરીઝ', hi: 'मूल श्रेणियां'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Categories Scrollable List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                    itemBuilder: (ctx, index) {
                      final cat = categories[index];
                      final count = expenses.where((e) => e.category.trim().toUpperCase() == cat.trim().toUpperCase()).length;
                      final isDefault = SettingsModel.defaultExpenseCategories.contains(cat);
                      final label = ExpenseCategories.getLabel(cat, lang);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.label_rounded, size: 16, color: Color(0xFFEF4444)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Code: $cat${isDefault ? " • Standard" : " • Custom"}',
                                    style: TextStyle(fontSize: 11, color: textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: count > 0
                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$count entries',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: count > 0 ? const Color(0xFF10B981) : textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 17),
                              tooltip: 'Edit',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _editCategoryDialog(context, cat, provider),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFDC2626)),
                              tooltip: 'Delete',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _confirmDeleteCategory(context, cat, count, provider),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    foregroundColor: textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(AppStrings.t(lang, en: 'Done', gu: 'પૂર્ણ', hi: 'संपन्न')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

