import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/production_provider.dart';
import '../../widgets/widgets.dart';

class RatesHeadsScreen extends StatefulWidget {
  const RatesHeadsScreen({super.key});

  @override
  State<RatesHeadsScreen> createState() => _RatesHeadsScreenState();
}

class _RatesHeadsScreenState extends State<RatesHeadsScreen> {
  final TextEditingController _rateInputCtrl = TextEditingController();
  final TextEditingController _headsInputCtrl = TextEditingController();

  String? _rateError;
  String? _headsError;

  @override
  void dispose() {
    _rateInputCtrl.dispose();
    _headsInputCtrl.dispose();
    super.dispose();
  }

  void _addRate() {
    final text = _rateInputCtrl.text.replaceAll(',', '').trim();
    final error = ProductionProvider.validateRate(text);
    if (error != null) {
      setState(() => _rateError = error);
      return;
    }

    final val = double.parse(text);
    final provider = context.read<ProductionProvider>();
    if (provider.settings.availableRates.contains(val)) {
      setState(() => _rateError = 'Rate already exists');
      return;
    }

    provider.addPresetRate(val);
    _rateInputCtrl.clear();
    setState(() => _rateError = null);
  }

  void _addHeads() {
    final text = _headsInputCtrl.text.replaceAll(',', '').trim();
    final error = ProductionProvider.validateHeads(text);
    if (error != null) {
      setState(() => _headsError = error);
      return;
    }

    final val = int.parse(text);
    final provider = context.read<ProductionProvider>();
    if (provider.settings.availableHeads.contains(val)) {
      setState(() => _headsError = 'Head count already exists');
      return;
    }

    provider.addPresetHead(val);
    _headsInputCtrl.clear();
    setState(() => _headsError = null);
  }

  Future<void> _confirmRemoveRate(double rate) async {
    final currency = context.read<ProductionProvider>().settings.currencySymbol;
    final confirm = await ConfirmDeleteDialog.show(
      context: context,
      title: 'Confirm Removal',
      message: 'Are you sure you want to remove rate $currency${rate.toStringAsFixed(2)} from available options?',
      confirmLabel: 'Remove',
    );
    if (confirm && mounted) {
      context.read<ProductionProvider>().removePresetRate(rate);
    }
  }

  Future<void> _confirmRemoveHead(int heads) async {
    final confirm = await ConfirmDeleteDialog.show(
      context: context,
      title: 'Confirm Removal',
      message: 'Are you sure you want to remove $heads heads from available head options?',
      confirmLabel: 'Remove',
    );
    if (confirm && mounted) {
      context.read<ProductionProvider>().removePresetHead(heads);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final settings = provider.settings;
    final currency = settings.currencySymbol;
    final isDark = settings.isDarkMode;
    final accent = AppTheme.parseColor(settings.themeColorHex);

    final inputFill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : AppTheme.slateBorder;
    final primaryTextColor = isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy;
    final labelTextColor = isDark ? const Color(0xFFE2E8F0) : AppTheme.textSecondary(context);

    InputDecoration inputDecor(String hint, String? error) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textMuted(context), fontSize: 13),
          errorText: error,
          filled: true,
          fillColor: inputFill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accent, width: 2)),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Card: Rate Options
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate Options',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor),
                      ),
                      const SizedBox(height: 16),

                      // List of rates
                      ...settings.availableRates.map((r) {
                        final isSelected = (settings.defaultRate - r).abs() < 0.001;
                        return AppListCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          isSelected: isSelected,
                          selectedColor: accent,
                          dense: true,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          title: Text(
                            r.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? accent : primaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: accent, size: 20)
                              : IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textMuted(context)),
                                  onPressed: () => _confirmRemoveRate(r),
                                  tooltip: 'Remove Rate',
                                ),
                          onTap: () {
                            provider.saveSettings(settings.copyWith(defaultRate: r));
                          },
                        );
                      }),
                      const SizedBox(height: 20),

                      // Custom Rate (₹)
                      Text(
                        'Custom Rate ($currency)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: labelTextColor),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _rateInputCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: primaryTextColor, fontSize: 13),
                              decoration: inputDecor('Enter rate', _rateError),
                              onSubmitted: (_) => _addRate(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _addRate,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Right Card: Head Options
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Head Options',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor),
                      ),
                      const SizedBox(height: 16),

                      // List of heads
                      ...settings.availableHeads.map((h) {
                        final isSelected = settings.defaultHeads == h;
                        return AppListCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          isSelected: isSelected,
                          selectedColor: accent,
                          dense: true,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          title: Text(
                            '$h',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? accent : primaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: accent, size: 20)
                              : IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textMuted(context)),
                                  onPressed: () => _confirmRemoveHead(h),
                                  tooltip: 'Remove Head Option',
                                ),
                          onTap: () {
                            provider.saveSettings(settings.copyWith(defaultHeads: h));
                          },
                        );
                      }),
                      const SizedBox(height: 20),

                      // Custom Head
                      Text(
                        'Custom Head',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: labelTextColor),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _headsInputCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: primaryTextColor, fontSize: 13),
                              decoration: inputDecor('Enter heads', _headsError),
                              onSubmitted: (_) => _addHeads(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _addHeads,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bottom info footnote
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textMuted(context)),
              const SizedBox(width: 8),
              Text(
                'You can manage default rates and head counts. Custom values can be added during entry.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
