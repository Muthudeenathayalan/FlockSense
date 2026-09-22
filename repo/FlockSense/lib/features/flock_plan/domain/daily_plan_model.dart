import 'package:flutter/material.dart';

enum TaskCategory {
  feeding,
  water,
  vaccine,
  medicine,
  environment,
  biosecurity,
  diagnostic,
}

extension TaskCategoryX on TaskCategory {
  String get label {
    switch (this) {
      case TaskCategory.feeding:
        return 'Feed & Nutrition';
      case TaskCategory.water:
        return 'Water & Hydration';
      case TaskCategory.vaccine:
        return 'Vaccination';
      case TaskCategory.medicine:
        return 'Medicine & Supplements';
      case TaskCategory.environment:
        return 'Climate & Ventilation';
      case TaskCategory.biosecurity:
        return 'Biosecurity & Hygiene';
      case TaskCategory.diagnostic:
        return 'Diagnostic Alert';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.feeding:
        return Icons.restaurant_rounded;
      case TaskCategory.water:
        return Icons.water_drop_rounded;
      case TaskCategory.vaccine:
        return Icons.vaccines_rounded;
      case TaskCategory.medicine:
        return Icons.medication_rounded;
      case TaskCategory.environment:
        return Icons.thermostat_rounded;
      case TaskCategory.biosecurity:
        return Icons.verified_user_rounded;
      case TaskCategory.diagnostic:
        return Icons.warning_amber_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.feeding:
        return const Color(0xFFD97706); // warm amber
      case TaskCategory.water:
        return const Color(0xFF0284C7); // sky blue
      case TaskCategory.vaccine:
        return const Color(0xFF0D9488); // teal
      case TaskCategory.medicine:
        return const Color(0xFF9333EA); // purple
      case TaskCategory.environment:
        return const Color(0xFFE11D48); // rose red
      case TaskCategory.biosecurity:
        return const Color(0xFF16A34A); // green
      case TaskCategory.diagnostic:
        return const Color(0xFFDC2626); // red alert
    }
  }
}

enum TaskPriority {
  critical,
  high,
  routine,
}

class DailyPlanTask {
  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final bool isCompleted;
  final String? actionLabel;
  final String? actionRoute;
  final bool isRealRecordVerified;
  final String? verificationNote;

  const DailyPlanTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.priority = TaskPriority.routine,
    this.isCompleted = false,
    this.actionLabel,
    this.actionRoute,
    this.isRealRecordVerified = false,
    this.verificationNote,
  });

  DailyPlanTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    bool? isCompleted,
    String? actionLabel,
    String? actionRoute,
    bool? isRealRecordVerified,
    String? verificationNote,
  }) {
    return DailyPlanTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      actionLabel: actionLabel ?? this.actionLabel,
      actionRoute: actionRoute ?? this.actionRoute,
      isRealRecordVerified: isRealRecordVerified ?? this.isRealRecordVerified,
      verificationNote: verificationNote ?? this.verificationNote,
    );
  }
}

class DailyFlockPlan {
  final int day;
  final String phase;
  final int liveBirds;
  final double targetWeightGrams;
  final double dailyFeedPerBirdGrams;
  final double totalFeedKg;
  final double dailyWaterPerBirdMl;
  final double totalWaterLiters;
  final String feedType;
  final double targetTempCelsius;
  final int lightingHours;
  final String? vaccineDue;
  final String? vaccineRoute;
  final String? medicineDue;
  final List<DailyPlanTask> tasks;
  final List<String> diagnosticAlerts;

  // Real-time telemetry & validation fields (from actual user records)
  final bool isRealDataValidated;
  final bool hasLoggedTodayRecord;
  final double? actualFeedGivenKg;
  final double? actualWaterGivenLiters;
  final double? actualAvgWeightGrams;
  final int? actualMortalityToday;
  final int? cumulativeMortality;
  final double? cumulativeMortalityPct;
  final double? actualFcr;
  final double? feedStockDaysRemaining;
  final double? feedStockBagsAvailable;

  const DailyFlockPlan({
    required this.day,
    required this.phase,
    required this.liveBirds,
    required this.targetWeightGrams,
    required this.dailyFeedPerBirdGrams,
    required this.totalFeedKg,
    required this.dailyWaterPerBirdMl,
    required this.totalWaterLiters,
    required this.feedType,
    required this.targetTempCelsius,
    required this.lightingHours,
    this.vaccineDue,
    this.vaccineRoute,
    this.medicineDue,
    required this.tasks,
    this.diagnosticAlerts = const [],
    this.isRealDataValidated = false,
    this.hasLoggedTodayRecord = false,
    this.actualFeedGivenKg,
    this.actualWaterGivenLiters,
    this.actualAvgWeightGrams,
    this.actualMortalityToday,
    this.cumulativeMortality,
    this.cumulativeMortalityPct,
    this.actualFcr,
    this.feedStockDaysRemaining,
    this.feedStockBagsAvailable,
  });

  int get completedCount => tasks.where((t) => t.isCompleted).length;
  int get totalCount => tasks.length;
  double get completionProgress =>
      totalCount > 0 ? completedCount / totalCount : 0.0;
}

class WeekFlockPlan {
  final int weekNumber;
  final String title;
  final String primaryMilestone;
  final double totalWeeklyFeedKg;
  final List<DailyFlockPlan> dailyPlans;

  const WeekFlockPlan({
    required this.weekNumber,
    required this.title,
    required this.primaryMilestone,
    required this.totalWeeklyFeedKg,
    required this.dailyPlans,
  });
}
