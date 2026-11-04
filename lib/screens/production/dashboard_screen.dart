import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/calculation_engine.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/core_widgets.dart';
import '../../models/account_model.dart';
import '../../models/production_record.dart';
import '../../providers/production_provider.dart';
import 'add_edit_record_dialog.dart';
import '../../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  String _selectedTrendAccount = 'All'; // 'All' for whole factory or 'Beads', '250 Area', '400 Area'
  String _selectedDashboardSection = 'All'; // 'All' or specific account/section name
  String _activeViewMode = 'all'; // 'all', 'overview', 'tables', 'charts'
  int _searchPage = 1;
  int _searchRowsPerPage = 10;
  int _searchSortColumnIndex = 0;
  bool _searchSortAscending = false;

  TrendPeriod _selectedTrendPeriod = TrendPeriod.day;
  String _chartType = 'market'; // 'market' or 'bar'
  String _marketStyle = 'line'; // 'line' or 'candle'
  int? _hoveredMarketPointIndex;
  Timer? _refreshTimer;
  int _countdownSeconds = 10;
  int? _lastConfiguredInterval;
  late AnimationController _chartAnimCtrl;

  @override
  void initState() {
    super.initState();
    _chartAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _chartAnimCtrl.forward();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _chartAnimCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _checkAndSyncTimer(int intervalSeconds) {
    if (_lastConfiguredInterval != intervalSeconds) {
      _lastConfiguredInterval = intervalSeconds;
      _refreshTimer?.cancel();
      if (intervalSeconds > 0) {
        _countdownSeconds = intervalSeconds;
        _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          setState(() {
            _countdownSeconds--;
            if (_countdownSeconds <= 0) {
              _countdownSeconds = intervalSeconds;
              context.read<ProductionProvider>().refreshData(silent: true);
              _chartAnimCtrl.forward(from: 0.0);
            }
          });
        });
      } else {
        _countdownSeconds = 0;
      }
    }
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => const AddEditRecordDialog(),
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
    target ??= provider.dashboardSelectedRecord;

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
    final target = provider.dashboardSelectedRecord;

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

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_fromDate.isAfter(_toDate)) {
            _toDate = _fromDate;
          }
        } else {
          _toDate = picked;
          if (_toDate.isBefore(_fromDate)) {
            _fromDate = _toDate;
          }
        }
      });
      if (mounted) {
        context.read<ProductionProvider>().setDateRange(_fromDate, _toDate);
      }
    }
  }

  Widget _buildViewModeSelector(BuildContext context, ProductionProvider provider) {
    final lang = provider.settings.appLanguage;
    final isDark = provider.settings.isDarkMode;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);

    final modes = [
      {'id': 'all', 'label': AppStrings.get('all', lang), 'icon': Icons.grid_view_rounded},
      {'id': 'overview', 'label': AppStrings.get('overview', lang), 'icon': Icons.dashboard_customize_rounded},
      {'id': 'tables', 'label': AppStrings.get('recordsTable', lang), 'icon': Icons.table_chart_rounded},
      {'id': 'charts', 'label': AppStrings.get('charts', lang), 'icon': Icons.insights_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((m) {
          final isSelected = _activeViewMode == m['id'];
          return InkWell(
            onTap: () => setState(() => _activeViewMode = m['id'] as String),
            borderRadius: BorderRadius.circular(7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? (isDark ? accent : Colors.white) : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    m['icon'] as IconData,
                    size: 15,
                    color: isSelected
                        ? (isDark ? AppTheme.contrastText(accent) : accent)
                        : AppTheme.textMuted(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    m['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? AppTheme.contrastText(accent) : AppTheme.textPrimary(context))
                          : AppTheme.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    _checkAndSyncTimer(provider.settings.autoRefreshIntervalSeconds);

    final currency = provider.settings.currencySymbol;
    final isSearching = provider.searchQuery.trim().isNotEmpty || _searchCtrl.text.trim().isNotEmpty;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);
    final isDark = provider.settings.isDarkMode;

    final showOverview = _activeViewMode == 'all' || _activeViewMode == 'overview';
    final showTables = _activeViewMode == 'all' || _activeViewMode == 'tables';
    final showCharts = _activeViewMode == 'all' || _activeViewMode == 'charts';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TOP ACTION & FILTER TOOLBAR
          _buildTopToolbar(provider),
          const SizedBox(height: 14),

          // 2. VIEW MODE SELECTOR (Segmented view toggle for un-crammed, clean UI)
          if (!isSearching) ...[
            _buildViewModeSelector(context, provider),
            const SizedBox(height: 16),
          ],

          if (isSearching) ...[
            // ONLY DISPLAY SEARCH RESULTS RECORDS AND NOTHING ELSE!
            _buildSearchResultsSection(context, provider, currency, isDark, accent),
          ] else ...[
            // 3. QUICK INFO CARDS (Total Factory Summary + Account Progress Cards sorted by highest production)
            if (showOverview) ...[
              _buildDetailsCardsSection(provider, currency),
              const SizedBox(height: 20),
            ],

            // 4. PRODUCTION RECORDS TABLES (Sorted with highest-producing section in front & section filter)
            if (showTables) ...[
              _buildAccountTablesSection(provider),
              const SizedBox(height: 20),
            ],

            // 5. PERFORMANCE & FINANCIAL MARKET / TREND CHART
            if (showCharts) ...[
              _buildTrendChartCard(provider, currency),
            ],
          ],
        ],
      ),
    );
  }

  // --- DETAILS CARDS SECTION ---
  Widget _buildDetailsCardsSection(ProductionProvider provider, String currency) {
    final lang = provider.settings.appLanguage;
    final isDark = provider.settings.isDarkMode;
    final allRecords = provider.allRecords;
    final totalBatches = allRecords.length;
    final totalStitches = allRecords.fold<int>(0, (s, r) => s + r.totalStitch);
    final totalAmount = allRecords.fold<double>(0.0, (s, r) => s + r.finalAmount);

    final dayRecords = allRecords.where((r) => r.shift.toLowerCase() == 'day').toList();
    final nightRecords = allRecords.where((r) => r.shift.toLowerCase() == 'night').toList();
    final dayStitches = dayRecords.fold<int>(0, (s, r) => s + r.totalStitch);
    final nightStitches = nightRecords.fold<int>(0, (s, r) => s + r.totalStitch);
    final dayAmount = dayRecords.fold<double>(0.0, (s, r) => s + r.finalAmount);
    final nightAmount = nightRecords.fold<double>(0.0, (s, r) => s + r.finalAmount);

    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : AppTheme.darkNavy;
    final textMuted = isDark ? const Color(0xFF94A3B8) : AppTheme.slateMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A. Grand Total Factory Overview Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E3A8A).withValues(alpha: 0.5), const Color(0xFF0F172A)]
                  : [const Color(0xFFEFF6FF), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.analytics_rounded, color: AppTheme.primaryBlue, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.get('factoryOverview', lang),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Across ${provider.accounts.length} Accounts & ${provider.machines.length} Machines',
                            style: TextStyle(fontSize: 12, color: textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Shift Breakdown Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ShiftSummaryPill(
                        label: AppStrings.get('dayShift', lang),
                        batches: dayRecords.length,
                        stitches: dayStitches,
                        amount: dayAmount,
                        currency: currency,
                        color: Colors.amber.shade700,
                        isDark: isDark,
                      ),
                      ShiftSummaryPill(
                        label: AppStrings.get('nightShift', lang),
                        batches: nightRecords.length,
                        stitches: nightStitches,
                        amount: nightAmount,
                        currency: currency,
                        color: Colors.indigo.shade400,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  KpiMetricCard(
                    title: AppStrings.get('totalStitches', lang),
                    value: NumberFormat('#,##,###').format(totalStitches),
                    icon: Icons.numbers_rounded,
                    color: Colors.amber.shade700,
                    isDark: isDark,
                  ),
                  KpiMetricCard(
                    title: AppStrings.get('totalRevenue', lang),
                    value: '$currency${NumberFormat('#,##,###.00').format(totalAmount)}',
                    icon: Icons.currency_rupee_rounded,
                    color: AppTheme.successGreenDark,
                    isDark: isDark,
                  ),
                  KpiMetricCard(
                    title: AppStrings.get('totalBatches', lang),
                    value: '$totalBatches Batches',
                    icon: Icons.layers_outlined,
                    color: AppTheme.primaryBlue,
                    isDark: isDark,
                  ),
                  KpiMetricCard(
                    title: AppStrings.get('configuredAccounts', lang),
                    value: '${provider.accounts.length} Accounts',
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF7C3AED),
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // B. Separate Account View Progress Cards Grid (Sorted by highest production first)
        LayoutBuilder(
          builder: (context, constraints) {
            final accounts = List<AccountModel>.from(provider.accounts);
            if (accounts.isEmpty) return const SizedBox();

            // Sort accounts so that the section with highest production (stitches & revenue) is first (aage)
            accounts.sort((a, b) {
              final sumA = provider.getAccountSummary(a.name);
              final sumB = provider.getAccountSummary(b.name);
              final stitchComp = sumB.totalStitch.compareTo(sumA.totalStitch);
              if (stitchComp != 0) return stitchComp;
              return sumB.finalAmount.compareTo(sumA.finalAmount);
            });

            final cardWidth = constraints.maxWidth < 750
                ? constraints.maxWidth
                : constraints.maxWidth < 1200
                    ? (constraints.maxWidth - 16) / 2
                    : (constraints.maxWidth - (16 * (accounts.length - 1))) / accounts.length;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: accounts.asMap().entries.map((entry) {
                final idx = entry.key;
                final acc = entry.value;
                final summary = provider.getAccountSummary(acc.name);
                final accColor = AppTheme.parseColor(acc.colorHex);
                final progressPercent = totalStitches > 0
                    ? ((summary.totalStitch / totalStitches) * 100).clamp(0.0, 100.0)
                    : 0.0;

                return AccountProgressCard(
                  width: cardWidth,
                  accountName: acc.name,
                  area: acc.area,
                  color: accColor,
                  totalRevenue: summary.finalAmount,
                  totalStitches: summary.totalStitch,
                  batchesCount: summary.totalEntries,
                  currency: currency,
                  progressPercent: progressPercent,
                  isDark: isDark,
                  isTopProducer: idx == 0 && summary.totalStitch > 0,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // --- ALL SEPARATE ACCOUNT PRODUCTION TABLES (SORTED BY HIGHEST PRODUCTION FIRST) ---
  Widget _buildAccountTablesSection(ProductionProvider provider) {
    final accounts = provider.accounts;
    final lang = provider.settings.appLanguage;

    if (accounts.isEmpty) {
      final noAccMsg = AppStrings.t(
        lang,
        en: 'No accounts configured yet. Open Accounts to create one.',
        gu: 'હજુ સુધી કોઈ ખાતા ગોઠવેલા નથી. ખાતું બનાવવા "ખાતાઓ" વિભાગ ખોલો.',
        hi: 'अभी तक कोई खाता नहीं बना है। खाता बनाने के लिए "खाते" मॉड्यूल खोलें।',
      );
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Text(noAccMsg),
      );
    }

    // Only display accounts that have at least one production entry recorded
    var accountsWithEntries = accounts.where((account) {
      final summary = provider.getAccountSummary(account.name);
      return summary.totalEntries > 0;
    }).toList();

    if (accountsWithEntries.isEmpty) {
      final accent = AppTheme.parseColor(provider.settings.themeColorHex);
      final hasFilter = provider.selectedMachineFilter != 'All Machines' ||
          provider.fromDate != null ||
          provider.searchQuery.isNotEmpty;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.table_rows_rounded, size: 36, color: accent),
            ),
            const SizedBox(height: 14),
            Text(
              AppStrings.get('noProductionFound', lang),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? AppStrings.get('noProductionFilterHint', lang)
                  : AppStrings.get('noProductionHint', lang),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted(context)),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _openAddDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(AppStrings.get('addEntry', lang)),
                ),
                if (hasFilter) ...[
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      _searchCtrl.clear();
                      provider.clearFilters();
                      setState(() {
                        _searchPage = 1;
                        _selectedDashboardSection = 'All';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary(context),
                      side: BorderSide(color: AppTheme.border(context)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: Text(AppStrings.get('resetFilter', lang)),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    // Sort accounts so the section with highest production (stitches & revenue) comes FIRST (aage rakho)
    accountsWithEntries.sort((a, b) {
      final sumA = provider.getAccountSummary(a.name);
      final sumB = provider.getAccountSummary(b.name);
      final stitchComparison = sumB.totalStitch.compareTo(sumA.totalStitch);
      if (stitchComparison != 0) return stitchComparison;
      return sumB.finalAmount.compareTo(sumA.finalAmount);
    });

    final isDark = provider.settings.isDarkMode;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);

    // Apply section filter if user selected a specific section
    final displayedAccounts = _selectedDashboardSection == 'All'
        ? accountsWithEntries
        : accountsWithEntries.where((a) => a.name == _selectedDashboardSection).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Filter & Priority Header Bar
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.t(lang, en: 'Production Sections', gu: 'ઉત્પાદન વિભાગો', hi: 'उत्पादन अनुभाग'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.darkNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.t(lang, en: 'Highest Production First', gu: 'સૌથી વધુ ઉત્પાદન પ્રથમ', hi: 'सर्वाधिक उत्पादन पहले'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Filter switcher chips for active accounts
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildSectionFilterChip(
                    label: 'All Active Sections (${accountsWithEntries.length})',
                    isSelected: _selectedDashboardSection == 'All',
                    color: accent,
                    isDark: isDark,
                    onTap: () => setState(() => _selectedDashboardSection = 'All'),
                  ),
                  ...accountsWithEntries.map((acc) {
                    final isTop = accountsWithEntries.indexOf(acc) == 0;
                    final sum = provider.getAccountSummary(acc.name);
                    final accColor = AppTheme.parseColor(acc.colorHex);
                    return _buildSectionFilterChip(
                      label: '${acc.name} (${NumberFormat.compact().format(sum.totalStitch)} st)',
                      icon: isTop ? Icons.workspace_premium_rounded : null,
                      isSelected: _selectedDashboardSection == acc.name,
                      color: accColor,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedDashboardSection = acc.name),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        // Render each account production table
        ...displayedAccounts.asMap().entries.map((entry) {
          final idx = entry.key;
          final account = entry.value;
          final isTop = accountsWithEntries.indexOf(account) == 0;
          return AccountProductionTable(
            key: ValueKey(account.id ?? account.name),
            account: account,
            position: idx + 1,
            isTopProducer: isTop,
            totalAccounts: displayedAccounts.length,
            onMoveUp: () => provider.moveAccountOrder(account.id!, true),
            onMoveDown: () => provider.moveAccountOrder(account.id!, false),
            onRecordChanged: () => setState(() {}),
          );
        }),
      ],
    );
  }

  Widget _buildSectionFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? color : const Color(0xFFD97706)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SEARCH RESULTS ONLY SECTION (Displayed when user searches in Dashboard) ---
  Widget _buildSearchResultsSection(
    BuildContext context,
    ProductionProvider provider,
    String currency,
    bool isDark,
    Color accent,
  ) {
    final query = (provider.searchQuery.isNotEmpty ? provider.searchQuery : _searchCtrl.text).trim().toLowerCase();

    // Query across all records in the factory
    final searchResults = provider.allRecords.where((r) {
      final matchDesign = r.designNo.toLowerCase().contains(query);
      final matchMachine = r.machineNo.toLowerCase().contains(query);
      final matchAccount = r.accountName.toLowerCase().contains(query);
      final matchNotes = r.notes.toLowerCase().contains(query);
      final matchShift = r.shift.toLowerCase().contains(query);
      if (!matchDesign && !matchMachine && !matchAccount && !matchNotes && !matchShift) {
        return false;
      }
      if (provider.selectedMachineFilter != 'All Machines' && r.machineNo != provider.selectedMachineFilter) {
        return false;
      }
      if (provider.fromDate != null) {
        final start = DateTime(provider.fromDate!.year, provider.fromDate!.month, provider.fromDate!.day);
        if (r.date.isBefore(start)) return false;
      }
      if (provider.toDate != null) {
        final end = DateTime(provider.toDate!.year, provider.toDate!.month, provider.toDate!.day, 23, 59, 59);
        if (r.date.isAfter(end)) return false;
      }
      return true;
    }).toList();

    // Sort search results dynamically
    searchResults.sort((a, b) {
      int cmp = 0;
      switch (_searchSortColumnIndex) {
        case 0:
          cmp = a.date.compareTo(b.date);
          break;
        case 1:
          cmp = a.accountName.toLowerCase().compareTo(b.accountName.toLowerCase());
          break;
        case 2:
          cmp = a.shift.toLowerCase().compareTo(b.shift.toLowerCase());
          break;
        case 3:
          cmp = a.designNo.toLowerCase().compareTo(b.designNo.toLowerCase());
          break;
        case 4:
          cmp = a.machineNo.toLowerCase().compareTo(b.machineNo.toLowerCase());
          break;
        case 5:
          cmp = a.totalStitch.compareTo(b.totalStitch);
          break;
        case 6:
          cmp = a.finalStitch.compareTo(b.finalStitch);
          break;
        case 7:
          cmp = a.rate.compareTo(b.rate);
          break;
        case 8:
          cmp = a.amount.compareTo(b.amount);
          break;
        case 9:
          cmp = a.heads.compareTo(b.heads);
          break;
        case 10:
          cmp = a.finalAmount.compareTo(b.finalAmount);
          break;
        default:
          cmp = a.date.compareTo(b.date);
      }
      return _searchSortAscending ? cmp : -cmp;
    });

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : AppTheme.darkNavy;
    final textMuted = isDark ? const Color(0xFF94A3B8) : AppTheme.slateMedium;

    final totalFound = searchResults.length;
    final isShowAll = _searchRowsPerPage <= 0;
    final totalPages = isShowAll ? 1 : max(1, (totalFound / _searchRowsPerPage).ceil());
    final validPage = isShowAll ? 1 : _searchPage.clamp(1, totalPages);
    final startIndex = isShowAll ? 0 : (validPage - 1) * _searchRowsPerPage;
    final pagedResults = isShowAll ? searchResults : searchResults.skip(startIndex).take(_searchRowsPerPage).toList();

    final allPagedSelected = pagedResults.isNotEmpty &&
        pagedResults.every((r) => r.id != null && provider.selectedIds.contains(r.id!));

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
          // 1. Search Results Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.search_rounded, color: accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Search Results for ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: accent.withValues(alpha: 0.35)),
                              ),
                              child: Text(
                                '"$query"',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Showing only matching production batches across all factory accounts',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Results count badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: totalFound > 0
                            ? AppTheme.successGreenDark.withValues(alpha: 0.15)
                            : (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: totalFound > 0
                              ? AppTheme.successGreenDark.withValues(alpha: 0.4)
                              : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5)),
                        ),
                      ),
                      child: Text(
                        '$totalFound ${totalFound == 1 ? "Batch" : "Batches"} Found',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: totalFound > 0 ? AppTheme.successGreenDark : AppTheme.dangerRed,
                        ),
                      ),
                    ),
                  ],
                ),

                // Clear Search Button
                ElevatedButton.icon(
                  onPressed: () {
                    _searchCtrl.clear();
                    provider.setSearchQuery('');
                    setState(() {
                      _searchPage = 1;
                    });
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text(
                    'Clear Search (Show Dashboard)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    foregroundColor: isDark ? Colors.white : AppTheme.darkNavy,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          // 2. Body: Empty State OR Search Results Table
          if (searchResults.isEmpty)
            AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No production records found matching "$query"',
              message: 'No batches match this design code, machine number, or notes. Try searching another term or clear the search.',
              isDark: isDark,
              accentColor: accent,
              actionLabel: 'Clear Search & Return to Dashboard',
              onAction: () {
                _searchCtrl.clear();
                provider.setSearchQuery('');
                setState(() => _searchPage = 1);
              },
            )
          else ...[
            // Quick Aggregate Summary Bar for Search Results
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Wrap(
                spacing: 24,
                runSpacing: 6,
                children: [
                  _searchStatItem('Total Matches', '$totalFound batches', accent),
                  _searchStatItem('Total Stitches', NumberFormat('#,##,###').format(searchResults.fold<int>(0, (s, r) => s + r.totalStitch)), accent),
                  _searchStatItem('Total Amount', '$currency${NumberFormat('#,##,###.00').format(searchResults.fold<double>(0.0, (s, r) => s + r.finalAmount))}', AppTheme.successGreenDark),
                ],
              ),
            ),

            // DataTable for Search Results
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      showCheckboxColumn: false,
                      sortColumnIndex: _searchSortColumnIndex,
                      sortAscending: _searchSortAscending,
                      headingRowColor: WidgetStateProperty.all(
                        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      ),
                      dataRowColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return accent.withValues(alpha: 0.12);
                        }
                        return Colors.transparent;
                      }),
                      columnSpacing: 18,
                      horizontalMargin: 16,
                      columns: [
                        DataColumn(
                          onSort: (idx, asc) => setState(() {
                            _searchSortColumnIndex = idx;
                            _searchSortAscending = asc;
                          }),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: allPagedSelected,
                                  onChanged: (val) {
                                    if (val == true) {
                                      for (final r in pagedResults) {
                                        if (r.id != null) provider.selectedIds.add(r.id!);
                                      }
                                    } else {
                                      for (final r in pagedResults) {
                                        if (r.id != null) provider.selectedIds.remove(r.id!);
                                      }
                                    }
                                    setState(() {});
                                  },
                                  activeColor: accent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                        DataColumn(
                          onSort: (idx, asc) => setState(() {
                            _searchSortColumnIndex = idx;
                            _searchSortAscending = asc;
                          }),
                          label: const Text('Khata / Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        DataColumn(
                          onSort: (idx, asc) => setState(() {
                            _searchSortColumnIndex = idx;
                            _searchSortAscending = asc;
                          }),
                          label: const Text('Shift', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        DataColumn(
                          onSort: (idx, asc) => setState(() {
                            _searchSortColumnIndex = idx;
                            _searchSortAscending = asc;
                          }),
                          label: const Text('Design No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        DataColumn(
                          onSort: (idx, asc) => setState(() {
                            _searchSortColumnIndex = idx;
                            _searchSortAscending = asc;
                          }),
                          label: const Text('Machine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        DataColumn(
                          numeric: true,
                          onSort: (idx, asc) => setState(() {
                            _searchSortColumnIndex = idx;
                            _searchSortAscending = asc;
                          }),
                          label: const Text('Total Stitch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        DataColumn(
                          numeric: true,
                          onSort: (idx, asc) => setState(() {
                            _searchSortColumnIndex = idx;
                            _searchSortAscending = asc;
                          }),
                          label: const Text('Final Stitch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        DataColumn(
                          onSort: (idx, asc) => setState(() {
                            _searchSortColumnIndex = idx;
                            _searchSortAscending = asc;
                          }),
                          label: const Text('Rate (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        DataColumn(
                          numeric: true,
                          onSort: (idx, asc) => setState(() {
                            _searchSortColumnIndex = idx;
                            _searchSortAscending = asc;
                          }),
                          label: const Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        DataColumn(
                          onSort: (idx, asc) => setState(() {
                            _searchSortColumnIndex = idx;
                            _searchSortAscending = asc;
                          }),
                          label: const Text('Heads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        DataColumn(
                          numeric: true,
                          onSort: (idx, asc) => setState(() {
                            _searchSortColumnIndex = idx;
                            _searchSortAscending = asc;
                          }),
                          label: const Text('Final Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                      rows: pagedResults.map((r) {
                        final isSelected = r.id != null && provider.selectedIds.contains(r.id!);
                        final isClicked = provider.dashboardSelectedRecord?.id == r.id;
                        final acc = provider.accounts.firstWhere(
                          (a) => a.name == r.accountName,
                          orElse: () => AccountModel(name: r.accountName, colorHex: '#2563EB', area: ''),
                        );
                        final accColor = AppTheme.parseColor(acc.colorHex);

                        return DataRow(
                          selected: isSelected || isClicked,
                          onSelectChanged: (_) {
                            provider.selectDashboardRecord(r);
                            setState(() {});
                          },
                          cells: [
                            // Date with checkbox
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                        if (r.id != null) {
                                          provider.toggleSelectId(r.id!);
                                        }
                                        setState(() {});
                                      },
                                      activeColor: accent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd-MM-yyyy').format(r.date),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            // Account / Khata Badge
                            DataCell(
                              AccountBadge(
                                accountName: r.accountName,
                                color: accColor,
                                isDark: isDark,
                              ),
                            ),
                            // Shift Badge
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                            ),
                            // Machine
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  r.machineNo,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            // Total Stitch
                            DataCell(
                              Text(
                                NumberFormat('#,##,###').format(r.totalStitch),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            // Final Stitch
                            DataCell(
                              Text(
                                r.finalStitch.toStringAsFixed(r.finalStitch.truncateToDouble() == r.finalStitch ? 0 : 2),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            // Rate Dropdown Pill
                            DataCell(
                              _buildInlineDropdownPill(
                                context: context,
                                label: '₹${r.rate.toStringAsFixed(2)}',
                                color: accent,
                                onTap: () => _showInlineRateDropdown(context, r, provider),
                              ),
                            ),
                            // Base Amount
                            DataCell(
                              Text(
                                '₹${NumberFormat('#,##,###.00').format(r.amount)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            // Heads Dropdown Pill
                            DataCell(
                              _buildInlineDropdownPill(
                                context: context,
                                label: '${r.heads}',
                                color: const Color(0xFF64748B),
                                onTap: () => _showInlineHeadsDropdown(context, r, provider),
                              ),
                            ),
                            // Final Amount
                            DataCell(
                              Text(
                                '₹${NumberFormat('#,##,###.00').format(r.finalAmount)}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successGreenDark,
                                ),
                              ),
                            ),
                            // Action Buttons (Edit & Delete)
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    color: accent,
                                    splashRadius: 16,
                                    tooltip: 'Edit record',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AddEditRecordDialog(existingRecord: r),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                    color: AppTheme.dangerRed,
                                    splashRadius: 16,
                                    tooltip: 'Delete record',
                                    onPressed: () => _confirmDeleteSingle(r),
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

            // 3. Pagination Footer for Search Results
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: TablePaginationBar(
                currentPage: validPage,
                totalPages: totalPages,
                totalItems: totalFound,
                rowsPerPage: _searchRowsPerPage,
                isDark: isDark,
                accentColor: accent,
                onPageChanged: (newPage) => setState(() => _searchPage = newPage),
                onRowsPerPageChanged: (v) => setState(() {
                  _searchRowsPerPage = v;
                  _searchPage = 1;
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _searchStatItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildInlineDropdownPill({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_drop_down_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  void _showInlineRateDropdown(BuildContext context, ProductionRecord record, ProductionProvider provider) {
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
                '${provider.settings.currencySymbol}${rate.toStringAsFixed(2)}',
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
      }
    });
  }

  void _showInlineHeadsDropdown(BuildContext context, ProductionRecord record, ProductionProvider provider) {
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
      }
    });
  }

  void _confirmDeleteSingle(ProductionRecord record) async {
    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final binName = AppStrings.get('recycleBin', lang);

    String message;
    if (lang == 'gu') {
      message = 'શું તમે ખરેખર ${record.designNo} (${record.machineNo}) નો રેકોર્ડ ડિલીટ કરવા માંગો છો?\n\nતે સુરક્ષિત રીતે $binName માં જશે અને ગમે ત્યારે પાછા લાવી શકાય છે.';
    } else if (lang == 'hi') {
      message = 'क्या आप वास्तव में ${record.designNo} (${record.machineNo}) का रिकॉर्ड हटाना चाहते हैं?\n\nयह सुरक्षित रूप से $binName में जाएगा और कभी भी वापस लाया जा सकता है।';
    } else {
      message = 'Are you sure you want to delete record ${record.designNo} (${record.machineNo})?\n\nIt will be moved to $binName and can be restored anytime.';
    }

    final confirmed = await ConfirmDeleteDialog.show(
      context: context,
      title: lang == 'gu' ? '$binName માં મોકલો' : (lang == 'hi' ? '$binName में भेजें' : 'Move to $binName'),
      message: message,
      confirmLabel: AppStrings.t(lang, en: 'Move to Bin', gu: '$binName માં મોકલો', hi: '$binName में भेजें'),
    );

    if (confirmed && record.id != null) {
      if (mounted) {
        await provider.deleteRecord(record.id!);
        if (mounted) {
          final snackMsg = lang == 'gu'
              ? 'રેકોર્ડ "${record.designNo}" $binName માં ગયો.'
              : (lang == 'hi'
                  ? 'रिकॉर्ड "${record.designNo}" $binName में चला गया।'
                  : 'Record "${record.designNo}" moved to $binName.');
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
  }

  // --- 1. Top Action & Filter Toolbar ---
  Widget _buildTopToolbar(ProductionProvider provider) {
    final machineOptions = <String>[
      'All Machines',
      ...provider.machines.map((m) => m.machineNo).toSet(),
    ];
    final currentMachine = machineOptions.contains(provider.selectedMachineFilter)
        ? provider.selectedMachineFilter
        : 'All Machines';

    final hasActiveFilter = provider.selectedMachineFilter != 'All Machines' ||
        provider.searchQuery.isNotEmpty ||
        _searchCtrl.text.isNotEmpty ||
        provider.fromDate != null ||
        _selectedDashboardSection != 'All';

    final lang = provider.settings.appLanguage;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);
    final isDark = provider.settings.isDarkMode;

    // Edit option is ONLY displayed when EXACTLY ONE record is selected.
    // If 0 records or more than 1 record are selected, Edit is hidden.
    final bool canEdit = (provider.selectedIds.length == 1) ||
        (provider.selectedIds.isEmpty && provider.dashboardSelectedRecord != null);
    final bool hasSelection = provider.selectedIds.isNotEmpty || provider.dashboardSelectedRecord != null;

    final actionButtons = <Widget>[
      // + Add Record
      AppButton.primary(
        label: AppStrings.get('addNew', lang),
        icon: Icons.add,
        onPressed: _openAddDialog,
      ),
      const SizedBox(width: 8),

      // Edit - ONLY shown when exactly 1 record is selected
      if (canEdit) ...[
        AppButton.outline(
          label: AppStrings.get('edit', lang),
          icon: Icons.edit_outlined,
          onPressed: _openEditDialog,
        ),
        const SizedBox(width: 8),
      ],

      // Delete - shown when one or more records are selected
      if (hasSelection) ...[
        AppButton.danger(
          label: provider.selectedIds.length > 1
              ? '${AppStrings.get('delete', lang)} (${provider.selectedIds.length})'
              : AppStrings.get('delete', lang),
          icon: Icons.delete_outline_rounded,
          onPressed: _confirmDelete,
        ),
      ],
    ];

    final filterControls = <Widget>[
      // Search input with AppSearchField
      SizedBox(
        width: 250,
        child: AppSearchField(
          controller: _searchCtrl,
          hintText: AppStrings.get('search', lang),
          onChanged: (val) {
            provider.setSearchQuery(val);
            setState(() {
              _searchPage = 1;
            });
          },
          onClear: () {
            _searchCtrl.clear();
            provider.setSearchQuery('');
            setState(() {
              _searchPage = 1;
            });
          },
        ),
      ),
      const SizedBox(width: 10),

      // From Date Container
      InkWell(
        onTap: () => _pickDate(true),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: provider.fromDate != null
                ? (isDark ? accent.withValues(alpha: 0.22) : const Color(0xFFEFF6FF))
                : (isDark ? const Color(0xFF0F172A) : Colors.white),
            border: Border.all(color: provider.fromDate != null ? accent : AppTheme.border(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('From Date  ', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))),
              Text(
                DateFormat('dd-MM-yyyy').format(_fromDate),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary(context)),
              ),
              const SizedBox(width: 6),
              Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted(context)),
            ],
          ),
        ),
      ),
      const SizedBox(width: 10),

      // To Date Container
      InkWell(
        onTap: () => _pickDate(false),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: provider.toDate != null
                ? (isDark ? accent.withValues(alpha: 0.22) : const Color(0xFFEFF6FF))
                : (isDark ? const Color(0xFF0F172A) : Colors.white),
            border: Border.all(color: provider.toDate != null ? accent : AppTheme.border(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('To Date  ', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))),
              Text(
                DateFormat('dd-MM-yyyy').format(_toDate),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary(context)),
              ),
              const SizedBox(width: 6),
              Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted(context)),
            ],
          ),
        ),
      ),
      const SizedBox(width: 10),

      // Machines Dropdown (Explicit container with active indicator)
      Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: currentMachine != 'All Machines'
              ? (isDark ? accent.withValues(alpha: 0.22) : const Color(0xFFEFF6FF))
              : (isDark ? const Color(0xFF0F172A) : Colors.white),
          border: Border.all(color: currentMachine != 'All Machines' ? accent : AppTheme.border(context)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentMachine,
            isDense: true,
            dropdownColor: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(8),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: currentMachine != 'All Machines' ? accent : AppTheme.textPrimary(context),
            ),
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.textMuted(context)),
            items: machineOptions.map((no) {
              return DropdownMenuItem<String>(
                value: no,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (no == 'All Machines')
                      Icon(Icons.precision_manufacturing_outlined, size: 14, color: AppTheme.textMuted(context))
                    else
                      Icon(Icons.circle, size: 8, color: accent),
                    const SizedBox(width: 6),
                    Text(no, style: TextStyle(color: AppTheme.textPrimary(context))),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                provider.setMachineFilter(val);
              }
            },
          ),
        ),
      ),

      // Reset / Clear Filters Button (Visible when any filter is active)
      if (hasActiveFilter) ...[
        const SizedBox(width: 8),
        Tooltip(
          message: 'Reset All Filters',
          child: InkWell(
            onTap: () {
              _searchCtrl.clear();
              provider.clearFilters();
              setState(() {
                _searchPage = 1;
                _selectedDashboardSection = 'All';
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
                border: Border.all(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.filter_alt_off_rounded, size: 15, color: AppTheme.dangerRed),
                  SizedBox(width: 4),
                  Text('Reset', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                ],
              ),
            ),
          ),
        ),
      ],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1550) {
            // Wrap gracefully into clean responsive rows without horizontal scroll
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: actionButtons,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: filterControls,
                ),
              ],
            );
          }

          // Full single-row desktop layout on ultra-wide screens
          return Row(
            children: [
              ...actionButtons,
              const Spacer(),
              ...filterControls,
            ],
          );
        },
      ),
    );
  }



  // --- 4. Trend & Profit/Loss (+ / -) Chart Card ---
  Widget _buildTrendChartCard(ProductionProvider provider, String currency) {
    final isDark = provider.settings.isDarkMode;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);
    final summary = provider.getTrendSummary(
      _selectedTrendPeriod,
      _selectedTrendAccount == 'All' ? null : _selectedTrendAccount,
    );
    final isPos = summary.isPositive;
    final diffFormatted = NumberFormat('#,##,###.00').format(summary.diffAmount.abs());
    final currentFormatted = NumberFormat('#,##,###.00').format(summary.currentAmount);

    final double maxPt = summary.points.isNotEmpty
        ? summary.points.map((p) => p.finalAmount).reduce(max)
        : 0.0;
    final double minPt = summary.points.isNotEmpty
        ? summary.points.map((p) => p.finalAmount).reduce(min)
        : 0.0;

    final hoveredPoint = (_hoveredMarketPointIndex != null &&
            _hoveredMarketPointIndex! < summary.points.length)
        ? summary.points[_hoveredMarketPointIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title, Period Switchers, Auto-Refresh Status & Manual Refresh Button
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1420;
              final headerInfo = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPos
                          ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5))
                          : (isDark ? const Color(0xFF450A0A).withValues(alpha: 0.4) : const Color(0xFFFEF2F2)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPos
                            ? (isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0))
                            : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
                      ),
                    ),
                    child: Icon(
                      isPos ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: isPos ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _selectedTrendAccount == 'All'
                                ? 'Performance & Trend (All Factory)'
                                : '$_selectedTrendAccount Performance Trend',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPos ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isPos ? 'PLUS (+)' : 'MINUS (-)',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedTrendAccount == 'All'
                            ? 'Factory-wide Day-to-Day, Weekly, Monthly & Yearly financial trend'
                            : 'Dedicated financial trend & production graph for $_selectedTrendAccount',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
                      ),
                    ],
                  ),
                ],
              );

              final controls = Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Khata / Category Selector Pills (All Factory, Beads, 250 Area, 400 Area)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _trendAccountPill('All Factory', 'All', null, accent, isDark),
                        ...provider.accounts.map((acc) {
                          return _trendAccountPill(
                            acc.name,
                            acc.name,
                            AppTheme.parseColor(acc.colorHex),
                            accent,
                            isDark,
                          );
                        }),
                      ],
                    ),
                  ),
                  // Chart View Mode Switcher: Market Chart vs Bar Chart
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _chartModePill('Market Chart', 'market', Icons.show_chart_rounded, accent, isDark),
                        _chartModePill('Bar Chart', 'bar', Icons.bar_chart_rounded, accent, isDark),
                      ],
                    ),
                  ),

                  // If Market Chart: Wave Glow vs Candlestick sub-toggle
                  if (_chartType == 'market')
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _marketStylePill('Area Wave', 'line', accent, isDark),
                          _marketStylePill('Candles', 'candle', accent, isDark),
                        ],
                      ),
                    ),

                  // Period Selector Pills
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _trendPeriodPill('Day to Day', TrendPeriod.day, accent, isDark),
                        _trendPeriodPill('Weekly', TrendPeriod.week, accent, isDark),
                        _trendPeriodPill('Monthly', TrendPeriod.month, accent, isDark),
                        _trendPeriodPill('Yearly', TrendPeriod.year, accent, isDark),
                      ],
                    ),
                  ),

                  // Auto-Refresh Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _countdownSeconds > 0
                          ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4))
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _countdownSeconds > 0
                            ? (isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0))
                            : AppTheme.border(context),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _countdownSeconds > 0 ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _countdownSeconds > 0 ? 'Live Sync (${_countdownSeconds}s)' : 'Manual Sync',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _countdownSeconds > 0
                                ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
                                : AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Manual Refresh Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        provider.refreshData(silent: false);
                        _chartAnimCtrl.forward(from: 0.0);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border(context)),
                          borderRadius: BorderRadius.circular(8),
                          color: isDark ? const Color(0xFF0F172A) : Colors.transparent,
                        ),
                        child: Icon(Icons.refresh_rounded, size: 18, color: accent),
                      ),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerInfo,
                    const SizedBox(height: 12),
                    controls,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  headerInfo,
                  const SizedBox(width: 16),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: controls,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Trend Metrics Strip with Financial Period High & Low Markers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Wrap(
              spacing: 20,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Current Period Revenue
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Current Period: ', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary(context))),
                    Text(
                      '$currency$currentFormatted',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                    ),
                  ],
                ),
                // Growth Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPos
                        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5))
                        : (isDark ? const Color(0xFF450A0A).withValues(alpha: 0.35) : const Color(0xFFFEF2F2)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isPos
                          ? (isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0))
                          : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPos ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 14,
                        color: isPos ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPos
                            ? 'PLUS (+$currency$diffFormatted | +${summary.percentDiff.toStringAsFixed(1)}%)'
                            : 'MINUS (-$currency$diffFormatted | -${summary.percentDiff.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPos
                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                              : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                ),
                // Total Stitches in Range
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grain_rounded, size: 15, color: accent),
                    const SizedBox(width: 5),
                    Text(
                      'Stitches: ${NumberFormat('#,##,###').format(summary.totalStitch)} (${summary.entryCount} Entries)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                    ),
                  ],
                ),
                // Financial High & Low indicators
                if (summary.points.isNotEmpty) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('▲ HIGH', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$currency${NumberFormat('#,##,###.00').format(maxPt)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('▼ LOW', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$currency${NumberFormat('#,##,###.00').format(minPt)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Interactive Hover Banner for Market Point Inspection
          if (hoveredPoint != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.insights_rounded, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    'Selected Point: ${hoveredPoint.label} (${DateFormat('dd-MM-yyyy').format(hoveredPoint.date)})',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                  ),
                  const Spacer(),
                  Text(
                    'Revenue: $currency${NumberFormat('#,##,###.00').format(hoveredPoint.finalAmount)}  •  Stitches: ${NumberFormat('#,##,###').format(hoveredPoint.totalStitch)}  •  Trend: ',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary(context)),
                  ),
                  Text(
                    hoveredPoint.percentChange >= 0
                        ? '+${hoveredPoint.percentChange.toStringAsFixed(1)}% Bullish'
                        : '${hoveredPoint.percentChange.toStringAsFixed(1)}% Bearish',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: hoveredPoint.isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),

          // Chart Visualization Area (Market Chart or Bar Chart)
          SizedBox(
            height: 230,
            child: summary.points.isEmpty
                ? Center(
                    child: Text('No records available for this period', style: TextStyle(color: AppTheme.textSecondary(context))),
                  )
                : (_chartType == 'market'
                    ? _buildMarketChart(summary, currency, accent, isDark)
                    : _buildBarChart(summary, currency, accent, isDark)),
          ),
        ],
      ),
    );
  }

  // --- 4.1. Financial Market Chart with MouseRegion hover tracking ---
  Widget _buildMarketChart(TrendSummary summary, String currency, Color accent, bool isDark) {
    return AnimatedBuilder(
      animation: _chartAnimCtrl,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return MouseRegion(
              onHover: (event) {
                final count = summary.points.length;
                if (count <= 1) return;
                const padLeft = 16.0;
                const padRight = 72.0;
                final chartWidth = constraints.maxWidth - padLeft - padRight;
                if (chartWidth <= 0) return;
                final stepX = chartWidth / (count - 1);
                final relX = event.localPosition.dx - padLeft;
                final idx = ((relX + stepX / 2) / stepX).floor().clamp(0, count - 1);
                if (_hoveredMarketPointIndex != idx) {
                  setState(() => _hoveredMarketPointIndex = idx);
                }
              },
              onExit: (_) {
                if (_hoveredMarketPointIndex != null) {
                  setState(() => _hoveredMarketPointIndex = null);
                }
              },
              child: CustomPaint(
                size: Size(constraints.maxWidth, 230),
                painter: MarketChartPainter(
                  points: summary.points,
                  progress: _chartAnimCtrl.value,
                  isDark: isDark,
                  accent: accent,
                  currency: currency,
                  style: _marketStyle,
                  hoveredIndex: _hoveredMarketPointIndex,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 4.2. Bar Comparison Chart ---
  Widget _buildBarChart(TrendSummary summary, String currency, Color accent, bool isDark) {
    return AnimatedBuilder(
      animation: _chartAnimCtrl,
      builder: (context, _) {
        final maxAmount = summary.points.map((p) => p.finalAmount).fold(0.0, (m, a) => a > m ? a : m);
        final safeMax = maxAmount > 0 ? maxAmount : 1.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final count = summary.points.length;
            final barWidth = (constraints.maxWidth / (count * 2.2)).clamp(28.0, 60.0);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: summary.points.map((pt) {
                final heightRatio = (pt.finalAmount / safeMax).clamp(0.08, 1.0);
                final animatedHeight = heightRatio * 140.0 * _chartAnimCtrl.value;
                final ptPos = pt.isPositive;

                return Tooltip(
                  richMessage: TextSpan(
                    children: [
                      TextSpan(text: '${pt.label}\n', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      TextSpan(text: 'Amount: $currency${NumberFormat('#,##,###.00').format(pt.finalAmount)}\n'),
                      TextSpan(text: 'Stitches: ${NumberFormat('#,##,###').format(pt.totalStitch)}\n'),
                      TextSpan(text: 'Entries: ${pt.entryCount}\n'),
                      TextSpan(
                        text: ptPos
                            ? 'Trend: ▲ +${pt.percentChange.toStringAsFixed(1)}%'
                            : 'Trend: ▼ ${pt.percentChange.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ptPos ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                        ),
                      ),
                    ],
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // +/- Percentage Pill on top of bar
                      Opacity(
                        opacity: _chartAnimCtrl.value.clamp(0.0, 1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: ptPos
                                ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5))
                                : (isDark ? const Color(0xFF450A0A).withValues(alpha: 0.4) : const Color(0xFFFEF2F2)),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: ptPos
                                  ? (isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0))
                                  : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            pt.percentChange == 0.0
                                ? 'Base'
                                : (ptPos
                                    ? '+${pt.percentChange.toStringAsFixed(1)}%'
                                    : '${pt.percentChange.toStringAsFixed(1)}%'),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: ptPos
                                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                  : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Animated Gradient Bar
                      Container(
                        width: barWidth,
                        height: animatedHeight,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          gradient: LinearGradient(
                            colors: ptPos
                                ? [const Color(0xFF10B981), const Color(0xFF047857)]
                                : [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ptPos ? const Color(0x3310B981) : const Color(0x33EF4444),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // X-Axis Label
                      Text(
                        pt.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$currency${_formatCondensed(pt.finalAmount)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // Helper toggle pill for Chart Mode ('market' vs 'bar')
  Widget _chartModePill(String title, String mode, IconData icon, Color accent, bool isDark) {
    final isSelected = _chartType == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        if (_chartType != mode) {
          setState(() => _chartType = mode);
          _chartAnimCtrl.forward(from: 0.0);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? accent : AppTheme.textSecondary(context),
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? accent : AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper toggle pill for Market Chart Style ('line' vs 'candle')
  Widget _marketStylePill(String title, String style, Color accent, bool isDark) {
    final isSelected = _marketStyle == style;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        if (_marketStyle != style) {
          setState(() => _marketStyle = style);
          _chartAnimCtrl.forward(from: 0.0);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? accent : AppTheme.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _trendAccountPill(String label, String value, Color? dotColor, Color accent, bool isDark) {
    final isSelected = _selectedTrendAccount == value;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        if (_selectedTrendAccount != value) {
          setState(() {
            _selectedTrendAccount = value;
            _hoveredMarketPointIndex = null;
          });
          _chartAnimCtrl.forward(from: 0.0);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? accent : AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendPeriodPill(String title, TrendPeriod period, Color accent, bool isDark) {
    final isSelected = _selectedTrendPeriod == period;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        if (_selectedTrendPeriod != period) {
          setState(() => _selectedTrendPeriod = period);
          _chartAnimCtrl.forward(from: 0.0);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? accent : AppTheme.textSecondary(context),
          ),
        ),
      ),
    );
  }

  String _formatCondensed(double val) {
    if (val >= 100000) {
      return '${(val / 100000).toStringAsFixed(1)}L';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}k';
    }
    return val.toStringAsFixed(0);
  }
}

// ==============================================================================
// FINANCIAL MARKET CHART PAINTER (SMOOTH BEZIER WAVE AREA & CANDLESTICKS)
// ==============================================================================
class MarketChartPainter extends CustomPainter {
  final List<TrendDataPoint> points;
  final double progress;
  final bool isDark;
  final Color accent;
  final String currency;
  final String style; // 'line' or 'candle'
  final int? hoveredIndex;

  MarketChartPainter({
    required this.points,
    required this.progress,
    required this.isDark,
    required this.accent,
    required this.currency,
    required this.style,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const double padLeft = 16.0;
    const double padRight = 72.0;
    const double padTop = 32.0;
    const double padBottom = 32.0;
    final double chartWidth = size.width - padLeft - padRight;
    final double chartHeight = size.height - padTop - padBottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Find min and max
    double maxAmount = points.first.finalAmount;
    double minAmount = points.first.finalAmount;
    int maxStitches = points.first.totalStitch;

    for (final pt in points) {
      if (pt.finalAmount > maxAmount) maxAmount = pt.finalAmount;
      if (pt.finalAmount < minAmount) minAmount = pt.finalAmount;
      if (pt.totalStitch > maxStitches) maxStitches = pt.totalStitch;
    }

    if (maxAmount == minAmount) {
      maxAmount = maxAmount > 0 ? maxAmount * 1.15 : 1000.0;
      minAmount = minAmount > 0 ? minAmount * 0.85 : 0.0;
    } else {
      final range = maxAmount - minAmount;
      maxAmount += range * 0.12;
      minAmount = (minAmount - range * 0.08).clamp(0.0, double.infinity);
    }
    final double amountRange = maxAmount - minAmount > 0 ? maxAmount - minAmount : 1.0;
    final int safeMaxStitches = maxStitches > 0 ? maxStitches : 1;

    // 1. Draw horizontal grid lines and price axis labels
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
    );

    const int gridLevels = 4;
    for (int i = 0; i <= gridLevels; i++) {
      final double y = padTop + chartHeight * (i / gridLevels);
      final double levelAmount = maxAmount - (amountRange * (i / gridLevels));

      // Dashed grid line
      const double dashWidth = 4.0;
      const double dashSpace = 4.0;
      double startX = padLeft;
      while (startX < padLeft + chartWidth) {
        canvas.drawLine(
          Offset(startX, y),
          Offset((startX + dashWidth).clamp(padLeft, padLeft + chartWidth), y),
          gridPaint,
        );
        startX += dashWidth + dashSpace;
      }

      // Right-side price level text
      final textSpan = TextSpan(
        text: '$currency${_formatShortAmount(levelAmount)}',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(padLeft + chartWidth + 8, y - textPainter.height / 2));
    }

    // 2. Compute coordinates for each data point
    final List<Offset> coords = [];
    final int count = points.length;
    final double stepX = count > 1 ? chartWidth / (count - 1) : chartWidth / 2;

    for (int i = 0; i < count; i++) {
      final x = count > 1 ? padLeft + i * stepX : padLeft + chartWidth / 2;
      final ratio = ((points[i].finalAmount - minAmount) / amountRange).clamp(0.0, 1.0);
      final targetY = padTop + chartHeight * (1.0 - ratio);
      final baselineY = padTop + chartHeight;
      final currentY = baselineY - (baselineY - targetY) * progress;
      coords.add(Offset(x, currentY));
    }

    // 3. Draw volume/stitch histogram bars at bottom
    final double volMaxHeight = chartHeight * 0.22;
    final double barW = (chartWidth / (count * 2.5)).clamp(8.0, 24.0);
    final volPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final pt = points[i];
      final stitchRatio = (pt.totalStitch / safeMaxStitches).clamp(0.08, 1.0);
      final volH = volMaxHeight * stitchRatio * progress;
      final x = coords[i].dx - barW / 2;
      final y = padTop + chartHeight - volH;

      volPaint.color = pt.isPositive
          ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.22)
          : const Color(0xFFEF4444).withValues(alpha: isDark ? 0.35 : 0.22);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, volH),
          const Radius.circular(3),
        ),
        volPaint,
      );
    }

    // 4. Style rendering: 'line' (Smooth Bezier + Glowing Area) or 'candle'
    if (style == 'line') {
      if (coords.length == 1) {
        final pt = coords.first;
        final pointPaint = Paint()..color = accent;
        canvas.drawCircle(pt, 6.0, pointPaint);
      } else {
        final path = Path();
        final fillPath = Path();

        path.moveTo(coords[0].dx, coords[0].dy);
        fillPath.moveTo(coords[0].dx, padTop + chartHeight);
        fillPath.lineTo(coords[0].dx, coords[0].dy);

        for (int i = 0; i < coords.length - 1; i++) {
          final p0 = coords[i];
          final p1 = coords[i + 1];
          final controlPointX = (p0.dx + p1.dx) / 2;

          path.cubicTo(controlPointX, p0.dy, controlPointX, p1.dy, p1.dx, p1.dy);
          fillPath.cubicTo(controlPointX, p0.dy, controlPointX, p1.dy, p1.dx, p1.dy);
        }

        fillPath.lineTo(coords.last.dx, padTop + chartHeight);
        fillPath.close();

        // Fill area gradient
        final fillGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: isDark ? 0.42 : 0.28),
            accent.withValues(alpha: isDark ? 0.12 : 0.05),
            accent.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.65, 1.0],
        );

        final fillPaint = Paint()
          ..shader = fillGradient.createShader(
            Rect.fromLTWH(padLeft, padTop, chartWidth, chartHeight),
          )
          ..style = PaintingStyle.fill;
        canvas.drawPath(fillPath, fillPaint);

        // Glowing Line Stroke
        final glowPaint = Paint()
          ..color = accent.withValues(alpha: 0.35)
          ..strokeWidth = 5.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(path, glowPaint);

        final linePaint = Paint()
          ..color = accent
          ..strokeWidth = 2.6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(path, linePaint);
      }

      // Draw node dots & glowing highlight beacon on latest / hovered point
      for (int i = 0; i < coords.length; i++) {
        final pt = coords[i];
        final isHovered = hoveredIndex == i;
        final isLast = i == coords.length - 1;

        if (isHovered || isLast) {
          canvas.drawCircle(
            pt,
            isHovered ? 9.0 : 7.0,
            Paint()..color = accent.withValues(alpha: 0.28),
          );
        }

        canvas.drawCircle(
          pt,
          isHovered ? 5.5 : 4.0,
          Paint()..color = isDark ? const Color(0xFF0F172A) : Colors.white,
        );

        canvas.drawCircle(
          pt,
          isHovered ? 3.8 : 2.6,
          Paint()..color = points[i].isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        );
      }
    } else {
      // Candlestick Style
      final candleWidth = (chartWidth / (count * 2.2)).clamp(10.0, 36.0);

      for (int i = 0; i < count; i++) {
        final pt = points[i];
        final center = coords[i];
        final isPos = pt.isPositive;
        final candleColor = isPos ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        final closeAmt = pt.finalAmount;
        final openAmt = (closeAmt - pt.changeAmount).clamp(0.0, double.infinity);
        final highAmt = (max(closeAmt, openAmt) * 1.035);
        final lowAmt = (min(closeAmt, openAmt) * 0.965);

        final highY = padTop + chartHeight * (1.0 - ((highAmt - minAmount) / amountRange).clamp(0.0, 1.0));
        final lowY = padTop + chartHeight * (1.0 - ((lowAmt - minAmount) / amountRange).clamp(0.0, 1.0));
        final openY = padTop + chartHeight * (1.0 - ((openAmt - minAmount) / amountRange).clamp(0.0, 1.0));
        final closeY = center.dy;

        final bodyTop = min(openY, closeY);
        final bodyBottom = max(openY, closeY);
        final bodyHeight = max(4.0, bodyBottom - bodyTop) * progress;

        // Wick
        final wickPaint = Paint()
          ..color = candleColor
          ..strokeWidth = 1.5;
        canvas.drawLine(
          Offset(center.dx, padTop + chartHeight - (padTop + chartHeight - highY) * progress),
          Offset(center.dx, padTop + chartHeight - (padTop + chartHeight - lowY) * progress),
          wickPaint,
        );

        // Body
        final bodyPaint = Paint()
          ..color = candleColor
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - candleWidth / 2, bodyTop, candleWidth, bodyHeight),
            const Radius.circular(2.5),
          ),
          bodyPaint,
        );
      }
    }

    // 5. Draw X-axis date labels
    final labelStyle = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
    );

    for (int i = 0; i < count; i++) {
      final label = points[i].label;
      final textSpan = TextSpan(text: label, style: labelStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(coords[i].dx - textPainter.width / 2, padTop + chartHeight + 10),
      );
    }
  }

  String _formatShortAmount(double val) {
    if (val >= 100000) {
      return '${(val / 100000).toStringAsFixed(1)}L';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}k';
    }
    return val.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant MarketChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.accent != accent ||
        oldDelegate.style != style ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}

