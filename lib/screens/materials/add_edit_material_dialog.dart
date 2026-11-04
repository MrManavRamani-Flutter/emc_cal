import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../models/material_item.dart';
import '../../models/material_product.dart';
import '../../models/supplier.dart';
import '../../providers/production_provider.dart';
import '../../widgets/searchable_product_picker.dart';
import '../../widgets/searchable_supplier_picker.dart';
import '../../widgets/app_svg_icon.dart';
import 'add_edit_material_product_dialog.dart';
import 'add_edit_supplier_dialog.dart';

/// Helper draft model representing an item row within a multi-item Challan
class ChallanItemDraft {
  String category;
  late TextEditingController productNameCtrl;
  late TextEditingController itemTypeCtrl;
  late TextEditingController mtrCtrl;
  late TextEditingController mmCtrl;
  late TextEditingController qtyCtrl;
  late TextEditingController rateCtrl;
  MaterialProduct? selectedProduct;
  VoidCallback? onUpdate;

  ChallanItemDraft({
    String? category,
    String? productName,
    String? itemType,
    double? mtr,
    double? mm,
    double? qty,
    double? rate,
    String? notes,
    this.onUpdate,
  }) : category = category ?? 'Sequence' {
    productNameCtrl = TextEditingController(text: productName ?? '');
    itemTypeCtrl = TextEditingController(text: itemType ?? 'piece');
    mtrCtrl = TextEditingController(text: (mtr != null && mtr > 0) ? mtr.toStringAsFixed(2) : '');
    mmCtrl = TextEditingController(text: (mm != null && mm > 0) ? mm.toStringAsFixed(2) : '');
    qtyCtrl = TextEditingController(text: (qty != null && qty > 0) ? qty.toStringAsFixed(2) : '');
    rateCtrl = TextEditingController(text: (rate != null && rate > 0) ? rate.toStringAsFixed(2) : '');

    qtyCtrl.addListener(_notify);
    rateCtrl.addListener(_notify);
  }

  void _notify() {
    if (onUpdate != null) onUpdate!();
  }

  double get qty => double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
  double get rate => double.tryParse(rateCtrl.text.trim()) ?? 0.0;
  double get mtr => double.tryParse(mtrCtrl.text.trim()) ?? 0.0;
  double get mm => double.tryParse(mmCtrl.text.trim()) ?? 0.0;
  double get amount => qty * rate;

  void dispose() {
    qtyCtrl.removeListener(_notify);
    rateCtrl.removeListener(_notify);
    productNameCtrl.dispose();
    itemTypeCtrl.dispose();
    mtrCtrl.dispose();
    mmCtrl.dispose();
    qtyCtrl.dispose();
    rateCtrl.dispose();
  }
}

class AddEditMaterialDialog extends StatefulWidget {
  final MaterialItem? initialItem;
  final String? defaultCategory;
  final String? defaultChallanNo;
  final String? defaultSupplier;
  final DateTime? defaultDate;
  final bool asScreen;
  final VoidCallback? onBack;
  final void Function(String primaryCategory, String challanNo)? onSaved;

  const AddEditMaterialDialog({
    super.key,
    this.initialItem,
    this.defaultCategory,
    this.defaultChallanNo,
    this.defaultSupplier,
    this.defaultDate,
    this.asScreen = false,
    this.onBack,
    this.onSaved,
  });

  @override
  State<AddEditMaterialDialog> createState() => _AddEditMaterialDialogState();
}

class _AddEditMaterialDialogState extends State<AddEditMaterialDialog> {
  final _formKey = GlobalKey<FormState>();

  static final NumberFormat currencyFormatter = NumberFormat('#,##,##0.00');
  static final NumberFormat qtyFormatter = NumberFormat('#,##,##0.##');

  late TextEditingController _challanNoCtrl;
  late TextEditingController _supplierNameCtrl;
  late DateTime _selectedDate;

