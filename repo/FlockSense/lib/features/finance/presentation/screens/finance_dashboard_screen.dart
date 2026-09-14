import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/finance/data/models/finance_transaction_model.dart';
import 'package:flock_sense/features/finance/data/services/finance_report_generator.dart';
import 'package:flock_sense/features/finance/data/services/finance_service.dart';
import 'package:flock_sense/features/finance/domain/finance_providers.dart';
import 'package:flock_sense/features/finance/presentation/widgets/budget_settings_dialog.dart';
import 'package:flock_sense/features/finance/presentation/widgets/finance_charts.dart';
import 'package:flock_sense/features/finance/presentation/widgets/finance_summary_cards.dart';
import 'package:flock_sense/features/finance/presentation/widgets/transaction_form_dialog.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

class FinanceDashboardScreen extends ConsumerStatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  ConsumerState<FinanceDashboardScreen> createState() =>
      _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState
    extends ConsumerState<FinanceDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openTransactionDialog(FinanceTransactionType type) async {
    final filter = ref.read(financeFilterProvider);
    final activeFarmId = filter.selectedFarmId ??
        ref.read(selectedDashboardFarmIdProvider) ??
        '';
    final activeBatchId = filter.selectedBatchId ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => TransactionFormDialog(
        initialType: type,
        farmId: activeFarmId.isNotEmpty ? activeFarmId : 'farm_default',
        batchId: activeBatchId.isNotEmpty ? activeBatchId : 'batch_default',
      ),
    );

    if (result == true) {
      ref.invalidate(financeTransactionsProvider);
    }
  }

  void _openBudgetDialog() async {
    final budgetAsync = ref.read(financeBudgetStreamProvider);
    final currentBudget = budgetAsync.asData?.value;

    if (currentBudget == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => BudgetSettingsDialog(currentBudget: currentBudget),
    );

    if (result == true) {
      ref.invalidate(financeBudgetStreamProvider);
    }
  }

  void _exportAndShare(ExportFormat format) async {
    final txsAsync = ref.read(financeTransactionsProvider);
    final transactions = txsAsync.asData?.value ?? [];

    await FinanceReportGenerator.shareReport(
      transactions: transactions,
      title: 'Financial BI Report',
      farmName: 'FlockSense Farm',
      format: format,
    );
  }

  void _confirmDeleteTransaction(FinanceTransactionModel tx) async {
    // Only allow deleting user-created custom finance transactions
    if (!tx.id.startsWith('tx_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This ${tx.category} record is automatically linked from its source module. To modify or delete it, please visit the corresponding ${tx.category} screen.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text(
          'Are you sure you want to delete this ${tx.category} transaction of ₹${tx.totalAmount.toStringAsFixed(0)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FinanceService.deleteTransaction(tx.id);
      ref.invalidate(financeTransactionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(financeFilterProvider);
    final filterNotifier = ref.read(financeFilterProvider.notifier);
    final analytics = ref.watch(financeAnalyticsProvider);
    final txsAsync = ref.watch(financeTransactionsProvider);
    final farmsAsync = ref.watch(farmListProvider);
    final batchesAsync = ref.watch(allUserBatchesProvider);

    final farms = farmsAsync.asData?.value ?? [];
    final allBatches = batchesAsync.asData?.value ?? [];

    // Filter available batches by selected farm
    final availableBatches = filter.selectedFarmId != null &&
            filter.selectedFarmId!.isNotEmpty &&
            filter.selectedFarmId != 'all'
        ? allBatches
            .where((b) => b.farmId == filter.selectedFarmId)
            .toList()
        : allBatches;

    final transactions = txsAsync.asData?.value ?? [];
    final searchQuery = filter.searchQuery.toLowerCase();

    // Filter Transactions
    final filteredTxs = transactions.where((t) {
      // Farm filter
      if (filter.selectedFarmId != null &&
          filter.selectedFarmId!.isNotEmpty &&
          filter.selectedFarmId != 'all' &&
          t.farmId != filter.selectedFarmId) {
        return false;
      }
      // Batch filter
      if (filter.selectedBatchId != null &&
          filter.selectedBatchId!.isNotEmpty &&
          filter.selectedBatchId != 'all' &&
          t.batchId != filter.selectedBatchId) {
        return false;
      }
      // Type filter
      if (filter.typeFilter != null && t.type != filter.typeFilter) {
        return false;
      }
      // Payment status filter
      if (filter.paymentStatusFilter != null &&
          t.paymentStatus != filter.paymentStatusFilter) {
        return false;
      }
      // Search filter
      if (searchQuery.isNotEmpty) {
        final matchesInvoice = t.invoiceNumber.toLowerCase().contains(searchQuery);
        final matchesParty = t.customerOrSupplier.toLowerCase().contains(searchQuery);
        final matchesCategory = t.category.toLowerCase().contains(searchQuery);
        return matchesInvoice || matchesParty || matchesCategory;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Finance & Profitability',
          style: TextStyle(
            color: Color(0xFF104422),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF104422)),
            tooltip: 'Budget Settings',
            onPressed: _openBudgetDialog,
          ),
          PopupMenuButton<ExportFormat>(
            icon: const Icon(Icons.download_outlined, color: Color(0xFF104422)),
            tooltip: 'Export Financial Report',
            onSelected: _exportAndShare,
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: ExportFormat.pdf,
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Export PDF Report'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ExportFormat.excel,
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text('Export Excel Sheet'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ExportFormat.csv,
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text('Export CSV Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF104422),
        onRefresh: () async => ref.invalidate(financeTransactionsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Farm & Batch Filter Bar
              _buildFarmBatchFilterBar(
                filter: filter,
                filterNotifier: filterNotifier,
                farms: farms,
                availableBatches: availableBatches,
              ),
              const SizedBox(height: 14),

              // Budget Warning Alerts Banner
              if (analytics.isMonthlyBudgetExceeded ||
                  analytics.isFeedBudgetExceeded ||
                  analytics.isMedicineBudgetExceeded) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BUDGET THRESHOLD WARNING',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              analytics.isMonthlyBudgetExceeded
                                  ? 'Monthly spending (${analytics.monthlyBudgetPct.toStringAsFixed(0)}%) exceeds operating budget limit!'
                                  : (analytics.isFeedBudgetExceeded
                                        ? 'Feed expenditure exceeds feed target budget!'
                                        : 'Medicine expense exceeds healthcare threshold!'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Executive Financial Dashboard & Unit Economics
              FinanceSummaryCards(analytics: analytics),
              const SizedBox(height: 18),

              // Business Analytics Charts
              RevenueExpenseChart(transactions: filteredTxs),
              const SizedBox(height: 14),
              ExpensePieChart(transactions: filteredTxs),
              const SizedBox(height: 18),

              // Business Insights & Predictions
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_graph, size: 16, color: Color(0xFF104422)),
                        const SizedBox(width: 6),
                        const Text(
                          'BUSINESS INSIGHTS & UNIT METRICS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF104422),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _insightRow(
                      Icons.account_tree_outlined,
                      'Highest Expense Category',
                      analytics.highestExpenseAmount > 0
                          ? '${analytics.highestExpenseCategory} (₹${(analytics.highestExpenseAmount / 1000).toStringAsFixed(1)}k)'
                          : 'No expenses recorded',
                    ),
                    _insightRow(
                      Icons.emoji_events_outlined,
                      'Best Performing Batch',
                      analytics.mostProfitableBatch,
                    ),
                    _insightRow(
                      Icons.trending_up,
                      'Expected Harvest Revenue',
                      analytics.expectedHarvestRevenue > 0
                          ? '₹${(analytics.expectedHarvestRevenue / 1000).toStringAsFixed(1)}k (Projected)'
                          : 'Awaiting active flock growth',
                    ),
                    _insightRow(
                      Icons.savings_outlined,
                      'Expected Monthly Revenue',
                      analytics.expectedMonthlyIncome > 0
                          ? '₹${(analytics.expectedMonthlyIncome / 1000).toStringAsFixed(1)}k'
                          : '₹0',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Toolbar & Record Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF104422),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text(
                        'Record Income',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () =>
                          _openTransactionDialog(FinanceTransactionType.income),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: const Text(
                        'Record Expense',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () =>
                          _openTransactionDialog(FinanceTransactionType.expense),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Search & Filter Toolbar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => filterNotifier.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Search invoice, customer, category...',
                        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('All', style: TextStyle(fontSize: 11)),
                    selected: filter.typeFilter == null,
                    selectedColor: const Color(0xFFDCFCE7),
                    checkmarkColor: const Color(0xFF104422),
                    onSelected: (_) => filterNotifier.setTypeFilter(null),
                  ),
                  const SizedBox(width: 4),
                  FilterChip(
                    label: const Text('Income', style: TextStyle(fontSize: 11)),
                    selected: filter.typeFilter == FinanceTransactionType.income,
                    selectedColor: const Color(0xFFDCFCE7),
                    checkmarkColor: const Color(0xFF104422),
                    onSelected: (_) => filterNotifier.setTypeFilter(
                      FinanceTransactionType.income,
                    ),
                  ),
                  const SizedBox(width: 4),
                  FilterChip(
                    label: const Text('Expense', style: TextStyle(fontSize: 11)),
                    selected: filter.typeFilter == FinanceTransactionType.expense,
                    selectedColor: const Color(0xFFFEE2E2),
                    checkmarkColor: const Color(0xFFDC2626),
                    onSelected: (_) => filterNotifier.setTypeFilter(
                      FinanceTransactionType.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Transaction Ledger Table
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TRANSACTION LEDGER',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF104422),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '${filteredTxs.length} records',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (txsAsync.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFF104422)),
                  ),
                )
              else if (filteredTxs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 44,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No transactions found',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Record a new sale, feed transaction, or custom entry to start tracking finances.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Income'),
                            onPressed: () => _openTransactionDialog(
                              FinanceTransactionType.income,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.remove, size: 16),
                            label: const Text('Expense'),
                            onPressed: () => _openTransactionDialog(
                              FinanceTransactionType.expense,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTxs.length,
                  itemBuilder: (context, index) {
                    final t = filteredTxs[index];
                    final isIncome = t.type == FinanceTransactionType.income;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: isIncome
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isIncome
                                ? const Color(0xFF104422)
                                : const Color(0xFFDC2626),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          '${t.category} • ${t.customerOrSupplier}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('dd MMM yyyy').format(t.date)} • ${t.invoiceNumber}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                            if (t.notes != null && t.notes!.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                t.notes!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black38,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'}₹${t.totalAmount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isIncome
                                        ? const Color(0xFF104422)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: t.paymentStatus == PaymentStatus.paid
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    t.paymentStatus.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: t.paymentStatus == PaymentStatus.paid
                                          ? const Color(0xFF104422)
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (t.id.startsWith('tx_')) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                tooltip: 'Delete custom entry',
                                onPressed: () => _confirmDeleteTransaction(t),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmBatchFilterBar({
    required FinanceFilterState filter,
    required FinanceFilterNotifier filterNotifier,
    required List<FarmModel> farms,
    required List<BatchModel> availableBatches,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Farm Filter Chips
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ChoiceChip(
                label: const Text('All Facilities'),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: filter.selectedFarmId == null || filter.selectedFarmId == 'all'
                      ? Colors.white
                      : Colors.black87,
                ),
                selected: filter.selectedFarmId == null || filter.selectedFarmId == 'all',
                selectedColor: const Color(0xFF104422),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (_) => filterNotifier.setFarmId(null),
              ),
              const SizedBox(width: 6),
              ...farms.map((f) {
                final isSelected = filter.selectedFarmId == f.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(f.farmName),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF104422),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (selected) {
                      filterNotifier.setFarmId(selected ? f.id : null);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        // Batch Filter Chips (if batches exist for selected scope)
        if (availableBatches.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('All Flocks'),
                  labelStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: filter.selectedBatchId == null || filter.selectedBatchId == 'all'
                        ? const Color(0xFF104422)
                        : Colors.black87,
                  ),
                  selected: filter.selectedBatchId == null || filter.selectedBatchId == 'all',
                  selectedColor: const Color(0xFFDCFCE7),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: filter.selectedBatchId == null || filter.selectedBatchId == 'all'
                        ? const Color(0xFF104422)
                        : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (_) => filterNotifier.setBatchId(null),
                ),
                const SizedBox(width: 6),
                ...availableBatches.map((b) {
                  final isSelected = filter.selectedBatchId == b.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('${b.batchName} (${b.currentBirds} birds)'),
                      labelStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? const Color(0xFF104422) : Colors.black87,
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFFDCFCE7),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF104422) : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (selected) {
                        filterNotifier.setBatchId(selected ? b.id : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _insightRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF104422)),
          const SizedBox(width: 8),
          Text(
            '$title: ',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
