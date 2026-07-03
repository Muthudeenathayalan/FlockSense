import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Future<Map<String, dynamic>> _dashboardDataFuture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dashboardDataFuture = _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isRefreshing) {
      debugPrint('[HomeScreen] App resumed, refreshing dashboard data');
      _refreshDashboard();
    }
  }

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FarmService.getUserFarms(forceRefresh: true);
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error refreshing farms: $e');
    }

    setState(() {
      _dashboardDataFuture = _loadDashboardData();
    });

    _isRefreshing = false;
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'totalFarms': 0,
          'totalFarmArea': 0.0,
          'activeBatchCount': 0,
          'liveBirdCount': 0,
          'activeFarmName': null,
          'farms': <FarmModel>[],
        };
      }

      final farmsFuture = FarmService.getUserFarms();
      final farmAreaFuture = FarmService.getUserFarmArea(user.uid);
      final userDocFuture = FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final batchCountFuture = BatchService.getUserActiveBatchCount(user.uid);
      final liveBirdsFuture = BatchService.getUserLiveBirdCount(user.uid);

      final results = await Future.wait([farmsFuture, farmAreaFuture, userDocFuture, batchCountFuture, liveBirdsFuture]);
      final farms = results[0] as List<FarmModel>;
      final totalFarmArea = results[1] as double;
      final userDoc = results[2] as DocumentSnapshot<Map<String, dynamic>>;
      final activeBatchCount = results[3] as int;
      final liveBirdCount = results[4] as int;

      String? activeFarmName;
      if (userDoc.exists) {
        final activeFarmId = userDoc.data()?['activeFarmId'] as String?;
        if (activeFarmId != null) {
          final activeFarm = farms.firstWhere(
            (farm) => farm.id == activeFarmId,
            orElse: () => FarmModel(
              id: '',
              userId: user.uid,
              farmName: 'Unknown Farm',
              farmType: '',
              flockType: '',
              address: '',
              lengthFt: 0.0,
              widthFt: 0.0,
              totalSqFt: 0.0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          if (activeFarm.id.isNotEmpty) {
            activeFarmName = activeFarm.farmName;
          }
        }
      }

      return {
        'totalFarms': farms.length,
        'totalFarmArea': totalFarmArea,
        'activeBatchCount': activeBatchCount,
        'liveBirdCount': liveBirdCount,
        'activeFarmName': activeFarmName,
        'farms': farms,
      };
    } catch (e) {
      debugPrint('[HomeScreen] Error loading dashboard data: $e');
      return {
        'totalFarms': 0,
        'totalFarmArea': 0.0,
        'activeBatchCount': 0,
        'liveBirdCount': 0,
        'activeFarmName': null,
        'farms': <FarmModel>[],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070D0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('FlockSense'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _dashboardDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: Color(0xFF6EE7B7)),
                      SizedBox(height: 18),
                      Text(
                        'Loading command center...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data ?? {};
              final totalFarms = data['totalFarms'] as int? ?? 0;
              final totalFarmArea = data['totalFarmArea'] as double? ?? 0.0;
              final activeBatchCount = data['activeBatchCount'] as int? ?? 0;
              final liveBirdCount = data['liveBirdCount'] as int? ?? 0;
              final activeFarmName = data['activeFarmName'] as String?;
              final selectedFarmName = activeFarmName ?? 'All Farms';
              final locationText = activeFarmName != null ? 'Selected farm in use' : 'No farm selected';

              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DashboardHeader(
                      subtitle: 'Command Center',
                      onRefresh: _refreshDashboard,
                      onNotifications: () {},
                    ),
                    const SizedBox(height: 24),
                    _DashboardFailureState(onRetry: _refreshDashboard),
                  ],
                );
              }

              if (totalFarms == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DashboardHeader(
                      subtitle: 'Command Center',
                      onRefresh: _refreshDashboard,
                      onNotifications: () {},
                    ),
                    const SizedBox(height: 24),
                    _EmptyDashboardState(onCreateFarm: () {
                      Navigator.pushNamed(context, AppRoutes.farmSetup);
                    }),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeader(
                    subtitle: 'Command Center',
                    onRefresh: _refreshDashboard,
                    onNotifications: () {},
                  ),
                  const SizedBox(height: 24),
                  _FarmOverviewHero(
                    activeFarmName: selectedFarmName,
                    locationText: locationText,
                    totalFarms: totalFarms,
                    totalFarmArea: totalFarmArea,
                    activeBatches: activeBatchCount,
                    liveBirds: liveBirdCount,
                  ),
                  const SizedBox(height: 24),
                  _DashboardGrid(totalFarmArea: totalFarmArea, liveBirds: liveBirdCount),
                  const SizedBox(height: 24),
                  const _PriorityActionsCard(),
                  const SizedBox(height: 24),
                  _BatchPerformanceCard(
                    activeBatches: activeBatchCount,
                    liveBirds: liveBirdCount,
                  ),
                  const SizedBox(height: 24),
                  const _RecentActivityCard(),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.subtitle,
    required this.onRefresh,
    required this.onNotifications,
  });

  final String subtitle;
  final VoidCallback onRefresh;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FlockSense',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.green.shade200,
                  fontSize: 16,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: 'Refresh',
        ),
        IconButton(
          onPressed: onNotifications,
          icon: const Icon(Icons.notifications_none, color: Colors.white70),
          tooltip: 'Notifications',
        ),
      ],
    );
  }
}

