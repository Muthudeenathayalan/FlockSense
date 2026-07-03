import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/shared/widgets/custom_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<FarmModel?> _farmFuture;

  @override
  void initState() {
    super.initState();
    _farmFuture = _loadActiveFarm();
  }

  Future<FarmModel?> _loadActiveFarm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final activeFarmId = userDoc.data()?['activeFarmId'] as String?;
    if (activeFarmId == null || activeFarmId.isEmpty) return null;

    return FarmService.getFarmById(activeFarmId);
  }

  Widget _buildSummaryCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.teal,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email ?? 'Owner';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.grey.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<FarmModel?>(
        future: _farmFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final farm = snapshot.data;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome back, $displayName',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                if (farm != null) ...[
                  Text(
                    '${farm.farmName} • ${FarmService.getFormattedFarmType(farm.flockType)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ] else ...[
                  const Text(
                    'No farm selected. Set up a farm to continue.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 24),
                if (farm != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Farm Details',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Location:', style: TextStyle(color: Colors.white70)),
                              Text(farm.address, style: const TextStyle(color: Colors.white)),
                            ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Status:', style: TextStyle(color: Colors.white70)),
                            Text(
                              farm.status,
                              style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<List<FarmModel>>(
                    future: FarmService.getUserFarms(),
                    builder: (context, farmsSnap) {
                      return GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildSummaryCard(context, 'Total Birds', '0', Icons.pets),
                          _buildSummaryCard(context, 'Active Batches', '0', Icons.group),
                          _buildSummaryCard(context, 'Feed Stock', '0 kg', Icons.inventory_2),
                          _buildSummaryCard(context, 'Alerts', '0', Icons.warning_amber),
                        ],
                      );
                    },
                  ),
                ],
                const Spacer(),
                if (farm != null) ...[
                  CustomButton(
                    label: 'Add Batch',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Batch management coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                CustomButton(
                  label: 'Manage Farms',
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.farms),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: 'Logout',
                  onPressed: () => _logout(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
