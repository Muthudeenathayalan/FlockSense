import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/action_tile.dart';
import 'package:flock_sense/core/widgets/section_header.dart';

class FeedInventoryScreen extends StatelessWidget {
  const FeedInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Feed Inventory')),
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
                    Text('Feed Management', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Track feed stock, monitor consumption, and manage reorders.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Quick Actions', subtitle: 'Manage your feed operations.'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  ActionTile(icon: Icons.inventory_2, label: 'Current Stock', onTap: () {}),
                  ActionTile(icon: Icons.add_shopping_cart, label: 'New Order', onTap: () {}),
                  ActionTile(icon: Icons.trending_down, label: 'Consumption', onTap: () {}),
                  ActionTile(icon: Icons.notifications_active, label: 'Reorder Alerts', onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Feed Types', subtitle: 'Manage different feed categories.'),
              const SizedBox(height: 16),
              _buildFeedTile(context, 'Starter Feed', '240 kg in stock', Icons.grain),
              _buildFeedTile(context, 'Grower Feed', '520 kg in stock', Icons.agriculture),
              _buildFeedTile(context, 'Layer Feed', '180 kg in stock', Icons.egg),
              _buildFeedTile(context, 'Broiler Feed', '890 kg in stock', Icons.fastfood),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coming soon', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('Live feed tracking, automatic reorder suggestions, and consumption analytics.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedTile(BuildContext context, String title, String subtitle, IconData icon) {
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
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon'))),
      ),
    );
  }
}
