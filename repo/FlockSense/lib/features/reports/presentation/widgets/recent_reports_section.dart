import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';
import 'package:flock_sense/features/reports/presentation/widgets/report_preview_modal.dart';

class RecentReportsSection extends StatelessWidget {
  const RecentReportsSection({
    super.key,
    required this.historyItems,
    required this.reportData,
  });

  final List<ReportHistoryItem> historyItems;
  final ReportData reportData;

  @override
  Widget build(BuildContext context) {
    if (historyItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final recentItems = historyItems.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.history_toggle_off, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Recently Generated Reports',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentItems.length,
            itemBuilder: (context, i) {
              final item = recentItems[i];
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: item.reportType.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.reportType.icon, color: item.reportType.color, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.reportTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.format.name.toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${item.farmName} • ${item.fileSizeKb.toStringAsFixed(0)} KB',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(item.generatedAt),
                          style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                        ),
                        GestureDetector(
                          onTap: () {
                            ReportPreviewModal.show(
                              context,
                              reportType: item.reportType,
                              data: reportData,
                            );
                          },
                          child: const Text(
                            'View Again',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
