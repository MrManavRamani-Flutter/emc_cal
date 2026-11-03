import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/production_record.dart';
import '../../providers/production_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedTab = 1; // 0: Daily, 1: Monthly, 2: Yearly, 3: Machine-wise
  String _selectedMonth = 'April 2025';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final currency = provider.settings.currencySymbol;
    final allRecords = provider.allRecords;

    // Dynamically extract available months from records
    final Set<String> availableMonthsSet = {};
    for (final r in allRecords) {
      availableMonthsSet.add(DateFormat('MMMM yyyy').format(r.date));
    }
    if (availableMonthsSet.isEmpty) {
      availableMonthsSet.add('April 2025');
    }
    final availableMonths = availableMonthsSet.toList()..sort();
    if (!availableMonths.contains(_selectedMonth)) {
      _selectedMonth = availableMonths.first;
    }

    // Filter records based on selected tab and month
    List<ProductionRecord> records;
    if (_selectedTab == 1) {
      // Monthly filter
      records = allRecords.where((r) {
        return DateFormat('MMMM yyyy').format(r.date) == _selectedMonth;
      }).toList();
    } else if (_selectedTab == 0) {
      // Daily filter (e.g. latest date or today)
      final targetDate = allRecords.isNotEmpty ? allRecords.first.date : DateTime.now();
      records = allRecords.where((r) {
        return r.date.year == targetDate.year &&
            r.date.month == targetDate.month &&
            r.date.day == targetDate.day;
      }).toList();
    } else {
      records = allRecords;
    }

    final totalStitches = records.fold(0, (s, r) => s + r.totalStitch);
    final totalAmount = records.fold(0.0, (s, r) => s + r.amount);
    final finalAmount = records.fold(0.0, (s, r) => s + r.finalAmount);

    // Grouping by machine for the summary table
    final Map<String, List<ProductionRecord>> machineGroups = {};
    for (final machine in provider.machines) {
      machineGroups[machine.machineNo] = [];
    }
    for (final r in records) {
      machineGroups.putIfAbsent(r.machineNo, () => []).add(r);
    }

    final sortedMachineKeys = machineGroups.keys.toList()..sort();

    final isDark = provider.settings.isDarkMode;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Period Tabs + Month Picker + Generate Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Row(
                  children: [
                    _tabItem('Daily', 0, accent, isDark),
                    _tabItem('Monthly', 1, accent, isDark),
                    _tabItem('Yearly', 2, accent, isDark),
                    _tabItem('Machine-wise', 3, accent, isDark),
                  ],
                ),
              ),
              const Spacer(),

              // Month Selector
              if (_selectedTab == 1) ...[
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMonth,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary(context)),
                      items: availableMonths.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m, style: TextStyle(color: AppTheme.textPrimary(context))),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMonth = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Report refreshed: ${records.length} records processed'),
                      backgroundColor: AppTheme.successGreenDark,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Generate'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            _selectedTab == 0
                ? 'Daily Report'
                : _selectedTab == 1
                    ? 'Monthly Report - $_selectedMonth'
                    : _selectedTab == 2
                        ? 'Yearly Report'
                        : 'Machine-wise Performance Report',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 14),

          // 4 Metric Cards
          Row(
            children: [
              Expanded(
                child: _reportCard(
                  label: 'Total Entries',
                  value: '${records.length}',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF2563EB),
                  bgColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _reportCard(
                  label: 'Total Stitches',
                  value: NumberFormat('#,##,###').format(totalStitches),
                  icon: Icons.grain_rounded,
                  color: const Color(0xFF16A34A),
                  bgColor: isDark ? const Color(0xFF065F46).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _reportCard(
                  label: 'Total Amount',
                  value: '$currency${NumberFormat('#,##,###.00').format(totalAmount)}',
                  icon: Icons.currency_rupee_rounded,
                  color: const Color(0xFF9333EA),
                  bgColor: isDark ? const Color(0xFF581C87).withValues(alpha: 0.3) : const Color(0xFFFAF5FF),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _reportCard(
                  label: 'Final Amount',
                  value: '$currency${NumberFormat('#,##,###.00').format(finalAmount)}',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFFD97706),
                  bgColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFFBEB),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Machine-wise Summary Table Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBg(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Machine-wise Summary',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                ),
                const SizedBox(height: 16),

                records.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No production records found for the selected reporting period.',
                            style: TextStyle(color: AppTheme.textMuted(context)),
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowHeight: 44,
                                dataRowMinHeight: 42,
                                dataRowMaxHeight: 42,
                                headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                columns: [
                                  DataColumn(label: Text('Machine No.', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy))),
                                  DataColumn(label: Text('Entries', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy))),
                                  DataColumn(label: Text('Total Stitches', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy))),
                                  DataColumn(label: Text('Amount ($currency)', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy))),
                                  DataColumn(label: Text('Final Amount ($currency)', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy))),
                                ],
                                rows: [
                                  ...sortedMachineKeys.map((mNo) {
                                    final items = machineGroups[mNo]!;
                                    final mStitch = items.fold(0, (s, r) => s + r.totalStitch);
                                    final mAmount = items.fold(0.0, (s, r) => s + r.amount);
                                    final mFinal = items.fold(0.0, (s, r) => s + r.finalAmount);

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(mNo, style: TextStyle(fontWeight: FontWeight.bold, color: accent))),
                                        DataCell(Text('${items.length}', style: TextStyle(color: AppTheme.textPrimary(context)))),
                                        DataCell(Text(NumberFormat('#,##,###').format(mStitch), style: TextStyle(color: AppTheme.textPrimary(context)))),
                                        DataCell(Text(NumberFormat('#,##,###.00').format(mAmount), style: TextStyle(color: AppTheme.textPrimary(context)))),
                                        DataCell(Text(NumberFormat('#,##,###.00').format(mFinal), style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                      ],
                                    );
                                  }),
                                  // Grand Total Row
                                  DataRow(
                                    color: WidgetStateProperty.all(isDark ? const Color(0xFF26354A) : const Color(0xFFF1F5F9)),
                                    cells: [
                                      DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.darkNavy))),
                                      DataCell(Text('${records.length}', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                      DataCell(Text(NumberFormat('#,##,###').format(totalStitches), style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                      DataCell(Text(NumberFormat('#,##,###.00').format(totalAmount), style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)))),
                                      DataCell(Text(NumberFormat('#,##,###.00').format(finalAmount), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF34D399) : AppTheme.successGreenDark))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String text, int index, Color accent, bool isDark) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFFCBD5E1) : AppTheme.slateDark),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _reportCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : AppTheme.slateLight)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
