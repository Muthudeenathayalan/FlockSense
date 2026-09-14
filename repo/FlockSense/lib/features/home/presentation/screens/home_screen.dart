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
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
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
            ?.where((b) =>
                b.isActive &&
                (data.activeFarm == null || b.farmId == data.activeFarm!.id))
            .toList() ??
        const <BatchModel>[];

    final now = DateTime.now();
    final pendingBatches = activeBatches.where((b) {
      final hasRecordToday = data.recentRecords.any((r) =>
          r.batchId == b.id &&
          r.recordDate.year == now.year &&
          r.recordDate.month == now.month &&
          r.recordDate.day == now.day);
      return !hasRecordToday;
    }).toList();

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
            onFarmTap: () => _showFarmSwitcherBottomSheet(context, ref, data),
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
                  const SizedBox(height: 16),

                  // Real-Time Pending Daily Record Warning Banner
                  if (activeBatches.isNotEmpty && pendingBatches.isNotEmpty) ...[
                    _PendingDailyRecordBanner(
                      pendingBatches: pendingBatches,
                      onLogRecord: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyRecordsDashboardScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                        separatorBuilder: (c, i) => const SizedBox(width: 14),
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
                  _PerformanceAnalyticsPanel(
                    records: data.recentRecords,
                    batches: activeBatches,
                    liveBirds: data.liveBirds,
                    todayMortality: data.todayMortality,
                  ),
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
                                onTap: () async {
                                  await switchDashboardFarm(ref, farm.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Switched active facility to ${farm.farmName}',
                                            ),
                                          ],
                                        ),
                                        backgroundColor: _kPrimaryDark,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
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

void _showFarmSwitcherBottomSheet(
  BuildContext context,
  WidgetRef ref,
  HomeDashboardData data,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kGreenTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warehouse_rounded,
                    color: _kPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Switch Active Facility',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _kTextPrimary,
                        ),
                      ),
                      Text(
                        'Select which farm to monitor in Command Center',
                        style: TextStyle(fontSize: 12, color: _kTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: _kBorder),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: data.farms.length,
                separatorBuilder: (c, i) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final farm = data.farms[index];
                  final isSelected = farm.id == data.activeFarm?.id;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await switchDashboardFarm(ref, farm.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text('Active facility: ${farm.farmName}'),
                              ],
                            ),
                            backgroundColor: _kPrimaryDark,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _kGreenTint.withValues(alpha: 0.5)
                            : _kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _kPrimary : _kBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected ? _kPrimary : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      farm.farmName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: _kTextPrimary,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _kPrimary,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${farm.farmType} • ${farm.totalSqFt.toStringAsFixed(0)} sq ft • ${farm.address.isNotEmpty ? farm.address : 'Operational'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: _kBorder),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kTextPrimary,
                      side: const BorderSide(color: _kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, AppRoutes.farms);
                    },
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text(
                      'All Facilities',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, AppRoutes.farmSetup);
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Add Facility',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
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
// 4-TAB PERFORMANCE ANALYTICS (Driven Entirely by User Telemetry)
// ─────────────────────────────────────────────────────────────────────────────
class _Chart7DayData {
  final List<String> dayNames;
  final List<DateTime> dates;
  final List<double> feedKg;
  final List<double> fcr;
  final List<double> mortality;
  final List<double> population;
  final List<double> revenue;
  final double totalFeedKg;
  final double totalMortality;
  final double avgFcr;
  final bool hasAnyData;

  const _Chart7DayData({
    required this.dayNames,
    required this.dates,
    required this.feedKg,
    required this.fcr,
    required this.mortality,
    required this.population,
    required this.revenue,
    required this.totalFeedKg,
    required this.totalMortality,
    required this.avgFcr,
    required this.hasAnyData,
  });

