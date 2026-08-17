import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/reports/data/report_export_handler.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({
    super.key,
    required this.reportType,
    required this.data,
  });

  final ReportType reportType;
  final ReportData data;

  static Future<void> show(
    BuildContext context, {
    required ReportType reportType,
    required ReportData data,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ExportDialog(reportType: reportType, data: data),
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
            content: Text('Report generated successfully: ${file.path.split('/').last}'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.reportType.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.reportType.icon, color: widget.reportType.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Export ${widget.reportType.title}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select desired export file format:',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          ...ExportFormat.values.map((format) {
            final isSelected = _selectedFormat == format;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: RadioListTile<ExportFormat>(
                value: format,
                groupValue: _selectedFormat,
                onChanged: _isGenerating
                    ? null
                    : (val) {
                        if (val != null) setState(() => _selectedFormat = val);
                      },
                title: Text(
                  format.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                secondary: Icon(format.icon, color: isSelected ? AppColors.primary : AppColors.textHint, size: 20),
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        OutlinedButton.icon(
          onPressed: _isGenerating ? null : () => _handleAction(true),
          icon: const Icon(Icons.share_outlined, size: 16),
          label: const Text('Share'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : () => _handleAction(false),
          icon: _isGenerating
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.download_rounded, size: 16),
          label: Text(_isGenerating ? 'Generating...' : 'Save File'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.reportType.color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
