import 'package:flutter/material.dart';

class FlockTypeDropdown extends StatelessWidget {
  const FlockTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final String? value;
  final ValueChanged<String?>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  static const _options = ['Broiler', 'Layer', 'Breeder', 'Mixed'];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Flock type',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dropdownColor: Colors.white,
      items: _options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      validator: validator,
      onChanged: enabled ? onChanged : null,
    );
  }
}
