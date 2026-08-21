import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/widgets/app_button.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.content,
    this.icon,
    this.iconColor,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDanger = false,
    this.isLoading = false,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget? content;
  final IconData? icon;
  final Color? iconColor;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDanger;
  final bool isLoading;
  final List<Widget>? actions;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        subtitle: message,
        icon: icon,
        isDanger: isDanger,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveIconColor = iconColor ??
        (isDanger ? AppColors.danger : (isDark ? AppColors.primaryLight : AppColors.primary));

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 28),
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: content!)),
            ],
            const SizedBox(height: 24),
            if (actions != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              )
            else
              Row(
                children: [
                  if (onCancel != null) ...[
                    Expanded(
                      child: AppButton(
                        label: cancelLabel,
                        onPressed: onCancel,
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.medium,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (onConfirm != null)
                    Expanded(
                      child: AppButton(
                        label: confirmLabel,
                        onPressed: onConfirm,
                        variant: isDanger
                            ? AppButtonVariant.danger
                            : AppButtonVariant.primary,
                        size: AppButtonSize.medium,
                        isLoading: isLoading,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
