class FeedSummary {
  const FeedSummary({
    required this.totalReceivedKg,
    required this.totalTransferInKg,
    required this.totalTransferOutKg,
    required this.totalConsumedKg,
    required this.totalAdjustedKg,
    required this.closingStockKg,
    required this.totalFeedCost,
  });

  final double totalReceivedKg;
  final double totalTransferInKg;
  final double totalTransferOutKg;
  final double totalConsumedKg;
  final double totalAdjustedKg;
  final double closingStockKg;
  final double totalFeedCost;

  static const empty = FeedSummary(
    totalReceivedKg: 0,
    totalTransferInKg: 0,
    totalTransferOutKg: 0,
    totalConsumedKg: 0,
    totalAdjustedKg: 0,
    closingStockKg: 0,
    totalFeedCost: 0,
  );
}