  final List<ChallanItemDraft> _items = [];
  final List<String> _categories = ['Sequence', 'Beads', 'Thread'];
  final List<String> _units = ['piece', 'cd', 'firka', 'cone', 'packet', 'box', 'kg', 'meter', 'roll'];

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;

    _challanNoCtrl = TextEditingController(text: item?.challanNo ?? widget.defaultChallanNo ?? '');
    _supplierNameCtrl = TextEditingController(text: item?.supplierName ?? widget.defaultSupplier ?? '');
    _selectedDate = item?.date ?? widget.defaultDate ?? DateTime.now();

    if (item != null) {
      var cat = item.category;
      if (cat.toLowerCase() == 'dhaga' || cat.toLowerCase() == 'daga') {
        cat = 'Thread';
      }
      _items.add(ChallanItemDraft(
        category: cat,
        productName: item.productName,
        itemType: item.itemType,
        mtr: item.mtr,
        mm: item.mm,
        qty: item.qty,
        rate: item.rate,
        notes: item.notes,
        onUpdate: () => setState(() {}),
      ));
    } else {
      var cat = widget.defaultCategory ?? 'Sequence';
      if (cat.toLowerCase() == 'dhaga' || cat.toLowerCase() == 'daga') {
        cat = 'Thread';
      }
      _items.add(ChallanItemDraft(
        category: cat,
        onUpdate: () => setState(() {}),
      ));
    }
  }

  @override
  void dispose() {
    _challanNoCtrl.dispose();
    _supplierNameCtrl.dispose();
    for (final it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  void _addItem([String? category]) {
    setState(() {
      final lastCategory = _items.isNotEmpty ? _items.last.category : (category ?? 'Sequence');
      _items.add(ChallanItemDraft(
        category: category ?? lastCategory,
        onUpdate: () => setState(() {}),
      ));
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(context.read<ProductionProvider>().settings.appLanguage, en: 'At least 1 product required in challan', gu: 'ચલાનમાં ઓછામાં ઓછી ૧ પ્રોડક્ટ હોવી જરૂરી છે', hi: 'चालान में कम से कम 1 उत्पाद होना आवश्यक है'))),
      );
      return;
    }
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  double get grandTotalBill => _items.fold(0.0, (sum, i) => sum + i.amount);
  double get grandTotalQty => _items.fold(0.0, (sum, i) => sum + i.qty);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _openAddNewProductDialog(String category) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditMaterialProductDialog(defaultCategory: category),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openAddNewSupplierDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const AddEditSupplierDialog(),
    ).then((val) {
      if (mounted) {
        if (val is Supplier) {
          setState(() => _supplierNameCtrl.text = val.name);
        } else {
          setState(() {});
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final challanNo = _challanNoCtrl.text.trim().isEmpty ? '-' : _challanNoCtrl.text.trim();
    final supplierName = _supplierNameCtrl.text.trim().isEmpty ? '-' : _supplierNameCtrl.text.trim();

    final lang = context.read<ProductionProvider>().settings.appLanguage;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(lang, en: 'Please add at least 1 item', gu: 'કૃપા કરીને ઓછામાં ઓછી ૧ પ્રોડક્ટ ઉમેરો', hi: 'कृपया कम से कम 1 उत्पाद जोड़ें'))),
      );
      return;
    }

    for (int i = 0; i < _items.length; i++) {
      final it = _items[i];
      if (it.productNameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t(lang, en: 'Item #${i + 1}: Product name is required', gu: 'આઈટમ #${i + 1}: પ્રોડક્ટ નું નામ દાખલ કરો', hi: 'आइटम #${i + 1}: उत्पाद का नाम आवश्यक है')),
            backgroundColor: AppTheme.dangerRedDark,
          ),
        );
        return;
      }
      if (it.qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t(lang, en: 'Item #${i + 1} (${it.productNameCtrl.text.trim()}): Qty must be > 0', gu: 'આઈટમ #${i + 1} (${it.productNameCtrl.text.trim()}): જથ્થો 0 થી વધુ હોવો જોઈએ', hi: 'आइटम #${i + 1} (${it.productNameCtrl.text.trim()}): मात्रा 0 से अधिक होनी चाहिए')),
            backgroundColor: AppTheme.dangerRedDark,
          ),
        );
        return;
      }
      if (it.rate < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t(lang, en: 'Item #${i + 1}: Valid rate is required', gu: 'આઈટમ #${i + 1}: ભાવ (Rate) યોગ્ય હોવો જોઈએ', hi: 'आइटम #${i + 1}: सही दर आवश्यक है')),
            backgroundColor: AppTheme.dangerRedDark,
          ),
        );
        return;
      }
    }

    final provider = context.read<ProductionProvider>();

    if (widget.initialItem != null) {
      final first = _items.first;
      final updated = MaterialItem(
        id: widget.initialItem!.id,
        challanNo: challanNo,
        supplierName: supplierName,
        date: _selectedDate,
        category: first.category,
        productName: first.productNameCtrl.text.trim().toUpperCase(),
        itemType: first.itemTypeCtrl.text.trim().isEmpty ? 'piece' : first.itemTypeCtrl.text.trim().toLowerCase(),
        mtr: first.mtr,
        mm: first.mm,
        qty: first.qty,
        rate: first.rate,
        amount: first.amount,
        usedQty: widget.initialItem!.usedQty,
        notes: '',
      );
      await provider.updateMaterialItem(updated);

      if (_items.length > 1) {
        final additionalItems = _items.sublist(1).map((it) {
          return MaterialItem(
            challanNo: challanNo,
            supplierName: supplierName,
            date: _selectedDate,
            category: it.category,
            productName: it.productNameCtrl.text.trim().toUpperCase(),
            itemType: it.itemTypeCtrl.text.trim().isEmpty ? 'piece' : it.itemTypeCtrl.text.trim().toLowerCase(),
            mtr: it.mtr,
            mm: it.mm,
            qty: it.qty,
            rate: it.rate,
            amount: it.amount,
            notes: '',
          );
        }).toList();
        await provider.insertMaterialItems(additionalItems);
      }
    } else {
      final newItems = _items.map((it) {
        return MaterialItem(
          challanNo: challanNo,
          supplierName: supplierName,
          date: _selectedDate,
          category: it.category,
          productName: it.productNameCtrl.text.trim().toUpperCase(),
          itemType: it.itemTypeCtrl.text.trim().isEmpty ? 'piece' : it.itemTypeCtrl.text.trim().toLowerCase(),
          mtr: it.mtr,
          mm: it.mm,
          qty: it.qty,
          rate: it.rate,
          amount: it.amount,
          notes: '',
        );
      }).toList();

      await provider.insertMaterialItems(newItems);
    }

    if (mounted) {
      final savedCat = _items.isNotEmpty ? _items.first.category : (widget.defaultCategory ?? 'Sequence');
      if (widget.onSaved != null) {
        widget.onSaved!(savedCat, challanNo);
      } else if (widget.onBack != null) {
        widget.onBack!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.t(lang,
              en: 'Challan #$challanNo (${_items.length} items, total: ₹${currencyFormatter.format(grandTotalBill)}) saved successfully!',
              gu: 'ચલાન #$challanNo (${_items.length} આઈટમ, કુલ બિલ: ₹${currencyFormatter.format(grandTotalBill)}) સફળતાપૂર્વક સાચવાઈ ગયું!',
              hi: 'चालान #$challanNo (${_items.length} आइटम, कुल: ₹${currencyFormatter.format(grandTotalBill)}) सफलतापूर्वक सहेजा गया!',
            ),
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

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Sequence':
        return const Color(0xFF2563EB); // Royal Blue
      case 'Beads':
        return const Color(0xFF8B5CF6); // Purple
      case 'Thread':
      case 'Dhaga':
        return const Color(0xFF10B981); // Emerald Green
      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Sequence':
        return Icons.auto_awesome_rounded;
      case 'Beads':
        return Icons.blur_on_rounded;
      case 'Thread':
      case 'Dhaga':
        return Icons.gesture_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);
    final isEditing = widget.initialItem != null;
    final lang = provider.settings.appLanguage;

    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Challan Header Details (Date, Challan #, Supplier, Notes)
          _buildChallanHeaderCard(context, provider, accent, isDark),
          const SizedBox(height: 18),

          // Section 2: Items List
          _buildItemsSectionHeader(context, accent),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (ctx, index) {
              return _buildItemCard(ctx, provider, index, _items[index], accent, isDark);
            },
          ),
          const SizedBox(height: 14),

          // Add Another Item Button (Dashed / Polished Card)
          _buildAddRowCard(context, accent, isDark),
          const SizedBox(height: 20),

          // Section 3: Grand Total Bill Summary Card
          _buildGrandTotalBillCard(context, accent, isDark, isEditing),
        ],
      ),
    );

    if (widget.asScreen) {
      return Container(
        color: Colors.transparent,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header with Back Button and Quick Save
              _buildTopHeaderBar(context, accent, isDark, isEditing),
              const SizedBox(height: 18),

              formContent,
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppTheme.cardBg(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: accent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? AppStrings.t(lang, en: 'Edit Purchase Material Entry', gu: 'ખરીદી મટીરીયલ એડિટ', hi: 'खरीद सामग्री प्रविष्टि संपादित करें')
                                : AppStrings.t(lang, en: 'Raw Material Purchase Challan Entry', gu: 'નવું કાચો માલ ખરીદી ચલણ બિલ', hi: 'कच्चा माल खरीद चालान बिल'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          Text(
                            AppStrings.t(lang,
                              en: 'Raw materials purchased from supplier • Company will pay this bill to vendor',
                              gu: 'વેપારી પાસેથી ખરીદેલ કાચા માલની એન્ટ્રી • કંપની દ્વારા સપ્લાયરને ચૂકવવાપાત્ર બિલ',
                              hi: 'सप्लायर से खरीदे गए कच्चे माल की प्रविष्टि • कंपनी द्वारा सप्लायर को देय बिल'),
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
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 16),

                formContent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Top Screen Bar
  Widget _buildTopHeaderBar(BuildContext context, Color accent, bool isDark, bool isEditing) {
    return Row(
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
            gradient: LinearGradient(
              colors: [accent.withValues(alpha: 0.25), accent.withValues(alpha: 0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.receipt_long_rounded, size: 22, color: accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing
                    ? AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Edit Purchase Material Entry', gu: 'ખરીદી મટીરીયલ એડિટ', hi: 'खरीद सामग्री प्रविष्टि संपादित करें')
                    : AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'New Material Purchase Challan & Inward Bill', gu: 'નવું કાચો માલ ખરીદી ચલણ બિલ', hi: 'नया कच्चा माल खरीद चालान बिल'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage,
                  en: 'Raw materials purchased from supplier (Dhaga, Sequence, Beads) • Multi-product purchase bill payable to vendor',
                  gu: 'સપ્લાયર પાસેથી કાચા માલની ખરીદી (દોરા, સીક્વન્સ, મોતી) • વેપારીને ચૂકવવાપાત્ર ખરીદી બિલ',
                  hi: 'सप्लायर से कच्चा माल खरीद (धागा, सीक्वेंस, मोती) • सप्लायर को देय खरीद बिल'),
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
              ),
            ],
          ),
        ),

        // Live Total Badge on Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSubtle(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage,
                  en: 'Purchase Bill: ',
                  gu: 'કુલ ખરીદી બિલ: ',
                  hi: 'कुल खरीद बिल: '),
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textMuted(context)),
              ),
              Text(
                '₹ ${currencyFormatter.format(grandTotalBill)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.successGreenDark),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        OutlinedButton(
          onPressed: _handleCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textMuted(context),
            side: BorderSide(color: AppTheme.border(context)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
        ),
        const SizedBox(width: 10),

        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_circle_rounded, size: 18),
          label: Text(isEditing
              ? AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Update Purchase Challan', gu: 'ખરીદી ચલણ અપડેટ', hi: 'खरीद चालान अपडेट करें')
              : AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Save Purchase Challan', gu: 'ખરીદી ચલણ સાચવો', hi: 'खरीद चालान सहेजें')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successGreenDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  // 1. Challan & Supplier Header Card
  Widget _buildChallanHeaderCard(BuildContext context, ProductionProvider provider, Color accent, bool isDark) {
    final hintColor = AppTheme.hintColor(context);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.storefront_rounded, size: 17, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: '1. Challan & Supplier Details', gu: '૧. ચલાન અને સપ્લાયર વિગત', hi: '1. चालान एवं सप्लायर विवरण'),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                  letterSpacing: -0.1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link_rounded, size: 13, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      'Common Supplier for all items below',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fields Grid: Date, Challan #, Supplier Name, Notes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Picker
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.get('challanDate', context.read<ProductionProvider>().settings.appLanguage)} *',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSubtle(context),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 15, color: accent),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd-MM-yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Challan No
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.get('challanNo', context.read<ProductionProvider>().settings.appLanguage)} *',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _challanNoCtrl,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Challan # is required' : null,
                      decoration: InputDecoration(
                        hintText: AppStrings.t(context.read<ProductionProvider>().settings.appLanguage,
                            en: 'e.g. 1086, CH-4091', gu: 'દા.ત. 1086, CH-4091', hi: 'उदा. 1086, CH-4091'),
                        hintStyle: TextStyle(color: hintColor, fontSize: 12),
                        prefixIcon: const Icon(Icons.receipt_rounded, size: 17),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Supplier Name (Picker & Master Add)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${AppStrings.get('supplierParty', context.read<ProductionProvider>().settings.appLanguage)} *',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                        ),
                        InkWell(
                          onTap: _openAddNewSupplierDialog,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, size: 12, color: accent),
                                const SizedBox(width: 3),
                                Text(
                                  AppStrings.get('newPartyMaster', context.read<ProductionProvider>().settings.appLanguage),
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: accent),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SearchableSupplierPicker(
                      suppliers: provider.suppliers,
                      selectedSupplierName: _supplierNameCtrl.text,
                      onSelected: (supplier) {
                        setState(() {
                          _supplierNameCtrl.text = supplier.name;
                        });
                      },
                      onAddNew: _openAddNewSupplierDialog,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Items Section Header
  Widget _buildItemsSectionHeader(BuildContext context, Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.inventory_2_rounded, size: 17, color: accent),
        ),
        const SizedBox(width: 10),
        Text(
          AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: '2. Challan Items & Products', gu: '૨. ચલાનની પ્રોડક્ટ્સ', hi: '2. चालान उत्पाद एवं सामग्री'),
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary(context),
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_items.length} ${_items.length == 1 ? "Product" : "Products"} Added',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _addItem(),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  // Individual Product Item Card
  Widget _buildItemCard(
    BuildContext context,
    ProductionProvider provider,
    int index,
    ChallanItemDraft item,
    Color accent,
    bool isDark,
  ) {
    final hintColor = AppTheme.hintColor(context);
    final catColor = _getCategoryColor(item.category);
    final categoryProducts = provider.getProductsByCategory(item.category);
    final lang = provider.settings.appLanguage;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: catColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Card Header Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: isDark ? 0.14 : 0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
              border: Border(
                bottom: BorderSide(color: catColor.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                // Item Number Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: catColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    'Item #${index + 1}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Category Switcher Pills
                ..._categories.map((cat) {
                  final isSelected = item.category == cat;
                  final cColor = _getCategoryColor(cat);
                  final cIcon = _getCategoryIcon(cat);

                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          item.category = cat;
                          item.selectedProduct = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? cColor : AppTheme.surfaceSubtle(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? cColor : AppTheme.border(context),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cIcon, size: 12, color: isSelected ? Colors.white : cColor),
                            const SizedBox(width: 5),
                            Text(
                              AppStrings.categoryName(cat, lang),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.white : AppTheme.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const Spacer(),

                // Live Subtotal Display Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: catColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Item Subtotal: ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted(context)),
                      ),
                      Text(
                        '₹ ${currencyFormatter.format(item.amount)}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: catColor,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_items.length > 1) ...[
                  const SizedBox(width: 10),
                  Tooltip(
                    message: 'Remove Item #${index + 1}',
                    child: InkWell(
                      onTap: () => _removeItem(index),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Item Card Body Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Product Selection, Product Name, and Unit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Master Picker
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Select from Master', gu: 'પ્રોડક્ટ પસંદ કરો', hi: 'मास्टर से चुनें'),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                              ),
                              InkWell(
                                onTap: () => _openAddNewProductDialog(item.category),
                                child: Text(
                                  'New Master',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: catColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          SearchableProductPicker(
                            products: categoryProducts,
                            selectedProduct: item.selectedProduct,
                            category: item.category,
                            onSelected: (prod) {
                              setState(() {
                                item.selectedProduct = prod;
                                item.productNameCtrl.text = prod.name.toUpperCase();
                                item.itemTypeCtrl.text = prod.unit;
                                if (prod.defaultRate > 0) {
                                  item.rateCtrl.text = prod.defaultRate.toStringAsFixed(2);
                                }
                                if (prod.defaultMtr > 0) {
                                  item.mtrCtrl.text = prod.defaultMtr.toStringAsFixed(2);
                                }
                                if (prod.defaultMm > 0) {
                                  item.mmCtrl.text = prod.defaultMm.toStringAsFixed(2);
                                }
                              });
                            },
                            onAddNew: () => _openAddNewProductDialog(item.category),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Editable Product Name
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage,
                                en: 'Product Name / Description *',
                                gu: 'પ્રોડક્ટનું નામ *',
                                hi: 'उत्पाद का नाम *'),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: item.productNameCtrl,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Product name required' : null,
                            decoration: InputDecoration(
                              hintText: AppStrings.t(context.read<ProductionProvider>().settings.appLanguage,
                                  en: 'e.g. Sonavale 1500, Open Cut, Zari Gold',
                                  gu: 'દા.ત. સોનાવાલે 1500, ઓપન કટ, ઝરી ગોલ્ડ',
                                  hi: 'उदा. Sonavale 1500, Open Cut, Zari Gold'),
                              hintStyle: TextStyle(color: hintColor, fontSize: 11.5),
                              prefixIcon: const Icon(Icons.style_rounded, size: 16),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Unit / Form
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Unit / Form', gu: 'એકમ', hi: 'इकाई'),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceSubtle(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border(context)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _units.contains(item.itemTypeCtrl.text.toLowerCase())
                                    ? item.itemTypeCtrl.text.toLowerCase()
                                    : 'piece',
                                isExpanded: true,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => item.itemTypeCtrl.text = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Line 2: Qty, Rate, Mtr, MM, and Live Math Formula Box
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quantity
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Qty *', gu: 'જથ્થો *', hi: 'मात्रा *'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: item.qtyCtrl,
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              final val = double.tryParse(v ?? '');
                              if (val == null || val <= 0) return 'Qty > 0';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: AppStrings.t(context.read<ProductionProvider>().settings.appLanguage,
                                  en: 'e.g. 100', gu: 'દા.ત. 100', hi: 'उदा. 100'),
                              hintStyle: TextStyle(color: hintColor, fontSize: 11.5),
                              prefixIcon: const Icon(Icons.numbers_rounded, size: 16),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Rate
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Rate (₹) *', gu: 'દર (₹) *', hi: 'દર (₹) *'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: item.rateCtrl,
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              final val = double.tryParse(v ?? '');
                              if (val == null || val < 0) return 'Rate >= 0';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: AppStrings.t(context.read<ProductionProvider>().settings.appLanguage,
                                  en: 'e.g. 25.00', gu: 'દા.ત. 25.00', hi: 'उदा. 25.00'),
                              hintStyle: TextStyle(color: hintColor, fontSize: 11.5),
                              prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 16),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Mtr (Optional)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Mtr', gu: 'મીટર', hi: 'मीटर'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: item.mtrCtrl,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Mtr',
                              hintStyle: TextStyle(color: hintColor, fontSize: 11),
                              prefixIcon: const Icon(Icons.straighten_rounded, size: 15),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // MM (Optional)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Size (MM)', gu: 'સાઈઝ (MM)', hi: 'साइज (MM)'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: item.mmCtrl,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'MM',
                              hintStyle: TextStyle(color: hintColor, fontSize: 11),
                              prefixIcon: const Icon(Icons.fit_screen_rounded, size: 15),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Live Math Formula Calculation Card
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Calculation', gu: 'ગણતરી', hi: 'गणना'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                          const SizedBox(height: 5),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: isDark ? 0.12 : 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: catColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calculate_rounded, size: 16, color: catColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${item.qty > 0 ? qtyFormatter.format(item.qty) : "0"} × ₹${item.rate > 0 ? currencyFormatter.format(item.rate) : "0.00"} = ₹ ${currencyFormatter.format(item.amount)}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: catColor,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add Another Row Action Card
  Widget _buildAddRowCard(BuildContext context, Color accent, bool isDark) {
    return InkWell(
      onTap: () => _addItem(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: 0.35),
            style: BorderStyle.solid,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, size: 18, color: accent),
            ),
            const SizedBox(width: 10),
            Text(
              AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Add Another Product to this Challan', gu: 'આ ચલાનમાં બીજી પ્રોડક્ટ ઉમેરો', hi: 'इस चालान में अन्य उत्पाद जोड़ें'),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Grand Total Bill Summary Card
  Widget _buildGrandTotalBillCard(BuildContext context, Color accent, bool isDark, bool isEditing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F291E), const Color(0xFF0A1F16), const Color(0xFF0F172A)]
              : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successGreenDark.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successGreenDark.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successGreenDark.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppTheme.successGreenDark, size: 28),
          ),
          const SizedBox(width: 16),

          // Total Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      AppStrings.t(context.read<ProductionProvider>().settings.appLanguage,
                        en: 'PURCHASE BILL PAYABLE TO SUPPLIER',
                        gu: 'સપ્લાયરને ચૂકવવાપાત્ર કુલ ખરીદી બિલ',
                        hi: 'सप्लायर को देय कुल खरीद बिल'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white70 : const Color(0xFF166534),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreenDark.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_items.length} ${_items.length == 1 ? "Product" : "Products"} | ${qtyFormatter.format(grandTotalQty)} Units',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successGreenDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '₹ ${currencyFormatter.format(grandTotalBill)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.successGreenDark,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.t(context.read<ProductionProvider>().settings.appLanguage,
                    en: 'Raw material purchase bill payable by OM MAVTAR GROUP to supplier',
                    gu: 'કંપની દ્વારા વેપારીને ચૂકવવાપાત્ર કાચા માલનું ખરીદી બિલ',
                    hi: 'कच्चे माल का खरीद बिल जो कंपनी द्वारा सप्लायर को देय है'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xFF15803D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          OutlinedButton(
            onPressed: _handleCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              side: BorderSide(color: AppTheme.border(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें'), style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: Text(
              isEditing
                  ? AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Update Purchase Challan', gu: 'ખરીદી ચલણ અપડેટ', hi: 'खरीद चालान अपडेट करें')
                  : AppStrings.t(context.watch<ProductionProvider>().settings.appLanguage, en: 'Save Purchase Challan', gu: 'ખરીદી ચલણ સાચવો', hi: 'खरीद चालान सहेजें'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreenDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 3,
            ),
          ),
        ],
      ),
    );
  }
}