  factory _Chart7DayData.compute(
    List<DailyRecordModel> records,
    List<BatchModel> batches,
  ) {
    final now = DateTime.now();
    final dayNames = <String>[];
    final dates = <DateTime>[];
    final feedKg = <double>[];
    final fcr = <double>[];
    final mortality = <double>[];
    final population = <double>[];
    final revenue = <double>[];

    final initialBirds = batches.fold<int>(0, (sum, b) => sum + b.totalBirds);
    final currentLiveBirds =
        batches.fold<int>(0, (sum, b) => sum + b.currentBirds);
    final runningBirds = currentLiveBirds > 0
        ? currentLiveBirds.toDouble()
        : (initialBirds > 0 ? initialBirds.toDouble() : 0.0);

    final hasAnyData = records.isNotEmpty || batches.isNotEmpty;

    for (var i = 6; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      dates.add(date);
      dayNames.add(DateFormat('E').format(date));

      final dayRecords = records
          .where(
            (r) =>
                r.recordDate.year == date.year &&
                r.recordDate.month == date.month &&
                r.recordDate.day == date.day,
          )
          .toList();

      final dayFeed = dayRecords.fold<double>(
        0.0,
        (sum, r) => sum + r.feedConsumedKg,
      );
      final dayMort = dayRecords.fold<double>(
        0.0,
        (sum, r) => sum + r.mortalityCount,
      );
      final validWeights = dayRecords
          .where((r) => r.avgWeightGrams > 0)
          .map((r) => r.avgWeightGrams)
          .toList();
      final dayWeight = validWeights.isNotEmpty
          ? (validWeights.reduce((a, b) => a + b) / validWeights.length)
          : 0.0;

      feedKg.add(dayFeed);
      mortality.add(dayMort);

      final weightKg = dayWeight > 0 ? (dayWeight / 1000.0) : 0.0;
      final dayFcr = (dayFeed > 0 && weightKg > 0 && runningBirds > 0)
          ? (dayFeed / (weightKg * runningBirds)).clamp(0.8, 3.5)
          : 0.0;
      fcr.add(dayFcr);

      final dayRevLakhs =
          (runningBirds * (weightKg > 0 ? weightKg : 1.5) * 120.0) / 100000.0;
      revenue.add(dayRevLakhs);
      population.add(runningBirds);
    }

    final totalFeed = feedKg.fold<double>(0.0, (sum, v) => sum + v);
    final totalMort = mortality.fold<double>(0.0, (sum, v) => sum + v);
    final nonZeroFcrs = fcr.where((v) => v > 0).toList();
    final avgFcrVal = nonZeroFcrs.isNotEmpty
        ? (nonZeroFcrs.reduce((a, b) => a + b) / nonZeroFcrs.length)
        : 0.0;

    return _Chart7DayData(
      dayNames: dayNames,
      dates: dates,
      feedKg: feedKg,
      fcr: fcr,
      mortality: mortality,
      population: population,
      revenue: revenue,
      totalFeedKg: totalFeed,
      totalMortality: totalMort,
      avgFcr: avgFcrVal,
      hasAnyData: hasAnyData,
    );
  }
}

class _ChartEmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;

  const _ChartEmptyPlaceholder({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: _kBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _kTextMuted, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kTextSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _dynamicDayTitle(double v, List<String> dayNames) {
  final i = v.toInt();
  if (i < 0 || i >= dayNames.length) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      dayNames[i],
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: _kTextMuted,
      ),
    ),
  );
}

class _PendingDailyRecordBanner extends StatelessWidget {
  final List<BatchModel> pendingBatches;
  final VoidCallback onLogRecord;

