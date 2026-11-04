import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:emb_cal/models/material_item.dart';
import 'package:emb_cal/models/material_product.dart';
import 'package:emb_cal/models/supplier.dart';
import 'package:emb_cal/providers/production_provider.dart';
import 'package:emb_cal/screens/materials/materials_screen.dart';
import 'package:emb_cal/screens/materials/add_edit_material_dialog.dart';
import 'package:emb_cal/screens/materials/add_edit_material_product_dialog.dart';
import 'package:emb_cal/screens/materials/add_edit_supplier_dialog.dart';
import 'package:emb_cal/core/localization/app_strings.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget createMaterialsWidget(ProductionProvider provider) {
    return ChangeNotifierProvider<ProductionProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: Scaffold(
          body: MaterialsScreen(),
        ),
      ),
    );
  }

  testWidgets('MaterialsScreen renders segmented desktop tabs with counters', (tester) async {
    final provider = ProductionProvider();
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    await tester.pumpWidget(createMaterialsWidget(provider));
    await tester.pumpAndSettle();

    // Verify Tab titles exist in the segmented control
    expect(find.text('CHALLAN REGISTER'), findsOneWidget);
    expect(find.text('SEQUENCE'), findsOneWidget);
    expect(find.text('BEADS'), findsOneWidget);
    expect(find.text('THREAD'), findsOneWidget);
    expect(find.text('PRODUCTS MASTER'), findsOneWidget);
    expect(find.text('SUPPLIERS MASTER'), findsOneWidget);

    // Verify Tab 0 (Challan Register) filter bar contains search, date, supplier, but NO product filter
    expect(find.text('All Time'), findsOneWidget);
    expect(find.text('Search Challan #, Party / Supplier...'), findsOneWidget);
    expect(find.text('All Products'), findsNothing); // Product dropdown hidden on Challan Register!
  });

  testWidgets('Switching to Sequence tab displays Sequence products filter and #ID column', (tester) async {
    final provider = ProductionProvider();
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    // Seed sample item
    final item = MaterialItem(
      id: 101,
      challanNo: 'CH-99',
      date: DateTime.now(),
      category: 'Sequence',
      productName: 'Gold 5mm Sequins',
      itemType: 'piece',
      qty: 50,
      rate: 10,
      amount: 500,
    );
    provider.materials.add(item);

    await tester.pumpWidget(createMaterialsWidget(provider));
    await tester.pumpAndSettle();

    // Tap on 'Sequence' Tab
    await tester.tap(find.text('SEQUENCE').first);
    await tester.pumpAndSettle();

    // Verify category products filter appears
    expect(find.text('All Sequence Products'), findsOneWidget);

    // Verify #ID column header and #101 badge exist
    expect(find.text('#ID'), findsOneWidget);
    expect(find.text('#101'), findsOneWidget);
    expect(find.text('#CH-99'), findsOneWidget);
  });

  testWidgets('Switching to Products Master shows Category filter and hides Date and Supplier filters', (tester) async {
    final provider = ProductionProvider();
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    final prod = MaterialProduct(
      id: 77,
      name: 'Sample Royal Beads',
      category: 'Beads',
      defaultRate: 25.0,
      unit: 'packet',
    );
    provider.materialProducts.add(prod);

    await tester.pumpWidget(createMaterialsWidget(provider));
    await tester.pumpAndSettle();

    // Tap on 'Products Master' Tab
    await tester.tap(find.text('PRODUCTS MASTER'));
    await tester.pumpAndSettle();

    // Verify Category Filter is present
    expect(find.text('All Categories'), findsOneWidget);

    // Verify Date & Supplier filters are HIDDEN on Products Master
    expect(find.text('All Time'), findsNothing);
    expect(find.text('All Suppliers (વ્યાપારી)'), findsNothing);

    // Verify Product #ID badge is rendered
    expect(find.text('#ID'), findsOneWidget);
    expect(find.text('#77'), findsOneWidget);
    expect(find.text('SAMPLE ROYAL BEADS'), findsOneWidget);
  });

  testWidgets('Switching to Suppliers Master shows Status and City filters and hides Date and Product filters', (tester) async {
    final provider = ProductionProvider();
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    final supp = Supplier(
      id: 88,
      name: 'Jay Ambe Enterprise',
      city: 'Surat',
      phone: '9876543210',
    );
    provider.suppliers.add(supp);

    await tester.pumpWidget(createMaterialsWidget(provider));
    await tester.pumpAndSettle();

    // Tap on 'Suppliers Master' Tab
    await tester.tap(find.text('SUPPLIERS MASTER'));
    await tester.pumpAndSettle();

    // Verify Status Filter is present
    expect(find.text('All Status'), findsOneWidget);

    // Verify Date, Supplier, Product dropdowns are HIDDEN
    expect(find.text('All Time'), findsNothing);
    expect(find.text('All Products'), findsNothing);

    // Verify Supplier #ID badge
    expect(find.text('#ID'), findsOneWidget);
    expect(find.text('#88'), findsOneWidget);
    expect(find.text('JAY AMBE ENTERPRISE'), findsOneWidget);
  });

  testWidgets('Add Material Entry button converts dialog to full screen with Back button', (tester) async {
    final provider = ProductionProvider();
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    await tester.pumpWidget(createMaterialsWidget(provider));
    await tester.pumpAndSettle();

    // Click on 'Add Purchase Challan Entry'
    final addBtn = find.textContaining('Purchase Challan Entry');
    await tester.tap(addBtn.evaluate().isNotEmpty ? addBtn : find.byIcon(Icons.add_shopping_cart_rounded));
    await tester.pumpAndSettle();

    // Verify AddEditMaterialDialog is rendered full screen (asScreen: true)
    expect(find.byType(AddEditMaterialDialog), findsOneWidget);
    expect(find.byTooltip(AppStrings.get('back', provider.settings.appLanguage)), findsOneWidget);
    expect(find.textContaining('Purchase Challan & Inward Bill'), findsOneWidget);

    // Click Back to Material Section
    await tester.tap(find.byTooltip(AppStrings.get('back', provider.settings.appLanguage)));
    await tester.pumpAndSettle();

    // Returns cleanly to list view
    expect(find.byType(AddEditMaterialDialog), findsNothing);
    expect(find.text('CHALLAN REGISTER'), findsOneWidget);
  });

  testWidgets('New Product Master button opens full screen product setup and can return', (tester) async {
    final provider = ProductionProvider();
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    await tester.pumpWidget(createMaterialsWidget(provider));
    await tester.pumpAndSettle();

    // Click on 'New Product Master'
    await tester.tap(find.text('New Product Master'));
    await tester.pumpAndSettle();

    // Verify AddEditMaterialProductDialog is rendered full screen
    expect(find.byType(AddEditMaterialProductDialog), findsOneWidget);
    expect(find.byTooltip(AppStrings.get('back', provider.settings.appLanguage)), findsOneWidget);

    // Click Back to return
    await tester.tap(find.byTooltip(AppStrings.get('back', provider.settings.appLanguage)));
    await tester.pumpAndSettle();

    expect(find.byType(AddEditMaterialProductDialog), findsNothing);
    expect(find.text('CHALLAN REGISTER'), findsOneWidget);
  });

  testWidgets('New Supplier button opens full screen supplier master and can return', (tester) async {
    final provider = ProductionProvider();
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    await tester.pumpWidget(createMaterialsWidget(provider));
    await tester.pumpAndSettle();

    // Click on 'New Supplier'
    await tester.tap(find.text('New Supplier'));
    await tester.pumpAndSettle();

    // Verify AddEditSupplierDialog is rendered full screen
    expect(find.byType(AddEditSupplierDialog), findsOneWidget);
    expect(find.byTooltip(AppStrings.get('back', provider.settings.appLanguage)), findsOneWidget);

    // Click Back to return
    await tester.tap(find.byTooltip(AppStrings.get('back', provider.settings.appLanguage)));
    await tester.pumpAndSettle();

    expect(find.byType(AddEditSupplierDialog), findsNothing);
    expect(find.text('CHALLAN REGISTER'), findsOneWidget);
  });

  testWidgets('Clicking Challan # opens full screen Calculation Statement with Ledger Table and Step-by-Step Math', (tester) async {
    final provider = ProductionProvider();
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    final item = MaterialItem(
      id: 55,
      challanNo: 'CH-888',
      supplierName: 'Khushi Fashion',
      date: DateTime(2026, 10, 15),
      category: 'Sequence',
      productName: 'L L CHIKKU cd',
      itemType: 'cd',
      qty: 150,
      rate: 87.4,
      amount: 13110,
    );
    provider.materials.add(item);

    await tester.pumpWidget(createMaterialsWidget(provider));
    await tester.pumpAndSettle();

    // Verify Challan #CH-888 is displayed in Challan Register
    expect(find.text('#CH-888'), findsOneWidget);

    // Click on Challan #CH-888
    await tester.tap(find.text('#CH-888'));
    await tester.pumpAndSettle();

    // Verify Calculation Statement screen elements
    expect(find.textContaining('Calculation Statement'), findsOneWidget);
    expect(find.byTooltip(AppStrings.get('back', provider.settings.appLanguage)), findsOneWidget);
    expect(find.text('Itemized Calculation Sheet'), findsOneWidget);
    expect(find.text('Qty × Rate = Amount'), findsOneWidget);
    expect(find.text('CALCULATION DETAILS'), findsOneWidget);
    expect(find.textContaining('Total Purchase Bill Payable to Supplier'), findsOneWidget);
    expect(find.text('150.0 × ₹87.40'), findsOneWidget);

    // Click Back to Challan Register
    await tester.tap(find.byTooltip(AppStrings.get('back', provider.settings.appLanguage)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Calculation Statement'), findsNothing);
    expect(find.text('CHALLAN REGISTER'), findsOneWidget);
  });

  testWidgets('Category tabs show exact items: Sequence (2), Beads (2), Dhaga (2) and Challan Register shows 5', (tester) async {
    final provider = ProductionProvider();
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    // Seed 1 Sequence challan with 2 items, 2 Dhaga challans (1 item each), 2 Beads challans (1 item each)
    provider.materials.addAll([
      MaterialItem(
        id: 1,
        challanNo: '1086',
        supplierName: 'Khushi Fashion',
        date: DateTime(2026, 10, 15),
        category: 'Sequence',
        productName: 'L L CHIKKU cd',
        itemType: 'cd',
        qty: 150,
        rate: 87.4,
        amount: 13110,
      ),
      MaterialItem(
        id: 2,
        challanNo: '1086',
        supplierName: 'Khushi Fashion',
        date: DateTime(2026, 10, 15),
        category: 'Sequence',
        productName: 'L L CHIKKU firka',
        itemType: 'firka',
        qty: 96,
        rate: 150.0,
        amount: 14400,
      ),
      MaterialItem(
        id: 3,
        challanNo: 'CH-4091',
        supplierName: 'Vardhman Threads',
        date: DateTime(2026, 10, 18),
        category: 'Dhaga',
        productName: 'Dull Gold Metallic Zari',
        itemType: 'Cone',
        qty: 120,
        rate: 85.0,
        amount: 10200,
      ),
      MaterialItem(
        id: 4,
        challanNo: 'CH-4120',
        supplierName: 'Vardhman Threads',
        date: DateTime(2026, 10, 20),
        category: 'Dhaga',
        productName: 'Royal Blue Viscose Rayon',
        itemType: 'Cone',
        qty: 80,
        rate: 95.0,
        amount: 7600,
      ),
      MaterialItem(
        id: 5,
        challanNo: 'BD-882',
        supplierName: 'Shreeji Beads',
        date: DateTime(2026, 10, 22),
        category: 'Beads',
        productName: 'Gold Hex Cutdana Beads',
        itemType: 'Packet',
        qty: 50,
        rate: 160.0,
        amount: 8000,
      ),
      MaterialItem(
        id: 6,
        challanNo: 'BD-895',
        supplierName: 'Shreeji Beads',
        date: DateTime(2026, 10, 24),
        category: 'Beads',
        productName: 'Pearl White Round Moti',
        itemType: 'Packet',
        qty: 40,
        rate: 140.0,
        amount: 5600,
      ),
    ]);

    // Check provider level calculations first
    expect(provider.challanSummaries.length, 5); // 5 Challans in register
    expect(provider.getFilteredMaterialsForCategory('Sequence').length, 2);
    expect(provider.getFilteredMaterialsForCategory('Beads').length, 2);
    expect(provider.getFilteredMaterialsForCategory('Dhaga').length, 2);

    await tester.pumpWidget(createMaterialsWidget(provider));
    await tester.pumpAndSettle();

    // Verify Tab 0 (Challan Register) shows all 5 challan rows
    expect(find.text('#1086'), findsOneWidget);
    expect(find.text('#CH-4091'), findsOneWidget);
    expect(find.text('#CH-4120'), findsOneWidget);
    expect(find.text('#BD-882'), findsOneWidget);
    expect(find.text('#BD-895'), findsOneWidget);

    // Switch to Sequence tab
    await tester.tap(find.text('SEQUENCE').first);
    await tester.pumpAndSettle();
    expect(find.text('L L CHIKKU CD'), findsOneWidget);
    expect(find.text('L L CHIKKU FIRKA'), findsOneWidget);

    // Switch to Thread tab
    await tester.tap(find.text('THREAD').first);
    await tester.pumpAndSettle();
    expect(find.text('DULL GOLD METALLIC ZARI'), findsOneWidget);
    expect(find.text('ROYAL BLUE VISCOSE RAYON'), findsOneWidget);

    // Switch to Beads tab
    await tester.tap(find.text('BEADS').first);
    await tester.pumpAndSettle();
    expect(find.text('GOLD HEX CUTDANA BEADS'), findsOneWidget);
    expect(find.text('PEARL WHITE ROUND MOTI'), findsOneWidget);
  });
}

