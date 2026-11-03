import 'package:flutter_test/flutter_test.dart';
import 'package:emb_cal/providers/production_provider.dart';
import 'package:emb_cal/core/calculation_engine.dart';

void main() {
  group('Validation Tests', () {
    test('Total Stitch validation rejects empty, zero, negative, and invalid text', () {
      expect(ProductionProvider.validateTotalStitch(''), isNotNull);
      expect(ProductionProvider.validateTotalStitch('   '), isNotNull);
      expect(ProductionProvider.validateTotalStitch('0'), isNotNull);
      expect(ProductionProvider.validateTotalStitch('-500'), isNotNull);
      expect(ProductionProvider.validateTotalStitch('abc'), isNotNull);
      expect(ProductionProvider.validateTotalStitch('300000'), isNull);
      expect(ProductionProvider.validateTotalStitch('450,000'), isNull);
    });

    test('Rate validation rejects zero, negative, empty, and non-numbers', () {
      expect(ProductionProvider.validateRate(''), isNotNull);
      expect(ProductionProvider.validateRate('0'), isNotNull);
      expect(ProductionProvider.validateRate('-1.25'), isNotNull);
      expect(ProductionProvider.validateRate('abc'), isNotNull);
      expect(ProductionProvider.validateRate('1.25'), isNull);
      expect(ProductionProvider.validateRate('1.50'), isNull);
    });

    test('Heads validation rejects zero, negative, empty, and non-integers', () {
      expect(ProductionProvider.validateHeads(''), isNotNull);
      expect(ProductionProvider.validateHeads('0'), isNotNull);
      expect(ProductionProvider.validateHeads('-12'), isNotNull);
      expect(ProductionProvider.validateHeads('150'), isNotNull); // Exceeds 100 limit
      expect(ProductionProvider.validateHeads('12'), isNull);
      expect(ProductionProvider.validateHeads('16'), isNull);
    });

    test('Design No validation rejects empty string', () {
      expect(ProductionProvider.validateDesignNo(''), isNotNull);
      expect(ProductionProvider.validateDesignNo('   '), isNotNull);
      expect(ProductionProvider.validateDesignNo('D001'), isNull);
      expect(ProductionProvider.validateDesignNo('ROSE-01'), isNull);
    });
  });

  group('Range Safety and Edge Cases', () {
    test('CalculationEngine handles zero and negative safely without crashing', () {
      final res = CalculationEngine.calculate(totalStitch: 0, rate: 0.0, heads: 0);
      expect(res.finalStitch, equals(0.0));
      expect(res.amount, equals(0.0));
      expect(res.finalAmount, equals(0.0));
    });

    test('CalculationEngine handles large stitch counts properly', () {
      final res = CalculationEngine.calculate(totalStitch: 8450000, rate: 1.25, heads: 12);
      expect(res.finalStitch, equals(8450.0));
      expect(res.amount, equals(10562.5));
      expect(res.finalAmount, equals(126750.0));
    });
  });
}
