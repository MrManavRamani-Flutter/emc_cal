import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../models/account_model.dart';
import '../../models/production_record.dart';
import '../../providers/production_provider.dart';
import 'add_edit_record_dialog.dart';
import 'daily_batch_entry_matrix_dialog.dart';
import '../../widgets/widgets.dart';

class ProductionEntryScreen extends StatefulWidget {
  const ProductionEntryScreen({super.key});

  @override
  State<ProductionEntryScreen> createState() => _ProductionEntryScreenState();
}

class _ProductionEntryScreenState extends State<ProductionEntryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  DateTime? _filterDate;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => const AddEditRecordDialog(),
    );
  }

  void _openMatrixDialog() {
    showDialog(
      context: context,
      builder: (_) => const DailyBatchEntryMatrixDialog(),
    );
  }

  void _openEditDialog() {
    final provider = context.read<ProductionProvider>();
    ProductionRecord? target;
    if (provider.selectedIds.length == 1) {
      final id = provider.selectedIds.first;
      target = provider.allRecords.cast<ProductionRecord?>().firstWhere(
            (r) => r?.id == id,
            orElse: () => null,
          );
    }
    target ??= provider.entrySelectedRecord;

    if (target != null) {
      showDialog(
        context: context,
        builder: (_) => AddEditRecordDialog(existingRecord: target),
      );
    }
  }

  void _confirmDelete() async {
    final provider = context.read<ProductionProvider>();
    final selectedCount = provider.selectedIds.length;
    final target = provider.entrySelectedRecord;

    if (selectedCount == 0 && target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a record to delete')),
      );
      return;
    }

    final lang = provider.settings.appLanguage;
    final binName = AppStrings.get('recycleBin', lang);

    String message;
    if (lang == 'gu') {
      message = selectedCount > 0
          ? 'શું તમે ખરેખર પસંદ કરેલા $selectedCount રેકોર્ડ્સ ડિલીટ કરવા માંગો છો?\n\nતે સુરક્ષિત રીતે $binName માં જશે અને ગમે ત્યારે પાછા લાવી શકાય છે.'
          : 'શું તમે ખરેખર ${target?.designNo} (${target?.machineNo}) નો રેકોર્ડ ડિલીટ કરવા માંગો છો?\n\nતે સુરક્ષિત રીતે $binName માં જશે અને ગમે ત્યારે પાછા લાવી શકાય છે.';
    } else if (lang == 'hi') {
      message = selectedCount > 0
          ? 'क्या आप वास्तव में चयनित $selectedCount रिकॉर्ड्स हटाना चाहते हैं?\n\nये सुरक्षित रूप से $binName में जाएँगे और कभी भी वापस लाए जा सकते हैं।'
          : 'क्या आप वास्तव में ${target?.designNo} (${target?.machineNo}) का रिकॉर्ड हटाना चाहते हैं?\n\nयह सुरक्षित रूप से $binName में जाएगा और कभी भी वापस लाया जा सकता है।';
    } else {
      message = selectedCount > 0
          ? 'Are you sure you want to delete $selectedCount selected records?\n\nThey will be safely moved to $binName and can be restored anytime.'
          : 'Are you sure you want to delete record ${target?.designNo} (${target?.machineNo})?\n\nIt will be safely moved to $binName and can be restored anytime.';
    }

    final confirmed = await ConfirmDeleteDialog.show(
      context: context,
      title: lang == 'gu' ? '$binName માં મોકલો' : (lang == 'hi' ? '$binName में भेजें' : 'Move to $binName'),
      message: message,
      confirmLabel: AppStrings.t(lang, en: 'Move to Bin', gu: '$binName માં મોકલો', hi: '$binName में भेजें'),
    );

    if (confirmed) {
      final count = selectedCount > 0 ? selectedCount : 1;
      if (selectedCount > 0) {
        await provider.deleteSelectedRecords();
      } else if (target?.id != null) {
        await provider.deleteRecord(target!.id!);
      }
      if (mounted) {
        final snackText = lang == 'gu'
            ? '$count રેકોર્ડ્સ $binName માં ગયા. તમે ગમે ત્યારે પાછા લાવી શકો છો.'
            : (lang == 'hi'
                ? '$count रिकॉर्ड्स $binName में चले गए। आप कभी भी वापस ला सकते हैं।'
                : '$count record(s) moved to $binName. You can restore anytime.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackText),
            action: SnackBarAction(
              label: 'Open Bin',
              textColor: Colors.amberAccent,
              onPressed: () => provider.setActiveNavIndex(11),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() => _filterDate = picked);
      if (mounted) {
        context.read<ProductionProvider>().setDateRange(picked, picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final currency = provider.settings.currencySymbol;
    final records = provider.paginatedRecords;
    final totalFiltered = provider.filteredRecords.length;
    final allSelected = records.isNotEmpty && records.every((r) => provider.selectedIds.contains(r.id));
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);
    final isDark = provider.settings.isDarkMode;

    final bool canEdit = (provider.selectedIds.length == 1) ||
        (provider.selectedIds.isEmpty && provider.entrySelectedRecord != null);
    final bool hasSelection = provider.selectedIds.isNotEmpty || provider.entrySelectedRecord != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Category Overview Cards (Dynamically reflects Beads, 250 Area, 400 Area, etc.)
          _buildCategoryOverviewCards(context, provider, accent, isDark),

          // Main Body: Records Table + Collapsible Calculation Details Side Panel
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Table Container
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Column(
                      children: [
                        // Top Toolbar: + Add Record | Edit | Delete | Khata Filter | Search | Date
                        Row(
                          children: [
                            // + Add Record
                            ElevatedButton.icon(
                              onPressed: _openAddDialog,
                              icon: AppSvgIcon.add(size: 16, color: Colors.white),
                              label: const Text('Add Record'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // ⚡ Batch Matrix Entry (M01-08)
                            ElevatedButton.icon(
                              onPressed: _openMatrixDialog,
                              icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
                              label: const Text('⚡ Batch Matrix (M01-08)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Edit - ONLY displayed when exactly 1 record is selected
                            if (canEdit) ...[
                              OutlinedButton.icon(
                                onPressed: _openEditDialog,
                                icon: AppSvgIcon.edit(size: 16, color: accent),
                                label: Text('Edit', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  side: BorderSide(color: accent.withValues(alpha: 0.6)),
                                  backgroundColor: accent.withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Delete
                            if (hasSelection) ...[
                              OutlinedButton.icon(
                                onPressed: _confirmDelete,
                                icon: AppSvgIcon.delete(size: 16, color: AppTheme.dangerRed),
                                label: Text(
                                  provider.selectedIds.length > 1
                                      ? 'Delete (${provider.selectedIds.length})'
                                      : 'Delete',
                                  style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],


                            // Category / Khata Filter Dropdown
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                border: Border.all(color: AppTheme.border(context)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: provider.selectedAccountFilter,
                                  isDense: true,
                                  icon: Icon(Icons.arrow_drop_down, color: AppTheme.textMuted(context), size: 18),
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                                  dropdownColor: AppTheme.cardBg(context),
                                  items: [
                                    const DropdownMenuItem(
                                      value: 'All Accounts',
                                      child: Row(
                                        children: [
                                          Icon(Icons.folder_open_rounded, size: 15, color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text('All Khatas / Categories'),
                                        ],
                                      ),
                                    ),
                                    ...provider.accounts.map((acc) {
                                      final c = AppTheme.parseColor(acc.colorHex);
                                      return DropdownMenuItem(
                                        value: acc.name,
                                        child: Row(
                                          children: [
                                            Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                                            const SizedBox(width: 8),
                                            Text(acc.name),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      provider.setSelectedAccountFilter(val);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Search input
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: _searchCtrl,
                                  style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 13),
                                  onChanged: provider.setSearchQuery,
                                  decoration: InputDecoration(
                                    hintText: 'Search by Design No, Machine No...',
                                    hintStyle: TextStyle(color: AppTheme.textMuted(context), fontSize: 13),
                                    prefixIcon: Icon(Icons.search, size: 16, color: AppTheme.textMuted(context)),
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.border(context))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.border(context))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accent, width: 2)),
                                    suffixIcon: _searchCtrl.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.clear, size: 14, color: AppTheme.textMuted(context)),
                                            onPressed: () {
                                              _searchCtrl.clear();
                                              provider.setSearchQuery('');
                                            },
                                          )
                                        : null,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Date Filter with Clear capability
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                border: Border.all(color: AppTheme.border(context)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: _pickDate,
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 14, color: accent),
                                        const SizedBox(width: 8),
                                        Text(
                                          _filterDate != null
                                              ? DateFormat('dd-MM-yyyy').format(_filterDate!)
                                              : 'All Dates',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: _filterDate != null ? AppTheme.textPrimary(context) : AppTheme.textMuted(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_filterDate != null) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () {
                                        setState(() => _filterDate = null);
                                        context.read<ProductionProvider>().setDateRange(null, null);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: Icon(Icons.close, size: 14, color: AppTheme.textMuted(context)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Production Grid Table
                        Expanded(
                          child: records.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF1F5F9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.table_rows_rounded, size: 40, color: AppTheme.slateMedium),
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        'No Production Records Found',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkNavy),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'No entries match the current search or date filters.',
                                        style: TextStyle(fontSize: 13, color: AppTheme.slateLight),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              _searchCtrl.clear();
                                              setState(() => _filterDate = null);
                                              provider.clearFilters();
                                            },
                                            icon: const Icon(Icons.refresh_rounded, size: 16),
                                            label: const Text('Clear Filters'),
                                          ),
                                          const SizedBox(width: 10),
                                          ElevatedButton.icon(
                                            onPressed: _openAddDialog,
                                            icon: const Icon(Icons.add, size: 16),
                                            label: const Text('Add Record'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double cardWidth = constraints.maxWidth;
                                    final double dynamicSpacing = ((cardWidth - 720) / 11).clamp(12.0, 48.0);

                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SingleChildScrollView(
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(minWidth: cardWidth),
                                          child: DataTable(
                                            showCheckboxColumn: false,
                                            headingRowHeight: 46,
                                            dataRowMinHeight: 44,
                                            dataRowMaxHeight: 44,
                                            horizontalMargin: 16,
                                            columnSpacing: dynamicSpacing,
                                            headingRowColor: WidgetStateProperty.all(AppTheme.tableHeaderBg(context)),
                                            columns: [
                                              DataColumn(
                                                label: Checkbox(
                                                  value: allSelected,
                                                  activeColor: accent,
                                                  onChanged: (val) => provider.toggleSelectAll(val ?? false),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                ),
                                              ),
                                              DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                              DataColumn(label: Text('Khata / Category', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                              DataColumn(label: Text('Design No.', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                              DataColumn(label: Text('Machine No.', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                              DataColumn(label: Text('Total Stitch', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                              DataColumn(label: Text('Final Stitch', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                              DataColumn(label: Text('Rate ($currency)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                              DataColumn(label: Text('Amount ($currency)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                              DataColumn(label: Text('Heads', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                              DataColumn(label: Text('Final Amount ($currency)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                              DataColumn(label: Text('Math', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                            ],
                                            rows: List.generate(records.length, (idx) {
                                              final r = records[idx];
                                              final isCurrent = provider.entrySelectedRecord?.id == r.id;
                                              final isChecked = r.id != null && provider.selectedIds.contains(r.id!);

                                              return DataRow(
                                                selected: isCurrent,
                                                onSelectChanged: (_) {
                                                  provider.selectEntryRecord(r);
                                                },
                                                color: WidgetStateProperty.resolveWith<Color?>((states) {
                                                  if (isCurrent) return AppTheme.tableRowSelected(context);
                                                  if (isChecked) return AppTheme.tableRowHover(context);
                                                  return null;
                                                }),
                                                cells: [
                                                  DataCell(
                                                    Checkbox(
                                                      value: isChecked,
                                                      activeColor: accent,
                                                      onChanged: (_) {
                                                        if (r.id != null) provider.toggleSelectId(r.id!);
                                                      },
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                    ),
                                                  ),
                                                  DataCell(Text('${(provider.currentPage - 1) * provider.rowsPerPage + idx + 1}', style: TextStyle(color: AppTheme.textSecondary(context)))),
                                                  DataCell(Text(r.formattedDate, style: TextStyle(color: AppTheme.textSecondary(context)))),
                                                  DataCell(
                                                    Builder(
                                                      builder: (context) {
                                                        final acc = provider.accounts.cast<AccountModel?>().firstWhere(
                                                          (a) => a?.name.toLowerCase() == r.accountName.toLowerCase(),
                                                          orElse: () => null,
                                                        );
                                                        final accColor = acc != null ? AppTheme.parseColor(acc.colorHex) : accent;
                                                        return Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                          decoration: BoxDecoration(
                                                            color: accColor.withValues(alpha: 0.12),
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(color: accColor.withValues(alpha: 0.3)),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Container(
                                                                width: 7,
                                                                height: 7,
                                                                decoration: BoxDecoration(
                                                                  color: accColor,
                                                                  shape: BoxShape.circle,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 5),
                                                              Text(
                                                                r.accountName,
                                                                style: TextStyle(
                                                                  color: accColor,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 11.5,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(r.designNo, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                                                  ),
                                                  DataCell(
                                                    Text(r.machineNo, style: TextStyle(fontWeight: FontWeight.w600, color: accent)),
                                                  ),
                                                  DataCell(Text(NumberFormat('#,##,###').format(r.totalStitch), style: TextStyle(color: AppTheme.textSecondary(context)))),
                                                  DataCell(Text(NumberFormat('#,##,###').format(r.finalStitch.toInt()), style: TextStyle(color: AppTheme.textSecondary(context)))),
                                                  DataCell(Text(r.rate.toStringAsFixed(2), style: TextStyle(color: AppTheme.textSecondary(context)))),
                                                  DataCell(Text(NumberFormat('#,##,###.00').format(r.amount), style: TextStyle(color: AppTheme.textSecondary(context)))),
                                                  DataCell(Text('${r.heads}', style: TextStyle(color: AppTheme.textSecondary(context)))),
                                                  DataCell(
                                                    Text(
                                                      NumberFormat('#,##,###.00').format(r.finalAmount),
                                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    IconButton(
                                                      icon: Icon(Icons.calculate_outlined, size: 18, color: accent),
                                                      tooltip: 'View Step-by-Step Math',
                                                      onPressed: () {
                                                        provider.selectEntryRecord(r);
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        Divider(height: 1, color: AppTheme.border(context)),

                        // Footer with Strict Range-Safe Pagination
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                totalFiltered == 0
                                    ? 'Showing 0 to 0 of 0 records'
                                    : 'Showing ${(provider.currentPage - 1) * provider.rowsPerPage + 1} to ${((provider.currentPage - 1) * provider.rowsPerPage + records.length).clamp(1, totalFiltered)} of $totalFiltered records',
                                style: const TextStyle(fontSize: 12, color: AppTheme.slateMedium),
                              ),
                              Row(
                                children: [
                                  const Text('Rows per page:', style: TextStyle(fontSize: 12, color: AppTheme.slateMedium)),
                                  const SizedBox(width: 8),
                                  DropdownButton<int>(
                                    value: provider.rowsPerPage,
                                    isDense: true,
                                    underline: const SizedBox(),
                                    items: [10, 20, 50].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                                    onChanged: (val) {
                                      if (val != null) provider.setRowsPerPage(val);
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  // Prev
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                                    onPressed: provider.currentPage > 1
                                        ? () => provider.setPage(provider.currentPage - 1)
                                        : null,
                                  ),
                                  // Page numbers
                                  ...List.generate(provider.totalPages, (i) {
                                    final p = i + 1;
                                    final isCur = p == provider.currentPage;
                                    return InkWell(
                                      onTap: () => provider.setPage(p),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 3),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCur ? AppTheme.primaryBlue : Colors.transparent,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$p',
                                          style: TextStyle(
                                            color: isCur ? Colors.white : AppTheme.slateDark,
                                            fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  // Next
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                                    onPressed: provider.currentPage < provider.totalPages
                                        ? () => provider.setPage(provider.currentPage + 1)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Side Calculation Details Inspector Panel (Visible when record selected)
                if (provider.entrySelectedRecord != null)
                  _buildCalculationInspectorSidePanel(
                    provider.entrySelectedRecord!,
                    provider,
                    accent,
                    isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Top Category Overview Cards
  Widget _buildCategoryOverviewCards(BuildContext context, ProductionProvider provider, Color accent, bool isDark) {
    final accounts = provider.accounts;
    final currency = provider.settings.currencySymbol;

    final totalFactoryStitches = provider.allRecords.fold<int>(0, (s, r) => s + r.totalStitch);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          // All Categories Summary Card
            AccountProgressCard(
              width: 220,
              accountName: 'All Categories',
              area: 'Factory',
              color: accent,
              totalRevenue: provider.allRecords.fold<double>(0.0, (s, r) => s + r.finalAmount),
              totalStitches: totalFactoryStitches,
              batchesCount: provider.allRecords.length,
              currency: currency,
              progressPercent: 100.0,
              isDark: isDark,
              isSelected: provider.selectedAccountFilter == 'All Accounts',
              onTap: () => provider.setSelectedAccountFilter('All Accounts'),
            ),
            const SizedBox(width: 12),

            // Dynamic User Configured Accounts (Beads, 250 Area, 400 Area, etc.)
            ...accounts.map((acc) {
              final summary = provider.getAccountSummary(acc.name);
              final accColor = AppTheme.parseColor(acc.colorHex);
              final isSelected = provider.selectedAccountFilter == acc.name;
              final progressPercent = totalFactoryStitches > 0
                  ? ((summary.totalStitch / totalFactoryStitches) * 100).clamp(0.0, 100.0)
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: AccountProgressCard(
                  width: 220,
                  accountName: acc.name,
                  area: acc.area.isNotEmpty ? acc.area : 'Category',
                  color: accColor,
                  totalRevenue: summary.finalAmount,
                  totalStitches: summary.totalStitch,
                  batchesCount: summary.totalEntries,
                  currency: currency,
                  progressPercent: progressPercent,
                  isDark: isDark,
                  isSelected: isSelected,
                  onTap: () {
                    if (isSelected) {
                      provider.setSelectedAccountFilter('All Accounts');
                    } else {
                      provider.setSelectedAccountFilter(acc.name);
                    }
                  },
                ),
              );
            }),
          ],
        ),
    );
  }

  // Right-Side Calculation Details Inspector Panel
  Widget _buildCalculationInspectorSidePanel(
    ProductionRecord r,
    ProductionProvider provider,
    Color accent,
    bool isDark,
  ) {
    final currency = provider.settings.currencySymbol;
    final acc = provider.accounts.cast<AccountModel?>().firstWhere(
      (a) => a?.name.toLowerCase() == r.accountName.toLowerCase(),
      orElse: () => null,
    );
    final accColor = acc != null ? AppTheme.parseColor(acc.colorHex) : accent;

    return Container(
      width: 330,
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Inspector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardBg(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: AppTheme.border(context))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.calculate_rounded, color: accent, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculation Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      Text(
                        'Step-by-Step Breakdown',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Close Details Panel',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => provider.clearEntrySelection(),
                ),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // Top Tags Row
                Row(
                  children: [
                    AccountBadge(
                      accountName: r.accountName,
                      color: accColor,
                      isDark: isDark,
                    ),
                    const Spacer(),
                    ShiftBadge(
                      shift: r.shift,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Record Summary Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Column(
                    children: [
                      _inspectorRow(context, 'Design No', r.designNo, isBold: true),
                      const SizedBox(height: 6),
                      _inspectorRow(context, 'Machine No', r.machineNo, valueColor: accent),
                      const SizedBox(height: 6),
                      _inspectorRow(context, 'Date', r.formattedDate),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Step-by-Step Mathematical Math
                Text(
                  'STEP-BY-STEP CALCULATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const SizedBox(height: 8),

                // Step 1: Base Stitch
                _stepCard(
                  stepNum: '1',
                  stepTitle: 'Base Stitch Conversion',
                  formula: 'Total Stitch ÷ 1,000 = Final Stitch',
                  detail: '${NumberFormat('#,##,###').format(r.totalStitch)} ÷ 1,000',
                  result: '${NumberFormat('#,##,###').format(r.finalStitch.toInt())} st',
                  accentColor: AppTheme.primaryBlue,
                  context: context,
                ),
                const SizedBox(height: 8),

                // Step 2: Amount Calculation
                _stepCard(
                  stepNum: '2',
                  stepTitle: 'Stitch Rate Calculation',
                  formula: 'Final Stitch × Rate ($currency) = Base Amount',
                  detail: '${NumberFormat('#,##,###').format(r.finalStitch.toInt())} × $currency${r.rate.toStringAsFixed(2)}',
                  result: '$currency${NumberFormat('#,##,###.00').format(r.amount)}',
                  accentColor: AppTheme.purpleAccent,
                  context: context,
                ),
                const SizedBox(height: 8),

                // Step 3: Head Multiplier
                _stepCard(
                  stepNum: '3',
                  stepTitle: 'Machine Heads Multiplier',
                  formula: 'Base Amount × Machine Heads = Final Amount',
                  detail: '$currency${NumberFormat('#,##,###.00').format(r.amount)} × ${r.heads} Heads',
                  result: '$currency${NumberFormat('#,##,###.00').format(r.finalAmount)}',
                  accentColor: AppTheme.successGreenDark,
                  context: context,
                ),
                const SizedBox(height: 14),

                // Grand Final Result Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.successGreenDark.withValues(alpha: 0.15),
                        accent.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.successGreenDark.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL PAYABLE AMOUNT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currency${NumberFormat('#,##,###.00').format(r.finalAmount)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.successGreenDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AddEditRecordDialog(existingRecord: r),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text('Edit Entry', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          provider.selectRecord(r);
                          provider.setActiveNavIndex(9); // Full calculation view
                        },
                        icon: const Icon(Icons.fullscreen, size: 14),
                        label: const Text('Full View', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inspectorRow(BuildContext context, String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.slateMedium)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary(context),
          ),
        ),
      ],
    );
  }

  Widget _stepCard({
    required String stepNum,
    required String stepTitle,
    required String formula,
    required String detail,
    required String result,
    required Color accentColor,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  stepNum,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  stepTitle,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(formula, style: TextStyle(fontSize: 10, color: AppTheme.textMuted(context))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(detail, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))),
              Text(
                result,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
