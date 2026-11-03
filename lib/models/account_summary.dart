/// Summary model for account-level production aggregation
class AccountSummary {
  final String accountName;
  final int totalEntries;
  final int totalStitch;
  final double totalAmount;
  final double finalAmount;
  final int dayEntries;
  final int nightEntries;
  final int dayStitch;
  final int nightStitch;
  final double dayAmount;
  final double nightAmount;

  const AccountSummary({
    required this.accountName,
    required this.totalEntries,
    required this.totalStitch,
    required this.totalAmount,
    required this.finalAmount,
    required this.dayEntries,
    required this.nightEntries,
    required this.dayStitch,
    required this.nightStitch,
    required this.dayAmount,
    required this.nightAmount,
  });
}