  const _PendingDailyRecordBanner({
    required this.pendingBatches,
    required this.onLogRecord,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingBatches.isEmpty) return const SizedBox.shrink();

    final batchNames = pendingBatches.map((b) => b.batchName).join(', ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Daily Record Pending",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "No daily log entered today for: $batchNames",
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFB91C1C),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: onLogRecord,
            child: const Text(
              'Log Now',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceAnalyticsPanel extends StatefulWidget {
  final List<DailyRecordModel> records;
  final List<BatchModel> batches;
  final int liveBirds;
  final int todayMortality;

  const _PerformanceAnalyticsPanel({
    this.records = const [],
    this.batches = const [],
    this.liveBirds = 0,
    this.todayMortality = 0,
  });

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

  @override
  Widget build(BuildContext context) {
    final chartData = _Chart7DayData.compute(widget.records, widget.batches);

    final survivalPct =
        (widget.batches.isNotEmpty && widget.batches.first.totalBirds > 0)
            ? ((widget.liveBirds / widget.batches.first.totalBirds) * 100)
                .toStringAsFixed(1)
            : '100.0';

    final tabSummaries = [
      widget.liveBirds > 0
          ? 'Live Birds: ${NumberFormat.decimalPattern().format(widget.liveBirds)} ($survivalPct% survival rate)'
          : 'No active flock population logged yet',
      chartData.totalFeedKg > 0
          ? '7-Day Feed: ${chartData.totalFeedKg.toStringAsFixed(1)} kg • Avg FCR: ${chartData.avgFcr > 0 ? chartData.avgFcr.toStringAsFixed(2) : "Tracking"}'
          : 'Log daily feed intake to track 7-day FCR trends',
      chartData.totalMortality > 0 || widget.todayMortality > 0
          ? '7-Day Loss: ${chartData.totalMortality.toInt()} birds • Today: ${widget.todayMortality} mortality'
          : 'Zero mortality recorded in the last 7 days',
      widget.liveBirds > 0
          ? 'Active Flock Size: ${widget.liveBirds} birds • Valuation derived from daily weights'
          : 'Create a batch to project 42-day harvest valuation',
    ];

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
                    tabSummaries[_selectedTab],
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
                  _PopulationChart(
                    key: const ValueKey(0),
                    data: chartData,
                  ),
                  _FeedEfficiencyChart(
                    key: const ValueKey(1),
                    data: chartData,
                  ),
                  _MortalityChart(
                    key: const ValueKey(2),
                    data: chartData,
                  ),
                  _RevenueChart(
                    key: const ValueKey(3),
                    data: chartData,
                  ),
                ][_selectedTab],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

FlGridData _cleanGrid() => FlGridData(
  show: true,
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) => FlLine(color: _kBorderLight, strokeWidth: 1),
);

class _PopulationChart extends StatelessWidget {
  final _Chart7DayData data;
  const _PopulationChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (!data.hasAnyData || data.population.every((p) => p <= 0)) {
      return const _ChartEmptyPlaceholder(
        icon: Icons.people_alt_rounded,
        message: 'No active flock population data logged yet',
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), data.population[i]));
    }

    final minPop = data.population.reduce(math.min);
    final maxPop = data.population.reduce(math.max);
    final minY = (minPop * 0.95).floorToDouble();
    final maxY = ((maxPop * 1.05) + 5).ceilToDouble();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY > minY ? maxY : minY + 10,
        lineBarsData: [
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
              getTitlesWidget: (v, meta) => _dynamicDayTitle(v, data.dayNames),
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
  final _Chart7DayData data;
  const _FeedEfficiencyChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final hasFeed = data.feedKg.any((f) => f > 0);
    if (!data.hasAnyData || !hasFeed) {
      return const _ChartEmptyPlaceholder(
        icon: Icons.grass_rounded,
        message:
            'No feed consumption logged in the past 7 days.\nLog daily records to view feed intake & FCR.',
      );
    }

    final feedSpots = List<FlSpot>.generate(
      7,
      (i) => FlSpot(i.toDouble(), data.feedKg[i]),
    );

    final maxFeed = data.feedKg.reduce(math.max);
    final maxY = maxFeed > 0 ? (maxFeed * 1.2) : 10.0;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: feedSpots,
            isCurved: true,
            color: _kSky,
            barWidth: 2.2,
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
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, meta) => _dynamicDayTitle(v, data.dayNames),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (v, _) => Text(
                '${v.toStringAsFixed(0)} kg',
                style: const TextStyle(
                  fontSize: 9,
                  color: _kTextMuted,
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
  final _Chart7DayData data;
  const _MortalityChart({super.key, required this.data});

  static Color _barColor(double v) {
    if (v == 0) return _kPrimary;
    if (v <= 2) return _kAmber;
    return _kRed;
  }

  @override
  Widget build(BuildContext context) {
    final maxMort =
        data.mortality.isNotEmpty ? data.mortality.reduce(math.max) : 0.0;
    final maxY = (maxMort + 2).clamp(5.0, 10000.0);

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: List.generate(
          7,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data.mortality[i] == 0 ? 0.20 : data.mortality[i],
                color: _barColor(data.mortality[i]),
                width: 26,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
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
              getTitlesWidget: (v, meta) => _dynamicDayTitle(v, data.dayNames),
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
  final _Chart7DayData data;
  const _RevenueChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final hasRev = data.revenue.any((r) => r > 0);
    if (!data.hasAnyData || !hasRev) {
      return const _ChartEmptyPlaceholder(
        icon: Icons.insights_rounded,
        message:
            'No flock valuation data available.\nLog bird weights and sales to view financial telemetry.',
      );
    }

    final revSpots = List<FlSpot>.generate(
      7,
      (i) => FlSpot(i.toDouble(), data.revenue[i]),
    );

    final maxRev = data.revenue.reduce(math.max);
    final maxY = maxRev > 0 ? (maxRev * 1.25) : 5.0;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: revSpots,
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
              getTitlesWidget: (v, meta) => _dynamicDayTitle(v, data.dayNames),
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
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
        ?trailing,
      ],
    );
  }
}
