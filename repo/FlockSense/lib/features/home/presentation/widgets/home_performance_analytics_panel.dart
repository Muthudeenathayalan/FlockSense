import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_section_header.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_tokens.dart';

/// Interactive segmented telemetry charts panel with locked Y-axis width.
class HomePerformanceAnalyticsPanel extends StatefulWidget {
  const HomePerformanceAnalyticsPanel({
    super.key,
    required this.data,
    required this.onAddBatch,
  });

  final HomeDashboardData data;
  final VoidCallback onAddBatch;

  @override
  State<HomePerformanceAnalyticsPanel> createState() =>
      _HomePerformanceAnalyticsPanelState();
}

class _HomePerformanceAnalyticsPanelState
    extends State<HomePerformanceAnalyticsPanel> {
  int _selectedTab = 0;

  static const List<String> _tabs = [
    'Population',
    'Feed & FCR',
    'Mortality',
    'Revenue Proj',
  ];

  static const List<IconData> _tabIcons = [
    Icons.people_alt_rounded,
    Icons.grass_rounded,
    Icons.health_and_safety_rounded,
    Icons.insights_rounded,
  ];

  List<String> get _tabSummaries {
    final liveBirdsStr = NumberFormat('#,###').format(widget.data.liveBirds);
    final fcr = widget.data.estFcr;
    final fcrStr = fcr != null ? fcr.toStringAsFixed(2) : '--';

    return [
      'Live Survival: $liveBirdsStr birds • Active Batches: ${widget.data.activeBatchCount}',
      'Est. FCR: $fcrStr • Daily Records: ${widget.data.recentRecords.length} entries',
      "Today's Losses: ${widget.data.todayMortality} birds • Monitored Batches: ${widget.data.activeBatchCount}",
      'Active Cycle Valuation • ${widget.data.activeBatchCount} flock(s) in growth',
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.activeBatchCount == 0 || widget.data.liveBirds == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeSectionHeader(
            title: 'Performance Analytics',
            subtitle: 'Live flock telemetry, intake & financial projections',
          ),
          const SizedBox(height: HomeTokens.gapHeaderToBody),
          _EmptyAnalyticsCard(
            onAddBatch: widget.onAddBatch,
            hasFarms: widget.data.farms.isNotEmpty,
          ),
        ],
      );
    }

    final summaries = _tabSummaries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: 'Performance Analytics',
          subtitle: 'Live flock telemetry, intake & financial projections',
        ),
        const SizedBox(height: HomeTokens.gapHeaderToBody),
        Container(
          decoration: BoxDecoration(
            color: HomeTokens.surface,
            borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
            border: Border.all(color: HomeTokens.border, width: 1),
            boxShadow: HomeTokens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_tabs.length, (i) {
                      final selected = i == _selectedTab;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTab = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? HomeTokens.primary : HomeTokens.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? HomeTokens.primary : HomeTokens.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _tabIcons[i],
                                size: 13,
                                color: selected ? Colors.white : HomeTokens.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _tabs[i],
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? Colors.white : HomeTokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: HomeTokens.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: HomeTokens.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        summaries[_selectedTab],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: HomeTokens.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: SizedBox(
                  height: 160,
                  child: _buildSelectedChart(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedChart() {
    switch (_selectedTab) {
      case 0:
        return _PopulationChart(data: widget.data);
      case 1:
        return _FeedEfficiencyChart(data: widget.data);
      case 2:
        return _MortalityChart(data: widget.data);
      case 3:
        return _RevenueChart(data: widget.data);
      default:
        return _PopulationChart(data: widget.data);
    }
  }
}

FlGridData _cleanGrid() => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: HomeTokens.borderLight, strokeWidth: 1),
    );

class _EmptyChartState extends StatelessWidget {
  const _EmptyChartState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_rounded, size: 32, color: HomeTokens.textMuted),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: HomeTokens.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopulationChart extends StatelessWidget {
  const _PopulationChart({required this.data});
  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final sorted = [...data.recentRecords]
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));
    final recs = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;

    if (recs.length < 2) {
      return const _EmptyChartState(
        message: 'Log daily telemetry records for this batch to render live population survival curves.',
      );
    }

    final spots = <FlSpot>[];
    double minBirds = recs.first.closingBirds.toDouble();
    double maxBirds = recs.first.closingBirds.toDouble();

    for (var i = 0; i < recs.length; i++) {
      final birds = recs[i].closingBirds.toDouble();
      if (birds < minBirds) minBirds = birds;
      if (birds > maxBirds) maxBirds = birds;
      spots.add(FlSpot(i.toDouble(), birds));
    }

    final minY = (minBirds - 10).clamp(0.0, double.infinity);
    final maxY = maxBirds + 10;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: HomeTokens.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3.5,
                color: HomeTokens.primary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  HomeTokens.primary.withValues(alpha: 0.22),
                  HomeTokens.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= recs.length) return const SizedBox.shrink();
                final label = recs[i].batchAgeDay > 0
                    ? 'D${recs[i].batchAgeDay}'
                    : DateFormat('MM/dd').format(recs[i].recordDate);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: HomeTokens.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44, // Locked to 44
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(
                  fontSize: 9,
                  color: HomeTokens.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: _cleanGrid(),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _FeedEfficiencyChart extends StatelessWidget {
  const _FeedEfficiencyChart({required this.data});
  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final sorted = [...data.recentRecords]
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));
    final recs = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;

    if (recs.length < 2) {
      return const _EmptyChartState(
        message: 'Log daily feed consumption records to render the feed intake and FCR efficiency trend.',
      );
    }

    final feedSpots = <FlSpot>[];
    double maxFeed = 1.0;
    for (var i = 0; i < recs.length; i++) {
      final feed = recs[i].feedConsumedKg;
      if (feed > maxFeed) maxFeed = feed;
      feedSpots.add(FlSpot(i.toDouble(), feed));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxFeed * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: feedSpots,
            isCurved: true,
            color: HomeTokens.sky,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3.5,
                color: HomeTokens.sky,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  HomeTokens.sky.withValues(alpha: 0.20),
                  HomeTokens.sky.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= recs.length) return const SizedBox.shrink();
                final label = recs[i].batchAgeDay > 0
                    ? 'D${recs[i].batchAgeDay}'
                    : DateFormat('MM/dd').format(recs[i].recordDate);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: HomeTokens.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44, // Locked to 44
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}kg',
                style: const TextStyle(
                  fontSize: 9,
                  color: HomeTokens.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: _cleanGrid(),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _MortalityChart extends StatelessWidget {
  const _MortalityChart({required this.data});
  final HomeDashboardData data;

  static Color _barColor(double v) {
    if (v == 0) return HomeTokens.primary;
    if (v <= 2) return HomeTokens.amber;
    return HomeTokens.red;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...data.recentRecords]
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));
    final recs = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;

    if (recs.length < 2) {
      return const _EmptyChartState(
        message: 'Log daily records to view mortality tracking and shed health alerts.',
      );
    }

    double maxMort = 5.0;
    for (final r in recs) {
      if (r.mortalityCount > maxMort) maxMort = r.mortalityCount.toDouble();
    }

    return BarChart(
      BarChartData(
        maxY: maxMort * 1.2,
        barGroups: List.generate(
          recs.length,
          (i) {
            final m = recs[i].mortalityCount.toDouble();
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: m,
                  color: _barColor(m),
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= recs.length) return const SizedBox.shrink();
                final label = recs[i].batchAgeDay > 0
                    ? 'D${recs[i].batchAgeDay}'
                    : DateFormat('MM/dd').format(recs[i].recordDate);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: HomeTokens.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44, // Locked to 44
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(
                  fontSize: 9,
                  color: HomeTokens.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: _cleanGrid(),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.data});
  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final sorted = [...data.recentRecords]
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));
    final recs = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;

    if (recs.length < 2) {
      return const _EmptyChartState(
        message: 'Log body weights and daily records to project harvest valuation and flock revenues.',
      );
    }

    final spots = <FlSpot>[];
    double maxVal = 1.0;
    for (var i = 0; i < recs.length; i++) {
      final r = recs[i];
      final weightGrams = r.avgWeightGrams > 0 ? r.avgWeightGrams : 45.0;
      final weightKg = weightGrams / 1000.0;
      final valK = (r.closingBirds * weightKg * 110.0) / 1000.0;
      if (valK > maxVal) maxVal = valK;
      spots.add(FlSpot(i.toDouble(), valK));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxVal * 1.25,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: HomeTokens.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3.5,
                color: HomeTokens.primary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  HomeTokens.primary.withValues(alpha: 0.22),
                  HomeTokens.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= recs.length) return const SizedBox.shrink();
                final label = recs[i].batchAgeDay > 0
                    ? 'D${recs[i].batchAgeDay}'
                    : DateFormat('MM/dd').format(recs[i].recordDate);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: HomeTokens.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44, // Locked to 44
              getTitlesWidget: (v, _) => Text(
                '₹${v.toInt()}K',
                style: const TextStyle(
                  fontSize: 9,
                  color: HomeTokens.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: _cleanGrid(),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard({
    required this.onAddBatch,
    required this.hasFarms,
  });

  final VoidCallback onAddBatch;
  final bool hasFarms;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: HomeTokens.surface,
        borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
        border: Border.all(color: HomeTokens.border, width: 1),
        boxShadow: HomeTokens.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: HomeTokens.blueTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: HomeTokens.blue,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Active Flock Telemetry',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: HomeTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Population curves, feed conversion ratio (FCR), and financial forecasts will automatically render when an active flock batch is logging daily records.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: HomeTokens.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onAddBatch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: HomeTokens.primary,
                borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    hasFarms ? 'Add Batch' : 'Register Farm',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
