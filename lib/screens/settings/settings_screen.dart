import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/calculation_engine.dart';
import '../../core/localization/app_strings.dart';
import '../../core/whatsapp_service.dart';
import '../employees/whatsapp_history_dialog.dart';
import '../../models/settings_model.dart';
import '../../providers/production_provider.dart';
import '../backup_restore/backup_restore_screen.dart';
import '../recycle_bin/recycle_bin_screen.dart';
import '../splash_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _activeSettingsTab = 0; // 0: General, 1: Rates, 2: Heads, 3: Appearance, 4: FAQ & Calculation, 5: Backup

  late double _defaultRate;
  late int _defaultHeads;
  late int _autoRefreshSeconds;
  late bool _isDarkMode;
  late String _themeColorHex;
  final TextEditingController _hexColorCtrl = TextEditingController();

  // WhatsApp Notification Settings
  late TextEditingController _senderPhoneCtrl;
  late bool _whatsappAutoSend;
  late String _whatsappMessageLanguage;

  // Calculation Sandbox Controllers
  final TextEditingController _testStitchCtrl = TextEditingController(text: '300000');
  final TextEditingController _testRateCtrl = TextEditingController(text: '1.25');
  final TextEditingController _testHeadsCtrl = TextEditingController(text: '12');

  String _dateFormat = 'Indian (DD-MM-YYYY)';
  String _numberFormat = 'Indian (1,00,000)';
  String _currencySymbol = '₹';
  String _paletteFilter = 'All';
  String _appLanguage = 'en';
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    final settings = context.read<ProductionProvider>().settings;
    _defaultRate = settings.defaultRate;
    _defaultHeads = settings.defaultHeads;
    _autoRefreshSeconds = settings.autoRefreshIntervalSeconds;
    _currencySymbol = settings.currencySymbol;
    _isDarkMode = settings.isDarkMode;
    _themeColorHex = settings.themeColorHex;
    _hexColorCtrl.text = _themeColorHex;
    _appLanguage = settings.appLanguage;
    if (_appLanguage == 'en_gu' || _appLanguage == 'en_hi' || _appLanguage.isEmpty) {
      _appLanguage = 'en';
    }
    _fontScale = settings.fontScale;

    _senderPhoneCtrl = TextEditingController(text: settings.senderPhone);
    _whatsappAutoSend = settings.whatsappAutoSend;
    _whatsappMessageLanguage = settings.whatsappMessageLanguage;

    if (!['₹', 'Rs.', 'INR'].contains(_currencySymbol)) {
      _currencySymbol = '₹';
    }
  }

  @override
  void dispose() {
    _hexColorCtrl.dispose();
    _senderPhoneCtrl.dispose();
    _testStitchCtrl.dispose();
    _testRateCtrl.dispose();
    _testHeadsCtrl.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final provider = context.read<ProductionProvider>();
    final updated = provider.settings.copyWith(
      defaultRate: _defaultRate,
      defaultHeads: _defaultHeads,
      currencySymbol: _currencySymbol,
      autoRefreshIntervalSeconds: _autoRefreshSeconds,
      isDarkMode: _isDarkMode,
      themeColorHex: _themeColorHex,
      senderPhone: _senderPhoneCtrl.text.trim(),
      whatsappAutoSend: _whatsappAutoSend,
      whatsappMessageLanguage: _whatsappMessageLanguage,
      appLanguage: _appLanguage,
      fontScale: _fontScale,
    );
    provider.saveSettings(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: AppTheme.successGreenDark,
      ),
    );
  }

  void _applyCustomColor() {
    String hex = _hexColorCtrl.text.trim();
    if (!hex.startsWith('#')) {
      hex = '#$hex';
    }
    final parsed = AppTheme.parseColor(hex, const Color(0x00000000));
    if (parsed == const Color(0x00000000) && hex.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-character hex code (e.g. #2563EB)'),
          backgroundColor: AppTheme.dangerRedDark,
        ),
      );
      return;
    }

    setState(() {
      _themeColorHex = hex;
    });
    context.read<ProductionProvider>().setThemeColorHex(hex);
  }

  void _showColorPickerDialog(BuildContext context, ProductionProvider provider) {
    Color tempColor = AppTheme.parseColor(_themeColorHex);

    final lightColors = [
      {'name': 'Soft Sky', 'hex': '#38BDF8'},
      {'name': 'Mint Aqua', 'hex': '#34D399'},
      {'name': 'Lavender', 'hex': '#A78BFA'},
      {'name': 'Golden Sun', 'hex': '#FBBF24'},
      {'name': 'Pastel Peach', 'hex': '#FB923C'},
      {'name': 'Rose Quartz', 'hex': '#F472B6'},
      {'name': 'Soft Cyan', 'hex': '#22D3EE'},
      {'name': 'Lime Tint', 'hex': '#A3E635'},
    ];

    final vibrantColors = [
      {'name': 'Royal Blue', 'hex': '#2563EB'},
      {'name': 'Emerald Green', 'hex': '#10B981'},
      {'name': 'Vibrant Purple', 'hex': '#8B5CF6'},
      {'name': 'Amber Orange', 'hex': '#F59E0B'},
      {'name': 'Crimson Red', 'hex': '#EF4444'},
      {'name': 'Teal Wave', 'hex': '#14B8A6'},
      {'name': 'Electric Violet', 'hex': '#7C3AED'},
      {'name': 'Indigo Blue', 'hex': '#4F46E5'},
    ];

    final darkColors = [
      {'name': 'Midnight Slate', 'hex': '#1E293B'},
      {'name': 'Deep Navy', 'hex': '#1E3A8A'},
      {'name': 'Forest Emerald', 'hex': '#064E3B'},
      {'name': 'Dark Burgundy', 'hex': '#831843'},
      {'name': 'Charcoal Black', 'hex': '#334155'},
      {'name': 'Royal Indigo', 'hex': '#312E81'},
      {'name': 'Dark Teal', 'hex': '#134E4A'},
      {'name': 'Espresso Brown', 'hex': '#451A03'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final contrastForeground = AppTheme.contrastText(tempColor);
            final isLight = AppTheme.isLightColor(tempColor);
            final hexString = '#${tempColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

            Widget buildColorRow(String title, List<Map<String, String>> palette) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: palette.map((c) {
                      final parsed = AppTheme.parseColor(c['hex']!);
                      final isSelected = tempColor.toARGB32() == parsed.toARGB32();
                      return Tooltip(
                        message: '${c['name']} (${c['hex']})',
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              tempColor = parsed;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: parsed,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.black26,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: parsed.withValues(alpha: 0.6),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 20,
                                    color: AppTheme.contrastText(parsed),
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],
              );
            }

            return AlertDialog(
              backgroundColor: AppTheme.cardBg(context),
              title: Row(
                children: [
                  const Icon(Icons.palette_rounded, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.t(_appLanguage, en: 'Color Palette Picker', gu: 'કલર પેલેટ પીકર', hi: 'रंग चयनकर्ता'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t(_appLanguage,
                        en: 'Light & Dark palette presets. Text readability is automatically protected.',
                        gu: 'લાઇટ અને ડાર્ક કલર પ્રીસેટ્સ. લખાણ વાંચવાની સરળતા આપોઆપ સુરક્ષિત રહે છે.',
                        hi: 'हल्के व गहरे रंग प्रीसेट। टेक्स्ट की स्पष्टता अपने आप सुरक्षित रहती है।',
                      ),
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                    ),
                    const SizedBox(height: 16),
                    buildColorRow(AppStrings.t(_appLanguage, en: 'Light Colors', gu: 'હળવા રંગો', hi: 'हल्के व कोमल रंग'), lightColors),
                    buildColorRow(AppStrings.t(_appLanguage, en: 'Vibrant & Modern Colors', gu: 'ચમકદાર અને આધુનિક રંગો', hi: 'चमकदार व आधुनिक रंग'), vibrantColors),
                    buildColorRow(AppStrings.t(_appLanguage, en: 'Dark & Deep Colors', gu: 'ઘેરા રંગો', hi: 'गहरे रंग'), darkColors),
                    const Divider(),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: tempColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border(context)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppStrings.t(_appLanguage, en: 'Selected', gu: 'પસંદ કરેલ', hi: 'चयनित')}: $hexString',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                                ),
                                Text(
                                  isLight
                                      ? AppStrings.t(_appLanguage,
                                          en: 'Light tone detected → Text set to Dark Slate (#0F172A)',
                                          gu: 'લાઇટ કલર ડિટેક્ટ થયો → ટેક્સ્ટ આપમેળે ડાર્ક સ્લેટ (#0F172A) સેટ થયો',
                                          hi: 'हल्का रंग पहचाना गया → टेक्स्ट गहरा स्लेट (#0F172A) सेट हुआ',
                                        )
                                      : AppStrings.t(_appLanguage,
                                          en: 'Dark tone detected → Text set to Crisp White (#FFFFFF)',
                                          gu: 'ડાર્ક કલર ડિટેક્ટ થયો → ટેક્સ્ટ આપમેળે સફેદ (#FFFFFF) સેટ થયો',
                                          hi: 'गहरा रंग पहचाना गया → टेक्स्ट सफेद (#FFFFFF) सेट हुआ',
                                        ),
                                  style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary(context)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tempColor,
                              foregroundColor: contrastForeground,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              AppStrings.t(_appLanguage, en: 'Sample Label', gu: 'નમૂનો લેબલ', hi: 'नमूना लेबल'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppStrings.t(_appLanguage, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final hex = '#${tempColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                    setState(() {
                      _themeColorHex = hex;
                      _hexColorCtrl.text = hex;
                    });
                    provider.setThemeColorHex(hex);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tempColor,
                    foregroundColor: contrastForeground,
                  ),
                  child: Text(
                    AppStrings.t(_appLanguage, en: 'Apply Color', gu: 'કલર લાગુ કરો', hi: 'लागू करें'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final settings = provider.settings;
    final accent = AppTheme.parseColor(_themeColorHex);
    final isDark = provider.settings.isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs Bar: General | Appearance & Theme | Calculation Guide | Database Backup & Restore
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border(context))),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tabItem(AppStrings.get('general', _appLanguage), 0, accent),
                  _tabItem(AppStrings.get('appearanceTheme', _appLanguage), 1, accent),
                  _tabItem(AppStrings.get('calculationGuide', _appLanguage), 2, accent),
                  _tabItem(AppStrings.get('dbBackupRestore', _appLanguage), 3, accent),
                  _tabItem(AppStrings.get('recycleBin', _appLanguage), 4, accent),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Content Body
            Expanded(
              child: _buildBody(context, provider, settings, accent, isDark),
            ),

            // Save Settings Button (hidden on Backup & Recycle Bin tabs since they have their own action buttons)
            if (_activeSettingsTab != 3 && _activeSettingsTab != 4) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductionProvider provider,
    dynamic settings,
    Color accent,
    bool isDark,
  ) {
    switch (_activeSettingsTab) {
      case 1:
        return _buildAppearanceTab(context, provider, accent, isDark);
      case 2:
        return _buildFaqAndCalculationTab(context, settings, accent, isDark);
      case 3:
        return const BackupRestoreScreen(isEmbedded: true);
      case 4:
        return const RecycleBinScreen();
      default:
        return _buildGeneralTab(context, settings, accent, isDark);
    }
  }

  Widget _tabItem(String title, int index, Color accent) {
    final isSelected = _activeSettingsTab == index;
    return InkWell(
      onTap: () {
        setState(() => _activeSettingsTab = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? accent : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? accent : AppTheme.textSecondary(context),
          ),
        ),
      ),
    );
  }

  // --- Calculation Guide & FAQ Tab ---
  Widget _buildFaqAndCalculationTab(
    BuildContext context,
    dynamic settings,
    Color accent,
    bool isDark,
  ) {
    // Parse sandbox inputs
    final testStitch = int.tryParse(_testStitchCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final testRate = double.tryParse(_testRateCtrl.text.trim()) ?? 0.0;
    final testHeads = int.tryParse(_testHeadsCtrl.text.trim()) ?? 0;
    final calc = CalculationEngine.calculate(
      totalStitch: testStitch,
      rate: testRate,
      heads: testHeads,
      stitchDivider: 1000.0,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.calculate_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t(_appLanguage,
                      en: 'Calculation Formula Guide',
                      gu: 'ગણતરી ફોર્મ્યુલા માર્ગદર્શિકા',
                      hi: 'गणना फॉर्मूला गाइड',
                    ),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                  ),
                  Text(
                    'Complete explanation of how embroidery production math works along with live interactive sandbox',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted(context)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),


          // 1. Three Step Formula Cards
          Text(
            '1. How Calculation Works (3-Step Formula)',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Step 1
              Expanded(
                child: _formulaStepCard(
                  context: context,
                  stepNumber: 'Step 1',
                  title: 'Final Stitch',
                  formula: 'Total Stitch ÷ 1,000',
                  desc: 'Machine stitch count ko 1,000 ke standard multiplier se divide karke units banate hain.',
                  example: 'Ex: 3,00,000 ÷ 1000 = 300 Final Stitch',
                  accent: accent,
                  icon: Icons.grain_rounded,
                ),
              ),
              const SizedBox(width: 12),
              // Step 2
              Expanded(
                child: _formulaStepCard(
                  context: context,
                  stepNumber: 'Step 2',
                  title: 'Base Amount (₹)',
                  formula: 'Final Stitch × Rate (₹)',
                  desc: 'Final Stitch ko embroidery rate per unit (e.g. ₹1.25) se multiply kiya jata hai.',
                  example: 'Ex: 300 × ₹1.25 = ₹375.00',
                  accent: accent,
                  icon: Icons.currency_rupee_rounded,
                ),
              ),
              const SizedBox(width: 12),
              // Step 3
              Expanded(
                child: _formulaStepCard(
                  context: context,
                  stepNumber: 'Step 3',
                  title: 'Final Amount (₹)',
                  formula: 'Amount × Machine Heads',
                  desc: 'Base amount ko machine me chal rahe active heads (needles) se multiply kiya jata hai.',
                  example: 'Ex: ₹375.00 × 12 Heads = ₹4,500.00',
                  accent: accent,
                  icon: Icons.precision_manufacturing_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Interactive Live Calculation Sandbox
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science_rounded, size: 18, color: accent),
                        const SizedBox(width: 8),
                        Text(
                          'Live Calculation Simulator (Khud Test Karein)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                        ),
                      ],
                    ),
                    Text(
                      'Formula: (Stitch ÷ 1000) × Rate × Heads',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Total Stitch Input
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Stitch', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context))),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _testStitchCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: '300000',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Rate Input
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rate (₹)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context))),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _testRateCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: '1.25',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Heads Input
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Heads', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context))),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _testHeadsCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: '12',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Live Calculation Output Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _outputBadge('Final Stitch', NumberFormat('#,##,###').format(calc.finalStitch.toInt()), accent),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.slateLight),
                      _outputBadge('Amount', '₹${NumberFormat('#,##,###.00').format(calc.amount)}', accent),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.slateLight),
                      _outputBadge(
                        AppStrings.t(_appLanguage, en: 'Final Amount', gu: 'કુલ રકમ', hi: 'कुल रकम'),
                        '₹${NumberFormat('#,##,###.00').format(calc.finalAmount)}',
                        AppTheme.successGreenDark,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outputBadge(String label, String value, Color color, {bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.slateLight, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 12.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _formulaStepCard({
    required BuildContext context,
    required String stepNumber,
    required String title,
    required String formula,
    required String desc,
    required String example,
    required Color accent,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  stepNumber,
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Icon(icon, size: 16, color: accent),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle(context),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              formula,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary(context), height: 1.3)),
          const SizedBox(height: 6),
          Text(example, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.successGreenDark)),
        ],
      ),
    );
  }
  // --- Appearance Tab ---
  Widget _buildAppearanceTab(
    BuildContext context,
    ProductionProvider provider,
    Color accent,
    bool isDark,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme & Visual Appearance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 4),
          Text(
            'Customize mode (Light/Dark) and personalize your accent colors across the app',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
          ),
          const SizedBox(height: 22),

          // 1. Light vs Dark Mode Cards
          Text(
            'Theme Mode',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Light Mode Card
              Expanded(
                child: _themeModeCard(
                  context: context,
                  title: 'Light Mode',
                  subtitle: 'Clean, high-clarity day interface',
                  icon: Icons.light_mode_rounded,
                  iconColor: Colors.amber.shade700,
                  isSelected: !_isDarkMode,
                  cardBg: const Color(0xFFF8FAFC),
                  accent: accent,
                  onTap: () {
                    setState(() => _isDarkMode = false);
                    provider.toggleDarkMode(false);
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Dark Mode Card
              Expanded(
                child: _themeModeCard(
                  context: context,
                  title: 'Dark Mode',
                  subtitle: 'Sleek, eye-friendly night interface',
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF818CF8),
                  isSelected: _isDarkMode,
                  cardBg: const Color(0xFF0F172A),
                  accent: accent,
                  onTap: () {
                    setState(() => _isDarkMode = true);
                    provider.toggleDarkMode(true);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Language Selection (5 Options)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.t(_appLanguage, en: 'Application Language', gu: 'એપ્લિકેશન ભાષા', hi: 'एप्लिकेशन भाषा'),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
              ),
              Text(
                'Clean, border-safe layout',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildLangCard(
                code: 'en',
                title: AppStrings.t(_appLanguage, en: 'English', gu: 'અંગ્રેજી', hi: 'अंग्रेजी'),
                subtitle: AppStrings.t(_appLanguage, en: 'English (Default)', gu: 'અંગ્રેજી (મૂળભૂત)', hi: 'अंग्रेजी (डिफ़ॉल्ट)'),
                icon: Icons.public_rounded,
                isSelected: _appLanguage == 'en',
                onTap: () {
                  setState(() => _appLanguage = 'en');
                  provider.setAppLanguage('en');
                },
              ),
              _buildLangCard(
                code: 'gu',
                title: AppStrings.t(_appLanguage, en: 'Gujarati', gu: 'ગુજરાતી', hi: 'गुजराती'),
                subtitle: AppStrings.t(_appLanguage, en: 'Pure Gujarati Interface', gu: 'સંપૂર્ણ ગુજરાતી ઈન્ટરફેસ', hi: 'सम्पूर्ण गुजराती इंटरफेस'),
                icon: Icons.language_rounded,
                isSelected: _appLanguage == 'gu',
                onTap: () {
                  setState(() => _appLanguage = 'gu');
                  provider.setAppLanguage('gu');
                },
              ),
              _buildLangCard(
                code: 'hi',
                title: AppStrings.t(_appLanguage, en: 'Hindi', gu: 'હિન્દી', hi: 'हिन्दी'),
                subtitle: AppStrings.t(_appLanguage, en: 'Pure Hindi Interface', gu: 'શુદ્ધ હિન્દી ઈન્ટરફેસ', hi: 'शुद्ध हिन्दी इंटरफेस'),
                icon: Icons.language_rounded,
                isSelected: _appLanguage == 'hi',
                onTap: () {
                  setState(() => _appLanguage = 'hi');
                  provider.setAppLanguage('hi');
                },
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 3. Font Size Scaling (85% to 130%)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.t(_appLanguage, en: 'Font Size & Zoom', gu: 'અક્ષરોનું માપ અને ઝૂમ', hi: 'फ़ॉन्ट साइज़ और ज़ूम'),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(_fontScale * 100).toStringAsFixed(0)}% Scale',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_size_rounded, size: 20, color: Color(0xFF64748B)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Slider(
                        value: _fontScale,
                        min: 0.85,
                        max: 1.30,
                        divisions: 9,
                        activeColor: accent,
                        inactiveColor: AppTheme.border(context),
                        label: '${(_fontScale * 100).toStringAsFixed(0)}%',
                        onChanged: (val) {
                          setState(() => _fontScale = val);
                          provider.setFontScale(val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'A',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _fontPresetChip('Compact (90%)', 0.90, provider),
                    _fontPresetChip('Default (100%)', 1.00, provider),
                    _fontPresetChip('Large (115%)', 1.15, provider),
                    _fontPresetChip('Extra Large (125%)', 1.25, provider),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppTheme.border(context)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.remove_red_eye_outlined, size: 16, color: AppTheme.textSecondary(context)),
                    const SizedBox(width: 6),
                    Text(
                      'Live Font Preview:',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondary(context)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.t(_appLanguage,
                          en: 'OM MAVTAR GROUP — Stitches 1,50,000 × ₹1.25 = ₹1,875',
                          gu: 'OM MAVTAR GROUP — ટાંકા ૧,૫૦,૦૦૦ × ₹૧.૨૫ = ₹૧,૮૭૫',
                          hi: 'OM MAVTAR GROUP — टांके 1,50,000 × ₹1.25 = ₹1,875',
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 2. Preset Accent Colors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Theme Accent Color (Preset Palette)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
              ),
              Text(
                'Click any swatch to apply instantly',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Category Filter Chips (All, Light, Dark, Vibrant)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPaletteCategoryChip('All', 'All Colors (20)'),
                const SizedBox(width: 8),
                _buildPaletteCategoryChip('light', AppStrings.t(_appLanguage, en: 'Light Colors (7)', gu: 'હળવા રંગો (7)', hi: 'हल्के रंग (7)')),
                const SizedBox(width: 8),
                _buildPaletteCategoryChip('dark', AppStrings.t(_appLanguage, en: 'Dark Colors (6)', gu: 'ઘેરા રંગો (6)', hi: 'गहरे रंग (6)')),
                const SizedBox(width: 8),
                _buildPaletteCategoryChip('vibrant', 'Vibrant / Classic (7)'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Builder(
            builder: (ctx) {
              final filteredPresets = _paletteFilter == 'All'
                  ? AppTheme.presetThemeColors
                  : AppTheme.presetThemeColors.where((p) => p['type'] == _paletteFilter).toList();

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: filteredPresets.map((item) {
                  final name = item['name']!;
                  final hex = item['hex']!;
                  final color = AppTheme.parseColor(hex);
                  final isSelected = _themeColorHex.toUpperCase() == hex.toUpperCase();
                  final checkmarkColor = AppTheme.contrastText(color);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _themeColorHex = hex;
                        _hexColorCtrl.text = hex;
                      });
                      provider.setThemeColorHex(hex);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? color : AppTheme.border(context),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black12, width: 0.5),
                            ),
                            child: isSelected
                                ? Icon(Icons.check, size: 16, color: checkmarkColor)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  hex,
                                  style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted(context)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 28),

          // 3. Custom Color Input & Color Picker
          Text(
            'Custom Color (Choose Any Color / Color Picker)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Live Color Chip Preview
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.parseColor(_themeColorHex),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
              // Hex Text Field
              SizedBox(
                width: 170,
                child: TextField(
                  controller: _hexColorCtrl,
                  decoration: InputDecoration(
                    hintText: '#0066FF',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _applyCustomColor,
                icon: const Icon(Icons.colorize_rounded, size: 16),
                label: const Text('Apply Hex'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppTheme.contrastText(accent),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showColorPickerDialog(context, provider),
                icon: const Icon(Icons.palette_rounded, size: 16),
                label: Text(AppStrings.t(_appLanguage, en: 'Open Color Picker', gu: 'કલર પીકર ખોલો', hi: 'रंग चयनकर्ता खोलें')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceSubtle(context),
                  foregroundColor: AppTheme.textPrimary(context),
                  side: BorderSide(color: AppTheme.border(context)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 4. Live Preview Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Row(
              children: [
                Icon(Icons.palette_rounded, color: accent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Theme Active: ${_isDarkMode ? "Dark Mode" : "Light Mode"} with accent color $_themeColorHex',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Labels & action buttons adapt automatically using contrast-safe rendering to protect readability.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppTheme.contrastText(accent),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Sample Button', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Animated Splash Screen Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEAB308).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAB308).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFF59E0B), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OM MAVTAR GROUP — Animated Splash Screen',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Watch the luxury animated embroidery hoop, sacred OM emblem, and dynamic database loader.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => const SplashScreen(isReplay: true),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    );
                  },
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text('Play Splash Screen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteCategoryChip(String type, String label) {
    final isSelected = _paletteFilter == type;
    final accent = AppTheme.parseColor(_themeColorHex);

    return InkWell(
      onTap: () {
        setState(() {
          _paletteFilter = type;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? accent : AppTheme.surfaceSubtle(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : AppTheme.border(context),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.contrastText(accent) : AppTheme.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _themeModeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required Color cardBg,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : AppTheme.border(context),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: title.contains('Dark') ? Colors.white : AppTheme.darkNavy,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: title.contains('Dark') ? const Color(0xFF94A3B8) : AppTheme.slateLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangCard({
    required String code,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AppTheme.isDark(context);
    final accent = Theme.of(context).primaryColor;
    final border = AppTheme.border(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 195,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? accent.withValues(alpha: 0.25) : accent.withValues(alpha: 0.1))
              : AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accent : border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? accent : AppTheme.textSecondary(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? accent : AppTheme.textPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.textMuted(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 16, color: accent),
          ],
        ),
      ),
    );
  }

  Widget _fontPresetChip(String label, double scale, ProductionProvider provider) {
    final isSelected = (_fontScale - scale).abs() < 0.03;
    final accent = Theme.of(context).primaryColor;

    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: accent.withValues(alpha: 0.2),
      onSelected: (_) {
        setState(() => _fontScale = scale);
        provider.setFontScale(scale);
      },
    );
  }

  // --- General Tab ---
  Widget _buildGeneralTab(
    BuildContext context,
    SettingsModel settings,
    Color accent,
    bool isDark,
  ) {
    // Deduplicate and ensure current default values are present in dropdowns
    final safeRates = settings.availableRates.toSet().toList();
    if (!safeRates.contains(_defaultRate)) {
      safeRates.add(_defaultRate);
    }
    safeRates.sort();

    final safeHeads = settings.availableHeads.toSet().toList();
    if (!safeHeads.contains(_defaultHeads)) {
      safeHeads.add(_defaultHeads);
    }
    safeHeads.sort();

    final dropdownBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputFill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : AppTheme.slateBorder;
    final primaryTextColor = isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy;
    final labelTextColor = isDark ? const Color(0xFFE2E8F0) : AppTheme.textSecondary(context);

    InputDecoration inputDecor() => InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true,
          fillColor: inputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accent, width: 2)),
        );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'General Settings',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _activeSettingsTab = 1),
                    child: Row(
                      children: [
                        Icon(Icons.palette_outlined, size: 15, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          'Theme & Colors',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: accent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  InkWell(
                    onTap: () => setState(() => _activeSettingsTab = 2),
                    child: Row(
                      children: [
                        Icon(Icons.help_outline_rounded, size: 15, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          'Calculation Guide →',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Two Columns Form
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Default Rate
                    Text('Default Rate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelTextColor)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<double>(
                      initialValue: _defaultRate,
                      dropdownColor: dropdownBg,
                      style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                      decoration: inputDecor(),
                      items: safeRates.map((double r) {
                        return DropdownMenuItem<double>(
                          value: r,
                          child: Text(r.toStringAsFixed(2), style: TextStyle(color: primaryTextColor)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _defaultRate = val);
                      },
                    ),
                    const SizedBox(height: 18),

                    // Default Heads
                    Text('Default Heads', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelTextColor)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _defaultHeads,
                      dropdownColor: dropdownBg,
                      style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                      decoration: inputDecor(),
                      items: safeHeads.map((int h) {
                        return DropdownMenuItem<int>(
                          value: h,
                          child: Text('$h', style: TextStyle(color: primaryTextColor)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _defaultHeads = val);
                      },
                    ),
                    const SizedBox(height: 18),

                    // Dates Format
                    Text('Dates Format', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelTextColor)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _dateFormat,
                      dropdownColor: dropdownBg,
                      style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                      decoration: inputDecor(),
                      items: const [
                        DropdownMenuItem(value: 'Indian (DD-MM-YYYY)', child: Text('Indian (DD-MM-YYYY)')),
                        DropdownMenuItem(value: 'ISO (YYYY-MM-DD)', child: Text('ISO (YYYY-MM-DD)')),
                        DropdownMenuItem(value: 'US (MM-DD-YYYY)', child: Text('US (MM-DD-YYYY)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _dateFormat = val);
                      },
                    ),
                    const SizedBox(height: 18),

                    // Currency Symbol
                    Text(
                      AppStrings.t(_appLanguage, en: 'Currency Symbol', gu: 'ચલણ પ્રતીક', hi: 'मुद्रा प्रतीक'),
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelTextColor),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _currencySymbol,
                      dropdownColor: dropdownBg,
                      style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                      decoration: inputDecor(),
                      items: [
                        DropdownMenuItem(
                          value: '₹',
                          child: Text(AppStrings.t(_appLanguage, en: '₹ (Indian Rupee)', gu: '₹ (ભારતીય રૂપિયો)', hi: '₹ (भारतीय रुपया)')),
                        ),
                        const DropdownMenuItem(value: 'Rs.', child: Text('Rs. (Rupees)')),
                        const DropdownMenuItem(value: 'INR', child: Text('INR (Indian Rupee)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _currencySymbol = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),

              // Right Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System Version (Disabled / Read-only)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Software Version', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelTextColor)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, size: 9.5, color: AppTheme.textMuted(context)),
                              const SizedBox(width: 3),
                              Text('Read-only', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFE2E8F0) : AppTheme.textSecondary(context))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    MouseRegion(
                      cursor: SystemMouseCursors.forbidden,
                      child: Tooltip(
                        message: 'System fixed version (Read-only)',
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor, width: 1.2),
                            borderRadius: BorderRadius.circular(8),
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('1.0.0 (Release Desktop)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                              Icon(Icons.lock_outline_rounded, size: 14, color: AppTheme.textMuted(context)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Number Format
                    Text('Number Format', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelTextColor)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _numberFormat,
                      dropdownColor: dropdownBg,
                      style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                      decoration: inputDecor(),
                      items: const [
                        DropdownMenuItem(value: 'Indian (1,00,000)', child: Text('Indian (1,00,000)')),
                        DropdownMenuItem(value: 'International (100,000)', child: Text('International (100,000)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _numberFormat = val);
                      },
                    ),
                    const SizedBox(height: 18),

                    // Dashboard Auto-Refresh Interval
                    Row(
                      children: [
                        Icon(Icons.sync_rounded, size: 15, color: accent),
                        const SizedBox(width: 5),
                        Text('Dashboard Auto-Refresh Interval', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelTextColor)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: [0, 10, 15, 30, 60, 120].contains(_autoRefreshSeconds) ? _autoRefreshSeconds : 120,
                      dropdownColor: dropdownBg,
                      style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                      decoration: inputDecor(),
                      items: const [
                        DropdownMenuItem(value: 120, child: Text('2 Min (120s - Recommended)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 60, child: Text('1 Min (60s)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 30, child: Text('30 Seconds', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 15, child: Text('15 Seconds', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 10, child: Text('10 Seconds (Fast Sync)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 0, child: Text('Disabled (Manual Only)', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _autoRefreshSeconds = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // WhatsApp Notifications & Upad Receipts Configuration Card
          _buildWhatsAppSettingsCard(
            context,
            settings,
            accent,
            isDark,
            dropdownBg,
            inputFill,
            borderColor,
            primaryTextColor,
            labelTextColor,
            inputDecor,
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppSettingsCard(
    BuildContext context,
    SettingsModel settings,
    Color accent,
    bool isDark,
    Color dropdownBg,
    Color inputFill,
    Color borderColor,
    Color primaryTextColor,
    Color labelTextColor,
    InputDecoration Function() inputDecor,
  ) {
    const waGreen = Color(0xFF25D366);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13202E) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: waGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: waGreen, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          AppStrings.t(_appLanguage,
                            en: 'WhatsApp Advance Receipts & Alerts',
                            gu: 'WhatsApp ઉપાડ રસીદ અને સૂચના',
                            hi: 'WhatsApp अग्रिम (उपाड़) रसीद व अलर्ट',
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF14532D),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: waGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEW FEATURE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: waGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppStrings.t(_appLanguage,
                        en: 'Configuration for sending detailed advance payment receipts to employees via WhatsApp',
                        gu: 'કર્મચારીને આપેલ એડવાન્સ ઉપાડની સંપૂર્ણ વિગતવાર રસીદ WhatsApp પર મોકલવા માટેનું સેટઅપ',
                        hi: 'कर्मचारी को दिए गए अग्रिम उपाड़ की विस्तृत रसीद WhatsApp पर भेजने हेतु सेटअप',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.visibility_rounded, size: 16, color: waGreen),
                label: Text(AppStrings.t(_appLanguage, en: 'Preview Sample', gu: 'નમૂનો જુઓ', hi: 'नमूना देखें')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: waGreen,
                  side: const BorderSide(color: waGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showSampleWhatsAppDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Two column configurations
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Sender Phone Number
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.contact_phone_outlined, size: 16, color: waGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppStrings.t(_appLanguage,
                              en: 'Manager / Owner Mobile Number (Sender Phone) *',
                              gu: 'મેનેજર / માલિકનો મોબાઇલ નંબર (Sender Phone) *',
                              hi: 'मैनेजर / मालिक का मोबाइल नंबर (Sender Phone) *',
                            ),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelTextColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _senderPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: AppStrings.t(_appLanguage,
                          en: 'e.g. 9876543210 (Manager Number)',
                          gu: 'દા.ત. 9876543210 (મેનેજર નંબર)',
                          hi: 'उदा. 9876543210 (मैनेजर नंबर)',
                        ),
                        prefixIcon: const Icon(Icons.phone_rounded, color: waGreen),
                        filled: true,
                        fillColor: inputFill,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: waGreen, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.t(_appLanguage,
                        en: 'This number will be included in the advance receipt for contact. If left blank, you will be prompted when sending.',
                        gu: 'આ નંબર ઉપાડ રસીદમાં સંપર્ક તરીકે જોડાશે. જો ખાલી હશે તો મોકલતી વખતે પૂછશે.',
                        hi: 'यह नंबर उपाड़ रसीद में संपर्क के रूप में जुड़ेगा। यदि खाली रहा तो भेजते समय पूछा जाएगा।',
                      ),
                      style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),

              // Right: Default Message Language
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.translate_rounded, size: 16, color: waGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppStrings.t(_appLanguage,
                              en: 'Default Message Language',
                              gu: 'ડિફૉલ્ટ રસીદ ભાષા',
                              hi: 'डिफ़ॉल्ट रसीद भाषा',
                            ),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelTextColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: ['English', 'Hindi', 'Gujarati', 'Both'].contains(_whatsappMessageLanguage)
                          ? _whatsappMessageLanguage
                          : 'English',
                      dropdownColor: dropdownBg,
                      style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputFill,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: waGreen, width: 2)),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'English',
                          child: Text(
                            AppStrings.t(_appLanguage, en: 'English (Dear Sir / Madam)', gu: 'અંગ્રેજી (Dear Sir / Madam)', hi: 'अंग्रेजी (Dear Sir / Madam)'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Gujarati',
                          child: Text(
                            AppStrings.t(_appLanguage, en: 'Gujarati (Respected Shri / Bahen)', gu: 'ગુજરાતી (માનવાચક શ્રી / બહેન)', hi: 'गुजराती (માનવાચક શ્રી / બહેન)'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Hindi',
                          child: Text(
                            AppStrings.t(_appLanguage, en: 'Hindi (Respected Sir / Madam)', gu: 'હિન્દી (આદરણીય શ્રી / મેડમ)', hi: 'हिन्दी (आदरणीय श्री / मैडम)'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Both',
                          child: Text(
                            AppStrings.t(_appLanguage, en: 'Both (Hindi + English)', gu: 'બંને (હિન્દી + અંગ્રેજી)', hi: 'दोनों (हिन्दी + English)'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _whatsappMessageLanguage = val);
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.t(_appLanguage,
                        en: 'Salutation is automatically customized based on employee gender.',
                        gu: 'કર્મચારીના લિંગ અનુસાર સંબોધન આપોઆપ સેટ થશે.',
                        hi: 'कर्मचारी के लिंग अनुसार संबोधन अपने आप सेट होगा।',
                      ),
                      style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Auto-send Toggle Container (Default: OFF as requested)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  _whatsappAutoSend ? Icons.send_rounded : Icons.touch_app_rounded,
                  color: _whatsappAutoSend ? waGreen : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t(_appLanguage,
                          en: 'Auto-send Receipt on Advance Entry',
                          gu: 'ઉપાડ નોંધતાં જ આપોઆપ WhatsApp ખોલો',
                          hi: 'उपाड़ दर्ज करते ही अपने आप WhatsApp खोलें',
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _whatsappAutoSend
                            ? AppStrings.t(_appLanguage,
                                en: 'ON: Employee WhatsApp opens immediately when a new advance is saved.',
                                gu: 'ચાલુ (ON): નવો ઉપાડ સેવ થતાં જ કર્મચારીનું WhatsApp સીધું ખૂલશે.',
                                hi: 'चालू (ON): नया उपाड़ सेव होते ही कर्मचारी का WhatsApp तुरंत खुलेगा।',
                              )
                            : AppStrings.t(_appLanguage,
                                en: 'OFF (Default): Advance is saved to database. WhatsApp is sent manually via button.',
                                gu: 'બંધ (OFF): ઉપાડ માત્ર ડેટાબેઝમાં નોંધાશે. WhatsApp મેન્યુઅલ બટનથી જ મોકલાશે.',
                                hi: 'बंद (OFF): उपाड़ सिर्फ डेटाबेस में दर्ज होगा। WhatsApp मैन्युअल बटन से भेजा जाएगा।',
                              ),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _whatsappAutoSend ? waGreen : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          fontWeight: _whatsappAutoSend ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch.adaptive(
                  value: _whatsappAutoSend,
                  activeTrackColor: waGreen.withValues(alpha: 0.5),
                  activeThumbColor: waGreen,
                  onChanged: (val) => setState(() => _whatsappAutoSend = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // View Sent Message Logs Action Tile
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: waGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: waGreen.withValues(alpha: 0.25)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, size: 20, color: waGreen),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t(_appLanguage,
                            en: 'WhatsApp Sent Message Logs',
                            gu: 'મોકલેલા WhatsApp મેસેજ રેકોર્ડ',
                            hi: 'भेजे गए WhatsApp मैसेज रिकॉर्ड',
                          ),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          AppStrings.t(_appLanguage,
                            en: 'Total ${context.watch<ProductionProvider>().whatsappLogs.length} messages logged',
                            gu: 'કુલ ${context.watch<ProductionProvider>().whatsappLogs.length} મેસેજ રેકોર્ડ થયેલ છે',
                            hi: 'कुल ${context.watch<ProductionProvider>().whatsappLogs.length} मैसेज रिकॉर्ड हैं',
                          ),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: waGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: Text(AppStrings.t(_appLanguage, en: 'View Logs', gu: 'રેકોર્ડ જુઓ', hi: 'लॉग देखें')),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => const WhatsAppHistoryDialog(),
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

  void _showSampleWhatsAppDialog(BuildContext context) {
    final sampleHindi = WhatsAppService.generateUpadMessage(
      language: _whatsappMessageLanguage,
      companyName: 'OM MAVTAR GROUP',
      employeeName: 'Ramesh Patel',
      role: 'Operator',
      gender: 'Male',
      upadAmount: 2000,
      date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      notes: AppStrings.t(_appLanguage, en: 'Festival Advance (Diwali Advance)', gu: 'તહેવાર એડવાન્સ (દિવાળી ઉપાડ)', hi: 'त्योहार अग्रिम (दिवाली उपाड़)'),
      monthlySalary: 22000,
      totalPendingUpad: 4000,
      remainingSalary: 18000,
      senderPhone: _senderPhoneCtrl.text.trim().isNotEmpty ? _senderPhoneCtrl.text.trim() : '9876543210',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
              const SizedBox(width: 10),
              Text(
                AppStrings.t(_appLanguage, en: 'WhatsApp Receipt Sample', gu: 'WhatsApp રસીદ નમૂનો', hi: 'WhatsApp रसीद नमूना'),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          content: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 450),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECE5DD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1D7DB)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                sampleHindi,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  color: Color(0xFF111B21),
                  height: 1.4,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.t(_appLanguage, en: 'Close', gu: 'બંધ કરો', hi: 'बंद करें')),
            ),
          ],
        );
      },
    );
  }
}
