import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/flock_plan/domain/flock_lifecycle_standard.dart';

class DailyGuidanceResult {
  final int ageDays;
  final String phase;
  final double targetWeightGrams;
  final double dailyFeedPerBirdGrams;
  final double totalEstimatedFeedKg;
  final double targetTempCelsius;
  final int recommendedLightHours;
  final String? scheduledVaccine;
  final String primaryTip;
  final List<String> actionItems;
  final String pushNotificationTitle;
  final String pushNotificationBody;

  const DailyGuidanceResult({
    required this.ageDays,
    required this.phase,
    required this.targetWeightGrams,
    required this.dailyFeedPerBirdGrams,
    required this.totalEstimatedFeedKg,
    required this.targetTempCelsius,
    required this.recommendedLightHours,
    this.scheduledVaccine,
    required this.primaryTip,
    required this.actionItems,
    required this.pushNotificationTitle,
    required this.pushNotificationBody,
  });
}

class DailyRecommendationService {
  DailyRecommendationService._();

  /// Computes personalized, age-specific recommendations and action plans
  /// for an active batch based on global breed standards and recent telemetry.
  static DailyGuidanceResult getGuidanceForBatch({
    required BatchModel batch,
    List<DailyRecordModel> recentRecords = const [],
  }) {
    final now = DateTime.now();
    final rawAge = now.difference(batch.placementDate).inDays + 1;
    final ageDays = rawAge < 1 ? 1 : rawAge;

    final std = FlockLifecycleStandard.getForDay(ageDays);
    final totalFeedKg = (std.dailyFeedPerBirdGrams * (batch.currentBirds > 0 ? batch.currentBirds : 1000)) / 1000.0;

    final actionItems = <String>[];
    String? primaryTip;

    // 1. Vaccine / Medication scheduled priority
    String? scheduledVaccine;
    if (std.vaccineName != null && std.vaccineName!.isNotEmpty) {
      scheduledVaccine = std.vaccineName;
      final routeStr = std.vaccineRoute != null ? ' via ${std.vaccineRoute}' : '';
      final vacTip = 'Vaccination due today: ${std.vaccineName}$routeStr. Withhold chlorinated water 24h prior.';
      actionItems.add(vacTip);
      primaryTip ??= 'Vaccination due today: ${std.vaccineName}';
    }

    // 2. Telemetry Anomaly Checks from latest record
    if (recentRecords.isNotEmpty) {
      final sortedRecords = List<DailyRecordModel>.from(recentRecords)
        ..sort((a, b) => b.recordDate.compareTo(a.recordDate));
      final latest = sortedRecords.first;

      // High mortality check
      if (latest.mortalityCount > 0 && latest.openingBirds > 0) {
        final mortPct = (latest.mortalityCount / latest.openingBirds) * 100.0;
        if (mortPct >= 1.0) {
          final mortTip = 'High mortality detected yesterday (${latest.mortalityCount} birds, ${mortPct.toStringAsFixed(1)}%). Check water lines, air velocity, and isolate sick birds.';
          actionItems.insert(0, mortTip);
          primaryTip = 'High mortality warning: inspect shed airflow & drinkers';
        }
      }

      // Heat stress & THI check
      if (latest.temperature != null && latest.temperature! >= 32.5) {
        final hum = latest.humidity ?? 65.0;
        final thi = 0.8 * latest.temperature! + (hum / 100) * (latest.temperature! - 14.4) + 46.4;
        if (thi >= 78.0) {
          final heatTip = 'Heat stress risk (THI ${thi.toStringAsFixed(1)}). Activate cooling pads, run foggers, and ensure cool drinking water.';
          actionItems.add(heatTip);
          primaryTip ??= 'Heat stress alert: run cooling pads & fans';
        }
      }

      // Water to feed ratio check
      if (latest.waterConsumedLiters > 0 && latest.feedConsumedKg > 0) {
        final ratio = latest.waterConsumedLiters / latest.feedConsumedKg;
        if (ratio > 2.2) {
          actionItems.add('Water-to-feed ratio is elevated (${ratio.toStringAsFixed(1)}:1). Check for drinker line leaks or panting.');
        } else if (ratio < 1.6) {
          actionItems.add('Water consumption is low (${ratio.toStringAsFixed(1)}:1). Inspect nipple drinkers for mineral or biofilm blockages.');
        }
      }
    }

    // 3. Lifecycle stage specific guidance
    if (ageDays <= 4) {
      primaryTip ??= 'Maintain brooding temperature at ${std.targetTempCelsius}°C and check 24h crop fill (>95%).';
      actionItems.add('Check chick paper feeding and maintain 32–33°C at chick height.');
      actionItems.add('Provide 24 hours of light for active feed and water discovery.');
    } else if (ageDays <= 7) {
      primaryTip ??= 'Target 7-day body weight is ${std.targetWeightGrams.toStringAsFixed(0)}g (4.5x hatch weight). Prepare for Day 7 vaccine.';
      actionItems.add('Sample weigh 50–100 chicks to verify 7-day weight gain milestone.');
      actionItems.add('Begin gradual temperature step-down to ${std.targetTempCelsius}°C.');
    } else if (ageDays <= 14) {
      primaryTip ??= 'Target weight: ${std.targetWeightGrams.toStringAsFixed(0)}g | Target feed: ${std.dailyFeedPerBirdGrams.toStringAsFixed(0)}g/bird (${std.feedType}).';
      actionItems.add('Provide ${std.lightingHours} hours of light and ${24 - std.lightingHours} hours of uninterrupted darkness for skeletal growth.');
      actionItems.add('Target shed temperature: ${std.targetTempCelsius}°C.');
    } else if (ageDays <= 21) {
      primaryTip ??= 'Transition phase: target weight ${std.targetWeightGrams.toStringAsFixed(0)}g | Feed: ${std.feedType}.';
      actionItems.add('Shift feed from Starter to Grower crumble to support rapid muscle development.');
      actionItems.add('Adjust feeder pan height so the pan lip aligns with the birds\' backs.');
    } else if (ageDays <= 35) {
      primaryTip ??= 'Peak growth velocity: target weight ${std.targetWeightGrams.toStringAsFixed(0)}g. Maintain high ventilation.';
      actionItems.add('Ensure maximum tunnel ventilation and check litter moisture under drinker lines.');
      actionItems.add('Transition to Finisher feed pellets (${std.dailyFeedPerBirdGrams.toStringAsFixed(0)}g/bird target).');
    } else {
      primaryTip ??= 'Pre-harvest window: observe medication withdrawal periods. Target weight: ${std.targetWeightGrams.toStringAsFixed(0)}g.';
      actionItems.add('Ensure all antibiotic and coccidiostat withdrawal periods are observed prior to bird sales.');
      actionItems.add('Schedule harvest bird catching logistics and dim lights to minimize stress.');
    }

    // Management tasks from breed standards
    if (std.managementTasks.isNotEmpty) {
      for (final task in std.managementTasks) {
        if (!actionItems.any((item) => item.toLowerCase().contains(task.toLowerCase()))) {
          actionItems.add(task);
        }
      }
    }

    final pushTitle = '📝 Day $ageDays Log — ${batch.batchName}';
    final pushBody = 'Tap to record today\'s mortality, feed & water.\n💡 Recommendation: $primaryTip';

    return DailyGuidanceResult(
      ageDays: ageDays,
      phase: std.phase,
      targetWeightGrams: std.targetWeightGrams,
      dailyFeedPerBirdGrams: std.dailyFeedPerBirdGrams,
      totalEstimatedFeedKg: totalFeedKg,
      targetTempCelsius: std.targetTempCelsius,
      recommendedLightHours: std.lightingHours,
      scheduledVaccine: scheduledVaccine,
      primaryTip: primaryTip,
      actionItems: actionItems,
      pushNotificationTitle: pushTitle,
      pushNotificationBody: pushBody,
    );
  }
}
