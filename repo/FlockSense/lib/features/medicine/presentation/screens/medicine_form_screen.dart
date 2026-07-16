import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/medicine/data/medicine_service.dart';
import 'package:flock_sense/features/medicine/domain/medicine_record_model.dart';

class MedicineFormScreen extends ConsumerStatefulWidget {
  const MedicineFormScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    required this.currentBatchAge,
    this.existing,
  });

  final String farmId;
  final String batchId;
  final int currentBatchAge;
  final MedicineRecordModel? existing;

  @override
  ConsumerState<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends ConsumerState<MedicineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  final _dcNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  late String _selectedRoute;
  late String _selectedUnit;
  bool _saving = false;

  static const List<String> _routes = <String>[
    'Drinking Water',
    'Feed',
    'Injection',
    'Spray',
    'Eye Drop',
  ];
  static const List<String> _units = <String>[
    'ml',
    'g',
    'kg',
    'tablets',
    'sachets',
    'bottles',
    'liters',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _selectedDate = existing?.date ?? DateTime.now();
    _selectedRoute = existing?.route ?? _routes.first;
    _selectedUnit = existing?.unit ?? _units.first;
    _medicineNameController.text = existing?.medicineName ?? '';
    _dcNumberController.text = existing?.dcNumber ?? '';
    _quantityController.text = existing?.quantity.toString() ?? '';
    _valueController.text = existing?.valueRs?.toString() ?? '';
    _notesController.text = existing?.notes ?? '';
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _dcNumberController.dispose();
    _quantityController.dispose();
    _valueController.dispose();
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
      await MedicineService.createMedicineRecord(
        farmId: widget.farmId,
        batchId: widget.batchId,
        medicineName: _medicineNameController.text.trim(),
        quantity: double.tryParse(_quantityController.text.trim()) ?? 0,
        unit: _selectedUnit,
        date: _selectedDate,
        batchAgeDay: widget.currentBatchAge,
        dcNumber: _dcNumberController.text.trim().isEmpty
            ? null
            : _dcNumberController.text.trim(),
        valueRs: double.tryParse(_valueController.text.trim()),
        route: _selectedRoute,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Medicine recorded'),
            ],
          ),
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
        title: Text(
          widget.existing == null ? 'Medicine Record' : 'Edit Medicine Record',
        ),
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
                  gradient: AppColors.dangerGradient,
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
                        Icons.medication_outlined,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Log Medicine',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Day ${widget.currentBatchAge}',
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
                _medicineNameController,
                'Medicine name',
                required: true,
                icon: Icons.medication_outlined,
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
                _dcNumberController,
                'DC Number',
                icon: Icons.receipt_outlined,
              ),
              const SizedBox(height: 14),
              const Text(
                'Route',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _routes.map((route) {
                  final selected = _selectedRoute == route;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRoute = route),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.dangerGradient : null,
                        color: selected ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        route,
                        style: TextStyle(
                          color: selected
                              ? AppColors.surface
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
              const Text(
                'Unit',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _units.map((unit) {
                  final selected = _selectedUnit == unit;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedUnit = unit),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.dangerLight
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        unit,
                        style: TextStyle(
                          color: selected
                              ? AppColors.danger
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _textField(
                _valueController,
                'Value (₹)',
                icon: Icons.currency_rupee_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                formatter: FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
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
                    : const Text('Save Record'),
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
