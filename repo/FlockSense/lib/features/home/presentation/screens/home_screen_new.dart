import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_command_center_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<_HomeData> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _HomeData.empty;

    final farms = await FarmService.getUserFarms(forceRefresh: true);
    final totalFarmArea = await FarmService.getUserFarmArea(user.uid);
    final activeBatchCount = await BatchService.getUserActiveBatchCount(
      user.uid,
    );
    final liveBirds = await BatchService.getUserLiveBirdCount(user.uid);
    final todayMortality = await DailyRecordService.getTodayMortalityCount(
      user.uid,
    );

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final activeFarmId = userDoc.data()?['activeFarmId'] as String?;

    FarmModel? activeFarm;
    if (activeFarmId != null) {
      for (final farm in farms) {
        if (farm.id == activeFarmId) {
          activeFarm = farm;
          break;
        }
      }
    }

    return _HomeData(
      farms: farms,
      activeFarm: activeFarm,
      activeBatchCount: activeBatchCount,
      totalFarmArea: totalFarmArea,
      liveBirds: liveBirds,
      todayMortality: todayMortality,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
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
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? _HomeData.empty;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
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
                  actions: [
                    IconButton(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                    ),
                  ],
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
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.farmSetup,
                              ),
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
                            onCreateFarm: () => Navigator.pushNamed(
                              context,
                              AppRoutes.farmSetup,
                            ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.activeFarm?.farmName ??
                                            'Active Farm',
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  '${farm.farmType} • ${farm.status}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppColors.textSecondary,
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
          );
        },
      ),
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.farms,
    required this.activeFarm,
    required this.activeBatchCount,
    required this.totalFarmArea,
    required this.liveBirds,
    required this.todayMortality,
  });

  final List<FarmModel> farms;
  final FarmModel? activeFarm;
  final int activeBatchCount;
  final double totalFarmArea;
  final int liveBirds;
  final int todayMortality;

  static const empty = _HomeData(
    farms: <FarmModel>[],
    activeFarm: null,
    activeBatchCount: 0,
    totalFarmArea: 0,
    liveBirds: 0,
    todayMortality: 0,
  );
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
