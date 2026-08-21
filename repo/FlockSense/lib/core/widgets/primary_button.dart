import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/app_button.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: secondary ? AppButtonVariant.outlined : AppButtonVariant.primary,
      width: double.infinity,
    );
  }
}