class _FarmOverviewHero extends StatelessWidget {
  const _FarmOverviewHero({
    required this.activeFarmName,
    required this.locationText,
    required this.totalFarms,
    required this.totalFarmArea,
    required this.activeBatches,
    required this.liveBirds,
  });

  final String activeFarmName;
  final String locationText;
  final int totalFarms;
  final double totalFarmArea;
  final int activeBatches;
  final int liveBirds;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1F16), Color(0xFF09100D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Farm Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeFarmName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _OverviewStatRow(
                      totalFarms: totalFarms,
                      totalFarmArea: totalFarmArea,
                      activeBatches: activeBatches,
                      liveBirds: liveBirds,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF6EE7B7), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locationText,
                            style: const TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const _HealthScoreRing(score: 92),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _MiniStatItem(
                icon: Icons.health_and_safety,
                label: 'Mortality Today',
                value: '0.00%',
                accent: Color(0xFF6EE7B7),
              ),
              _MiniStatItem(
                icon: Icons.monitor_weight,
                label: 'Avg Weight',
                value: '0.00 kg',
                accent: Color(0xFF34D399),
              ),
              _MiniStatItem(
                icon: Icons.show_chart,
                label: 'FCR',
                value: '0.00',
                accent: Color(0xFF4ADE80),
              ),
              _MiniStatItem(
                icon: Icons.thermostat_outlined,
                label: 'Temperature',
                value: 'Normal',
                accent: Color(0xFF86EFAC),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthScoreRing extends StatelessWidget {
  const _HealthScoreRing({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF68D391), Color(0xFF0B120F)],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '/100',
              style: TextStyle(color: Colors.green.shade100, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatItem extends StatelessWidget {
  const _MiniStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStatRow extends StatelessWidget {
  const _OverviewStatRow({
    required this.totalFarms,
    required this.totalFarmArea,
    required this.activeBatches,
    required this.liveBirds,
  });

  final int totalFarms;
  final double totalFarmArea;
  final int activeBatches;
  final int liveBirds;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _OverviewValue(label: 'Farms', value: totalFarms.toString()),
            const SizedBox(width: 12),
            _OverviewValue(label: 'Area', value: '${totalFarmArea.toStringAsFixed(0)} ft²'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _OverviewValue(label: 'Batches', value: activeBatches.toString()),
            const SizedBox(width: 12),
            _OverviewValue(label: 'Live birds', value: liveBirds.toString()),
          ],
        ),
      ],
    );
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF121F17),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.totalFarmArea, required this.liveBirds});

  final double totalFarmArea;
  final int liveBirds;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _PremiumDashboardCard(
        title: 'Alerts',
        value: '3 New',
        icon: Icons.warning_amber_rounded,
        accent: const Color(0xFFEC4899),
        subtitle: 'Review high priority alerts',
      ),
      _PremiumDashboardCard(
        title: 'Vaccination',
        value: '2 Scheduled',
        icon: Icons.medical_information,
        accent: const Color(0xFFF59E0B),
        subtitle: 'Keep flock immunized',
      ),
      _PremiumDashboardCard(
        title: 'Feed Inventory',
        value: '0 kg',
        icon: Icons.spa,
        accent: const Color(0xFF10B981),
        subtitle: 'Record feed stock levels',
      ),
      _PremiumDashboardCard(
        title: 'Water Usage',
        value: '0 L',
        icon: Icons.water_drop,
        accent: const Color(0xFF38BDF8),
        subtitle: 'Monitor daily water',
      ),
      _PremiumDashboardCard(
        title: 'Farm Area',
        value: '${totalFarmArea.toStringAsFixed(0)} ft²',
        icon: Icons.terrain,
        accent: const Color(0xFF22C55E),
        subtitle: 'Total operational area',
      ),
      _PremiumDashboardCard(
        title: 'Environment',
        value: 'Normal',
        icon: Icons.thermostat,
        accent: const Color(0xFF4ADE80),
        subtitle: 'Stable temperature',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.05,
      children: cards,
    );
  }
}

