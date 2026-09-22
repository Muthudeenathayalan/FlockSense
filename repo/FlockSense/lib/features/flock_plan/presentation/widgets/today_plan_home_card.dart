import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/flock_plan/data/flock_plan_service.dart';
import 'package:flock_sense/features/flock_plan/domain/daily_plan_model.dart';
import 'package:flock_sense/features/flock_plan/presentation/screens/flock_plan_screen.dart';
import 'package:flock_sense/features/flock_plan/presentation/widgets/day_analytics_modal.dart';
import 'package:flock_sense/features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import 'package:flock_sense/features/performance/presentation/screens/batch_performance_screen.dart';
import 'package:flock_sense/features/reports/presentation/screens/reports_dashboard_screen.dart';
import 'package:flock_sense/features/vaccination/presentation/screens/vaccination_screen.dart';

class TodayPlanHomeCard extends StatefulWidget {
  const TodayPlanHomeCard({
    super.key,
    required this.batch,
    required this.farmId,
    required this.farmName,
  });

  final BatchModel batch;
  final String farmId;
  final String farmName;

  @override
  State<TodayPlanHomeCard> createState() => _TodayPlanHomeCardState();
}

class _TodayPlanHomeCardState extends State<TodayPlanHomeCard> {
  DailyFlockPlan? _plan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final age = FlockPlanService.getFlockAge(widget.batch);
    _plan = FlockPlanService.getStandardPlanForDay(batch: widget.batch, day: age);
    _loadPlan();
  }

  @override
  void didUpdateWidget(covariant TodayPlanHomeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.batch.id != widget.batch.id ||
        oldWidget.batch.currentBirds != widget.batch.currentBirds) {
      _loadPlan();
    }
  }

  Future<void> _loadPlan() async {
    try {
      final plan = await FlockPlanService.getTodayPlan(
        farmId: widget.farmId,
        batch: widget.batch,
      );
      if (mounted) {
        setState(() {
          _plan = plan;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTaskToggle(DailyPlanTask task) async {
    if (_plan == null) return;
    final newCompleted = !task.isCompleted;

    // Optimistic state update
    setState(() {
      final updatedTasks = _plan!.tasks.map((t) {
        if (t.id == task.id) {
          return t.copyWith(isCompleted: newCompleted);
        }
        return t;
      }).toList();

      _plan = DailyFlockPlan(
        day: _plan!.day,
        phase: _plan!.phase,
        liveBirds: _plan!.liveBirds,
        targetWeightGrams: _plan!.targetWeightGrams,
        dailyFeedPerBirdGrams: _plan!.dailyFeedPerBirdGrams,
        totalFeedKg: _plan!.totalFeedKg,
        dailyWaterPerBirdMl: _plan!.dailyWaterPerBirdMl,
        totalWaterLiters: _plan!.totalWaterLiters,
        feedType: _plan!.feedType,
        targetTempCelsius: _plan!.targetTempCelsius,
        lightingHours: _plan!.lightingHours,
        vaccineDue: _plan!.vaccineDue,
        vaccineRoute: _plan!.vaccineRoute,
        medicineDue: _plan!.medicineDue,
        tasks: updatedTasks,
        diagnosticAlerts: _plan!.diagnosticAlerts,
      );
    });

    await FlockPlanService.toggleTaskCompletion(
      batchId: widget.batch.id,
      day: _plan!.day,
      taskId: task.id,
      completed: newCompleted,
    );
  }

  void _handleActionNavigation(String? route) {
    if (route == null) return;
    switch (route) {
      case '/daily-record':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DailyRecordsDashboardScreen(),
          ),
        ).then((_) => _loadPlan());
        break;
      case '/vaccine':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VaccinationScreen()),
        ).then((_) => _loadPlan());
        break;
      case '/inventory':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const InventoryDashboardScreen(),
          ),
        ).then((_) => _loadPlan());
        break;
      case '/reports':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportsDashboardScreen(
              initialFarmId: widget.farmId,
              initialBatchId: widget.batch.id,
            ),
          ),
        );
        break;
      case '/performance':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BatchPerformanceScreen(
              farmId: widget.farmId,
              batchId: widget.batch.id,
              batchName: widget.batch.batchName,
              batch: widget.batch,
            ),
          ),
        );
        break;
    }
  }

  void _openFullPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlockPlanScreen(
          farmId: widget.farmId,
          batch: widget.batch,
        ),
      ),
    ).then((_) => _loadPlan());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _plan == null) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final plan = _plan ??
        FlockPlanService.getStandardPlanForDay(
          batch: widget.batch,
          day: FlockPlanService.getFlockAge(widget.batch),
        );
    final progress = plan.completionProgress;
    final displayTasks = plan.tasks.take(4).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3E22), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFFFFD54F),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TODAY'S FLOCK ACTION PLAN",
                        style: TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${widget.batch.batchName} • Day ${plan.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.phase,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Executive 2x2 Metrics Grid (Feed, Water, Climate, Weight)
                _buildMetricsGrid(plan),
                const SizedBox(height: 14),

                // Real-time Diagnostic Alerts Banner (if any)
                if (plan.diagnosticAlerts.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.notification_important_rounded,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'REAL-TIME FLOCK ALERTS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF991B1B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...plan.diagnosticAlerts.take(2).map((alert) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      alert,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF7F1D1D),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],

                // 3. Progress Bar
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${plan.completedCount} of ${plan.totalCount} Tasks Completed',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${(progress * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: progress == 1.0
                                      ? AppColors.primary
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: AppColors.borderLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress == 1.0
                                    ? AppColors.primary
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. Vaccine Due Banner (if applicable today)
                if (plan.vaccineDue != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.vaccines_rounded,
                          color: Color(0xFF0D9488),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vaccine Due Today: ${plan.vaccineDue}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: Color(0xFF115E59),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                plan.vaccineRoute ?? 'Administer in drinking water with milk powder',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _handleActionNavigation('/vaccine'),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Record',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 5. Tasks List
                ...displayTasks.map((task) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _handleTaskToggle(task),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? const Color(0xFFF0FDF4) // Soft green tint
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: task.isCompleted
                                ? const Color(0xFFBBF7D0)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.scale(
                              scale: 0.9,
                              child: Checkbox(
                                value: task.isCompleted,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (_) => _handleTaskToggle(task),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: task.isCompleted
                                          ? const Color(0xFF166534)
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (task.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      task.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: task.isCompleted
                                            ? const Color(0xFF15803D)
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (task.isRealRecordVerified && task.verificationNote != null) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified_rounded, size: 10.5, color: Color(0xFF16A34A)),
                                          const SizedBox(width: 4),
                                          Text(
                                            task.verificationNote!,
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF15803D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (task.actionLabel != null && !task.isCompleted) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () =>
                                    _handleActionNavigation(task.actionRoute),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: task.category.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: task.category.color.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    task.actionLabel!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: task.category.color,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 10),

                // 6. View Complete Plan Action Button (With generous padding for FAB clearance)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openFullPlan,
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: const Text(
                      'View 7-Day & 42-Day Master Lifecycle Plan',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Clean, spacious 2x2 executive metrics grid
  Widget _buildMetricsGrid(DailyFlockPlan plan) {
    final hasFeedLog = plan.actualFeedGivenKg != null && plan.actualFeedGivenKg! > 0;
    final hasWaterLog = plan.actualWaterGivenLiters != null && plan.actualWaterGivenLiters! > 0;
    final hasWeight = plan.actualAvgWeightGrams != null && plan.actualAvgWeightGrams! > 0;

    return Column(
      children: [
        // Top Row: Feed & Water
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.restaurant_rounded,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                borderColor: const Color(0xFFFDE68A),
                title: 'Daily Feed',
                value: hasFeedLog
                    ? '${plan.actualFeedGivenKg!.toStringAsFixed(1)} kg'
                    : '${plan.totalFeedKg.toStringAsFixed(1)} kg',
                subtitle: 'Target: ${plan.totalFeedKg.toStringAsFixed(1)} kg',
                badgeText: hasFeedLog ? 'Logged' : plan.feedType.split(' ').first,
                badgeColor: hasFeedLog ? const Color(0xFF15803D) : const Color(0xFFB45309),
                onTap: () => DayAnalyticsModal.show(
                  context,
                  plan: plan,
                  batch: widget.batch,
                  farmId: widget.farmId,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF0284C7),
                bgColor: const Color(0xFFF0F9FF),
                borderColor: const Color(0xFFBAE6FD),
                title: 'Daily Water',
                value: hasWaterLog
                    ? '${plan.actualWaterGivenLiters!.toStringAsFixed(0)} L'
                    : '${plan.totalWaterLiters.toStringAsFixed(0)} L',
                subtitle: 'Target: ${plan.totalWaterLiters.toStringAsFixed(0)} L',
                badgeText: hasWaterLog ? 'Logged' : 'Sanitized',
                badgeColor: hasWaterLog ? const Color(0xFF15803D) : const Color(0xFF0369A1),
                onTap: () => DayAnalyticsModal.show(
                  context,
                  plan: plan,
                  batch: widget.batch,
                  farmId: widget.farmId,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Bottom Row: Shed Temp & Body Weight
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.thermostat_rounded,
                iconColor: const Color(0xFFE11D48),
                bgColor: const Color(0xFFFFF1F2),
                borderColor: const Color(0xFFFECDD3),
                title: 'Shed Temp',
                value: '${plan.targetTempCelsius.toStringAsFixed(1)}°C',
                subtitle: '${plan.lightingHours}h Light Photoperiod',
                badgeText: 'Optimal',
                badgeColor: const Color(0xFFBE123C),
                onTap: () => DayAnalyticsModal.show(
                  context,
                  plan: plan,
                  batch: widget.batch,
                  farmId: widget.farmId,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.monitor_weight_outlined,
                iconColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFBBF7D0),
                title: 'Flock Weight',
                value: hasWeight
                    ? '${plan.actualAvgWeightGrams!.toStringAsFixed(0)}g'
                    : '${plan.targetWeightGrams.toStringAsFixed(0)}g',
                subtitle: 'Target: ${plan.targetWeightGrams.toStringAsFixed(0)}g',
                badgeText: hasWeight ? 'Sampled' : 'Standard',
                badgeColor: hasWeight ? const Color(0xFF15803D) : const Color(0xFF16A34A),
                onTap: () => DayAnalyticsModal.show(
                  context,
                  plan: plan,
                  batch: widget.batch,
                  farmId: widget.farmId,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String value,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, size: 14, color: iconColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
