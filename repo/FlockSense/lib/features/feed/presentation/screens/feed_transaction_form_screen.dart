import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/feed/data/feed_service.dart';
import 'package:flock_sense/features/feed/domain/feed_transaction_model.dart';

class FeedTransactionFormScreen extends StatefulWidget {
  const FeedTransactionFormScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    this.batchName,
    this.existingTransaction,
  });

  final String farmId;
  final String batchId;
  final String? batchName;
  final FeedTransactionModel? existingTransaction;

  @override
  State<FeedTransactionFormScreen> createState() =>
      _FeedTransactionFormScreenState();
}

class _FeedTransactionFormScreenState extends State<FeedTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late String _selectedFeedType;
  final _dcNumberController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _bagsController = TextEditingController();
  final _weightPerBagController = TextEditingController();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  static const List<String> _feedTypes = <String>[
    'PB82',
    '882',
    'B4',
    'Starter',
    'Grower',
    'Finisher',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    _selectedDate = existing?.date ?? DateTime.now();
    _selectedFeedType = existing?.feedType ?? _feedTypes.first;
    _dcNumberController.text = existing?.dcNumber ?? '';
    _batchNumberController.text = existing?.batchNumber ?? '';
    _bagsController.text = existing?.bags.toString() ?? '';
    _weightPerBagController.text = existing?.weightPerBagKg.toString() ?? '75';
    _supplierController.text = existing?.supplierName ?? '';
    _notesController.text = existing?.notes ?? '';
  }

  @override
  void dispose() {
    _dcNumberController.dispose();
    _batchNumberController.dispose();
    _bagsController.dispose();
    _weightPerBagController.dispose();
    _supplierController.dispose();
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
      final bags = int.tryParse(_bagsController.text.trim()) ?? 0;
      final weightPerBag =
          double.tryParse(_weightPerBagController.text.trim()) ?? 0;
      final totalKg = bags > 0 && weightPerBag > 0
          ? (bags * weightPerBag).toDouble()
          : 0.0;

      if (bags <= 0) {
        throw Exception('Bags must be greater than zero.');
      }

      await FeedService.createFeedTransaction(
        farmId: widget.farmId,
        batchId: widget.batchId,
        transactionDate: _selectedDate,
        transactionType: 'received',
        feedType: _selectedFeedType,
        feedBatchNumber: _batchNumberController.text.trim().isEmpty
            ? null
            : _batchNumberController.text.trim(),
        dcNumber: _dcNumberController.text.trim().isEmpty
            ? null
            : _dcNumberController.text.trim(),
        bags: bags,
        weightPerBagKg: weightPerBag,
        totalKg: totalKg,
        supplierOrSource: _supplierController.text.trim().isEmpty
            ? null
            : _supplierController.text.trim(),
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
              Text('Feed receipt saved'),
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
          widget.batchName != null
              ? 'Feed Receipt • ${widget.batchName}'
              : 'Feed Receipt',
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
                  gradient: AppColors.goldGradient,
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
                        Icons.inventory_outlined,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Feed Receipt',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Log feed delivery',
                            style: TextStyle(color: AppColors.surface),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Feed type',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _feedTypes.map((type) {
                  final selected = _selectedFeedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFeedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.goldGradient : null,
                        color: selected ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_outlined,
                            size: 18,
                            color: selected
                                ? AppColors.surface
                                : AppColors.gold,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.surface
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
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
              _textField(_dcNumberController, 'DC / Delivery Challan No.'),
              const SizedBox(height: 14),
              _textField(_batchNumberController, 'Batch/Lot No.'),
              const SizedBox(height: 14),
              _textField(
                _bagsController,
                'Bags',
                keyboardType: TextInputType.numberWithOptions(decimal: false),
                formatter: FilteringTextInputFormatter.allow(RegExp(r'[\d]')),
              ),
              const SizedBox(height: 14),
              _textField(
                _weightPerBagController,
                'Weight per bag (kg)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                formatter: FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Text(
                  'Total: ${_calculateTotalKg()} kg',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _textField(_supplierController, 'Supplier Name'),
              const SizedBox(height: 14),
              _textField(_notesController, 'Notes', maxLines: 3),
              const SizedBox(height: 22),
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
                    : const Text('Save Receipt'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotalKg() {
    final bags = int.tryParse(_bagsController.text.trim()) ?? 0;
    final weightPerBag =
        double.tryParse(_weightPerBagController.text.trim()) ?? 0;
    return bags > 0 && weightPerBag > 0 ? bags * weightPerBag : 0;
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
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
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      validator: (value) {
        if (label.contains('Bags')) {
          final parsed = int.tryParse(value?.trim() ?? '') ?? 0;
          return parsed > 0 ? null : 'Required';
        }
        return null;
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString()}';
  }
}
