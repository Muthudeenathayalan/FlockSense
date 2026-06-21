import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flock_sense/core/widgets/dashboard_card.dart';
import 'package:flock_sense/core/widgets/section_header.dart';
import 'package:flock_sense/core/widgets/action_tile.dart';
import 'package:flock_sense/core/widgets/empty_state_widget.dart';
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
    
    // Force refresh by invalidating cache
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
        throw Exception('User not authenticated');
      }

      // Fetch all farms for the user
      final farms = await FarmService.getUserFarms();

      // Calculate total capacity
      int totalCapacity = 0;
      for (final farm in farms) {
        totalCapacity += farm.birdCapacity;
      }

      // Get active farm name
      String? activeFarmName;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final activeFarmId = userDoc.get('activeFarmId') as String?;
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
                birdCapacity: 0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            activeFarmName = activeFarm.id.isNotEmpty ? activeFarm.farmName : null;
          }
        }
      } catch (e) {
        debugPrint('[HomeScreen] Error fetching active farm: $e');
      }

      return {
        'totalFarms': farms.length,
        'totalCapacity': totalCapacity,
        'activeFarmName': activeFarmName,
        'farms': farms,
      };
    } catch (e) {
      debugPrint('[HomeScreen] Error loading dashboard data: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Farmer';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
            tooltip: 'Refresh farms',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _dashboardDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Loading your dashboard...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading dashboard',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please try again later',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _refreshDashboard,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final data = snapshot.data ?? {};
              final totalFarms = data['totalFarms'] as int? ?? 0;
              final totalCapacity = data['totalCapacity'] as int? ?? 0;
              final activeFarmName = data['activeFarmName'] as String?;

              // Show empty state if no farms
              if (totalFarms == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, userName: displayName),
                    const SizedBox(height: 32),
                    Center(
                      child: EmptyStateWidget(
                        title: 'No farms yet',
                        message: 'Start by creating your first farm to begin managing your poultry operations.',
                        buttonLabel: 'Create Farm',
                        onButtonPressed: () {
                          // Navigate to farm creation
                        },
                        icon: Icons.agriculture,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, userName: displayName, activeFarmName: activeFarmName),
                  const SizedBox(height: 24),
                  _buildOverviewCards(context, totalFarms, totalCapacity),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Quick actions',
                    subtitle: 'Instant farm workflows at your fingertips.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ActionTile(icon: Icons.agriculture, label: 'Active Farms', onTap: () {}),
                      ActionTile(icon: Icons.timeline, label: 'Batches', onTap: () {}),
                      ActionTile(icon: Icons.insights, label: 'Health', onTap: () {}),
                      ActionTile(icon: Icons.cloud, label: 'Weather', onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'AI recommendation',
                    subtitle: 'Suggested actions to keep your flock thriving.',
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Feed schedule optimization', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text('Adjust the feed ratio for broiler farms to improve growth and reduce waste.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              FilledButton(onPressed: () {}, child: const Text('View suggestions')),
                              const SizedBox(width: 12),
                              OutlinedButton(onPressed: () {}, child: const Text('Dismiss')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Recent activity',
                    subtitle: 'Latest farm events and alerts.',
                  ),
                  const SizedBox(height: 16),
                  _buildActivityItem(context, 'Batch A2 updated', 'Feed schedule changed for Broiler farm.'),
                  _buildActivityItem(context, 'Biosecurity check', 'New hygiene checklist created.'),
                  _buildActivityItem(context, 'Stock delivery', 'Feed order has arrived at farm gate.'),
                  const SizedBox(height: 24),
                  EmptyStateWidget(
                    title: 'You\'re all caught up',
                    message: 'No urgent tasks for today. Check back later for new recommendations.',
                    buttonLabel: 'Refresh dashboard',
                    onButtonPressed: () {
                      setState(() {
                        _dashboardDataFuture = _loadDashboardData();
                      });
                    },
                    icon: Icons.check_circle_outline,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required String userName, String? activeFarmName}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Good morning', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
            const SizedBox(height: 8),
            Text(
              userName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (activeFarmName != null) ...[
              Text(
                'Active farm: $activeFarmName',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Your farms are looking healthy today. Keep an eye on tasks and recommendations.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, int totalFarms, int totalCapacity) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        DashboardCard(
          title: 'Total Birds',
          value: totalCapacity.toString(),
          icon: Icons.pets,
          accentColor: Colors.green,
        ),
        DashboardCard(
          title: 'Active Farms',
          value: totalFarms.toString(),
          icon: Icons.agriculture,
          accentColor: Colors.teal,
        ),
        const DashboardCard(
          title: 'Health Score',
          value: '92%',
          icon: Icons.health_and_safety,
          accentColor: Colors.indigo,
        ),
        const DashboardCard(
          title: 'Daily Tasks',
          value: '6',
          icon: Icons.checklist,
          accentColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String subtitle) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ),
    );
  }
}
