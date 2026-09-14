import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/sales/data/sales_service.dart';

class SalesFormScreen extends StatefulWidget {
  const SalesFormScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    this.currentBatchAge = 0,
    this.availableBirds,
  });

  final String farmId;
  final String batchId;
  final int currentBatchAge;
  final int? availableBirds;

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

  int? _availableBirds;
  int _calculatedAge = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _availableBirds = widget.availableBirds;
    _calculatedAge = widget.currentBatchAge;
    _birdsController.addListener(_onFieldChanged);
    _priceController.addListener(_onFieldChanged);
    _loadBatchInfo();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadBatchInfo() async {
    try {
      final b = await BatchService.getBatchById(widget.farmId, widget.batchId);
      if (b != null && mounted) {
        setState(() {
          _availableBirds = b.currentBirds;
          final age = _selectedDate.difference(b.placementDate).inDays;
          _calculatedAge = age >= 0 ? age : 0;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _birdsController.removeListener(_onFieldChanged);
    _priceController.removeListener(_onFieldChanged);
    _customerController.dispose();
    _birdsController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _vehicleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _soldCount => int.tryParse(_birdsController.text.trim()) ?? 0;
  double get _pricePerBird =>
      double.tryParse(_priceController.text.trim()) ?? 0.0;
  int get _remainingBirds =>
      _availableBirds != null ? (_availableBirds! - _soldCount) : 0;
  double get _totalEstimatedValue => _soldCount * _pricePerBird;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadBatchInfo();
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
        birdsSold: _soldCount,
        averageWeightKg: double.tryParse(_weightController.text.trim()) ?? 0,
        pricePerBird: _pricePerBird,
        date: _selectedDate,
        batchAgeDay: _calculatedAge > 0 ? _calculatedAge : widget.currentBatchAge,
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
          content: Text('Sale entry saved successfully. Flock count updated.'),
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
    final hasAvailable = _availableBirds != null;
    final isExceeding = hasAvailable && _soldCount > _availableBirds!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bird Sale Entry'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card with Live Flock Context
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.point_of_sale_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bird Sale Entry',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasAvailable
                                ? 'Available: ${NumberFormat('#,###').format(_availableBirds)} live birds • Day $_calculatedAge'
                                : 'Recording live flock sales',
                            style: const TextStyle(
                              color: Color(0xFFDCFCE7),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
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
                'Customer / Trader Name',
                required: true,
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),

              _textField(
                _birdsController,
                'Number of Birds Sold',
                required: true,
                icon: Icons.pets_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                formatter: FilteringTextInputFormatter.allow(RegExp(r'[\d]')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Birds sold is required';
                  }
                  final n = int.tryParse(value.trim());
                  if (n == null || n <= 0) return 'Must be greater than 0';
                  if (hasAvailable && n > _availableBirds!) {
                    return 'Cannot sell more than available live birds ($_availableBirds)';
                  }
                  return null;
                },
              ),

              // Live Real-Time Deduction Preview Banner
              if (_soldCount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isExceeding ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isExceeding ? const Color(0xFFFECDD3) : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExceeding
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        color: isExceeding ? AppColors.danger : AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isExceeding
                              ? 'Exceeds available live birds ($_availableBirds)'
                              : 'Remaining after sale: ${NumberFormat('#,###').format(_remainingBirds)} birds',
                          style: TextStyle(
                            color: isExceeding ? const Color(0xFFBE123C) : const Color(0xFF15803D),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_totalEstimatedValue > 0)
                        Text(
                          '₹${NumberFormat('#,###').format(_totalEstimatedValue)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              _textField(
                _weightController,
                'Average Weight (kg / bird)',
                icon: Icons.scale_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                formatter: FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ),
              const SizedBox(height: 14),

              _textField(
                _priceController,
                'Price per Bird (₹)',
                required: true,
                icon: Icons.currency_rupee_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                formatter: FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ),
              const SizedBox(height: 14),

              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
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
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sale Date: ${_formatDate(_selectedDate)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Change',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _textField(
                _vehicleController,
                'Vehicle Number (Optional)',
                icon: Icons.local_shipping_outlined,
              ),
              const SizedBox(height: 14),

              _textField(
                _notesController,
                'Notes / Remarks (Optional)',
                maxLines: 2,
                icon: Icons.note_outlined,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.surface,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Sale & Deduct Flock',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
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
    String? Function(String?)? validator,
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
            : Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      validator: validator ??
          (required
              ? (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null
              : null),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString()}';
  }
}
