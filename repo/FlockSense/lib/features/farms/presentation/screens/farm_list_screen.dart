import 'package:flutter/material.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

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
    _farmsFuture = FarmService.getUserFarms();
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
          setState(() {
            _farmsFuture = FarmService.getUserFarms();
          });
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My Farms'),
        backgroundColor: Colors.grey.shade900,
      ),
      body: FutureBuilder<List<FarmModel>>(
        future: _farmsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading farms: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final farms = snapshot.data ?? [];

          if (farms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.agriculture, size: 64, color: Colors.white30),
                  const SizedBox(height: 16),
                  const Text(
                    'No farms yet',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: farms.length,
            itemBuilder: (context, index) {
              final farm = farms[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    farm.farmName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${FarmService.getFormattedFarmType(farm.farmType)} • ${farm.totalCapacity} birds',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        farm.location,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Set Active'),
                        onTap: () => _setActiveFarm(farm.farmId),
                      ),
                      PopupMenuItem(
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onTap: () => _deleteFarm(farm.farmId, farm.farmName),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
