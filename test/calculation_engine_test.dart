import 'package:flutter_test/flutter_test.dart';
import 'package:emb_cal/core/calculation_engine.dart';

void main() {
  group('Embroidery Calculation Engine Tests', () {
    test('Calculates row 1 correctly: 300,000 stitches, ₹1.25 rate, 12 heads', () {
      final result = CalculationEngine.calculate(
        totalStitch: 300000,
        rate: 1.25,
        heads: 12,
      );

      expect(result.finalStitch, equals(300.0));
      expect(result.amount, equals(375.0));
      expect(result.finalAmount, equals(4500.0));
    });

    test('Calculates row 2 correctly: 450,000 stitches, ₹1.50 rate, 15 heads', () {
      final result = CalculationEngine.calculate(
        totalStitch: 450000,
        rate: 1.50,
        heads: 15,
      );

      expect(result.finalStitch, equals(450.0));
      expect(result.amount, equals(675.0));
      expect(result.finalAmount, equals(10125.0));
    });

    test('Calculates row 9 correctly with decimal amount: 275,000 stitches, ₹1.25 rate, 10 heads', () {
      final result = CalculationEngine.calculate(
        totalStitch: 275000,
        rate: 1.25,
        heads: 10,
      );

      expect(result.finalStitch, equals(275.0));
      expect(result.amount, equals(343.75));
      expect(result.finalAmount, equals(3437.50));
    });
  });
}
