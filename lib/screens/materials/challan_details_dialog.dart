import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../data/pdf_exporter.dart';
import '../../models/challan_summary.dart';
import '../../models/material_item.dart';
import '../../models/supplier.dart';
import '../../providers/production_provider.dart';
import 'add_edit_material_dialog.dart';
import '../../widgets/app_svg_icon.dart';

class ChallanDetailsDialog extends StatefulWidget {
  final ChallanSummary challan;
  final bool asScreen;
  final VoidCallback? onBack;
  final ValueChanged<MaterialItem>? onEditItem;
  final VoidCallback? onAddItem;

  const ChallanDetailsDialog({
    super.key,
    required this.challan,
    this.asScreen = false,
    this.onBack,
    this.onEditItem,
    this.onAddItem,
  });

  @override
  State<ChallanDetailsDialog> createState() => _ChallanDetailsDialogState();
}

class _ChallanDetailsDialogState extends State<ChallanDetailsDialog> {
  bool _sortIdAscending = true;

  ChallanSummary get challan => widget.challan;
  bool get asScreen => widget.asScreen;
  VoidCallback? get onBack => widget.onBack;
  ValueChanged<MaterialItem>? get onEditItem => widget.onEditItem;
  VoidCallback? get onAddItem => widget.onAddItem;

  void _openAddEditItemDialog(BuildContext context, [MaterialItem? item]) {
    if (item != null && onEditItem != null) {
      onEditItem!(item);
      return;
    }
    if (item == null && onAddItem != null) {
      onAddItem!();
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditMaterialDialog(
        initialItem: item,
        defaultChallanNo: challan.challanNo,
        defaultSupplier: challan.supplierName,
        defaultDate: challan.date,
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _confirmDeleteItem(BuildContext context, MaterialItem item) {
    final prov = context.read<ProductionProvider>();
    final lang = prov.settings.appLanguage;
    final binName = AppStrings.get('recycleBin', lang);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(lang == 'gu' ? 'આઇટમને $binName માં મોકલો?' : (lang == 'hi' ? 'आइटम को $binName में भेजें?' : 'Move Item to $binName?')),
          content: Text(lang == 'gu'
              ? 'શું તમે ખરેખર ${item.productName} (₹${item.amount.toStringAsFixed(2)}) ડિલીટ કરવા માંગો છો?\n\nતે સુરક્ષિત રીતે $binName માં જશે અને ગમે ત્યારે પાછું લાવી શકાય છે.'
              : (lang == 'hi'
                  ? 'क्या आप वास्तव में ${item.productName} (₹${item.amount.toStringAsFixed(2)}) हटाना चाहते हैं?\n\nयह सुरक्षित रूप से $binName में जाएगा और कभी भी वापस लाया जा सकता है।'
                  : 'Are you sure you want to delete ${item.productName} (₹${item.amount.toStringAsFixed(2)})?\n\nIt will be moved to $binName and can be restored anytime.')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.get('cancel', lang)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (item.id != null) {
                  await prov.deleteMaterialItem(item.id!);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted && challan.items.length <= 1) {
                  _handleBack(context);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Item "${item.productName}" moved to $binName.'),
                      action: SnackBarAction(
                        label: 'Open Bin',
                        textColor: Colors.amberAccent,
                        onPressed: () => prov.setActiveNavIndex(11),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRedDark, foregroundColor: Colors.white),
              child: const Text('Delete & Move to Bin'),
            ),
          ],
        );
      },
    );
  }

