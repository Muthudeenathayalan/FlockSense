import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/section_header.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Reports')),
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
                    Text('Farm Reports', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Track farm performance, trends, and analytics.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Report types', subtitle: 'Select a report to view details.'),
              const SizedBox(height: 16),
              _buildReportTile(context, 'Performance Summary', 'View overall farm performance metrics and trends.', Icons.trending_up),
              _buildReportTile(context, 'Health Analytics', 'Analyze bird health status and disease prevention.', Icons.health_and_safety),
              _buildReportTile(context, 'Feed Efficiency', 'Track feed consumption and conversion rates.', Icons.agriculture),
              _buildReportTile(context, 'Financial Report', 'Review costs, income, and profitability.', Icons.account_balance_wallet),
              _buildReportTile(context, 'Batch History', 'View historical data for completed batches.', Icons.history),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coming soon', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('Export reports, advanced analytics, and scheduled email delivery.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTile(BuildContext context, String title, String subtitle, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report coming soon'))),
      ),
    );
  }
}
