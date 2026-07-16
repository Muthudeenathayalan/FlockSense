import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

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
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: secondary ? AppColors.surface : AppColors.primary,
        foregroundColor: secondary ? AppColors.textPrimary : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: secondary ? 0 : 2,
        side: secondary
            ? const BorderSide(color: AppColors.border)
            : BorderSide.none,
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: secondary ? AppColors.primary : Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
    );
  }
}