  void _printChallanPdf(BuildContext context, ChallanSummary challan, List<MaterialItem> liveItems) async {
    final prov = context.read<ProductionProvider>();
    Supplier? supp;
    try {
      supp = prov.suppliers.firstWhere(
        (s) => s.name.trim().toLowerCase() == challan.supplierName.trim().toLowerCase(),
      );
    } catch (_) {}

    final summary = challan.copyWith(items: liveItems);
    try {
      await PdfExporter.printOrPreviewChallanInvoice(
        challan: summary,
        companyName: 'OM MAVTAR GROUP',
        supplierPhone: supp?.phone,
        supplierCity: supp?.city,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF bill: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showChallanPaymentStatusDialog(BuildContext context, ChallanSummary challan, List<MaterialItem> liveItems) {
    final prov = context.read<ProductionProvider>();
    final lang = prov.settings.appLanguage;
    final isCurrentlyPaid = liveItems.isNotEmpty && liveItems.every((i) => i.isPaid);
    final targetStatus = isCurrentlyPaid ? 'Pending' : 'Paid';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(
              isCurrentlyPaid ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
              color: isCurrentlyPaid ? Colors.amber[800] : const Color(0xFF059669),
            ),
            const SizedBox(width: 10),
            Text(AppStrings.t(lang,
                en: 'Supplier Payment Status',
                gu: 'સપ્લાયરને ચૂકવણી સ્થિતિ',
                hi: 'सप्लायर भुगतान स्थिति')),
          ],
        ),
        content: Text(
          AppStrings.t(lang,
              en: 'Raw material purchase bill for Challan #${challan.challanNo} from supplier "${challan.supplierName}".\n\nTotal Purchase Bill: ₹${NumberFormat('#,##,###.00').format(liveItems.fold<double>(0.0, (s, i) => s + i.amount))}\n\nUpdate payment status to "$targetStatus"?',
              gu: 'Challan #${challan.challanNo} (વેપારી: ${challan.supplierName}) ના કાચા માલ ખરીદી બિલની ચૂકવણી સ્થિતિ "$targetStatus" તરીકે સેટ કરવી છે?\n\nકુલ ખરીદી બિલ રકમ: ₹${NumberFormat('#,##,###.00').format(liveItems.fold<double>(0.0, (s, i) => s + i.amount))}',
              hi: 'चालान #${challan.challanNo} (सप्लायर: ${challan.supplierName}) के कच्चे माल खरीद बिल की भुगतान स्थिति "$targetStatus" सेट करनी है?\n\nकुल खरीद राशि: ₹${NumberFormat('#,##,###.00').format(liveItems.fold<double>(0.0, (s, i) => s + i.amount))}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await prov.updateChallanPaymentStatus(
                challan.challanNo,
                challan.supplierName,
                targetStatus,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Challan #${challan.challanNo} marked as $targetStatus to Supplier.'),
                    backgroundColor: isCurrentlyPaid ? Colors.amber[800] : const Color(0xFF059669),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyPaid ? Colors.amber[800] : const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: Text(targetStatus == 'Paid' ? 'Mark as Paid to Supplier' : 'Keep as Payable / Pending'),
          ),
        ],
      ),
    );
  }

  void _toggleItemPaymentStatus(BuildContext context, MaterialItem item) async {
    final prov = context.read<ProductionProvider>();
    final nextStatus = item.isPaid ? 'Pending' : 'Paid';
    if (item.id != null) {
      await prov.updateMaterialItemPaymentStatus(item.id!, nextStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);

    // Get live items for this challan from provider
    final liveItems = provider.materials
        .where((m) =>
            m.challanNo == challan.challanNo &&
            (challan.supplierName.isEmpty || m.supplierName == challan.supplierName))
        .toList();
    final totalAmount = liveItems.fold<double>(0.0, (sum, m) => sum + m.amount);
    final totalQty = liveItems.fold<double>(0.0, (sum, m) => sum + m.qty);

    if (asScreen) {
      return _buildScreenView(context, provider, liveItems, totalAmount, totalQty, accent, isDark);
    }

    return _buildDialogView(context, liveItems, totalAmount, totalQty, accent, isDark);
  }

  // Full Screen Calculation Statement View
  Widget _buildScreenView(
    BuildContext context,
    ProductionProvider provider,
    List<MaterialItem> liveItems,
    double totalAmount,
    double totalQty,
    Color accent,
    bool isDark,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header Bar
            _buildTopScreenBar(context, accent, isDark, liveItems),
            const SizedBox(height: 18),

            // 2. Challan & Party Invoice Memo Header Card
            _buildChallanMemoHeader(context, provider, liveItems, accent, isDark),
            const SizedBox(height: 18),

            // 3. Calculation Workspace (Table on Left, Step-by-Step Math on Right)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 960;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Itemized Calculation Ledger Table
                        Expanded(
                          flex: 7,
                          child: _buildCalculationTableCard(context, liveItems, totalAmount, totalQty, accent, isDark),
                        ),
                        const SizedBox(width: 18),
                        // Right: Step-by-Step Calculation Breakdown Panel
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: _buildStepByStepMathPanel(context, liveItems, totalAmount, totalQty, accent, isDark),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepByStepMathPanel(context, liveItems, totalAmount, totalQty, accent, isDark),
                          const SizedBox(height: 18),
                          _buildCalculationTableCard(context, liveItems, totalAmount, totalQty, accent, isDark),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top Screen Bar with Back Button, Calculation Title, PDF Bill, and Add Action
  Widget _buildTopScreenBar(BuildContext context, Color accent, bool isDark, List<MaterialItem> liveItems) {
    final lang = context.read<ProductionProvider>().settings.appLanguage;
    return Row(
      children: [
        Tooltip(
          message: AppStrings.get('back', lang),
          child: InkWell(
            onTap: () => _handleBack(context),
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
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.calculate_rounded, size: 24, color: accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.t(lang,
                    en: 'Material Purchase Challan & Calculation Statement',
                    gu: 'કાચો માલ ખરીદી ચલણ અને હિસાબ',
                    hi: 'कच्चा माल खरीद चालान एवं गणना विवरण'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_rounded, size: 12, color: Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Text(
                          '#${challan.challanNo}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Supplier / Vendor: ${challan.supplierName} • Date: ${DateFormat('dd MMMM yyyy').format(challan.date)} • Company Purchase Inward (${liveItems.length} Products)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // PDF Bill Print Button
        ElevatedButton.icon(
          onPressed: () => _printChallanPdf(context, challan, liveItems),
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 17),
          label: Text(AppStrings.t(lang, en: 'PDF Bill', gu: 'પીડીએફ બિલ', hi: 'पीडीएफ बिल')),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () => _openAddEditItemDialog(context),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(AppStrings.t(lang, en: 'Add Item to Challan', gu: 'વસ્તુ ઉમેરો', hi: 'वस्तु जोड़ें')),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: AppTheme.contrastText(accent),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // Challan Invoice & Party Memo Header Card
  Widget _buildChallanMemoHeader(
    BuildContext context,
    ProductionProvider provider,
    List<MaterialItem> liveItems,
    Color accent,
    bool isDark,
  ) {
    Supplier? supplierMatch;
    try {
      supplierMatch = provider.suppliers.firstWhere(
        (s) => s.name.trim().toLowerCase() == challan.supplierName.trim().toLowerCase(),
      );
    } catch (_) {
      supplierMatch = null;
    }

    final categories = liveItems.map((m) => m.category).toSet().toList();
    final isPaid = liveItems.isNotEmpty && liveItems.every((i) => i.isPaid);
    final isPartiallyPaid = !isPaid && liveItems.any((i) => i.isPaid);
    final lang = provider.settings.appLanguage;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Party / Supplier Info
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_rounded, size: 22, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t(lang,
                            en: 'SUPPLIER / VENDOR (RAW MATERIAL)',
                            gu: 'વેપારી (કાચો માલ આપનાર)',
                            hi: 'सप्लायर (कच्चा माल आपूर्तिकर्ता)'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        challan.supplierName.isNotEmpty && challan.supplierName != '-'
                            ? challan.supplierName
                            : 'Unknown Supplier',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      if (supplierMatch != null && (supplierMatch.phone.isNotEmpty || supplierMatch.city.isNotEmpty))
                        Text(
                          '${supplierMatch.city}${supplierMatch.city.isNotEmpty && supplierMatch.phone.isNotEmpty ? " • " : ""}${supplierMatch.phone}',
                          style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted(context)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 42, color: AppTheme.border(context)),
          const SizedBox(width: 18),

          // 2. Challan Number
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.25 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, size: 22, color: Color(0xFF0284C7)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHALLAN NO',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '#${challan.challanNo}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 42, color: AppTheme.border(context)),
          const SizedBox(width: 18),

          // 3. Challan Date
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: isDark ? 0.25 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, size: 22, color: Colors.amber),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENTRY DATE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('dd MMM yyyy').format(challan.date),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 42, color: AppTheme.border(context)),
          const SizedBox(width: 18),

          // 4. Categories Tagged
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CATEGORIES',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: categories.map((cat) {
                    Color catColor = cat == 'Sequence'
                        ? const Color(0xFF2563EB)
                        : cat == 'Beads'
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF059669);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: catColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: catColor),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 42, color: AppTheme.border(context)),
          const SizedBox(width: 18),

          // 5. Payment Status with 1-Click Toggle
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t(lang,
                      en: 'PAYMENT TO SUPPLIER',
                      gu: 'સપ્લાયરને ચૂકવણી',
                      hi: 'सप्लायर को भुगतान'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const SizedBox(height: 5),
                InkWell(
                  onTap: () => _showChallanPaymentStatusDialog(context, challan, liveItems),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? const Color(0xFF10B981).withValues(alpha: 0.14)
                          : isPartiallyPaid
                              ? Colors.amber.withValues(alpha: 0.14)
                              : const Color(0xFFEF4444).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPaid
                            ? const Color(0xFF10B981)
                            : isPartiallyPaid
                                ? Colors.amber[700]!
                                : const Color(0xFFEF4444),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaid
                              ? Icons.check_circle_rounded
                              : isPartiallyPaid
                                  ? Icons.timelapse_rounded
                                  : Icons.pending_actions_rounded,
                          size: 14,
                          color: isPaid
                              ? const Color(0xFF10B981)
                              : isPartiallyPaid
                                  ? Colors.amber[800]
                                  : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isPaid
                              ? AppStrings.t(lang, en: 'Paid to Supplier', gu: 'સપ્લાયરને ચૂકતે', hi: 'सप्लायर को भुगतान')
                              : isPartiallyPaid
                                  ? AppStrings.t(lang, en: 'Partial Paid', gu: 'અંશતઃ ચૂકતે', hi: 'आंशिक भुगतान')
                                  : AppStrings.t(lang, en: 'Payable to Supplier', gu: 'ચૂકવવાનું બાકી', hi: 'सप्लायर को देय बाकी'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isPaid
                                ? const Color(0xFF10B981)
                                : isPartiallyPaid
                                    ? Colors.amber[800]
                                    : const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 13,
                          color: isPaid
                              ? const Color(0xFF10B981)
                              : isPartiallyPaid
                                  ? Colors.amber[800]
                                  : const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationTableCard(
    BuildContext context,
    List<MaterialItem> liveItems,
    double totalAmount,
    double totalQty,
    Color accent,
    bool isDark,
  ) {
    final sortedItems = List<MaterialItem>.from(liveItems);
    final lang = context.read<ProductionProvider>().settings.appLanguage;
    sortedItems.sort((a, b) {
      final idA = a.id ?? 0;
      final idB = b.id ?? 0;
      return _sortIdAscending ? idA.compareTo(idB) : idB.compareTo(idA);
    });

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Card Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.table_chart_rounded, size: 18, color: AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.t(lang,
                          en: 'Itemized Calculation Sheet',
                          gu: 'આઇટમવાર ગણતરી પત્રક',
                          hi: 'मदवार गणना पत्रक'),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${liveItems.length} Products',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted(context)),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.functions_rounded, size: 13, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        'Qty × Rate = Amount',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Pinned Header Row (No horizontal scroll, 100% width)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle(context),
              border: Border(bottom: BorderSide(color: AppTheme.border(context))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () => setState(() => _sortIdAscending = !_sortIdAscending),
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#ID', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted(context))),
                        const SizedBox(width: 2),
                        Icon(
                          _sortIdAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 12,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(AppStrings.t(lang, en: 'Product Description', gu: 'માલ વિગત', hi: 'उत्पाद विवरण'), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                ),
                Expanded(
                  flex: 2,
                  child: Text(AppStrings.t(lang, en: 'Qty & Form', gu: 'જથ્થો અને સ્વરૂપ', hi: 'मात्रा और प्रकार'), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                ),
                Expanded(
                  flex: 2,
                  child: Text(AppStrings.t(lang, en: 'Rate & Formula', gu: 'ભાવ અને ગણતરી', hi: 'दर और सूत्र'), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                ),
                Expanded(
                  flex: 2,
                  child: Text(AppStrings.t(lang, en: 'Purchase Bill (₹)', gu: 'ખરીદી રકમ (₹)', hi: 'खरीद राशि (₹)'), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                ),
                Expanded(
                  flex: 2,
                  child: Text(AppStrings.t(lang, en: 'Payment to Supplier', gu: 'સપ્લાયરને ચૂકવણી', hi: 'सप्लायर को भुगतान'), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                ),
                Expanded(
                  flex: 2,
                  child: Text(AppStrings.t(lang, en: 'Actions', gu: 'ક્રિયાઓ', hi: 'क्रियाएं'), textAlign: TextAlign.right, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                ),
              ],
            ),
          ),

          // Main Data Table Body (Fixed width, vertical scroll only)
          Expanded(
            child: sortedItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text('No items on this challan', style: TextStyle(color: AppTheme.textMuted(context))),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: sortedItems.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.border(context).withValues(alpha: 0.5)),
                    itemBuilder: (ctx, idx) {
                      final item = sortedItems[idx];
                      Color catColor = item.category == 'Sequence'
                          ? const Color(0xFF2563EB)
                          : item.category == 'Beads'
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF059669);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            // # and ID
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${idx + 1}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted(context)),
                                  ),
                                  if (item.id != null)
                                    Text(
                                      '#${item.id}',
                                      style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.textMuted(context)),
                                    ),
                                ],
                              ),
                            ),

                            // Product Description & Specs
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.productName.toUpperCase(),
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.category,
                                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: catColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.mtr > 0 || item.mm > 0 || item.notes.isNotEmpty)
                                    Text(
                                      '${item.mtr > 0 ? "${item.mtr}m " : ""}${item.mm > 0 ? "${item.mm}mm " : ""}${item.notes.isNotEmpty ? "• ${item.notes}" : ""}',
                                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),

                            // Qty & Form
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    NumberFormat('#,##,###.00').format(item.qty),
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                                  ),
                                  Text(
                                    item.itemType,
                                    style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary(context)),
                                  ),
                                ],
                              ),
                            ),

                            // Rate & Formula
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹ ${NumberFormat('#,##,###.00').format(item.rate)}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context)),
                                  ),
                                  Text(
                                    '${item.qty.toStringAsFixed(1)} × ₹${item.rate.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.primaryBlue),
                                  ),
                                ],
                              ),
                            ),

                            // Total Amount
                            Expanded(
                              flex: 2,
                              child: Text(
                                '₹ ${NumberFormat('#,##,###.00').format(item.amount)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.successGreenDark,
                                ),
                              ),
                            ),

                            // Payment Status Chip with Clickable Toggle
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () => _toggleItemPaymentStatus(context, item),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: item.isPaid
                                        ? const Color(0xFF10B981).withValues(alpha: 0.14)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: item.isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        item.isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                                        size: 11,
                                        color: item.isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          item.isPaid
                                              ? AppStrings.t(lang, en: 'Paid to Supplier', gu: 'સપ્લાયરને ચૂકતે', hi: 'सप्लायर को भुगतान')
                                              : AppStrings.t(lang, en: 'Payable / Due', gu: 'ચૂકવવાનું બાકી', hi: 'देय / बाकी'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: item.isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Actions
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    tooltip: 'Edit Item',
                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                    padding: EdgeInsets.zero,
                                    onPressed: () => _openAddEditItemDialog(context, item),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRedDark),
                                    tooltip: 'Delete Item',
                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                    padding: EdgeInsets.zero,
                                    onPressed: () => _confirmDeleteItem(context, item),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Table Bottom Summary Footer Bar
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle(context),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 14,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTALS: ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted(context), letterSpacing: 0.5),
                    ),
                    Text(
                      '${liveItems.length} Products  •  ${NumberFormat('#,##,###.00').format(totalQty)} Units Total',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Gross Ledger Amount: ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context)),
                    ),
                    Text(
                      '₹ ${NumberFormat('#,##,###.00').format(totalAmount)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.successGreenDark,
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

  // Right Section: Step-by-Step Calculation Breakdown & Final Amount Voucher
  Widget _buildStepByStepMathPanel(
    BuildContext context,
    List<MaterialItem> liveItems,
    double totalAmount,
    double totalQty,
    Color accent,
    bool isDark,
  ) {
    final lang = context.read<ProductionProvider>().settings.appLanguage;
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calculate_rounded, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CALCULATION DETAILS',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    Text(
                      'Step-by-Step Math Breakdown',
                      style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Step 1: Registered Items Count
          _calcStepCard(
            context: context,
            stepNum: '1',
            stepTitle: 'Registered Items Count',
            formula: 'Total Items = Count(Products)',
            detail: '${liveItems.length} Products registered on Challan #${challan.challanNo}',
            result: '${liveItems.length} items',
            accentColor: AppTheme.primaryBlue,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // Step 2: Total Quantity Volume
          _calcStepCard(
            context: context,
            stepNum: '2',
            stepTitle: 'Total Material Quantity',
            formula: 'Total Qty = ∑ Item.Quantity',
            detail: 'Cumulative units across all product lines',
            result: '${NumberFormat('#,##,###.00').format(totalQty)} units',
            accentColor: const Color(0xFF7C3AED),
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // Step 3: Math Formula Applied
          _calcStepCard(
            context: context,
            stepNum: '3',
            stepTitle: 'Applied Calculation Formula',
            formula: 'Amount = Qty × Rate (₹)',
            detail: 'Each product line calculated as Qty multiplied by Unit Rate',
            result: 'Qty × Rate',
            accentColor: const Color(0xFF0284C7),
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // Step 4: Gross Ledger Subtotal
          _calcStepCard(
            context: context,
            stepNum: '4',
            stepTitle: 'Cumulative Gross Subtotal',
            formula: 'Grand Total = ∑ Line Amounts',
            detail: 'Sum of all individual product amounts',
            result: '₹ ${NumberFormat('#,##,###.00').format(totalAmount)}',
            accentColor: AppTheme.successGreenDark,
            isDark: isDark,
          ),
          const SizedBox(height: 18),

          // Prominent Emerald Final Amount Box (ચૂકવવાપાત્ર રકમ)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF064E3B).withValues(alpha: 0.6), const Color(0xFF022C22).withValues(alpha: 0.7)]
                    : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF059669).withValues(alpha: 0.6) : const Color(0xFF86EFAC),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.08),
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
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      AppStrings.t(lang,
                          en: 'Total Purchase Bill Payable to Supplier',
                          gu: 'સપ્લાયરને ચૂકવવાપાત્ર કુલ ખરીદી રકમ',
                          hi: 'सप्लायर को देय कुल खरीद राशि'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Color(0xFF047857),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 13, color: Color(0xFF059669)),
                          SizedBox(width: 3),
                          Text(
                            '100% Verified',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹ ${NumberFormat('#,##,###.00').format(totalAmount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: Color(0xFF059669),
                    fontFamily: 'monospace',
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.t(lang,
                    en: 'Company owes this bill amount to supplier "${challan.supplierName}"',
                    gu: 'કંપની દ્વારા વેપારી "${challan.supplierName}" ને આ ખરીદી બિલ રકમ ચૂકવવાની રહે છે',
                    hi: 'कंपनी द्वारा सप्लायर "${challan.supplierName}" को यह खरीद बिल राशि देय है'),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step Card Helper
  Widget _calcStepCard({
    required BuildContext context,
    required String stepNum,
    required String stepTitle,
    required String formula,
    required String detail,
    required String result,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    stepNum,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stepTitle,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                ),
              ),
              Text(
                result,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.cardBg(context),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Text(
              formula,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: AppTheme.textSecondary(context)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted(context)),
          ),
        ],
      ),
    );
  }

  // Modal Dialog View (for fallback if opened as a popup)
  Widget _buildDialogView(
    BuildContext context,
    List<MaterialItem> liveItems,
    double totalAmount,
    double totalQty,
    Color accent,
    bool isDark,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: AppTheme.cardBg(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 740),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.3 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calculate_rounded, color: accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Challan #${challan.challanNo}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary(context),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSubtle(context),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.border(context)),
                              ),
                              child: Text(
                                DateFormat('dd-MM-yyyy').format(challan.date),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context)),
                              ),
                            ),
                          ],
                        ),
                        if (challan.supplierName.isNotEmpty && challan.supplierName != '-')
                          Text(
                            'Supplier: ${challan.supplierName}',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626)),
                    tooltip: 'Print PDF Challan Bill',
                    onPressed: () => _printChallanPdf(context, challan, liveItems),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => _handleBack(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Banner
              _buildSummaryCard(context, liveItems, totalAmount, totalQty, accent, isDark),
              const SizedBox(height: 16),

              // Items Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Itemized Calculation Sheet (${liveItems.length})',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                  ),
                  TextButton.icon(
                    onPressed: () => _openAddEditItemDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Item', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Items List
              Expanded(
                child: _buildItemsList(context, liveItems, accent, isDark),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Close action
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _handleBack(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: AppTheme.contrastText(accent),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(AppStrings.get('closeDetails', context.read<ProductionProvider>().settings.appLanguage)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    List<MaterialItem> liveItems,
    double totalAmount,
    double totalQty,
    Color accent,
    bool isDark,
  ) {
    final lang = context.read<ProductionProvider>().settings.appLanguage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A).withValues(alpha: 0.35), const Color(0xFF0F172A)]
              : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.t(lang, en: 'Total Items', gu: 'કુલ માલ', hi: 'कुल वस्तुएं'), style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))),
              const SizedBox(height: 2),
              Text(
                '${liveItems.length} Products (${NumberFormat('#,##,###.00').format(totalQty)} units)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppStrings.t(lang, en: 'Challan Grand Total', gu: 'કુલ રકમ', hi: 'कुल राशि'), style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))),
              const SizedBox(height: 2),
              Text(
                '₹ ${NumberFormat('#,##,###.00').format(totalAmount)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.successGreenDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, List<MaterialItem> liveItems, Color accent, bool isDark) {
    if (liveItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No items on this challan',
            style: TextStyle(color: AppTheme.textMuted(context)),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: liveItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final item = liveItems[i];
        Color catColor = item.category == 'Sequence'
            ? const Color(0xFF2563EB)
            : item.category == 'Beads'
                ? const Color(0xFF7C3AED)
                : const Color(0xFF059669);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSubtle(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Index
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: catColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // #ID Badge
              if (item.id != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg(context),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Text(
                    '#ID: ${item.id}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: AppTheme.textMuted(context),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Product Info & Formula
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.productName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: catColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.qty.toStringAsFixed(2)} ${item.itemType}  ×  ₹${item.rate.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Amount
              Text(
                '₹ ${NumberFormat('#,##,###.00').format(item.amount)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.successGreenDark,
                ),
              ),
              const SizedBox(width: 12),

              // Payment Status Toggle Chip
              InkWell(
                onTap: () => _toggleItemPaymentStatus(context, item),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.isPaid
                        ? const Color(0xFF10B981).withValues(alpha: 0.14)
                        : const Color(0xFFEF4444).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    item.isPaid ? 'Paid' : 'Pending',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: item.isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Actions
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit item',
                visualDensity: VisualDensity.compact,
                onPressed: () => _openAddEditItemDialog(context, item),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.dangerRedDark),
                tooltip: 'Delete item',
                visualDensity: VisualDensity.compact,
                onPressed: () => _confirmDeleteItem(context, item),
              ),
            ],
          ),
        );
      },
    );
  }
}
