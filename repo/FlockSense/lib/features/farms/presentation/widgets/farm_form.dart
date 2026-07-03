import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/primary_button.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_type_dropdown.dart';
import 'package:flock_sense/features/farms/presentation/widgets/flock_type_dropdown.dart';
import 'package:flock_sense/shared/widgets/error_widget.dart';

class FarmForm extends StatefulWidget {
  final Function(
    String farmName,
    String farmType,
    String flockType,
    String address,
    String? areaName,
    String? district,
    String? state,
    String? farmerName,
    String? phoneNumber,
    String? notes,
    double lengthFt,
    double widthFt,
    int? capacity,
  )
  onSubmit;
  final bool isLoading;
  final String? errorMessage;

  const FarmForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<FarmForm> createState() => _FarmFormState();
}

class _FarmFormState extends State<FarmForm> {
  final _formKey = GlobalKey<FormState>();
  final _farmNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaNameController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController(text: 'Tamil Nadu');
  final _farmerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _capacityController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedFarmType;
  String? _selectedFlockType;
  String? _validationError;

  @override
  void dispose() {
    _farmNameController.dispose();
    _addressController.dispose();
    _areaNameController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _farmerNameController.dispose();
    _phoneController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    debugPrint('[FarmForm] Save button pressed');
    setState(() {
      _validationError = null;
    });

    if (!_formKey.currentState!.validate()) {
      debugPrint('[FarmForm] Form validation failed');
      return;
    }

    debugPrint('[FarmForm] Form validation passed');
    final farmName = _farmNameController.text.trim();
    final address = _addressController.text.trim();
    final farmType = _selectedFarmType;
    final flockType = _selectedFlockType;
    final notes = _notesController.text.trim();

    if (farmType == null || farmType.isEmpty) {
      debugPrint('[FarmForm] Farm type not selected');
      setState(() {
        _validationError = 'Please select a farm type.';
      });
      return;
    }

    if (flockType == null || flockType.isEmpty) {
      debugPrint('[FarmForm] Flock type not selected');
      setState(() {
        _validationError = 'Please select a flock type.';
      });
      return;
    }

    final areaName = _areaNameController.text.trim();
    final district = _districtController.text.trim();
    final state = _stateController.text.trim();
    final farmerName = _farmerNameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final lengthFt = double.tryParse(_lengthController.text.trim()) ?? 0.0;
    final widthFt = double.tryParse(_widthController.text.trim()) ?? 0.0;
    final capacity = int.tryParse(_capacityController.text.trim());

    debugPrint(
      '[FarmForm] Submitting farm data: farmName=$farmName, farmType=$farmType, flockType=$flockType, address=$address, areaName=$areaName, district=$district, lengthFt=$lengthFt, widthFt=$widthFt',
    );
    widget.onSubmit(
      farmName,
      farmType,
      flockType,
      address,
      areaName.isNotEmpty ? areaName : null,
      district.isNotEmpty ? district : null,
      state.isNotEmpty ? state : null,
      farmerName.isNotEmpty ? farmerName : null,
      phoneNumber.isNotEmpty ? phoneNumber : null,
      notes.isNotEmpty ? notes : null,
      lengthFt,
      widthFt,
      capacity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayError = _validationError ?? widget.errorMessage;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Farm',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your farm details below to get started quickly.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Farm information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _farmNameController,
                    enabled: !widget.isLoading,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Farm name is required.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(labelText: 'Farm name'),
                  ),
                  const SizedBox(height: 16),
                  FarmTypeDropdown(
                    value: _selectedFarmType,
                    enabled: !widget.isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a farm type.';
                      }
                      return null;
                    },
                    onChanged: widget.isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _selectedFarmType = value;
                            });
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _addressController,
                    enabled: !widget.isLoading,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Address is required.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Street or farm location',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _areaNameController,
                    enabled: !widget.isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Area name',
                      hintText: 'e.g., Kovilpatti',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _districtController,
                    enabled: !widget.isLoading,
                    decoration: const InputDecoration(
                      labelText: 'District',
                      hintText: 'e.g., Madurai',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _stateController,
                    enabled: !widget.isLoading,
                    decoration: const InputDecoration(
                      labelText: 'State',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Farm contact',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _farmerNameController,
                    enabled: !widget.isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Farmer / Owner name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    enabled: !widget.isLoading,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: '+91XXXXXXXXXX',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Farm area',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _lengthController,
                    enabled: !widget.isLoading,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Length (ft)',
                      hintText: 'e.g., 120.5',
                    ),
                    validator: (value) {
                      final number = double.tryParse(value?.trim() ?? '');
                      if (number == null || number <= 0) {
                        return 'Length must be greater than zero.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _widthController,
                    enabled: !widget.isLoading,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Width (ft)',
                      hintText: 'e.g., 65.0',
                    ),
                    validator: (value) {
                      final number = double.tryParse(value?.trim() ?? '');
                      if (number == null || number <= 0) {
                        return 'Width must be greater than zero.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    enabled: !widget.isLoading,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Optional bird capacity',
                      hintText: 'e.g., 1200',
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) return null;
                      final number = int.tryParse(value!.trim());
                      if (number == null || number <= 0) {
                        return 'Enter a valid capacity number.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Flock details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FlockTypeDropdown(
                    value: _selectedFlockType,
                    enabled: !widget.isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please select a flock type.';
                      return null;
                    },
                    onChanged: widget.isLoading
                        ? null
                        : (v) {
                            setState(() {
                              _selectedFlockType = v;
                            });
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Additional notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _notesController,
                    enabled: !widget.isLoading,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Optional farm notes',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (displayError != null) AppErrorWidget(message: displayError),
            PrimaryButton(
              label: 'Save farm',
              onPressed: _submit,
              isLoading: widget.isLoading,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
