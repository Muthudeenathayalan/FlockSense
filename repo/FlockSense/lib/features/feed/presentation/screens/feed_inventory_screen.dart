import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/feed/data/feed_service.dart';
import 'package:flock_sense/features/feed/domain/feed_transaction_model.dart';
import 'package:flock_sense/features/feed/presentation/screens/feed_transaction_form_screen.dart';

class FeedInventoryScreen extends StatefulWidget {
  const FeedInventoryScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    this.batchName,
  });

  final String farmId;
  final String batchId;
  final String? batchName;

  @override
  State<FeedInventoryScreen> createState() => _FeedInventoryScreenState();
}

class _FeedInventoryScreenState extends State<FeedInventoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.batchName != null
              ? 'Feed Inventory • ${widget.batchName}'
              : 'Feed Inventory',
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
      ),
      body: StreamBuilder<List<FeedTransactionModel>>(
        stream: FeedService.watchFeedTransactions(
          farmId: widget.farmId,
          batchId: widget.batchId,
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
          final transactions = snapshot.data ?? <FeedTransactionModel>[];
          final deliveryCount = transactions.length;
          final totalBags = transactions.fold<int>(
            0,
            (sum, item) => sum + item.bags,
          );
          final totalKg = transactions.fold<double>(
            0,
            (sum, item) => sum + item.totalKg,
          );
          final progressByType = <String, double>{};
          for (final item in transactions) {
            progressByType[item.feedType] =
                (progressByType[item.feedType] ?? 0) + item.totalKg;
          }

          if (transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.goldLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        size: 36,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No feed deliveries yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Log your first feed receipt',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _openForm(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Receipt'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Feed Summary',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _summaryTile(
                            'Total Bags',
                            '$totalBags',
                            Icons.inventory_2_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _summaryTile(
                            'Total KG',
                            '${totalKg.toStringAsFixed(1)}',
                            Icons.scale_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _summaryTile(
                            'Deliveries',
                            '$deliveryCount',
                            Icons.local_shipping,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Feed type mix',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...['PB82', '882', 'B4'].map((type) {
                      final kg = progressByType[type] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  type,
                                  style: const TextStyle(
                                    color: AppColors.surface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${kg.toStringAsFixed(0)} kg',
                                  style: const TextStyle(
                                    color: AppColors.surface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: totalKg > 0 ? (kg / totalKg) : 0,
                                minHeight: 8,
                                backgroundColor: AppColors.surface.withValues(
                                  alpha: 0.2,
                                ),
                                color: AppColors.surface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Deliveries',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ...transactions.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _deliveryCard(context, item),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Receipt'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
    );
  }

  Widget _summaryTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.surface),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.surface,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.surface, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _deliveryCard(BuildContext context, FeedTransactionModel item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: AppColors.goldGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping, color: AppColors.surface),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.feedType} — ${item.bags} bags',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(item.date)} · DC: ${item.dcNumber ?? '–'} · ${item.weightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.weightKg.toStringAsFixed(1)} kg',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedTransactionFormScreen(
          farmId: widget.farmId,
          batchId: widget.batchId,
          batchName: widget.batchName,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString()}';
  }
}
