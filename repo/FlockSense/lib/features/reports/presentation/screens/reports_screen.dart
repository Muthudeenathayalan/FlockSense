import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/features/performance/presentation/screens/batch_performance_screen.dart';
import 'package:flock_sense/features/reports/data/pdf_generator.dart';
import 'package:flock_sense/features/reports/data/report_service.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    required this.batchName,
  });

  final String farmId;
  final String batchId;
  final String batchName;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  String? _error;
  ReportData? _reportData;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reportData = await ReportService.loadReportData(
        farmId: widget.farmId,
        batchId: widget.batchId,
      );
      if (!mounted) return;
      setState(() {
        _reportData = reportData;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('ReportsScreen._loadData failed: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load report data. Please try again.';
      });
    }
  }

  Future<void> _generateAndSharePdf() async {
    if (_reportData == null) return;
    setState(() => _isLoading = true);
    try {
      _pdfBytes = await PdfGenerator.generateFarmRecord(_reportData!);
      final filename =
          '${widget.batchName.replaceAll(' ', '_')}_farm_record.pdf';
      final file = XFile.fromData(
        _pdfBytes!,
        name: filename,
        mimeType: 'application/pdf',
      );
      await Share.shareXFiles([file], text: 'FlockSense Farm Record');
    } catch (error) {
      debugPrint('ReportsScreen._generateAndSharePdf failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate report.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _printPdf() async {
    if (_reportData == null) return;
    setState(() => _isLoading = true);
    try {
      _pdfBytes ??= await PdfGenerator.generateFarmRecord(_reportData!);
      await Printing.layoutPdf(onLayout: (_) => _pdfBytes!);
    } catch (error) {
      debugPrint('ReportsScreen._printPdf failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open print dialog.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _viewPerformance() {
    if (_reportData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BatchPerformanceScreen(
          farmId: widget.farmId,
          batchId: widget.batchId,
          batchName: widget.batchName,
          batch: _reportData!.batch,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Reports — ${widget.batchName}'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 20),
              _buildActionCard(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Complete SKM Farm Record',
                subtitle:
                    'All pages including performance, feed, medicine, sales',
                gradient: AppColors.primaryGradient,
                buttonLabel: 'Generate PDF',
                onTap: _generateAndSharePdf,
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.analytics_outlined,
                title: 'Batch Performance Report',
                subtitle:
                    'FCR, body weight, mortality charts and weekly summary',
                gradient: AppColors.goldGradient,
                buttonLabel: 'View Performance',
                onTap: _viewPerformance,
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.share_outlined,
                title: 'Print or Share',
                subtitle: 'Open in system print dialog or share via any app',
                gradient: AppColors.emeraldGradient,
                buttonLabel: 'Print Report',
                onTap: _printPdf,
              ),
              const SizedBox(height: 24),
              if (_reportData != null) _buildSummaryChips(_reportData!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: const [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Preparing report data...',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Icon(Icons.error_outline, color: AppColors.danger),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unable to load report data.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reportData != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ready to generate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Batch: ${widget.batchName}\nFarm: ${_reportData!.farm.farmName}\nRecords: ${_reportData!.dailyRecords.length}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'No report data available yet.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChips(ReportData data) {
    final dateFormat = DateFormat.yMMMd();
    final chips = [
      '${data.dailyRecords.length} daily records',
      '${data.feedTransactions.length} feed receipts',
      '${data.medicineRecords.length} medicines',
      '${data.vaccineRecords.length} vaccines',
      '${data.birdSales.length} sales',
      'Generated ${dateFormat.format(data.generatedAt)}',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chips
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
