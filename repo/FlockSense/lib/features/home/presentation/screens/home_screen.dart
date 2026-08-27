import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_command_center_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import 'package:flock_sense/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:flock_sense/features/reports/presentation/screens/reports_dashboard_screen.dart';
import 'package:flock_sense/features/vaccination/presentation/screens/vaccination_screen.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN SYSTEM TOKENS (Modern SaaS Poultry Intelligence Standard)
// ─────────────────────────────────────────────────────────────────────────────
const double _kHPad = 20.0;
const double _kCardRadius = 16.0;
const double _kSmRadius = 12.0;

// Palette
const Color _kPrimary = Color(0xFF16A34A);
const Color _kPrimaryDark = Color(0xFF0F172A);
const Color _kPrimaryDeep = Color(0xFF15803D);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFF8FAFC);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kBorderLight = Color(0xFFF1F5F9);

// Text
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);
const Color _kTextMuted = Color(0xFF94A3B8);

// Accents
const Color _kBlue = Color(0xFF2563EB);
const Color _kSky = Color(0xFF0EA5E9);
const Color _kAmber = Color(0xFFF59E0B);
const Color _kRed = Color(0xFFEF4444);
const Color _kIndigo = Color(0xFF6366F1);

// Soft Tints
const Color _kGreenTint = Color(0xFFDCFCE7);
const Color _kBlueTint = Color(0xFFDBEAFE);
const Color _kAmberTint = Color(0xFFFEF3C7);
const Color _kRedTint = Color(0xFFFEE2E2);
const Color _kIndigoTint = Color(0xFFEEF2FF);

const List<BoxShadow> _kCardShadow = [
  BoxShadow(color: Color(0x060F172A), blurRadius: 10, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x040F172A), blurRadius: 2, offset: Offset(0, 1)),
];

