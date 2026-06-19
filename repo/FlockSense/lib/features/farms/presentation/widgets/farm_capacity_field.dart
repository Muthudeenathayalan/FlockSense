import 'package:flutter/material.dart';

class FarmCapacityField extends StatelessWidget {
  const FarmCapacityField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.validator,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      validator: validator,
      decoration: InputDecoration(
        labelText: 'Bird capacity',
        hintText: 'Enter total birds',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
