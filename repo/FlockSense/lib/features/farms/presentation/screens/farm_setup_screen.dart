import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
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
    String location,
    String farmType,
    int totalCapacity,
  ) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FarmService.createFarm(
        farmName: farmName,
        location: location,
        farmType: farmType,
        totalCapacity: totalCapacity,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } on FirebaseException catch (e) {
      setState(() {
        if (e.code == 'permission-denied') {
          _errorMessage =
              'You do not have permission to create a farm. Please check your Firebase Firestore rules or sign in with the correct account.';
        } else {
          _errorMessage = e.message ?? 'Failed to create farm. Please try again.';
        }
      });
    } catch (e) {
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
      backgroundColor: Colors.black,
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
