import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/performance/domain/performance_calculator.dart';

class BatchPerformanceScreen extends StatelessWidget {
  const BatchPerformanceScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    required this.batchName,
    required this.batch,
  });

  final String farmId;
  final String batchId;
  final String batchName;
  final BatchModel batch;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('$batchName — Performance'),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Growth'),
              Tab(text: 'Mortality'),
              Tab(text: 'FCR'),
            ],
          ),
        ),
        body: StreamBuilder<List<DailyRecordModel>>(
          stream: DailyRecordService.watchDailyRecords(
            farmId: farmId,
            batchId: batchId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load performance data',
                  style: const TextStyle(color: AppColors.danger),
                ),
              );
            }

            final records = [...(snapshot.data ?? <DailyRecordModel>[])];
            records.sort((a, b) => a.batchAgeDay.compareTo(b.batchAgeDay));
            if (records.isEmpty) {
              return _emptyState();
            }

            return TabBarView(
              children: [
                _buildOverviewTab(records),
                _buildGrowthTab(records),
                _buildMortalityTab(records),
                _buildFcrTab(records),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.show_chart_outlined, size: 70, color: AppColors.primary),
            SizedBox(height: 14),
            Text(
              'No performance data yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add daily records to start tracking growth, mortality, and feed efficiency.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(List<DailyRecordModel> records) {
    final summary = PerformanceCalculator.calculateSummary(records, batch);
    final weeklyMortality = PerformanceCalculator.calculateWeeklyMortality(
      records,
      batch.totalBirds,
    );
    final cumulativeMortality = summary.currentMortalityPct;
    final pef = summary.pef;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _kpiCard(
                label: 'Day',
                value: summary.currentDay.toString(),
                icon: Icons.today,
                gradient: AppColors.primaryGradient,
              ),
              _kpiCard(
                label: 'Body Weight',
                value: '${summary.currentAvgWeightGrams.toStringAsFixed(0)}g',
                icon: Icons.monitor_weight_outlined,
                gradient: AppColors.goldGradient,
              ),
              _kpiCard(
                label: 'Mortality',
                value: '${summary.currentMortalityPct.toStringAsFixed(2)}%',
                icon: Icons.warning_amber_outlined,
                gradient: cumulativeMortality > 3
                    ? AppColors.dangerGradient
                    : AppColors.emeraldGradient,
              ),
              _kpiCard(
                label: 'FCR',
                value: summary.currentFcr?.toStringAsFixed(2) ?? '–',
                icon: Icons.show_chart,
                gradient: (summary.currentFcr ?? 0) > 1.7
                    ? AppColors.dangerGradient
                    : AppColors.primaryGradient,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (pef != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: AppColors.emeraldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Production Efficiency Factor',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          pef.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.emerald,
                          ),
                        ),
                        Text(
                          pef > 350
                              ? 'Excellent'
                              : pef > 300
                              ? 'Good'
                              : 'Needs attention',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Weekly Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  color: AppColors.surfaceSoft,
                  child: Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Week',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Deaths',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Mort%',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Cum Mort%',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                ...weeklyMortality.map((entry) {
                  final cumulative = weeklyMortality
                      .takeWhile((item) => item.week <= entry.week)
                      .fold<double>(0, (sum, item) => sum + item.pct);
                  final isAlert = entry.pct > 1.0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    color: entry.week.isEven
                        ? AppColors.surface
                        : AppColors.surfaceSoft,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'W${entry.week}',
                            style: TextStyle(
                              color: isAlert
                                  ? AppColors.danger
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${entry.deaths}',
                            style: TextStyle(
                              color: isAlert
                                  ? AppColors.danger
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${entry.pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: isAlert
                                  ? AppColors.danger
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${cumulative.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: isAlert
                                  ? AppColors.danger
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthTab(List<DailyRecordModel> records) {
    final actualSpots =
        records
            .where((r) => r.avgWeightGrams > 0)
            .map((r) => FlSpot(r.batchAgeDay.toDouble(), r.avgWeightGrams))
            .toList()
          ..sort((a, b) => a.x.compareTo(b.x));
    final maxY = math.max(
      3200.0,
      (actualSpots.isEmpty
              ? 0.0
              : actualSpots.map((e) => e.y).reduce(math.max)) +
          200,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Body Weight',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Actual vs SKM Standard (g/bird)',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              _LegendDot(color: Color(0xFF1565C0)),
              SizedBox(width: 6),
              Text(
                'Actual weight',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              SizedBox(width: 18),
              _LegendDot(color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text(
                'SKM Standard',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  minX: 0,
                  maxX: 42,
                  backgroundColor: AppColors.background,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppColors.border, strokeWidth: 0.8),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: AppColors.border),
                      left: BorderSide(color: AppColors.border),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: 500,
                        getTitlesWidget: (value, _) => Text(
                          value >= 1000
                              ? '${(value / 1000).toStringAsFixed(1)}kg'
                              : '${value.toInt()}g',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 7,
                        getTitlesWidget: (value, _) => Text(
                          'D${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: actualSpots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: const Color(0xFF1565C0),
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(
                          radius: 3,
                          color: const Color(0xFF1565C0),
                          strokeColor: Colors.white,
                          strokeWidth: 1.5,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                      ),
                    ),
                    LineChartBarData(
                      spots: PerformanceCalculator.skmBodyWeightStd.entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      barWidth: 1.5,
                      dashArray: const [6, 4],
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                        final label = s.barIndex == 0
                            ? 'Day ${s.x.toInt()}\n${s.y >= 1000 ? '${(s.y / 1000).toStringAsFixed(2)}kg' : '${s.y.toStringAsFixed(0)}g'} actual'
                            : '${s.y >= 1000 ? '${(s.y / 1000).toStringAsFixed(2)}kg' : '${s.y.toStringAsFixed(0)}g'} standard';
                        return LineTooltipItem(
                          label,
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data points: ${actualSpots.length} of ${batch.totalBirds > 0 ? 42 : 0} days',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMortalityTab(List<DailyRecordModel> records) {
    final sorted = [...records]
      ..sort((a, b) => a.batchAgeDay.compareTo(b.batchAgeDay));
    final cumulativeSpots = sorted
        .map(
          (r) => FlSpot(
            r.batchAgeDay.toDouble(),
            PerformanceCalculator.calculateCumulativeMortalityPct(
              sorted,
              batch.totalBirds,
              r.batchAgeDay,
            ),
          ),
        )
        .toList();
    final weekly = PerformanceCalculator.calculateWeeklyMortality(
      records,
      batch.totalBirds,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cumulative Mortality Trend',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Acceptable limit: 3%',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 6,
                  minX: 0,
                  maxX: 42,
                  backgroundColor: AppColors.background,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppColors.border, strokeWidth: 0.8),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: AppColors.border),
                      left: BorderSide(color: AppColors.border),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 1,
                        getTitlesWidget: (value, _) => Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 7,
                        getTitlesWidget: (value, _) => Text(
                          'D${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: cumulativeSpots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: AppColors.danger,
                      barWidth: 2.5,
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.danger.withValues(alpha: 0.1),
                      ),
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: const [FlSpot(0, 3), FlSpot(42, 3)],
                      color: Colors.orange,
                      barWidth: 1.5,
                      dashArray: const [6, 4],
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots
                          .map(
                            (s) => LineTooltipItem(
                              'Day ${s.x.toInt()}: ${s.y.toStringAsFixed(2)}% cumulative',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Weekly Deaths (bar chart)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: weekly.isEmpty
                      ? 100
                      : weekly
                                .map((e) => e.deaths.toDouble())
                                .reduce(math.max) +
                            20,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = weekly[groupIndex];
                        return BarTooltipItem(
                          'Week ${item.week}: ${item.deaths} birds',
                          const TextStyle(color: Colors.white, fontSize: 11),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, _) => Text(
                          'W${value.toInt() + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, _) => Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(weekly.length, (index) {
                    final item = weekly[index];
                    final color = item.deaths < 50
                        ? AppColors.emerald
                        : item.deaths < 100
                        ? AppColors.gold
                        : AppColors.danger;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: item.deaths.toDouble(),
                          color: color,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFcrTab(List<DailyRecordModel> records) {
    final summary = PerformanceCalculator.calculateSummary(records, batch);
    final currentFcr = summary.currentFcr;
    final currentDay = summary.currentDay;
    final standardFcr = _resolveFcrStandard(currentDay);

    final actualSpots =
        records
            .map(
              (r) => MapEntry(
                r.batchAgeDay,
                PerformanceCalculator.calculateCumulativeFcr(
                  records,
                  r.batchAgeDay,
                ),
              ),
            )
            .where((entry) => entry.value != null)
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value!))
            .toList()
          ..sort((a, b) => a.x.compareTo(b.x));

    final standardSpots = PerformanceCalculator.skmFcrStd.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    final currentColor = currentFcr == null
        ? AppColors.textSecondary
        : currentFcr < 1.5
        ? AppColors.emerald
        : currentFcr < 1.7
        ? AppColors.gold
        : AppColors.danger;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feed Conversion Ratio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'FCR = Feed consumed (kg) ÷ Live weight (kg). Lower is better.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentFcr?.toStringAsFixed(2) ?? '–',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: currentColor,
                  ),
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.emerald,
                            AppColors.gold,
                            AppColors.danger,
                          ],
                        ),
                      ),
                    ),
                    if (currentFcr != null)
                      Positioned(
                        left: ((currentFcr.clamp(0.5, 2.5) - 0.5) / 2.0) * 100,
                        top: -4,
                        child: const Icon(
                          Icons.arrow_drop_up,
                          color: AppColors.primaryDark,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'SKM Standard for day $currentDay: ${standardFcr.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: 0.5,
                  maxY: 2.5,
                  minX: 0,
                  maxX: 42,
                  backgroundColor: AppColors.background,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.25,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppColors.border, strokeWidth: 0.8),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: AppColors.border),
                      left: BorderSide(color: AppColors.border),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 0.25,
                        getTitlesWidget: (value, _) => Text(
                          value.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 7,
                        getTitlesWidget: (value, _) => Text(
                          'D${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: actualSpots,
                      color: AppColors.primary,
                      barWidth: 2.5,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, p1, p2, p3) => FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.primary,
                          strokeColor: Colors.white,
                          strokeWidth: 1.5,
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: standardSpots,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      barWidth: 1.5,
                      dashArray: const [6, 4],
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots
                          .map(
                            (s) => LineTooltipItem(
                              'Day ${s.x.toInt()}: FCR ${s.y.toStringAsFixed(2)} (std: ${_resolveFcrStandard(s.x.toInt()).toStringAsFixed(2)})',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: const [
                _FcrRangeRow(
                  '< 1.5',
                  'Excellent',
                  'Very efficient feed use',
                  true,
                ),
                _FcrRangeRow('1.5–1.7', 'Good', 'Industry standard', false),
                _FcrRangeRow('1.7–2.0', 'Fair', 'Room for improvement', false),
                _FcrRangeRow(
                  '> 2.0',
                  'Poor',
                  'Check feed wastage / health',
                  false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _resolveFcrStandard(int day) {
    var selected = 0.0;
    for (final entry in PerformanceCalculator.skmFcrStd.entries) {
      if (entry.key <= day) {
        selected = entry.value;
      }
    }
    return selected;
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FcrRangeRow extends StatelessWidget {
  const _FcrRangeRow(this.range, this.rating, this.meaning, this.highlight);

  final String range;
  final String rating;
  final String meaning;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primaryLight : AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              range,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              rating,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              meaning,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
