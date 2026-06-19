import 'package:flutter/material.dart';

class FarmTypeDropdown extends StatelessWidget {
  const FarmTypeDropdown({
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

  static const _farmTypeOptions = ['EC', 'Open'];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'Farm type',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dropdownColor: Colors.white,
      items: _farmTypeOptions
          .map(
            (type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            ),
          )
          .toList(),
      validator: validator,
      onChanged: enabled ? onChanged : null,
    );
  }
}
