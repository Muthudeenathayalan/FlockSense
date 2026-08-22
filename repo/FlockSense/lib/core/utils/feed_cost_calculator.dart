/// Feed cost economics and margin analysis calculator.
class FeedCostCalculator {
  /// Calculates feed cost per kg of live weight produced:
  /// Feed Cost / kg = (FCR * Price per kg of feed)
  static double calculateFeedCostPerKgLive({
    required double fcr,
    required double feedPricePerKg,
  }) {
    if (fcr <= 0.0 || feedPricePerKg <= 0.0) return 0.0;
    return double.parse((fcr * feedPricePerKg).toStringAsFixed(2));
  }

  /// Calculates gross liveweight margin per kg:
  /// Margin / kg = Sale Price per kg - Feed Cost per kg
  static double calculateGrossMarginPerKg({
    required double salePricePerKg,
    required double feedCostPerKg,
  }) {
    return double.parse((salePricePerKg - feedCostPerKg).toStringAsFixed(2));
  }
}
