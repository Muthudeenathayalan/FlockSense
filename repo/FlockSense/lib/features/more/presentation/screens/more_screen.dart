import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_placeholder_screen.dart';
import 'package:flock_sense/features/feed/presentation/screens/feed_records_screen.dart';
import 'package:flock_sense/features/sales/presentation/screens/bird_sales_screen.dart';
import 'package:flock_sense/features/performance/presentation/screens/farm_performance_screen.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_records_screen.dart';
import 'package:flock_sense/features/support/presentation/screens/help_support_screen.dart';

// Uses the icon categories from the uploaded reference image:
// FlockSense, Dashboard, Farms & Sheds, Flocks/Batches,
// Growth Analytics, Log Data, Calendar/Schedule, Settings
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _items = [
    _MoreItem('Dashboard', Icons.dashboard_outlined, 'Live farm overview', AppColors.primary),
    _MoreItem('Farms & Sheds', Icons.home_work_outlined, 'Manage your farms', Color(0xFF1B6B8A)),
    _MoreItem('Flocks & Batches', Icons.pets, 'Track each batch', Color(0xFF2E7D32)),
    _MoreItem('Growth Analytics', Icons.trending_up, 'Weight & FCR charts', Color(0xFF6A1B9A)),
    _MoreItem('Log Data', Icons.assignment_outlined, 'Daily records entry', Color(0xFFE65100)),
    _MoreItem('Calendar', Icons.calendar_month_outlined, 'Vaccination schedule', Color(0xFF00838F)),
    _MoreItem('AI Advisor', Icons.psychology_outlined, 'Smart recommendations', Color(0xFF283593)),
    _MoreItem('Reports', Icons.bar_chart_outlined, 'Export PDF & Excel', Color(0xFF558B2F)),
    _MoreItem('Finance', Icons.account_balance_outlined, 'Income & expenses', Color(0xFF37474F)),
    _MoreItem('Inventory', Icons.inventory_2_outlined, 'Feed & medicine stock', Color(0xFFAD1457)),
    _MoreItem('Notifications', Icons.notifications_outlined, 'Reminders & alerts', Color(0xFFF57F17)),
    _MoreItem('Settings', Icons.settings_outlined, 'App preferences', Color(0xFF455A64)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemCount: _items.length,
        itemBuilder: (_, i) => _MoreCard(item: _items[i]),
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem(this.label, this.icon, this.subtitle, this.color);
  final String label, subtitle;
  final IconData icon;
  final Color color;
}

class _MoreCard extends StatelessWidget {
  const _MoreCard({required this.item});
  final _MoreItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        switch (item.label) {
          case 'Log Data':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyRecordsPlaceholderScreen()));
            return;
          case 'Inventory':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedRecordsScreen()));
            return;
          case 'Finance':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BirdSalesScreen()));
            return;
          case 'Reports':
            _showExportSheet(context);
            return;
          case 'Growth Analytics':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmPerformanceScreen()));
            return;
          case 'Flocks & Batches':
            Navigator.pushNamed(context, '/batches');
            return;
          case 'Calendar':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VaccineRecordsScreen()));
            return;
          case 'Dashboard':
            Navigator.popUntil(context, (r) => r.isFirst);
            return;
          case 'Settings':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
            return;
          default:
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${item.label} — coming soon'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3)),
          const SizedBox(height: 3),
          Text(item.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
        ]),
      ),
    );
  }
}

void _showExportSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.picture_as_pdf), title: const Text('Export PDF'), subtitle: const Text('Coming soon'), onTap: () {}),
        ListTile(leading: const Icon(Icons.share), title: const Text('Share Report'), subtitle: const Text('Coming soon'), onTap: () {}),
        ListTile(leading: const Icon(Icons.file_download), title: const Text('Download CSV'), subtitle: const Text('Coming soon'), onTap: () {}),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

// (imports moved to top)

