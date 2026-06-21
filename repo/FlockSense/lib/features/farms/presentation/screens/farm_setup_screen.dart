import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_form.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';

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
    debugPrint('[FarmSetupScreen] onSubmit called with: farmName=$farmName, farmType=$farmType');
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
    } on ValidationException catch (e) {
      debugPrint('[FarmSetupScreen] Validation error: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } on AuthException catch (e) {
      debugPrint('[FarmSetupScreen] Auth error: ${e.message}');
      setState(() {
        _errorMessage = ErrorMessages.getDisplayMessage(e);
      });
    } on PermissionException catch (e) {
      debugPrint('[FarmSetupScreen] Permission error: ${e.message}');
      setState(() {
        _errorMessage = 'You do not have permission to create a farm. Please check your Firebase settings.';
      });
    } on FirestoreException catch (e) {
      debugPrint('[FarmSetupScreen] Firestore error: code=${e.code}, message=${e.message}');
      setState(() {
        _errorMessage = ErrorMessages.getDisplayMessage(e);
      });
    } on AppException catch (e) {
      debugPrint('[FarmSetupScreen] App error: ${e.message}');
      setState(() {
        _errorMessage = ErrorMessages.getDisplayMessage(e);
      });
    } on FirebaseException catch (e) {
      debugPrint('[FarmSetupScreen] Firebase error: code=${e.code}, message=${e.message}');
      setState(() {
        _errorMessage = e.message ?? 'Failed to create farm. Please try again.';
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