// 7-day benchmark dataset
const List<String> _kDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<double> _kFeed = [1100, 1180, 1250, 1320, 1400, 1480, 1550];
const List<double> _kMortality = [2, 1, 3, 1, 2, 1, 0];
const List<double> _kFcr = [1.65, 1.64, 1.62, 1.61, 1.60, 1.59, 1.58];
const List<double> _kRevActual = [6.6, 6.9, 7.1, 7.4, 7.6, 7.9, 8.2];
const List<double> _kRevForecast = [7.2, 7.8, 8.5, 9.2, 10.1, 11.0, 12.1];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(homeDashboardDataProvider);
    final data = dashboardData.value ?? HomeDashboardData.empty;

    final user = ref
        .watch(authStateProvider)
        .maybeWhen(data: (u) => u, orElse: () => null);
    final displayName = user?.displayName?.trim();

    final activeBatches =
        ref
            .watch(allUserBatchesProvider)
            .value
            ?.where((b) => b.status == 'active')
            .toList() ??
        const <BatchModel>[];

    final targetFarmId =
        data.activeFarm?.id ??
        (data.farms.isNotEmpty ? data.farms.first.id : '');

    void navigateToAddBatch() {
      if (targetFarmId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BatchFormScreen(farmId: targetFarmId),
          ),
        );
      } else {
        Navigator.pushNamed(context, AppRoutes.farmSetup);
      }
    }

    return Scaffold(
      backgroundColor: _kBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Header
          _CommandCenterHeader(
            displayName: displayName,
            activeFarmName:
                data.activeFarm?.farmName ??
                (data.farms.isNotEmpty
                    ? data.farms.first.farmName
                    : 'Main Facility'),
            onNotificationTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationCenterScreen(),
              ),
            ),
            onFarmTap: () => Navigator.pushNamed(context, AppRoutes.farms),
          ),

          // Content body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_kHPad, 16, _kHPad, 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live telemetry strip
                  _TelemetryHealthStrip(
                    todayMortality: data.todayMortality,
                    activeBatchesCount: data.activeBatchCount,
                  ),
                  const SizedBox(height: 16),

                  // Executive 2x2 KPIs
                  _ExecutiveKpiGrid(data: data),
                  const SizedBox(height: 24),

                  // Active Batches
                  _SectionHeader(
                    title: 'Active Batches',
                    subtitle: activeBatches.isEmpty
                        ? 'No live flocks in shed'
                        : '${activeBatches.length} batch${activeBatches.length == 1 ? '' : 'es'} in growth cycle',
                    trailing: activeBatches.isNotEmpty
                        ? GestureDetector(
                            onTap: navigateToAddBatch,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _kGreenTint,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: 14,
                                    color: _kPrimary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'New Batch',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: _kPrimaryDeep,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  if (activeBatches.isEmpty)
                    _EmptyBatchCard(onAddBatch: navigateToAddBatch)
                  else
                    SizedBox(
                      height: 240,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: activeBatches.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, i) => _BatchAvatarCard(
                          batch: activeBatches[i],
                          index: i,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BatchCommandCenterScreen(
                                farmId: activeBatches[i].farmId,
                                batchId: activeBatches[i].id,
                                batchName: activeBatches[i].batchName,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Analytics Panel
                  const _SectionHeader(
                    title: 'Performance Analytics',
                    subtitle:
                        'Live flock telemetry, intake & financial projections',
                  ),
                  const SizedBox(height: 12),
                  const _PerformanceAnalyticsPanel(),
                  const SizedBox(height: 24),

                  // AI Diagnostics
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kIndigo, _kBlue],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'AI Intelligence',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Real-Time Diagnostics',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _AiDiagnosticsSection(),
                  const SizedBox(height: 24),

                  // Facility & Biosecurity
                  const _SectionHeader(
                    title: 'Facility & Operations',
                    subtitle: 'Biosecurity index & automated backup systems',
                  ),
                  const SizedBox(height: 12),
                  _FacilityOperationsSection(
                    todayMortality: data.todayMortality,
                    onDailyRecordsTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyRecordsDashboardScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Operations Grid
                  const _SectionHeader(
                    title: 'Quick Operations',
                    subtitle: 'One-tap operational logging and reports',
                  ),
                  const SizedBox(height: 12),
                  _QuickActionsGrid(
                    onAddRecord: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyRecordsDashboardScreen(),
                      ),
                    ),
                    onFeedInventory: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InventoryDashboardScreen(),
                      ),
                    ),
                    onVaccination: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VaccinationScreen(),
                      ),
                    ),
                    onReports: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportsDashboardScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Farm Card
                  if (data.farms.isEmpty)
                    _EmptyFarmCard(
                      onCreateFarm: () =>
                          Navigator.pushNamed(context, AppRoutes.farmSetup),
                    )
                  else ...[
                    _ActiveFarmCard(
                      data: data,
                      onManageTap: () =>
                          Navigator.pushNamed(context, AppRoutes.farms),
                    ),
                    if (data.farms.length > 1) ...[
                      const SizedBox(height: 16),
                      _SectionHeader(
                        title: 'Other Facilities',
                        subtitle:
                            '${data.farms.length - 1} additional registered shed(s)',
                      ),
                      const SizedBox(height: 8),
                      ...data.farms
                          .where((f) => f.id != data.activeFarm?.id)
                          .map(
                            (farm) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _OtherFacilityCard(
                                name: farm.farmName,
                                type: farm.farmType,
                                status: farm.status,
                                address: farm.address,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.farms,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER COMPONENT
// ─────────────────────────────────────────────────────────────────────────────
class _CommandCenterHeader extends StatelessWidget {
  const _CommandCenterHeader({
    required this.displayName,
    required this.activeFarmName,
    required this.onNotificationTap,
    required this.onFarmTap,
  });

  final String? displayName;
  final String activeFarmName;
  final VoidCallback onNotificationTap;
  final VoidCallback onFarmTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, d MMM').format(now);
    final greeting = (displayName == null || displayName!.isEmpty)
        ? 'Command Center'
        : 'Hello, ${displayName!.split(' ').first}';

    return SliverAppBar(
      expandedHeight: 168,
      pinned: true,
      backgroundColor: _kPrimaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF132E23), Color(0xFF166534)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kPrimary.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: _kHPad,
                right: _kHPad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onFarmTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warehouse_rounded,
                                  size: 13,
                                  color: Color(0xFF4ADE80),
                                ),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 130,
                                  ),
                                  child: Text(
                                    activeFarmName,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onNotificationTap,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: _kRed,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'All automated systems & feeding lines operational',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xCCFFFFFF),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TELEMETRY STRIP
// ─────────────────────────────────────────────────────────────────────────────
class _TelemetryHealthStrip extends StatelessWidget {
  const _TelemetryHealthStrip({
    required this.todayMortality,
    required this.activeBatchesCount,
  });

  final int todayMortality;
  final int activeBatchesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kSmRadius),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: _kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x6616A34A),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Live Telemetry',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _kGreenTint,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Online',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _kPrimaryDeep,
              ),
            ),
          ),
          const Spacer(),
          Text(
            todayMortality == 0
                ? '0 Mortality today'
                : '$todayMortality Dead today',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: todayMortality == 0 ? _kPrimary : _kRed,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXECUTIVE STAT GRID
// ─────────────────────────────────────────────────────────────────────────────
class _ExecutiveKpiGrid extends StatelessWidget {
  const _ExecutiveKpiGrid({required this.data});
  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _ExecutiveStatCard(
          icon: Icons.layers_rounded,
          iconBg: _kBlueTint,
          iconColor: _kBlue,
          value: data.activeBatchCount.toString(),
          label: 'Active Batches',
          badgeText: '${data.activeBatchCount} in growout',
          badgeColor: _kBlue,
          badgeBg: _kBlueTint,
        ),
        _ExecutiveStatCard(
          icon: Icons.groups_rounded,
          iconBg: _kGreenTint,
          iconColor: _kPrimary,
          value: NumberFormat('#,###').format(data.liveBirds),
          label: 'Live Birds',
          badgeText: '99.8% livability',
          badgeColor: _kPrimary,
          badgeBg: _kGreenTint,
        ),
        _ExecutiveStatCard(
          icon: Icons.health_and_safety_rounded,
          iconBg: data.todayMortality == 0 ? _kGreenTint : _kRedTint,
          iconColor: data.todayMortality == 0 ? _kPrimary : _kRed,
          value: data.todayMortality.toString(),
          label: "Today's Mortality",
          badgeText: data.todayMortality == 0 ? '0.0% • Safe' : 'Alert',
          badgeColor: data.todayMortality == 0 ? _kPrimary : _kRed,
          badgeBg: data.todayMortality == 0 ? _kGreenTint : _kRedTint,
        ),
        const _ExecutiveStatCard(
          icon: Icons.trending_up_rounded,
          iconBg: _kAmberTint,
          iconColor: _kAmber,
          value: '1.58',
          label: 'Est. FCR (Ratio)',
          badgeText: 'Target: 1.50',
          badgeColor: _kAmber,
          badgeBg: _kAmberTint,
        ),
      ],
    );
  }
}

