import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/app_button.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: AppButtonVariant.primary,
      width: double.infinity,
    );
  }
}

