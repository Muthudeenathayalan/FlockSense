import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_record_form_screen.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';
import 'package:flock_sense/features/performance/presentation/providers/growth_analytics_providers.dart';
import 'package:flock_sense/features/performance/presentation/widgets/analytics_chart_card.dart';
import 'package:flock_sense/features/performance/presentation/widgets/analytics_filter_bar.dart';
import 'package:flock_sense/features/performance/presentation/widgets/analytics_summary_card.dart';
import 'package:flock_sense/features/performance/presentation/widgets/charts/adg_chart.dart';
import 'package:flock_sense/features/performance/presentation/widgets/charts/epef_gauge_card.dart';
import 'package:flock_sense/features/performance/presentation/widgets/charts/expense_breakdown_chart.dart';
import 'package:flock_sense/features/performance/presentation/widgets/charts/fcr_trend_chart.dart';
import 'package:flock_sense/features/performance/presentation/widgets/charts/feed_consumption_chart.dart';
import 'package:flock_sense/features/performance/presentation/widgets/charts/mortality_chart.dart';
import 'package:flock_sense/features/performance/presentation/widgets/charts/profit_trend_chart.dart';
import 'package:flock_sense/features/performance/presentation/widgets/charts/thi_chart.dart';
import 'package:flock_sense/features/performance/presentation/widgets/charts/water_consumption_chart.dart';
import 'package:flock_sense/features/performance/presentation/widgets/charts/weight_growth_chart.dart';
import 'package:flock_sense/features/performance/presentation/widgets/insights_card.dart';
import 'package:flock_sense/features/performance/presentation/widgets/lag_analysis_card.dart';
import 'package:flock_sense/features/performance/presentation/widgets/timelines/medicine_usage_timeline.dart';
import 'package:flock_sense/features/performance/presentation/widgets/timelines/vaccination_timeline_widget.dart';
import 'package:flock_sense/features/performance/services/analytics_export_service.dart';

