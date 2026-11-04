import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../core/utils/safe_range_utils.dart';
import '../../models/expense_model.dart';
import '../../providers/production_provider.dart';
import 'manage_expense_categories_dialog.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'ALL';
  String _selectedPeriod = 'ALL'; // 'TODAY', 'MONTH', 'ALL'
  
  // Table sorting
  String _sortColumn = 'date';
  bool _sortAscending = false;

  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _showAll = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddEditExpenseDialog([ExpenseModel? existing]) {
    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isEdit = existing != null;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final paidByController = TextEditingController(text: existing?.paidBy ?? '');
    final customCategoryController = TextEditingController();

    final categoriesList = provider.expenseCategories;
    String selectedCategory = existing?.category ?? (categoriesList.isNotEmpty ? categoriesList.first : 'LIGHT_BILL');
    bool isCustomCategory = false;
    String selectedMode = existing?.paymentMode ?? 'Cash';
    DateTime selectedDate = existing?.date ?? DateTime.now();

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isEdit ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                    color: const Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEdit
                      ? AppStrings.t(lang, en: 'Edit Expense Entry', gu: 'ખર્ચ સુધારો', hi: 'खर्च संपादित करें')
                      : AppStrings.t(lang, en: 'Add Factory Expense', gu: 'નવો કારખાના ખર્ચ નોંધો', hi: 'नया कारखाना खर्च दर्ज करें'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title / Description
                      TextFormField(
                        controller: titleController,
                        autofocus: !isEdit,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          labelText: '${AppStrings.t(lang, en: 'Expense Title / Description', gu: 'ખર્ચ વિગત / નામ', hi: 'खर्च विवरण / नाम')} *',
                          hintText: 'e.g. Factory Electricity Bill, Tea/Breakfast, Needle oil...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter expense description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Amount & Category in Row
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                labelText: '${AppStrings.t(lang, en: 'Amount (₹)', gu: 'રકમ (₹)', hi: 'राशि (₹)')} *',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter amount';
                                final num = double.tryParse(val.trim());
                                if (num == null || num <= 0) return 'Invalid amount';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 6,
                            child: DropdownButtonFormField<String>(
                              // ignore: deprecated_member_use
                              value: isCustomCategory
                                  ? '__NEW__'
                                  : (categoriesList.contains(selectedCategory) ? selectedCategory : 'OTHER'),
                              decoration: InputDecoration(
                                labelText: AppStrings.t(lang, en: 'Category', gu: 'કેટેગરી', hi: 'श्रेणी'),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: [
                                ...categoriesList.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Text(
                                      ExpenseCategories.getLabel(cat, lang),
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                                DropdownMenuItem(
                                  value: '__NEW__',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                      const SizedBox(width: 6),
                                      Text(
                                        AppStrings.t(lang, en: '➕ Add Category...', gu: '➕ નવી કેટેગરી...', hi: '➕ नई श्रेणी...'),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val == '__NEW__') {
                                  setDialogState(() {
                                    isCustomCategory = true;
                                  });
                                } else if (val != null) {
                                  setDialogState(() {
                                    isCustomCategory = false;
                                    selectedCategory = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (isCustomCategory) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: customCategoryController,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            labelText: '${AppStrings.t(lang, en: 'Enter New Category Name', gu: 'નવી કેટેગરીનું નામ લખો', hi: 'नई श्रेणी का नाम दर्ज करें')} *',
                            hintText: AppStrings.t(lang,
                                en: 'e.g. Generator Diesel, Packing Box...',
                                gu: 'દા.ત. જનરેટર ડીઝલ, પેકિંગ બોક્સ...',
                                hi: 'उदा. जनरेटर डीजल, पैकिंग बॉक्स...'),
                            prefixIcon: const Icon(Icons.new_label_rounded, size: 18, color: Color(0xFFEF4444)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              tooltip: 'Cancel',
                              onPressed: () {
                                setDialogState(() {
                                  isCustomCategory = false;
                                  selectedCategory = categoriesList.first;
                                });
                              },
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (val) {
                            if (isCustomCategory && (val == null || val.trim().isEmpty)) {
                              return 'Please enter new category name';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Date & Payment Mode in Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setDialogState(() => selectedDate = picked);
                                }
                              },
                              icon: const Icon(Icons.calendar_month_rounded, size: 16),
                              label: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedMode,
                              decoration: InputDecoration(
                                labelText: AppStrings.t(lang, en: 'Payment Mode', gu: 'ચૂકવણી રીત', hi: 'भुगतान प्रकार'),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: ['Cash', 'Bank / UPI', 'Cheque', 'Other']
                                  .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedMode = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Paid By
                      TextFormField(
                        controller: paidByController,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          labelText: AppStrings.t(lang, en: 'Paid By / Handled By', gu: 'કોણે ચૂકવ્યા (નામ)', hi: 'किसने भुगतान किया'),
                          hintText: 'e.g. Owner, Manager, Cash in hand',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Notes / Receipt
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          labelText: AppStrings.t(lang, en: 'Bill No / Notes / Details', gu: 'બિલ નંબર / ખાસ નોંધ', hi: 'बिल नंबर / विवरण'),
                          hintText: 'Optional bill or receipt memo details',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() != true) return;
                  final title = titleController.text.trim();
                  final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                  final notes = notesController.text.trim();
                  final paidBy = paidByController.text.trim();

                  String finalCategory = selectedCategory;
                  if (isCustomCategory) {
                    final customText = customCategoryController.text.trim();
                    if (customText.isNotEmpty) {
                      final upperKey = customText.toUpperCase().replaceAll(' ', '_');
                      await provider.addExpenseCategory(upperKey);
                      finalCategory = upperKey;
                    }
                  }

                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();

                  final exp = ExpenseModel(
                    id: existing?.id,
                    title: title,
                    amount: amount,
                    category: finalCategory,
                    date: selectedDate,
                    notes: notes,
                    paymentMode: selectedMode,
                    paidBy: paidBy,
                  );

                  if (isEdit) {
                    await provider.updateExpense(exp);
                  } else {
                    await provider.addExpense(exp);
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Expense "$title" updated successfully!'
                              : 'Expense of ₹${amount.toStringAsFixed(2)} recorded!',
                        ),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isEdit
                      ? AppStrings.t(lang, en: 'Save Changes', gu: 'ફેરફાર સાચવો', hi: 'बदलाव सहेजें')
                      : AppStrings.t(lang, en: 'Record Expense', gu: 'ખર્ચ સાચવો', hi: 'खर्च दर्ज करें'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openManageCategoriesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const ManageExpenseCategoriesDialog(),
    );
  }

  void _confirmDeleteExpense(ExpenseModel exp) async {
    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(AppStrings.t(lang, en: 'Delete Expense?', gu: 'ખર્ચ કાઢી નાખવો?', hi: 'खर्च हटाएं?')),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${exp.title}" (₹${exp.amount.toStringAsFixed(2)})?',
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

    if (confirm == true && exp.id != null) {
      await provider.deleteExpense(exp.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense "${exp.title}" deleted.'),
            backgroundColor: const Color(0xFF334155),
            action: SnackBarAction(
              label: 'Undo',
              textColor: const Color(0xFF60A5FA),
              onPressed: () async {
                await provider.addExpense(exp);
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
    final lang = provider.settings.appLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allExpenses = provider.expenses;
    final now = DateTime.now();

    // Compute Metrics
    final todayExpenses = allExpenses
        .where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day)
        .fold<double>(0.0, (s, e) => s + e.amount);

    final monthExpenses = allExpenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0.0, (s, e) => s + e.amount);

    final totalExpenses = allExpenses.fold<double>(0.0, (s, e) => s + e.amount);

    // Filter logic
    final searchQuery = _searchController.text.trim().toLowerCase();
    List<ExpenseModel> filtered = allExpenses.where((e) {
      if (_selectedCategory != 'ALL' && e.category != _selectedCategory) return false;
      if (_selectedPeriod == 'TODAY') {
        if (e.date.year != now.year || e.date.month != now.month || e.date.day != now.day) return false;
      } else if (_selectedPeriod == 'MONTH') {
        if (e.date.year != now.year || e.date.month != now.month) return false;
      }
      if (searchQuery.isNotEmpty) {
        final matchTitle = e.title.toLowerCase().contains(searchQuery);
        final matchCategory = e.category.toLowerCase().contains(searchQuery);
        final matchNotes = e.notes.toLowerCase().contains(searchQuery);
        final matchPaidBy = e.paidBy.toLowerCase().contains(searchQuery);
        if (!matchTitle && !matchCategory && !matchNotes && !matchPaidBy) return false;
      }
      return true;
    }).toList();

    // Sort logic
    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortColumn) {
        case 'title':
          cmp = a.title.compareTo(b.title);
          break;
        case 'category':
          cmp = a.category.compareTo(b.category);
          break;
        case 'amount':
          cmp = a.amount.compareTo(b.amount);
          break;
        case 'paymentMode':
          cmp = a.paymentMode.compareTo(b.paymentMode);
          break;
        case 'date':
        default:
          cmp = a.date.compareTo(b.date);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    final totalFilteredAmount = filtered.fold<double>(0.0, (s, e) => s + e.amount);

    // Pagination slice using SafeRangeUtils
    final int totalRecords = filtered.length;
    final int totalPages = _showAll ? 1 : (totalRecords <= 0 ? 1 : ((totalRecords - 1) ~/ _pageSize) + 1);
    final int safeCurrentPage = SafeRangeUtils.safePage(_currentPage, totalPages);
    final List<ExpenseModel> pageItems = _showAll
        ? filtered
        : SafeRangeUtils.safePageSlice(filtered, safeCurrentPage, _pageSize);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkScaffoldBg : const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFEF4444), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.t(lang,
                            en: 'Factory General Expenses & Ledger',
                            gu: 'કારખાના સામાન્ય ખર્ચ અને ખાતાવહી',
                            hi: 'कारखाना सामान्य खर्च एवं बहीखाता'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.t(lang,
                            en: 'Electricity, factory rent, repairs, tea, machine spares and daily operating costs',
                            gu: 'લાઈટબિલ, ભાડું, રિપેરિંગ, ચા-પાણી, મશીન પાર્ટ્સ અને દૈનિક ખર્ચ હિસાબ',
                            hi: 'बिजली, किराया, मरम्मत, चाय-नाश्ता, मशीन पार्ट्स और दैनिक खर्च हिसाब'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openManageCategoriesDialog,
                  icon: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF6366F1)),
                  label: Text(
                    AppStrings.t(lang, en: 'Manage Categories', gu: 'કેટેગરી મેનેજ કરો', hi: 'श्रेणियां प्रबंधित करें'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    side: BorderSide(color: isDark ? const Color(0xFF6366F1).withValues(alpha: 0.5) : const Color(0xFFC7D2FE)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _openAddEditExpenseDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    AppStrings.t(lang, en: 'Add Expense', gu: 'ખર્ચ નોંધો', hi: 'खर्च जोड़ें'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // Main Scrollable Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 4 Metric KPI Cards
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      final card1 = _buildKpiCard(
                        title: AppStrings.t(lang, en: "Today's Expense", gu: 'આજનો ખર્ચ', hi: 'आज का खर्च'),
                        amount: todayExpenses,
                        icon: Icons.today_rounded,
                        color: const Color(0xFFEF4444),
                        bgColor: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2),
                        isDark: isDark,
                      );
                      final card2 = _buildKpiCard(
                        title: AppStrings.t(lang, en: "This Month's Expense", gu: 'આ મહિનાનો ખર્ચ', hi: 'इस महीने का खर्च'),
                        amount: monthExpenses,
                        icon: Icons.calendar_month_rounded,
                        color: const Color(0xFFF59E0B),
                        bgColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFFBEB),
                        isDark: isDark,
                      );
                      final card3 = _buildKpiCard(
                        title: AppStrings.t(lang, en: 'Total Factory Expenses', gu: 'કુલ કારખાના ખર્ચ', hi: 'कुल कारखाना खर्च'),
                        amount: totalExpenses,
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF6366F1),
                        bgColor: isDark ? const Color(0xFF312E81).withValues(alpha: 0.3) : const Color(0xFFEEF2FF),
                        isDark: isDark,
                      );
                      final card4 = _buildKpiCard(
                        title: AppStrings.t(lang, en: 'Total Filtered Amount', gu: 'ફિલ્ટર કરેલ કુલ ખર્ચ', hi: 'फिल्टर किया गया खर्च'),
                        amount: totalFilteredAmount,
                        icon: Icons.filter_alt_rounded,
                        color: const Color(0xFF10B981),
                        bgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
                        isDark: isDark,
                        subtitle: '${filtered.length} Records',
                      );

                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(child: card1),
                            const SizedBox(width: 14),
                            Expanded(child: card2),
                            const SizedBox(width: 14),
                            Expanded(child: card3),
                            const SizedBox(width: 14),
                            Expanded(child: card4),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            Row(children: [Expanded(child: card1), const SizedBox(width: 14), Expanded(child: card2)]),
                            const SizedBox(height: 14),
                            Row(children: [Expanded(child: card3), const SizedBox(width: 14), Expanded(child: card4)]),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 18),

                  // Filter Bar & Search
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search and Period row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  hintText: AppStrings.t(lang,
                                      en: 'Search by title, notes, paid by or category...',
                                      gu: 'ખર્ચ નામ, નોંધ અથવા ચૂકવનાર શોધો...',
                                      hi: 'नाम, विवरण या भुगतानकर्ता से खोजें...'),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onChanged: (_) => setState(() {
                                  _currentPage = 1;
                                }),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Period Filter Chips
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'ALL', label: Text('All Time')),
                                ButtonSegment(value: 'MONTH', label: Text('This Month')),
                                ButtonSegment(value: 'TODAY', label: Text('Today')),
                              ],
                              selected: {_selectedPeriod},
                              onSelectionChanged: (val) {
                                setState(() {
                                  _selectedPeriod = val.first;
                                  _currentPage = 1;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Category Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('ALL CATEGORIES'),
                                selected: _selectedCategory == 'ALL',
                                onSelected: (_) => setState(() {
                                  _selectedCategory = 'ALL';
                                  _currentPage = 1;
                                }),
                              ),
                              const SizedBox(width: 8),
                              ...provider.expenseCategories.map((cat) {
                                final isSelected = _selectedCategory == cat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(ExpenseCategories.getLabel(cat, lang)),
                                    selected: isSelected,
                                    onSelected: (_) => setState(() {
                                      _selectedCategory = cat;
                                      _currentPage = 1;
                                    }),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Data Table Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                          ),
                          child: Row(
                            children: [
                              _buildSortableHeader('#', '', flex: 1),
                              _buildSortableHeader('Date', 'date', flex: 2),
                              _buildSortableHeader('Title / Description', 'title', flex: 4),
                              _buildSortableHeader('Category', 'category', flex: 3),
                              _buildSortableHeader('Amount (₹)', 'amount', flex: 2),
                              _buildSortableHeader('Mode', 'paymentMode', flex: 2),
                              _buildSortableHeader('Paid By / Notes', '', flex: 3),
                              const SizedBox(
                                width: 70,
                                child: Text('Actions', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),

                        // Table Body
                        if (pageItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.inbox_rounded, size: 40, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No expense records found matching filters',
                                    style: TextStyle(color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pageItems.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: isDark ? AppTheme.darkBorder.withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (ctx, idx) {
                              final exp = pageItems[idx];
                              final rowIdx = _showAll ? idx + 1 : ((safeCurrentPage - 1) * _pageSize) + idx + 1;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '$rowIdx',
                                        style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        DateFormat('dd-MM-yyyy').format(exp.date),
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        exp.title,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          ExpenseCategories.getLabel(exp.category, lang),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '₹${NumberFormat('#,##,###.00').format(exp.amount)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        exp.paymentMode,
                                        style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        exp.notes.isNotEmpty
                                            ? exp.notes
                                            : (exp.paidBy.isNotEmpty ? 'Paid by: ${exp.paidBy}' : '-'),
                                        style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 70,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_rounded, size: 16),
                                            color: const Color(0xFF3B82F6),
                                            onPressed: () => _openAddEditExpenseDialog(exp),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                            color: const Color(0xFFEF4444),
                                            onPressed: () => _confirmDeleteExpense(exp),
                                            tooltip: 'Delete',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        // Pagination Footer with Show All toggle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                            border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${pageItems.length} of $totalRecords records (Total: ₹${NumberFormat('#,##,###.00').format(totalFilteredAmount)})',
                                style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                              ),
                              Row(
                                children: [
                                  // Show All checkbox
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: _showAll,
                                        onChanged: (val) {
                                          setState(() {
                                            _showAll = val ?? false;
                                            _currentPage = 1;
                                          });
                                        },
                                      ),
                                      const Text('Show All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  if (!_showAll) ...[
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                                      onPressed: safeCurrentPage > 1
                                          ? () => setState(() => _currentPage = safeCurrentPage - 1)
                                          : null,
                                    ),
                                    Text(
                                      '$safeCurrentPage / $totalPages',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                                      onPressed: safeCurrentPage < totalPages
                                          ? () => setState(() => _currentPage = safeCurrentPage + 1)
                                          : null,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(String title, String colKey, {required int flex}) {
    final isSelected = _sortColumn == colKey && colKey.isNotEmpty;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: colKey.isEmpty
            ? null
            : () {
                setState(() {
                  if (_sortColumn == colKey) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortColumn = colKey;
                    _sortAscending = true;
                  }
                });
              },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFEF4444) : null,
              ),
            ),
            if (colKey.isNotEmpty) ...[
              const SizedBox(width: 4),
              Icon(
                isSelected
                    ? (_sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                    : Icons.unfold_more_rounded,
                size: 13,
                color: isSelected ? const Color(0xFFEF4444) : Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isDark,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${NumberFormat('#,##,###.00').format(amount)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
