import '../models/calculation_result.dart';
export '../models/calculation_result.dart';


class CalculationEngine {
  /// Stitch divider constant (default 1000)
  static const double defaultStitchDivider = 1000.0;

  /// Formula 1: Final Stitch = Total Stitch ÷ 1000
  static double calculateFinalStitch(int totalStitch, {double stitchDivider = defaultStitchDivider}) {
    if (stitchDivider <= 0) return 0.0;
    return totalStitch / stitchDivider;
  }

  /// Formula 2: Amount = Final Stitch × Rate
  static double calculateAmount(double finalStitch, double rate) {
    return finalStitch * rate;
  }

  /// Formula 3: Final Amount = Amount × Heads
  static double calculateFinalAmount(double amount, int heads) {
    return amount * heads;
  }

  /// Complete calculation pipeline
  static CalculationResult calculate({
    required int totalStitch,
    required double rate,
    required int heads,
    double stitchDivider = defaultStitchDivider,
  }) {
    final finalStitch = calculateFinalStitch(totalStitch, stitchDivider: stitchDivider);
    final amount = calculateAmount(finalStitch, rate);
    final finalAmount = calculateFinalAmount(amount, heads);

    return CalculationResult(
      totalStitch: totalStitch,
      finalStitch: finalStitch,
      rate: rate,
      amount: amount,
      heads: heads,
      finalAmount: finalAmount,
    );
  }

  /// Formats rate preserving up to 3 decimal places (e.g. 0.125 or 1.25)
  static String formatRate(double rate) {
    if ((rate * 100).truncateToDouble() != rate * 100) {
      return rate.toStringAsFixed(3);
    }
    return rate.toStringAsFixed(2);
  }
}
