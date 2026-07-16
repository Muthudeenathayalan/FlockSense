import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/action_tile.dart';
import 'package:flock_sense/core/widgets/section_header.dart';

class VaccinationScreen extends StatelessWidget {
  const VaccinationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Vaccination Schedule')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vaccination Management',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track vaccination schedules, due reminders, and health records.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Quick Actions',
                subtitle: 'Manage vaccination records.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  ActionTile(
                    icon: Icons.calendar_today,
                    label: 'Schedule',
                    onTap: () {},
                  ),
                  ActionTile(
                    icon: Icons.check_circle,
                    label: 'Record Vaccine',
                    onTap: () {},
                  ),
                  ActionTile(
                    icon: Icons.notifications_active,
                    label: 'Reminders',
                    onTap: () {},
                  ),
                  ActionTile(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Due Vaccines',
                subtitle: 'Vaccines that need to be administered.',
              ),
              const SizedBox(height: 16),
              _buildVaccineTile(
                context,
                'Newcastle Disease',
                'Due in 2 days',
                Icons.warning_amber,
                Colors.orange,
              ),
              _buildVaccineTile(
                context,
                'Infectious Bursal',
                'Due in 5 days',
                Icons.schedule,
                Colors.blue,
              ),
              _buildVaccineTile(
                context,
                'Marek\'s Disease',
                'On time',
                Icons.check_circle,
                Colors.green,
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Completed',
                subtitle: 'Recently administered vaccines.',
              ),
              const SizedBox(height: 16),
              _buildCompletedTile(
                context,
                'Gumboro Vaccine',
                'Completed 3 days ago',
              ),
              _buildCompletedTile(
                context,
                'Coccidiosis Vaccine',
                'Completed 1 week ago',
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coming soon',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Calendar view, automated reminders, and health certification reports.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaccineTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withAlpha((0.15 * 255).toInt()),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Coming soon'))),
      ),
    );
  }

  Widget _buildCompletedTile(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.green.withAlpha((0.15 * 255).toInt()),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
      ),
    );
  }
}