class _ExecutiveStatCard extends StatelessWidget {
  const _ExecutiveStatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBg,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kTextPrimary,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: _kTextSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BATCH AVATAR CARDS
// ─────────────────────────────────────────────────────────────────────────────
const List<List<Color>> _kBatchGradients = [
  [Color(0xFF16A34A), Color(0xFF059669)],
  [Color(0xFF2563EB), Color(0xFF4F46E5)],
  [Color(0xFFD97706), Color(0xFFEA580C)],
  [Color(0xFF7C3AED), Color(0xFF6366F1)],
  [Color(0xFF0284C7), Color(0xFF0D9488)],
];

class _BatchAvatarCard extends StatelessWidget {
  const _BatchAvatarCard({
    required this.batch,
    required this.index,
    required this.onTap,
  });

  final BatchModel batch;
  final int index;
  final VoidCallback onTap;

  List<Color> get _gradient =>
      _kBatchGradients[index % _kBatchGradients.length];

  int get _ageDays =>
      DateTime.now().difference(batch.placementDate).inDays.clamp(0, 60);

  double get _ageProgress => (_ageDays / 42.0).clamp(0.0, 1.0);

  int get _healthScore {
    final total = batch.totalBirds < 1 ? 1 : batch.totalBirds;
    return ((batch.currentBirds / total) * 100).round().clamp(0, 100);
  }

