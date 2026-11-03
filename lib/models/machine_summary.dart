/// Summary model for machine-level production aggregation
class MachineSummary {
  final String machineNo;
  final int totalEntries;
  final int totalStitch;
  final double totalAmount;
  final double finalAmount;

  const MachineSummary({
    required this.machineNo,
    required this.totalEntries,
    required this.totalStitch,
    required this.totalAmount,
    required this.finalAmount,
  });
}
