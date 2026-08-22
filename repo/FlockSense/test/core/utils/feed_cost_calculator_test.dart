import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/feed_cost_calculator.dart';

void main() {
  group('FeedCostCalculator Tests', () {
    test('calculates feed cost per kg live weight correctly', () {
      final cost = FeedCostCalculator.calculateFeedCostPerKgLive(
        fcr: 1.55,
        feedPricePerKg: 38.0,
      );
      expect(cost, 58.90);
    });

    test('calculates gross margin per kg live weight correctly', () {
      final margin = FeedCostCalculator.calculateGrossMarginPerKg(
        salePricePerKg: 85.0,
        feedCostPerKg: 58.90,
      );
      expect(margin, 26.10);
    });
  });
}
