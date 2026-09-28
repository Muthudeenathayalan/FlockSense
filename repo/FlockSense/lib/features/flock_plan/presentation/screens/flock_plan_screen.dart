import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/flock_plan/data/flock_plan_service.dart';
import 'package:flock_sense/features/flock_plan/domain/daily_plan_model.dart';
import 'package:flock_sense/features/flock_plan/domain/flock_lifecycle_standard.dart';
import 'package:flock_sense/features/flock_plan/presentation/widgets/day_analytics_modal.dart';
import 'package:flock_sense/features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import 'package:flock_sense/features/performance/presentation/screens/batch_performance_screen.dart';
import 'package:flock_sense/features/reports/presentation/screens/reports_dashboard_screen.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_records_screen.dart';

class FlockPlanScreen extends StatefulWidget {
  const FlockPlanScreen({
    super.key,
    required this.farmId,
    required this.batch,
  });

  final String farmId;
  final BatchModel batch;

  @override
  State<FlockPlanScreen> createState() => _FlockPlanScreenState();
}

class _FlockPlanScreenState extends State<FlockPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DailyFlockPlan? _todayPlan;
  WeekFlockPlan? _weekPlan;
  List<DailyFlockPlan>? _masterChart;
  bool _isLoading = true;
  String? _errorMessage;

  int _selectedWeek = 1;
  int _masterChartFilterWeek = 0; // 0 = All

  WeekFlockPlan _getSafeStandardWeekPlan(int weekNum) {
    final chart = _masterChart ?? FlockPlanService.getFullCycleChartSync(widget.batch);
    final weekStart = ((weekNum - 1) * 7).clamp(0, chart.length);
    final weekEnd = (weekStart + 7).clamp(0, chart.length);
    final weekDays = chart.sublist(weekStart, weekEnd);
    final totalFeed = weekDays.fold<double>(0.0, (sum, d) => sum + d.totalFeedKg);
    return WeekFlockPlan(
      weekNumber: weekNum,
      title: 'Week $weekNum Protocols',
      primaryMilestone: 'Standard growth protocols & guidelines',
      dailyPlans: weekDays,
      totalWeeklyFeedKg: totalFeed,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final age = FlockPlanService.getFlockAge(widget.batch);
    _selectedWeek = ((age - 1) ~/ 7) + 1;
    
    // Immediately initialize standard fallback data so all 3 tabs render instantly without blank screens
    _todayPlan = FlockPlanService.getStandardPlanForDay(batch: widget.batch, day: age);
    _masterChart = FlockPlanService.getFullCycleChartSync(widget.batch);
    _weekPlan = _getSafeStandardWeekPlan(_selectedWeek);

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final today = await FlockPlanService.getTodayPlan(
        farmId: widget.farmId,
        batch: widget.batch,
      );
      final week = await FlockPlanService.getWeekPlan(
        farmId: widget.farmId,
        batch: widget.batch,
        weekNumber: _selectedWeek,
      );
      List<DailyRecordModel>? records;
      try {
        records = await DailyRecordService.getAllDailyRecords(
          farmId: widget.farmId,
          batchId: widget.batch.id,
        );
      } catch (_) {}
      final master = FlockPlanService.getFullCycleChartSync(widget.batch, records);

      if (mounted) {
        setState(() {
          _todayPlan = today;
          _weekPlan = week;
          _masterChart = master;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[FlockPlanScreen] Error loading plan: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Offline mode: displaying standard benchmarks';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleWeekChange(int newWeek) async {
    setState(() {
      _selectedWeek = newWeek;
      _weekPlan = _getSafeStandardWeekPlan(newWeek);
      _isLoading = true;
    });
    try {
      final week = await FlockPlanService.getWeekPlan(
        farmId: widget.farmId,
        batch: widget.batch,
        weekNumber: newWeek,
      );
      if (mounted) {
        setState(() {
          _weekPlan = week;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTaskToggle(DailyPlanTask task) async {
    if (_todayPlan == null) return;
    final newCompleted = !task.isCompleted;

    setState(() {
      final updatedTasks = _todayPlan!.tasks.map((t) {
        if (t.id == task.id) return t.copyWith(isCompleted: newCompleted);
        return t;
      }).toList();

      _todayPlan = DailyFlockPlan(
        day: _todayPlan!.day,
        phase: _todayPlan!.phase,
        liveBirds: _todayPlan!.liveBirds,
        targetWeightGrams: _todayPlan!.targetWeightGrams,
        dailyFeedPerBirdGrams: _todayPlan!.dailyFeedPerBirdGrams,
        totalFeedKg: _todayPlan!.totalFeedKg,
        dailyWaterPerBirdMl: _todayPlan!.dailyWaterPerBirdMl,
        totalWaterLiters: _todayPlan!.totalWaterLiters,
        feedType: _todayPlan!.feedType,
        targetTempCelsius: _todayPlan!.targetTempCelsius,
        lightingHours: _todayPlan!.lightingHours,
        vaccineDue: _todayPlan!.vaccineDue,
        vaccineRoute: _todayPlan!.vaccineRoute,
        medicineDue: _todayPlan!.medicineDue,
        tasks: updatedTasks,
        diagnosticAlerts: _todayPlan!.diagnosticAlerts,
        isRealDataValidated: _todayPlan!.isRealDataValidated,
        hasLoggedTodayRecord: _todayPlan!.hasLoggedTodayRecord,
        actualFeedGivenKg: _todayPlan!.actualFeedGivenKg,
        actualWaterGivenLiters: _todayPlan!.actualWaterGivenLiters,
        actualAvgWeightGrams: _todayPlan!.actualAvgWeightGrams,
        actualMortalityToday: _todayPlan!.actualMortalityToday,
        cumulativeMortality: _todayPlan!.cumulativeMortality,
        cumulativeMortalityPct: _todayPlan!.cumulativeMortalityPct,
        actualFcr: _todayPlan!.actualFcr,
        feedStockDaysRemaining: _todayPlan!.feedStockDaysRemaining,
        feedStockBagsAvailable: _todayPlan!.feedStockBagsAvailable,
      );
    });

    await FlockPlanService.toggleTaskCompletion(
      batchId: widget.batch.id,
      day: _todayPlan!.day,
      taskId: task.id,
      completed: newCompleted,
    );
  }

  void _handleAction(String? route) {
    if (route == null) return;
    switch (route) {
      case '/daily-record':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DailyRecordsDashboardScreen(),
          ),
        ).then((_) => _loadData());
        break;
      case '/vaccine':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VaccineRecordsScreen(
              farmId: widget.farmId,
              batchId: widget.batch.id,
              batchName: widget.batch.batchName,
            ),
          ),
        ).then((_) => _loadData());
        break;
      case '/inventory':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const InventoryDashboardScreen(),
          ),
        ).then((_) => _loadData());
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

  @override
  Widget build(BuildContext context) {
    final flockAge = FlockPlanService.getFlockAge(widget.batch);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Flock Action Plan & Lifecycle Chart',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${widget.batch.batchName} • Day $flockAge',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD54F),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: "Today (Day $flockAge)"),
            const Tab(text: "This Week"),
            Tab(text: "${widget.batch.cycleTargetDays}-Day Chart"),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Plan',
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _isLoading && _todayPlan == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildWeekTab(),
                _buildMasterChartTab(),
              ],
            ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 1: TODAY'S PLAN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTodayTab() {
    try {
      final flockAge = FlockPlanService.getFlockAge(widget.batch);
      final plan = _todayPlan ??
          FlockPlanService.getStandardPlanForDay(batch: widget.batch, day: flockAge);
      final progress = plan.completionProgress.clamp(0.0, 1.0);

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            if (_errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 16, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Standard benchmark mode • Pull to sync live telemetry',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _loadData,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Hero Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3E22), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'FLOCK DAY ${plan.day}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        plan.phase,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Daily Standard for ${plan.liveBirds} Live Birds',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target Feed: ${plan.totalFeedKg.toStringAsFixed(1)} kg • Water: ${plan.totalWaterLiters.toStringAsFixed(0)} L',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${plan.completedCount} of ${plan.totalCount} Tasks Completed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? Colors.lightGreenAccent : const Color(0xFFFFD54F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4 Target Quantities Cards
          Row(
            children: [
              _buildTargetCard(
                icon: Icons.restaurant_rounded,
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                title: 'Daily Feed',
                value: plan.actualFeedGivenKg != null && plan.actualFeedGivenKg! > 0
                    ? '${plan.actualFeedGivenKg!.toStringAsFixed(1)} / ${plan.totalFeedKg.toStringAsFixed(1)} kg'
                    : '${plan.totalFeedKg.toStringAsFixed(1)} kg',
                subtitle: plan.actualFeedGivenKg != null && plan.actualFeedGivenKg! > 0 && plan.totalFeedKg > 0
                    ? 'Logged vs Target (${((plan.actualFeedGivenKg! / plan.totalFeedKg) * 100).clamp(0, 999).toStringAsFixed(0)}%)'
                    : '${plan.dailyFeedPerBirdGrams.toStringAsFixed(0)}g/bird • ${plan.feedType}',
              ),
              const SizedBox(width: 10),
              _buildTargetCard(
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFE0F2FE),
                title: 'Daily Water',
                value: plan.actualWaterGivenLiters != null && plan.actualWaterGivenLiters! > 0
                    ? '${plan.actualWaterGivenLiters!.toStringAsFixed(0)} / ${plan.totalWaterLiters.toStringAsFixed(0)} L'
                    : '${plan.totalWaterLiters.toStringAsFixed(0)} L',
                subtitle: plan.actualWaterGivenLiters != null && plan.actualWaterGivenLiters! > 0
                    ? 'Logged vs Target'
                    : '${plan.dailyWaterPerBirdMl.toStringAsFixed(0)} ml/bird • Clean',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTargetCard(
                icon: Icons.thermostat_rounded,
                color: const Color(0xFFE11D48),
                bgColor: const Color(0xFFFFE4E6),
                title: 'Target Temp',
                value: '${plan.targetTempCelsius.toStringAsFixed(1)}°C',
                subtitle: '${plan.lightingHours}h light / ${24 - plan.lightingHours}h dark',
              ),
              const SizedBox(width: 10),
              _buildTargetCard(
                icon: Icons.monitor_weight_outlined,
                color: const Color(0xFF16A34A),
                bgColor: const Color(0xFFDCFCE7),
                title: 'Target Body Wt',
                value: plan.actualAvgWeightGrams != null
                    ? '${plan.actualAvgWeightGrams!.toStringAsFixed(0)}g'
                    : '${plan.targetWeightGrams.toStringAsFixed(0)}g',
                subtitle: plan.actualAvgWeightGrams != null
                    ? 'Sampled (Std: ${plan.targetWeightGrams.toStringAsFixed(0)}g)'
                    : 'Cobb/Ross 500 standard',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Real-time Batch Telemetry & Live Validation Summary Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
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
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.insights_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'REAL-TIME BATCH METRICS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: plan.isRealDataValidated
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        plan.isRealDataValidated
                            ? '● Live Telemetry Synced'
                            : 'Standard Benchmark',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: plan.isRealDataValidated
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Live Birds',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${plan.liveBirds}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Batch FCR',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            plan.actualFcr != null && plan.actualFcr!.isFinite && !plan.actualFcr!.isNaN
                                ? plan.actualFcr!.toStringAsFixed(2)
                                : '${FlockLifecycleStandard.getForDay(plan.day).standardFcr.toStringAsFixed(2)} (Std)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: (plan.actualFcr != null && plan.actualFcr! > 1.65)
                                  ? const Color(0xFFDC2626)
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cumulative Mort.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${((plan.cumulativeMortalityPct ?? 0).isFinite ? (plan.cumulativeMortalityPct ?? 0) : 0).toStringAsFixed(1)}% (${plan.cumulativeMortality ?? 0})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Feed Stock',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            plan.feedStockDaysRemaining != null && plan.feedStockDaysRemaining!.isFinite
                                ? '~${plan.feedStockDaysRemaining!.toStringAsFixed(1)} days left'
                                : 'Check inventory',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: (plan.feedStockDaysRemaining != null &&
                                      plan.feedStockDaysRemaining! <= 3.5)
                                  ? const Color(0xFFDC2626)
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Today's Log Status",
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            plan.hasLoggedTodayRecord ? '✓ Logged' : 'Pending entry',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: plan.hasLoggedTodayRecord
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Diagnostic Alerts (if any)
          if (plan.diagnosticAlerts.isNotEmpty) ...[
            ...plan.diagnosticAlerts.map(
              (alert) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFE11D48),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        alert,
                        style: const TextStyle(
                          color: Color(0xFF9F1239),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Vaccine Banner
          if (plan.vaccineDue != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vaccines, color: Color(0xFF0D9488), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vaccine Due Today: ${plan.vaccineDue}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: Color(0xFF115E59),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan.vaccineRoute ?? 'Administer in drinking water with skim milk stabilizer.',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleAction('/vaccine'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Record'),
                  ),
                ],
              ),
            ),
          ],

          // Section Title: Daily Checklist
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Action Checklist",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Tap task when done',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tasks List
          ...plan.tasks.map((task) => _buildTaskItem(task)),
          const SizedBox(height: 16),

          // Action Button: View Pie Chart & Growth Analytics Modal
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => DayAnalyticsModal.show(
                context,
                plan: plan,
                batch: widget.batch,
                farmId: widget.farmId,
              ),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text("View Day ${plan.day} Targets & FCR Requirements"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Action Button: Log Telemetry
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleAction('/daily-record'),
              icon: const Icon(Icons.assignment_outlined),
              label: Text("Log Day ${plan.day} Daily Record (${plan.totalFeedKg.toStringAsFixed(0)} kg Target)"),
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
          const SizedBox(height: 24),
        ],
      ),
      ),
    );
    } catch (e, stack) {
      debugPrint('[FlockPlanScreen] Error in _buildTodayTab: $e\n$stack');
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Today\'s Plan Available',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap refresh to reload latest batch telemetry and lifecycle milestones.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reload Action Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTaskItem(DailyPlanTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: task.isCompleted ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: task.isCompleted ? const Color(0xFFBBF7D0) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: task.isCompleted,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (_) => _handleTaskToggle(task),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: task.isCompleted ? FontWeight.w600 : FontWeight.w700,
                          color: task.isCompleted ? const Color(0xFF166534) : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (task.isCompleted) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: task.category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.category.label.split(' ').first,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: task.category.color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: task.isCompleted ? AppColors.textMuted : AppColors.textSecondary,
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
                        const Icon(Icons.verified_rounded, size: 11, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(
                          task.verificationNote!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (task.actionLabel != null && !task.isCompleted) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => _handleAction(task.actionRoute),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: Text(task.actionLabel!),
                    style: TextButton.styleFrom(
                      foregroundColor: task.category.color,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 2: THIS WEEK'S PLAN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildWeekTab() {
    try {
      final week = _weekPlan ?? _getSafeStandardWeekPlan(_selectedWeek);

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Week Selector Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(6, (i) {
                  final w = i + 1;
                  final isSel = _selectedWeek == w;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('Week $w (D${(w - 1) * 7 + 1}-${w * 7})'),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => _handleWeekChange(w),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Week Overview Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    week.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Milestone: ${week.primaryMilestone}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Week Feed Required:',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${week.totalWeeklyFeedKg.toStringAsFixed(0)} kg (~${week.totalWeeklyFeedKg > 0 ? (week.totalWeeklyFeedKg / 50).ceil() : 0} Bags)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // 7-Day Breakdown Cards
          ...week.dailyPlans.map((daily) {
            final isFlockToday = daily.day == FlockPlanService.getFlockAge(widget.batch);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isFlockToday ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFlockToday ? AppColors.primary : AppColors.border,
                  width: isFlockToday ? 1.5 : 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => DayAnalyticsModal.show(
                    context,
                    plan: daily,
                    batch: widget.batch,
                    farmId: widget.farmId,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isFlockToday ? AppColors.primary : AppColors.surfaceSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Day ${daily.day}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isFlockToday ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isFlockToday)
                                  const Text(
                                    'TODAY',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              'Target: ${daily.targetWeightGrams.toStringAsFixed(0)}g',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '🌾 ${daily.totalFeedKg.toStringAsFixed(1)} kg (${daily.dailyFeedPerBirdGrams.toStringAsFixed(0)}g/bird)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '💧 ${daily.totalWaterLiters.toStringAsFixed(0)} L (${daily.dailyWaterPerBirdMl.toStringAsFixed(0)} ml/bird)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '🌡️ ${daily.targetTempCelsius}°C',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '💡 ${daily.lightingHours}h light',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        if (daily.vaccineDue != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF99F6E4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.vaccines, size: 14, color: Color(0xFF0D9488)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Vaccine: ${daily.vaccineDue}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              daily.phase,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.tune_rounded, size: 13, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'View Day ${daily.day} Targets & FCR',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.primary),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      ),
    );
    } catch (e, stack) {
      debugPrint('[FlockPlanScreen] Error in _buildWeekTab: $e\n$stack');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 48),
              const SizedBox(height: 12),
              Text(
                'Week $_selectedWeek Plan',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reload Week'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 3: 42-DAY MASTER LIFECYCLE CHART
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMasterChartTab() {
    try {
      final chart = _masterChart ?? FlockPlanService.getFullCycleChartSync(widget.batch);

      final filtered = _masterChartFilterWeek == 0
          ? chart
          : chart.where((p) {
              final w = ((p.day - 1) ~/ 7) + 1;
              return w == _masterChartFilterWeek;
            }).toList();

      return Column(
        children: [
        // Week Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('All ${chart.length} Days'),
                    selected: _masterChartFilterWeek == 0,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _masterChartFilterWeek == 0 ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    onSelected: (_) => setState(() => _masterChartFilterWeek = 0),
                  ),
                ),
                ...List.generate((chart.length / 7).ceil(), (i) {
                  final w = i + 1;
                  final isSel = _masterChartFilterWeek == w;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('Week $w'),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      onSelected: (_) => setState(() => _masterChartFilterWeek = w),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Interactive Hint Banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap any day row below to view required FCR, Feed, Water & Temperature targets',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Scrollable Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                columnSpacing: 16,
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('Day', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Phase', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Target Wt', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Feed/Bird', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Flock Feed', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Flock Water', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Temp', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Special Protocol', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Targets', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filtered.map((p) {
                  final isToday = p.day == FlockPlanService.getFlockAge(widget.batch);
                  return DataRow(
                    color: isToday ? WidgetStateProperty.all(const Color(0xFFDCFCE7)) : null,
                    onSelectChanged: (_) => DayAnalyticsModal.show(
                      context,
                      plan: p,
                      batch: widget.batch,
                      farmId: widget.farmId,
                    ),
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Day ${p.day}',
                              style: TextStyle(
                                fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
                                color: isToday ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'Today',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      DataCell(Text(p.phase.split(' ').first)),
                      DataCell(Text('${p.targetWeightGrams.toStringAsFixed(0)}g')),
                      DataCell(Text('${p.dailyFeedPerBirdGrams.toStringAsFixed(0)}g')),
                      DataCell(Text('${p.totalFeedKg.toStringAsFixed(1)} kg')),
                      DataCell(Text('${p.totalWaterLiters.toStringAsFixed(0)} L')),
                      DataCell(Text('${p.targetTempCelsius}°C')),
                      DataCell(
                        p.vaccineDue != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.vaccineDue!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0369A1),
                                  ),
                                ),
                              )
                            : Text(
                                p.feedType.split(' ').first,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune_rounded, size: 13, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'View',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
    } catch (e, stack) {
      debugPrint('[FlockPlanScreen] Error in _buildMasterChartTab: $e\n$stack');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.table_chart_rounded, color: AppColors.primary, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Lifecycle Chart',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reload Chart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

