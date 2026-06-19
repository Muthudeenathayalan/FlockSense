import 'package:flutter/material.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_command_center_screen.dart';
import 'package:flock_sense/features/farms/presentation/widgets/empty_farm_widget.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_card.dart';

class FarmListScreen extends StatefulWidget {
  const FarmListScreen({super.key});

  @override
  State<FarmListScreen> createState() => _FarmListScreenState();
}

class _FarmListScreenState extends State<FarmListScreen> {
  late Future<List<FarmModel>> _farmsFuture;

  @override
  void initState() {
    super.initState();
    _refreshFarms();
  }

  Future<void> _refreshFarms() async {
    setState(() {
      _farmsFuture = FarmService.getUserFarms();
    });
  }

  Future<void> _setActiveFarm(String farmId) async {
    try {
      await FarmService.setActiveFarm(farmId);
      if (mounted) {
        Navigator.pop(context, farmId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set active farm: $e')),
        );
      }
    }
  }

  Future<void> _deleteFarm(String farmId, String farmName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Farm'),
        content: Text('Are you sure you want to delete "$farmName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FarmService.deleteFarm(farmId);
        if (mounted) {
          await _refreshFarms();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete farm: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Farms'),
      ),
      body: FutureBuilder<List<FarmModel>>(
        future: _farmsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading farms: ${snapshot.error}',
                  style: const TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final farms = snapshot.data ?? [];

          if (farms.isEmpty) {
            return EmptyFarmWidget(
              onCreate: () => Navigator.pushNamed(context, AppRoutes.farmSetup).then((res) {
                if (res == true) _refreshFarms();
              }),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: farms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final farm = farms[index];

                return FarmCard(
                farm: farm,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => FarmCommandCenterScreen(farm: farm)))
                    .then((_) => _refreshFarms()),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.green),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'active',
                      child: const Text('Set Active'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'active') {
                      _setActiveFarm(farm.id);
                    } else if (value == 'delete') {
                      _deleteFarm(farm.id, farm.farmName);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.farmSetup).then((res) {
          if (res == true) _refreshFarms();
        }),
        tooltip: 'Create Farm',
        child: const Icon(Icons.add),
      ),
    );
  }
}
