import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/reports/data/pdf_generator.dart';
import 'package:flock_sense/features/reports/data/report_export_handler.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';
import 'package:flock_sense/features/reports/presentation/widgets/export_dialog.dart';

class ReportPreviewModal extends StatefulWidget {
  const ReportPreviewModal({
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
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewModal(reportType: reportType, data: data),
      ),
    );
  }

  @override
  State<ReportPreviewModal> createState() => _ReportPreviewModalState();
}

class _ReportPreviewModalState extends State<ReportPreviewModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ExportFormat _selectedFormat = ExportFormat.pdf;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.reportType.title),
        backgroundColor: widget.reportType.color,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.picture_as_pdf), text: 'PDF Preview'),
            Tab(icon: Icon(Icons.table_rows), text: 'Data Table'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Report',
            onPressed: () {
              ReportExportHandler.shareReport(
                data: widget.data,
                reportType: widget.reportType,
                format: _selectedFormat,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export',
            onPressed: () {
              ExportDialog.show(
                context,
                reportType: widget.reportType,
                data: widget.data,
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. PDF Preview Tab
          PdfPreview(
            build: (format) => PdfGenerator.generatePdfForReportType(
              data: widget.data,
              reportType: widget.reportType,
            ),
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            loadingWidget: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),

          // 2. Data Table Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryHeader(),
                const SizedBox(height: 16),
                _buildDataTable(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: ExportFormat.values.map((fmt) {
                    final isSel = _selectedFormat == fmt;
                    return ChoiceChip(
                      selected: isSel,
                      label: Text(fmt.name.toUpperCase()),
                      selectedColor: widget.reportType.color,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      onSelected: (_) => setState(() => _selectedFormat = fmt),
                    );
                  }).toList(),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ReportExportHandler.shareReport(
                    data: widget.data,
                    reportType: widget.reportType,
                    format: _selectedFormat,
                  );
                },
                icon: const Icon(Icons.share, size: 16),
                label: Text('Share ${_selectedFormat.name.toUpperCase()}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.reportType.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.data.farm.farmName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Batch: ${widget.data.batch.batchName} • ${widget.data.dailyRecords.length} Records',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(
              label: Text('Day', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Closing Birds',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Mortality',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Feed (kg)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Water (L)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Avg Wt (g)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: widget.data.dailyRecords.map((r) {
            return DataRow(
              cells: [
                DataCell(Text('${r.batchAgeDay}')),
                DataCell(Text('${r.recordDate.month}/${r.recordDate.day}')),
                DataCell(Text('${r.closingBirds}')),
                DataCell(Text('${r.mortalityCount}')),
                DataCell(Text('${r.feedConsumedKg}')),
                DataCell(Text('${r.waterConsumedLiters}')),
                DataCell(Text('${r.avgWeightGrams}')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
