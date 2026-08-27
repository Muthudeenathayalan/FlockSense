import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outlined, text, gradient, danger }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final IconData? trailingIcon;
  final double? width;
  final LinearGradient? gradient;

  double get _height {
    switch (size) {
      case AppButtonSize.small:
        return 40;
      case AppButtonSize.medium:
        return 50;
      case AppButtonSize.large:
        return 56;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppButtonSize.small:
        return 13;
      case AppButtonSize.medium:
        return 15;
      case AppButtonSize.large:
        return 16;
    }
  }

  EdgeInsetsGeometry get _padding {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = (isLoading || isDisabled) ? null : onPressed;

    if (variant == AppButtonVariant.gradient || gradient != null) {
      final effectiveGradient = gradient ?? AppColors.primaryGradient;

      Widget buttonWidget = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isDisabled ? null : effectiveGradient,
            color: isDisabled ? AppColors.border : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: (isDisabled || variant == AppButtonVariant.text)
                ? null
                : const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: InkWell(
            onTap: effectiveOnPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: _height,
              padding: _padding,
              alignment: Alignment.center,
              child: _buildContent(context, Colors.white),
            ),
          ),
        ),
      );

      if (width != null) {
        return SizedBox(width: width, child: buttonWidget);
      }
      return buttonWidget;
    }

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.border,
            disabledForegroundColor: AppColors.textDisabled,
            elevation: 0,
            minimumSize: Size(width ?? 0, _height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: _padding,
          ),
          child: _buildContent(context, Colors.white),
        );
        break;

      case AppButtonVariant.secondary:
        button = FilledButton.tonal(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.surfaceSoft,
            foregroundColor: AppColors.primaryDark,
            disabledBackgroundColor: AppColors.border,
            disabledForegroundColor: AppColors.textDisabled,
            minimumSize: Size(width ?? 0, _height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: _padding,
          ),
          child: _buildContent(context, AppColors.primaryDark),
        );
        break;

      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.textDisabled,
            minimumSize: Size(width ?? 0, _height),
            side: BorderSide(
              color: isDisabled ? AppColors.border : AppColors.border,
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: _padding,
          ),
          child: _buildContent(context, AppColors.primary),
        );
        break;

      case AppButtonVariant.danger:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.border,
            disabledForegroundColor: AppColors.textDisabled,
            elevation: 0,
            minimumSize: Size(width ?? 0, _height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: _padding,
          ),
          child: _buildContent(context, Colors.white),
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.textDisabled,
            minimumSize: Size(width ?? 0, _height),
            padding: _padding,
          ),
          child: _buildContent(context, AppColors.primary),
        );
        break;

      case AppButtonVariant.gradient:
        // Covered above
        button = const SizedBox();
        break;
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }

  Widget _buildContent(BuildContext context, Color defaultColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(defaultColor),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _fontSize + 2),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w700),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: _fontSize + 2),
        ],
      ],
    );
  }
}
