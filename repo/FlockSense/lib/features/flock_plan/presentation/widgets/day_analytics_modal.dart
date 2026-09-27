import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/flock_plan/data/flock_plan_service.dart';
import 'package:flock_sense/features/flock_plan/domain/daily_plan_model.dart';
import 'package:flock_sense/features/flock_plan/domain/flock_lifecycle_standard.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_records_screen.dart';

class DayAnalyticsModal extends StatelessWidget {
  const DayAnalyticsModal({
    super.key,
    required this.plan,
    required this.batch,
    required this.farmId,
  });

  final DailyFlockPlan plan;
  final BatchModel batch;
  final String farmId;

  static Future<void> show(
    BuildContext context, {
    required DailyFlockPlan plan,
    required BatchModel batch,
    required String farmId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DayAnalyticsModal(
        plan: plan,
        batch: batch,
        farmId: farmId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final std = FlockLifecycleStandard.getForDay(plan.day);
    final flockAge = FlockPlanService.getFlockAge(batch);
    final isFlockToday = plan.day == flockAge;

    final standardFcr = std.standardFcr;
    final actualFcr = plan.actualFcr;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Day ${plan.day} Requirements',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isFlockToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${batch.batchName} • ${plan.phase}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header: Core Requirements
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DAILY TARGETS & SPECIFICATIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${batch.totalBirds} Birds Base',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1. FCR TARGET CARD
                  _buildRequirementCard(
                    icon: Icons.speed_rounded,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                    title: 'Feed Conversion Ratio (FCR)',
                    mainValue: actualFcr != null && actualFcr.isFinite && !actualFcr.isNaN
                        ? actualFcr.toStringAsFixed(2)
                        : standardFcr.toStringAsFixed(2),
                    badgeText: actualFcr != null
                        ? (actualFcr <= standardFcr + 0.05 ? 'Optimal FCR' : 'Actual FCR')
                        : 'Standard Benchmark',
                    badgeColor: actualFcr != null && actualFcr <= standardFcr + 0.05
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    badgeTextColor: actualFcr != null && actualFcr <= standardFcr + 0.05
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB45309),
                    primaryNote: 'Day ${plan.day} standard target: ${standardFcr.toStringAsFixed(2)} FCR',
                    secondaryNote: 'Expected efficiency for Cobb 500 / Ross 308 standard commercial broilers.',
                    extraWidget: _buildFcrProgressionBar(
                      selectedDay: plan.day,
                      standardFcr: standardFcr,
                      actualFcr: actualFcr,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. DAILY FEED CARD
                  _buildRequirementCard(
                    icon: Icons.restaurant_rounded,
                    iconColor: const Color(0xFFD97706),
                    iconBgColor: const Color(0xFFFEF3C7),
                    title: 'Feed To Give Today',
                    mainValue: '${plan.totalFeedKg.toStringAsFixed(1)} kg',
                    badgeText: '${plan.dailyFeedPerBirdGrams.toStringAsFixed(0)}g / bird',
                    badgeColor: const Color(0xFFFEF3C7),
                    badgeTextColor: const Color(0xFF92400E),
                    primaryNote: 'Feed Type: ${plan.feedType}',
                    secondaryNote: plan.actualFeedGivenKg != null && plan.actualFeedGivenKg! > 0
                        ? 'Logged Today: ${plan.actualFeedGivenKg!.toStringAsFixed(1)} kg (${((plan.actualFeedGivenKg! / plan.totalFeedKg) * 100).clamp(0, 999).toStringAsFixed(0)}% of target given)'
                        : 'Distribute evenly across feeders 2 to 3 times daily.',
                  ),
                  const SizedBox(height: 14),

                  // 3. DAILY WATER CARD
                  _buildRequirementCard(
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFF0284C7),
                    iconBgColor: const Color(0xFFE0F2FE),
                    title: 'Water To Give Today',
                    mainValue: '${plan.totalWaterLiters.toStringAsFixed(0)} Liters',
                    badgeText: '${plan.dailyWaterPerBirdMl.toStringAsFixed(0)} ml / bird',
                    badgeColor: const Color(0xFFE0F2FE),
                    badgeTextColor: const Color(0xFF075985),
                    primaryNote: 'Clean sanitized fresh drinking water (1:2 feed-to-water ratio)',
                    secondaryNote: plan.actualWaterGivenLiters != null && plan.actualWaterGivenLiters! > 0
                        ? 'Logged Today: ${plan.actualWaterGivenLiters!.toStringAsFixed(0)} L'
                        : 'Flush nipple lines or wash bell drinkers every morning.',
                  ),
                  const SizedBox(height: 14),

                  // 4. REQUIRED TEMPERATURE & LIGHTING CARD
                  _buildRequirementCard(
                    icon: Icons.thermostat_rounded,
                    iconColor: const Color(0xFFE11D48),
                    iconBgColor: const Color(0xFFFFE4E6),
                    title: 'Target Shed Temperature',
                    mainValue: '${plan.targetTempCelsius.toStringAsFixed(1)}°C',
                    badgeText: '${plan.lightingHours}h Light / ${24 - plan.lightingHours}h Dark',
                    badgeColor: const Color(0xFFFFE4E6),
                    badgeTextColor: const Color(0xFF9F1239),
                    primaryNote: _getTemperatureGuidance(plan.day, plan.targetTempCelsius),
                    secondaryNote: 'Ensure brooding heat sources or cross-ventilation maintain uniform air quality.',
                  ),
                  const SizedBox(height: 14),

                  // 5. TARGET BODY WEIGHT HIGHLIGHT
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.monitor_weight_outlined,
                            color: Color(0xFF16A34A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Target Body Weight',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                plan.actualAvgWeightGrams != null
                                    ? '${plan.actualAvgWeightGrams!.toStringAsFixed(0)}g (Target: ${plan.targetWeightGrams.toStringAsFixed(0)}g)'
                                    : '${plan.targetWeightGrams.toStringAsFixed(0)}g',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (plan.actualAvgWeightGrams != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: plan.actualAvgWeightGrams! >= plan.targetWeightGrams
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              plan.actualAvgWeightGrams! >= plan.targetWeightGrams
                                  ? '+${(plan.actualAvgWeightGrams! - plan.targetWeightGrams).toStringAsFixed(0)}g'
                                  : '${(plan.actualAvgWeightGrams! - plan.targetWeightGrams).toStringAsFixed(0)}g',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: plan.actualAvgWeightGrams! >= plan.targetWeightGrams
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 6. VACCINE DUE ALERT (IF ANY)
                  if (plan.vaccineDue != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.vaccines_rounded, color: Color(0xFF0D9488), size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vaccine Due Today: ${plan.vaccineDue}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF115E59),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  plan.vaccineRoute ?? 'Administer in drinking water with stabilizer.',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VaccineRecordsScreen(
                                    farmId: farmId,
                                    batchId: batch.id,
                                    batchName: batch.batchName,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Record', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 7. ACTION BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DailyRecordsDashboardScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment_outlined, size: 18),
                      label: Text(
                        isFlockToday
                            ? 'Log Day ${plan.day} Daily Record'
                            : 'Open Daily Records',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String mainValue,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String primaryNote,
    required String secondaryNote,
    Widget? extraWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mainValue,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            primaryNote,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            secondaryNote,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          if (extraWidget != null) ...[
            const SizedBox(height: 10),
            extraWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildFcrProgressionBar({
    required int selectedDay,
    required double standardFcr,
    required double? actualFcr,
  }) {
    // Benchmark ranges: Brooding (1.05) to Harvest (1.70)
    final progress = ((standardFcr - 1.0) / (1.75 - 1.0)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lifecycle FCR Range',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              Text(
                'Day $selectedDay: ${standardFcr.toStringAsFixed(2)} target',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                standardFcr <= 1.25
                    ? const Color(0xFF16A34A)
                    : (standardFcr <= 1.55 ? const Color(0xFFD97706) : const Color(0xFF0284C7)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Brooding (1.05)', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
              Text('Grower (1.30)', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
              Text('Finisher (1.55)', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
              Text('Harvest (1.70)', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  String _getTemperatureGuidance(int day, double temp) {
    if (day <= 3) {
      return 'Critical Brooding Temp: Keep chicks warm & prevent drafts.';
    } else if (day <= 7) {
      return 'Early Brooding: Gradually reduce temp ~0.5°C per day.';
    } else if (day <= 14) {
      return 'Active Feathering: Maintain ventilation while keeping birds comfortable.';
    } else if (day <= 21) {
      return 'Grower Phase: Transition to ambient house temp with good air flow.';
    } else {
      return 'Finisher Phase: Cool ventilation essential to avoid heat stress.';
    }
  }
}
