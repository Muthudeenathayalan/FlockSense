import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/models/flock.dart';
import 'package:flock_sense/services/firestore_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: Text('Please sign in to view dashboard data.')),
      );
    }

    final service = FirestoreService(uid: uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Your key farm metrics are shown here.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Flock>>(
                  stream: service.watchFlocks(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Failed to load dashboard: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final flocks = snapshot.data ?? [];
                    final activeCount = flocks.length;
                    final targetFcrValues = flocks.map((flock) => flock.targetFcr).whereType<double>().toList();
                    final avgFcrDisplay = targetFcrValues.isEmpty
                        ? '-'
                        : (targetFcrValues.reduce((a, b) => a + b) / targetFcrValues.length).toStringAsFixed(2);

                    if (flocks.isEmpty) {
                      return const Center(
                        child: Text('No flock data available yet. Add a flock to start your dashboard.'),
                      );
                    }

                    return Column(
                      children: [
                        _DashboardCard(title: 'Active flocks', value: '$activeCount'),
                        const SizedBox(height: 12),
                        _DashboardCard(title: 'Average target FCR', value: avgFcrDisplay),
                        const SizedBox(height: 12),
                        _DashboardCard(title: 'Total inventory status', value: 'See Flocks tab'),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;

  const _DashboardCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
