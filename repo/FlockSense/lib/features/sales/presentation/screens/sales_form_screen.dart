import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/sales/data/sales_service.dart';

class SalesFormScreen extends StatefulWidget {
  const SalesFormScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    required this.currentBatchAge,
  });

  final String farmId;
  final String batchId;
  final int currentBatchAge;

  @override
  State<SalesFormScreen> createState() => _SalesFormScreenState();
}

class _SalesFormScreenState extends State<SalesFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _birdsController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _vehicleController = TextEditingController();
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
    _customerController.dispose();
    _birdsController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _vehicleController.dispose();
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
      await SalesService.createSalesRecord(
        farmId: widget.farmId,
        batchId: widget.batchId,
        customerName: _customerController.text.trim(),
        birdsSold: int.tryParse(_birdsController.text.trim()) ?? 0,
        averageWeightKg: double.tryParse(_weightController.text.trim()) ?? 0,
        pricePerBird: double.tryParse(_priceController.text.trim()) ?? 0,
        date: _selectedDate,
        batchAgeDay: widget.currentBatchAge,
        vehicleNumber: _vehicleController.text.trim().isEmpty
            ? null
            : _vehicleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale entry saved'),
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
        title: const Text('Bird Sale Entry'),
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
                        Icons.sell_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bird Sales',
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
                _customerController,
                'Customer name',
                required: true,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              _textField(
                _birdsController,
                'Birds sold',
                required: true,
                icon: Icons.pets_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                formatter: FilteringTextInputFormatter.allow(RegExp(r'[\d]')),
              ),
              const SizedBox(height: 14),
              _textField(
                _weightController,
                'Average weight (kg)',
                icon: Icons.scale_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                formatter: FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ),
              const SizedBox(height: 14),
              _textField(
                _priceController,
                'Price per bird (₹)',
                required: true,
                icon: Icons.currency_rupee_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                formatter: FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
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
                _vehicleController,
                'Vehicle number',
                icon: Icons.local_shipping_outlined,
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
                    : const Text('Save Sale'),
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
