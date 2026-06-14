import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/models/flock.dart';
import 'package:flock_sense/services/firestore_service.dart';

class NewFlockScreen extends StatefulWidget {
  const NewFlockScreen({super.key});

  @override
  State<NewFlockScreen> createState() => _NewFlockScreenState();
}

class _NewFlockScreenState extends State<NewFlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _openingCountController = TextEditingController();
  final _targetFcrController = TextEditingController();
  final _expectedHarvestController = TextEditingController();
  String _birdType = 'Broiler';
  DateTime _placementDate = DateTime.now();
  bool _isSaving = false;
  String? _error;

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _error = 'You must be signed in to add a new flock.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final flock = Flock(
        id: '',
        name: _nameController.text.trim(),
        birdType: _birdType,
        breed: _breedController.text.trim(),
        placementDate: _placementDate,
        openingCount: int.parse(_openingCountController.text.trim()),
        targetFcr: _targetFcrController.text.trim().isEmpty ? null : double.parse(_targetFcrController.text.trim()),
        expectedHarvestDay: _expectedHarvestController.text.trim().isEmpty ? null : int.parse(_expectedHarvestController.text.trim()),
        createdAt: DateTime.now(),
      );

      await FirestoreService(uid: uid).createFlock(flock);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() {
        _error = 'Unable to save flock: ${error.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickPlacementDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _placementDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() {
        _placementDate = selected;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _openingCountController.dispose();
    _targetFcrController.dispose();
    _expectedHarvestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Flock')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text('Create a new flock batch', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Flock name', border: OutlineInputBorder()),
                  validator: (value) => value?.trim().isEmpty == true ? 'Enter a flock name' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _birdType,
                  items: const ['Broiler', 'Layer', 'Breeder', 'Backyard'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  decoration: const InputDecoration(labelText: 'Bird type', border: OutlineInputBorder()),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _birdType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _breedController,
                  decoration: const InputDecoration(labelText: 'Breed', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _openingCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Opening bird count', border: OutlineInputBorder()),
                  validator: (value) {
                    final intValue = int.tryParse(value ?? '');
                    if (intValue == null || intValue <= 0) {
                      return 'Enter a valid count';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Placement date: ${_placementDate.toLocal().toString().split(' ').first}'),
                    ),
                    TextButton(onPressed: _pickPlacementDate, child: const Text('Change')),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetFcrController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Target FCR (optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _expectedHarvestController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Expected harvest day (optional)', border: OutlineInputBorder()),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Create flock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
