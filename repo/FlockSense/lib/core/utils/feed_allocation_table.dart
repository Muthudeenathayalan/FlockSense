/// Feed phase allocation model and transitions for broiler flocks.
class FeedAllocationTable {
  /// Returns the recommended feed phase based on flock age in days.
  static String getFeedPhase(int ageDays) {
    if (ageDays <= 10) return 'Pre-Starter / Starter';
    if (ageDays <= 24) return 'Grower';
    return 'Finisher';
  }

  /// Calculates total cumulative feed requirement in kilograms for a batch.
  static double estimateTotalFeedRequirementKg({
    required int birdCount,
    required int targetAgeDays,
  }) {
    if (birdCount <= 0 || targetAgeDays <= 0) return 0.0;
    // Commercial rule of thumb: ~3.8kg feed consumed per 2.2kg broiler at day 35
    final kgPerBird = targetAgeDays <= 10
        ? 0.28
        : targetAgeDays <= 24
            ? 1.50
            : 3.85;
    return double.parse((birdCount * kgPerBird).toStringAsFixed(1));
  }

  /// Calculates estimated 50kg feed bags needed.
  static int estimateBagsNeeded({required int birdCount, required int targetAgeDays}) {
    final totalKg = estimateTotalFeedRequirementKg(birdCount: birdCount, targetAgeDays: targetAgeDays);
    return (totalKg / 50.0).ceil();
  }
}
