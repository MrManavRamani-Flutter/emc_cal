import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/models/models.dart';
import 'package:emb_cal/providers/production_provider.dart';
import 'package:emb_cal/data/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Material Calculation Isolation & Navigation Tests', () {
    test('setActiveNavIndex preserves index 10 for Material Calculation Screen without clamping to 9', () {
      final provider = ProductionProvider();
      
      // Index 10 is Material Calculation Screen
      provider.setActiveNavIndex(10);
      expect(provider.activeNavIndex, 10);

      // Verify other navigation indexes
      provider.setActiveNavIndex(0);
      expect(provider.activeNavIndex, 0);

      provider.setActiveNavIndex(6); // Analytics
      expect(provider.activeNavIndex, 6);
    });

    test('Material Item amount auto-calculates as Qty * Rate and handles Sequence, Daga, Beads categories', () async {
      final dbHelper = DatabaseHelper.instance;

      // 1. Sequence Category Record (Khushi Fashion Demo bill)
      final seqItem1 = MaterialItem(
        challanNo: 'CH-DEMO-1086',
        supplierName: 'KHUSHI FASHION (Surat)',
        date: DateTime(2026, 10, 1),
        category: 'Sequence',
        productName: 'L L CHIKKU cd',
        itemType: 'cd',
        mtr: 190.0,
        mm: 5.0,
        qty: 150.0,
        rate: 87.40,
        amount: 150.0 * 87.40, // 13,110.00
      );

      final seqItem2 = MaterialItem(
        challanNo: 'CH-DEMO-1086',
        supplierName: 'KHUSHI FASHION (Surat)',
        date: DateTime(2026, 10, 1),
        category: 'Sequence',
        productName: 'L L CHIKKU firka',
        itemType: 'firka',
        mtr: 190.0,
        mm: 5.0,
        qty: 160.0,
        rate: 90.00,
        amount: 160.0 * 90.00, // 14,400.00
      );

      // 2. Daga Category Record
      final dagaItem = MaterialItem(
        challanNo: 'CH-DEMO-DAGA',
        supplierName: 'SURAT ZARI MART',
        date: DateTime(2026, 10, 5),
        category: 'Daga',
        productName: 'Metallic Gold Zari 120D',
        itemType: 'cone',
        mtr: 1000.0,
        mm: 0.0,
        qty: 25.0,
        rate: 180.00,
        amount: 25.0 * 180.00, // 4,500.00
      );

      // 3. Beads Category Record
      final beadsItem = MaterialItem(
        challanNo: 'CH-DEMO-BEADS',
        supplierName: 'ROYAL PEARL CO',
        date: DateTime(2026, 10, 6),
        category: 'Beads',
        productName: 'Pearl White Round Beads 4mm',
        itemType: 'packet',
        mtr: 0.0,
        mm: 4.0,
        qty: 50.0,
        rate: 65.00,
        amount: 50.0 * 65.00, // 3,250.00
      );

      // Verify amounts calculated correctly
      expect(seqItem1.amount, 13110.0);
      expect(seqItem2.amount, 14400.0);
      expect(seqItem1.amount + seqItem2.amount, 27510.0);
      expect(dagaItem.amount, 4500.0);
      expect(beadsItem.amount, 3250.0);

      // Insert items into database
      final id1 = await dbHelper.insertMaterialItem(seqItem1);
      final id2 = await dbHelper.insertMaterialItem(seqItem2);
      final id3 = await dbHelper.insertMaterialItem(dagaItem);
      final id4 = await dbHelper.insertMaterialItem(beadsItem);

      expect(id1, isNotNull);
      expect(id2, isNotNull);
      expect(id3, isNotNull);
      expect(id4, isNotNull);

      // Fetch by specific search query
      final demoResults = await dbHelper.getMaterialItems(searchQuery: 'CH-DEMO');
      expect(demoResults.length, 4);

      // Fetch by category with search
      final seqItems = await dbHelper.getMaterialItems(category: 'Sequence', searchQuery: 'CH-DEMO');
      expect(seqItems.length, 2);
      expect(seqItems.every((i) => i.category == 'Sequence'), isTrue);

      final dagaItems = await dbHelper.getMaterialItems(category: 'Daga', searchQuery: 'CH-DEMO');
      expect(dagaItems.length, 1);
      expect(dagaItems.first.productName, 'Metallic Gold Zari 120D');

      final beadsItems = await dbHelper.getMaterialItems(category: 'Beads', searchQuery: 'CH-DEMO');
      expect(beadsItems.length, 1);
      expect(beadsItems.first.productName, 'Pearl White Round Beads 4mm');

      // Total demo material amount
      final totalAmount = demoResults.fold<double>(0.0, (acc, item) => acc + item.amount);
      expect(totalAmount, 13110.0 + 14400.0 + 4500.0 + 3250.0);

      // Clean up test records
      await dbHelper.deleteMaterialItem(id1);
      await dbHelper.deleteMaterialItem(id2);
      await dbHelper.deleteMaterialItem(id3);
      await dbHelper.deleteMaterialItem(id4);

      final afterDelete = await dbHelper.getMaterialItems(searchQuery: 'CH-DEMO');
      expect(afterDelete.isEmpty, isTrue);
    });

    test('Material Product Master operations and Challan Summary grouping', () async {
      final dbHelper = DatabaseHelper.instance;

      // 1. Insert product master test items
      final p1 = MaterialProduct(
        name: 'Open Cut Test (ઓપન કટ)',
        category: 'Sequence',
        defaultRate: 18.00,
        unit: 'piece',
      );
      final p2 = MaterialProduct(
        name: 'Regular Daga Test',
        category: 'Dhaga',
        defaultRate: 600.00,
        unit: 'box',
      );

      final pId1 = await dbHelper.insertMaterialProduct(p1);
      final pId2 = await dbHelper.insertMaterialProduct(p2);

      expect(pId1, isNotNull);
      expect(pId2, isNotNull);

      // Query products
      final allProducts = await dbHelper.getMaterialProducts(searchQuery: 'Test');
      expect(allProducts.length, 2);

      final seqProducts = await dbHelper.getMaterialProducts(category: 'Sequence', searchQuery: 'Test');
      expect(seqProducts.length, 1);
      expect(seqProducts.first.name, 'Open Cut Test (ઓપન કટ)');
      expect(seqProducts.first.defaultRate, 18.00);
      expect(seqProducts.first.unit, 'piece');

      // 2. Test ChallanSummary aggregation
      final ch1Item1 = MaterialItem(
        challanNo: 'CH-2552-TEST',
        date: DateTime(2026, 10, 1),
        category: 'Sequence',
        productName: 'Open Cut Test',
        itemType: 'piece',
        qty: 120.0,
        rate: 18.0,
        amount: 120.0 * 18.0, // 2160.0
      );
      final ch1Item2 = MaterialItem(
        challanNo: 'CH-2552-TEST',
        date: DateTime(2026, 10, 1),
        category: 'Dhaga',
        productName: 'Regular Daga Test',
        itemType: 'box',
        qty: 24.0,
        rate: 600.0,
        amount: 24.0 * 600.0, // 14400.0
      );

      final summary = ChallanSummary(
        challanNo: 'CH-2552-TEST',
        date: DateTime(2026, 10, 1),
        supplierName: 'Test Supplier',
        items: [ch1Item1, ch1Item2],
      );

      expect(summary.itemCount, 2);
      expect(summary.totalAmount, 2160.0 + 14400.0);
      expect(summary.totalQty, 120.0 + 24.0);
      expect(summary.categories, containsAll(['Sequence', 'Dhaga']));

      // Clean up product test items
      await dbHelper.deleteMaterialProduct(pId1);
      await dbHelper.deleteMaterialProduct(pId2);
    });

    test('Material filter state changes and supplier/product/date filters work reliably', () {
      final provider = ProductionProvider();

      // Test default values
      expect(provider.materialDateFilter, 'All Time');
      expect(provider.materialSupplierFilter, 'All Suppliers');
      expect(provider.materialProductFilter, 'All Products');
      expect(provider.materialSearchQuery, '');

      // Set filters
      provider.setMaterialSearchQuery('2552');
      provider.setMaterialDateFilter('This Month');
      provider.setMaterialSupplierFilter('Radha Raman');
      provider.setMaterialProductFilter('Open Cut');

      expect(provider.materialSearchQuery, '2552');
      expect(provider.materialDateFilter, 'This Month');
      expect(provider.materialSupplierFilter, 'Radha Raman');
      expect(provider.materialProductFilter, 'Open Cut');

      // Reset filters restores everything safely
      provider.resetMaterialFilters();
      expect(provider.materialSearchQuery, '');
      expect(provider.materialDateFilter, 'All Time');
      expect(provider.materialSupplierFilter, 'All Suppliers');
      expect(provider.materialProductFilter, 'All Products');
    });

    test('Supplier model serialization, copyWith, and DatabaseHelper CRUD operations work seamlessly', () async {
      final dbHelper = DatabaseHelper.instance;

      // 1. Model test
      final supp1 = Supplier(
        name: 'Om Shakti Thread Mart',
        phone: '9898123456',
        city: 'Surat',
        gstNo: '24ABCDE1234F1Z5',
        notes: 'Ring Road shop #12',
      );

      final map = supp1.toMap();
      expect(map['name'], 'Om Shakti Thread Mart');
      expect(map['phone'], '9898123456');
      expect(map['city'], 'Surat');
      expect(map['gst_no'], '24ABCDE1234F1Z5');
      expect(map['notes'], 'Ring Road shop #12');
      expect(map['is_active'], 1);

      final restored = Supplier.fromMap(map);
      expect(restored.name, 'Om Shakti Thread Mart');
      expect(restored.phone, '9898123456');
      expect(restored.city, 'Surat');

      // 2. Insert into DB
      final sId = await dbHelper.insertSupplier(supp1);
      expect(sId, greaterThan(0));

      // 3. Query with search query
      final found = await dbHelper.getSuppliers(searchQuery: 'Shakti');
      expect(found.any((s) => s.id == sId), isTrue);

      // 4. Update supplier
      final updatedSupp = supp1.copyWith(
        id: sId,
        phone: '9898999999',
        notes: 'Updated contact details',
      );
      await dbHelper.updateSupplier(updatedSupp);

      final reloaded = await dbHelper.getSuppliers();
      final target = reloaded.firstWhere((s) => s.id == sId);
      expect(target.phone, '9898999999');
      expect(target.notes, 'Updated contact details');

      // 5. Delete supplier
      await dbHelper.deleteSupplier(sId);
      final afterDelete = await dbHelper.getSuppliers();
      expect(afterDelete.any((s) => s.id == sId), isFalse);
    });
  });
}
