import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/feed/data/feed_service.dart';
import 'package:flock_sense/features/feed/domain/feed_summary.dart';
import 'package:flock_sense/features/feed/domain/feed_transaction_model.dart';
import 'package:flock_sense/features/feed/presentation/screens/feed_transaction_form_screen.dart';

class FeedRecordsScreen extends StatefulWidget {
  const FeedRecordsScreen({
    super.key,
    this.farmId = '',
    this.batchId = '',
    this.batchName,
  });

  final String farmId;
  final String batchId;
  final String? batchName;

  @override
  State<FeedRecordsScreen> createState() => _FeedRecordsScreenState();
}

class _FeedRecordsScreenState extends State<FeedRecordsScreen> {
  late final Stream<List<FeedTransactionModel>> _transactionsStream;
  late Future<FeedSummary> _summaryFuture;

  bool get _hasBatchContext =>
      widget.farmId.isNotEmpty && widget.batchId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _transactionsStream = _hasBatchContext
        ? FeedService.watchFeedTransactions(
            farmId: widget.farmId,
            batchId: widget.batchId,
          )
        : const Stream.empty();
    _summaryFuture = _loadSummary();
  }

  Future<FeedSummary> _loadSummary() async {
    if (!_hasBatchContext) return FeedSummary.empty;
    return FeedService.calculateFeedSummary(
      farmId: widget.farmId,
      batchId: widget.batchId,
    );
  }

  void _refreshSummary() {
    if (!mounted) return;
    setState(() => _summaryFuture = _loadSummary());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.batchName != null
              ? 'Feed Ledger • ${widget.batchName}'
              : 'Feed Ledger',
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
      ),
      floatingActionButton: _hasBatchContext
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeedTransactionFormScreen(
                      farmId: widget.farmId,
                      batchId: widget.batchId,
                      batchName: widget.batchName,
                    ),
                  ),
                );
                _refreshSummary();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add transaction'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: FutureBuilder<FeedSummary>(
        future: _summaryFuture,
        builder: (context, summarySnapshot) {
          if (!_hasBatchContext) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.feed_outlined,
                      size: 56,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Choose a batch to view feed records.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final summary = summarySnapshot.data ?? FeedSummary.empty;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        'Closing stock',
                        '${summary.closingStockKg.toStringAsFixed(1)} kg',
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        'Consumed',
                        '${summary.totalConsumedKg.toStringAsFixed(1)} kg',
                        AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        'Received',
                        '${summary.totalReceivedKg.toStringAsFixed(1)} kg',
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        'Cost',
                        '${summary.totalFeedCost.toStringAsFixed(0)}',
                        AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<FeedTransactionModel>>(
                  stream: _transactionsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final transactions =
                        snapshot.data ?? const <FeedTransactionModel>[];
                    if (transactions.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 56,
                                color: AppColors.textHint,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No feed transactions yet. Add the first delivery or adjustment.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return _transactionTile(transaction);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(FeedTransactionModel transaction) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconForType(transaction.transactionType),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        transaction.feedType,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      _labelForType(transaction.transactionType),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.totalKg.toStringAsFixed(1)} kg • ${transaction.bags} bags',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (transaction.notes != null &&
                    transaction.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    transaction.notes!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeedTransactionFormScreen(
                      farmId: widget.farmId,
                      batchId: widget.batchId,
                      batchName: widget.batchName,
                      existingTransaction: transaction,
                    ),
                  ),
                );
                _refreshSummary();
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete transaction?'),
                    content: const Text(
                      'This removes the feed entry from the ledger.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FeedService.deleteFeedTransaction(
                    farmId: widget.farmId,
                    batchId: widget.batchId,
                    transactionId: transaction.id,
                  );
                  _refreshSummary();
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'transferIn':
      case 'received':
        return Icons.inventory_2_outlined;
      case 'transferOut':
        return Icons.output_rounded;
      case 'adjustmentAdd':
      case 'adjustmentRemove':
        return Icons.tune_rounded;
      default:
        return Icons.local_shipping_outlined;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'received':
        return 'Received';
      case 'transferIn':
        return 'Transfer in';
      case 'transferOut':
        return 'Transfer out';
      case 'adjustmentAdd':
        return 'Adjustment +';
      case 'adjustmentRemove':
        return 'Adjustment -';
      default:
        return 'Transaction';
    }
  }
}
