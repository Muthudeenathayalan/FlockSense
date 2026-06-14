import 'package:flutter/material.dart';
import 'package:flock_sense/screens/dashboard_screen.dart';
import 'package:flock_sense/screens/flocks_screen.dart';
import 'package:flock_sense/screens/finance_screen.dart';

class MyFarmsScreen extends StatelessWidget {
  const MyFarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _FarmsOption(
        title: 'Farm',
        subtitle: 'View farm summary and locations',
        icon: Icons.agriculture,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const DashboardScreen())),
      ),
      _FarmsOption(
        title: 'Batch',
        subtitle: 'Manage all flock batches',
        icon: Icons.inventory_2,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FlocksScreen())),
      ),
      _FarmsOption(
        title: 'Daily Task',
        subtitle: 'Track daily operations',
        icon: Icons.task_alt,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily task screen coming soon')),
        ),
      ),
      _FarmsOption(
        title: 'Details',
        subtitle: 'Batch details and insights',
        icon: Icons.details,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Details screen coming soon')),
        ),
      ),
      _FarmsOption(
        title: 'Feed Stack',
        subtitle: 'Manage feed inventory',
        icon: Icons.food_bank,
        onTap: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Feed stack coming soon'))),
      ),
      _FarmsOption(
        title: 'Finance',
        subtitle: 'Expense and revenue overview',
        icon: Icons.account_balance_wallet,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FinanceScreen())),
      ),
      _FarmsOption(
        title: 'Schedule & Task',
        subtitle: 'Plan tasks and vaccination schedules',
        icon: Icons.schedule,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule screen coming soon')),
        ),
      ),
      _FarmsOption(
        title: 'Sale',
        subtitle: 'Record sales and income',
        icon: Icons.sell,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale screen coming soon')),
        ),
      ),
      _FarmsOption(
        title: 'Notifications',
        subtitle: 'View important alerts',
        icon: Icons.notifications_active,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications screen coming soon')),
        ),
      ),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Farms',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Access farm tools, batch management and task workflows in one place.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) => items[index],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmsOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _FarmsOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.shade50,
              child: Icon(icon, color: Colors.teal),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
