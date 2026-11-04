import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../models/production_record.dart';
import '../../providers/production_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Multi-Filter State
  String _selectedAccount = 'All Accounts';
  String _selectedMachine = 'All Machines';
  String _selectedShift = 'All Shifts';
  String _datePreset = 'All Time'; // 'All Time', 'Today', 'Last 7 Days', 'This Month', 'Custom'
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchCtrl = TextEditingController();

  // Chart Mode: 0 = Date-wise Trend, 1 = Machine Comparison, 2 = Shift Breakdown
  int _chartMode = 0;

  // Detailed Table Sorting
  int _tableSortColumnIndex = 1;
  bool _tableSortAscending = false;

  Timer? _refreshTimer;
  int _lastConfiguredInterval = -1;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _checkAndSyncTimer(int intervalSeconds) {
    if (_lastConfiguredInterval != intervalSeconds) {
      _lastConfiguredInterval = intervalSeconds;
      _refreshTimer?.cancel();
      if (intervalSeconds > 0) {
        _refreshTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
          if (!mounted) return;
          context.read<ProductionProvider>().refreshData(silent: true);
        });
      }
    }
  }

  void _setDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _datePreset = preset;
      if (preset == 'Today') {
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (preset == 'Last 7 Days') {
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
      } else if (preset == 'This Month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else if (preset == 'All Time') {
        _startDate = null;
        _endDate = null;
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedAccount = 'All Accounts';
      _selectedMachine = 'All Machines';
      _selectedShift = 'All Shifts';
      _datePreset = 'All Time';
      _startDate = null;
      _endDate = null;
      _searchCtrl.clear();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime(2050),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now()),
    );
    if (picked != null) {
      setState(() {
        _datePreset = 'Custom';
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    _checkAndSyncTimer(provider.settings.autoRefreshIntervalSeconds);
    final isDark = provider.settings.isDarkMode;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);
    final lang = provider.settings.appLanguage;

    // Apply multiple filters simultaneously
    final records = provider.getFilteredAnalyticsRecords(
      accountName: _selectedAccount,
      machineNo: _selectedMachine,
      startDate: _startDate,
      endDate: _endDate,
      shift: _selectedShift,
      searchQuery: _searchCtrl.text,
    );

    // KPI Metrics for the filtered subset
    final totalStitches = records.fold<int>(0, (s, r) => s + r.totalStitch);
    final totalAmount = records.fold<double>(0.0, (s, r) => s + r.finalAmount);
    final totalBatches = records.length;
    final avgStitchesPerBatch = totalBatches > 0 ? (totalStitches / totalBatches).round() : 0;
    final stitchesInLakhs = (totalStitches / 100000.0).toStringAsFixed(2);

    // Grouping by Date for Date-wise Chart
    final Map<String, _DateStat> dateMap = {};
    for (final r in records) {
      final key = DateFormat('dd MMM').format(r.date);
      if (!dateMap.containsKey(key)) {
        dateMap[key] = _DateStat(dateLabel: key, date: r.date);
      }
      dateMap[key]!.totalStitches += r.totalStitch;
      dateMap[key]!.totalAmount += r.finalAmount;
      dateMap[key]!.entriesCount++;
    }
    final sortedDateStats = dateMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));

    // Grouping by Machine for Machine Comparison
    final Map<String, _MachineStat> machineMap = {};
    for (final m in provider.machines) {
      machineMap[m.machineNo] = _MachineStat(machineNo: m.machineNo, machineName: m.name);
    }
    for (final r in records) {
      machineMap.putIfAbsent(r.machineNo, () => _MachineStat(machineNo: r.machineNo, machineName: r.machineNo));
      machineMap[r.machineNo]!.totalStitches += r.totalStitch;
      machineMap[r.machineNo]!.totalAmount += r.finalAmount;
      machineMap[r.machineNo]!.batchesCount++;
    }
    final activeMachineStats = machineMap.values.where((m) => m.totalStitches > 0).toList()
      ..sort((a, b) => b.totalStitches.compareTo(a.totalStitches));

    // Shift breakdown
    final dayStitches = records.where((r) => r.shift.toLowerCase() == 'day').fold<int>(0, (s, r) => s + r.totalStitch);
    final nightStitches = records.where((r) => r.shift.toLowerCase() == 'night').fold<int>(0, (s, r) => s + r.totalStitch);
    final dayAmount = records.where((r) => r.shift.toLowerCase() == 'day').fold<double>(0.0, (s, r) => s + r.finalAmount);
    final nightAmount = records.where((r) => r.shift.toLowerCase() == 'night').fold<double>(0.0, (s, r) => s + r.finalAmount);

    final hasActiveFilter = _selectedAccount != 'All Accounts' ||
        _selectedMachine != 'All Machines' ||
        _selectedShift != 'All Shifts' ||
        _datePreset != 'All Time' ||
        _searchCtrl.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insights_rounded, size: 24, color: accent),
                          const SizedBox(width: 10),
                          Text(
                            AppStrings.t(lang, en: 'Analytics & Production Reports', gu: 'એનાલિટિક્સ અને પ્રોડક્શન રિપોર્ટ્સ', hi: 'उत्पादन विश्लेषण एवं रिपोर्ट्स'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary(context),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.t(lang, en: 'Filter by Khata, Machine, Date & Shift together with live interactive visual charts', gu: 'ખાતાવહી, મશીન, તારીખ અને શિફ્ટ ફિલ્ટર સાથે લાઈવ ચાર્ટ્સ', hi: 'खाता, मशीन, तारीख एवं शिफ्ट अनुसार लाइव इंटरैक्टिव चार्ट्स'),
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted(context)),
                      ),
                    ],
                  ),
                ),
                if (hasActiveFilter)
                  OutlinedButton.icon(
                    onPressed: _clearAllFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: Text(AppStrings.t(lang, en: 'Reset All Filters', gu: 'તમામ ફિલ્ટર રીસેટ કરો', hi: 'सभी फ़िल्टर साफ़ करें')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerRedDark,
                      side: const BorderSide(color: AppTheme.dangerRedLight, width: 1.2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Multi-Filter Control Console
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardBg(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 18, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.t(lang, en: 'Multi-Filter Console', gu: 'મલ્ટી-ફિલ્ટર કન્સોલ', hi: 'मल्टी-फ़िल्टर कंसोल'),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                      ),
                      const Spacer(),
                      Text(
                        'Matches: ${records.length} Batches',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 1: Khata (Account) + Machine + Shift + Search
                  Row(
                    children: [
                      // 1. Khata / Account Filter
                      Expanded(
                        flex: 3,
                        child: _dropdownField(
                          label: AppStrings.t(lang, en: 'Account / Khata', gu: 'ખાતું (Account)', hi: 'खाता (Account)'),
                          icon: Icons.account_balance_wallet_outlined,
                          value: _selectedAccount,
                          items: ['All Accounts', ...provider.accounts.map((a) => a.name)],
                          onChanged: (val) => setState(() => _selectedAccount = val!),
                          context: context,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 2. Machine Filter
                      Expanded(
                        flex: 3,
                        child: _dropdownField(
                          label: AppStrings.t(lang, en: 'Machine No.', gu: 'મશીન નંબર', hi: 'मशीन नंबर'),
                          icon: Icons.precision_manufacturing_outlined,
                          value: _selectedMachine,
                          items: ['All Machines', ...provider.machines.map((m) => m.machineNo)],
                          onChanged: (val) => setState(() => _selectedMachine = val!),
                          context: context,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 3. Shift Filter
                      Expanded(
                        flex: 2,
                        child: _dropdownField(
                          label: AppStrings.t(lang, en: 'Shift', gu: 'શિફ્ટ', hi: 'पाली (Shift)'),
                          icon: Icons.wb_twilight_rounded,
                          value: _selectedShift,
                          items: const ['All Shifts', 'Day', 'Night'],
                          onChanged: (val) => setState(() => _selectedShift = val!),
                          context: context,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 4. Search Filter
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 44,
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Design / Search',
                              hintText: '11010, 257...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 18),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 2: Date Range Presets & Custom Picker
                  Row(
                    children: [
                      Text(
                        'Date Range: ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary(context)),
                      ),
                      const SizedBox(width: 8),
                      _presetChip('All Time', accent),
                      _presetChip('Today', accent),
                      _presetChip('Last 7 Days', accent),
                      _presetChip('This Month', accent),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range_rounded, size: 16),
                        label: Text(
                          _startDate != null && _endDate != null
                              ? '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}'
                              : 'Custom Date Range',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: BorderSide(
                            color: _datePreset == 'Custom' ? accent : AppTheme.border(context),
                            width: _datePreset == 'Custom' ? 1.8 : 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4 KPI Summary Cards (Live filtered)
            Row(
              children: [
                Expanded(
                  child: _kpiCard(
                    title: AppStrings.t(lang, en: 'Total Stitches', gu: 'કુલ ટાંકા (Stitches)', hi: 'कुल स्टिच'),
                    value: NumberFormat('#,##,###').format(totalStitches),
                    subtitle: '$stitchesInLakhs Lakh Stitches',
                    icon: Icons.grain_rounded,
                    color: const Color(0xFF16A34A),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _kpiCard(
                    title: AppStrings.t(lang, en: 'Total Amount', gu: 'કુલ રકમ (Amount)', hi: 'कुल रकम'),
                    value: '₹ ${NumberFormat('#,##,###.00').format(totalAmount)}',
                    subtitle: 'From $totalBatches batches',
                    icon: Icons.currency_rupee_rounded,
                    color: const Color(0xFF2563EB),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _kpiCard(
                    title: 'Avg. Stitches / Batch',
                    value: NumberFormat('#,##,###').format(avgStitchesPerBatch),
                    subtitle: 'Average machine batch volume',
                    icon: Icons.speed_rounded,
                    color: const Color(0xFF9333EA),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _kpiCard(
                    title: 'Active Filter Selection',
                    value: _selectedAccount == 'All Accounts' ? 'All Accounts' : _selectedAccount,
                    subtitle: _selectedMachine == 'All Machines' ? 'All Machines' : _selectedMachine,
                    icon: Icons.filter_alt_rounded,
                    color: const Color(0xFFD97706),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Interactive Chart Card with 3 View Modes
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBg(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart Header & Mode Selector
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bar_chart_rounded, size: 20, color: accent),
                              const SizedBox(width: 8),
                              Text(
                                _chartMode == 0
                                    ? AppStrings.t(lang, en: 'Date-wise Production Chart', gu: 'તારીખ મુજબ પ્રોડક્શન ચાર્ટ', hi: 'तारीख अनुसार उत्पादन ट्रेंड')
                                    : _chartMode == 1
                                        ? AppStrings.t(lang, en: 'Machine-wise Comparison Chart', gu: 'મશીન મુજબ સરખામણી ચાર્ટ', hi: 'मशीन अनुसार तुलनात्मक चार्ट')
                                        : AppStrings.t(lang, en: 'Shift Breakdown', gu: 'શિફ્ટ વિશ્લેષણ', hi: 'दिन बनाम रात शिफ्ट ब्रेकडाउन'),
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                              ),
                            ],
                          ),
                          Text(
                            'Showing filtered data for: $_selectedAccount • $_selectedMachine • $_selectedShift',
                            style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted(context)),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Mode Switcher Buttons
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSubtle(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: Row(
                          children: [
                            _chartModeBtn('Date Trend', 0, Icons.timeline_rounded, accent),
                            _chartModeBtn('Machine Wise', 1, Icons.precision_manufacturing_rounded, accent),
                            _chartModeBtn('Shift Wise', 2, Icons.wb_sunny_rounded, accent),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Chart Content Body
                  records.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.analytics_outlined, size: 48, color: AppTheme.textMuted(context)),
                                const SizedBox(height: 8),
                                Text(
                                  'No production records found matching this combination of filters.',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _chartMode == 0
                          ? _buildDateWiseChart(sortedDateStats, accent, isDark)
                          : _chartMode == 1
                              ? _buildMachineComparisonChart(activeMachineStats, accent, isDark)
                              : _buildShiftComparisonView(dayStitches, nightStitches, dayAmount, nightAmount, totalStitches, totalAmount, isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Filtered Record Data Table Card
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Text(
                          'Detailed Production Records (${records.length} Entries)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                        ),
                        const Spacer(),
                        Text(
                          'Filtered Total: ₹ ${NumberFormat('#,##,###.00').format(totalAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.successGreenDark),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  records.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'No records match the current filter selection.',
                              style: TextStyle(color: AppTheme.textMuted(context)),
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final tableRecords = List<ProductionRecord>.from(records);
                            tableRecords.sort((a, b) {
                              int cmp = 0;
                              switch (_tableSortColumnIndex) {
                                case 0:
                                  cmp = (a.id ?? 0).compareTo(b.id ?? 0);
                                  break;
                                case 1:
                                  cmp = a.date.compareTo(b.date);
                                  break;
                                case 2:
                                  cmp = a.shift.toLowerCase().compareTo(b.shift.toLowerCase());
                                  break;
                                case 3:
                                  cmp = a.accountName.toLowerCase().compareTo(b.accountName.toLowerCase());
                                  break;
                                case 4:
                                  cmp = a.machineNo.toLowerCase().compareTo(b.machineNo.toLowerCase());
                                  break;
                                case 5:
                                  cmp = a.designNo.toLowerCase().compareTo(b.designNo.toLowerCase());
                                  break;
                                case 6:
                                  cmp = a.totalStitch.compareTo(b.totalStitch);
                                  break;
                                case 7:
                                  cmp = a.heads.compareTo(b.heads);
                                  break;
                                case 8:
                                  cmp = a.rate.compareTo(b.rate);
                                  break;
                                case 9:
                                  cmp = a.finalAmount.compareTo(b.finalAmount);
                                  break;
                                default:
                                  cmp = a.date.compareTo(b.date);
                              }
                              return _tableSortAscending ? cmp : -cmp;
                            });

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  sortColumnIndex: _tableSortColumnIndex,
                                  sortAscending: _tableSortAscending,
                                  headingRowHeight: 44,
                                  dataRowMinHeight: 48,
                                  dataRowMaxHeight: 52,
                                  horizontalMargin: 16,
                                  columnSpacing: 18,
                                  headingRowColor: WidgetStateProperty.all(AppTheme.tableHeaderBg(context)),
                                  columns: [
                                    DataColumn(
                                      label: const Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      onSort: (idx, asc) => setState(() {
                                        _tableSortColumnIndex = idx;
                                        _tableSortAscending = asc;
                                      }),
                                    ),
                                    DataColumn(
                                      label: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      onSort: (idx, asc) => setState(() {
                                        _tableSortColumnIndex = idx;
                                        _tableSortAscending = asc;
                                      }),
                                    ),
                                    DataColumn(
                                      label: const Text('Shift', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      onSort: (idx, asc) => setState(() {
                                        _tableSortColumnIndex = idx;
                                        _tableSortAscending = asc;
                                      }),
                                    ),
                                    DataColumn(
                                      label: const Text('Khata (Account)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      onSort: (idx, asc) => setState(() {
                                        _tableSortColumnIndex = idx;
                                        _tableSortAscending = asc;
                                      }),
                                    ),
                                    DataColumn(
                                      label: const Text('Machine No.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      onSort: (idx, asc) => setState(() {
                                        _tableSortColumnIndex = idx;
                                        _tableSortAscending = asc;
                                      }),
                                    ),
                                    DataColumn(
                                      label: const Text('Design No.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      onSort: (idx, asc) => setState(() {
                                        _tableSortColumnIndex = idx;
                                        _tableSortAscending = asc;
                                      }),
                                    ),
                                    DataColumn(
                                      numeric: true,
                                      label: const Text('Total Stitch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      onSort: (idx, asc) => setState(() {
                                        _tableSortColumnIndex = idx;
                                        _tableSortAscending = asc;
                                      }),
                                    ),
                                    DataColumn(
                                      numeric: true,
                                      label: const Text('Heads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      onSort: (idx, asc) => setState(() {
                                        _tableSortColumnIndex = idx;
                                        _tableSortAscending = asc;
                                      }),
                                    ),
                                    DataColumn(
                                      numeric: true,
                                      label: const Text('Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      onSort: (idx, asc) => setState(() {
                                        _tableSortColumnIndex = idx;
                                        _tableSortAscending = asc;
                                      }),
                                    ),
                                    DataColumn(
                                      numeric: true,
                                      label: const Text('Final Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      onSort: (idx, asc) => setState(() {
                                        _tableSortColumnIndex = idx;
                                        _tableSortAscending = asc;
                                      }),
                                    ),
                                  ],
                                  rows: tableRecords.asMap().entries.map((entry) {
                                    final index = entry.key + 1;
                                    final r = entry.value;

                                    return DataRow(
                                      cells: [
                                        DataCell(Text('$index', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5))),
                                        DataCell(Text(r.formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: r.shift.toLowerCase() == 'night'
                                                  ? Colors.indigo.withValues(alpha: 0.15)
                                                  : Colors.amber.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              r.shift,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: r.shift.toLowerCase() == 'night' ? Colors.indigo : Colors.amber.shade800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            r.accountName,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: accent.withValues(alpha: isDark ? 0.25 : 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              r.machineNo,
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: accent),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(r.designNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataCell(Text(NumberFormat('#,##,###').format(r.totalStitch), style: const TextStyle(fontSize: 12))),
                                        DataCell(Text('${r.heads}', style: const TextStyle(fontSize: 12))),
                                        DataCell(Text('₹ ${r.rate.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12))),
                                        DataCell(
                                          Text(
                                            '₹ ${NumberFormat('#,##,###.00').format(r.finalAmount)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.successGreenDark),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Visual Chart Renderers ---

  Widget _buildDateWiseChart(List<_DateStat> stats, Color accent, bool isDark) {
    if (stats.isEmpty) return const SizedBox();

    final lang = context.watch<ProductionProvider>().settings.appLanguage;
    final maxStitch = stats.map((s) => s.totalStitches).reduce(max);
    final safeMax = maxStitch > 0 ? maxStitch : 1;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: stats.map((stat) {
              final ratio = (stat.totalStitches / safeMax).clamp(0.05, 1.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${(stat.totalStitches / 1000).toStringAsFixed(0)}k',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary(context)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: (160 * ratio).toDouble(),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [accent, accent.withValues(alpha: 0.7)],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stat.dateLabel,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 12, height: 12, color: accent),
            const SizedBox(width: 6),
            Text(AppStrings.t(lang, en: 'Date-wise Stitch Volume', gu: 'તારીખ મુજબ ટાંકા વોલ્યુમ', hi: 'तारीख अनुसार स्टिच वॉल्यूम'), style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted(context))),
          ],
        ),
      ],
    );
  }

  Widget _buildMachineComparisonChart(List<_MachineStat> stats, Color accent, bool isDark) {
    if (stats.isEmpty) return const SizedBox();

    final maxStitches = stats.map((s) => s.totalStitches).reduce(max);
    final safeMax = maxStitches > 0 ? maxStitches : 1;

    return Column(
      children: stats.map((m) {
        final ratio = (m.totalStitches / safeMax).clamp(0.02, 1.0);
        final isTop = m == stats.first;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Row(
                  children: [
                    Text(
                      m.machineNo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (isTop) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.workspace_premium_rounded, size: 13, color: Color(0xFFD97706)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 24,
                    color: AppTheme.surfaceSubtle(context),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ratio,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isTop
                                ? [Colors.amber.shade600, Colors.amber.shade400]
                                : [accent, accent.withValues(alpha: 0.7)],
                          ),
                        ),
                        child: Text(
                          NumberFormat('#,##,###').format(m.totalStitches),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isTop ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 110,
                child: Text(
                  '₹ ${NumberFormat('#,##,###.00').format(m.totalAmount)}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.successGreenDark),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShiftComparisonView(
    int dayStitches,
    int nightStitches,
    double dayAmount,
    double nightAmount,
    int totalStitches,
    double totalAmount,
    bool isDark,
  ) {
    final lang = context.watch<ProductionProvider>().settings.appLanguage;
    final dayRatio = totalStitches > 0 ? (dayStitches / totalStitches * 100).toStringAsFixed(1) : '0.0';
    final nightRatio = totalStitches > 0 ? (nightStitches / totalStitches * 100).toStringAsFixed(1) : '0.0';

    return Row(
      children: [
        // Day Shift Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade400, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny_rounded, color: Colors.amber.shade800, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      AppStrings.t(lang, en: 'Day Shift', gu: 'દિવસની શિફ્ટ', hi: 'दिन की शिफ्ट'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.amber.shade400, borderRadius: BorderRadius.circular(6)),
                      child: Text('$dayRatio%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Total Stitches: ${NumberFormat('#,##,###').format(dayStitches)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Revenue: ₹ ${NumberFormat('#,##,###.00').format(dayAmount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.successGreenDark)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Night Shift Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade400, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.nightlight_round, color: Colors.indigo.shade600, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      AppStrings.t(lang, en: 'Night Shift', gu: 'રાતની શિફ્ટ', hi: 'रात की शिफ्ट'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.indigo.shade500, borderRadius: BorderRadius.circular(6)),
                      child: Text('$nightRatio%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Total Stitches: ${NumberFormat('#,##,###').format(nightStitches)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Revenue: ₹ ${NumberFormat('#,##,###.00').format(nightAmount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.successGreenDark)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Helpers ---

  Widget _presetChip(String label, Color accent) {
    final isSelected = _datePreset == label;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (_) => _setDatePreset(label),
        selectedColor: accent.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? accent : AppTheme.textPrimary(context),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _chartModeBtn(String label, int mode, IconData icon, Color accent) {
    final isSelected = _chartMode == mode;
    return InkWell(
      onTap: () => setState(() => _chartMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? AppTheme.contrastText(accent) : AppTheme.textMuted(context)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.contrastText(accent) : AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary(context))),
        const SizedBox(height: 4),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded),
              items: items.map((it) {
                return DropdownMenuItem(
                  value: it,
                  child: Row(
                    children: [
                      Icon(icon, size: 15, color: AppTheme.textMuted(context)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          it,
                          style: TextStyle(fontSize: 12, fontWeight: it == value ? FontWeight.bold : FontWeight.normal),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context)), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context), letterSpacing: -0.2), overflow: TextOverflow.ellipsis),
                Text(subtitle, style: TextStyle(fontSize: 10, color: AppTheme.textMuted(context)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateStat {
  final String dateLabel;
  final DateTime date;
  int totalStitches = 0;
  double totalAmount = 0.0;
  int entriesCount = 0;

  _DateStat({required this.dateLabel, required this.date});
}

class _MachineStat {
  final String machineNo;
  final String machineName;
  int totalStitches = 0;
  double totalAmount = 0.0;
  int batchesCount = 0;

  _MachineStat({required this.machineNo, required this.machineName});
}
