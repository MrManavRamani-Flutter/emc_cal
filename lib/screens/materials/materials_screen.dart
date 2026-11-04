import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../data/excel_exporter.dart';
import '../../data/pdf_exporter.dart';
import '../../models/challan_summary.dart';
import '../../models/material_item.dart';
import '../../models/material_product.dart';
import '../../models/supplier.dart';
import '../../providers/production_provider.dart';
import 'add_edit_material_dialog.dart';
import 'add_edit_material_product_dialog.dart';
import 'add_edit_supplier_dialog.dart';
import 'challan_details_dialog.dart';

enum MaterialScreenView {
  list,
  addMaterial,
  editMaterial,
  addProduct,
  editProduct,
  addSupplier,
  editSupplier,
  challanDetails,
}

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  MaterialScreenView _currentView = MaterialScreenView.list;
  MaterialItem? _activeItem;
  MaterialProduct? _activeProduct;
  Supplier? _activeSupplier;
  ChallanSummary? _activeChallan;
  String? _activeCategory;

  // Local filter states for specialized master tabs
  String _productMasterCategory = 'All';
  String _supplierMasterStatus = 'All';
  bool _sortIdAscending = true; // Default ID sort: Ascending (1, 2, 3...)

  final List<String> _tabs = [
    'CHALLAN REGISTER',
    'SEQUENCE',
    'BEADS',
    'THREAD',
    'PRODUCTS MASTER',
    'SUPPLIERS MASTER',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      final categoryMap = {
        0: 'Challan',
        1: 'Sequence',
        2: 'Beads',
        3: 'Dhaga',
        4: 'Products',
        5: 'Suppliers',
      };
      final provider = context.read<ProductionProvider>();
      final newCat = categoryMap[_tabController.index] ?? 'Challan';
      if (provider.selectedMaterialCategory != newCat) {
        provider.setSelectedMaterialCategory(newCat);
        // Reset category product filter if leaving a category tab to avoid empty table
        if (provider.materialProductFilter != 'All Products') {
          provider.setMaterialProductFilter('All Products');
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _currentTabCategory() {
    switch (_tabController.index) {
      case 1:
        return 'Sequence';
      case 2:
        return 'Beads';
      case 3:
        return 'Dhaga';
      default:
        return 'Sequence';
    }
  }

  // View Navigation Handlers (Replacing Dialog popups with Full Screens)
  void _openAddEntry([String? defaultCategory]) {
    setState(() {
      _activeItem = null;
      _activeCategory = defaultCategory ?? _currentTabCategory();
      _currentView = MaterialScreenView.addMaterial;
    });
  }

  void _openEditEntry(MaterialItem item) {
    setState(() {
      _activeItem = item;
      _activeCategory = item.category;
      _currentView = MaterialScreenView.editMaterial;
    });
  }

  void _openAddProduct([String? defaultCategory]) {
    setState(() {
      _activeProduct = null;
      _activeCategory = defaultCategory ?? _currentTabCategory();
      _currentView = MaterialScreenView.addProduct;
    });
  }

  void _openEditProduct(MaterialProduct product) {
    setState(() {
      _activeProduct = product;
      _activeCategory = product.category;
      _currentView = MaterialScreenView.editProduct;
    });
  }

  void _openAddSupplier() {
    setState(() {
      _activeSupplier = null;
      _currentView = MaterialScreenView.addSupplier;
    });
  }

  void _openEditSupplier(Supplier supplier) {
    setState(() {
      _activeSupplier = supplier;
      _currentView = MaterialScreenView.editSupplier;
    });
  }

  void _openChallanDetails(ChallanSummary challan) {
    setState(() {
      _activeChallan = challan;
      _currentView = MaterialScreenView.challanDetails;
    });
  }

  void _openChallanByNo(String challanNo) {
    final provider = context.read<ProductionProvider>();
    final matches = provider.materials.where((m) => m.challanNo == challanNo).toList();
    if (matches.isNotEmpty) {
      final summary = ChallanSummary(
        challanNo: challanNo,
        date: matches.first.date,
        supplierName: matches.first.supplierName,
        items: matches,
      );
      _openChallanDetails(summary);
    }
  }

  // Export Supplier PDF Statement
  Future<void> _exportSupplierPdf(BuildContext context, String supplierName) async {
    final provider = context.read<ProductionProvider>();
    final items = provider.getMaterialsForSupplier(supplierName);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No order records found for $supplierName.')),
      );
      return;
    }

    final matching = provider.suppliers.where((s) => s.name.trim().toLowerCase() == supplierName.trim().toLowerCase()).toList();
    final supp = matching.isNotEmpty ? matching.first : null;

    try {
      await PdfExporter.printOrPreviewSupplierStatement(
        supplierName: supplierName,
        items: items,
        companyName: provider.settings.companyName,
        phone: supp?.phone,
        city: supp?.city,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Export Single Item PDF Challan (Surat Textile Paper Format)
  Future<void> _printSingleItemChallanPdf(MaterialItem item) async {
    final provider = context.read<ProductionProvider>();
    Supplier? supp;
    try {
      supp = provider.suppliers.firstWhere(
        (s) => s.name.trim().toLowerCase() == item.supplierName.trim().toLowerCase(),
      );
    } catch (_) {}

    try {
      final savedPath = await PdfExporter.exportAndOpenMaterialItemPdf(
        item: item,
        companyName: provider.settings.companyName.isEmpty ? 'OM MAVTAR GROUP' : provider.settings.companyName,
        supplierPhone: supp?.phone,
        supplierCity: supp?.city,
        supplierGst: supp?.gstNo,
      );
      if (mounted && savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item PDF Challan opened in Preview! Saved to: $savedPath'),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating item PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Export Supplier Excel Sheet
  Future<void> _exportSupplierExcel(BuildContext context, String supplierName) async {
    final provider = context.read<ProductionProvider>();
    final items = provider.getMaterialsForSupplier(supplierName);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No order records found for $supplierName.')),
      );
      return;
    }

    final matching = provider.suppliers.where((s) => s.name.trim().toLowerCase() == supplierName.trim().toLowerCase()).toList();
    final supp = matching.isNotEmpty ? matching.first : null;

    final bytes = ExcelExporter.generateSupplierExcel(
      supplierName: supplierName,
      items: items,
      companyName: provider.settings.companyName,
      phone: supp?.phone,
      city: supp?.city,
      currencySymbol: provider.settings.currencySymbol,
    );

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to encode Excel file.'), backgroundColor: Colors.red),
      );
      return;
    }

    final cleanName = supplierName.isEmpty ? 'All_Suppliers' : supplierName.replaceAll(RegExp(r'[\\/*?:\[\]\s]'), '_');
    final filename = 'Supplier_${cleanName}_Report_${DateFormat("yyyyMMdd").format(DateTime.now())}.xlsx';

    String? targetPath;
    try {
      final uri = await FilePicker.saveFile(
        fileName: filename,
        bytes: Uint8List.fromList(bytes),
        dialogTitle: 'Save Supplier Excel Report',
      );
      if (uri != null) {
        targetPath = uri.toFilePath();
      }
    } catch (_) {
      final docs = await getApplicationDocumentsDirectory();
      targetPath = '${docs.path}/$filename';
      final file = File(targetPath);
      await file.writeAsBytes(bytes);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel Report exported for $supplierName.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  // Quick Payment Status Toggle Dialog for Challan
  void _showPaymentStatusToggleDialog(BuildContext context, ChallanSummary ch) {
    final provider = context.read<ProductionProvider>();
    final isCurrentlyPaid = ch.isPaid;
    final lang = provider.settings.appLanguage;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(Icons.payment_rounded, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(AppStrings.t(lang,
                  en: 'Challan #${ch.challanNo} Supplier Payment',
                  gu: 'ચલણ #${ch.challanNo} સપ્લાયરને ચૂકવણી',
                  hi: 'चालान #${ch.challanNo} सप्लायर भुगतान')),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.t(lang, en: "Supplier / Vendor", gu: "વેપારી (માલ આપનાર)", hi: "सप्लायर (सामग्री आपूर्तिकर्ता)")}: ${ch.supplierName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.t(lang, en: "Total Purchase Bill", gu: "કુલ ખરીદી બિલ", hi: "कुल खरीद बिल")}: ₹ ${NumberFormat("#,##,###.00").format(ch.totalAmount)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.t(lang,
                        en: 'Note: OM MAVTAR GROUP purchases material from this supplier and pays this bill amount.',
                        gu: 'નોંધ: કંપની આ વેપારી પાસેથી કાચો માલ ખરીદે છે અને આ રકમ વેપારીને ચૂકવવાની થાય છે.',
                        hi: 'नोट: कंपनी इस सप्लायर से कच्चा माल खरीदती है और यह बिल सप्लायर को भुगतान करना होता है।'),
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrentlyPaid ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isCurrentlyPaid ? Icons.check_circle : Icons.pending, size: 14, color: isCurrentlyPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Text(
                      'Current Status: ${isCurrentlyPaid ? AppStrings.t(lang, en: "Paid to Supplier", gu: "સપ્લાયરને ચૂકતે થયેલ", hi: "सप्लायर को भुगतान किया") : AppStrings.t(lang, en: "Payable to Supplier / Due", gu: "સપ્લાયરને ચૂકવવાનું બાકી", hi: "सप्लायर को देय बाकी")}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isCurrentlyPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppStrings.t(lang,
                  en: 'Update payment made to supplier for this purchase challan:',
                  gu: 'આ ખરીદી ચલણ માટે સપ્લાયરને ચૂકવણી સ્થિતિ અપડેટ કરો:',
                  hi: 'इस खरीद चालान के लिए सप्लायर भुगतान स्थिति अपडेट करें:'),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            if (!isCurrentlyPaid)
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: Text(AppStrings.t(lang, en: 'Mark as Paid to Supplier', gu: 'સપ્લાયરને ચૂકવી દીધું (Paid)', hi: 'सप्लायर को भुगतान किया चिह्नित करें')),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await provider.updateChallanPaymentStatus(ch.challanNo, ch.supplierName, 'Paid');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Challan #${ch.challanNo} marked as Paid to Supplier.'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
              ),
            if (isCurrentlyPaid)
              ElevatedButton.icon(
                icon: const Icon(Icons.timelapse, size: 16),
                label: Text(AppStrings.t(lang, en: 'Keep as Payable / Pending', gu: 'સપ્લાયરને ચૂકવવાનું બાકી રાખો', hi: 'सप्लायर को देय बाकी रखें')),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await provider.updateChallanPaymentStatus(ch.challanNo, ch.supplierName, 'Pending');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Challan #${ch.challanNo} marked as Payable / Pending.'),
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  }
                },
              ),
          ],
        );
      },
    );
  }

  // Quick Payment Status Toggle Dialog for Individual Item
  void _showItemPaymentStatusToggleDialog(BuildContext context, MaterialItem item) {
    if (item.id == null) return;
    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final isCurrentlyPaid = item.isPaid;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(Icons.payment_rounded, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 8),
              Flexible(child: Text('Item #${item.id} Supplier Payment')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${item.productName} (${AppStrings.categoryName(item.category, lang)})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Supplier / Vendor: ${item.supplierName} • Challan #${item.challanNo}', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text('Purchase Bill Amount: ₹ ${NumberFormat("#,##,###.00").format(item.amount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrentlyPaid ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isCurrentlyPaid ? Icons.check_circle : Icons.pending, size: 14, color: isCurrentlyPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Text(
                      'Payment Status: ${isCurrentlyPaid ? AppStrings.t(lang, en: "Paid to Supplier", gu: "સપ્લાયરને ચૂકતે થયેલ", hi: "सप्लायर को भुगतान किया") : AppStrings.t(lang, en: "Payable to Supplier / Due", gu: "સપ્લાયરને ચૂકવવાનું બાકી", hi: "सप्लायर को देय बाकी")}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isCurrentlyPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            if (!isCurrentlyPaid)
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: Text(AppStrings.t(lang, en: 'Mark as Paid to Supplier', gu: 'સપ્લાયરને ચૂકવી દીધું', hi: 'सप्लायर को भुगतान किया')),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await provider.updateMaterialItemPaymentStatus(item.id!, 'Paid');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.productName} marked as Paid to Supplier.'), backgroundColor: const Color(0xFF10B981)),
                    );
                  }
                },
              ),
            if (isCurrentlyPaid)
              ElevatedButton.icon(
                icon: const Icon(Icons.timelapse, size: 16),
                label: Text(AppStrings.t(lang, en: 'Keep as Payable', gu: 'સપ્લાયરને ચૂકવવાનું બાકી રાખો', hi: 'सप्लायर को देय बाकी रखें')),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await provider.updateMaterialItemPaymentStatus(item.id!, 'Pending');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.productName} marked as Payable to Supplier.'), backgroundColor: const Color(0xFFEF4444)),
                    );
                  }
                },
              ),
          ],
        );
      },
    );
  }

  // Mark all pending raw material purchase orders for this supplier as paid by company
  void _confirmMarkAllPaid(BuildContext context, String supplierName) {
    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
            const SizedBox(width: 8),
            Text(AppStrings.t(lang,
              en: 'Mark All Paid to Supplier?',
              gu: 'વેપારીને તમામ બિલો ચૂકતે કરો?',
              hi: 'सप्लायर को सभी बिल भुगतान करें?')),
          ],
        ),
        content: Text(AppStrings.t(provider.settings.appLanguage,
          en: 'Confirm payment to supplier "$supplierName" for all pending raw material purchase challans? This marks all purchase bills as paid by OM MAVTAR GROUP.',
          gu: 'શું તમે વેપારી "$supplierName" ના કાચા માલ ખરીદીના તમામ પેન્ડિંગ ચલણ કંપની દ્વારા ચૂકતે (Paid to Supplier) કરવા માંગો છો?',
          hi: 'क्या आप सप्लायर "$supplierName" के कच्चे माल खरीद के सभी लंबित चालान कंपनी द्वारा भुगतान किए गए (Paid to Supplier) चिह्नित करना चाहते हैं?')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.updateSupplierAllPaymentStatus(supplierName, 'Paid');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All purchase bills for "$supplierName" marked as Paid to Supplier.'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            child: Text(AppStrings.t(lang, en: 'Yes, Mark Paid to Supplier', gu: 'હા, ચૂકતે કરો', hi: 'हाँ, भुगतान चिह्नित करें')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSupplier(Supplier supplier) {
    final prov = context.read<ProductionProvider>();
    final lang = prov.settings.appLanguage;
    final binName = AppStrings.get('recycleBin', lang);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(lang == 'gu' ? 'વેપારીને $binName માં મોકલો?' : (lang == 'hi' ? 'व्यापारी को $binName में भेजें?' : 'Move Supplier to $binName?')),
        content: Text(lang == 'gu'
            ? '"${supplier.name}" હટાવવું છે?\n\nતે સુરક્ષિત રીતે $binName માં જશે અને ગમે ત્યારે પાછું લાવી શકાય છે.'
            : (lang == 'hi'
                ? '"${supplier.name}" हटाना चाहते हैं?\n\nयह सुरक्षित रूप से $binName में जाएगा और कभी भी वापस लाया जा सकता है।'
                : 'Remove "${supplier.name}"?\n\nIt will be moved to $binName and can be restored anytime.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(AppStrings.get('cancel', lang))),
          ElevatedButton(
            onPressed: () async {
              if (supplier.id != null) {
                await prov.deleteSupplier(supplier.id!);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Supplier "${supplier.name}" moved to $binName.'),
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
      ),
    );
  }

  void _confirmDeleteProduct(MaterialProduct product) {
    final prov = context.read<ProductionProvider>();
    final lang = prov.settings.appLanguage;
    final binName = AppStrings.get('recycleBin', lang);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(lang == 'gu' ? 'પ્રોડક્ટને $binName માં મોકલો?' : (lang == 'hi' ? 'उत्पाद को $binName में भेजें?' : 'Move Product to $binName?')),
        content: Text(lang == 'gu'
            ? '"${product.name}" હટાવવું છે?\n\nતે સુરક્ષિત રીતે $binName માં જશે અને ગમે ત્યારે પાછું લાવી શકાય છે.'
            : (lang == 'hi'
                ? '"${product.name}" हटाना चाहते हैं?\n\nयह सुरक्षित रूप से $binName में जाएगा और कभी भी वापस लाया जा सकता है।'
                : 'Remove "${product.name}"?\n\nIt will be moved to $binName and can be restored anytime.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(AppStrings.get('cancel', lang))),
          ElevatedButton(
            onPressed: () async {
              if (product.id != null) {
                await prov.deleteMaterialProduct(product.id!);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Product "${product.name}" moved to $binName.'),
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
      ),
    );
  }

  void _confirmDeleteItem(MaterialItem item) {
    final prov = context.read<ProductionProvider>();
    final lang = prov.settings.appLanguage;
    final binName = AppStrings.get('recycleBin', lang);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(lang == 'gu' ? 'મટિરિયલને $binName માં મોકલો?' : (lang == 'hi' ? 'सामग्री को $binName में भेजें?' : 'Move Material to $binName?')),
        content: Text(lang == 'gu'
            ? '"${item.productName}" (ચલણ #${item.challanNo}) હટાવવું છે?\n\nતે સુરક્ષિત રીતે $binName માં જશે અને ગમે ત્યારે પાછું લાવી શકાય છે.'
            : (lang == 'hi'
                ? '"${item.productName}" (चालान #${item.challanNo}) हटाना चाहते हैं?\n\nयह सुरक्षित रूप से $binName में जाएगा और कभी भी वापस लाया जा सकता है।'
                : 'Delete "${item.productName}" (Challan #${item.challanNo})?\n\nIt will be moved to $binName and can be restored anytime.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(AppStrings.get('cancel', lang))),
          ElevatedButton(
            onPressed: () async {
              if (item.id != null) {
                await prov.deleteMaterialItem(item.id!);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
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
      ),
    );
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: context.read<ProductionProvider>().materialCustomDateRange ??
          DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now()),
    );
    if (picked != null && context.mounted) {
      context.read<ProductionProvider>().setMaterialDateFilter('Custom', picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);

    // Screen View Switcher: Convert Dialogs to Full Screen Views
    switch (_currentView) {
      case MaterialScreenView.addMaterial:
      case MaterialScreenView.editMaterial:
        return AddEditMaterialDialog(
          asScreen: true,
          initialItem: _activeItem,
          defaultCategory: _activeCategory,
          defaultChallanNo: _activeChallan?.challanNo,
          defaultSupplier: _activeChallan?.supplierName,
          defaultDate: _activeChallan?.date,
          onSaved: (savedCat, savedChallanNo) {
            setState(() {
              if (_activeChallan != null) {
                _currentView = MaterialScreenView.challanDetails;
                _activeItem = null;
              } else {
                _currentView = MaterialScreenView.list;
                _activeItem = null;
                // Auto switch to list screen of added category or challan register
                final catLower = savedCat.toLowerCase();
                if (_tabController.index == 0) {
                  _tabController.animateTo(0);
                } else if (catLower == 'sequence') {
                  _tabController.animateTo(1);
                } else if (catLower == 'beads') {
                  _tabController.animateTo(2);
                } else if (catLower == 'dhaga' || catLower == 'daga') {
                  _tabController.animateTo(3);
                } else {
                  _tabController.animateTo(0);
                }
              }
            });
          },
          onBack: () => setState(() {
            _currentView = _activeChallan != null ? MaterialScreenView.challanDetails : MaterialScreenView.list;
            _activeItem = null;
          }),
        );
      case MaterialScreenView.addProduct:
      case MaterialScreenView.editProduct:
        return AddEditMaterialProductDialog(
          asScreen: true,
          initialProduct: _activeProduct,
          defaultCategory: _activeCategory,
          onSaved: (prod) {
            setState(() {
              _currentView = MaterialScreenView.list;
              _activeProduct = null;
              _productMasterCategory = 'All'; // Ensure newly added product is visible
              _tabController.animateTo(4); // Auto open Products Master Tab
            });
          },
          onBack: () => setState(() {
            _currentView = MaterialScreenView.list;
            _activeProduct = null;
          }),
        );
      case MaterialScreenView.addSupplier:
      case MaterialScreenView.editSupplier:
        return AddEditSupplierDialog(
          asScreen: true,
          initialSupplier: _activeSupplier,
          onSaved: (supp) {
            setState(() {
              _currentView = MaterialScreenView.list;
              _activeSupplier = null;
              _supplierMasterStatus = 'All'; // Ensure newly added supplier is visible
              _tabController.animateTo(5); // Auto open Suppliers Master Tab
            });
          },
          onBack: () => setState(() {
            _currentView = MaterialScreenView.list;
            _activeSupplier = null;
          }),
        );
      case MaterialScreenView.challanDetails:
        return ChallanDetailsDialog(
          asScreen: true,
          challan: _activeChallan!,
          onBack: () => setState(() {
            _currentView = MaterialScreenView.list;
            _activeChallan = null;
          }),
          onEditItem: _openEditEntry,
          onAddItem: () => _openAddEntry(_currentTabCategory()),
        );
      case MaterialScreenView.list:
        return _buildListView(context, provider, accent, isDark);
    }
  }

  Widget _buildListView(BuildContext context, ProductionProvider provider, Color accent, bool isDark) {
    final lang = provider.settings.appLanguage;
    final allMaterials = provider.materials;
    final filteredMaterials = provider.filteredMaterials;
    final challanList = provider.challanSummaries;
    final productList = provider.materialProducts;

    final seqItems = allMaterials.where((m) => m.category.toLowerCase() == 'sequence').toList();
    final beadsItems = allMaterials.where((m) => m.category.toLowerCase() == 'beads').toList();
    final dhagaItems = allMaterials.where((m) => m.category.toLowerCase() == 'dhaga' || m.category.toLowerCase() == 'daga' || m.category.toLowerCase() == 'thread').toList();

    // Financial totals & items for active tab
    final activeTabItems = _tabController.index == 0
        ? filteredMaterials
        : (_tabController.index == 1
            ? provider.getFilteredMaterialsForCategory('Sequence')
            : (_tabController.index == 2
                ? provider.getFilteredMaterialsForCategory('Beads')
                : provider.getFilteredMaterialsForCategory('Dhaga')));

    final totalAmount = activeTabItems.fold<double>(0.0, (s, m) => s + m.amount);
    final paidAmount = activeTabItems.where((m) => m.isPaid).fold<double>(0.0, (s, m) => s + m.amount);
    final pendingAmount = activeTabItems.where((m) => !m.isPaid).fold<double>(0.0, (s, m) => s + m.amount);
    final totalQty = activeTabItems.fold<double>(0.0, (s, m) => s + m.qty);
    final activeChallansCount = activeTabItems.map((m) => '${m.formattedDate}_${m.challanNo}').toSet().length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Screen Header & Primary Actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.3 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.shopping_bag_rounded, size: 24, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t(provider.settings.appLanguage,
                          en: 'Material Purchases & Challan Ledger',
                          gu: 'કાચો માલ ખરીદી અને ચલણ હિસાબ',
                          hi: 'कच्चा माल खरीद एवं चालान लेजर'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary(context),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.t(lang,
                          en: 'Company purchases raw materials (Sequence, Beads, Thread) from suppliers on challan • Track purchase bills & payments payable to vendors',
                          gu: 'કંપની દ્વારા વેપારીઓ પાસેથી કાચા માલની ખરીદી (દોરા, સીક્વન્સ, મોતી) • ખરીદી ચલણ બિલ અને સપ્લાયરને ચૂકવવાપાત્ર હિસાબ',
                          hi: 'कंपनी द्वारा सप्लायरों से कच्चा माल खरीद (धागा, सीक्वेंस, मोती) • खरीद चालान बिल और सप्लायरों को देय भुगतान'),
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                      ),
                    ],
                  ),
                ),
                // Action Buttons (Open as Full Screens)
                ElevatedButton.icon(
                  onPressed: () => _openAddSupplier(),
                  icon: const Icon(Icons.storefront_rounded, size: 16),
                  label: Text(AppStrings.t(lang, en: 'New Supplier', gu: 'નવો વેપારી', hi: 'नया सप्लायर')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceSubtle(context),
                    foregroundColor: AppTheme.textPrimary(context),
                    side: BorderSide(color: AppTheme.border(context)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _openAddProduct(),
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: Text(AppStrings.t(lang, en: 'New Product Master', gu: 'પ્રોડક્ટ માસ્ટર', hi: 'उत्पाद मास्टर')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceSubtle(context),
                    foregroundColor: AppTheme.textPrimary(context),
                    side: BorderSide(color: AppTheme.border(context)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _openAddEntry(),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: Text(AppStrings.t(lang,
                    en: '+ Purchase Challan Entry',
                    gu: '+ ખરીદી ચલણ એન્ટ્રી',
                    hi: '+ खरीद चालान प्रविष्टि')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppTheme.contrastText(accent),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Real Segmented Desktop Tab Bar
            _buildSegmentedTabBar(
              context: context,
              challanCount: challanList.length,
              seqCount: seqItems.length,
              beadsCount: beadsItems.length,
              dhagaCount: dhagaItems.length,
              productsCount: productList.length,
              suppliersCount: provider.suppliers.length,
              accent: accent,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // 3. Tab-Wise Dynamic Filter Bar (Only show what is needed per tab)
            _buildDynamicFilterBar(context, provider, accent),
            const SizedBox(height: 14),

            // 4. KPI Summary Strip or Supplier Statement Banner
            if (_tabController.index != 4 && _tabController.index != 5) ...[
              if (provider.materialSupplierFilter != 'All Suppliers') ...[
                _buildSupplierStatementBanner(context, provider, accent),
                const SizedBox(height: 14),
              ] else ...[
                _buildKpiStrip(context, totalAmount, paidAmount, pendingAmount, totalQty, activeTabItems.length, activeChallansCount),
                const SizedBox(height: 14),
              ],
            ],

            // 5. Tab Views Area
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 0: Challan Register
                  _buildChallanRegisterTab(context, challanList, accent),

                  // Tab 1: Sequence Records
                  _buildCategoryItemsTab(context, 'Sequence', const Color(0xFF2563EB)),

                  // Tab 2: Beads Records
                  _buildCategoryItemsTab(context, 'Beads', const Color(0xFF7C3AED)),

                  // Tab 3: Dhaga Records
                  _buildCategoryItemsTab(context, 'Dhaga', const Color(0xFF059669)),

                  // Tab 4: Products Master
                  _buildProductsMasterTab(context, productList, accent),

                  // Tab 5: Suppliers Master
                  _buildSuppliersMasterTab(context, provider.suppliers, accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Segmented Desktop Tab Bar Builder
  Widget _buildSegmentedTabBar({
    required BuildContext context,
    required int challanCount,
    required int seqCount,
    required int beadsCount,
    required int dhagaCount,
    required int productsCount,
    required int suppliersCount,
    required Color accent,
    required bool isDark,
  }) {
    final lang = context.watch<ProductionProvider>().settings.appLanguage;
    final activeIndex = _tabController.index;

    Color getTabColor(int idx) {
      switch (idx) {
        case 0:
          return const Color(0xFF0284C7);
        case 1:
          return const Color(0xFF2563EB);
        case 2:
          return const Color(0xFF7C3AED);
        case 3:
          return const Color(0xFF059669);
        case 4:
          return const Color(0xFFD97706);
        case 5:
          return const Color(0xFF6366F1);
        default:
          return accent;
      }
    }

    final activeColor = getTabColor(activeIndex);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        onTap: (index) {
          final categoryMap = {
            0: 'Challan',
            1: 'Sequence',
            2: 'Beads',
            3: 'Dhaga',
            4: 'Products',
            5: 'Suppliers',
          };
          final provider = context.read<ProductionProvider>();
          final newCat = categoryMap[index] ?? 'Challan';
          if (provider.selectedMaterialCategory != newCat) {
            provider.setSelectedMaterialCategory(newCat);
            if (provider.materialProductFilter != 'All Products') {
              provider.setMaterialProductFilter('All Products');
            }
          }
          setState(() {});
        },
        indicator: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: activeColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        tabs: [
          _buildSegmentTabItem(0, Icons.receipt_long_rounded, getTabColor(0), 'CHALLAN REGISTER', challanCount, activeIndex == 0, context),
          _buildSegmentTabItem(1, Icons.auto_awesome_rounded, getTabColor(1), 'SEQUENCE', seqCount, activeIndex == 1, context),
          _buildSegmentTabItem(2, Icons.lens_blur_rounded, getTabColor(2), 'BEADS', beadsCount, activeIndex == 2, context),
          _buildSegmentTabItem(3, Icons.line_weight_rounded, getTabColor(3), AppStrings.t(lang, en: 'THREAD', gu: 'દોરા / ધાગા', hi: 'धागा'), dhagaCount, activeIndex == 3, context),
          _buildSegmentTabItem(4, Icons.inventory_2_rounded, getTabColor(4), 'PRODUCTS MASTER', productsCount, activeIndex == 4, context),
          _buildSegmentTabItem(5, Icons.storefront_rounded, getTabColor(5), 'SUPPLIERS MASTER', suppliersCount, activeIndex == 5, context),
        ],
      ),
    );
  }

  Widget _buildSegmentTabItem(
    int index,
    IconData icon,
    Color color,
    String label,
    int count,
    bool isSelected,
    BuildContext context,
  ) {
    final isDark = AppTheme.isDark(context);
    return Tab(
      height: 42,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : color.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : AppTheme.textMuted(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: isDark ? 0.25 : 0.15)
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? color : AppTheme.textMuted(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Tab-Wise Dynamic Filter Bar (Only display what is relevant per active tab)
  Widget _buildDynamicFilterBar(BuildContext context, ProductionProvider provider, Color accent) {
    final tabIndex = _tabController.index;
    final lang = provider.settings.appLanguage;
    final hintColor = AppTheme.hintColor(context);

    // Calculate active filter state according to the selected tab
    bool hasActiveFilter = false;
    if (tabIndex == 0) {
      // Challan Register: Search, Date, Supplier
      hasActiveFilter = provider.materialSearchQuery.isNotEmpty ||
          provider.materialDateFilter != 'All Time' ||
          provider.materialSupplierFilter != 'All Suppliers';
    } else if (tabIndex >= 1 && tabIndex <= 3) {
      // Sequence (1), Beads (2), Dhaga (3): Search, Date, Supplier, Category-Products
      hasActiveFilter = provider.materialSearchQuery.isNotEmpty ||
          provider.materialDateFilter != 'All Time' ||
          provider.materialSupplierFilter != 'All Suppliers' ||
          provider.materialProductFilter != 'All Products';
    } else if (tabIndex == 4) {
      // Products Master: Search, Category
      hasActiveFilter = provider.materialSearchQuery.isNotEmpty || _productMasterCategory != 'All';
    } else if (tabIndex == 5) {
      // Suppliers Master: Search, Status
      hasActiveFilter = provider.materialSearchQuery.isNotEmpty ||
          _supplierMasterStatus != 'All';
    }

    // Dynamic Search Hint based on tab
    String searchHint;
    switch (tabIndex) {
      case 0:
        searchHint = 'Search Challan #, Party / Supplier...';
        break;
      case 1:
        searchHint = 'Search Sequence Challan #, Product, Supplier...';
        break;
      case 2:
        searchHint = 'Search Beads Challan #, Product, Supplier...';
        break;
      case 3:
        searchHint = AppStrings.t(lang,
            en: 'Search Thread Challan #, Product, Supplier...',
            gu: 'દોરા / ધાગા ચલણ #, પ્રોડક્ટ, સપ્લાયર શોધો...',
            hi: 'धागा चालान #, उत्पाद, आपूर्तिकर्ता खोजें...');
        break;
      case 4:
        searchHint = 'Search Product Name, Category, Unit...';
        break;
      case 5:
        searchHint = 'Search Supplier Name, Phone...';
        break;
      default:
        searchHint = 'Search Challan #, Product, Supplier...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 1. Search Field (Always present, customized hint per tab)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => provider.setMaterialSearchQuery(val),
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle: TextStyle(color: hintColor, fontSize: 12),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            provider.setMaterialSearchQuery('');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),

          // 2. Date Filter Dropdown (Only for Ledger Tabs: 0, 1, 2, 3)
          if (tabIndex <= 3)
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: provider.materialDateFilter,
                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                  items: ['All Time', 'Today', 'Yesterday', 'This Week', 'This Month', 'Last Month', 'Custom'].map((opt) {
                    return DropdownMenuItem(value: opt, child: Text(opt));
                  }).toList(),
                  onChanged: (val) {
                    if (val == 'Custom') {
                      _pickCustomDateRange(context);
                    } else if (val != null) {
                      provider.setMaterialDateFilter(val);
                    }
                  },
                ),
              ),
            ),

          // 3. Supplier Filter Dropdown (Only for Ledger Tabs: 0, 1, 2, 3)
          if (tabIndex <= 3 && provider.materialSuppliers.length > 1)
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: provider.materialSuppliers.contains(provider.materialSupplierFilter)
                      ? provider.materialSupplierFilter
                      : 'All Suppliers',
                  icon: const Icon(Icons.store_rounded, size: 16),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                  items: provider.materialSuppliers.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        s == 'All Suppliers'
                            ? AppStrings.t(provider.settings.appLanguage, en: 'All Suppliers', gu: 'તમામ વેપારી (All Suppliers)', hi: 'सभी सप्लायर (All Suppliers)')
                            : s,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) provider.setMaterialSupplierFilter(val);
                  },
                ),
              ),
            ),

          // 4. Product Filter Dropdown (Only for Category Tabs: 1 = Sequence, 2 = Beads, 3 = Dhaga)
          if (tabIndex >= 1 && tabIndex <= 3) ...[
            _buildCategorySpecificProductDropdown(context, provider, tabIndex),
          ],

          // 5. Products Master Tab Filters (Category Filter: All, Sequence, Beads, Dhaga)
          if (tabIndex == 4)
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _productMasterCategory,
                  icon: const Icon(Icons.category_rounded, size: 16),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                  items: [
                    DropdownMenuItem(value: 'All', child: Text(AppStrings.t(provider.settings.appLanguage, en: 'All Categories', gu: 'તમામ કેટેગરી', hi: 'सभी श्रेणियां'))),
                    DropdownMenuItem(value: 'Sequence', child: Text(AppStrings.t(provider.settings.appLanguage, en: 'Sequence', gu: 'સીક્વન્સ', hi: 'सीक्वेंस'))),
                    DropdownMenuItem(value: 'Beads', child: Text(AppStrings.t(provider.settings.appLanguage, en: 'Beads', gu: 'મોતી / બિલ્લી', hi: 'मोती / बीड्स'))),
                    DropdownMenuItem(value: 'Dhaga', child: Text(AppStrings.t(provider.settings.appLanguage, en: 'Thread', gu: 'દોરા / ધાગા', hi: 'धागा'))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _productMasterCategory = val);
                  },
                ),
              ),
            ),

          // 6. Suppliers Master Tab Filters (City & Active Status Filter)
          if (tabIndex == 5) ...[
            // Status Filter Dropdown
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _supplierMasterStatus,
                  icon: const Icon(Icons.toggle_on_rounded, size: 16),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                  items: [
                    DropdownMenuItem(value: 'All', child: Text(AppStrings.t(provider.settings.appLanguage, en: 'All Status', gu: 'તમામ સ્ટેટસ', hi: 'सभी स्थिति'))),
                    DropdownMenuItem(value: 'Active', child: Text(AppStrings.t(provider.settings.appLanguage, en: 'Active Only', gu: 'માત્ર સક્રિય', hi: 'केवल सक्रिय'))),
                    DropdownMenuItem(value: 'Inactive', child: Text(AppStrings.t(provider.settings.appLanguage, en: 'Inactive Only', gu: 'માત્ર નિષ્ક્રિય', hi: 'केवल निष्क्रिय'))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _supplierMasterStatus = val);
                  },
                ),
              ),
            ),
          ],

          // 7. Reset Filters Pill Button (Visible when filters are active on current tab)
          if (hasActiveFilter)
            ActionChip(
              avatar: const Icon(Icons.filter_alt_off_rounded, size: 15, color: Colors.white),
              label: Text(AppStrings.t(provider.settings.appLanguage, en: 'Reset Filters', gu: 'ફિલ્ટર ક્લીયર', hi: 'फ़िल्टर साफ़ करें'), style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.dangerRedDark,
              side: BorderSide.none,
              onPressed: () {
                _searchCtrl.clear();
                provider.resetMaterialFilters();
                setState(() {
                  _productMasterCategory = 'All';
                  _supplierMasterStatus = 'All';
                });
              },
            ),
        ],
      ),
    );
  }

  // Category-specific product dropdown: only shows products of that category
  Widget _buildCategorySpecificProductDropdown(BuildContext context, ProductionProvider provider, int tabIndex) {
    final catName = tabIndex == 1 ? 'Sequence' : (tabIndex == 2 ? 'Beads' : 'Thread');

    // Collect product names from materials in this category
    final set = <String>{};
    for (final m in provider.materials) {
      final isMatch = (catName == 'Dhaga' || catName == 'Thread')
          ? (m.category.toLowerCase() == 'dhaga' || m.category.toLowerCase() == 'daga' || m.category.toLowerCase() == 'thread')
          : (m.category.toLowerCase() == catName.toLowerCase());
      if (isMatch && m.productName.trim().isNotEmpty) {
        set.add(m.productName.trim());
      }
    }
    // Also include active products from master for this category
    for (final p in provider.materialProducts) {
      final isMatch = (catName == 'Dhaga' || catName == 'Thread')
          ? (p.category.toLowerCase() == 'dhaga' || p.category.toLowerCase() == 'daga' || p.category.toLowerCase() == 'thread')
          : (p.category.toLowerCase() == catName.toLowerCase());
      if (isMatch && p.name.trim().isNotEmpty) {
        set.add(p.name.trim());
      }
    }

    final productOptions = ['All Products', ...set.toList()..sort()];

    final currentValue = productOptions.contains(provider.materialProductFilter)
        ? provider.materialProductFilter
        : 'All Products';

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          icon: const Icon(Icons.inventory_2_rounded, size: 16),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
          items: productOptions.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Text(
                p == 'All Products' ? 'All $catName Products' : p.toUpperCase(),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) provider.setMaterialProductFilter(val);
          },
        ),
      ),
    );
  }

  // Supplier Statement & Ledger Banner
  Widget _buildSupplierStatementBanner(BuildContext context, ProductionProvider provider, Color accent) {
    final supplierName = provider.materialSupplierFilter;
    final items = provider.getMaterialsForSupplier(supplierName);
    final totalPurchases = provider.getSupplierTotalAmount(supplierName);
    final paidAmount = provider.getSupplierPaidAmount(supplierName);
    final pendingAmount = provider.getSupplierPendingAmount(supplierName);
    final challans = provider.getChallansForSupplier(supplierName);

    final matching = provider.suppliers.where((s) => s.name.trim().toLowerCase() == supplierName.trim().toLowerCase()).toList();
    final supp = matching.isNotEmpty ? matching.first : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Supplier Header and Action Buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.storefront_rounded, size: 24, color: accent),
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
                            supplierName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${challans.length} Challans • ${items.length} Items',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${AppStrings.t(provider.settings.appLanguage, en: "Supplier Order Statement & Ledger (Raw Material Purchases)", gu: "ઓર્ડર વિગત અને હિસાબ (કાચો માલ ખરીદી)", hi: "सप्लायर ऑर्डर लेजर एवं हिसाब (कच्चा माल खरीद)")}'
                      '${supp != null && supp.phone.isNotEmpty ? " • 📞 ${supp.phone}" : ""}'
                      '${supp != null && supp.city.isNotEmpty ? " • 📍 ${supp.city}" : ""}',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted(context)),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // PDF Export Button
                  ElevatedButton.icon(
                    onPressed: () => _exportSupplierPdf(context, supplierName),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: Text(AppStrings.t(provider.settings.appLanguage, en: 'PDF Statement', gu: 'પીડીએફ સ્ટેટમેન્ટ', hi: 'पीडीएफ स्टेटमेंट')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.12),
                      foregroundColor: const Color(0xFFDC2626),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFDC2626), width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  // Excel Export Button
                  ElevatedButton.icon(
                    onPressed: () => _exportSupplierExcel(context, supplierName),
                    icon: const Icon(Icons.table_chart_rounded, size: 16),
                    label: Text(AppStrings.t(provider.settings.appLanguage, en: 'Excel Report', gu: 'એક્સેલ રિપોર્ટ', hi: 'एक्सेल रिपोर्ट')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669).withValues(alpha: 0.12),
                      foregroundColor: const Color(0xFF059669),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFF059669), width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  // Mark All Paid Button
                  if (pendingAmount > 0)
                    ElevatedButton.icon(
                      onPressed: () => _confirmMarkAllPaid(context, supplierName),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: Text(AppStrings.t(provider.settings.appLanguage, en: 'Mark All Paid to Supplier', gu: 'બધા ચૂકતે કરો', hi: 'सभी भुगतान करें')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  // Clear Supplier Filter
                  IconButton(
                    tooltip: AppStrings.t(provider.settings.appLanguage, en: 'Show All Suppliers', gu: 'તમામ વેપારી દર્શાવો', hi: 'सभी सप्लायर दिखाएं'),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => provider.setMaterialSupplierFilter('All Suppliers'),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surfaceSubtle(context),
                      side: BorderSide(color: AppTheme.border(context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom Row: 3 Financial Metrics Strip
          Row(
            children: [
              _miniKpi(context, AppStrings.t(provider.settings.appLanguage, en: 'Total Purchases', gu: 'કુલ ખરીદી બિલ', hi: 'कुल खरीद बिल'), '₹ ${NumberFormat("#,##,###.00").format(totalPurchases)}', const Color(0xFF2563EB)),
              const SizedBox(width: 12),
              _miniKpi(context, AppStrings.t(provider.settings.appLanguage, en: 'Paid to Supplier', gu: 'સપ્લાયરને ચૂકવેલ', hi: 'सप्लायर को भुगतान'), '₹ ${NumberFormat("#,##,###.00").format(paidAmount)}', const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _miniKpi(
                context,
                AppStrings.t(provider.settings.appLanguage, en: 'Payable Balance Due', gu: 'સપ્લાયરને ચૂકવવાનું બાકી', hi: 'सप्लायर को देय बाकी'),
                '₹ ${NumberFormat("#,##,###.00").format(pendingAmount)}',
                pendingAmount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. KPI Summary Strip (5 Essential Metrics for Raw Material Purchases & Accounts Payable)
  Widget _buildKpiStrip(
    BuildContext context,
    double totalAmount,
    double paidAmount,
    double pendingAmount,
    double totalQty,
    int totalItems,
    int totalChallans,
  ) {
    final lang = context.watch<ProductionProvider>().settings.appLanguage;
    return Row(
      children: [
        _miniKpi(
          context,
          AppStrings.t(lang, en: 'Total Purchases', gu: 'કુલ ખરીદી બિલ', hi: 'कुल खरीद बिल'),
          '₹ ${NumberFormat('#,##,###.00').format(totalAmount)}',
          const Color(0xFF2563EB),
        ),
        const SizedBox(width: 10),
        _miniKpi(
          context,
          AppStrings.t(lang, en: 'Paid to Suppliers', gu: 'સપ્લાયરને ચૂકવેલ', hi: 'सप्लायर को भुगतान'),
          '₹ ${NumberFormat('#,##,###.00').format(paidAmount)}',
          const Color(0xFF10B981),
        ),
        const SizedBox(width: 10),
        _miniKpi(
          context,
          AppStrings.t(lang, en: 'Payable Balance Due', gu: 'સપ્લાયરને ચૂકવવાનું બાકી', hi: 'सप्लायर को देय बाकी'),
          '₹ ${NumberFormat('#,##,###.00').format(pendingAmount)}',
          pendingAmount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        ),
        const SizedBox(width: 10),
        _miniKpi(
          context,
          AppStrings.t(lang, en: 'Inward Stock / Qty', gu: 'ખરીદી જથ્થો (આવક)', hi: 'खरीद मात्रा (आवक)'),
          '${NumberFormat('#,##,###.00').format(totalQty)} units',
          const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 10),
        _miniKpi(
          context,
          AppStrings.t(lang, en: 'Purchase Challans', gu: 'ખરીદી ચલણ સંખ્યા', hi: 'खरीद चालान संख्या'),
          '$totalChallans Challans',
          const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _miniKpi(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Tab 0: Challan Register (Fixed Screen Width, No Horizontal Scroll)
  Widget _buildChallanRegisterTab(BuildContext context, List<ChallanSummary> challans, Color accent) {
    final lang = context.watch<ProductionProvider>().settings.appLanguage;
    if (challans.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No Challans Found',
        subtitle: 'Click "Add Material Entry" to record your first challan bill.',
        onAction: () => _openAddEntry(),
      );
    }

    final isDark = AppTheme.isDark(context);
    final headerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary(context),
    );

    final sortedChallans = List<ChallanSummary>.from(challans);
    sortedChallans.sort((a, b) {
      final idA = (a.items.isNotEmpty ? a.items.first.id : null) ?? int.tryParse(a.challanNo) ?? 0;
      final idB = (b.items.isNotEmpty ? b.items.first.id : null) ?? int.tryParse(b.challanNo) ?? 0;
      return _sortIdAscending ? idA.compareTo(idB) : idB.compareTo(idA);
    });

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          // 1. Pinned Header Row (100% Width, Fits Screen)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: AppTheme.border(context))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: InkWell(
                    onTap: () => setState(() => _sortIdAscending = !_sortIdAscending),
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#ID', style: headerStyle),
                        const SizedBox(width: 3),
                        Icon(
                          _sortIdAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 13,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(flex: 11, child: Text(AppStrings.t(lang, en: 'Date', gu: 'તારીખ', hi: 'तारीख'), style: headerStyle)),
                Expanded(flex: 12, child: Text('Challan #', style: headerStyle)),
                Expanded(flex: 18, child: Text(AppStrings.t(lang, en: 'Supplier / Vendor', gu: 'વેપારી (સપ્લાયર)', hi: 'सप्लायर / व्यापारी'), style: headerStyle)),
                Expanded(flex: 14, child: Text('Categories', style: headerStyle)),
                Expanded(flex: 11, child: Text(AppStrings.t(lang, en: 'Inward Qty', gu: 'ખરીદી જથ્થો', hi: 'आवक मात्रा'), style: headerStyle, textAlign: TextAlign.right)),
                Expanded(flex: 15, child: Text(AppStrings.t(lang, en: 'Purchase Bill (₹)', gu: 'ખરીદી બિલ (₹)', hi: 'खरीद बिल (₹)'), style: headerStyle, textAlign: TextAlign.right)),
                Expanded(flex: 16, child: Text(AppStrings.t(lang, en: 'Payment to Supplier', gu: 'સપ્લાયરને ચૂકવણી', hi: 'सप्लायर को भुगतान'), style: headerStyle, textAlign: TextAlign.center)),
                Expanded(flex: 7, child: Text('Details', style: headerStyle, textAlign: TextAlign.center)),
              ],
            ),
          ),

          // 2. Vertical Scrollable List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: sortedChallans.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.border(context).withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final ch = sortedChallans[index];
                final isPaid = ch.isPaid;
                final isPartial = ch.isPartiallyPaid;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openChallanDetails(ch),
                    hoverColor: accent.withValues(alpha: 0.05),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      child: Row(
                        children: [
                          // 0. #ID
                          Expanded(
                            flex: 7,
                            child: Text(
                              ch.items.isNotEmpty && ch.items.first.id != null ? '#${ch.items.first.id}' : '—',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                          ),
                          // 1. Date
                          Expanded(
                            flex: 11,
                            child: Text(
                              DateFormat('dd-MM-yyyy').format(ch.date),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                          // 2. Challan # Badge
                          Expanded(
                            flex: 13,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.receipt_rounded, size: 12, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '#${ch.challanNo}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'monospace',
                                          color: Color(0xFF0284C7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // 3. Supplier Name
                          Expanded(
                            flex: 19,
                            child: Text(
                              ch.supplierName.isEmpty ? '—' : ch.supplierName,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 4. Categories & Items Count
                          Expanded(
                            flex: 17,
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ...ch.categories.take(2).map((c) {
                                  final color = c == 'Sequence'
                                      ? const Color(0xFF2563EB)
                                      : c == 'Beads'
                                          ? const Color(0xFF7C3AED)
                                          : const Color(0xFF059669);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(c, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color)),
                                  );
                                }),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceSubtle(context),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${ch.itemCount} ${ch.itemCount == 1 ? "item" : "items"}',
                                    style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted(context), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 5. Total Qty
                          Expanded(
                            flex: 11,
                            child: Text(
                              NumberFormat('#,##,###.00').format(ch.totalQty),
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          // 6. Total Amount
                          Expanded(
                            flex: 15,
                            child: Text(
                              '₹ ${NumberFormat('#,##,###.00').format(ch.totalAmount)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.successGreenDark),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          // 7. Payment Status Clickable Chip
                          Expanded(
                            flex: 16,
                            child: Center(
                              child: Tooltip(
                                message: isPaid
                                    ? 'Paid to Supplier ${ch.supplierName} (સપ્લાયરને ચૂકવી દીધેલ)'
                                    : 'Payable to Supplier ${ch.supplierName} (સપ્લાયરને ચૂકવવાનું બાકી)',
                                child: InkWell(
                                  onTap: () => _showPaymentStatusToggleDialog(context, ch),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: isPaid
                                          ? const Color(0xFF10B981).withValues(alpha: 0.14)
                                          : isPartial
                                              ? const Color(0xFFF59E0B).withValues(alpha: 0.14)
                                              : const Color(0xFFEF4444).withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isPaid
                                            ? const Color(0xFF10B981).withValues(alpha: 0.45)
                                            : isPartial
                                                ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
                                                : const Color(0xFFEF4444).withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPaid
                                              ? Icons.check_circle_rounded
                                              : isPartial
                                                  ? Icons.timelapse_rounded
                                                  : Icons.pending_rounded,
                                          size: 12,
                                          color: isPaid
                                              ? const Color(0xFF10B981)
                                              : isPartial
                                                  ? const Color(0xFFF59E0B)
                                                  : const Color(0xFFEF4444),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            isPaid
                                                ? AppStrings.t(lang, en: 'Paid', gu: 'ચૂકતે', hi: 'भुगतान')
                                                : isPartial
                                                    ? AppStrings.t(lang, en: 'Partial', gu: 'અંશતઃ', hi: 'आंशिक')
                                                    : AppStrings.t(lang, en: 'Pending', gu: 'બાકી', hi: 'लंबित'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isPaid
                                                  ? const Color(0xFF10B981)
                                                  : isPartial
                                                      ? const Color(0xFFF59E0B)
                                                      : const Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 8. Action: View Details
                          Expanded(
                            flex: 7,
                            child: Center(
                              child: IconButton(
                                icon: const Icon(Icons.visibility_rounded, size: 17),
                                tooltip: AppStrings.t(lang, en: 'View Details', gu: 'વિગત જુઓ', hi: 'विवरण देखें'),
                                color: accent,
                                onPressed: () => _openChallanDetails(ch),
                                style: IconButton.styleFrom(
                                  backgroundColor: accent.withValues(alpha: 0.12),
                                  padding: const EdgeInsets.all(5),
                                  minimumSize: const Size(30, 30),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Tabs 1, 2, 3: Category Items (Sequence, Beads, Dhaga)
  Widget _buildCategoryItemsTab(BuildContext context, String category, Color catColor) {
    final provider = context.watch<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final items = provider.getFilteredMaterialsForCategory(category);

    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category_outlined,
        title: 'No $category Records Found',
        subtitle: 'Click "Add Material Entry" to add records for $category.',
        onAction: () => _openAddEntry(category),
      );
    }

    final isDark = AppTheme.isDark(context);
    final headerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary(context),
    );

    final sortedItems = List<MaterialItem>.from(items);
    sortedItems.sort((a, b) {
      final idA = a.id ?? 0;
      final idB = b.id ?? 0;
      return _sortIdAscending ? idA.compareTo(idB) : idB.compareTo(idA);
    });

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          // 1. Pinned Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: AppTheme.border(context))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 8,
                  child: InkWell(
                    onTap: () => setState(() => _sortIdAscending = !_sortIdAscending),
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#ID', style: headerStyle),
                        const SizedBox(width: 3),
                        Icon(
                          _sortIdAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 13,
                          color: catColor,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(flex: 14, child: Text('Date / Challan #', style: headerStyle)),
                Expanded(flex: 22, child: Text('Product & Specs', style: headerStyle)),
                Expanded(flex: 16, child: Text(AppStrings.t(lang, en: 'Supplier / Vendor', gu: 'વેપારી (સપ્લાયર)', hi: 'सप्लायर / व्यापारी'), style: headerStyle)),
                Expanded(flex: 11, child: Text(AppStrings.t(lang, en: 'Purchased Qty', gu: 'ખરીદી જથ્થો', hi: 'खरीद मात्रा'), style: headerStyle, textAlign: TextAlign.right)),
                Expanded(flex: 9, child: Text('Rate (₹)', style: headerStyle, textAlign: TextAlign.right)),
                Expanded(flex: 13, child: Text(AppStrings.t(lang, en: 'Purchase Amt (₹)', gu: 'ખરીદી રકમ (₹)', hi: 'खरीद राशि (₹)'), style: headerStyle, textAlign: TextAlign.right)),
                Expanded(flex: 13, child: Text(AppStrings.t(lang, en: 'Payment to Supplier', gu: 'સપ્લાયરને ચૂકવણી', hi: 'सप्लायर को भुगतान'), style: headerStyle, textAlign: TextAlign.center)),
                Expanded(flex: 10, child: Text('Actions', style: headerStyle, textAlign: TextAlign.center)),
              ],
            ),
          ),

          // 2. Vertical Scrollable List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: sortedItems.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.border(context).withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final item = sortedItems[index];
                final isPaid = item.isPaid;

                final specs = [
                  item.itemType,
                  if (item.mm > 0) '${item.mm.toStringAsFixed(0)}mm',
                  if (item.mtr > 0) '${item.mtr.toStringAsFixed(0)}m',
                ].join(' • ');

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openChallanByNo(item.challanNo),
                    hoverColor: catColor.withValues(alpha: 0.05),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          // 0. #ID
                          Expanded(
                            flex: 8,
                            child: Text(
                              item.id != null ? '#${item.id}' : '—',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                          ),
                          // 1. Date & Challan #
                          Expanded(
                            flex: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.formattedDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.challanNo.isNotEmpty ? '#${item.challanNo}' : 'No Challan',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'monospace',
                                      color: catColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 2. Product & Specs
                          Expanded(
                            flex: 22,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName.toUpperCase(),
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (specs.isNotEmpty)
                                  Text(
                                    specs,
                                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          // 3. Supplier / Party
                          Expanded(
                            flex: 16,
                            child: Text(
                              item.supplierName.isEmpty ? '—' : item.supplierName,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 4. Quantity
                          Expanded(
                            flex: 11,
                            child: Text(
                              '${NumberFormat("#,##,###.00").format(item.qty)} ${item.itemType}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          // 5. Rate
                          Expanded(
                            flex: 9,
                            child: Text(
                              '₹ ${item.rate.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          // 6. Total Amount
                          Expanded(
                            flex: 13,
                            child: Text(
                              '₹ ${NumberFormat("#,##,###.00").format(item.amount)}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppTheme.successGreenDark),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          // 7. Payment Status Chip
                          Expanded(
                            flex: 13,
                            child: Center(
                              child: Tooltip(
                                message: isPaid
                                    ? 'Paid to Supplier ${item.supplierName} (સપ્લાયરને ચૂકવી દીધેલ)'
                                    : 'Payable to Supplier ${item.supplierName} (સપ્લાયરને ચૂકવવાનું બાકી)',
                                child: InkWell(
                                  onTap: () => _showItemPaymentStatusToggleDialog(context, item),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isPaid
                                          ? const Color(0xFF10B981).withValues(alpha: 0.14)
                                          : const Color(0xFFEF4444).withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isPaid
                                            ? const Color(0xFF10B981).withValues(alpha: 0.45)
                                            : const Color(0xFFEF4444).withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                                          size: 11,
                                          color: isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            isPaid
                                                ? AppStrings.t(lang, en: 'Paid', gu: 'ચૂકતે', hi: 'भुगतान')
                                                : AppStrings.t(lang, en: 'Pending', gu: 'બાકી', hi: 'लंबित'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10.5,
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
                            ),
                          ),
                          // 8. Actions
                          Expanded(
                            flex: 10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'Print Item PDF Challan',
                                  child: InkWell(
                                    onTap: () => _printSingleItemChallanPdf(item),
                                    borderRadius: BorderRadius.circular(4),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.picture_as_pdf_outlined, size: 15, color: Color(0xFFDC2626)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Tooltip(
                                  message: 'Edit',
                                  child: InkWell(
                                    onTap: () => _openEditEntry(item),
                                    borderRadius: BorderRadius.circular(4),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.edit_outlined, size: 15),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Tooltip(
                                  message: 'Delete',
                                  child: InkWell(
                                    onTap: () => _confirmDeleteItem(item),
                                    borderRadius: BorderRadius.circular(4),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.delete_outline_rounded, size: 15, color: AppTheme.dangerRedDark),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Tab 4: Products Master
  Widget _buildProductsMasterTab(BuildContext context, List<MaterialProduct> products, Color accent) {
    final provider = context.watch<ProductionProvider>();
    final query = provider.materialSearchQuery.trim().toLowerCase();

    final filtered = products.where((p) {
      if (_productMasterCategory != 'All' && p.category.toLowerCase() != _productMasterCategory.toLowerCase()) {
        return false;
      }
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.unit.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final idA = a.id ?? 0;
      final idB = b.id ?? 0;
      return _sortIdAscending ? idA.compareTo(idB) : idB.compareTo(idA);
    });

    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No Products in Master',
        subtitle: 'Click "New Product Master" to add products and define default prices.',
        onAction: () => _openAddProduct(),
      );
    }

    final isDark = AppTheme.isDark(context);
    final headerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary(context),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: AppTheme.border(context))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 8,
                  child: InkWell(
                    onTap: () => setState(() => _sortIdAscending = !_sortIdAscending),
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#ID', style: headerStyle),
                        const SizedBox(width: 3),
                        Icon(
                          _sortIdAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 13,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(flex: 28, child: Text(AppStrings.t(provider.settings.appLanguage, en: 'Product Name', gu: 'પ્રોડક્ટનું નામ', hi: 'उत्पाद का नाम'), style: headerStyle)),
                Expanded(flex: 16, child: Text('Category', style: headerStyle)),
                Expanded(flex: 14, child: Text('Default Rate (₹)', style: headerStyle, textAlign: TextAlign.right)),
                Expanded(flex: 14, child: Text('Unit / Form', style: headerStyle, textAlign: TextAlign.center)),
                Expanded(flex: 18, child: Text('Specs (MTR / MM)', style: headerStyle)),
                Expanded(flex: 10, child: Text('Actions', style: headerStyle, textAlign: TextAlign.center)),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.border(context).withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final prod = filtered[index];
                final lang = provider.settings.appLanguage;
                final catColor = prod.category == 'Sequence'
                    ? const Color(0xFF2563EB)
                    : prod.category == 'Beads'
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF059669);

                final specs = [
                  if (prod.defaultMm > 0) '${prod.defaultMm.toStringAsFixed(0)}mm',
                  if (prod.defaultMtr > 0) '${prod.defaultMtr.toStringAsFixed(0)}m',
                  if (prod.notes.isNotEmpty) prod.notes,
                ].join(' • ');

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // 1. ID
                      Expanded(
                        flex: 8,
                        child: Text(
                          '#${prod.id ?? "—"}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: AppTheme.textMuted(context),
                          ),
                        ),
                      ),
                      // 2. Product Name
                      Expanded(
                        flex: 28,
                        child: Row(
                          children: [
                            Icon(Icons.style_rounded, size: 15, color: catColor),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                prod.name.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 3. Category
                      Expanded(
                        flex: 16,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: catColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                            child: Text(AppStrings.categoryName(prod.category, lang), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: catColor)),
                          ),
                        ),
                      ),
                      // 4. Default Rate
                      Expanded(
                        flex: 14,
                        child: Text(
                          '₹ ${prod.defaultRate.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.successGreenDark),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      // 5. Unit / Form
                      Expanded(
                        flex: 14,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.surfaceSubtle(context), borderRadius: BorderRadius.circular(4), border: Border.all(color: AppTheme.border(context))),
                            child: Text(prod.unit, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      // 6. Specs
                      Expanded(
                        flex: 18,
                        child: Text(
                          specs.isEmpty ? '—' : specs,
                          style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted(context)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 7. Actions
                      Expanded(
                        flex: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Edit Product',
                              onPressed: () => _openEditProduct(prod),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRedDark),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Delete Product',
                              onPressed: () => _confirmDeleteProduct(prod),
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
        ],
      ),
    );
  }

  // Tab 5: Suppliers Master (Fixed Width, No Horizontal Scroll)
  Widget _buildSuppliersMasterTab(BuildContext context, List<Supplier> suppliers, Color accent) {
    final provider = context.watch<ProductionProvider>();
    final query = provider.materialSearchQuery.trim().toLowerCase();

    final filtered = suppliers.where((s) {
      if (_supplierMasterStatus == 'Active' && !s.isActive) return false;
      if (_supplierMasterStatus == 'Inactive' && s.isActive) return false;
      if (query.isEmpty) return true;
      return s.name.toLowerCase().contains(query) ||
          s.phone.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final idA = a.id ?? 0;
      final idB = b.id ?? 0;
      return _sortIdAscending ? idA.compareTo(idB) : idB.compareTo(idA);
    });

    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: Icons.storefront_outlined,
        title: 'No Suppliers in Master',
        subtitle: 'Click "New Supplier" to register party names for quick selection during material entry.',
        onAction: () => _openAddSupplier(),
      );
    }

    final isDark = AppTheme.isDark(context);
    final headerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary(context),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: AppTheme.border(context))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 8,
                  child: InkWell(
                    onTap: () => setState(() => _sortIdAscending = !_sortIdAscending),
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#ID', style: headerStyle),
                        const SizedBox(width: 3),
                        Icon(
                          _sortIdAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 13,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(flex: 22, child: Text(AppStrings.t(provider.settings.appLanguage, en: 'Supplier Name', gu: 'સપ્લાયરનું નામ', hi: 'सप्लायर का नाम'), style: headerStyle)),
                Expanded(flex: 16, child: Text('Mobile / City', style: headerStyle)),
                Expanded(flex: 20, child: Text('Total Orders & Purchases', style: headerStyle)),
                Expanded(flex: 12, child: Text('Status', style: headerStyle, textAlign: TextAlign.center)),
                Expanded(flex: 24, child: Text('Actions & Statement', style: headerStyle, textAlign: TextAlign.center)),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.border(context).withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final supp = filtered[index];
                final supplierItems = provider.getMaterialsForSupplier(supp.name);
                final totalSpend = supplierItems.fold(0.0, (sum, i) => sum + i.amount);
                final challanCount = provider.getChallansForSupplier(supp.name).length;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // 1. #ID
                      Expanded(
                        flex: 8,
                        child: Text(
                          '#${supp.id ?? "—"}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: AppTheme.textMuted(context),
                          ),
                        ),
                      ),
                      // 2. Name
                      Expanded(
                        flex: 22,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: accent.withValues(alpha: 0.15),
                              child: Text(
                                supp.name.isNotEmpty ? supp.name[0].toUpperCase() : 'S',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                supp.name.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 3. Mobile / City
                      Expanded(
                        flex: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              supp.phone.isEmpty ? '—' : supp.phone,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: supp.phone.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                                color: supp.phone.isNotEmpty ? AppTheme.primaryBlue : AppTheme.textMuted(context),
                              ),
                            ),
                            if (supp.city.isNotEmpty)
                              Text(supp.city, style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
                          ],
                        ),
                      ),
                      // 4. Total Orders & Purchases
                      Expanded(
                        flex: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹ ${NumberFormat("#,##,###.00").format(totalSpend)}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.successGreenDark),
                            ),
                            Text(
                              '$challanCount Challans • ${supplierItems.length} Items',
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                            ),
                          ],
                        ),
                      ),
                      // 5. Status
                      Expanded(
                        flex: 12,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: supp.isActive ? AppTheme.successGreenDark.withValues(alpha: 0.12) : AppTheme.dangerRedDark.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: supp.isActive ? AppTheme.successGreenDark.withValues(alpha: 0.3) : AppTheme.dangerRedDark.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              supp.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: supp.isActive ? AppTheme.successGreenDark : AppTheme.dangerRedDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 6. Actions & Statements
                      Expanded(
                        flex: 24,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // View Orders & Statement in Challan Register
                            ElevatedButton.icon(
                              onPressed: () {
                                provider.setMaterialSupplierFilter(supp.name);
                                _tabController.animateTo(0);
                              },
                              icon: const Icon(Icons.receipt_long_rounded, size: 12),
                              label: const Text('Orders', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent.withValues(alpha: 0.15),
                                foregroundColor: accent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Quick PDF Statement
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFFDC2626)),
                              tooltip: 'PDF Statement',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _exportSupplierPdf(context, supp.name),
                            ),
                            // Quick Excel Report
                            IconButton(
                              icon: const Icon(Icons.table_chart_rounded, size: 16, color: Color(0xFF059669)),
                              tooltip: 'Excel Report',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _exportSupplierExcel(context, supp.name),
                            ),
                            // Edit
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Edit Supplier',
                              onPressed: () => _openEditSupplier(supp),
                            ),
                            // Delete
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRedDark),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Delete Supplier',
                              onPressed: () => _confirmDeleteSupplier(supp),
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
        ],
      ),
    );
  }

  // Empty State Widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.textMuted(context)),
            const SizedBox(height: 14),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted(context)), textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Entry Now'),
            ),
          ],
        ),
      ),
    );
  }
}
