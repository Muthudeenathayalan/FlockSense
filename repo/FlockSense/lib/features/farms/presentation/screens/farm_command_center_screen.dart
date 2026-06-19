import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/action_tile.dart';
import 'package:flock_sense/core/widgets/dashboard_card.dart';
import 'package:flock_sense/core/widgets/section_header.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

class FarmCommandCenterScreen extends StatelessWidget {
  const FarmCommandCenterScreen({super.key, required this.farm});

  final FarmModel farm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Farm Command Center'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(farm.farmName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(FarmService.getFormattedFarmType(farm.flockType), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
                          const SizedBox(width: 12),
                          const StatusBadge(label: 'Active'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('Manage farm operations, view health metrics, and track batch performance.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  DashboardCard(title: 'Bird Capacity', value: '${farm.birdCapacity}', icon: Icons.pets, accentColor: Colors.green),
                  DashboardCard(title: 'Active Batches', value: '0', icon: Icons.groups, accentColor: Colors.teal),
                  DashboardCard(title: 'Today Mortality', value: '0', icon: Icons.healing, accentColor: Colors.redAccent),
                  DashboardCard(title: 'Farm Health', value: '100%', icon: Icons.insights, accentColor: Colors.indigo),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Quick actions', subtitle: 'Access the farm tools you need right now.'),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ActionTile(icon: Icons.group, label: 'Batches', onTap: () {}),
                  ActionTile(icon: Icons.calendar_today, label: 'Daily Records', onTap: () {}),
                  ActionTile(icon: Icons.inventory_2, label: 'Feed Stock', onTap: () {}),
                  ActionTile(icon: Icons.account_balance_wallet, label: 'Finance', onTap: () {}),
                  ActionTile(icon: Icons.pie_chart, label: 'Reports', onTap: () {}),
                  ActionTile(icon: Icons.insights, label: 'AI Insights', onTap: () {}),
                  ActionTile(icon: Icons.settings, label: 'Settings', onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Active Batches', subtitle: 'Monitor the current flock activity.'),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No active batches yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text('Add your first batch to see live performance data and farm insights.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Alerts', subtitle: 'Important farm notifications.'),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text('No alerts for this farm', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Today’s tasks', subtitle: 'Keep your farm running smoothly.'),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 1,
                child: ListTile(
                  title: const Text('No tasks scheduled'),
                  subtitle: Text('Add tasks once your first farm is set up.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Recent activity', subtitle: 'Farm actions and updates.'),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 1,
                child: ListTile(
                  title: const Text('No recent activity'),
                  subtitle: Text('Activities will appear here once your farm starts operating.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
