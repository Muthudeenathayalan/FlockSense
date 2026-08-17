import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';
import 'package:flock_sense/features/inventory/domain/stock_movement_model.dart';
import 'package:flock_sense/features/inventory/presentation/providers/inventory_providers.dart';

class StockMovementDialog extends ConsumerStatefulWidget {
  const StockMovementDialog({
    super.key,
    required this.item,
    required this.action, // 'increase', 'reduce', 'transfer'
  });

  final InventoryItemModel item;
  final String action;

  @override
  ConsumerState<StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends ConsumerState<StockMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _supplierController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _targetLocationController = TextEditingController();
  final _notesController = TextEditingController();

  String _reason = 'purchase';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _supplierController.text = widget.item.supplier;
    if (widget.action == 'increase') {
      _reason = 'purchase';
    } else if (widget.action == 'reduce') {
      _reason = widget.item.category == 'Feed'
          ? 'feedUsed'
          : (widget.item.category == 'Medicine' ? 'medicineUsed' : 'vaccination');
    } else if (widget.action == 'transfer') {
      _reason = 'transfer';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _supplierController.dispose();
    _invoiceController.dispose();
    _targetLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.action == 'increase'
        ? 'Increase Stock (+)'
        : (widget.action == 'reduce' ? 'Reduce Stock (-)' : 'Transfer Stock (⇄)');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Item: ${widget.item.itemName} (${widget.item.quantityAvailable} ${widget.item.unit} currently available)',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Quantity Field
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantity to ${widget.action} *',
                  suffixText: widget.item.unit,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter quantity';
                  final qty = double.tryParse(val.trim());
                  if (qty == null || qty <= 0) return 'Enter a valid positive number';
                  if ((widget.action == 'reduce' || widget.action == 'transfer') &&
                      qty > widget.item.quantityAvailable) {
                    return 'Quantity exceeds available stock (${widget.item.quantityAvailable})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Reason Dropdown
              DropdownButtonFormField<String>(
                value: _reason,
                decoration: InputDecoration(
                  labelText: 'Reason *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _getReasonOptions(),
                onChanged: (val) {
                  if (val != null) setState(() => _reason = val);
                },
              ),

              if (widget.action == 'increase') ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _supplierController,
                  decoration: InputDecoration(
                    labelText: 'Supplier',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _invoiceController,
                  decoration: InputDecoration(
                    labelText: 'Invoice / DC Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],

              if (widget.action == 'transfer') ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _targetLocationController,
                  decoration: InputDecoration(
                    labelText: 'Target Shed / Location *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter target location';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes / Remarks',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.action == 'increase'
                ? AppColors.primary
                : (widget.action == 'reduce' ? AppColors.danger : const Color(0xFF00838F)),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _getReasonOptions() {
    if (widget.action == 'increase') {
      return const [
        DropdownMenuItem(value: 'purchase', child: Text('Purchase / Restock')),
        DropdownMenuItem(value: 'return', child: Text('Stock Return')),
        DropdownMenuItem(value: 'adjustment', child: Text('Audit Adjustment')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ];
    } else if (widget.action == 'reduce') {
      return const [
        DropdownMenuItem(value: 'feedUsed', child: Text('Feed Consumed')),
        DropdownMenuItem(value: 'medicineUsed', child: Text('Medicine Applied')),
        DropdownMenuItem(value: 'vaccination', child: Text('Vaccination Administered')),
        DropdownMenuItem(value: 'damaged', child: Text('Damaged / Spilled')),
        DropdownMenuItem(value: 'expired', child: Text('Expired Disposal')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ];
    } else {
      return const [
        DropdownMenuItem(value: 'transfer', child: Text('Transfer to Shed/Location')),
        DropdownMenuItem(value: 'other', child: Text('Other Transfer')),
      ];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final qty = double.parse(_quantityController.text.trim());
      final service = ref.read(inventoryServiceProvider);

      final movement = StockMovementModel(
        id: '',
        inventoryItemId: widget.item.id,
        farmId: widget.item.farmId,
        ownerId: widget.item.ownerId,
        action: widget.action,
        quantity: qty,
        reason: _reason,
        date: DateTime.now(),
        supplier: _supplierController.text.trim(),
        invoiceNumber: _invoiceController.text.trim(),
        targetLocation: _targetLocationController.text.trim(),
        userName: 'User Log',
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await service.recordStockMovement(
        uid: widget.item.ownerId,
        farmId: widget.item.farmId,
        movement: movement,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock ${widget.action} recorded successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update stock: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