class GrowthAnalyticsScreen extends ConsumerWidget {
  const GrowthAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(growthAnalyticsStreamProvider);
    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    final data = analyticsAsync.when(
      data: (d) => !d.isEmpty
          ? d
          : ref.read(growthAnalyticsServiceProvider).getFallbackData(),
      loading: () => ref.read(growthAnalyticsServiceProvider).getFallbackData(),
      error: (_, __) =>
          ref.read(growthAnalyticsServiceProvider).getFallbackData(),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Growth Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onSelected: (val) {
              switch (val) {
                case 'pdf':
                  AnalyticsExportService.printOrPreviewPdf(context, data);
                  break;
                case 'csv':
                  _showCsvDialog(context, data);
                  break;
                case 'share':
                  AnalyticsExportService.shareReport(context, data);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text('Export PDF Report'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green, size: 20),
                    SizedBox(width: 10),
                    Text('Export CSV Report'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Text('Share Telemetry Report'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DailyRecordFormScreen(
                farmId: data.activeFarm?.id ?? '',
                batchId: data.activeBatch?.id ?? '',
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text(
          'Log Telemetry',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          // Analytics Filter Bar
          AnalyticsFilterBar(
            farms: data.availableFarms,
            batches: data.availableBatches,
            activeFarm: data.activeFarm,
            activeBatch: data.activeBatch,
          ),
          const Divider(height: 1, color: AppColors.border),

          // Scrollable Analytics Body
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(growthAnalyticsStreamProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: 85,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. KPI Summary Cards Horizontal Strip
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          AnalyticsSummaryCard(
                            title: 'Total Birds',
                            value: '${data.totalBirdsRemaining}',
                            subtitle: '${data.totalMortality} mortality',
                            icon: Icons.pets_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          AnalyticsSummaryCard(
                            title: 'Avg Weight',
                            value:
                                '${data.averageWeightGrams.toStringAsFixed(0)}g',
                            subtitle: 'Day ${data.batchAgeDays}',
                            icon: Icons.monitor_weight_rounded,
                            color: const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 10),
                          AnalyticsSummaryCard(
                            title: 'FCR Index',
                            value: data.fcr.toStringAsFixed(2),
                            subtitle: data.fcr <= 1.55
                                ? 'Optimal range'
                                : 'High feed ratio',
                            icon: Icons.tune_rounded,
                            color: data.fcr <= 1.55
                                ? const Color(0xFF10B981)
                                : AppColors.danger,
                          ),
                          const SizedBox(width: 10),
                          AnalyticsSummaryCard(
                            title: 'Total Feed',
                            value:
                                '${data.totalFeedConsumedKg.toStringAsFixed(0)} kg',
                            subtitle: 'Cumulative intake',
                            icon: Icons.rice_bowl_rounded,
                            color: const Color(0xFFE49B25),
                          ),
                          const SizedBox(width: 10),
                          AnalyticsSummaryCard(
                            title: 'Net Profit',
                            value: currencyFormat.format(data.netProfit),
                            subtitle:
                                'Margin ${data.profitMarginPercentage.toStringAsFixed(1)}%',
                            icon: Icons.payments_rounded,
                            color: data.netProfit >= 0
                                ? const Color(0xFF10B981)
                                : AppColors.danger,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Lag & Bottleneck Diagnostic Card (CRITICAL REQUIREMENT)
                    LagAnalysisCard(data: data),

                    // 3. EPEF Efficiency Score Gauge Card
                    AnalyticsChartCard(
                      title: 'European Production Efficiency (EPEF)',
                      subtitle:
                          'Comprehensive performance index combining growth, FCR & livability',
                      child: EpefGaugeCard(data: data),
                    ),

                    // 4. Weight Growth Curve Chart
                    AnalyticsChartCard(
                      title: 'Weight Growth Curve (g)',
                      subtitle:
                          'Actual weight trajectory vs standard target curve',
                      child: WeightGrowthChart(points: data.weightGrowthPoints),
                    ),

                    // 5. FCR Benchmark Trend Chart
                    AnalyticsChartCard(
                      title: 'Feed Conversion Ratio (FCR) Trend',
                      subtitle: 'Actual FCR vs target benchmark (1.50)',
                      child: FcrTrendChart(data: data),
                    ),

                    // 6. Average Daily Weight Gain (ADG) Chart
                    AnalyticsChartCard(
                      title: 'Average Daily Gain (ADG - g/day)',
                      subtitle:
                          'Daily growth rate velocity to identify stagnation days',
                      child: AdgChart(data: data),
                    ),

                    // 7. Daily Feed Consumption Chart
                    AnalyticsChartCard(
                      title: 'Daily Feed Consumption (kg)',
                      subtitle: 'Daily feed intake progression per bird',
                      child: FeedConsumptionChart(
                        bars: data.feedConsumptionBars,
                      ),
                    ),

                    // 8. Daily Water Consumption Chart
                    AnalyticsChartCard(
                      title: 'Water Intake & Feed Ratio',
                      subtitle:
                          'Daily water consumption (L) and hydration ratio',
                      child: WaterConsumptionChart(
                        points: data.waterConsumptionPoints,
                      ),
                    ),

                    // 9. Mortality & Livability Rate Chart
                    AnalyticsChartCard(
                      title: 'Mortality & Livability %',
                      subtitle:
                          'Daily mortality count & cumulative survival rate',
                      child: MortalityChart(bars: data.mortalityBars),
                    ),

                    // 10. Environmental THI Heat Stress Chart
                    AnalyticsChartCard(
                      title: 'Temperature & Humidity Index (THI)',
                      subtitle:
                          'Daily shed temperature (°C) & relative humidity (%)',
                      child: ThiChart(data: data),
                    ),

                    // 11. Expense Breakdown Pie Chart
                    AnalyticsChartCard(
                      title: 'Cost Structure Breakdown',
                      subtitle:
                          'Distribution of feed, medicine, vaccine & operational costs',
                      child: ExpenseBreakdownChart(
                        categories: data.expenseBreakdown,
                      ),
                    ),

                    // 12. Revenue vs Profit Margin Chart
                    AnalyticsChartCard(
                      title: 'Financial Profit Trend',
                      subtitle: 'Cumulative revenue vs net profit margin',
                      child: ProfitTrendChart(points: data.profitTrendPoints),
                    ),

                    // 13. Smart Telemetry AI Insights Card
                    InsightsCard(insights: data.aiInsights),
                    const SizedBox(height: 16),

                    // 14. Timelines: Vaccination & Medicine
                    VaccinationTimelineWidget(vaccines: data.vaccineTimeline),
                    const SizedBox(height: 14),
                    MedicineUsageTimeline(medicines: data.medicineTimeline),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCsvDialog(BuildContext context, GrowthAnalyticsData data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export CSV Dataset'),
        content: const Text(
          'Generated CSV contains daily weight, feed, water, mortality, FCR, and financial records for analysis in Excel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AnalyticsExportService.shareReport(context, data);
            },
            icon: const Icon(Icons.download),
            label: const Text('Download CSV'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to calculate growth telemetry',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().contains('permission-denied')
                  ? 'Permission denied. Check Firestore security rules.'
                  : 'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => ref.invalidate(growthAnalyticsStreamProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
