import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/calculation_engine.dart';
import '../core/localization/app_strings.dart';
import '../models/account_model.dart';
import '../models/production_record.dart';
import '../providers/production_provider.dart';
import '../screens/production/add_edit_record_dialog.dart';
import '../core/widgets/app_empty_state.dart';
import 'shift_badge.dart';
import 'table_pagination_bar.dart';

class AccountProductionTable extends StatefulWidget {
  final AccountModel account;
  final int position;
  final int totalAccounts;
  final bool isTopProducer;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onRecordChanged;

  const AccountProductionTable({
    super.key,
    required this.account,
    required this.position,
    required this.totalAccounts,
    this.isTopProducer = false,
    this.onMoveUp,
    this.onMoveDown,
    this.onRecordChanged,
  });

  @override
  State<AccountProductionTable> createState() => _AccountProductionTableState();
}

class _AccountProductionTableState extends State<AccountProductionTable> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _shiftFilter = 'All'; // 'All', 'Day', 'Night'
  int _currentPage = 1;
  final int _rowsPerPage = 8;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddRecord() {
    showDialog(
      context: context,
      builder: (_) => AddEditRecordDialog(initialAccountName: widget.account.name),
    ).then((_) => widget.onRecordChanged?.call());
  }

  void _openEditRecord(ProductionRecord record) {
    showDialog(
      context: context,
      builder: (_) => AddEditRecordDialog(existingRecord: record),
    ).then((_) => widget.onRecordChanged?.call());
  }

  Future<void> _confirmDelete(List<ProductionRecord> recordsToDelete) async {
    if (recordsToDelete.isEmpty) return;

    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final binName = AppStrings.get('recycleBin', lang);
    final count = recordsToDelete.length;

    String message;
    if (lang == 'gu') {
      message = count == 1
          ? 'શું તમે ખરેખર ${widget.account.name} માંથી ${recordsToDelete.first.designNo} (${recordsToDelete.first.machineNo}) નો રેકોર્ડ ડિલીટ કરવા માંગો છો?\n\nતે સુરક્ષિત રીતે $binName માં જશે અને ગમે ત્યારે પાછા લાવી શકાય છે.'
          : 'શું તમે ખરેખર ${widget.account.name} માંથી પસંદ કરેલા $count રેકોર્ડ્સ ડિલીટ કરવા માંગો છો?\n\nતે સુરક્ષિત રીતે $binName માં જશે અને ગમે ત્યારે પાછા લાવી શકાય છે.';
    } else if (lang == 'hi') {
      message = count == 1
          ? 'क्या आप वास्तव में ${widget.account.name} से ${recordsToDelete.first.designNo} (${recordsToDelete.first.machineNo}) का रिकॉर्ड हटाना चाहते हैं?\n\nयह सुरक्षित रूप से $binName में जाएगा और कभी भी वापस लाया जा सकता है।'
          : 'क्या आप वास्तव में ${widget.account.name} से चयनित $count रिकॉर्ड्स हटाना चाहते हैं?\n\nये सुरक्षित रूप से $binName में जाएँगे और कभी भी वापस लाए जा सकते हैं।';
    } else {
      message = count == 1
          ? 'Are you sure you want to delete record ${recordsToDelete.first.designNo} (${recordsToDelete.first.machineNo}) from ${widget.account.name}?\n\nIt will be moved to $binName and can be restored anytime.'
          : 'Are you sure you want to delete $count selected records from ${widget.account.name}?\n\nThey will be moved to $binName and can be restored anytime.';
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_delete_rounded, color: AppTheme.dangerRed, size: 22),
            const SizedBox(width: 8),
            Text(
              lang == 'gu' ? '$binName માં મોકલો' : (lang == 'hi' ? '$binName में भेजें' : 'Move to $binName'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete & Move to Bin'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (count == 1) {
        await provider.deleteRecord(recordsToDelete.first.id!);
      } else {
        for (final r in recordsToDelete) {
          if (r.id != null) await provider.deleteRecord(r.id!);
        }
      }
      widget.onRecordChanged?.call();

      if (mounted) {
        final snackMsg = lang == 'gu'
            ? '$count રેકોર્ડ્સ $binName માં ગયા. તમે ગમે ત્યારે પાછા લાવી શકો છો.'
            : (lang == 'hi'
                ? '$count रिकॉर्ड्स $binName में चले गए। आप कभी भी वापस ला सकते हैं।'
                : '$count record(s) moved to $binName. You can restore anytime.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackMsg),
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

  void _showRateDropdown(BuildContext context, ProductionRecord record, ProductionProvider provider) {
    final availableRates = provider.settings.availableRates;
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (button == null || overlay == null) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<double>(
      context: context,
      position: position,
      items: availableRates.map((rate) {
        final isSelected = (rate - record.rate).abs() < 0.001;
        return PopupMenuItem<double>(
          value: rate,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.settings.currencySymbol}${CalculationEngine.formatRate(rate)}',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary(context),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_rounded, size: 16, color: AppTheme.primaryBlue),
            ],
          ),
        );
      }).toList(),
    ).then((newRate) {
      if (newRate != null && (newRate - record.rate).abs() > 0.001) {
        final calc = CalculationEngine.calculate(
          totalStitch: record.totalStitch,
          rate: newRate,
          heads: record.heads,
          stitchDivider: provider.settings.stitchDivider,
        );
        provider.updateRecordDirect(
          record.copyWith(
            rate: newRate,
            amount: calc.amount,
            finalAmount: calc.finalAmount,
          ),
        );
        widget.onRecordChanged?.call();
      }
    });
  }

  void _showHeadsDropdown(BuildContext context, ProductionRecord record, ProductionProvider provider) {
    final availableHeads = provider.settings.availableHeads;
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (button == null || overlay == null) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<int>(
      context: context,
      position: position,
      items: availableHeads.map((heads) {
        final isSelected = heads == record.heads;
        return PopupMenuItem<int>(
          value: heads,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$heads Heads',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary(context),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_rounded, size: 16, color: AppTheme.primaryBlue),
            ],
          ),
        );
      }).toList(),
    ).then((newHeads) {
      if (newHeads != null && newHeads != record.heads) {
        final calc = CalculationEngine.calculate(
          totalStitch: record.totalStitch,
          rate: record.rate,
          heads: newHeads,
          stitchDivider: provider.settings.stitchDivider,
        );
        provider.updateRecordDirect(
          record.copyWith(
            heads: newHeads,
            amount: calc.amount,
            finalAmount: calc.finalAmount,
          ),
        );
        widget.onRecordChanged?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final isDark = provider.settings.isDarkMode;
    final currency = provider.settings.currencySymbol;
    final lang = provider.settings.appLanguage;
    final accountColor = AppTheme.parseColor(widget.account.colorHex);

    // Filter records for this account
    final allAccountRecords = provider.allRecords.where((r) => r.accountName == widget.account.name).toList();
    final summary = provider.getAccountSummary(widget.account.name);

    // Apply local search and shift filter
    var filtered = allAccountRecords;
    if (_shiftFilter != 'All') {
      filtered = filtered.where((r) => r.shift.toLowerCase() == _shiftFilter.toLowerCase()).toList();
    }
    if (_searchCtrl.text.trim().isNotEmpty) {
      final q = _searchCtrl.text.trim().toLowerCase();
      filtered = filtered.where((r) =>
        r.designNo.toLowerCase().contains(q) ||
        r.machineNo.toLowerCase().contains(q) ||
        r.notes.toLowerCase().contains(q),
      ).toList();
    }

    final totalFiltered = filtered.length;
    final totalPages = max(1, (totalFiltered / _rowsPerPage).ceil());
    final validPage = _currentPage.clamp(1, totalPages);
    final startIndex = (validPage - 1) * _rowsPerPage;
    final pagedRecords = filtered.skip(startIndex).take(_rowsPerPage).toList();

    // Track selections for this account's records
    final selectedInAccount = pagedRecords.where((r) => r.id != null && provider.selectedIds.contains(r.id!)).toList();
    final allPagedSelected = pagedRecords.isNotEmpty && pagedRecords.every((r) => r.id != null && provider.selectedIds.contains(r.id!));
    final singleSelectedRecord = selectedInAccount.length == 1 ? selectedInAccount.first : null;

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : AppTheme.darkNavy;
    final textMuted = isDark ? const Color(0xFF94A3B8) : AppTheme.slateMedium;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ACCOUNT CARD HEADER (Title, Color Badge, Reorder Controls, Quick Stats)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                // Position Badge & Reorder controls
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accountColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accountColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${widget.position}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accountColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: widget.position > 1 ? widget.onMoveUp : null,
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 15,
                          color: widget.position > 1 ? accountColor : textMuted.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 2),
                      InkWell(
                        onTap: widget.position < widget.totalAccounts ? widget.onMoveDown : null,
                        child: Icon(
                          Icons.arrow_downward_rounded,
                          size: 15,
                          color: widget.position < widget.totalAccounts ? accountColor : textMuted.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Account Name with color circle
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: accountColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(
                        widget.account.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accountColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.account.area.isNotEmpty ? 'Area: ${widget.account.area}' : 'Category',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accountColor),
                        ),
                      ),
                      if (widget.isTopProducer)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.get('topProduction', lang),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Quick Header Summary Chips
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildStatChip(
                      icon: Icons.layers_outlined,
                      label: '${summary.totalEntries} Batches',
                      color: accountColor,
                      isDark: isDark,
                    ),
                    _buildStatChip(
                      icon: Icons.numbers_rounded,
                      label: '${NumberFormat('#,##,###').format(summary.totalStitch)} Stitches',
                      color: Colors.amber.shade700,
                      isDark: isDark,
                    ),
                    _buildStatChip(
                      icon: Icons.currency_rupee_rounded,
                      label: '$currency${NumberFormat('#,##,###.00').format(summary.finalAmount)}',
                      color: AppTheme.successGreenDark,
                      isDark: isDark,
                      isBold: true,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. SUB-TOOLBAR (Search, Shift Filter, Add Record, Edit, Delete)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Left: Shift Filter & Search
                Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Shift Pills (All, Day, Night)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildShiftPill('All', 'All Shifts', Icons.apps_rounded, isDark, accountColor),
                          _buildShiftPill('Day', 'Day', Icons.wb_sunny_rounded, isDark, accountColor),
                          _buildShiftPill('Night', 'Night', Icons.nightlight_round, isDark, accountColor),
                        ],
                      ),
                    ),

                    // Search box
                    SizedBox(
                      width: 220,
                      height: 36,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() => _currentPage = 1),
                        style: TextStyle(fontSize: 12.5, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search design, machine...',
                          hintStyle: TextStyle(fontSize: 12, color: textMuted),
                          prefixIcon: Icon(Icons.search_rounded, size: 16, color: textMuted),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 14),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _currentPage = 1);
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        ),
                      ),
                    ),
                  ],
                ),

                // Right: Action Buttons (Add, Conditional Edit, Delete)
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Conditional Single Edit Button
                    if (singleSelectedRecord != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accountColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () => _openEditRecord(singleSelectedRecord),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),

                    // Delete Button
                    if (selectedInAccount.isNotEmpty)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.dangerRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () => _confirmDelete(selectedInAccount),
                        icon: const Icon(Icons.delete_outline_rounded, size: 15),
                        label: Text('Delete (${selectedInAccount.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),

                    // + Add Record Button for this account
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accountColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: _openAddRecord,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text('Add to ${widget.account.area.isNotEmpty ? widget.account.area : 'Account'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. TABLE BODY (100% Auto-fit Horizontal Width)
          LayoutBuilder(
            builder: (context, constraints) {
              if (pagedRecords.isEmpty) {
                return AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: _searchCtrl.text.isNotEmpty
                      ? 'No matching records in ${widget.account.name}'
                      : 'No production batches in ${widget.account.name}',
                  message: _searchCtrl.text.isNotEmpty
                      ? 'No batches match "${_searchCtrl.text}". Try a different design number or clear search.'
                      : 'No production batches recorded in ${widget.account.name} yet.',
                  isDark: isDark,
                  accentColor: accountColor,
                  actionLabel: _searchCtrl.text.isNotEmpty ? 'Clear Search' : 'Add Entry',
                  onAction: _searchCtrl.text.isNotEmpty
                      ? () => setState(() => _searchCtrl.clear())
                      : _openAddRecord,
                );
              }

              const minTableWidth = 820.0;
              final effectiveWidth = max(constraints.maxWidth, minTableWidth);
              final dynamicSpacing = ((effectiveWidth - 680) / 10).clamp(8.0, 22.0);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: effectiveWidth),
                  child: DataTable(
                    showCheckboxColumn: false,
                    horizontalMargin: 12,
                    columnSpacing: dynamicSpacing,
                    headingRowHeight: 40,
                    dataRowMinHeight: 42,
                    dataRowMaxHeight: 48,
                    headingRowColor: WidgetStateProperty.all(
                      isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    ),
                    columns: [
                      // Select All Checkbox + Date
                      DataColumn(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: allPagedSelected,
                              activeColor: accountColor,
                              onChanged: (val) {
                                for (final r in pagedRecords) {
                                  if (r.id == null) continue;
                                  if (val == true) {
                                    provider.selectedIds.add(r.id!);
                                  } else {
                                    provider.selectedIds.remove(r.id!);
                                  }
                                }
                                setState(() {});
                              },
                            ),
                            const SizedBox(width: 4),
                            Text('Date', style: _headerStyle(isDark)),
                          ],
                        ),
                      ),
                      DataColumn(label: Text('Shift', style: _headerStyle(isDark))),
                      DataColumn(label: Text('Design No', style: _headerStyle(isDark))),
                      DataColumn(label: Text('Machine', style: _headerStyle(isDark))),
                      DataColumn(label: Text('Total Stitch', style: _headerStyle(isDark)), numeric: true),
                      DataColumn(label: Text('Final Stitch', style: _headerStyle(isDark)), numeric: true),
                      DataColumn(label: Text('Rate ($currency)', style: _headerStyle(isDark)), numeric: true),
                      DataColumn(label: Text('Amount ($currency)', style: _headerStyle(isDark)), numeric: true),
                      DataColumn(label: Text('Heads', style: _headerStyle(isDark)), numeric: true),
                      DataColumn(label: Text('Final Amount ($currency)', style: _headerStyle(isDark)), numeric: true),
                      DataColumn(label: Text('Action', style: _headerStyle(isDark))),
                    ],
                    rows: pagedRecords.map((r) {
                            final isRowSelected = r.id != null && provider.selectedIds.contains(r.id!);

                            return DataRow(
                              selected: isRowSelected,
                              onSelectChanged: (val) {
                                if (r.id != null) {
                                  provider.toggleSelectId(r.id!);
                                  provider.selectDashboardRecord(r);
                                  setState(() {});
                                }
                              },
                              cells: [
                                // Date + Checkbox
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: isRowSelected,
                                        activeColor: accountColor,
                                        onChanged: (val) {
                                          if (r.id != null) {
                                            provider.toggleSelectId(r.id!);
                                            provider.selectDashboardRecord(r);
                                            setState(() {});
                                          }
                                        },
                                      ),
                                      Text(
                                        r.formattedDate,
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
                                      ),
                                    ],
                                  ),
                                ),

                                // Shift Badge (Day / Night)
                                DataCell(
                                  ShiftBadge(
                                    shift: r.shift,
                                    isDark: isDark,
                                  ),
                                ),

                                // Design No
                                DataCell(
                                  Text(
                                    r.designNo,
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                ),

                                // Machine No
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      r.machineNo,
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textPrimary),
                                    ),
                                  ),
                                ),

                                // Total Stitch
                                DataCell(
                                  Text(
                                    NumberFormat('#,##,###').format(r.totalStitch),
                                    style: TextStyle(fontSize: 12.5, color: textPrimary),
                                  ),
                                ),

                                // Final Stitch
                                DataCell(
                                  Text(
                                    NumberFormat('#,##,###').format(r.finalStitch.toInt()),
                                    style: TextStyle(fontSize: 12.5, color: textMuted),
                                  ),
                                ),

                                // Rate (Clickable Dropdown Pill)
                                DataCell(
                                  Builder(
                                    builder: (btnCtx) => InkWell(
                                      onTap: () => _showRateDropdown(btnCtx, r, provider),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: accountColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: accountColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '$currency${CalculationEngine.formatRate(r.rate)}',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accountColor),
                                            ),
                                            const SizedBox(width: 3),
                                            Icon(Icons.arrow_drop_down, size: 14, color: accountColor),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Base Amount
                                DataCell(
                                  Text(
                                    '$currency${NumberFormat('#,##,###.00').format(r.amount)}',
                                    style: TextStyle(fontSize: 12.5, color: textPrimary),
                                  ),
                                ),

                                // Heads (Clickable Dropdown Pill)
                                DataCell(
                                  Builder(
                                    builder: (btnCtx) => InkWell(
                                      onTap: () => _showHeadsDropdown(btnCtx, r, provider),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${r.heads}',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                                            ),
                                            const SizedBox(width: 3),
                                            Icon(Icons.arrow_drop_down, size: 14, color: textMuted),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Final Amount (Bold Green)
                                DataCell(
                                  Text(
                                    '$currency${NumberFormat('#,##,###.00').format(r.finalAmount)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF4ADE80) : AppTheme.successGreenDark,
                                    ),
                                  ),
                                ),

                                // Quick Edit Action
                                DataCell(
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, size: 16, color: accountColor),
                                    tooltip: 'Edit Record',
                                    onPressed: () => _openEditRecord(r),
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

          // 4. PAGINATION FOOTER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: TablePaginationBar(
              currentPage: validPage,
              totalPages: totalPages,
              totalItems: totalFiltered,
              rowsPerPage: _rowsPerPage,
              isDark: isDark,
              accentColor: accountColor,
              onPageChanged: (newPage) => setState(() => _currentPage = newPage),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftPill(String value, String label, IconData icon, bool isDark, Color accent) {
    final isSelected = _shiftFilter == value;
    return InkWell(
      onTap: () => setState(() {
        _shiftFilter = value;
        _currentPage = 1;
      }),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 3, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? accent : AppTheme.textMuted(context)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.textPrimary(context) : AppTheme.textMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle(bool isDark) {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy,
    );
  }
}
