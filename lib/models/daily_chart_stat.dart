/// Daily chart statistics model used for performance and trend visualizations
class DailyChartStat {
  final String dateLabel;
  final DateTime date;
  final double totalAmount;
  final double finalAmount;

  const DailyChartStat({
    required this.dateLabel,
    required this.date,
    required this.totalAmount,
    required this.finalAmount,
  });
}
