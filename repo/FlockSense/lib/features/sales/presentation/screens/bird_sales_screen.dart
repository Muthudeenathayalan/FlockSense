import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/sales/data/sales_service.dart';
import 'package:flock_sense/features/sales/domain/sales_record_model.dart';
import 'package:flock_sense/features/sales/presentation/screens/sales_form_screen.dart';

class BirdSalesScreen extends StatefulWidget {
  const BirdSalesScreen({super.key, this.farmId, this.batchId, this.batchName});

  final String? farmId;
  final String? batchId;
  final String? batchName;

  @override
  State<BirdSalesScreen> createState() => _BirdSalesScreenState();
}

class _BirdSalesScreenState extends State<BirdSalesScreen> {
  bool get _hasContext =>
      (widget.farmId?.isNotEmpty ?? false) &&
      (widget.batchId?.isNotEmpty ?? false);

  Future<void> _confirmDelete(SalesRecordModel record) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Delete Sale Record',
      message:
          'Are you sure you want to delete this sale of ${record.birdsSold} birds? The sold bird count will be restored to the live batch.',
      confirmLabel: 'Delete & Restore Flock',
      isDanger: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;

    try {
      await SalesService.deleteSalesRecord(
        widget.farmId!,
        widget.batchId!,
        record.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale deleted. Restored bird count to flock.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasContext) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            widget.batchName == null ? 'Sales' : 'Sales • ${widget.batchName}',
          ),
        ),
        body: const Center(
          child: Text('Open sales from a batch to record transactions.'),
        ),
      );
    }

    return StreamBuilder<BatchModel?>(
      stream: BatchService.watchBatch(widget.farmId!, widget.batchId!),
      builder: (context, batchSnap) {
        final batch = batchSnap.data;
        final ageDays = batch != null
            ? DateTime.now().difference(batch.placementDate).inDays
            : 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              widget.batchName == null ? 'Sales' : 'Sales • ${widget.batchName}',
            ),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            elevation: 0,
          ),
          body: StreamBuilder<List<SalesRecordModel>>(
            stream: SalesService.watchSalesRecords(
              widget.farmId!,
              widget.batchId!,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                );
              }

              final records = snapshot.data ?? <SalesRecordModel>[];
              var totalSold = 0;
              var totalRevenue = 0.0;
              for (final r in records) {
                totalSold += r.birdsSold;
                totalRevenue += r.totalValue;
              }

              return Column(
                children: [
                  // Real-time Flock & Sales Metrics Header Banner
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _statItem(
                            label: 'Live Birds',
                            value: batch != null
                                ? NumberFormat('#,###').format(batch.currentBirds)
                                : '—',
                            icon: Icons.pets_rounded,
                            isPrimary: true,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white24,
                        ),
                        Expanded(
                          child: _statItem(
                            label: 'Total Sold',
                            value: NumberFormat('#,###').format(totalSold),
                            icon: Icons.scale_rounded,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white24,
                        ),
                        Expanded(
                          child: _statItem(
                            label: 'Revenue',
                            value: '₹${NumberFormat.compact().format(totalRevenue)}',
                            icon: Icons.currency_rupee_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sales Records List
                  Expanded(
                    child: records.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.point_of_sale_outlined,
                                      size: 36,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No sales yet',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Record sales to automatically reduce live flock count',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: records.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final record = records[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEFF6FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.sell_outlined,
                                        color: Color(0xFF2563EB),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            record.customerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${_formatDate(record.date)} · ${NumberFormat('#,###').format(record.birdsSold)} birds · ${record.averageWeightKg.toStringAsFixed(1)} kg',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${NumberFormat('#,###').format(record.totalValue)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '@ ₹${record.pricePerBird.toStringAsFixed(0)}/bird',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                      tooltip: 'Delete sale',
                                      onPressed: () => _confirmDelete(record),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SalesFormScreen(
                  farmId: widget.farmId!,
                  batchId: widget.batchId!,
                  currentBatchAge: ageDays,
                  availableBirds: batch?.currentBirds,
                ),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add Sale',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
          ),
        );
      },
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required IconData icon,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isPrimary ? 16 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString()}';
  }
}
