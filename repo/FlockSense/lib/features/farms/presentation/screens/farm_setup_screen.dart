import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_form.dart';

class FarmSetupScreen extends StatefulWidget {
  const FarmSetupScreen({super.key});

  @override
  State<FarmSetupScreen> createState() => _FarmSetupScreenState();
}

class _FarmSetupScreenState extends State<FarmSetupScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleCreateFarm(
    String farmName,
    String farmType,
    String flockType,
    String address,
    int birdCapacity,
    String? district,
    String? state,
    double? lengthFt,
    double? widthFt,
    String? notes,
  ) async {
    debugPrint('[FarmSetupScreen] onSubmit called with: farmName=$farmName, farmType=$farmType, flockType=$flockType, address=$address, capacity=$birdCapacity');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[FarmSetupScreen] Calling FarmService.createFarm()');
      await FarmService.createFarm(
        farmName: farmName,
        farmType: farmType,
        flockType: flockType,
        address: address,
        birdCapacity: birdCapacity,
        district: district,
        state: state,
        lengthFt: lengthFt,
        widthFt: widthFt,
        notes: notes,
      );

      debugPrint('[FarmSetupScreen] Farm created successfully!');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm created successfully!')),
      );
      // Return to previous screen and signal refresh
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      debugPrint('[FarmSetupScreen] Firebase error: code=${e.code}, message=${e.message}');
      setState(() {
        if (e.code == 'permission-denied') {
          _errorMessage =
              'You do not have permission to create a farm. Please check your Firebase Firestore rules or sign in with the correct account.';
        } else if (e.code == 'unauthenticated') {
          _errorMessage = 'You must be signed in to create a farm.';
        } else {
          _errorMessage = e.message ?? 'Failed to create farm. Please try again.';
        }
      });
    } catch (e) {
      debugPrint('[FarmSetupScreen] Unexpected error: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: FarmForm(
          onSubmit: _handleCreateFarm,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
        ),
      ),
    );
  }
}
