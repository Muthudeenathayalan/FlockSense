import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/app_text_field.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.validator,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final bool obscureText;
  final bool enabled;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      onChanged: onChanged,
      validator: validator,
      showObscureToggle: obscureText,
    );
  }
}
