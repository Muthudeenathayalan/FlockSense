import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/vaccine/data/vaccine_service.dart';

class VaccineFormScreen extends StatefulWidget {
  const VaccineFormScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    required this.currentBatchAge,
  });

  final String farmId;
  final String batchId;
  final int currentBatchAge;

  @override
  State<VaccineFormScreen> createState() => _VaccineFormScreenState();
}

class _VaccineFormScreenState extends State<VaccineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'ml');
  final _routeController = TextEditingController(text: 'Injection');
  final _doneByController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _batchNumberController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _routeController.dispose();
    _doneByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await VaccineService.createVaccineRecord(
        farmId: widget.farmId,
        batchId: widget.batchId,
        vaccineName: _nameController.text.trim(),
        vaccineType: _typeController.text.trim(),
        quantity: double.tryParse(_quantityController.text.trim()) ?? 0,
        unit: _unitController.text.trim(),
        date: _selectedDate,
        batchAgeDay: widget.currentBatchAge,
        batchNumber: _batchNumberController.text.trim().isEmpty
            ? null
            : _batchNumberController.text.trim(),
        route: _routeController.text.trim(),
        doneBy: _doneByController.text.trim().isEmpty
            ? null
            : _doneByController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vaccine entry saved'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vaccination Entry'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.vaccines_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vaccination',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Age day ${widget.currentBatchAge}',
                            style: const TextStyle(color: AppColors.surface),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _textField(
                _nameController,
                'Vaccine name',
                required: true,
                icon: Icons.vaccines_outlined,
              ),
              const SizedBox(height: 14),
              _textField(
                _typeController,
                'Vaccine type',
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 14),
              _textField(
                _batchNumberController,
                'Batch/Lot number',
                icon: Icons.confirmation_number_outlined,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _textField(
                _quantityController,
                'Quantity',
                required: true,
                icon: Icons.numbers_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                formatter: FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ),
              const SizedBox(height: 14),
              _textField(
                _unitController,
                'Unit',
                icon: Icons.straighten_outlined,
              ),
              const SizedBox(height: 14),
              _textField(
                _routeController,
                'Route',
                icon: Icons.local_hospital_outlined,
              ),
              const SizedBox(height: 14),
              _textField(
                _doneByController,
                'Done by',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              _textField(
                _notesController,
                'Notes',
                maxLines: 3,
                icon: Icons.sticky_note_2_outlined,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : const Text('Save Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    IconData? icon,
    TextInputType? keyboardType,
    TextInputFormatter? formatter,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatter == null ? null : [formatter],
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      validator: required
          ? (value) =>
                (value == null || value.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString()}';
  }
}
