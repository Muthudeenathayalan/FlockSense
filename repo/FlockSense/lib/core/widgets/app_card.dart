import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

enum AppCardVariant {
  surface,
  flat,
  outlined,
  gradient,
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.elevation = 0,
    this.borderRadius = 20,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.variant = AppCardVariant.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? borderColor;
  final LinearGradient? gradient;
  final AppCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    BorderSide borderSide;
    List<BoxShadow>? shadows;

    switch (variant) {
      case AppCardVariant.surface:
        bg = backgroundColor ?? (isDark ? AppColors.darkSurface : AppColors.surface);
        borderSide = BorderSide(
          color: borderColor ?? (isDark ? AppColors.darkBorder : AppColors.border),
          width: 0.8,
        );
        shadows = elevation > 0 || !isDark
            ? [
                BoxShadow(
                  color: isDark ? Colors.black26 : AppColors.shadow,
                  blurRadius: elevation > 0 ? elevation * 4 : 10,
                  offset: Offset(0, elevation > 0 ? elevation : 3),
                ),
              ]
            : null;
        break;

      case AppCardVariant.flat:
        bg = backgroundColor ?? (isDark ? AppColors.darkSurfaceSoft : AppColors.surfaceSoft);
        borderSide = BorderSide.none;
        shadows = null;
        break;

      case AppCardVariant.outlined:
        bg = backgroundColor ?? Colors.transparent;
        borderSide = BorderSide(
          color: borderColor ?? (isDark ? AppColors.darkBorder : AppColors.border),
          width: 1.2,
        );
        shadows = null;
        break;

      case AppCardVariant.gradient:
        bg = Colors.transparent;
        borderSide = borderColor != null
            ? BorderSide(color: borderColor!, width: 0.8)
            : BorderSide.none;
        shadows = const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ];
        break;
    }

    final effectiveGradient =
        variant == AppCardVariant.gradient ? (gradient ?? AppColors.cardGradient) : null;

    final cardDecoration = BoxDecoration(
      color: effectiveGradient == null ? bg : null,
      gradient: effectiveGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
      boxShadow: shadows,
    );


    if (onTap == null && onLongPress == null) {
      return Container(
        margin: margin,
        decoration: cardDecoration,
        child: Padding(padding: padding, child: child),
      );
    }

    return Container(
      margin: margin,
      decoration: cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

