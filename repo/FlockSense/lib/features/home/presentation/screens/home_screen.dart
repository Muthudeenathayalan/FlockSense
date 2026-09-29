import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/home/presentation/widgets/home_action_plan_button.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_tokens.dart';
import 'package:flock_sense/features/home/presentation/widgets/home_active_batches_section.dart';
import 'package:flock_sense/features/home/presentation/widgets/home_active_farm_card.dart';
import 'package:flock_sense/features/home/presentation/widgets/home_ai_diagnostics_section.dart';
import 'package:flock_sense/features/home/presentation/widgets/home_command_header.dart';
import 'package:flock_sense/features/home/presentation/widgets/home_kpi_grid.dart';
import 'package:flock_sense/features/home/presentation/widgets/home_performance_analytics_panel.dart';
import 'package:flock_sense/features/home/presentation/widgets/home_quick_actions_grid.dart';
import 'package:flock_sense/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sheds/presentation/screens/shed_form_screen.dart';

/// Aligned, modular Home Dashboard coordinator screen.
/// Assembles dedicated sub-widgets adhering to Clean Architecture and strict spatial tokens.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(homeDashboardDataProvider);
    final data = dashboardData.value ?? HomeDashboardData.empty;

    final user = ref.watch(authStateProvider).maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );
    final displayName = user?.displayName?.trim();

    final activeBatches = ref
            .watch(allUserBatchesProvider)
            .value
            ?.where((b) =>
                b.isActive &&
                (data.activeFarm == null || b.farmId == data.activeFarm!.id))
            .toList() ??
        const <BatchModel>[];

    final targetFarmId = data.activeFarm?.id ??
        (data.farms.isNotEmpty ? data.farms.first.id : '');

    void navigateToAddBatch() async {
      if (targetFarmId.isNotEmpty) {
        final sheds = await ShedService.getShedsByFarmId(targetFarmId);
        if (!context.mounted) return;
        if (sheds.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Please create a shed first before creating a batch.',
              ),
              action: SnackBarAction(
                label: 'Add Shed',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShedFormScreen(
                        farmId: targetFarmId,
                        farm: data.activeFarm,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
          return;
        }
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

    try {
      return Scaffold(
        backgroundColor: HomeTokens.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // 1. Top Header Banner with Integrated Facility Switcher & Live Telemetry
            HomeCommandHeader(
              displayName: displayName,
              data: data,
              onNotificationTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationCenterScreen(),
                ),
              ),
            ),

            // 2. Aligned Content Body
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  HomeTokens.screenGutter,
                  14,
                  HomeTokens.screenGutter,
                  88,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Action Plan Button (when active flock exists) - Simple, neat compact pill
                    if (activeBatches.isNotEmpty) ...[
                      HomeActionPlanButton(
                        batch: activeBatches.first,
                        farmId: targetFarmId,
                        farmName: data.activeFarm?.farmName ?? 'Main Facility',
                      ),
                      const SizedBox(height: 10),
                    ],

                    // 2x2 Executive KPIs with locked baseline alignment
                    HomeKpiGrid(data: data),
                    const SizedBox(height: HomeTokens.gapSection),

                    // Active Batches Carousel
                    HomeActiveBatchesSection(
                      activeBatches: activeBatches,
                      recentRecords: data.recentRecords,
                      onAddBatch: navigateToAddBatch,
                    ),
                    const SizedBox(height: HomeTokens.gapSection),

                    // Segmented Telemetry Analytics Charts (Locked Y-axis width)
                    HomePerformanceAnalyticsPanel(
                      data: data,
                      onAddBatch: navigateToAddBatch,
                    ),
                    const SizedBox(height: HomeTokens.gapSection),

                    // Real-time AI Biosecurity & Telemetry Diagnostics
                    HomeAiDiagnosticsSection(data: data),
                    const SizedBox(height: HomeTokens.gapSection),

                    // Quick Operations Grid
                    HomeQuickActionsGrid(activeBatches: activeBatches),
                    const SizedBox(height: HomeTokens.gapSection),

                    // Active Facility Specs Card
                    HomeActiveFarmCard(data: data),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      debugPrint('[HomeScreen] Critical build error caught: $e\n$stack');
      return Scaffold(
        backgroundColor: HomeTokens.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: HomeTokens.greenTint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/flocksense_app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'FlockSense Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: HomeTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Preparing your farm workspace...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: HomeTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(homeDashboardDataProvider);
                      ref.invalidate(farmListProvider);
                      ref.invalidate(allUserBatchesProvider);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomeTokens.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 42),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
