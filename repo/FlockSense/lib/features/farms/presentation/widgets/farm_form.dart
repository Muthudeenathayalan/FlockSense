import 'package:flutter/material.dart';
import 'package:flock_sense/shared/widgets/custom_button.dart';
import 'package:flock_sense/shared/widgets/custom_text_field.dart';
import 'package:flock_sense/shared/widgets/error_widget.dart';

class FarmForm extends StatefulWidget {
  final Function(String farmName, String location, String farmType, int totalCapacity) onSubmit;
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
  final _farmNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  String? _selectedFarmType;
  String? _validationError;

  final List<String> _farmTypeOptions = ['Broiler', 'Layer', 'Breeder', 'Mixed'];

  @override
  void dispose() {
    _farmNameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _validationError = null;
    });

    final farmName = _farmNameController.text.trim();
    final location = _locationController.text.trim();
    final farmType = _selectedFarmType;
    final capacityStr = _capacityController.text.trim();

    if (farmName.isEmpty) {
      setState(() {
        _validationError = 'Farm name is required.';
      });
      return;
    }

    if (location.isEmpty) {
      setState(() {
        _validationError = 'Location is required.';
      });
      return;
    }

    if (farmType == null || farmType.isEmpty) {
      setState(() {
        _validationError = 'Please select a farm type.';
      });
      return;
    }

    if (capacityStr.isEmpty) {
      setState(() {
        _validationError = 'Total capacity is required.';
      });
      return;
    }

    final capacity = int.tryParse(capacityStr);
    if (capacity == null || capacity <= 0) {
      setState(() {
        _validationError = 'Please enter a valid capacity number.';
      });
      return;
    }

    widget.onSubmit(farmName, location, farmType.toLowerCase(), capacity);
  }

  @override
  Widget build(BuildContext context) {
    final displayError = _validationError ?? widget.errorMessage;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Setup Your Farm',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about your farm to get started.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            controller: _farmNameController,
            hintText: 'Farm name',
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _locationController,
            hintText: 'Location',
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade700),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButton<String>(
              value: _selectedFarmType,
              isExpanded: true,
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              dropdownColor: Colors.grey.shade900,
              hint: const Text('Select farm type', style: TextStyle(color: Colors.white70)),
              items: _farmTypeOptions.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: widget.isLoading ? null : (value) {
                setState(() {
                  _selectedFarmType = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _capacityController,
            hintText: 'Total bird capacity',
            keyboardType: TextInputType.number,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 24),
          if (displayError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppErrorWidget(message: displayError),
            ),
          if (widget.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            CustomButton(
              label: 'Create Farm',
              onPressed: _submit,
            ),
        ],
      ),
    );
  }
}
