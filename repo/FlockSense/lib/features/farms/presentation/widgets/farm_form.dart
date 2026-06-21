import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/primary_button.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_capacity_field.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_type_dropdown.dart';
import 'package:flock_sense/features/farms/presentation/widgets/flock_type_dropdown.dart';
import 'package:flock_sense/shared/widgets/error_widget.dart';

class FarmForm extends StatefulWidget {
  final Function(
    String farmName,
    String farmType,
    String flockType,
    String address,
    int birdCapacity,
    String? district,
    String? state,
    double? lengthFt,
    double? widthFt,
    String? notes,
  ) onSubmit;
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
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _capacityController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedFarmType;
  String? _selectedFlockType;
  String? _validationError;
  String? _selectedDistrict;
  String? _selectedState;

  @override
  void dispose() {
    _farmNameController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _capacityController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
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
    final district = _selectedDistrict ?? '';
    final state = _selectedState ?? '';
    final address = _addressController.text.trim();
    final farmType = _selectedFarmType;
    final flockType = _selectedFlockType;
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;
    final length = double.tryParse(_lengthController.text.trim());
    final width = double.tryParse(_widthController.text.trim());
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

    if (_selectedDistrict == null || _selectedDistrict!.isEmpty) {
      debugPrint('[FarmForm] District not selected');
      setState(() {
        _validationError = 'Please select a district.';
      });
      return;
    }

    if (_selectedState == null || _selectedState!.isEmpty) {
      debugPrint('[FarmForm] State not selected');
      setState(() {
        _validationError = 'Please select a state.';
      });
      return;
    }

    debugPrint('[FarmForm] Submitting farm data: farmName=$farmName, farmType=$farmType, flockType=$flockType, address=$address, capacity=$capacity, district=$district, state=$state');
    widget.onSubmit(
      farmName,
      farmType,
      flockType!,
      address,
      capacity,
      district.isNotEmpty ? district : null,
      state.isNotEmpty ? state : null,
      length,
      width,
      notes.isNotEmpty ? notes : null,
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
            Text('Create Farm', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Add your farm details below to get started quickly.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
            const SizedBox(height: 24),
            AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Farm information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                Text('Location', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                  decoration: const InputDecoration(labelText: 'Address', hintText: 'Street or farm location'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: const InputDecoration(labelText: 'District'),
                  items: [
                    'Ariyalur',
                    'Chengalpattu',
                    'Chennai',
                    'Coimbatore',
                    'Cuddalore',
                    'Dharmapuri',
                    'Dindigul',
                    'Erode',
                    'Kallakurichi',
                    'Kanchipuram',
                    'Karur',
                    'Krishnagiri',
                    'Madurai',
                    'Mayiladuthurai',
                    'Nagapattinam',
                    'Namakkal',
                    'Perambalur',
                    'Pudukkottai',
                    'Ramanathapuram',
                    'Ranipet',
                    'Salem',
                    'Sivaganga',
                    'Tenkasi',
                    'Thanjavur',
                    'Theni',
                    'Thoothukudi',
                    'Tiruchirappalli',
                    'Tirunelveli',
                    'Tirupathur',
                    'Tiruvallur',
                    'Tiruvannamalai',
                    'Tiruvarur',
                    'Vellore',
                    'Viluppuram',
                    'Virudhunagar',
                  ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: widget.isLoading
                      ? null
                      : (v) {
                          setState(() {
                            _selectedDistrict = v;
                          });
                        },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedState,
                  decoration: const InputDecoration(labelText: 'State'),
                  items: ['Tamil Nadu']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: widget.isLoading
                      ? null
                      : (v) {
                          setState(() {
                            _selectedState = v;
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
                Text('Farm details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                FarmCapacityField(
                  controller: _capacityController,
                  enabled: !widget.isLoading,
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (value == null || value.trim().isEmpty) {
                      return 'Bird capacity is required.';
                    }
                    if (parsed == null || parsed <= 0) {
                      return 'Please enter a valid number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lengthController,
                        enabled: !widget.isLoading,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Length (ft)'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _widthController,
                        enabled: !widget.isLoading,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Width (ft)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Optional. Add farm footprint details for future planning.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Additional notes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
            PrimaryButton(label: 'Save farm', onPressed: _submit, isLoading: widget.isLoading),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
