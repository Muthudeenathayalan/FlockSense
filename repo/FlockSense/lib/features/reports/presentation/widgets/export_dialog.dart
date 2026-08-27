import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/features/reports/data/report_export_handler.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key, required this.reportType, required this.data});

  final ReportType reportType;
  final ReportData data;

  static Future<void> show(
    BuildContext context, {
    required ReportType reportType,
    required ReportData data,
  }) {
    return AppDialog.show(
      context: context,
      child: ExportDialog(reportType: reportType, data: data),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _isGenerating = false;

  Future<void> _handleAction(bool isShare) async {
    setState(() => _isGenerating = true);
    try {
      if (isShare) {
        await ReportExportHandler.shareReport(
          data: widget.data,
          reportType: widget.reportType,
          format: _selectedFormat,
        );
      } else {
        final file = await ReportExportHandler.generateAndSaveFile(
          data: widget.data,
          reportType: widget.reportType,
          format: _selectedFormat,
        );
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report generated successfully: ${file.path.split('/').last}',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Export failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppDialog(
      title: 'Export ${widget.reportType.title}',
      icon: widget.reportType.icon,
      iconColor: widget.reportType.color,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select desired export file format:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ...ExportFormat.values.map((format) {
            final isSelected = _selectedFormat == format;
            return AppCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.zero,
              borderColor: isSelected ? AppColors.primary : null,
              child: RadioListTile<ExportFormat>(
                value: format,
                groupValue: _selectedFormat,
                activeColor: AppColors.primary,
                onChanged: _isGenerating
                    ? null
                    : (val) {
                        if (val != null) setState(() => _selectedFormat = val);
                      },
                title: Text(
                  format.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary),
                  ),
                ),
                secondary: Icon(
                  format.icon,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary),
                  size: 20,
                ),
              ),
            );
          }),
        ],
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          variant: AppButtonVariant.text,
          size: AppButtonSize.small,
        ),
        const SizedBox(width: 8),
        AppButton(
          label: 'Share',
          icon: Icons.share_outlined,
          onPressed: _isGenerating ? null : () => _handleAction(true),
          variant: AppButtonVariant.outlined,
          size: AppButtonSize.small,
        ),
        const SizedBox(width: 8),
        AppButton(
          label: _isGenerating ? 'Saving...' : 'Save File',
          icon: Icons.download_rounded,
          onPressed: _isGenerating ? null : () => _handleAction(false),
          isLoading: _isGenerating,
          variant: AppButtonVariant.primary,
          size: AppButtonSize.small,
        ),
      ],
    );
  }
}
