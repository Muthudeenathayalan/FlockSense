import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/dashboard_card.dart';
import 'package:flock_sense/core/widgets/section_header.dart';
import 'package:flock_sense/core/widgets/action_tile.dart';
import 'package:flock_sense/core/widgets/empty_state_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildOverviewCards(context),
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
                title: 'You’re all caught up',
                message: 'No urgent tasks for today. Check back later for new recommendations.',
                buttonLabel: 'Refresh dashboard',
                onButtonPressed: () {},
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            Text('Farmer!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Your farms are looking healthy today. Keep an eye on tasks and recommendations.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        DashboardCard(title: 'Total Birds', value: '1,280', icon: Icons.pets, accentColor: Colors.green),
        DashboardCard(title: 'Active Farms', value: '4', icon: Icons.agriculture, accentColor: Colors.teal),
        DashboardCard(title: 'Health Score', value: '92%', icon: Icons.health_and_safety, accentColor: Colors.indigo),
        DashboardCard(title: 'Daily Tasks', value: '6', icon: Icons.checklist, accentColor: Colors.orange),
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
