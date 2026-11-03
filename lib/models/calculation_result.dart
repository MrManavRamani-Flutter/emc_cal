/// Output result of the embroidery calculation engine
class CalculationResult {
  final int totalStitch;
  final double finalStitch;
  final double rate;
  final double amount;
  final int heads;
  final double finalAmount;

  const CalculationResult({
    required this.totalStitch,
    required this.finalStitch,
    required this.rate,
    required this.amount,
    required this.heads,
    required this.finalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalStitch': totalStitch,
      'finalStitch': finalStitch,
      'rate': rate,
      'amount': amount,
      'heads': heads,
      'finalAmount': finalAmount,
    };
  }
}
