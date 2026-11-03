import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emb_cal/models/supplier.dart';
import 'package:emb_cal/models/material_product.dart';
import 'package:emb_cal/widgets/searchable_supplier_picker.dart';
import 'package:emb_cal/widgets/searchable_product_picker.dart';

void main() {
  final sampleSuppliers = List.generate(
    30,
    (i) => Supplier(
      id: i + 1,
      name: 'Supplier ${i + 1} Surat',
      phone: '98765432${i.toString().padLeft(2, '0')}',
      city: 'Surat',
    ),
  );

  final sampleProducts = List.generate(
    30,
    (i) => MaterialProduct(
      id: i + 1,
      name: 'Item Product ${i + 1}',
      category: 'Sequence',
      defaultRate: 15.0 + i,
      unit: 'roll',
    ),
  );

  group('SearchablePicker Auto-Scroll Tests', () {
    testWidgets('SearchableSupplierPicker auto-scrolls to pre-selected supplier on open',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchableSupplierPicker(
              suppliers: sampleSuppliers,
              selectedSupplierName: 'Supplier 22 Surat',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Open picker modal
      await tester.tap(find.byType(SearchableSupplierPicker));
      await tester.pumpAndSettle();

      // Verify that Supplier 22 Surat is in the dialog list and visible
      expect(
        find.descendant(of: find.byType(Dialog), matching: find.text('Supplier 22 Surat')),
        findsOneWidget,
      );

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).last);
      expect(scrollable.position.pixels, greaterThan(0.0));
    });

    testWidgets('SearchableSupplierPicker arrowDown auto-scrolls down when item moves below viewport',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchableSupplierPicker(
              suppliers: sampleSuppliers,
              selectedSupplierName: '',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Open picker modal
      await tester.tap(find.byType(SearchableSupplierPicker));
      await tester.pumpAndSettle();

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).last);
      expect(scrollable.position.pixels, equals(0.0));

      // Press ArrowDown 15 times to navigate down deep into the list
      for (int i = 0; i < 15; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }

      // Scroll position must have moved down automatically to keep the 15th item in view
      expect(scrollable.position.pixels, greaterThan(200.0));

      // Press PageUp to jump back up
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();

      // Press Home key to jump back to top
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();

      expect(scrollable.position.pixels, equals(0.0));
    });

    testWidgets('SearchableProductPicker auto-scrolls to pre-selected product on open',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchableProductPicker(
              products: sampleProducts,
              selectedProduct: sampleProducts[20],
              category: 'Sequence',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Open picker modal
      await tester.tap(find.byType(SearchableProductPicker));
      await tester.pumpAndSettle();

      // Verify that Item Product 21 is in the dialog list and visible
      expect(
        find.descendant(of: find.byType(Dialog), matching: find.text('Item Product 21')),
        findsOneWidget,
      );

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).last);
      expect(scrollable.position.pixels, greaterThan(0.0));
    });

    testWidgets('SearchableProductPicker arrow keys navigate and auto-scroll viewport',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchableProductPicker(
              products: sampleProducts,
              selectedProduct: null,
              category: 'Sequence',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Open picker modal
      await tester.tap(find.byType(SearchableProductPicker));
      await tester.pumpAndSettle();

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).last);
      expect(scrollable.position.pixels, equals(0.0));

      // Press ArrowDown 12 times
      for (int i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }

      // It must auto-scroll down to keep the selected item in view
      expect(scrollable.position.pixels, greaterThan(150.0));

      // Entering search text resets scroll to 0.0
      await tester.enterText(find.byType(TextField), 'Product 1');
      await tester.pumpAndSettle();

      expect(scrollable.position.pixels, equals(0.0));
    });
  });
}
