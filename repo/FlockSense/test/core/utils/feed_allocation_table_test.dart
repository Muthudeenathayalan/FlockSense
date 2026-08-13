import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/feed_allocation_table.dart';

void main() {
  group('FeedAllocationTable Tests', () {
    test('determines correct phase based on bird age', () {
      expect(FeedAllocationTable.getFeedPhase(5), 'Pre-Starter / Starter');
      expect(FeedAllocationTable.getFeedPhase(15), 'Grower');
      expect(FeedAllocationTable.getFeedPhase(32), 'Finisher');
    });

    test('calculates feed requirements and 50kg bag counts accurately', () {
      final totalKg = FeedAllocationTable.estimateTotalFeedRequirementKg(
        birdCount: 1000,
        targetAgeDays: 35,
      );
      expect(totalKg, 3850.0);
      expect(FeedAllocationTable.estimateBagsNeeded(birdCount: 1000, targetAgeDays: 35), 77);
    });
  });
}
