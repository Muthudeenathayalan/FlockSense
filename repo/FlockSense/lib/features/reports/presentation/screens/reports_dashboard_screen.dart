import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';
import 'package:flock_sense/features/reports/presentation/providers/reports_providers.dart';
import 'package:flock_sense/features/reports/presentation/widgets/export_dialog.dart';
import 'package:flock_sense/features/reports/presentation/widgets/recent_reports_section.dart';
import 'package:flock_sense/features/reports/presentation/widgets/report_card.dart';
import 'package:flock_sense/features/reports/presentation/widgets/report_filter_bar.dart';
import 'package:flock_sense/features/reports/presentation/widgets/report_history_section.dart';
import 'package:flock_sense/features/reports/presentation/widgets/report_preview_modal.dart';

class ReportsDashboardScreen extends ConsumerStatefulWidget {
  const ReportsDashboardScreen({
    super.key,
    this.initialFarmId,
    this.initialBatchId,
  });

  final String? initialFarmId;
  final String? initialBatchId;

  @override
  ConsumerState<ReportsDashboardScreen> createState() =>
      _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState
    extends ConsumerState<ReportsDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialFarmId != null || widget.initialBatchId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialFarmId != null) {
          ref
              .read(reportsFilterProvider.notifier)
              .setFarmId(widget.initialFarmId);
        }
        if (widget.initialBatchId != null) {
          ref
              .read(reportsFilterProvider.notifier)
              .setBatchId(widget.initialBatchId);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(reportsFilterProvider);
    final filterNotifier = ref.read(reportsFilterProvider.notifier);
    final reportsAsync = ref.watch(reportsDataProvider);
    final historyItems = ref.watch(reportsHistoryProvider);

    final filteredTypes = ReportType.values.where((type) {
      if (filterState.searchQuery.isEmpty) return true;
      final q = filterState.searchQuery.toLowerCase();
      return type.title.toLowerCase().contains(q) ||
          type.description.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Export Center'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => ref.invalidate(reportsDataProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: reportsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => _buildErrorView(err),
          data: (data) => _buildDashboardBody(
            context: context,
            data: data,
            filterState: filterState,
            filterNotifier: filterNotifier,
            filteredTypes: filteredTypes,
            historyItems: historyItems,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to Load Report Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(reportsDataProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardBody({
    required BuildContext context,
    required ReportData data,
    required ReportFilterState filterState,
    required ReportsFilterNotifier filterNotifier,
    required List<ReportType> filteredTypes,
    required List<ReportHistoryItem> historyItems,
  }) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(reportsDataProvider),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
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
              child: TextField(
                controller: _searchController,
                onChanged: (val) => filterNotifier.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText:
                      'Search report types (e.g. Farm, Finance, Growth)...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  suffixIcon: filterState.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            filterNotifier.setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filter Bar
            ReportFilterBar(farms: data.farms, batches: data.batches),
            const SizedBox(height: 16),

            // Informational Notice if Telemetry is Empty for this Selection
            if (data.dailyRecords.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFD97706),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'No daily telemetry records for this selection',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Reports display baseline setup and breed standards. Switch batches above or log daily telemetry.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const DailyRecordsDashboardScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Add Record',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Recently Generated Reports
            RecentReportsSection(historyItems: historyItems, reportData: data),
            if (historyItems.isNotEmpty) const SizedBox(height: 24),

            // Category Header
            Row(
              children: [
                const Icon(
                  Icons.grid_view_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Report Categories (${filteredTypes.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid of Report Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600
                    ? 3
                    : (constraints.maxWidth > 340 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 220,
                  ),
                  itemCount: filteredTypes.length,
                  itemBuilder: (context, index) {
                    final type = filteredTypes[index];
                    final historyMatch = historyItems
                        .where((h) => h.reportType == type)
                        .toList();
                    final lastDate = historyMatch.isNotEmpty
                        ? historyMatch.first.generatedAt
                        : null;

                    return ReportCard(
                      reportType: type,
                      lastGeneratedDate: lastDate,
                      onTapPreview: () {
                        ReportPreviewModal.show(
                          context,
                          reportType: type,
                          data: data,
                        );
                      },
                      onTapExport: () {
                        ExportDialog.show(
                          context,
                          reportType: type,
                          data: data,
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 28),

            // Full Report History Section
            ReportHistorySection(historyItems: historyItems, reportData: data),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
