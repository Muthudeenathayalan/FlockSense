import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';
import 'package:flock_sense/features/inventory/presentation/providers/inventory_providers.dart';

class InventoryItemFormScreen extends ConsumerStatefulWidget {
  const InventoryItemFormScreen({super.key, this.existingItem});

  final InventoryItemModel? existingItem;

  @override
  ConsumerState<InventoryItemFormScreen> createState() =>
      _InventoryItemFormScreenState();
}

class _InventoryItemFormScreenState
    extends ConsumerState<InventoryItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _supplierController;
  late TextEditingController _quantityController;
  late TextEditingController _minStockController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _storageLocationController;
  late TextEditingController _batchNumberController;
  late TextEditingController _notesController;

  String _category = 'Feed';
  String _unit = 'kg';
  DateTime _purchaseDate = DateTime.now();
  DateTime? _expiryDate;
  bool _isSaving = false;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;

    _nameController = TextEditingController(text: item?.itemName ?? '');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _supplierController = TextEditingController(text: item?.supplier ?? '');
    _quantityController = TextEditingController(
      text: item != null ? item.quantityAvailable.toString() : '',
    );
    _minStockController = TextEditingController(
      text: item != null ? item.minStockLevel.toString() : '10',
    );
    _purchasePriceController = TextEditingController(
      text: item != null ? item.purchasePrice.toString() : '',
    );
    _sellingPriceController = TextEditingController(
      text: item?.sellingPrice != null ? item!.sellingPrice.toString() : '',
    );
    _storageLocationController = TextEditingController(
      text: item?.storageLocation ?? 'Main Store',
    );
    _batchNumberController = TextEditingController(
      text: item?.batchNumber ?? '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');

    if (item != null) {
      _category = item.category;
      _unit = item.unit;
      _purchaseDate = item.purchaseDate;
      _expiryDate = item.expiryDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _supplierController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _storageLocationController.dispose();
    _batchNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingItem != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Inventory Item' : 'Add Inventory Item'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Selection
              const Text(
                'Item Category *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'Feed', child: Text('Feed')),
                  DropdownMenuItem(value: 'Medicine', child: Text('Medicine')),
                  DropdownMenuItem(value: 'Vaccines', child: Text('Vaccines')),
                  DropdownMenuItem(
                    value: 'Equipment',
                    child: Text('Equipment'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _category = val;
                      _unit = _defaultUnitForCategory(val);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Item Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g. Starter Feed, Amoxicillin 10%',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please enter item name'
                    : null,
              ),
              const SizedBox(height: 14),

              // Brand & Supplier
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        labelText: 'Brand / Manufacturer',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _supplierController,
                      decoration: InputDecoration(
                        labelText: 'Supplier Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quantity & Unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Quantity Available *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Enter quantity';
                        final q = double.tryParse(val.trim());
                        if (q == null || q < 0) return 'Invalid quantity';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: InputDecoration(
                        labelText: 'Unit *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(
                          value: 'Liters',
                          child: Text('Liters'),
                        ),
                        DropdownMenuItem(value: 'Bags', child: Text('Bags')),
                        DropdownMenuItem(value: 'Doses', child: Text('Doses')),
                        DropdownMenuItem(
                          value: 'Pieces',
                          child: Text('Pieces'),
                        ),
                        DropdownMenuItem(value: 'Units', child: Text('Units')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _unit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Minimum Stock Level & Storage Location
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Min Stock Level *',
                        helperText: 'Alert badge threshold',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Enter min stock';
                        final m = double.tryParse(val.trim());
                        if (m == null || m < 0) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _storageLocationController,
                      decoration: InputDecoration(
                        labelText: 'Storage Location *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Enter location'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Purchase Price & Selling Price
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Purchase Price (₹) *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Enter price';
                        final p = double.tryParse(val.trim());
                        if (p == null || p < 0) return 'Invalid price';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Selling Price (₹)',
                        helperText: 'Optional',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Dates: Purchase Date & Expiry Date
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _purchaseDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null)
                          setState(() => _purchaseDate = picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Purchase Date *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        child: Text(_dateFormat.format(_purchaseDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _expiryDate ??
                              DateTime.now().add(const Duration(days: 180)),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 30),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked != null)
                          setState(() => _expiryDate = picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Expiry Date',
                          helperText: 'Optional',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: _expiryDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () =>
                                      setState(() => _expiryDate = null),
                                )
                              : null,
                        ),
                        child: Text(
                          _expiryDate != null
                              ? _dateFormat.format(_expiryDate!)
                              : 'None',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Batch Number & Notes
              TextFormField(
                controller: _batchNumberController,
                decoration: InputDecoration(
                  labelText: 'Batch / Lot Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes / Remarks',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveItem,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isEdit ? 'Update Item' : 'Save Item to Inventory',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _defaultUnitForCategory(String category) {
    switch (category) {
      case 'Feed':
        return 'kg';
      case 'Medicine':
        return 'Units';
      case 'Vaccines':
        return 'Doses';
      case 'Equipment':
      default:
        return 'Pieces';
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = ref.read(authStateProvider).value;
      final activeFarmId = ref.read(activeFarmIdProvider).value;

      if (user == null || activeFarmId == null) {
        throw Exception('User or farm session not found.');
      }

      final service = ref.read(inventoryServiceProvider);

      final item = InventoryItemModel(
        id: widget.existingItem?.id ?? '',
        farmId: activeFarmId,
        ownerId: user.uid,
        itemName: _nameController.text.trim(),
        category: _category,
        brand: _brandController.text.trim(),
        supplier: _supplierController.text.trim(),
        quantityAvailable: double.parse(_quantityController.text.trim()),
        unit: _unit,
        minStockLevel: double.parse(_minStockController.text.trim()),
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
        purchasePrice: double.parse(_purchasePriceController.text.trim()),
        sellingPrice: _sellingPriceController.text.trim().isNotEmpty
            ? double.tryParse(_sellingPriceController.text.trim())
            : null,
        storageLocation: _storageLocationController.text.trim(),
        batchNumber: _batchNumberController.text.trim().isNotEmpty
            ? _batchNumberController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingItem == null) {
        await service.addInventoryItem(item);
      } else {
        await service.updateInventoryItem(item);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingItem == null
                  ? 'Inventory item added successfully!'
                  : 'Inventory item updated successfully!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving item: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
