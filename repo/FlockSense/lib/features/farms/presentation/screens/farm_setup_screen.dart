import 'package:flutter/material.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_form.dart';

/// Create a new farm
class FarmSetupScreen extends StatefulWidget {
  const FarmSetupScreen({super.key});

  @override
  State<FarmSetupScreen> createState() => _FarmSetupScreenState();
}

class _FarmSetupScreenState extends State<FarmSetupScreen> {
  bool _saving = false;

  Future<void> _onSubmit(
    String farmName,
    String farmType,
    String flockType,
    String address,
    String? areaName,
    String? district,
    String? state,
    String? farmerName,
    String? phoneNumber,
    String? notes,
    double lengthFt,
    double widthFt,
    int? capacity,
  ) async {
    setState(() => _saving = true);
    try {
      await FarmService.createFarm(
        farmName: farmName,
        farmType: farmType,
        flockType: flockType,
        address: address,
        areaName: areaName,
        district: district,
        state: state,
        farmerName: farmerName,
        phoneNumber: phoneNumber,
        notes: notes,
        lengthFt: lengthFt,
        widthFt: widthFt,
        capacity: capacity,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Farm saved! It will sync to the cloud when online.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Farm')),
      body: _saving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving farm...'),
                ],
              ),
            )
          : FarmForm(onSubmit: _onSubmit),
    );
  }
}
