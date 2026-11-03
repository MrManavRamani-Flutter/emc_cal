import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/localization/app_strings.dart';
import '../providers/production_provider.dart';
import 'masters/accounts_screen.dart';
import 'analytics/analytics_screen.dart';
import 'backup_restore/backup_restore_screen.dart';
import 'production/calculation_details_screen.dart';
import 'production/dashboard_screen.dart';
import 'employees/employees_screen.dart';
import 'analytics/excel_export_screen.dart';
import 'masters/machines_screen.dart';
import 'materials/materials_screen.dart';
import 'production/production_entry_screen.dart';
import 'masters/rates_heads_screen.dart';
import 'recycle_bin/recycle_bin_screen.dart';
import 'settings/settings_screen.dart';
import '../widgets/app_svg_icon.dart';
import '../widgets/embroidery_machine_art.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  double _sidebarWidth = 240.0;
  bool _isDraggingSidebar = false;
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final isDark = provider.settings.isDarkMode;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);

    final effectiveSidebarWidth = _isSidebarCollapsed ? 70.0 : _sidebarWidth;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkScaffoldBg : AppTheme.slateBackground,
      body: Column(
        children: [
          // Top Header Bar
          _buildTopHeader(context, provider),

          // Main App Body (Sidebar + Drag Resizer + Content Screen)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Navigation Sidebar (resizable when expanded, compact when collapsed)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: effectiveSidebarWidth,
                  child: ClipRect(
                    child: _buildSidebar(context, provider),
                  ),
                ),

                // Resizable Divider / Drag Handle (only active when uncollapsed)
                if (!_isSidebarCollapsed)
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) => setState(() => _isDraggingSidebar = true),
                      onHorizontalDragEnd: (_) => setState(() => _isDraggingSidebar = false),
                      onHorizontalDragCancel: () => setState(() => _isDraggingSidebar = false),
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(180.0, 420.0);
                        });
                      },
                      child: Container(
                        width: 8,
                        height: double.infinity,
                        color: _isDraggingSidebar
                            ? accent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        alignment: Alignment.center,
                        child: Container(
                          width: 2,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isDraggingSidebar ? accent : AppTheme.border(context),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Active Screen Body
                Expanded(
                  child: _buildActiveScreen(provider.activeNavIndex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Top Header Bar
  Widget _buildTopHeader(BuildContext context, ProductionProvider provider) {
    final todayStr = DateFormat('dd MMM yyyy').format(DateTime.now());
    final totalMachines = provider.machines.length;
    final operatorName = provider.settings.operatorName;
    final isDark = provider.settings.isDarkMode;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        border: Border(bottom: BorderSide(color: AppTheme.border(context), width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1080;
          final isMedium = constraints.maxWidth >= 820;
          final isVeryCompact = constraints.maxWidth < 640;

          return Row(
            children: [
              // Sidebar Collapse / Expand Toggle Button
              Tooltip(
                message: _isSidebarCollapsed
                    ? AppStrings.t(provider.settings.appLanguage, en: 'Expand Sidebar', gu: 'સાઈડબાર ખોલો', hi: 'साइडबार खोलें')
                    : AppStrings.t(provider.settings.appLanguage, en: 'Collapse Sidebar', gu: 'સાઈડબાર સંકોચો', hi: 'साइडबार छोटा करें'),
                child: InkWell(
                  onTap: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: _isSidebarCollapsed
                        ? AppSvgIcon.expand(size: 18, color: accent)
                        : AppSvgIcon.collapse(size: 18, color: accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // App Logo (OM Mavtar Group Image - PRESERVED UNCHANGED)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.5),
                  child: Image.asset(
                    'assets/images/om_logo.jpg',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // App Title & Tagline
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.settings.companyName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary(context),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (!isVeryCompact)
                      Text(
                        'Track • Calculate • Manage • Grow',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right Header Widgets with Custom SVG Icons
              if (isWide) ...[
                _headerChip(
                  context: context,
                  icon: AppSvgIcon.calendar(size: 16, color: accent),
                  title: AppStrings.get('today', provider.settings.appLanguage),
                  subtitle: todayStr,
                  iconColor: accent,
                ),
                const SizedBox(width: 14),
                _headerChip(
                  context: context,
                  icon: AppSvgIcon.machines(size: 16, color: AppTheme.purpleAccent),
                  title: AppStrings.get('activeMachines', provider.settings.appLanguage),
                  subtitle: '$totalMachines',
                  iconColor: AppTheme.purpleAccent,
                ),
                const SizedBox(width: 14),
              ],

              if (isMedium) ...[
                _headerChip(
                  context: context,
                  icon: AppSvgIcon.user(size: 16, color: AppTheme.successGreenDark),
                  title: AppStrings.get('operator', provider.settings.appLanguage),
                  subtitle: operatorName,
                  iconColor: AppTheme.successGreenDark,
                ),
                const SizedBox(width: 12),
              ],



              // Quick Dark / Light Mode Switcher (SVG Sun / Moon)
              Tooltip(
                message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                child: InkWell(
                  onTap: () => provider.toggleDarkMode(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: isDark
                        ? AppSvgIcon.sun(size: 18, color: Colors.amber)
                        : AppSvgIcon.moon(size: 18, color: const Color(0xFF475569)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _headerChip({
    required BuildContext context,
    required Widget icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    final isDark = AppTheme.isDark(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7.5),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon,
        ),
        const SizedBox(width: 9),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 10, color: AppTheme.textMuted(context))),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Left Sidebar
  Widget _buildSidebar(BuildContext context, ProductionProvider provider) {
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);
    final isDark = provider.settings.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        border: Border(right: BorderSide(color: AppTheme.border(context), width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Menu Items (Dedicated vector SVG icons)
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 8 : 12),
              children: [
                // 1. Dashboard
                _sidebarItem(
                  context: context,
                  index: 0,
                  label: AppStrings.get('dashboard', provider.settings.appLanguage),
                  icon: (color) => AppSvgIcon.dashboard(size: 20, color: color),
                  currentIndex: provider.activeNavIndex,
                  accentColor: accent,
                  isDark: isDark,
                  onTap: () => provider.setActiveNavIndex(0),
                ),

                // 2. Production Entry
                _sidebarItem(
                  context: context,
                  index: 1,
                  label: AppStrings.get('productionEntry', provider.settings.appLanguage),
                  icon: (color) => AppSvgIcon.production(size: 20, color: color),
                  currentIndex: provider.activeNavIndex,
                  accentColor: accent,
                  isDark: isDark,
                  onTap: () => provider.setActiveNavIndex(1),
                ),

                // 3. Employees & Upad
                _sidebarItem(
                  context: context,
                  index: 12,
                  label: AppStrings.get('employees', provider.settings.appLanguage),
                  icon: (color) => AppSvgIcon.employees(size: 20, color: color),
                  currentIndex: provider.activeNavIndex,
                  accentColor: accent,
                  isDark: isDark,
                  badgeCount: provider.employees.length,
                  onTap: () => provider.setActiveNavIndex(12),
                ),

                // 4. Accounts / Khata
                _sidebarItem(
                  context: context,
                  index: 8,
                  label: AppStrings.get('accounts', provider.settings.appLanguage),
                  icon: (color) => AppSvgIcon.accounts(size: 20, color: color),
                  currentIndex: provider.activeNavIndex,
                  accentColor: accent,
                  isDark: isDark,
                  onTap: () => provider.setActiveNavIndex(8),
                ),

                // 5. Material Entry
                _sidebarItem(
                  context: context,
                  index: 10,
                  label: AppStrings.get('materials', provider.settings.appLanguage),
                  icon: (color) => AppSvgIcon.materials(size: 20, color: color),
                  currentIndex: provider.activeNavIndex,
                  accentColor: accent,
                  isDark: isDark,
                  onTap: () => provider.setActiveNavIndex(10),
                ),

                // 6. Analytics & Charts
                _sidebarItem(
                  context: context,
                  index: 4,
                  label: AppStrings.get('analytics', provider.settings.appLanguage),
                  icon: (color) => AppSvgIcon.analytics(size: 20, color: color),
                  currentIndex: provider.activeNavIndex,
                  accentColor: accent,
                  isDark: isDark,
                  onTap: () => provider.setActiveNavIndex(4),
                ),

                // 7. Excel Export
                _sidebarItem(
                  context: context,
                  index: 5,
                  label: AppStrings.get('excelExport', provider.settings.appLanguage),
                  icon: (color) => AppSvgIcon.excel(size: 20, color: color),
                  currentIndex: provider.activeNavIndex,
                  accentColor: accent,
                  isDark: isDark,
                  onTap: () => provider.setActiveNavIndex(5),
                ),

                // 8. Machines
                _sidebarItem(
                  context: context,
                  index: 2,
                  label: AppStrings.get('machines', provider.settings.appLanguage),
                  icon: (color) => AppSvgIcon.machines(size: 20, color: color),
                  currentIndex: provider.activeNavIndex,
                  accentColor: accent,
                  isDark: isDark,
                  onTap: () => provider.setActiveNavIndex(2),
                ),

                // 9. Rates & Heads
                _sidebarItem(
                  context: context,
                  index: 3,
                  label: AppStrings.get('ratesHeads', provider.settings.appLanguage),
                  icon: (color) => AppSvgIcon.rates(size: 20, color: color),
                  currentIndex: provider.activeNavIndex,
                  accentColor: accent,
                  isDark: isDark,
                  onTap: () => provider.setActiveNavIndex(3),
                ),

                // 10. Recycle Bin & Safe Vault
                _sidebarItem(
                  context: context,
                  index: 11,
                  label: AppStrings.get('recycleBin', provider.settings.appLanguage),
                  icon: (color) => AppSvgIcon.recycleBin(size: 20, color: color),
                  currentIndex: provider.activeNavIndex,
                  accentColor: accent,
                  isDark: isDark,
                  badgeCount: provider.deletedRecords.length,
                  onTap: () => provider.setActiveNavIndex(11),
                ),

                // 11. Settings
                _sidebarItem(
                  context: context,
                  index: 7,
                  label: AppStrings.get('settings', provider.settings.appLanguage),
                  icon: (color) => AppSvgIcon.settings(size: 20, color: color),
                  currentIndex: provider.activeNavIndex,
                  accentColor: accent,
                  isDark: isDark,
                  onTap: () => provider.setActiveNavIndex(7),
                ),
              ],
            ),
          ),

          // Bottom Sidebar Section (Collapsible mode shows compact dot, full mode shows artwork)
          if (!_isSidebarCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EmbroideryMachineArt(width: 80, height: 48),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 5,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.successGreenDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        'v1.0.0 • ${AppStrings.get('offlineMode', provider.settings.appLanguage)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Tooltip(
                message: 'v1.0.0 • Offline Mode (100% Local DB)',
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.successGreenDark,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required BuildContext context,
    required int index,
    required String label,
    required Widget Function(Color color) icon,
    required int currentIndex,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final isSelected = index == currentIndex;
    final itemColor = isSelected
        ? AppTheme.contrastText(accentColor)
        : (isDark ? const Color(0xFFCBD5E1) : AppTheme.slateDark);

    final content = Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _isSidebarCollapsed ? 8 : 12,
            vertical: 9.5,
          ),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactItem = _isSidebarCollapsed || constraints.maxWidth < 110;
              if (isCompactItem) {
                return Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      icon(itemColor),
                      if (badgeCount > 0)
                        Positioned(
                          right: -4,
                          top: -3,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppTheme.dangerRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }
              return Row(
                children: [
                  icon(itemColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: itemColor,
                      ),
                    ),
                  ),
                  if (badgeCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.contrastText(accentColor)
                              : (isDark ? Colors.white : AppTheme.darkNavy),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );

    if (_isSidebarCollapsed) {
      return Tooltip(
        message: badgeCount > 0 ? '$label ($badgeCount)' : label,
        waitDuration: const Duration(milliseconds: 300),
        child: content,
      );
    }
    return content;
  }

  Widget _buildActiveScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ProductionEntryScreen();
      case 2:
        return const MachinesScreen();
      case 3:
        return const RatesHeadsScreen();
      case 4:
        return const AnalyticsScreen();
      case 5:
        return const ExcelExportScreen();
      case 6:
        return const BackupRestoreScreen();
      case 7:
        return const SettingsScreen();
      case 8:
        return const AccountsScreen();
      case 9:
        return const CalculationDetailsScreen();
      case 10:
        return const MaterialsScreen();
      case 11:
        return const RecycleBinScreen();
      case 12:
        return const EmployeesScreen();
      default:
        return const DashboardScreen();
    }
  }
}
