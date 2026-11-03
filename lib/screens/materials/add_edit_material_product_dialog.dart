import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../models/material_product.dart';
import '../../providers/production_provider.dart';
import '../../widgets/app_svg_icon.dart';

class AddEditMaterialProductDialog extends StatefulWidget {
  final MaterialProduct? initialProduct;
  final String? defaultCategory;
  final bool asScreen;
  final VoidCallback? onBack;
  final ValueChanged<MaterialProduct>? onSaved;

  const AddEditMaterialProductDialog({
    super.key,
    this.initialProduct,
    this.defaultCategory,
    this.asScreen = false,
    this.onBack,
    this.onSaved,
  });

  @override
  State<AddEditMaterialProductDialog> createState() => _AddEditMaterialProductDialogState();
}

class _AddEditMaterialProductDialogState extends State<AddEditMaterialProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _mtrCtrl;
  late TextEditingController _mmCtrl;
  late String _category;
  late String _unit;

  final List<String> _categories = ['Sequence', 'Beads', 'Thread'];
  final List<String> _units = ['piece', 'pcs', 'cd', 'firka', 'cone', 'packet', 'box', 'kg', 'meter', 'roll'];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;

    var initCat = p?.category ?? widget.defaultCategory ?? 'Sequence';
    if (initCat.toLowerCase() == 'dhaga' || initCat.toLowerCase() == 'daga') {
      initCat = 'Thread';
    }
    _category = initCat;
    _unit = p?.unit ?? 'piece';
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _rateCtrl = TextEditingController(text: p != null ? p.defaultRate.toStringAsFixed(2) : '');
    _mtrCtrl = TextEditingController(text: p != null && p.defaultMtr > 0 ? p.defaultMtr.toStringAsFixed(2) : '');
    _mmCtrl = TextEditingController(text: p != null && p.defaultMm > 0 ? p.defaultMm.toStringAsFixed(2) : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rateCtrl.dispose();
    _mtrCtrl.dispose();
    _mmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProductionProvider>();
    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 0.0;
    final mtr = double.tryParse(_mtrCtrl.text.trim()) ?? 0.0;
    final mm = double.tryParse(_mmCtrl.text.trim()) ?? 0.0;

    final product = MaterialProduct(
      id: widget.initialProduct?.id,
      name: _nameCtrl.text.trim().toUpperCase(),
      category: _category,
      defaultRate: rate,
      unit: _unit,
      defaultMtr: mtr,
      defaultMm: mm,
      notes: '',
    );

    if (widget.initialProduct == null) {
      await provider.insertMaterialProduct(product);
    } else {
      await provider.updateMaterialProduct(product);
    }

    if (mounted) {
      if (widget.onSaved != null) {
        widget.onSaved!(product);
      } else if (widget.onBack != null) {
        widget.onBack!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(product);
      }
      final lang = context.read<ProductionProvider>().settings.appLanguage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialProduct == null
                ? AppStrings.t(lang, en: 'New product master added successfully!', gu: 'નવું પ્રોડક્ટ માસ્ટર સફળતાપૂર્વક ઉમેરાઈ ગયું!', hi: 'नया उत्पाद मास्टर सफलतापूर्वक जोड़ा गया!')
                : AppStrings.t(lang, en: 'Product master updated successfully!', gu: 'પ્રોડક્ટ માસ્ટર અપડેટ થઈ ગયું!', hi: 'उत्पाद मास्टर अपडेट हो गया!'),
          ),
          backgroundColor: AppTheme.successGreenDark,
        ),
      );
    }
  }

  void _handleCancel() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.parseColor(context.watch<ProductionProvider>().settings.themeColorHex);
    final isEditing = widget.initialProduct != null;
    final hintColor = AppTheme.hintColor(context);

    if (widget.asScreen) {
      return Container(
        color: Colors.transparent,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Row(
                children: [
                  Tooltip(
                    message: AppStrings.get('back', context.read<ProductionProvider>().settings.appLanguage),
                    child: InkWell(
                      onTap: _handleCancel,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSubtle(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: AppSvgIcon.back(size: 20, color: AppTheme.textPrimary(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.3 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.inventory_2_rounded, size: 24, color: accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isEditing ? 'Edit Product & Default Rate' : 'New Product Master Setup',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary(context),
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isEditing && widget.initialProduct?.id != null) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  '#ID: ${widget.initialProduct!.id}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                    color: accent,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure product defaults (rates, units, mm, mtr) to auto-fill material challans',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _handleCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textMuted(context),
                      side: BorderSide(color: AppTheme.border(context)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: Text(isEditing
                        ? AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Update Product', gu: 'પ્રોડક્ટ સુધારો', hi: 'उत्पाद अपडेट करें')
                        : AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Save Product', gu: 'પ્રોડક્ટ સાચવો', hi: 'उत्पाद सहेजें')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: AppTheme.contrastText(accent),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Form Container Card
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: _buildFormBody(context, accent, hintColor, isDark, isEditing),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppTheme.cardBg(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.inventory_2_rounded, color: accent, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Product & Rate' : 'Add Material Product Master',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                            Text(
                              AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage,
                                en: 'Configure product and its default rate here (One-time Setup)',
                                gu: 'અહીં એક વાર પ્રોડક્ટ અને તેનો ડિફૉલ્ટ ભાવ સેટ કરો',
                                hi: 'यहाँ एक बार प्रोडक्ट और उसकी डिफ़ॉल्ट दर सेट करें (One-time Setup)',
                              ),
                              style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted(context)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _handleCancel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  _buildFormBody(context, accent, hintColor, isDark, isEditing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormBody(BuildContext context, Color accent, Color hintColor, bool isDark, bool isEditing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category Selection Tabs
        Text(
          AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Category *', gu: 'કેટેગરી *', hi: 'श्रेणी (Category) *'),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
        ),
                const SizedBox(height: 8),
                Row(
                  children: _categories.map((cat) {
                    final isSelected = _category == cat;
                    Color catColor = cat == 'Sequence'
                        ? const Color(0xFF2563EB)
                        : cat == 'Beads'
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF059669);

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => setState(() => _category = cat),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? catColor.withValues(alpha: isDark ? 0.3 : 0.12)
                                  : AppTheme.surfaceSubtle(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? catColor : AppTheme.border(context),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                AppStrings.categoryName(cat, context.watch<ProductionProvider>().settings.appLanguage),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? catColor : AppTheme.textPrimary(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Product Name
                Text(
                  AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Product Name *', gu: 'પ્રોડક્ટનું નામ *', hi: 'उत्पाद का नाम *'),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
                  decoration: InputDecoration(
                    hintText: 'Ex: Open Cut, KM Chocolate 24, Sonavale 1500',
                    hintStyle: TextStyle(color: hintColor, fontSize: 12.5, fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.style_rounded, size: 18),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Default Rate & Unit / Form
                Row(
                  children: [
                    // Default Rate
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Default Rate (₹) *', gu: 'ડિફૉલ્ટ ભાવ (₹) *', hi: 'डिफ़ॉल्ट दर (₹) *'),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _rateCtrl,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              final val = double.tryParse(v ?? '');
                              if (val == null || val <= 0) return 'Valid rate required';
                              if (val > 1000000) return 'Rate max ₹10,00,000';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Ex: 85.00 / 18.00',
                              hintStyle: TextStyle(color: hintColor, fontSize: 12.5, fontWeight: FontWeight.normal),
                              prefixText: '₹ ',
                              prefixStyle: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600),
                              prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Unit / Form Dropdown
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit / Form *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _units.contains(_unit) ? _unit : 'piece',
                            isExpanded: true,
                            items: _units.map((u) {
                              return DropdownMenuItem(value: u, child: Text(u, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _unit = val);
                            },
                            decoration: const InputDecoration(
                              isDense: true,
                              prefixIcon: Icon(Icons.straighten_rounded, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Optional: Default MTR and MM
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Meter (MTR - Optional)', gu: 'મીટર (MTR - મરજિયાત)', hi: 'मीटर (MTR - वैकल्पिक)'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _mtrCtrl,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Ex: 190.00 / 1000',
                              hintStyle: TextStyle(color: hintColor, fontSize: 12.5, fontWeight: FontWeight.normal),
                              suffixText: 'm',
                              suffixStyle: TextStyle(color: AppTheme.textSecondary(context)),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Size (MM - Optional)', gu: 'સાઈઝ (MM - મરજિયાત)', hi: 'साइज (MM - वैकल्पिक)'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _mmCtrl,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Ex: 5.00 / 3.00',
                              hintStyle: TextStyle(color: hintColor, fontSize: 12.5, fontWeight: FontWeight.normal),
                              suffixText: 'mm',
                              suffixStyle: TextStyle(color: AppTheme.textSecondary(context)),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _handleCancel,
                      child: Text(AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें'), style: TextStyle(color: AppTheme.textMuted(context))),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: Text(isEditing
                          ? AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Update Product', gu: 'પ્રોડક્ટ સુધારો', hi: 'उत्पाद अपडेट करें')
                          : AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Save Product', gu: 'પ્રોડક્ટ સાચવો', hi: 'उत्पाद सहेजें')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: AppTheme.contrastText(accent),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            );
  }
}
