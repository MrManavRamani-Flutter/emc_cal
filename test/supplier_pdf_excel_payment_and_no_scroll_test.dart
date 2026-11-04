import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:emb_cal/models/material_item.dart';
import 'package:emb_cal/models/challan_summary.dart';
import 'package:emb_cal/models/supplier.dart';
import 'package:emb_cal/providers/production_provider.dart';
import 'package:emb_cal/screens/materials/materials_screen.dart';
import 'package:emb_cal/data/excel_exporter.dart';
import 'package:emb_cal/data/pdf_exporter.dart';

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

  group('Supplier Orders, Excel, PDF & Payment Status Tests', () {
    test('ExcelExporter generates non-empty byte buffer for supplier statement', () {
      final items = [
        MaterialItem(
          id: 1,
          challanNo: '1001',
          supplierName: 'Jay Ambe Thread',
          date: DateTime(2026, 11, 1),
          category: 'Sequence',
          productName: 'L L CHIKKU cd (5mm)',
          itemType: 'cd',
          qty: 150,
          rate: 87.4,
          amount: 13110,
          paymentStatus: 'Paid',
        ),
        MaterialItem(
          id: 2,
          challanNo: '1002',
          supplierName: 'Jay Ambe Thread',
          date: DateTime(2026, 11, 2),
          category: 'Dhaga',
          productName: 'Metallic Gold Zari',
          itemType: 'Cone',
          qty: 50,
          rate: 120,
          amount: 6000,
          paymentStatus: 'Pending',
        ),
      ];

      final excelBytes = ExcelExporter.generateSupplierExcel(
        supplierName: 'Jay Ambe Thread',
        items: items,
        phone: '9876543210',
        city: 'Surat',
      );

      expect(excelBytes, isNotNull);
      expect(excelBytes!.isNotEmpty, isTrue);
    });

    test('PdfExporter generates non-empty PDF bytes for supplier statement and challan invoice', () async {
      final items = [
        MaterialItem(
          id: 1,
          challanNo: '1001',
          supplierName: 'Jay Ambe Thread',
          date: DateTime(2026, 11, 1),
          category: 'Sequence',
          productName: 'L L CHIKKU cd (5mm)',
          itemType: 'cd',
          qty: 150,
          rate: 87.4,
          amount: 13110,
          paymentStatus: 'Paid',
        ),
      ];

      final supplierPdfBytes = await PdfExporter.generateSupplierStatementPdf(
        supplierName: 'Jay Ambe Thread',
        items: items,
        companyName: 'OM MAVTAR GROUP',
        phone: '9876543210',
        city: 'Surat',
      );

      expect(supplierPdfBytes, isNotNull);
      expect(supplierPdfBytes.isNotEmpty, isTrue);

      final challanSummary = ChallanSummary(
        challanNo: '1001',
        date: DateTime(2026, 11, 1),
        supplierName: 'Jay Ambe Thread',
        items: items,
      );

      final challanPdfBytes = await PdfExporter.generateChallanInvoicePdf(
        challan: challanSummary,
        companyName: 'OM MAVTAR GROUP',
      );

      expect(challanPdfBytes, isNotNull);
      expect(challanPdfBytes.isNotEmpty, isTrue);

      // Verify authentic amount in words helper
      expect(PdfExporter.amountInWords(8433.00), 'Eight Thousand Four Hundred Thirty Three Rupees Only');
      expect(PdfExporter.amountInWords(20945.60), 'Twenty Thousand Nine Hundred Forty Five Rupees And Sixty Paise Only');

      // Verify separate material item challan generation
      final singleItemChallan = ChallanSummary(
        challanNo: '4043',
        date: DateTime(2026, 11, 1),
        supplierName: 'BHAGWATI JARI',
        items: [
          MaterialItem(
            id: 14,
            challanNo: '4043',
            supplierName: 'BHAGWATI JARI',
            date: DateTime(2026, 11, 1),
            category: 'Thread',
            productName: 'GOLDAN SAMK JARI 200G',
            itemType: 'cone',
            qty: 120.0,
            rate: 115.0,
            amount: 13800.0,
          ),
        ],
      );
      final singleItemPdf = await PdfExporter.generateChallanInvoicePdf(
        challan: singleItemChallan,
        supplierPhone: '9737211542',
        supplierCity: '109, HARI OM IND. ESTATE, AANJANA FARM, SURAT',
      );
      expect(singleItemPdf.isNotEmpty, isTrue);
    });

    test('ChallanSummary and Provider correctly track Paid vs Pending balances', () {
      final items = [
        MaterialItem(
          id: 1,
          challanNo: 'CH-1',
          supplierName: 'Test Supplier',
          date: DateTime(2026, 11, 1),
          category: 'Sequence',
          productName: 'Seq 1',
          itemType: 'cd',
          qty: 100,
          rate: 10,
          amount: 1000,
          paymentStatus: 'Paid',
        ),
        MaterialItem(
          id: 2,
          challanNo: 'CH-1',
          supplierName: 'Test Supplier',
          date: DateTime(2026, 11, 1),
          category: 'Sequence',
          productName: 'Seq 2',
          itemType: 'cd',
          qty: 200,
          rate: 10,
          amount: 2000,
          paymentStatus: 'Pending',
        ),
      ];

      final challan = ChallanSummary(
        challanNo: 'CH-1',
        date: DateTime(2026, 11, 1),
        supplierName: 'Test Supplier',
        items: items,
      );

      expect(challan.isPaid, isFalse);
      expect(challan.isPartiallyPaid, isTrue);
      expect(challan.paymentStatus, 'Partial');
      expect(challan.totalAmount, 3000.0);
      expect(challan.paidAmount, 1000.0);
      expect(challan.pendingAmount, 2000.0);

      final provider = ProductionProvider();
      provider.materials.addAll(items);
      provider.suppliers.add(Supplier(id: 1, name: 'Test Supplier', city: 'Surat', phone: '1234567890'));

      expect(provider.getMaterialsForSupplier('Test Supplier').length, 2);
      expect(provider.getChallansForSupplier('Test Supplier').length, 1);
      expect(provider.getSupplierTotalAmount('Test Supplier'), 3000.0);
      expect(provider.getSupplierPaidAmount('Test Supplier'), 1000.0);
      expect(provider.getSupplierPendingAmount('Test Supplier'), 2000.0);
    });

    testWidgets('Selecting a supplier in dropdown renders Supplier Statement Banner with PDF & Excel buttons', (tester) async {
      final provider = ProductionProvider();
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      final items = [
        MaterialItem(
          id: 1,
          challanNo: '1001',
          supplierName: 'Jay Ambe Thread',
          date: DateTime(2026, 11, 1),
          category: 'Sequence',
          productName: 'L L CHIKKU cd (5mm)',
          itemType: 'cd',
          qty: 150,
          rate: 87.4,
          amount: 13110,
          paymentStatus: 'Paid',
        ),
      ];

      provider.materials.addAll(items);
      provider.suppliers.add(Supplier(id: 1, name: 'Jay Ambe Thread', city: 'Surat', phone: '9876543210'));

      // Set supplier filter
      provider.setMaterialSupplierFilter('Jay Ambe Thread');

      await tester.pumpWidget(createMaterialsWidget(provider));
      await tester.pumpAndSettle();

      // Verify Supplier Statement Banner appears
      expect(find.textContaining('Supplier Order Statement & Ledger'), findsOneWidget);
      expect(find.textContaining('PDF Statement'), findsOneWidget);
      expect(find.textContaining('Excel Report'), findsOneWidget);

      // Verify Paid status chip is displayed
      expect(find.text('Paid'), findsWidgets);
    });

    testWidgets('Items default to ID ascending order and toggle to descending on #ID tap', (tester) async {
      final provider = ProductionProvider();
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      final items = [
        MaterialItem(
          id: 55,
          challanNo: '1002',
          supplierName: 'Party B',
          date: DateTime(2026, 11, 2),
          category: 'Sequence',
          productName: 'Sequins Gold 55',
          itemType: 'piece',
          qty: 10,
          rate: 10,
          amount: 100,
        ),
        MaterialItem(
          id: 12,
          challanNo: '1001',
          supplierName: 'Party A',
          date: DateTime(2026, 11, 1),
          category: 'Sequence',
          productName: 'Sequins Silver 12',
          itemType: 'piece',
          qty: 20,
          rate: 10,
          amount: 200,
        ),
      ];
      provider.materials.addAll(items);

      await tester.pumpWidget(createMaterialsWidget(provider));
      await tester.pumpAndSettle();

      // Go to Sequence tab
      await tester.tap(find.text('SEQUENCE').first);
      await tester.pumpAndSettle();

      // Both items should be present
      expect(find.text('#12'), findsOneWidget);
      expect(find.text('#55'), findsOneWidget);

      // Verify default ascending order (12 comes before 55 visually on Y axis)
      final pos12 = tester.getTopLeft(find.text('#12')).dy;
      final pos55 = tester.getTopLeft(find.text('#55')).dy;
      expect(pos12 < pos55, isTrue, reason: 'ID 12 should appear before ID 55 in default ASC order');

      // Tap on #ID header to toggle to DESC order
      await tester.tap(find.text('#ID').first);
      await tester.pumpAndSettle();

      // Verify descending order (55 comes before 12 visually on Y axis)
      final pos12Desc = tester.getTopLeft(find.text('#12')).dy;
      final pos55Desc = tester.getTopLeft(find.text('#55')).dy;
      expect(pos55Desc < pos12Desc, isTrue, reason: 'ID 55 should appear before ID 12 in DESC order');
    });
  });
}
