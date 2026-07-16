import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(homeDashboardDataProvider);
    final user = ref
        .watch(authStateProvider)
        .maybeWhen(data: (user) => user, orElse: () => null);
    final displayName = user?.displayName?.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: dashboardData.when(
        data: (data) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 210,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              titleTextStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppDesign.headerGreenGradient,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x1AFFFFFF),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -10,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x12FFFFFF),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName == null || displayName.isEmpty
                                  ? 'Command Center'
                                  : 'Good morning',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xCCFFFFFF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayName == null || displayName.isEmpty
                                  ? 'FlockSense'
                                  : displayName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AppDesign.statusChip(
                              data.farms.isEmpty
                                  ? 'Start your first farm'
                                  : '${data.farms.length} farms active',
                              const Color(0x26FFFFFF),
                              textColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.28,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _GradientStatTile(
                          label: 'Farms',
                          value: data.farms.length.toString(),
                          icon: Icons.agriculture_rounded,
                          gradient: AppDesign.actionGreen,
                        ),
                        _GradientStatTile(
                          label: 'Active Batches',
                          value: data.activeBatchCount.toString(),
                          icon: Icons.pets_rounded,
                          gradient: AppDesign.actionTeal,
                        ),
                        _GradientStatTile(
                          label: 'Live Birds',
                          value: data.liveBirds.toString(),
                          icon: Icons.groups_rounded,
                          gradient: AppDesign.actionGold,
                        ),
                        _GradientStatTile(
                          label: 'Mortality',
                          value: data.todayMortality.toString(),
                          icon: Icons.health_and_safety_outlined,
                          gradient: AppDesign.actionBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppDesign.sectionTitle('Quick Actions'),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                      children: [
                        AppDesign.actionButton(
                          icon: Icons.add_business_rounded,
                          label: 'New Farm',
                          gradient: AppDesign.actionGreen,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.farmSetup),
                        ),
                        AppDesign.actionButton(
                          icon: Icons.home_work_rounded,
                          label: 'My Farms',
                          gradient: AppDesign.actionTeal,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.farms),
                        ),
                        AppDesign.actionButton(
                          icon: Icons.calendar_today_rounded,
                          label: 'Records',
                          gradient: AppDesign.actionGold,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.main),
                        ),
                        AppDesign.actionButton(
                          icon: Icons.picture_as_pdf_rounded,
                          label: 'Reports',
                          gradient: AppDesign.actionBlue,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.main),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (data.farms.isEmpty)
                      _EmptyStartCard(
                        onCreateFarm: () =>
                            Navigator.pushNamed(context, AppRoutes.farmSetup),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppDesign.gradientDecoration(
                          AppDesign.headerGreenGradient,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0x26FFFFFF),
                              ),
                              child: const Icon(
                                Icons.home_work_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.activeFarm?.farmName ?? 'Active Farm',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data.activeFarm?.address ??
                                        'Open the farm command center',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xCCFFFFFF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (data.farms.length > 1) ...[
                        AppDesign.sectionTitle('Other Farms'),
                        ...data.farms
                            .where((farm) => farm.id != data.activeFarm?.id)
                            .map(
                              (farm) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: AppDesign.cardDecoration,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          gradient: AppDesign.actionTeal,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.agriculture_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              farm.farmName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${farm.farmType} • ${farm.status}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 52,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Unable to load dashboard right now.',
                  style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => ref.refresh(homeDashboardDataProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
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

class _EmptyStartCard extends StatelessWidget {
  const _EmptyStartCard({required this.onCreateFarm});

  final VoidCallback onCreateFarm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDesign.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppDesign.actionGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.add_home_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Start your first farm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a farm to unlock batches, daily records, and reports.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: onCreateFarm,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppDesign.actionGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Create Farm',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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

class _GradientStatTile extends StatelessWidget {
  const _GradientStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x26FFFFFF),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xCCFFFFFF)),
          ),
        ],
      ),
    );
  }
}