class _PremiumDashboardCard extends StatelessWidget {
  const _PremiumDashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    required this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B13),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PriorityActionsCard extends StatelessWidget {
  const _PriorityActionsCard();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionChipData(label: 'Check temperature', color: const Color(0xFFEF4444)),
      _ActionChipData(label: 'Refill water', color: const Color(0xFFF97316)),
      _ActionChipData(label: 'Vaccinate batch', color: const Color(0xFF22C55E)),
      _ActionChipData(label: 'Litter management', color: const Color(0xFF4ADE80)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F14),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Priority Actions Today',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Action items to keep farm operations running smoothly.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions
                .map(
                  (action) => ActionChip(
                    backgroundColor: action.color.withOpacity(0.18),
                    label: Text(action.label, style: TextStyle(color: action.color, fontWeight: FontWeight.w600)),
                    onPressed: () {},
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionChipData {
  const _ActionChipData({required this.label, required this.color});

  final String label;
  final Color color;
}

class _BatchPerformanceCard extends StatelessWidget {
  const _BatchPerformanceCard({
    required this.activeBatches,
    required this.liveBirds,
  });

  final int activeBatches;
  final int liveBirds;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F14),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Batch Performance',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: const Text('Live', style: TextStyle(color: Colors.greenAccent)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _PerformanceMetric(label: 'Active batches', value: activeBatches.toString())),
              const SizedBox(width: 12),
              Expanded(child: _PerformanceMetric(label: 'Live birds', value: liveBirds.toString())),
            ],
          ),
          const SizedBox(height: 18),
          const _PerformanceMetric(label: 'Avg weight', value: '0.00 kg'),
          const SizedBox(height: 14),
          const _PerformanceMetric(label: 'Mortality', value: '0.00%'),
          const SizedBox(height: 14),
          const _PerformanceMetric(label: 'FCR', value: '0.00'),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: _PerformanceBar(label: 'Batch health', score: 0.84)),
              SizedBox(width: 10),
              Expanded(child: _PerformanceBar(label: 'Feed use', score: 0.62)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  const _PerformanceMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _PerformanceBar extends StatelessWidget {
  const _PerformanceBar({required this.label, required this.score});

  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: score,
            minHeight: 10,
            backgroundColor: Colors.white12,
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(height: 6),
        Text('${(score * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    const activities = [
      _ActivityData(title: 'Farm created', description: 'A new farm profile was added.'),
      _ActivityData(title: 'Shed added', description: 'A shed was prepared for incoming flock.'),
      _ActivityData(title: 'Batch placed', description: 'A new placement batch is live.'),
      _ActivityData(title: 'Daily record pending', description: 'Log today’s farm observations.'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F14),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ...activities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.history, color: Colors.greenAccent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(activity.description, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
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

class _ActivityData {
  const _ActivityData({required this.title, required this.description});

  final String title;
  final String description;
}

class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState({required this.onCreateFarm});

  final VoidCallback onCreateFarm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F14),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Start your first farm',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create a farm to unlock shed, batch, and daily tracking.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 26),
          FilledButton(
            onPressed: onCreateFarm,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Create Farm'),
          ),
        ],
      ),
    );
  }
}

class _DashboardFailureState extends StatelessWidget {
  const _DashboardFailureState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F14),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Dashboard data is not available right now.',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          const Text(
            'We are unable to load real-time farm metrics. Please try again or continue working offline.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Retry Dashboard'),
          ),
        ],
      ),
    );
  }
}
