import 'package:flutter_test/flutter_test.dart';
import 'package:emb_cal/models/production_record.dart';
import 'package:emb_cal/core/calculation_engine.dart';

bool evaluateCanEdit(Set<int> selectedIds, ProductionRecord? target) {
  return (selectedIds.length == 1) || (selectedIds.isEmpty && target != null);
}

void main() {
  group('Dashboard Single-Selection Edit Logic Tests', () {
    test('canEdit is true when exactly 1 checkbox is selected', () {
      final selectedIds = <int>{101};
      final ProductionRecord? rowSelection = null;

      expect(evaluateCanEdit(selectedIds, rowSelection), isTrue);
    });

    test('canEdit is false when 0 items are selected and no row clicked', () {
      final selectedIds = <int>{};
      final ProductionRecord? rowSelection = null;

      expect(evaluateCanEdit(selectedIds, rowSelection), isFalse);
    });

    test('canEdit is false when 2 or more checkboxes are selected', () {
      final selectedIds = <int>{101, 102};
      final dummyRecord = ProductionRecord(
        id: 101,
        date: DateTime.now(),
        machineNo: 'M-1',
        designNo: 'D-101',
        totalStitch: 100000,
        finalStitch: 100.0,
        rate: 1.5,
        amount: 150.0,
        heads: 12,
        finalAmount: 1800.0,
      );

      expect(evaluateCanEdit(selectedIds, dummyRecord), isFalse);
    });

    test('canEdit is true when 0 checkboxes but exactly 1 row is clicked', () {
      final selectedIds = <int>{};
      final dummyRecord = ProductionRecord(
        id: 101,
        date: DateTime.now(),
        machineNo: 'M-1',
        designNo: 'D-101',
        totalStitch: 100000,
        finalStitch: 100.0,
        rate: 1.5,
        amount: 150.0,
        heads: 12,
        finalAmount: 1800.0,
      );

      expect(evaluateCanEdit(selectedIds, dummyRecord), isTrue);
    });
  });

  group('Embroidery Calculation FAQ Formula Tests', () {
    test('Step-by-step formula matches FAQ documentation', () {
      const stitches = 300000;
      const rate = 1.25;
      const heads = 12;

      // Step 1: Final Stitch = Total Stitch / 1000
      final finalStitch = stitches / 1000.0;
      expect(finalStitch, equals(300.0));

      // Step 2: Base Amount = Final Stitch * Rate
      final baseAmount = finalStitch * rate;
      expect(baseAmount, equals(375.0));

      // Step 3: Final Amount = Base Amount * Heads
      final finalAmount = baseAmount * heads;
      expect(finalAmount, equals(4500.0));

      // Compare with CalculationEngine output
      final calcResult = CalculationEngine.calculate(
        totalStitch: stitches,
        rate: rate,
        heads: heads,
      );

      expect(calcResult.finalStitch, equals(finalStitch));
      expect(calcResult.amount, equals(baseAmount));
      expect(calcResult.finalAmount, equals(finalAmount));
    });
  });
}
