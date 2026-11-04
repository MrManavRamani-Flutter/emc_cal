import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/calculation_engine.dart';
import '../core/localization/app_strings.dart';
import '../data/database_helper.dart';
import '../models/models.dart';
export '../models/trend_summary.dart';
export '../models/account_summary.dart';
export '../models/machine_summary.dart';
export '../models/daily_chart_stat.dart';

class ProductionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<ProductionRecord> _records = [];
  List<MachineModel> _machines = [];
  List<AccountModel> _accounts = [];
  List<DeletedRecordItem> _deletedRecords = [];
  List<DeletedRecordItem> _archivedRecords = [];
  SettingsModel _settings = SettingsModel();

  bool _isLoading = true;
  String? _errorMessage;

  // Selected Record for Dashboard & Entry Screens (Independently tracked)
  ProductionRecord? _dashboardSelectedRecord;
  ProductionRecord? _entrySelectedRecord;
  final Set<int> _selectedIds = {};

  // Filtering & Search
  String _searchQuery = '';
  String _selectedMachineFilter = 'All Machines';
  String _selectedShiftFilter = 'All';
  String _selectedAccountFilter = 'All Accounts';
  DateTime? _fromDate;
  DateTime? _toDate;

  // Pagination
  int _currentPage = 1;
  int _rowsPerPage = 10;

  // Sorting
  String _sortColumn = 'date';
  bool _sortAscending = false;

  // Active Screen Navigation (0 to 10)
  int _activeNavIndex = 0;

  // Material & Stock Management State
  List<MaterialItem> _materials = [];
  List<MaterialProduct> _materialProducts = [];
  List<Supplier> _suppliers = [];
  String _selectedMaterialCategory = 'Challan'; // 'Challan', 'Sequence', 'Beads', 'Dhaga', 'Products', 'Suppliers'
  String _materialSearchQuery = '';
  String _materialDateFilter = 'All Time';
  DateTimeRange? _materialCustomDateRange;
  String _materialProductFilter = 'All Products';
  String _materialSupplierFilter = 'All Suppliers';

  // Employee & Upad Management State
  List<EmployeeModel> _employees = [];
  List<EmployeeUpadModel> _employeeUpads = [];
  List<WhatsAppLogModel> _whatsappLogs = [];
  String _employeeSearchQuery = '';
  String _selectedEmployeeRoleFilter = 'All Roles';
  bool _employeeActiveOnlyFilter = false;

  ProductionProvider() {
    init();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ProductionRecord> get allRecords => _records;
  List<MachineModel> get machines => _machines;
  List<AccountModel> get accounts => _accounts;
  List<DeletedRecordItem> get deletedRecords => _deletedRecords;
  List<DeletedRecordItem> get archivedRecords => _archivedRecords;
  SettingsModel get settings => _settings;
  ProductionRecord? get dashboardSelectedRecord => _dashboardSelectedRecord;
  ProductionRecord? get entrySelectedRecord => _entrySelectedRecord;
  ProductionRecord? get selectedRecord => _dashboardSelectedRecord;
  Set<int> get selectedIds => _selectedIds;
  int get activeNavIndex => _activeNavIndex;

  String get searchQuery => _searchQuery;
  String get selectedMachineFilter => _selectedMachineFilter;
  String get selectedShiftFilter => _selectedShiftFilter;
  String get selectedAccountFilter => _selectedAccountFilter;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;

  int get currentPage => _currentPage.clamp(1, max(1, totalPages));
  int get rowsPerPage => _rowsPerPage;

  String get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;

  void setSort(String column) {
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = true;
    }
    _currentPage = 1;
    notifyListeners();
  }

  // Material & Stock Getters
  List<MaterialItem> get materials => _materials;
  List<MaterialProduct> get materialProducts => _materialProducts;
  List<Supplier> get suppliers => _suppliers;
  List<Supplier> get activeSuppliers => _suppliers.where((s) => s.isActive).toList();
  String get selectedMaterialCategory => _selectedMaterialCategory;
  String get materialSearchQuery => _materialSearchQuery;
  String get materialDateFilter => _materialDateFilter;
  DateTimeRange? get materialCustomDateRange => _materialCustomDateRange;
  String get materialProductFilter => _materialProductFilter;
  String get materialSupplierFilter => _materialSupplierFilter;

  // Employee & Upad Getters
  List<EmployeeModel> get employees => _employees;
  List<EmployeeUpadModel> get employeeUpads => _employeeUpads;
  List<WhatsAppLogModel> get whatsappLogs => _whatsappLogs;
  String get employeeSearchQuery => _employeeSearchQuery;
  String get selectedEmployeeRoleFilter => _selectedEmployeeRoleFilter;
  bool get employeeActiveOnlyFilter => _employeeActiveOnlyFilter;

  List<EmployeeModel> get filteredEmployees {
    return _employees.where((e) {
      if (_employeeActiveOnlyFilter && !e.isActive) return false;
      if (_selectedEmployeeRoleFilter != 'All Roles' && e.role != _selectedEmployeeRoleFilter) return false;
      if (_employeeSearchQuery.trim().isNotEmpty) {
        final query = _employeeSearchQuery.trim().toLowerCase();
        final matchesName = e.name.toLowerCase().contains(query);
        final matchesRole = e.role.toLowerCase().contains(query);
        final matchesPhone = e.phone.toLowerCase().contains(query);
        if (!matchesName && !matchesRole && !matchesPhone) return false;
      }
      return true;
    }).toList();
  }

  double getEmployeeTotalUpad(int employeeId, {bool unsettledOnly = true}) {
    return _employeeUpads
        .where((u) => u.employeeId == employeeId && (!unsettledOnly || !u.isSettled))
        .fold(0.0, (sum, u) => sum + u.amount);
  }

  double getEmployeeRemainingSalary(EmployeeModel employee) {
    if (employee.id == null) return employee.monthlySalary;
    final totalUpad = getEmployeeTotalUpad(employee.id!, unsettledOnly: true);
    return max(0.0, employee.monthlySalary - totalUpad);
  }

  List<EmployeeUpadModel> getUpadsForEmployee(int employeeId) {
    return _employeeUpads.where((u) => u.employeeId == employeeId).toList();
  }

  double getEmployeeAllTimeTotalUpad(int employeeId) {
    return _employeeUpads
        .where((u) => u.employeeId == employeeId)
        .fold(0.0, (sum, u) => sum + u.amount);
  }

  double getEmployeeSettledUpad(int employeeId) {
    return _employeeUpads
        .where((u) => u.employeeId == employeeId && u.isSettled)
        .fold(0.0, (sum, u) => sum + u.amount);
  }

  double get totalMonthlyPayroll => _employees.where((e) => e.isActive).fold(0.0, (s, e) => s + e.monthlySalary);
  double get totalPendingUpad => _employeeUpads.where((u) => !u.isSettled).fold(0.0, (s, u) => s + u.amount);
  double get totalAllTimeFactoryUpad => _employeeUpads.fold(0.0, (s, u) => s + u.amount);
  double get totalNetPayableSalary => max(0.0, totalMonthlyPayroll - totalPendingUpad);
  int get totalActiveEmployees => _employees.where((e) => e.isActive).length;
  List<String> get employeeRoles => _settings.employeeRoles;

  List<String> get materialSuppliers {
    final set = <String>{};
    for (final s in _suppliers) {
      if (s.name.trim().isNotEmpty && s.isActive) {
        set.add(s.name.trim());
      }
    }
    for (final m in _materials) {
      if (m.supplierName.trim().isNotEmpty) {
        set.add(m.supplierName.trim());
      }
    }
    return ['All Suppliers', ...set.toList()..sort()];
  }

  List<String> get materialProductNames {
    final set = <String>{};
    for (final m in _materials) {
      if (m.productName.trim().isNotEmpty) {
        set.add(m.productName.trim());
      }
    }
    return ['All Products', ...set.toList()..sort()];
  }

  List<MaterialProduct> getProductsByCategory(String category) {
    if (category == 'All' || category == 'All Material' || category == 'Challan') {
      return _materialProducts.where((p) => p.isActive).toList();
    }
    final catLower = category.trim().toLowerCase();
    return _materialProducts.where((p) {
      if (!p.isActive) return false;
      final pCat = p.category.trim().toLowerCase();
      if (catLower == 'dhaga' || catLower == 'daga' || catLower == 'thread') {
        return pCat == 'dhaga' || pCat == 'daga' || pCat == 'thread';
      }
      return pCat == catLower;
    }).toList();
  }

  List<MaterialItem> getFilteredMaterialsForCategory(String category) {
    final catLower = category.trim().toLowerCase();
    final isAll = catLower.isEmpty ||
        catLower == 'all' ||
        catLower == 'all material' ||
        catLower == 'challan';

    return _materials.where((item) {
      final itemCat = item.category.trim().toLowerCase();

      // 1. Category Filter: Thread, Dhaga & Daga are treated interchangeably
      if (!isAll) {
        if (catLower == 'dhaga' || catLower == 'daga' || catLower == 'thread') {
          if (itemCat != 'dhaga' && itemCat != 'daga' && itemCat != 'thread') return false;
        } else {
          if (itemCat != catLower) return false;
        }
      }

      // 2. Product Filter (Safe per category: only apply if the selected product filter belongs to this category or matches)
      if (_materialProductFilter != 'All Products') {
        if (item.productName != _materialProductFilter) {
          final productBelongsToCategory = _materialProducts.any((p) {
            final pCat = p.category.trim().toLowerCase();
            final matchesCurrentCat = isAll ||
                ((catLower == 'dhaga' || catLower == 'daga' || catLower == 'thread')
                    ? (pCat == 'dhaga' || pCat == 'daga' || pCat == 'thread')
                    : pCat == catLower);
            return p.name == _materialProductFilter && matchesCurrentCat;
          });
          if (productBelongsToCategory || isAll) {
            return false;
          }
        }
      }

      // 3. Date Filter
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final itemDay = DateTime(item.date.year, item.date.month, item.date.day);

      if (_materialDateFilter == 'Today') {
        if (!itemDay.isAtSameMomentAs(today)) return false;
      } else if (_materialDateFilter == 'Yesterday') {
        final yesterday = today.subtract(const Duration(days: 1));
        if (!itemDay.isAtSameMomentAs(yesterday)) return false;
      } else if (_materialDateFilter == 'This Week') {
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        if (item.date.isBefore(startOfWeek) || item.date.isAfter(endOfWeek)) return false;
      } else if (_materialDateFilter == 'This Month') {
        if (item.date.year != now.year || item.date.month != now.month) return false;
      } else if (_materialDateFilter == 'Last Month') {
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        if (item.date.year != lastMonthDate.year || item.date.month != lastMonthDate.month) return false;
      } else if (_materialDateFilter == 'Custom' && _materialCustomDateRange != null) {
        final start = DateTime(
          _materialCustomDateRange!.start.year,
          _materialCustomDateRange!.start.month,
          _materialCustomDateRange!.start.day,
        );
        final end = DateTime(
          _materialCustomDateRange!.end.year,
          _materialCustomDateRange!.end.month,
          _materialCustomDateRange!.end.day,
          23,
          59,
          59,
        );
        if (item.date.isBefore(start) || item.date.isAfter(end)) return false;
      }

      // 4. Supplier Filter
      if (_materialSupplierFilter != 'All Suppliers' &&
          item.supplierName.trim().toLowerCase() != _materialSupplierFilter.trim().toLowerCase()) {
        return false;
      }

      // 5. Search Query Filter
      if (_materialSearchQuery.trim().isEmpty) return true;
      final q = _materialSearchQuery.trim().toLowerCase();
      return item.productName.toLowerCase().contains(q) ||
          item.challanNo.toLowerCase().contains(q) ||
          item.supplierName.toLowerCase().contains(q) ||
          item.itemType.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
    }).toList();
  }

  List<MaterialItem> get filteredMaterials =>
      getFilteredMaterialsForCategory(_selectedMaterialCategory);

  List<ChallanSummary> get challanSummaries {
    final Map<String, List<MaterialItem>> grouped = {};
    for (final item in getFilteredMaterialsForCategory('Challan')) {
      final key = '${item.formattedDate}_${item.supplierName.trim().toLowerCase()}_${item.challanNo.trim().toLowerCase()}';
      grouped.putIfAbsent(key, () => []).add(item);
    }
    final summaries = grouped.entries.map((entry) {
      final items = entry.value;
      return ChallanSummary(
        challanNo: items.first.challanNo,
        date: items.first.date,
        supplierName: items.first.supplierName,
        items: items,
      );
    }).toList();
    summaries.sort((a, b) {
      final cmp = b.date.compareTo(a.date);
      if (cmp != 0) return cmp;
      return b.challanNo.compareTo(a.challanNo);
    });
    return summaries;
  }

  double get totalMaterialInvestment => _materials.fold(0.0, (sum, m) => sum + m.amount);
  double get totalMaterialBalanceValue => _materials.fold(0.0, (sum, m) => sum + m.balanceAmount);
  double get totalMaterialUsedValue => totalMaterialInvestment - totalMaterialBalanceValue;
  int get totalMaterialItemsCount => _materials.length;

  List<MaterialItem> getMaterialsForSupplier(String supplierName) {
    if (supplierName.isEmpty || supplierName == 'All' || supplierName == 'All Suppliers') {
      return _materials;
    }
    return _materials.where((m) => m.supplierName.trim().toLowerCase() == supplierName.trim().toLowerCase()).toList();
  }

  List<ChallanSummary> getChallansForSupplier(String supplierName) {
    if (supplierName.isEmpty || supplierName == 'All' || supplierName == 'All Suppliers') {
      return challanSummaries;
    }
    return challanSummaries.where((c) => c.supplierName.trim().toLowerCase() == supplierName.trim().toLowerCase()).toList();
  }

  double getSupplierTotalAmount(String supplierName) {
    return getMaterialsForSupplier(supplierName).fold(0.0, (sum, m) => sum + m.amount);
  }

  double getSupplierPaidAmount(String supplierName) {
    return getMaterialsForSupplier(supplierName).where((m) => m.isPaid).fold(0.0, (sum, m) => sum + m.amount);
  }

  double getSupplierPendingAmount(String supplierName) {
    return getMaterialsForSupplier(supplierName).where((m) => !m.isPaid).fold(0.0, (sum, m) => sum + m.amount);
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _machines = await _db.getMachines();
      _accounts = await _db.getAccounts();
      _records = await _db.getRecords();
      _materials = await _db.getMaterialItems();
      _materialProducts = await _db.getMaterialProducts();
      _suppliers = await _db.getSuppliers();
      _employees = await _db.getEmployees();
      _employeeUpads = await _db.getEmployeeUpads();
      _whatsappLogs = await _db.getWhatsAppLogs();
      _deletedRecords = await _db.getDeletedRecords();
      _archivedRecords = [];
      _settings = await _db.getSettings();

      _dashboardSelectedRecord = null;
      _entrySelectedRecord = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedShiftFilter(String shift) {
    _selectedShiftFilter = shift;
    _currentPage = 1;
    notifyListeners();
  }

  void setSelectedAccountFilter(String account) {
    _selectedAccountFilter = account;
    _currentPage = 1;
    notifyListeners();
  }

  void setActiveNavIndex(int index) {
    _activeNavIndex = index;
    notifyListeners();
  }

  void selectDashboardRecord(ProductionRecord? record) {
    if (_dashboardSelectedRecord?.id == record?.id && record != null) {
      _dashboardSelectedRecord = null;
    } else {
      _dashboardSelectedRecord = record;
    }
    notifyListeners();
  }

  void selectEntryRecord(ProductionRecord? record) {
    if (_entrySelectedRecord?.id == record?.id && record != null) {
      _entrySelectedRecord = null;
    } else {
      _entrySelectedRecord = record;
    }
    notifyListeners();
  }

  void clearEntrySelection() {
    _entrySelectedRecord = null;
    notifyListeners();
  }

  void selectRecord(ProductionRecord? record) {
    _dashboardSelectedRecord = record;
    notifyListeners();
  }

  void toggleSelectId(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void toggleSelectAll(bool selectAll) {
    _selectedIds.clear();
    if (selectAll) {
      for (final r in filteredRecords) {
        if (r.id != null) {
          _selectedIds.add(r.id!);
        }
      }
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    _currentPage = 1;
    _syncSelectedRecord();
    notifyListeners();
  }

  void setMachineFilter(String machineNo) {
    _selectedMachineFilter = machineNo;
    _currentPage = 1;
    _syncSelectedRecord();
    notifyListeners();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    if (from != null && to != null && from.isAfter(to)) {
      // Auto-correct range to prevent inverted date queries
      _fromDate = to;
      _toDate = from;
    } else {
      _fromDate = from;
      _toDate = to;
    }
    _currentPage = 1;
    _syncSelectedRecord();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedMachineFilter = 'All Machines';
    _selectedShiftFilter = 'All';
    _selectedAccountFilter = 'All Accounts';
    _fromDate = null;
    _toDate = null;
    _currentPage = 1;
    _syncSelectedRecord();
    notifyListeners();
  }

  void _syncSelectedRecord() {
    final list = filteredRecords;
    if (_dashboardSelectedRecord != null && !list.any((r) => r.id == _dashboardSelectedRecord!.id)) {
      _dashboardSelectedRecord = null;
    }
    if (_entrySelectedRecord != null && !list.any((r) => r.id == _entrySelectedRecord!.id)) {
      _entrySelectedRecord = null;
    }
  }

  void setPage(int page) {
    _currentPage = page.clamp(1, max(1, totalPages));
    notifyListeners();
  }

  void setRowsPerPage(int count) {
    _rowsPerPage = count.clamp(5, 100);
    _currentPage = 1;
    notifyListeners();
  }

  // Filtered Records List
  List<ProductionRecord> get filteredRecords {
    if (_records.isEmpty) return [];

    final list = _records.where((record) {
      // Machine filter
      if (_selectedMachineFilter != 'All Machines' &&
          record.machineNo != _selectedMachineFilter) {
        return false;
      }

      // Shift filter
      if (_selectedShiftFilter != 'All' &&
          record.shift.toLowerCase() != _selectedShiftFilter.toLowerCase()) {
        return false;
      }

      // Account filter
      if (_selectedAccountFilter != 'All Accounts' &&
          record.accountName != _selectedAccountFilter) {
        return false;
      }

      // Date filter
      if (_fromDate != null) {
        final start = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        if (record.date.isBefore(start)) return false;
      }
      if (_toDate != null) {
        final end = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
        if (record.date.isAfter(end)) return false;
      }

      // Search Query
      if (_searchQuery.isNotEmpty) {
        final matchDesign = record.designNo.toLowerCase().contains(_searchQuery);
        final matchMachine = record.machineNo.toLowerCase().contains(_searchQuery);
        final matchNotes = record.notes.toLowerCase().contains(_searchQuery);
        final matchAccount = record.accountName.toLowerCase().contains(_searchQuery);
        final matchShift = record.shift.toLowerCase().contains(_searchQuery);
        if (!matchDesign && !matchMachine && !matchNotes && !matchAccount && !matchShift) return false;
      }

      return true;
    }).toList();

    list.sort((a, b) {
      int cmp = 0;
      switch (_sortColumn) {
        case 'date':
          cmp = a.date.compareTo(b.date);
          break;
        case 'category':
          cmp = a.accountName.toLowerCase().compareTo(b.accountName.toLowerCase());
          break;
        case 'designNo':
          cmp = a.designNo.toLowerCase().compareTo(b.designNo.toLowerCase());
          break;
        case 'machineNo':
          cmp = a.machineNo.toLowerCase().compareTo(b.machineNo.toLowerCase());
          break;
        case 'totalStitch':
          cmp = a.totalStitch.compareTo(b.totalStitch);
          break;
        case 'finalStitch':
          cmp = a.finalStitch.compareTo(b.finalStitch);
          break;
        case 'rate':
          cmp = a.rate.compareTo(b.rate);
          break;
        case 'amount':
          cmp = a.amount.compareTo(b.amount);
          break;
        case 'finalAmount':
          cmp = a.finalAmount.compareTo(b.finalAmount);
          break;
        default:
          cmp = a.date.compareTo(b.date);
      }
      if (cmp == 0) {
        cmp = (a.id ?? 0).compareTo(b.id ?? 0);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  // Paginated records with strict bounds safety
  List<ProductionRecord> get paginatedRecords {
    final list = filteredRecords;
    if (list.isEmpty) return [];

    if (_rowsPerPage <= 0) {
      return list; // "Show All" selected
    }

    final validPage = _currentPage.clamp(1, max(1, totalPages)).toInt();
    final startIndex = (validPage - 1) * _rowsPerPage;
    if (startIndex >= list.length) {
      return [];
    }
    final endIndex = (startIndex + _rowsPerPage).clamp(0, list.length).toInt();
    return list.sublist(startIndex, endIndex);
  }

  int get totalPages {
    final count = filteredRecords.length;
    if (count == 0) return 1;
    if (_rowsPerPage <= 0) return 1; // "Show All" has 1 page
    return (count / _rowsPerPage).ceil();
  }

  // Summary Metrics
  int get totalEntriesCount => _records.length;

  int get grandTotalStitch {
    return _records.fold(0, (sum, r) => sum + r.totalStitch);
  }

  double get grandTotalAmount {
    return _records.fold(0.0, (sum, r) => sum + r.amount);
  }

  double get grandFinalAmount {
    return _records.fold(0.0, (sum, r) => sum + r.finalAmount);
  }

  // Filtered Summary Metrics
  int get filteredTotalStitch {
    return filteredRecords.fold(0, (sum, r) => sum + r.totalStitch);
  }

  double get filteredTotalAmount {
    return filteredRecords.fold(0.0, (sum, r) => sum + r.amount);
  }

  double get filteredFinalAmount {
    return filteredRecords.fold(0.0, (sum, r) => sum + r.finalAmount);
  }

  // Machine-wise Totals Breakdown
  List<MachineSummary> get machineSummaries {
    final Map<String, List<ProductionRecord>> grouped = {};

    for (final machine in _machines) {
      grouped[machine.machineNo] = [];
    }

    for (final record in filteredRecords) {
      grouped.putIfAbsent(record.machineNo, () => []).add(record);
    }

    final List<MachineSummary> list = [];
    final sortedKeys = grouped.keys.toList()..sort();

    for (final machineNo in sortedKeys) {
      final entries = grouped[machineNo]!;
      final totalStitch = entries.fold(0, (sum, r) => sum + r.totalStitch);
      final totalAmount = entries.fold(0.0, (sum, r) => sum + r.amount);
      final finalAmount = entries.fold(0.0, (sum, r) => sum + r.finalAmount);

      list.add(MachineSummary(
        machineNo: machineNo,
        totalEntries: entries.length,
        totalStitch: totalStitch,
        totalAmount: totalAmount,
        finalAmount: finalAmount,
      ));
    }

    return list;
  }

  // Daily Chart Stats (e.g. for last 7 distinct production dates)
  List<DailyChartStat> get chartStats {
    if (_records.isEmpty) return [];

    final Map<String, List<ProductionRecord>> byDate = {};
    for (final r in _records) {
      final key = DateFormat('yyyy-MM-dd').format(r.date);
      byDate.putIfAbsent(key, () => []).add(r);
    }

    final sortedDates = byDate.keys.toList()..sort();
    // Take recent 7 dates
    final recentKeys = sortedDates.length > 7
        ? sortedDates.sublist(sortedDates.length - 7)
        : sortedDates;

    return recentKeys.map((k) {
      final items = byDate[k]!;
      final date = DateTime.parse(k);
      final tAmount = items.fold(0.0, (s, r) => s + r.amount);
      final fAmount = items.fold(0.0, (s, r) => s + r.finalAmount);
      return DailyChartStat(
        dateLabel: DateFormat('dd MMM').format(date),
        date: date,
        totalAmount: tAmount,
        finalAmount: fAmount,
      );
    }).toList();
  }

  // Trend Analysis Engine (+ / - Day to Day, Weekly, Monthly, Yearly, with Account Filter)
  TrendSummary getTrendSummary(TrendPeriod period, [String? accountName]) {
    final effectiveRecords = (accountName != null && accountName != 'All' && accountName.isNotEmpty)
        ? _records.where((r) => r.accountName == accountName).toList()
        : _records;

    if (effectiveRecords.isEmpty) {
      return TrendSummary(
        period: period,
        currentAmount: 0.0,
        previousAmount: 0.0,
        diffAmount: 0.0,
        percentDiff: 0.0,
        isPositive: true,
        totalStitch: 0,
        entryCount: 0,
        points: const [],
      );
    }

    final Map<String, List<ProductionRecord>> groups = {};
    final Map<String, DateTime> groupDate = {};

    for (final r in effectiveRecords) {
      String key;
      DateTime dKey;
      switch (period) {
        case TrendPeriod.day:
          key = DateFormat('yyyy-MM-dd').format(r.date);
          dKey = DateTime(r.date.year, r.date.month, r.date.day);
          break;
        case TrendPeriod.week:
          // Week starting Monday
          final monday = r.date.subtract(Duration(days: r.date.weekday - 1));
          key = DateFormat('yyyy-MM-dd').format(monday);
          dKey = DateTime(monday.year, monday.month, monday.day);
          break;
        case TrendPeriod.month:
          key = DateFormat('yyyy-MM').format(r.date);
          dKey = DateTime(r.date.year, r.date.month, 1);
          break;
        case TrendPeriod.year:
          key = DateFormat('yyyy').format(r.date);
          dKey = DateTime(r.date.year, 1, 1);
          break;
      }
      groups.putIfAbsent(key, () => []).add(r);
      groupDate[key] = dKey;
    }

    final sortedKeys = groups.keys.toList()..sort();
    final int maxPoints = switch (period) {
      TrendPeriod.day => 10,
      TrendPeriod.week => 8,
      TrendPeriod.month => 12,
      TrendPeriod.year => 5,
    };

    final displayKeys = sortedKeys.length > maxPoints
        ? sortedKeys.sublist(sortedKeys.length - maxPoints)
        : sortedKeys;

    final List<TrendDataPoint> points = [];
    double prevAmount = 0.0;

    for (int i = 0; i < displayKeys.length; i++) {
      final k = displayKeys[i];
      final items = groups[k]!;
      final d = groupDate[k]!;
      final amount = items.fold(0.0, (s, r) => s + r.finalAmount);
      final totalStitch = items.fold(0, (s, r) => s + r.totalStitch);
      final rawAmount = items.fold(0.0, (s, r) => s + r.amount);

      String label;
      switch (period) {
        case TrendPeriod.day:
          label = DateFormat('dd MMM').format(d);
          break;
        case TrendPeriod.week:
          label = 'Wk ${DateFormat('ww').format(d)}';
          break;
        case TrendPeriod.month:
          label = DateFormat('MMM yy').format(d);
          break;
        case TrendPeriod.year:
          label = DateFormat('yyyy').format(d);
          break;
      }

      final changeAmount = i > 0 ? (amount - prevAmount) : 0.0;
      final percentChange = (i > 0 && prevAmount > 0)
          ? ((changeAmount / prevAmount) * 100)
          : 0.0;
      final isPos = i == 0 || changeAmount >= 0;

      points.add(TrendDataPoint(
        label: label,
        date: d,
        amount: rawAmount,
        finalAmount: amount,
        totalStitch: totalStitch,
        entryCount: items.length,
        changeAmount: changeAmount,
        percentChange: percentChange,
        isPositive: isPos,
      ));

      prevAmount = amount;
    }

    final totalStitch = effectiveRecords.fold(0, (s, r) => s + r.totalStitch);
    final currentAmount = points.isNotEmpty ? points.last.finalAmount : 0.0;
    final previousAmount = points.length >= 2 ? points[points.length - 2].finalAmount : 0.0;
    final diffAmount = points.length >= 2 ? (currentAmount - previousAmount) : 0.0;
    final percentDiff = (previousAmount > 0) ? ((diffAmount / previousAmount) * 100) : 0.0;
    final isPositive = points.length >= 2 ? (diffAmount >= 0) : true;

    return TrendSummary(
      period: period,
      currentAmount: currentAmount,
      previousAmount: previousAmount,
      diffAmount: diffAmount,
      percentDiff: percentDiff,
      isPositive: isPositive,
      totalStitch: totalStitch,
      entryCount: effectiveRecords.length,
      points: points,
    );
  }

  // Live Auto-Refresh
  Future<void> refreshData({bool silent = true}) async {
    try {
      final newRecords = await _db.getRecords();
      final newMachines = await _db.getMachines();
      final newAccounts = await _db.getAccounts();
      final newSettings = await _db.getSettings();
      _records = newRecords;
      _machines = newMachines;
      _accounts = newAccounts;
      _settings = newSettings;
      _syncSelectedRecord();
      notifyListeners();
    } catch (e) {
      if (!silent) {
        _errorMessage = 'Refresh failed: $e';
        notifyListeners();
      }
    }
  }

  // Strict Validation Helpers
  static String? validateTotalStitch(String? val, {bool allowZero = false}) {
    if (val == null || val.trim().isEmpty) {
      return 'Total stitch count is required';
    }
    final cleaned = val.replaceAll(',', '').trim();
    final n = int.tryParse(cleaned);
    if (n == null) {
      return 'Enter a valid number (e.g. 300000)';
    }
    if (allowZero) {
      if (n < 0) {
        return 'Stitch count cannot be negative';
      }
    } else {
      if (n <= 0) {
        return 'Stitch count must be greater than zero';
      }
    }
    if (n > 50000000) {
      return 'Stitch count exceeds realistic limit (max 50,000,000)';
    }
    return null;
  }

  static String? validateRate(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Rate is required';
    }
    final cleaned = val.replaceAll(',', '').trim();
    final r = double.tryParse(cleaned);
    if (r == null) {
      return 'Enter a valid rate (e.g. 1.25)';
    }
    if (r <= 0) {
      return 'Rate must be positive';
    }
    if (r > 1000) {
      return 'Rate exceeds standard maximum limit';
    }
    return null;
  }

  static String? validateHeads(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Head count is required';
    }
    final cleaned = val.trim();
    final h = int.tryParse(cleaned);
    if (h == null) {
      return 'Enter valid integer (e.g. 12)';
    }
    if (h <= 0) {
      return 'Heads must be at least 1';
    }
    if (h > 100) {
      return 'Heads count cannot exceed 100';
    }
    return null;
  }

  static String? validateDesignNo(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Design number / code is required';
    }
    if (val.trim().length > 80) {
      return 'Design code too long (max 80 chars)';
    }
    return null;
  }

  // CRUD Operations - Records
  Future<void> addRecord({
    required DateTime date,
    DateTime? createdAt,
    required String designNo,
    required String machineNo,
    required int totalStitch,
    required double rate,
    required int heads,
    String notes = '',
    String accountName = '250 Area',
    String shift = 'Day',
  }) async {
    final calc = CalculationEngine.calculate(
      totalStitch: totalStitch,
      rate: rate,
      heads: heads,
      stitchDivider: _settings.stitchDivider,
    );

    final record = ProductionRecord(
      date: date,
      createdAt: createdAt ?? DateTime.now(),
      designNo: designNo.trim().toUpperCase(),
      machineNo: machineNo.trim(),
      totalStitch: totalStitch,
      finalStitch: calc.finalStitch,
      rate: rate,
      amount: calc.amount,
      heads: heads,
      finalAmount: calc.finalAmount,
      notes: notes.trim(),
      accountName: accountName,
      shift: shift,
    );

    final id = await _db.insertRecord(record);
    final savedRecord = record.copyWith(id: id);
    _records.insert(0, savedRecord);
    _dashboardSelectedRecord = savedRecord;
    _entrySelectedRecord = savedRecord;
    notifyListeners();
  }

  Future<void> addBatchRecords(List<ProductionRecord> records) async {
    if (records.isEmpty) return;
    await _db.insertRecordsBatch(records);
    // Reload records from db
    await refreshData(silent: true);
    if (records.isNotEmpty) {
      _dashboardSelectedRecord = _records.isNotEmpty ? _records.first : null;
      _entrySelectedRecord = _records.isNotEmpty ? _records.first : null;
    }
    notifyListeners();
  }

  Future<void> updateRecord({
    required int id,
    required DateTime date,
    DateTime? createdAt,
    required String designNo,
    required String machineNo,
    required int totalStitch,
    required double rate,
    required int heads,
    String notes = '',
    String accountName = '250 Area',
    String shift = 'Day',
  }) async {
    final existing = _records.where((r) => r.id == id).firstOrNull;
    final calc = CalculationEngine.calculate(
      totalStitch: totalStitch,
      rate: rate,
      heads: heads,
      stitchDivider: _settings.stitchDivider,
    );

    final record = ProductionRecord(
      id: id,
      date: date,
      createdAt: createdAt ?? existing?.createdAt ?? DateTime.now(),
      designNo: designNo.trim().toUpperCase(),
      machineNo: machineNo.trim(),
      totalStitch: totalStitch,
      finalStitch: calc.finalStitch,
      rate: rate,
      amount: calc.amount,
      heads: heads,
      finalAmount: calc.finalAmount,
      notes: notes.trim(),
      accountName: accountName,
      shift: shift,
    );

    await _db.updateRecord(record);
    final index = _records.indexWhere((r) => r.id == id);
    if (index != -1) {
      _records[index] = record;
      if (_dashboardSelectedRecord?.id == id) {
        _dashboardSelectedRecord = record;
      }
      if (_entrySelectedRecord?.id == id) {
        _entrySelectedRecord = record;
      }
      notifyListeners();
    }
  }

  Future<void> updateRecordDirect(ProductionRecord record) async {
    if (record.id == null) return;

    final calc = CalculationEngine.calculate(
      totalStitch: record.totalStitch,
      rate: record.rate,
      heads: record.heads,
      stitchDivider: _settings.stitchDivider,
    );

    final updated = record.copyWith(
      finalStitch: calc.finalStitch,
      amount: calc.amount,
      finalAmount: calc.finalAmount,
    );

    await _db.updateRecord(updated);
    final index = _records.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _records[index] = updated;
      if (_dashboardSelectedRecord?.id == updated.id) {
        _dashboardSelectedRecord = updated;
      }
      if (_entrySelectedRecord?.id == updated.id) {
        _entrySelectedRecord = updated;
      }
      notifyListeners();
    }
  }

  Future<void> deleteRecord(int id) async {
    final toDelete = _records.where((r) => r.id == id).toList();
    if (toDelete.isNotEmpty) {
      final rec = toDelete.first;
      await _db.insertDeletedRecord(DeletedRecordItem(
        recordType: 'production_record',
        recordTitle: 'Design: ${rec.designNo} (${rec.machineNo})',
        recordSubtitle: 'Date: ${DateFormat('dd-MM-yyyy').format(rec.date)} | Shift: ${rec.shift} | Khata: ${rec.accountName} | ₹${rec.finalAmount.toStringAsFixed(2)} | Stitches: ${rec.totalStitch}',
        originalId: rec.id,
        originalData: jsonEncode(rec.toMap()),
        deletedAt: DateTime.now(),
      ));
    }

    await _db.deleteRecord(id);
    _records.removeWhere((r) => r.id == id);
    _selectedIds.remove(id);
    if (_dashboardSelectedRecord?.id == id) {
      _dashboardSelectedRecord = null;
    }
    if (_entrySelectedRecord?.id == id) {
      _entrySelectedRecord = null;
    }
    _deletedRecords = await _db.getDeletedRecords();
    notifyListeners();
  }

  Future<void> deleteSelectedRecords() async {
    if (_selectedIds.isEmpty) return;
    final toDelete = _records.where((r) => r.id != null && _selectedIds.contains(r.id!)).toList();
    for (final rec in toDelete) {
      await _db.insertDeletedRecord(DeletedRecordItem(
        recordType: 'production_record',
        recordTitle: 'Design: ${rec.designNo} (${rec.machineNo})',
        recordSubtitle: 'Date: ${DateFormat('dd-MM-yyyy').format(rec.date)} | Shift: ${rec.shift} | Khata: ${rec.accountName} | ₹${rec.finalAmount.toStringAsFixed(2)} | Stitches: ${rec.totalStitch}',
        originalId: rec.id,
        originalData: jsonEncode(rec.toMap()),
        deletedAt: DateTime.now(),
      ));
    }

    await _db.deleteRecordsBatch(_selectedIds.toList());
    _records.removeWhere((r) => r.id != null && _selectedIds.contains(r.id!));
    if (_dashboardSelectedRecord != null && _selectedIds.contains(_dashboardSelectedRecord!.id)) {
      _dashboardSelectedRecord = null;
    }
    if (_entrySelectedRecord != null && _selectedIds.contains(_entrySelectedRecord!.id)) {
      _entrySelectedRecord = null;
    }
    _selectedIds.clear();
    _deletedRecords = await _db.getDeletedRecords();
    notifyListeners();
  }

  // CRUD Operations - Machines
  Future<void> addMachine(MachineModel machine) async {
    final id = await _db.insertMachine(machine);
    _machines.add(machine.copyWith(id: id));
    _machines.sort((a, b) => a.machineNo.compareTo(b.machineNo));
    notifyListeners();
  }

  Future<void> updateMachine(MachineModel machine) async {
    await _db.updateMachine(machine);
    final index = _machines.indexWhere((m) => m.id == machine.id);
    if (index != -1) {
      _machines[index] = machine;
      _machines.sort((a, b) => a.machineNo.compareTo(b.machineNo));
      notifyListeners();
    }
  }

  Future<void> deleteMachine(int id) async {
    final toDelete = _machines.where((m) => m.id == id).toList();
    if (toDelete.isNotEmpty) {
      final m = toDelete.first;
      await _db.insertDeletedRecord(DeletedRecordItem(
        recordType: 'machine',
        recordTitle: 'Machine: ${m.machineNo} - ${m.name}',
        recordSubtitle: 'Head Capacity: ${m.headCapacity} Heads | Notes: ${m.notes.isEmpty ? "None" : m.notes}',
        originalId: m.id,
        originalData: jsonEncode(m.toMap()),
        deletedAt: DateTime.now(),
      ));
    }

    await _db.deleteMachine(id);
    _machines.removeWhere((m) => m.id == id);
    _deletedRecords = await _db.getDeletedRecords();
    notifyListeners();
  }

  // Rates & Heads Presets
  void addPresetRate(double rate) {
    if (rate <= 0 || _settings.availableRates.contains(rate)) return;
    final updated = List<double>.from(_settings.availableRates)..add(rate)..sort();
    saveSettings(_settings.copyWith(availableRates: updated));
  }

  void removePresetRate(double rate) {
    if (_settings.availableRates.length <= 1) return;
    final updated = List<double>.from(_settings.availableRates)..remove(rate);
    double newDefault = _settings.defaultRate;
    if (!_settings.availableRates.contains(newDefault)) {
      newDefault = updated.first;
    }
    saveSettings(_settings.copyWith(availableRates: updated, defaultRate: newDefault));
  }

  void addPresetHead(int heads) {
    if (heads <= 0 || _settings.availableHeads.contains(heads)) return;
    final updated = List<int>.from(_settings.availableHeads)..add(heads)..sort();
    saveSettings(_settings.copyWith(availableHeads: updated));
  }

  void removePresetHead(int heads) {
    if (_settings.availableHeads.length <= 1) return;
    final updated = List<int>.from(_settings.availableHeads)..remove(heads);
    int newDefault = _settings.defaultHeads;
    if (!_settings.availableHeads.contains(newDefault)) {
      newDefault = updated.first;
    }
    saveSettings(_settings.copyWith(availableHeads: updated, defaultHeads: newDefault));
  }

  // Settings
  Future<void> saveSettings(SettingsModel newSettings) async {
    _settings = newSettings;
    await _db.saveSettings(newSettings);
    notifyListeners();
  }

  Future<void> updateSettings(SettingsModel newSettings) => saveSettings(newSettings);

  Future<void> toggleDarkMode([bool? value]) async {
    final next = value ?? !_settings.isDarkMode;
    await saveSettings(_settings.copyWith(isDarkMode: next));
  }

  Future<void> setThemeColorHex(String hex) async {
    final cleanHex = hex.trim();
    if (cleanHex.isEmpty) return;
    await saveSettings(_settings.copyWith(themeColorHex: cleanHex));
  }

  Future<void> setAppLanguage(String langCode) async {
    final clean = langCode.trim();
    if (clean.isEmpty) return;
    await saveSettings(_settings.copyWith(appLanguage: clean));
  }

  Future<void> setFontScale(double scale) async {
    final clamped = scale.clamp(0.85, 1.30);
    await saveSettings(_settings.copyWith(fontScale: clamped));
  }

  // Database Backup / Reset
  Future<String> exportBackupJson() async {
    return await _db.exportBackupJson();
  }

  Future<bool> isDatabaseEmpty() async {
    return await _db.isDatabaseEmpty();
  }

  Future<void> restoreFromJson(String jsonString, {bool merge = false}) async {
    await _db.restoreFromJson(jsonString, merge: merge);
    await init();
    // Reset filters to ensure restored records are immediately displayed on all screens
    _selectedAccountFilter = 'All Accounts';
    _selectedMachineFilter = 'All Machines';
    _selectedShiftFilter = 'All Shifts';
    _searchQuery = '';
    _currentPage = 1;
    _materialSearchQuery = '';
    _materialDateFilter = 'All Time';
    _materialProductFilter = 'All Products';
    _materialSupplierFilter = 'All Suppliers';
    notifyListeners();
  }

  Future<void> resetToSampleData() async {
    await _db.resetToSampleData();
    await init();
  }

  // --- Account CRUD & Reordering Operations ---
  Future<void> addAccount(AccountModel account) async {
    final nextOrder = _accounts.isEmpty ? 1 : (_accounts.map((a) => a.displayOrder).fold<int>(0, max) + 1);
    final toAdd = account.copyWith(displayOrder: account.displayOrder > 0 ? account.displayOrder : nextOrder);
    await _db.insertAccount(toAdd);
    _accounts = await _db.getAccounts();
    notifyListeners();
  }

  Future<void> updateAccount(AccountModel account) async {
    await _db.updateAccount(account);
    _accounts = await _db.getAccounts();
    notifyListeners();
  }

  Future<void> deleteAccount(int id) async {
    final toDelete = _accounts.where((a) => a.id == id).toList();
    if (toDelete.isNotEmpty) {
      final a = toDelete.first;
      await _db.insertDeletedRecord(DeletedRecordItem(
        recordType: 'account',
        recordTitle: 'Account: ${a.name} (${a.area})',
        recordSubtitle: 'Order: ${a.displayOrder} | Color: ${a.colorHex} | Notes: ${a.notes.isEmpty ? "None" : a.notes}',
        originalId: a.id,
        originalData: jsonEncode(a.toMap()),
        deletedAt: DateTime.now(),
      ));
    }

    await _db.deleteAccount(id);
    _accounts = await _db.getAccounts();
    _deletedRecords = await _db.getDeletedRecords();
    notifyListeners();
  }

  Future<void> moveAccountOrder(int accountId, bool moveUp) async {
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index == -1) return;
    if (moveUp && index > 0) {
      final temp = _accounts[index];
      _accounts[index] = _accounts[index - 1];
      _accounts[index - 1] = temp;
    } else if (!moveUp && index < _accounts.length - 1) {
      final temp = _accounts[index];
      _accounts[index] = _accounts[index + 1];
      _accounts[index + 1] = temp;
    } else {
      return;
    }
    await _db.updateAccountOrders(_accounts);
    _accounts = await _db.getAccounts();
    notifyListeners();
  }

  Future<void> setAccountOrder(int accountId, int newOrder) async {
    final account = _accounts.firstWhere((a) => a.id == accountId, orElse: () => _accounts.first);
    if (account.id == null) return;
    final updated = account.copyWith(displayOrder: newOrder);
    await _db.updateAccount(updated);
    _accounts = await _db.getAccounts();
    notifyListeners();
  }

  AccountSummary getAccountSummary(String accountName) {
    final recs = _records.where((r) => r.accountName == accountName).toList();
    final totalEntries = recs.length;
    final totalStitch = recs.fold<int>(0, (s, r) => s + r.totalStitch);
    final totalAmount = recs.fold<double>(0.0, (s, r) => s + r.amount);
    final finalAmount = recs.fold<double>(0.0, (s, r) => s + r.finalAmount);
    final dayEntries = recs.where((r) => r.shift.toLowerCase() == 'day').length;
    final nightEntries = recs.where((r) => r.shift.toLowerCase() == 'night').length;
    final dayStitch = recs.where((r) => r.shift.toLowerCase() == 'day').fold<int>(0, (s, r) => s + r.totalStitch);
    final nightStitch = recs.where((r) => r.shift.toLowerCase() == 'night').fold<int>(0, (s, r) => s + r.totalStitch);
    final dayAmount = recs.where((r) => r.shift.toLowerCase() == 'day').fold<double>(0.0, (s, r) => s + r.finalAmount);
    final nightAmount = recs.where((r) => r.shift.toLowerCase() == 'night').fold<double>(0.0, (s, r) => s + r.finalAmount);

    return AccountSummary(
      accountName: accountName,
      totalEntries: totalEntries,
      totalStitch: totalStitch,
      totalAmount: totalAmount,
      finalAmount: finalAmount,
      dayEntries: dayEntries,
      nightEntries: nightEntries,
      dayStitch: dayStitch,
      nightStitch: nightStitch,
      dayAmount: dayAmount,
      nightAmount: nightAmount,
    );
  }

  List<ProductionRecord> getRecordsForAccount(
    String accountName, {
    String? shiftFilter,
    String? searchQuery,
    DateTime? from,
    DateTime? to,
  }) {
    var list = _records.where((r) => r.accountName == accountName).toList();
    if (shiftFilter != null && shiftFilter != 'All') {
      list = list.where((r) => r.shift.toLowerCase() == shiftFilter.toLowerCase()).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((r) =>
        r.designNo.toLowerCase().contains(q) ||
        r.machineNo.toLowerCase().contains(q) ||
        r.notes.toLowerCase().contains(q),
      ).toList();
    }
    if (from != null && to != null) {
      final start = DateTime(from.year, from.month, from.day);
      final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
      list = list.where((r) => !r.date.isBefore(start) && !r.date.isAfter(end)).toList();
    }
    return list;
  }

  // --- Material & Stock Actions (Daga, Sequence, Beads) ---
  Future<void> loadMaterials() async {
    _materials = await _db.getMaterialItems();
    notifyListeners();
  }

  void setSelectedMaterialCategory(String category) {
    _selectedMaterialCategory = category;
    notifyListeners();
  }

  void setMaterialSearchQuery(String query) {
    _materialSearchQuery = query;
    notifyListeners();
  }

  Future<void> insertMaterialItem(MaterialItem item) async {
    await _db.insertMaterialItem(item);
    await loadMaterials();
  }

  Future<void> insertMaterialItems(List<MaterialItem> items) async {
    if (items.isEmpty) return;
    await _db.insertMaterialItems(items);
    await loadMaterials();
  }

  Future<void> updateMaterialItem(MaterialItem item) async {
    await _db.updateMaterialItem(item);
    await loadMaterials();
  }

  Future<void> deleteMaterialItem(int id) async {
    final toDelete = _materials.where((m) => m.id == id).toList();
    if (toDelete.isNotEmpty) {
      final item = toDelete.first;
      await _db.insertDeletedRecord(DeletedRecordItem(
        recordType: 'material_item',
        recordTitle: '${item.productName} (${item.category}) - Challan #${item.challanNo.isEmpty ? "N/A" : item.challanNo}',
        recordSubtitle: 'Supplier: ${item.supplierName} | Date: ${DateFormat('dd-MM-yyyy').format(item.date)} | Qty: ${item.qty} ${item.itemType} | Rate: ₹${item.rate} | Amount: ₹${item.amount.toStringAsFixed(2)}',
        originalId: item.id,
        originalData: jsonEncode(item.toMap()),
        deletedAt: DateTime.now(),
      ));
    }
    await _db.deleteMaterialItem(id);
    _deletedRecords = await _db.getDeletedRecords();
    await loadMaterials();
  }

  Future<void> recordMaterialUsage(int id, double addedUsedQty) async {
    await _db.recordMaterialUsage(id, addedUsedQty);
    await loadMaterials();
  }

  Future<void> updateMaterialItemPaymentStatus(int id, String status, [DateTime? paymentDate]) async {
    await _db.updateMaterialItemPaymentStatus(id, status, paymentDate);
    await loadMaterials();
  }

  Future<void> updateChallanPaymentStatus(String challanNo, String supplierName, String status, [DateTime? paymentDate]) async {
    await _db.updateChallanPaymentStatus(challanNo, supplierName, status, paymentDate);
    await loadMaterials();
  }

  Future<void> updateSupplierAllPaymentStatus(String supplierName, String status, [DateTime? paymentDate]) async {
    await _db.updateSupplierAllPaymentStatus(supplierName, status, paymentDate);
    await loadMaterials();
  }

  // --- Material Product Master Actions ---
  Future<void> loadMaterialProducts() async {
    _materialProducts = await _db.getMaterialProducts();
    notifyListeners();
  }

  Future<void> insertMaterialProduct(MaterialProduct product) async {
    await _db.insertMaterialProduct(product);
    await loadMaterialProducts();
  }

  Future<void> updateMaterialProduct(MaterialProduct product) async {
    await _db.updateMaterialProduct(product);
    await loadMaterialProducts();
  }

  Future<void> deleteMaterialProduct(int id) async {
    final toDelete = _materialProducts.where((p) => p.id == id).toList();
    if (toDelete.isNotEmpty) {
      final p = toDelete.first;
      await _db.insertDeletedRecord(DeletedRecordItem(
        recordType: 'material_product',
        recordTitle: 'Product Master: ${p.name} (${p.category})',
        recordSubtitle: 'Default Rate: ₹${p.defaultRate} / ${p.unit} | MTR: ${p.defaultMtr} | MM: ${p.defaultMm}',
        originalId: p.id,
        originalData: jsonEncode(p.toMap()),
        deletedAt: DateTime.now(),
      ));
    }
    await _db.deleteMaterialProduct(id);
    _deletedRecords = await _db.getDeletedRecords();
    await loadMaterialProducts();
  }

  // --- Supplier Master Actions ---
  Future<void> loadSuppliers() async {
    _suppliers = await _db.getSuppliers();
    notifyListeners();
  }

  Future<void> insertSupplier(Supplier supplier) async {
    await _db.insertSupplier(supplier);
    await loadSuppliers();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await _db.updateSupplier(supplier);
    await loadSuppliers();
  }

  Future<void> deleteSupplier(int id) async {
    final toDelete = _suppliers.where((s) => s.id == id).toList();
    if (toDelete.isNotEmpty) {
      final s = toDelete.first;
      await _db.insertDeletedRecord(DeletedRecordItem(
        recordType: 'supplier',
        recordTitle: 'Supplier: ${s.name}',
        recordSubtitle: s.phone.isNotEmpty ? 'Phone: ${s.phone}' : 'Supplier Master',
        originalId: s.id,
        originalData: jsonEncode(s.toMap()),
        deletedAt: DateTime.now(),
      ));
    }
    await _db.deleteSupplier(id);
    _deletedRecords = await _db.getDeletedRecords();
    await loadSuppliers();
  }

  // --- Recycle Bin Actions ---
  Future<void> loadDeletedRecords() async {
    _deletedRecords = await _db.getDeletedRecords();
    _archivedRecords = [];
    notifyListeners();
  }

  Future<bool> restoreDeletedRecord(int deletedRecordId) async {
    final success = await _db.restoreDeletedRecord(deletedRecordId);
    if (success) {
      await init();
    }
    return success;
  }

  Future<int> restoreAllDeletedRecords() async {
    final count = await _db.restoreAllDeletedRecords();
    if (count > 0) {
      await init();
    }
    return count;
  }

  /// True permanent delete - record is wiped from database and nowhere stored
  Future<void> permanentlyDeleteRecord(int deletedRecordId) async {
    await _db.deleteDeletedRecord(deletedRecordId);
    await loadDeletedRecords();
  }

  /// True permanent empty - all recycle bin records wiped from database
  Future<void> emptyRecycleBin() async {
    await _db.clearAllDeletedRecords();
    await loadDeletedRecords();
  }

  Future<void> clearAllDummyData() async {
    await _db.purgeAllDummyData();
    await init();
  }

  void setMaterialDateFilter(String filter, [DateTimeRange? customRange]) {
    _materialDateFilter = filter;
    _materialCustomDateRange = customRange;
    notifyListeners();
  }

  void setMaterialProductFilter(String product) {
    _materialProductFilter = product;
    notifyListeners();
  }

  void setMaterialSupplierFilter(String supplier) {
    _materialSupplierFilter = supplier;
    notifyListeners();
  }

  void resetMaterialFilters() {
    _materialSearchQuery = '';
    _materialDateFilter = 'All Time';
    _materialCustomDateRange = null;
    _materialProductFilter = 'All Products';
    _materialSupplierFilter = 'All Suppliers';
    notifyListeners();
  }

  // --- Multi-Filter Analytics & Chart Query ---
  List<ProductionRecord> getFilteredAnalyticsRecords({
    String? accountName,
    String? machineNo,
    DateTime? startDate,
    DateTime? endDate,
    String? shift,
    String? searchQuery,
  }) {
    return _records.where((r) {
      if (accountName != null &&
          accountName.isNotEmpty &&
          accountName != 'All' &&
          accountName != 'All Accounts') {
        if (r.accountName != accountName) return false;
      }
      if (machineNo != null &&
          machineNo.isNotEmpty &&
          machineNo != 'All' &&
          machineNo != 'All Machines') {
        if (r.machineNo != machineNo) return false;
      }
      if (shift != null &&
          shift.isNotEmpty &&
          shift != 'All' &&
          shift != 'All Shifts') {
        if (r.shift.toLowerCase() != shift.toLowerCase()) return false;
      }
      if (startDate != null) {
        final rDate = DateTime(r.date.year, r.date.month, r.date.day);
        final sDate = DateTime(startDate.year, startDate.month, startDate.day);
        if (rDate.isBefore(sDate)) return false;
      }
      if (endDate != null) {
        final rDate = DateTime(r.date.year, r.date.month, r.date.day);
        final eDate = DateTime(endDate.year, endDate.month, endDate.day);
        if (rDate.isAfter(eDate)) return false;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matches = r.designNo.toLowerCase().contains(q) ||
            r.machineNo.toLowerCase().contains(q) ||
            r.accountName.toLowerCase().contains(q) ||
            r.notes.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  // --- Employee & Upad Actions ---
  Future<void> loadEmployees() async {
    _employees = await _db.getEmployees();
    notifyListeners();
  }

  Future<void> loadEmployeeUpads() async {
    _employeeUpads = await _db.getEmployeeUpads();
    notifyListeners();
  }

  Future<void> addEmployee(EmployeeModel employee) async {
    await _db.insertEmployee(employee);
    await loadEmployees();
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    await _db.updateEmployee(employee);
    await loadEmployees();
  }

  Future<void> deleteEmployee(int id) async {
    final toDelete = _employees.where((e) => e.id == id).toList();
    if (toDelete.isNotEmpty) {
      final emp = toDelete.first;
      await _db.insertDeletedRecord(DeletedRecordItem(
        recordType: 'employee',
        recordTitle: 'Employee: ${emp.name} (${emp.role})',
        recordSubtitle: 'Phone: ${emp.phone.isEmpty ? "None" : emp.phone} | Monthly Salary: ₹${emp.monthlySalary.toStringAsFixed(0)}',
        originalId: emp.id,
        originalData: jsonEncode(emp.toMap()),
        deletedAt: DateTime.now(),
      ));
    }
    await _db.deleteEmployee(id);
    _deletedRecords = await _db.getDeletedRecords();
    await loadEmployees();
    await loadEmployeeUpads();
  }

  Future<void> addEmployeeUpad(EmployeeUpadModel upad) async {
    await _db.insertEmployeeUpad(upad);
    await loadEmployeeUpads();
  }

  Future<void> updateEmployeeUpad(EmployeeUpadModel upad) async {
    await _db.updateEmployeeUpad(upad);
    await loadEmployeeUpads();
  }

  Future<void> deleteEmployeeUpad(int id) async {
    final toDelete = _employeeUpads.where((u) => u.id == id).toList();
    if (toDelete.isNotEmpty) {
      final u = toDelete.first;
      await _db.insertDeletedRecord(DeletedRecordItem(
        recordType: 'employee_upad',
        recordTitle: 'Upad: ₹${u.amount.toStringAsFixed(0)} - ${u.employeeName}',
        recordSubtitle: 'Date: ${DateFormat('dd/MM/yyyy').format(u.date)} | Notes: ${u.notes.isEmpty ? "None" : u.notes}',
        originalId: u.id,
        originalData: jsonEncode(u.toMap()),
        deletedAt: DateTime.now(),
      ));
    }
    await _db.deleteEmployeeUpad(id);
    _deletedRecords = await _db.getDeletedRecords();
    await loadEmployeeUpads();
  }

  Future<void> settleEmployeeUpads(int employeeId) async {
    final emp = _employees.cast<EmployeeModel?>().firstWhere((e) => e?.id == employeeId, orElse: () => null);
    double carryForward = 0.0;
    if (emp != null) {
      final totalPending = getEmployeeTotalUpad(employeeId, unsettledOnly: true);
      if (totalPending > emp.monthlySalary) {
        carryForward = totalPending - emp.monthlySalary;
      }
    }
    final lang = _settings.appLanguage;
    final notes = AppStrings.t(
      lang,
      en: 'Previous Month Excess Advance Carry-Forward',
      gu: 'ગત માસનો વધારાનો બાકી ઉપાડ',
      hi: 'पिछले माह का अतिरिक्त बकाया अग्रिम',
    );
    await _db.settleEmployeeUpads(
      employeeId,
      carryForwardAmount: carryForward > 0 ? carryForward : null,
      carryForwardNotes: carryForward > 0 ? notes : null,
    );
    await loadEmployeeUpads();
  }

  void setEmployeeSearchQuery(String query) {
    _employeeSearchQuery = query;
    notifyListeners();
  }

  void setEmployeeRoleFilter(String role) {
    _selectedEmployeeRoleFilter = role;
    notifyListeners();
  }

  void setEmployeeActiveOnlyFilter(bool activeOnly) {
    _employeeActiveOnlyFilter = activeOnly;
    notifyListeners();
  }

  // --- Dynamic Roles Management ---
  Future<void> addEmployeeRole(String newRole) async {
    final trimmed = newRole.trim();
    if (trimmed.isEmpty) return;
    if (_settings.employeeRoles.any((r) => r.toLowerCase() == trimmed.toLowerCase())) return;
    final updatedList = List<String>.from(_settings.employeeRoles)..add(trimmed);
    _settings = _settings.copyWith(employeeRoles: updatedList);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateEmployeeRole(String oldRole, String newRole) async {
    final trimmed = newRole.trim();
    if (trimmed.isEmpty || oldRole == trimmed) return;
    final updatedList = _settings.employeeRoles.map((r) => r == oldRole ? trimmed : r).toList();
    _settings = _settings.copyWith(employeeRoles: updatedList);
    await _db.saveSettings(_settings);

    // Update existing employees who had this role in SQLite
    final db = await _db.database;
    await db.update('employees', {'role': trimmed}, where: 'role = ?', whereArgs: [oldRole]);
    await loadEmployees();
    notifyListeners();
  }

  Future<void> deleteEmployeeRole(String role) async {
    final updatedList = _settings.employeeRoles.where((r) => r != role).toList();
    if (updatedList.isEmpty) return;
    _settings = _settings.copyWith(employeeRoles: updatedList);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> resetEmployeeRolesToDefault() async {
    _settings = _settings.copyWith(employeeRoles: SettingsModel.defaultRoles);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  // --- WhatsApp Message Logs Actions ---
  Future<void> loadWhatsAppLogs({int? employeeId, String? searchQuery}) async {
    _whatsappLogs = await _db.getWhatsAppLogs(
      employeeId: employeeId,
      searchQuery: searchQuery,
    );
    notifyListeners();
  }

  Future<WhatsAppLogModel> logWhatsAppMessage({
    int? employeeId,
    required String employeeName,
    required String recipientPhone,
    required String senderPhone,
    required String message,
    String messageType = 'upad_receipt',
    double amount = 0.0,
    String status = 'Sent',
  }) async {
    final log = WhatsAppLogModel(
      employeeId: employeeId,
      employeeName: employeeName,
      recipientPhone: recipientPhone,
      senderPhone: senderPhone,
      message: message,
      messageType: messageType,
      amount: amount,
      createdAt: DateTime.now(),
      status: status,
    );
    final id = await _db.insertWhatsAppLog(log);
    final savedLog = log.copyWith(id: id);
    _whatsappLogs.insert(0, savedLog);
    notifyListeners();
    return savedLog;
  }

  Future<void> deleteWhatsAppLog(int id) async {
    await _db.deleteWhatsAppLog(id);
    _whatsappLogs.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  Future<void> clearAllWhatsAppLogs() async {
    await _db.clearAllWhatsAppLogs();
    _whatsappLogs.clear();
    notifyListeners();
  }
}
