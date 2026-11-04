import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../models/account_model.dart';
import '../../providers/production_provider.dart';
import '../../widgets/widgets.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchFilter = '';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  final List<String> _presetColors = [
    '#2563EB', // Blue (250 Area)
    '#059669', // Emerald (400 Area)
    '#7C3AED', // Purple (Beads)
    '#DC2626', // Crimson
    '#D97706', // Amber
    '#0D9488', // Teal
    '#4F46E5', // Indigo
    '#E11D48', // Rose
    '#475569', // Slate
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddEditAccountDialog([AccountModel? account]) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: account?.name ?? '');
    final areaCtrl = TextEditingController(text: account?.area ?? '');
    String selectedColor = account?.colorHex ?? _presetColors.first;
    bool isActive = account?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final inputFill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
          final borderColor = isDark ? const Color(0xFF334155) : AppTheme.slateBorder;

          final lang = context.read<ProductionProvider>().settings.appLanguage;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  account == null ? Icons.add_circle_outline_rounded : Icons.edit_outlined,
                  color: AppTheme.parseColor(selectedColor),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  account == null
                      ? AppStrings.t(lang, en: 'Add New Account / Khata', gu: 'નવું ખાતું ઉમેરો', hi: 'नया खाता जोड़ें')
                      : AppStrings.t(lang, en: 'Edit Account / Khata', gu: 'ખાતું સુધારો', hi: 'खाता संपादित करें'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Name
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.t(lang, en: 'Account / Khata Name *', gu: 'ખાતાનું નામ *', hi: 'खाते का नाम *'),
                          hintText: 'e.g. Beads, 250 Area, 400 Area',
                          filled: true,
                          fillColor: inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return AppStrings.t(lang, en: 'Enter account name', gu: 'કૃપા કરીને ખાતાનું નામ લખો', hi: 'कृपया खाते का नाम दर्ज करें');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Area / Sub-code
                      TextFormField(
                        controller: areaCtrl,
                        decoration: InputDecoration(
                          labelText: 'Area / Code',
                          hintText: 'e.g. 250, 400, Beads, Frame-A',
                          filled: true,
                          fillColor: inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Color Theme Picker
                      const Text(
                        'Account Theme Color',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _presetColors.map((hex) {
                          final color = AppTheme.parseColor(hex);
                          final isSelected = selectedColor.toUpperCase() == hex.toUpperCase();
                          return InkWell(
                            onTap: () => setDialogState(() => selectedColor = hex),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.6),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Active Toggle
                      AppSwitchCard(
                        titleText: 'Active Account',
                        subtitleText: 'Visible on dashboard and production entry',
                        value: isActive,
                        activeColor: AppTheme.parseColor(selectedColor),
                        onChanged: (val) => setDialogState(() => isActive = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.parseColor(selectedColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final provider = context.read<ProductionProvider>();
                    final accName = nameCtrl.text.trim();

                    final isDuplicate = provider.accounts.any(
                      (a) => a.name.toLowerCase() == accName.toLowerCase() && a.id != account?.id,
                    );
                    if (isDuplicate) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Account name "$accName" already exists!'),
                          backgroundColor: AppTheme.dangerRed,
                        ),
                      );
                      return;
                    }

                    try {
                      if (account == null) {
                        await provider.addAccount(
                          AccountModel(
                            name: accName,
                            area: areaCtrl.text.trim(),
                            colorHex: selectedColor,
                            isActive: isActive,
                            notes: '',
                          ),
                        );
                      } else {
                        await provider.updateAccount(
                          account.copyWith(
                            name: accName,
                            area: areaCtrl.text.trim(),
                            colorHex: selectedColor,
                            isActive: isActive,
                            notes: '',
                          ),
                        );
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving account: $e'),
                            backgroundColor: AppTheme.dangerRed,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Text(account == null ? 'Add Account' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteAccount(AccountModel account, int tiedRecordsCount) async {
    final prov = context.read<ProductionProvider>();
    final lang = prov.settings.appLanguage;
    final binName = AppStrings.get('recycleBin', lang);

    String message;
    if (lang == 'gu') {
      message = tiedRecordsCount > 0
          ? '${account.name} પાસે $tiedRecordsCount ઉત્પાદન એન્ટ્રીઓ છે.\n\n$binName માં મોકલવાથી તે ભવિષ્યની નવી એન્ટ્રીઓ માટે બંધ થશે પરંતુ જૂનો બધો ડેટા સુરક્ષિત રહેશે અને ગમે ત્યારે પાછો લાવી શકાય છે.\n\nઆગળ વધવું?'
          : 'શું તમે ખરેખર ${account.name} ડિલીટ કરવા માંગો છો?\n\nતે સુરક્ષિત રીતે $binName માં જશે અને ગમે ત્યારે પાછું લાવી શકાય છે.';
    } else if (lang == 'hi') {
      message = tiedRecordsCount > 0
          ? '${account.name} के पास $tiedRecordsCount उत्पादन रिकॉर्ड हैं।\n\n$binName में भेजने पर यह भविष्य की प्रविष्टियों से हट जाएगा, लेकिन सारा डेटा सुरक्षित रहेगा और कभी भी वापस लाया जा सकता है।\n\nक्या आगे बढ़ना है?'
          : 'क्या आप वास्तव में ${account.name} हटाना चाहते हैं?\n\nयह सुरक्षित रूप से $binName में जाएगा और कभी भी वापस लाया जा सकता है।';
    } else {
      message = tiedRecordsCount > 0
          ? '${account.name} has $tiedRecordsCount recorded production batches.\n\nMoving it to the Recycle Bin will remove it from future entries, but all history is preserved and you can restore it anytime.\n\nProceed with removal?'
          : 'Are you sure you want to delete ${account.name}?\n\nIt will be moved to $binName and can be restored anytime.';
    }

    final confirm = await ConfirmDeleteDialog.show(
      context: context,
      title: lang == 'gu' ? '${account.name} $binName માં મોકલો' : (lang == 'hi' ? '${account.name} $binName में भेजें' : 'Move ${account.name} to $binName'),
      message: message,
      confirmLabel: 'Move to $binName',
    );

    if (confirm == true && account.id != null && mounted) {
      await prov.deleteAccount(account.id!);
      if (mounted) {
        final snackText = lang == 'gu'
            ? '${account.name} $binName માં ગયો. તમે ગમે ત્યારે પાછો લાવી શકો છો.'
            : (lang == 'hi'
                ? '${account.name} $binName में चला गया। आप कभी भी वापस ला सकते हैं।'
                : '${account.name} moved to $binName. You can restore anytime.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackText),
            backgroundColor: AppTheme.successGreenDark,
            action: SnackBarAction(
              label: 'Open Bin',
              textColor: Colors.amberAccent,
              onPressed: () => prov.setActiveNavIndex(11),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final isDark = provider.settings.isDarkMode;
    final currency = provider.settings.currencySymbol;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);

    final accounts = provider.accounts.where((a) {
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return a.name.toLowerCase().contains(q) ||
          a.area.toLowerCase().contains(q) ||
          a.notes.toLowerCase().contains(q);
    }).toList();

    accounts.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.displayOrder.compareTo(b.displayOrder);
          break;
        case 1:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 2:
          cmp = a.area.toLowerCase().compareTo(b.area.toLowerCase());
          break;
        case 4:
          final sumA = provider.getAccountSummary(a.name).totalEntries;
          final sumB = provider.getAccountSummary(b.name).totalEntries;
          cmp = sumA.compareTo(sumB);
          break;
        case 5:
          final sumA = provider.getAccountSummary(a.name).totalStitch;
          final sumB = provider.getAccountSummary(b.name).totalStitch;
          cmp = sumA.compareTo(sumB);
          break;
        case 6:
          final sumA = provider.getAccountSummary(a.name).finalAmount;
          final sumB = provider.getAccountSummary(b.name).finalAmount;
          cmp = sumA.compareTo(sumB);
          break;
        case 7:
          cmp = (a.isActive ? 1 : 0).compareTo(b.isActive ? 1 : 0);
          break;
        default:
          cmp = a.displayOrder.compareTo(b.displayOrder);
      }
      return _sortAscending ? cmp : -cmp;
    });

    final totalBatches = provider.allRecords.length;
    final totalRevenue = provider.allRecords.fold<double>(0.0, (s, r) => s + r.finalAmount);

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : AppTheme.darkNavy;
    final textMuted = isDark ? const Color(0xFF94A3B8) : AppTheme.slateMedium;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t(provider.settings.appLanguage, en: 'Accounts & Categories', gu: 'ખાતાવહી અને કેટેગરી', hi: 'खाता प्रबंधन एवं श्रेणियां'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage area-wise accounts (250 Area, 400 Area, Beads Khatu) and reorder tables on Dashboard',
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Account / Khatu', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
                onPressed: () => _openAddEditAccountDialog(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Overview Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 800;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildSummaryCard(
                    title: 'Total Accounts',
                    value: '${provider.accounts.length}',
                    icon: Icons.folder_shared_outlined,
                    color: accent,
                    width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                    isDark: isDark,
                  ),
                  _buildSummaryCard(
                    title: 'Active on Dashboard',
                    value: '${provider.accounts.where((a) => a.isActive).length}',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppTheme.successGreenDark,
                    width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                    isDark: isDark,
                  ),
                  _buildSummaryCard(
                    title: 'Total Recorded Batches',
                    value: '$totalBatches',
                    icon: Icons.layers_outlined,
                    color: Colors.amber.shade700,
                    width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                    isDark: isDark,
                  ),
                  _buildSummaryCard(
                    title: 'Total Revenue',
                    value: '$currency${NumberFormat('#,##,###').format(totalRevenue)}',
                    icon: Icons.currency_rupee_rounded,
                    color: const Color(0xFF7C3AED),
                    width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Main Table Container
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
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
                // Table Toolbar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Configured Accounts & Dashboard Order (${accounts.length})',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        height: 38,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => setState(() => _searchFilter = val.trim()),
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search account or area...',
                            hintStyle: TextStyle(fontSize: 12.5, color: textMuted),
                            prefixIcon: Icon(Icons.search_rounded, size: 17, color: textMuted),
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
                ),

                // Table Data
                LayoutBuilder(
                  builder: (context, constraints) {
                    final dynamicSpacing = ((constraints.maxWidth - 680) / 9).clamp(10.0, 26.0);
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          columnSpacing: dynamicSpacing,
                          horizontalMargin: 12,
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAscending,
                          headingRowColor: WidgetStateProperty.all(
                            isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          ),
                          columns: [
                            DataColumn(
                              label: Text('Dashboard Order', style: _headerStyle(isDark)),
                              onSort: (idx, asc) => setState(() {
                                _sortColumnIndex = idx;
                                _sortAscending = asc;
                              }),
                            ),
                            DataColumn(
                              label: Text('Account Name', style: _headerStyle(isDark)),
                              onSort: (idx, asc) => setState(() {
                                _sortColumnIndex = idx;
                                _sortAscending = asc;
                              }),
                            ),
                            DataColumn(
                              label: Text('Area / Code', style: _headerStyle(isDark)),
                              onSort: (idx, asc) => setState(() {
                                _sortColumnIndex = idx;
                                _sortAscending = asc;
                              }),
                            ),
                            DataColumn(label: Text('Color Theme', style: _headerStyle(isDark))),
                            DataColumn(
                              numeric: true,
                              label: Text('Batches', style: _headerStyle(isDark)),
                              onSort: (idx, asc) => setState(() {
                                _sortColumnIndex = idx;
                                _sortAscending = asc;
                              }),
                            ),
                            DataColumn(
                              numeric: true,
                              label: Text('Total Stitch', style: _headerStyle(isDark)),
                              onSort: (idx, asc) => setState(() {
                                _sortColumnIndex = idx;
                                _sortAscending = asc;
                              }),
                            ),
                            DataColumn(
                              numeric: true,
                              label: Text('Total Revenue ($currency)', style: _headerStyle(isDark)),
                              onSort: (idx, asc) => setState(() {
                                _sortColumnIndex = idx;
                                _sortAscending = asc;
                              }),
                            ),
                            DataColumn(
                              label: Text('Status', style: _headerStyle(isDark)),
                              onSort: (idx, asc) => setState(() {
                                _sortColumnIndex = idx;
                                _sortAscending = asc;
                              }),
                            ),
                            DataColumn(label: Text('Actions', style: _headerStyle(isDark))),
                          ],
                          rows: accounts.map((acc) {
                            final summary = provider.getAccountSummary(acc.name);
                            final color = AppTheme.parseColor(acc.colorHex);
                            final index = provider.accounts.indexWhere((a) => a.id == acc.id);
                            final isFirst = index <= 0;
                            final isLast = index >= provider.accounts.length - 1;

                            return DataRow(
                              cells: [
                                // Order controls (▲/▼)
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Pos #${index + 1}',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: Icon(Icons.arrow_upward_rounded, size: 16, color: isFirst ? textMuted.withValues(alpha: 0.3) : color),
                                        tooltip: 'Move Up',
                                        onPressed: isFirst ? null : () => provider.moveAccountOrder(acc.id!, true),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.arrow_downward_rounded, size: 16, color: isLast ? textMuted.withValues(alpha: 0.3) : color),
                                        tooltip: 'Move Down',
                                        onPressed: isLast ? null : () => provider.moveAccountOrder(acc.id!, false),
                                      ),
                                    ],
                                  ),
                                ),

                                // Account Name
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        acc.name,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                                      ),
                                    ],
                                  ),
                                ),

                                // Area / Code
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      acc.area.isNotEmpty ? acc.area : '—',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                                    ),
                                  ),
                                ),

                                // Color Theme
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(acc.colorHex, style: TextStyle(fontSize: 11.5, color: textMuted)),
                                    ],
                                  ),
                                ),

                                // Batches
                                DataCell(
                                  Text(
                                    '${summary.totalEntries}',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                ),

                                // Total Stitch
                                DataCell(
                                  Text(
                                    NumberFormat('#,##,###').format(summary.totalStitch),
                                    style: TextStyle(fontSize: 13, color: textPrimary),
                                  ),
                                ),

                                // Total Revenue
                                DataCell(
                                  Text(
                                    '$currency${NumberFormat('#,##,###.00').format(summary.finalAmount)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF4ADE80) : AppTheme.successGreenDark,
                                    ),
                                  ),
                                ),

                                // Status
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: acc.isActive
                                          ? AppTheme.successGreenDark.withValues(alpha: 0.12)
                                          : AppTheme.dangerRed.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      acc.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: acc.isActive ? AppTheme.successGreenDark : AppTheme.dangerRed,
                                      ),
                                    ),
                                  ),
                                ),

                                // Actions
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, size: 18, color: accent),
                                        tooltip: 'Edit Account',
                                        onPressed: () => _openAddEditAccountDialog(acc),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.dangerRed),
                                        tooltip: 'Delete Account',
                                        onPressed: () => _confirmDeleteAccount(acc, summary.totalEntries),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : AppTheme.slateMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.darkNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
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
