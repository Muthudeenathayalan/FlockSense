import 'package:flutter/material.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_list_screen.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_setup_screen.dart';

/// Detail view for a single farm. Exposes Sheds and (future) Batches as tabs.
class FarmCommandCenterScreen extends StatelessWidget {
  const FarmCommandCenterScreen({super.key, required this.farm});
  final FarmModel farm;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(farm.farmName),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit farm',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FarmSetupScreen()),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Batches'),
              Tab(icon: Icon(Icons.info_outline), text: 'Details'),
              Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Reports'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BatchListScreen(farmId: farm.id, farmName: farm.farmName),
            _FarmDetailsTab(farm: farm),
            const Center(child: Text('Reports coming soon')),
          ],
        ),
      ),
    );
  }
}

class _FarmDetailsTab extends StatelessWidget {
  const _FarmDetailsTab({required this.farm});
  final FarmModel farm;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Farm type', farm.farmType),
      ('Flock type', farm.flockType),
      ('Address', farm.address),
      if (farm.location?.isNotEmpty ?? false) ('Location', farm.location!),
      if (farm.ownerName?.isNotEmpty ?? false) ('Owner', farm.ownerName!),
      if (farm.phone?.isNotEmpty ?? false) ('Phone', farm.phone!),
      if (farm.notes?.isNotEmpty ?? false) ('Notes', farm.notes!),
      ('Status', farm.status),
      ('Created', _fmt(farm.createdAt)),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            title: const Text('Batch Placement', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Create and manage chick batches'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BatchListScreen(
                    farmId: farm.id,
                    farmName: farm.farmName,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(rows.length, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    rows[i].$1,
                    style: const TextStyle(color: Colors.black45, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Text(
                    rows[i].$2,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