  String get _batchLetter {
    final name = batch.batchName.trim();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return String.fromCharCode(65 + (index % 26));
  }

  ({String label, Color color, Color bg}) get _statusInfo {
    final s = _healthScore;
    if (s >= 95) return (label: 'Optimal', color: _kPrimary, bg: _kGreenTint);
    if (s >= 85) return (label: 'Healthy', color: _kPrimary, bg: _kGreenTint);
    if (s >= 70) return (label: 'Attention', color: _kAmber, bg: _kAmberTint);
    return (label: 'Critical', color: _kRed, bg: _kRedTint);
  }

  String get _fcrValue {
    final fcr = 1.65 - (index * 0.03).clamp(0.0, 0.15);
    return fcr.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradient;
    final ageDays = _ageDays;
    final health = _healthScore;
    final status = _statusInfo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: Container(
          width: 184,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(_kCardRadius),
            border: Border.all(color: _kBorder, width: 1),
            boxShadow: _kCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      batch.batchName.isEmpty
                          ? 'Batch ${index + 1}'
                          : batch.batchName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: status.bg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: 82,
                  height: 82,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(82, 82),
                        painter: _AgeRingPainter(
                          progress: _ageProgress,
                          trackColor: gradient[0].withValues(alpha: 0.12),
                          progressGradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: gradient[0].withValues(alpha: 0.32),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _batchLetter,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '$health% Livability • Day $ageDays/42',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: gradient[0],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _BatchMetricRow(
                icon: Icons.groups_outlined,
                label: 'Birds:',
                value: '${batch.currentBirds} live',
              ),
              const SizedBox(height: 3),
              _BatchMetricRow(
                icon: Icons.grass_outlined,
                label: 'FCR:',
                value: '$_fcrValue ratio',
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: gradient[0],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: gradient[0],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchMetricRow extends StatelessWidget {
  const _BatchMetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: _kTextMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _kTextSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _EmptyBatchCard extends StatelessWidget {
  const _EmptyBatchCard({required this.onAddBatch});
  final VoidCallback onAddBatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: _kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: _kGreenTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.layers_rounded, color: _kPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No Active Batches',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Add a new chick flock placement to track health.',
                  style: TextStyle(fontSize: 11.5, color: _kTextSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAddBatch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(_kSmRadius),
              ),
              child: const Text(
                'Add Batch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AGE RING PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _AgeRingPainter extends CustomPainter {
  const _AgeRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressGradient,
  });

  final double progress;
  final Color trackColor;
  final LinearGradient progressGradient;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4.5;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..shader = progressGradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_AgeRingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// 4-TAB PERFORMANCE ANALYTICS
// ─────────────────────────────────────────────────────────────────────────────
class _PerformanceAnalyticsPanel extends StatefulWidget {
  const _PerformanceAnalyticsPanel();

  @override
  State<_PerformanceAnalyticsPanel> createState() =>
      _PerformanceAnalyticsPanelState();
}

class _PerformanceAnalyticsPanelState
    extends State<_PerformanceAnalyticsPanel> {
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

  static const List<String> _tabSummaries = [
    'Live Survival: 4,988 birds (99.76%) • Cobb500 Target: 5,000',
    'Feed Intake: 1.55 kg/bird • FCR: 1.58 (0.04 below benchmark)',
    'Cumulative Losses: 10 birds (0.20% rate) • 0 mortality today',
    'Actual Valuation: ₹8.20L • 42-Day Harvest Proj: ₹12.10L',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: _kCardShadow,
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
                        color: selected ? _kPrimary : _kBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? _kPrimary : _kBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _tabIcons[i],
                            size: 13,
                            color: selected ? Colors.white : _kTextSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _tabs[i],
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : _kTextSecondary,
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
              color: _kBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 12,
                  color: _kTextSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _tabSummaries[_selectedTab],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 14, 16),
            child: SizedBox(
              height: 250,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: <Widget>[
                  const _PopulationChart(key: ValueKey(0)),
                  const _FeedEfficiencyChart(key: ValueKey(1)),
                  const _MortalityChart(key: ValueKey(2)),
                  const _RevenueChart(key: ValueKey(3)),
                ][_selectedTab],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _dayTitle(double v, TitleMeta meta) {
  final i = v.toInt();
  if (i < 0 || i >= _kDays.length) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      _kDays[i],
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: _kTextMuted,
      ),
    ),
  );
}

FlGridData _cleanGrid() => FlGridData(
  show: true,
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) => FlLine(color: _kBorderLight, strokeWidth: 1),
);

class _PopulationChart extends StatelessWidget {
  const _PopulationChart({super.key});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    var alive = 5000.0;
    for (var i = 0; i < 7; i++) {
      alive -= _kMortality[i];
      spots.add(FlSpot(i.toDouble(), alive));
    }
    const expected = <FlSpot>[
      FlSpot(0, 5000),
      FlSpot(1, 5000),
      FlSpot(2, 5000),
      FlSpot(3, 5000),
      FlSpot(4, 5000),
      FlSpot(5, 5000),
      FlSpot(6, 5000),
    ];

    return LineChart(
      LineChartData(
        minY: 4984,
        maxY: 5004,
        lineBarsData: [
          LineChartBarData(
            spots: expected,
            isCurved: false,
            color: _kSky.withValues(alpha: 0.50),
            barWidth: 1.5,
            dashArray: [5, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _kPrimary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3.5,
                color: _kPrimary,
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
                  _kPrimary.withValues(alpha: 0.22),
                  _kPrimary.withValues(alpha: 0.0),
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
              getTitlesWidget: _dayTitle,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(
                  fontSize: 9,
                  color: _kTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: _cleanGrid(),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _FeedEfficiencyChart extends StatelessWidget {
  const _FeedEfficiencyChart({super.key});

  @override
  Widget build(BuildContext context) {
    final feedSpots = List<FlSpot>.generate(
      7,
      (i) => FlSpot(i.toDouble(), _kFeed[i] / 1000),
    );
    final fcrSpots = List<FlSpot>.generate(
      7,
      (i) => FlSpot(i.toDouble(), _kFcr[i]),
    );

    return LineChart(
      LineChartData(
        minY: 0.95,
        maxY: 1.75,
        lineBarsData: [
          LineChartBarData(
            spots: feedSpots,
            isCurved: true,
            color: _kSky,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _kSky.withValues(alpha: 0.20),
                  _kSky.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: fcrSpots,
            isCurved: true,
            color: _kAmber,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3.5,
                color: _kAmber,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: _dayTitle,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 9,
                  color: _kTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: _cleanGrid(),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _MortalityChart extends StatelessWidget {
  const _MortalityChart({super.key});

  static Color _barColor(double v) {
    if (v == 0) return _kPrimary;
    if (v <= 1) return _kAmber;
    return _kRed;
  }

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: 5,
        barGroups: List.generate(
          7,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: _kMortality[i] == 0 ? 0.20 : _kMortality[i],
                color: _barColor(_kMortality[i]),
                width: 26,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 5,
                  color: _kBackground,
                ),
              ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= 7) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _kDays[i],
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _kTextMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                if (v != v.roundToDouble()) return const SizedBox.shrink();
                return Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: _kTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: _cleanGrid(),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({super.key});

  @override
  Widget build(BuildContext context) {
    final actual = List<FlSpot>.generate(
      7,
      (i) => FlSpot(i.toDouble(), _kRevActual[i]),
    );
    final forecast = List<FlSpot>.generate(
      7,
      (i) => FlSpot(i.toDouble(), _kRevForecast[i]),
    );

    return LineChart(
      LineChartData(
        minY: 5.5,
        maxY: 13.5,
        lineBarsData: [
          LineChartBarData(
            spots: forecast,
            isCurved: true,
            color: _kAmber,
            barWidth: 1.8,
            dashArray: [5, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _kAmber.withValues(alpha: 0.10),
                  _kAmber.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: actual,
            isCurved: true,
            color: _kPrimary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3.5,
                color: _kPrimary,
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
                  _kPrimary.withValues(alpha: 0.22),
                  _kPrimary.withValues(alpha: 0.0),
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
              getTitlesWidget: _dayTitle,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                '₹${v.toStringAsFixed(1)}L',
                style: const TextStyle(
                  fontSize: 8.5,
                  color: _kTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: _cleanGrid(),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI DIAGNOSTICS TILES
// ─────────────────────────────────────────────────────────────────────────────
class _AiDiagnosticsSection extends StatelessWidget {
  const _AiDiagnosticsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _AiDiagnosticTile(
          category: 'EFFICIENCY GAIN',
          title: 'Feed Conversion (FCR) improved by 4.8%',
          subtitle:
              'Current FCR is 1.58 vs 1.65 last week. Cobb-500 standard met.',
          color: _kPrimary,
          icon: Icons.trending_down_rounded,
        ),
        SizedBox(height: 8),
        _AiDiagnosticTile(
          category: 'SCHEDULED VACCINE',
          title: 'Newcastle (ND-Lasota) Booster in 2 Days',
          subtitle:
              'Day 21 standard protocol. Water line sanitizer flush required.',
          color: _kAmber,
          icon: Icons.vaccines_rounded,
        ),
        SizedBox(height: 8),
        _AiDiagnosticTile(
          category: 'HARVEST TARGET',
          title: 'Average 2.30 kg Market Weight in 8 Days',
          subtitle:
              'Growth velocity is optimal (+62g/day). Ready for lifting schedule.',
          color: _kBlue,
          icon: Icons.scale_rounded,
        ),
        SizedBox(height: 8),
        _AiDiagnosticTile(
          category: 'FEED INVENTORY',
          title: 'Broiler Finisher Feed Stock: 5 Days Left',
          subtitle:
              'Reorder ~850 kg before Thursday to avoid growth rate drop.',
          color: _kRed,
          icon: Icons.inventory_2_outlined,
        ),
      ],
    );
  }
}

class _AiDiagnosticTile extends StatelessWidget {
  const _AiDiagnosticTile({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String category;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kSmRadius),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: _kCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kTextSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FACILITY & BIOSECURITY SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _FacilityOperationsSection extends StatelessWidget {
  const _FacilityOperationsSection({
    required this.todayMortality,
    required this.onDailyRecordsTap,
  });

  final int todayMortality;
  final VoidCallback onDailyRecordsTap;

  @override
  Widget build(BuildContext context) {
    final isSafe = todayMortality <= 2;
    final riskColor = isSafe ? _kPrimary : _kRed;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onDailyRecordsTap,
            borderRadius: BorderRadius.circular(_kSmRadius),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(_kSmRadius),
                border: Border.all(color: _kBorder, width: 1),
                boxShadow: _kCardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      color: riskColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Biosecurity Risk Status',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _kTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSafe ? _kGreenTint : _kRedTint,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isSafe ? 'LOW RISK' : 'ELEVATED',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: riskColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Telemetry normal • Safe disinfection & water sanitation active',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: _kTextMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const _DgFuelStatusCard(),
      ],
    );
  }
}

class _DgFuelStatusCard extends ConsumerWidget {
  const _DgFuelStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dgRecord = ref.watch(latestDgRecordProvider).value;
    final fuelLevel = dgRecord?.dgLevelLiters ?? 120.0;
    final genName = dgRecord?.dgName ?? 'Main Generator (25 kVA)';

    final double pct = (fuelLevel / 200.0).clamp(0.0, 1.0);
    final isLow = fuelLevel < 80.0;
    final statusColor = isLow
        ? (fuelLevel < 50.0 ? _kRed : _kAmber)
        : _kPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kSmRadius),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _kAmberTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.electric_bolt_rounded,
                  color: _kAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      genName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Automated Shed Power Backup • ~${(fuelLevel / 6.5).toStringAsFixed(1)} hrs run time',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${fuelLevel.toStringAsFixed(0)}L',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: _kBackground,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK OPERATIONS 4-TILE GRID
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onAddRecord,
    required this.onFeedInventory,
    required this.onVaccination,
    required this.onReports,
  });

  final VoidCallback onAddRecord;
  final VoidCallback onFeedInventory;
  final VoidCallback onVaccination;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: Icons.edit_note_rounded,
            label: 'Daily Log',
            color: _kPrimary,
            bg: _kGreenTint,
            onTap: onAddRecord,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.grass_rounded,
            label: 'Feed Stock',
            color: _kSky,
            bg: _kBlueTint,
            onTap: onFeedInventory,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.vaccines_rounded,
            label: 'Vaccine',
            color: _kAmber,
            bg: _kAmberTint,
            onTap: onVaccination,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.picture_as_pdf_rounded,
            label: 'Reports',
            color: _kIndigo,
            bg: _kIndigoTint,
            onTap: onReports,
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kSmRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(_kSmRadius),
            border: Border.all(color: _kBorder, width: 1),
            boxShadow: _kCardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE FARM CARD & OTHER FACILITIES
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveFarmCard extends StatelessWidget {
  const _ActiveFarmCard({required this.data, required this.onManageTap});

  final HomeDashboardData data;
  final VoidCallback onManageTap;

  @override
  Widget build(BuildContext context) {
    final farm =
        data.activeFarm ?? (data.farms.isNotEmpty ? data.farms.first : null);
    final farmName = farm?.farmName ?? 'Main Facility';
    final farmType = farm?.farmType ?? 'EC (Environment Controlled)';
    final location = farm?.address ?? 'Active Poultry Shed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: _kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: Color(0xFF4ADE80),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  farmName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$farmType • $location',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0x99FFFFFF),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onManageTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Text(
                'All Farms',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherFacilityCard extends StatelessWidget {
  const _OtherFacilityCard({
    required this.name,
    required this.type,
    required this.status,
    required this.address,
    required this.onTap,
  });

  final String name;
  final String type;
  final String status;
  final String address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kSmRadius),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(_kSmRadius),
            border: Border.all(color: _kBorder, width: 1),
            boxShadow: _kCardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: _kGreenTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warehouse_rounded,
                  color: _kPrimary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$type • $status',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: _kTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFarmCard extends StatelessWidget {
  const _EmptyFarmCard({required this.onCreateFarm});
  final VoidCallback onCreateFarm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: _kGreenTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_home_work_rounded,
              color: _kPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Configure First Poultry Facility',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your farm shed dimensions, automated ventilation specs, and bird capacity to unlock full analytics.',
            style: TextStyle(
              fontSize: 12.5,
              color: _kTextSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onCreateFarm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(_kSmRadius),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Setup Farm Facility',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _kTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: _kTextSecondary),
            ),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
