import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/reports/data/pdf_generator.dart';
import 'package:flock_sense/features/reports/data/report_history_service.dart';
import 'package:flock_sense/features/reports/data/report_service.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

/// Service responsible for automatically generating, requesting user permission,
/// and saving comprehensive end-to-end batch reports to local phone storage
/// whenever a batch is completed/harvested.
class BatchCompletionReportService {
  BatchCompletionReportService._();

  static const String _prefAutoDownloadKey = 'flocksense_auto_download_report';
  static const String _prefDownloadedBatchesKey =
      'flocksense_downloaded_batch_reports';

  /// Check if auto-download on completion is enabled by the user.
  /// Defaults to null (not yet decided / prompt user on first completion).
  static Future<bool?> isAutoDownloadEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_prefAutoDownloadKey)) return null;
      return prefs.getBool(_prefAutoDownloadKey);
    } catch (_) {
      return null;
    }
  }

  /// Update the user's auto-download preference.
  static Future<void> setAutoDownloadEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefAutoDownloadKey, enabled);
    } catch (e) {
      debugPrint('[BatchCompletionReportService] Error saving preference: $e');
    }
  }

  /// Check if this batch's final report was already downloaded.
  static Future<bool> hasBatchReportBeenDownloaded(String batchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefDownloadedBatchesKey) ?? [];
      return list.contains(batchId);
    } catch (_) {
      return false;
    }
  }

  /// Mark a batch as downloaded so we don't prompt repeatedly.
  static Future<void> markBatchReportDownloaded(String batchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefDownloadedBatchesKey) ?? [];
      if (!list.contains(batchId)) {
        list.add(batchId);
        await prefs.setStringList(_prefDownloadedBatchesKey, list);
      }
    } catch (_) {}
  }

  /// Generates the complete 15-page batch report and writes it to local phone storage.
  static Future<File> saveBatchReportToDevice({
    required String farmId,
    required String batchId,
    required String batchName,
  }) async {
    // 1. Fetch complete authentic batch data
    final reportData = await ReportService.loadReportData(
      farmId: farmId,
      batchId: batchId,
    );

    // 2. Generate the 15-page comprehensive commercial farm record PDF
    final pdfBytes = await PdfGenerator.generateFarmRecord(reportData);

    // 3. Resolve storage directory (Downloads directory preferred on mobile/desktop)
    Directory targetDir;
    try {
      final dlDir = await getDownloadsDirectory();
      targetDir = dlDir ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      try {
        targetDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        targetDir = await getTemporaryDirectory();
      }
    }

    final sanitizedBatch = batchName
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .trim()
        .replaceAll(' ', '_');
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final filename = 'FlockSense_${sanitizedBatch}_Final_Audit_$dateStr.pdf';
    final targetPath = '${targetDir.path}/$filename';
    final file = File(targetPath);

    await file.writeAsBytes(pdfBytes, flush: true);

    // 4. Save to Reports History
    final historyItem = ReportHistoryItem(
      id: 'final_audit_${batchId}_${DateTime.now().millisecondsSinceEpoch}',
      reportType: ReportType.completeFarm,
      reportTitle: 'Complete Batch Final Audit ($batchName)',
      farmName: reportData.farm.farmName,
      batchName: batchName,
      format: ExportFormat.pdf,
      generatedAt: DateTime.now(),
      fileSizeKb: pdfBytes.lengthInBytes / 1024.0,
      filePath: file.path,
    );
    await ReportHistoryService.saveHistoryItem(historyItem);
    await markBatchReportDownloaded(batchId);

    return file;
  }

  /// Prompts user with permission dialog (or auto-saves if consented)
  /// and saves the report to local phone storage.
  static Future<void> promptAndHandleBatchCompletion({
    required BuildContext context,
    required String farmId,
    required String batchId,
    required String batchName,
    bool forcePrompt = false,
  }) async {
    if (!context.mounted) return;

    final alreadyDownloaded = await hasBatchReportBeenDownloaded(batchId);
    if (alreadyDownloaded && !forcePrompt) {
      return;
    }

    final preference = await isAutoDownloadEnabled();

    // If user explicitly configured "Always auto-save" and this is not a forced prompt:
    if (preference == true && !forcePrompt) {
      await _executeDownloadWithFeedback(
        context: context,
        farmId: farmId,
        batchId: batchId,
        batchName: batchName,
      );
      return;
    }

    // Otherwise, show interactive permission & consent dialog
    if (!context.mounted) return;
    bool rememberChoice = preference ?? true;

    final shouldDownload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Flock Harvested! 🎉',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Congratulations on completing "$batchName"!',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Would you like to automatically download and save the complete 15-page End-to-End Batch Audit & Technique Report PDF directly to your phone storage?',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: rememberChoice,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setDialogState(() => rememberChoice = val ?? true);
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Always auto-save final report for finished batches',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (rememberChoice) {
                      setAutoDownloadEnabled(false);
                    }
                    Navigator.pop(ctx, false);
                  },
                  child: const Text(
                    'Not Now',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setAutoDownloadEnabled(rememberChoice);
                    Navigator.pop(ctx, true);
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download to Phone'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldDownload == true && context.mounted) {
      await _executeDownloadWithFeedback(
        context: context,
        farmId: farmId,
        batchId: batchId,
        batchName: batchName,
      );
    }
  }

  static Future<void> _executeDownloadWithFeedback({
    required BuildContext context,
    required String farmId,
    required String batchId,
    required String batchName,
  }) async {
    // Show quick in-progress feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Text('Saving final report for "$batchName" to storage...'),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
      ),
    );

    try {
      final savedFile = await saveBatchReportToDevice(
        farmId: farmId,
        batchId: batchId,
        batchName: batchName,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final fileName = savedFile.path.split(Platform.isWindows ? '\\' : '/').last;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Saved to phone storage: $fileName'),
          duration: const Duration(seconds: 7),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Share / View',
            textColor: Colors.white,
            onPressed: () {
              Share.shareXFiles(
                [XFile(savedFile.path)],
                text: 'FlockSense Final Batch Audit — $batchName',
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not auto-save report: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
