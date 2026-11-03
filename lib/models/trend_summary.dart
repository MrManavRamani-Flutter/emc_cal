/// Enumeration of trend aggregation periods
enum TrendPeriod { day, week, month, year }

/// Single data point inside a performance trend series
class TrendDataPoint {
  final String label;
  final DateTime date;
  final double amount;
  final double finalAmount;
  final int totalStitch;
  final int entryCount;
  final double changeAmount;
  final double percentChange;
  final bool isPositive;

  const TrendDataPoint({
    required this.label,
    required this.date,
    required this.amount,
    required this.finalAmount,
    required this.totalStitch,
    required this.entryCount,
    required this.changeAmount,
    required this.percentChange,
    required this.isPositive,
  });
}

/// Comprehensive trend summary for period-over-period comparisons
class TrendSummary {
  final TrendPeriod period;
  final double currentAmount;
  final double previousAmount;
  final double diffAmount;
  final double percentDiff;
  final bool isPositive;
  final int totalStitch;
  final int entryCount;
  final List<TrendDataPoint> points;

  const TrendSummary({
    required this.period,
    required this.currentAmount,
    required this.previousAmount,
    required this.diffAmount,
    required this.percentDiff,
    required this.isPositive,
    required this.totalStitch,
    required this.entryCount,
    required this.points,
  });
}
