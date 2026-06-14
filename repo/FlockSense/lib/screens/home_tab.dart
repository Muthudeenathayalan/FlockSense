import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/widgets/metric_card.dart';
import 'package:flock_sense/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:flock_sense/screens/flocks_screen.dart';
import 'package:flock_sense/screens/reports_screen.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Dashboard',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Track your batches, mortality, feed, vaccinations, and profit.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              children: [
                MetricCard(
                  title: 'Total flocks',
                  value: metrics.totalFlocks.toString(),
                  accentColor: Colors.teal,
                ),
                MetricCard(
                  title: 'Total birds',
                  value: metrics.totalBirds.toString(),
                  accentColor: Colors.indigo,
                ),
                MetricCard(
                  title: 'Target FCR',
                  value: metrics.averageTargetFcr > 0 ? metrics.averageTargetFcr.toStringAsFixed(2) : '-',
                  accentColor: Colors.orange,
                ),
                MetricCard(
                  title: 'Pending vaccines',
                  value: metrics.pendingVaccinations.toString(),
                  accentColor: Colors.redAccent,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Quick actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionChip(label: 'Add flock', icon: Icons.add_circle_outline, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FlocksScreen()))),
                _ActionChip(label: 'Reports', icon: Icons.bar_chart, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen()))),
                _ActionChip(label: 'Revenue', icon: Icons.attach_money, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Finance coming soon')))),
                _ActionChip(label: 'Health', icon: Icons.health_and_safety, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Health workflows coming soon')))),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Recent activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  _ActivityTile(title: 'Batch A1 updated', subtitle: 'Feed schedule changed for Broiler flock'),
                  _ActivityTile(title: 'Vaccination reminder', subtitle: 'Hatchery batch needs vaccine on Friday'),
                  _ActivityTile(title: 'Report ready', subtitle: 'Weekly flock performance summary available'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.teal),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ActivityTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
