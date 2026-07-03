import 'package:flutter/material.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';

class BatchFormScreen extends StatefulWidget {
  const BatchFormScreen({super.key, required this.farmId, this.shedId});
  final String farmId;
  final String? shedId;

  @override
  State<BatchFormScreen> createState() => _BatchFormScreenState();
}

class _BatchFormScreenState extends State<BatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _batchNameController = TextEditingController();
  final _hatchDateController = TextEditingController();
  final _placementDateController = TextEditingController();
  final _maleCountController = TextEditingController();
  final _femaleCountController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _hatcheryController = TextEditingController();
  final _supervisorController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  DateTime? _parseDate(String value) {
    return DateTime.tryParse(value.trim());
  }

  int _parseInt(String value) => int.tryParse(value.trim()) ?? 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final hatchDate = _parseDate(_hatchDateController.text) ?? DateTime.now();
    final placementDate = _parseDate(_placementDateController.text) ?? DateTime.now();
    final maleCount = _parseInt(_maleCountController.text);
    final femaleCount = _parseInt(_femaleCountController.text);

    try {
      await BatchService.createBatch(
        farmId: widget.farmId,
        shedId: widget.shedId,
        batchName: _batchNameController.text.trim(),
        hatchDate: hatchDate,
        placementDate: placementDate,
        maleCount: maleCount,
        femaleCount: femaleCount,
        breedOrFlockType: _breedController.text.trim(),
        chickAvgWeight: double.tryParse(_weightController.text.trim()),
        hatcheryName: _hatcheryController.text.trim().isNotEmpty ? _hatcheryController.text.trim() : null,
        supervisorName: _supervisorController.text.trim().isNotEmpty ? _supervisorController.text.trim() : null,
        vehicleNumber: _vehicleController.text.trim().isNotEmpty ? _vehicleController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _batchNameController.dispose();
    _hatchDateController.dispose();
    _placementDateController.dispose();
    _maleCountController.dispose();
    _femaleCountController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _hatcheryController.dispose();
    _supervisorController.dispose();
    _vehicleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Batch')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_batchNameController, 'Batch name', required: true),
              const SizedBox(height: 16),
              _field(_hatchDateController, 'Hatch date (YYYY-MM-DD)', required: true),
              const SizedBox(height: 16),
              _field(_placementDateController, 'Placement date (YYYY-MM-DD)', required: true),
              const SizedBox(height: 16),
              _field(
                _maleCountController,
                'Male count',
                keyboardType: TextInputType.number,
                required: true,
                validator: (v) {
                  final value = int.tryParse(v ?? '');
                  if (value == null || value < 0) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _field(
                _femaleCountController,
                'Female count',
                keyboardType: TextInputType.number,
                required: true,
                validator: (v) {
                  final value = int.tryParse(v ?? '');
                  if (value == null || value < 0) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _field(_breedController, 'Breed / flock type'),
              const SizedBox(height: 16),
              _field(_weightController, 'Chick avg weight (kg)'),
              const SizedBox(height: 16),
              _field(_hatcheryController, 'Hatchery name'),
              const SizedBox(height: 16),
              _field(_supervisorController, 'Supervisor name'),
              const SizedBox(height: 16),
              _field(_vehicleController, 'Vehicle number'),
              const SizedBox(height: 16),
              _field(_notesController, 'Notes', maxLines: 3),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Batch'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator: validator ?? (required ? (value) => (value?.trim().isEmpty ?? true) ? 'Required' : null : null),
    );
  }
}
