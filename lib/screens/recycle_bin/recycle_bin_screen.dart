import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../models/deleted_record_item.dart';
import '../../providers/production_provider.dart';
import '../../widgets/app_svg_icon.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedTypeFilter = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final isDark = provider.settings.isDarkMode;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);
    final lang = provider.settings.appLanguage;

    final currentList = provider.deletedRecords;

    // Filter by type
    final typeFiltered = _selectedTypeFilter == 'All'
        ? currentList
        : currentList.where((item) => item.recordType == _selectedTypeFilter).toList();

    // Filter by search query
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? typeFiltered
        : typeFiltered.where((item) {
            final title = item.recordTitle.toLowerCase();
            final subtitle = item.recordSubtitle.toLowerCase();
            final type = item.typeDisplayName.toLowerCase();
            final gujType = item.typeGujaratiName.toLowerCase();
            return title.contains(query) ||
                subtitle.contains(query) ||
                type.contains(query) ||
                gujType.contains(query);
          }).toList();

    // Counts for metrics
    final prodCount = currentList.where((i) => i.recordType == 'production_record').length;
    final matCount = currentList.where((i) => i.recordType == 'material_item').length;
    final masterCount = currentList.where((i) =>
        i.recordType == 'machine' ||
        i.recordType == 'account' ||
        i.recordType == 'material_product' ||
        i.recordType == 'supplier').length;
    final empCount = currentList.where((i) =>
        i.recordType == 'employee' ||
        i.recordType == 'employee_upad').length;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkScaffoldBg : AppTheme.slateBackground,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            _buildHeader(context, provider, accent, isDark, currentList.length),
            const SizedBox(height: 14),

            // Explanatory Banner
            _buildPreservationBanner(context, isDark, accent, lang),
            const SizedBox(height: 14),

            // Metric Summary Cards
            _buildMetricsRow(context, isDark, accent, currentList.length, prodCount, matCount, masterCount, empCount, lang),
            const SizedBox(height: 14),

            // Search Bar & Filter Chips
            _buildFilterBar(context, isDark, accent, currentList, lang),
            const SizedBox(height: 14),

            // Content List / Empty State
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(context, isDark, query.isNotEmpty || _selectedTypeFilter != 'All', lang)
                  : _buildRecordsList(context, provider, isDark, accent, filtered, lang),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ProductionProvider provider,
    Color accent,
    bool isDark,
    int totalCount,
  ) {
    final lang = provider.settings.appLanguage;
    final mainTitle = AppStrings.get('recycleBin', lang);
    final subTitle = AppStrings.get('recycleBinSubtitle', lang);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 980;

        Widget titleSection = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppSvgIcon.recycleBin(color: accent, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mainTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subTitle,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        Widget controlSection = Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.end,
          children: [
            if (totalCount > 0) ...[
              OutlinedButton.icon(
                onPressed: () => _confirmRestoreAll(context, provider),
                icon: AppSvgIcon.restore(size: 16, color: AppTheme.successGreenDark),
                label: Text(AppStrings.get('restoreAll', lang)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.successGreenDark,
                  side: const BorderSide(color: AppTheme.successGreenDark),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _confirmEmptyBin(context, provider),
                icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.white),
                label: Text(AppStrings.get('emptyBin', lang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 12),
              controlSection,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleSection),
            controlSection,
          ],
        );
      },
    );
  }

  Widget _buildPreservationBanner(BuildContext context, bool isDark, Color accent, String lang) {
    final bannerText = AppStrings.get('recycleBinGuarantee', lang);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          AppSvgIcon.info(size: 16, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bannerText,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(
    BuildContext context,
    bool isDark,
    Color accent,
    int totalCount,
    int prodCount,
    int matCount,
    int masterCount,
    int empCount,
    String lang,
  ) {
    String totalTitle = AppStrings.get('recycleBin', lang);
    String totalSub = AppStrings.t(lang, en: 'Total Deleted', gu: 'કુલ ડિલીટ રેકોર્ડ્સ', hi: 'कुल डिलीट रिकॉर्ड्स');

    String prodTitle = AppStrings.get('production', lang);
    String prodSub = AppStrings.t(lang, en: 'Production Records', gu: 'ઉત્પાદન રેકોર્ડ્સ', hi: 'उत्पादन रिकॉर्ड');

    String matTitle = AppStrings.get('materials', lang);
    String matSub = AppStrings.t(lang, en: 'Challan Items', gu: 'મટીરીયલ ચલણ', hi: 'सामग्री चालान');

    String empTitle = AppStrings.get('employees', lang);
    String empSub = AppStrings.t(lang, en: 'Employees & Advance', gu: 'કર્મચારી & ઉપાડ', hi: 'कर्मचारी एवं अग्रिम');

    String masterTitle = AppStrings.get('machines', lang);
    String masterSub = AppStrings.t(lang, en: 'Master Catalogs', gu: 'માસ્ટર કેટલોગ', hi: 'मास्टर कैटलॉग');

    final cards = [
      _metricCard(
        context: context,
        title: totalTitle,
        subtitle: totalSub,
        value: '$totalCount',
        icon: AppSvgIcon.recycleBin(size: 20, color: accent),
        color: accent,
        isDark: isDark,
      ),
      _metricCard(
        context: context,
        title: prodTitle,
        subtitle: prodSub,
        value: '$prodCount',
        icon: AppSvgIcon.production(size: 20, color: const Color(0xFF2563EB)),
        color: const Color(0xFF2563EB),
        isDark: isDark,
      ),
      _metricCard(
        context: context,
        title: matTitle,
        subtitle: matSub,
        value: '$matCount',
        icon: AppSvgIcon.materials(size: 20, color: const Color(0xFFD97706)),
        color: const Color(0xFFD97706),
        isDark: isDark,
      ),
      _metricCard(
        context: context,
        title: empTitle,
        subtitle: empSub,
        value: '$empCount',
        icon: AppSvgIcon.employees(size: 20, color: const Color(0xFF0D9488)),
        color: const Color(0xFF0D9488),
        isDark: isDark,
      ),
      _metricCard(
        context: context,
        title: masterTitle,
        subtitle: masterSub,
        value: '$masterCount',
        icon: AppSvgIcon.machines(size: 20, color: const Color(0xFF7C3AED)),
        color: const Color(0xFF7C3AED),
        isDark: isDark,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          final cardWidth = ((constraints.maxWidth - 20) / 2).clamp(160.0, 360.0);
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
          );
        }
        return Row(
          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
        );
      },
    );
  }

  Widget _metricCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String value,
    required Widget icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: icon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    bool isDark,
    Color accent,
    List<DeletedRecordItem> currentList,
    String lang,
  ) {
    String getLabel(String key, String en, String gu, String hi) {
      return AppStrings.t(lang, en: en, gu: gu, hi: hi);
    }

    final filterOptions = [
      {'key': 'All', 'label': AppStrings.get('allFilter', lang), 'count': currentList.length},
      {'key': 'production_record', 'label': getLabel('production_record', 'Production', 'પ્રોડક્શન', 'उत्पादन'), 'count': currentList.where((i) => i.recordType == 'production_record').length},
      {'key': 'material_item', 'label': getLabel('material_item', 'Materials', 'મટીરીયલ', 'सामग्री'), 'count': currentList.where((i) => i.recordType == 'material_item').length},
      {'key': 'employee', 'label': getLabel('employee', 'Employees', 'કર્મચારીઓ', 'कर्मचारी'), 'count': currentList.where((i) => i.recordType == 'employee').length},
      {'key': 'employee_upad', 'label': getLabel('employee_upad', 'Advances', 'ઉપાડ', 'अग्रिम'), 'count': currentList.where((i) => i.recordType == 'employee_upad').length},
      {'key': 'machine', 'label': getLabel('machine', 'Machines', 'મશીનો', 'मशीनें'), 'count': currentList.where((i) => i.recordType == 'machine').length},
      {'key': 'account', 'label': getLabel('account', 'Accounts', 'ખાતાઓ', 'खाते'), 'count': currentList.where((i) => i.recordType == 'account').length},
      {'key': 'material_product', 'label': getLabel('material_product', 'Products', 'પ્રોડક્ટ્સ', 'उत्पाद'), 'count': currentList.where((i) => i.recordType == 'material_product').length},
      {'key': 'supplier', 'label': getLabel('supplier', 'Suppliers', 'વેપારીઓ', 'व्यापारी'), 'count': currentList.where((i) => i.recordType == 'supplier').length},
    ];

    String hintText;
    if (lang == 'gu') {
      hintText = 'ડીલીટ થયેલા રેકોર્ડ્સમાં શોધો...';
    } else if (lang == 'hi') {
      hintText = 'डिलीट रिकॉर्ड्स में खोजें...';
    } else {
      hintText = 'Search in deleted records...';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          // Search Field
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(9.0),
                    child: AppSvgIcon.search(size: 16, color: AppTheme.textMuted(context)),
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.border(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                ),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Filter Chips (Responsive Wrap)
          Expanded(
            flex: 7,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: filterOptions.map((opt) {
                final key = opt['key'] as String;
                final label = opt['label'] as String;
                final count = opt['count'] as int;
                final isSelected = _selectedTypeFilter == key;

                return InkWell(
                  onTap: () => setState(() => _selectedTypeFilter = key),
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? accent : AppTheme.border(context),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.textSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, bool hasFilters, String lang) {
    String emptyTitle = AppStrings.get('recycleBinEmpty', lang);
    String emptySubtitle = AppStrings.get('recycleBinEmptySubtitle', lang);

    if (hasFilters) {
      emptyTitle = AppStrings.t(lang, en: 'No Matching Deleted Records', gu: 'કોઈ મેળ ખાતા ડિલીટ રેકોર્ડ્સ મળ્યા નથી', hi: 'कोई मेल खाते डिलीट रिकॉर्ड नहीं मिले');
      emptySubtitle = AppStrings.t(lang, en: 'Try adjusting your search query or filter selection.', gu: 'તમારી શોધ અથવા ફિલ્ટર બદલીને ફરી પ્રયાસ કરો.', hi: 'अपनी खोज या फ़िल्टर बदलकर पुनः प्रयास करें।');
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: AppSvgIcon.recycleBin(size: 48, color: AppTheme.textMuted(context)),
          ),
          const SizedBox(height: 14),
          Text(
            emptyTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            emptySubtitle,
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textMuted(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(
    BuildContext context,
    ProductionProvider provider,
    bool isDark,
    Color accent,
    List<DeletedRecordItem> list,
    String lang,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.border(context)),
        itemBuilder: (context, index) {
          final item = list[index];
          final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.deletedAt);

          final iconWidget = Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.typeColor.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: item.typeColor.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: item.getSvgIcon(size: 22, color: item.typeColor),
          );

          final infoColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.localizedTypeName(lang),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: item.typeColor,
                      ),
                    ),
                  ),
                  if (item.originalId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#ID: ${item.originalId}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSvgIcon.calendar(size: 12, color: AppTheme.textMuted(context)),
                      const SizedBox(width: 4),
                      Text(
                        'Deleted: $dateStr',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.recordTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              if (item.recordSubtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.recordSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ],
          );

          final actionButtons = Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Restore Button
              ElevatedButton.icon(
                onPressed: () => _restoreItem(context, provider, item),
                icon: AppSvgIcon.restore(size: 14, color: Colors.white),
                label: Text(AppStrings.get('restore', lang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),

              // Delete Permanently Button
              Tooltip(
                message: AppStrings.t(lang, en: 'Permanently Delete Record', gu: 'કાયમી ડીલીટ કરો', hi: 'स्थायी रूप से हटाएं'),
                child: OutlinedButton.icon(
                  onPressed: () => _confirmPermanentDeleteItem(context, provider, item, lang),
                  icon: const Icon(Icons.delete_forever_rounded, size: 14, color: AppTheme.dangerRed),
                  label: Text(
                    AppStrings.t(lang, en: 'Delete', gu: 'ડીલીટ', hi: 'हटाएं'),
                    style: const TextStyle(color: AppTheme.dangerRed),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.dangerRed,
                    side: BorderSide(color: AppTheme.dangerRed.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ],
          );

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 650) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          iconWidget,
                          const SizedBox(width: 12),
                          Expanded(child: infoColumn),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: actionButtons,
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    iconWidget,
                    const SizedBox(width: 14),
                    Expanded(child: infoColumn),
                    const SizedBox(width: 14),
                    actionButtons,
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _restoreItem(
    BuildContext context,
    ProductionProvider provider,
    DeletedRecordItem item,
  ) async {
    if (item.id == null) return;
    final success = await provider.restoreDeletedRecord(item.id!);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.recordTitle}" successfully restored back!'),
            backgroundColor: AppTheme.successGreenDark,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to restore record.'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _confirmPermanentDeleteItem(
    BuildContext context,
    ProductionProvider provider,
    DeletedRecordItem item,
    String lang,
  ) async {
    if (item.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(lang,
          en: 'Permanently Delete Record?',
          gu: 'કાયમી ડીલીટ કરવું છે?',
          hi: 'स्थायी रूप से हटाएं?',
        )),
        content: Text(
          AppStrings.t(lang,
            en: 'Are you sure you want to permanently delete "${item.recordTitle}"?\n\nWarning: This record will NOT be stored anywhere and cannot be recovered.',
            gu: 'શું તમે "${item.recordTitle}" ને કાયમ માટે ડીલીટ કરવા માંગો છો?\n\nચેતવણી: આ રેકોર્ડ ક્યાંય પણ સંગ્રહિત થશે નહીં અને પુનઃપ્રાપ્ત કરી શકાશે નહીં.',
            hi: 'क्या आप "${item.recordTitle}" को स्थायी रूप से हटाना चाहते हैं?\n\nचेतावनी: यह रिकॉर्ड कहीं भी स्टोर नहीं रहेगा और इसे वापस नहीं लाया जा सकेगा।',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.get('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppStrings.t(lang, en: 'Delete Permanently', gu: 'કાયમી ડીલીટ કરો', hi: 'स्थायी रूप से हटाएं'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && item.id != null) {
      await provider.permanentlyDeleteRecord(item.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.recordTitle}" permanently deleted.'),
            backgroundColor: AppTheme.dangerRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _confirmRestoreAll(
    BuildContext context,
    ProductionProvider provider,
  ) async {
    final list = provider.deletedRecords;
    final count = list.length;
    final lang = provider.settings.appLanguage;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(lang,
          en: 'Restore All Bin Records?',
          gu: 'બધા રેકોર્ડ્સ રીસ્ટોર કરવા છે?',
          hi: 'सभी रिकॉर्ड्स पुनर्स्थापित करें?',
        )),
        content: Text(
          AppStrings.t(lang,
            en: 'Are you sure you want to restore all $count records back to active data?',
            gu: 'શું તમે બધા $count રેકોર્ડ્સને સક્રિય ડેટામાં પાછા લાવવા માંગો છો?',
            hi: 'क्या आप सभी $count रिकॉर्ड्स को सक्रिय डेटा में वापस लाना चाहते हैं?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.get('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreenDark),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.get('restoreAll', lang), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final restored = await provider.restoreAllDeletedRecords();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully restored $restored records back to active data!'),
            backgroundColor: AppTheme.successGreenDark,
          ),
        );
      }
    }
  }

  Future<void> _confirmEmptyBin(
    BuildContext context,
    ProductionProvider provider,
  ) async {
    final count = provider.deletedRecords.length;
    final lang = provider.settings.appLanguage;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(lang,
          en: 'Empty Recycle Bin Permanently?',
          gu: 'રીસાયકલ બિન કાયમ માટે ખાલી કરવું છે?',
          hi: 'रीसायकल बिन स्थायी रूप से खाली करें?',
        )),
        content: Text(
          AppStrings.t(lang,
            en: 'Permanently deleting $count items from Recycle Bin.\n\nWarning: All items will be permanently erased and will NOT be stored anywhere. They cannot be recovered.',
            gu: 'રીસાયકલ બિનમાંથી $count આઇટમ્સ કાયમ માટે ડીલીટ થશે.\n\nચેતવણી: બધી આઇટમ્સ કાયમ માટે હટાવી દેવામાં આવશે અને ક્યાંય પણ સંગ્રહિત રહેશે નહીં. તેને પુનઃપ્રાપ્ત કરી શકાશે નહીં.',
            hi: 'रीसायकल बिन से $count आइटम्स स्थायी रूप से हटाए जा रहे हैं।\n\nचेतावनी: सभी आइटम्स हमेशा के लिए मिटा दिए जाएंगे और कहीं भी स्टोर नहीं रहेंगे। उन्हें वापस नहीं लाया जा सकेगा।',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.get('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppStrings.t(lang, en: 'Empty Permanently', gu: 'કાયમી ખાલી કરો', hi: 'स्थायी रूप से खाली करें'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.emptyRecycleBin();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recycle Bin permanently emptied. Nothing is stored.'),
            backgroundColor: AppTheme.dangerRed,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
