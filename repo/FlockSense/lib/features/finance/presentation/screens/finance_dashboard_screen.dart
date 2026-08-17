import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/finance/data/models/finance_transaction_model.dart';
import 'package:flock_sense/features/finance/data/services/finance_report_generator.dart';
import 'package:flock_sense/features/finance/domain/finance_providers.dart';
import 'package:flock_sense/features/finance/presentation/widgets/budget_settings_dialog.dart';
import 'package:flock_sense/features/finance/presentation/widgets/finance_charts.dart';
import 'package:flock_sense/features/finance/presentation/widgets/finance_kpi_card.dart';
import 'package:flock_sense/features/finance/presentation/widgets/transaction_form_dialog.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

class FinanceDashboardScreen extends ConsumerStatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  ConsumerState<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends ConsumerState<FinanceDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openTransactionDialog(FinanceTransactionType type) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => TransactionFormDialog(initialType: type),
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
      farmName: 'Green Valley Poultry',
      format: format,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(financeFilterProvider);
    final filterNotifier = ref.read(financeFilterProvider.notifier);
    final analytics = ref.watch(financeAnalyticsProvider);
    final txsAsync = ref.watch(financeTransactionsProvider);

    final transactions = txsAsync.asData?.value ?? [];
    final searchQuery = filter.searchQuery.toLowerCase();

    // Filter Transactions
    final filteredTxs = transactions.where((t) {
      if (filter.typeFilter != null && t.type != filter.typeFilter) return false;
      if (filter.paymentStatusFilter != null && t.paymentStatus != filter.paymentStatusFilter) return false;
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
        title: const Text('Finance & Business Intelligence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Budget Settings',
            onPressed: _openBudgetDialog,
          ),
          PopupMenuButton<ExportFormat>(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export Financial Report',
            onSelected: _exportAndShare,
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: ExportFormat.pdf, child: Text('Export PDF Report')),
              PopupMenuItem(value: ExportFormat.excel, child: Text('Export Excel Sheet')),
              PopupMenuItem(value: ExportFormat.csv, child: Text('Export CSV Data')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(financeTransactionsProvider),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Budget Warning Alerts Banner
              if (analytics.isMonthlyBudgetExceeded || analytics.isFeedBudgetExceeded || analytics.isMedicineBudgetExceeded) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BUDGET THRESHOLD WARNING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.red)),
                            const SizedBox(height: 2),
                            Text(
                              analytics.isMonthlyBudgetExceeded
                                  ? 'Monthly spending (${analytics.monthlyBudgetPct.toStringAsFixed(0)}%) exceeds operating budget limit!'
                                  : (analytics.isFeedBudgetExceeded ? 'Feed expenditure exceeds feed target budget!' : 'Medicine expense exceeds healthcare threshold!'),
                              style: const TextStyle(fontSize: 10, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 10 KPI Cards Grid
              const Text('EXECUTIVE FINANCIAL DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B5E20))),
              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisExtent: 94,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final kpiList = [
                    FinanceKpiCard(label: "Today's Income", value: "₹${analytics.todayIncome.toStringAsFixed(0)}", subtext: "Daily Gross", icon: Icons.arrow_downward, color: const Color(0xFF1B5E20)),
                    FinanceKpiCard(label: "Today's Expenses", value: "₹${analytics.todayExpense.toStringAsFixed(0)}", subtext: "Daily Outflow", icon: Icons.arrow_upward, color: const Color(0xFFE65100)),
                    FinanceKpiCard(label: "Today's Profit", value: "₹${analytics.todayProfit.toStringAsFixed(0)}", subtext: "Net Daily", icon: Icons.attach_money, color: analytics.todayProfit >= 0 ? const Color(0xFF1B5E20) : Colors.red),
                    FinanceKpiCard(label: "Monthly Revenue", value: "₹${(analytics.monthlyRevenue / 1000).toStringAsFixed(1)}k", subtext: "Month Gross", icon: Icons.account_balance, color: const Color(0xFF1B5E20)),
                    FinanceKpiCard(label: "Monthly Expenses", value: "₹${(analytics.monthlyExpenses / 1000).toStringAsFixed(1)}k", subtext: "Month Outflow", icon: Icons.shopping_bag_outlined, color: const Color(0xFFE65100)),
                    FinanceKpiCard(label: "Monthly Profit", value: "₹${(analytics.monthlyProfit / 1000).toStringAsFixed(1)}k", subtext: "Month Net", icon: Icons.trending_up, color: const Color(0xFF1B5E20)),
                    FinanceKpiCard(label: "Current Cash Flow", value: "₹${(analytics.currentCashFlow / 1000).toStringAsFixed(1)}k", subtext: "Available", icon: Icons.payments_outlined, color: const Color(0xFF00838F)),
                    FinanceKpiCard(label: "Outstanding", value: "₹${(analytics.outstandingPayments / 1000).toStringAsFixed(1)}k", subtext: "Receivables", icon: Icons.schedule_outlined, color: Colors.purple.shade700),
                    FinanceKpiCard(label: "Profit Margin", value: "${analytics.profitMarginPct.toStringAsFixed(1)}%", subtext: "Margin Index", icon: Icons.pie_chart, color: const Color(0xFF1B5E20)),
                    FinanceKpiCard(label: "ROI Index", value: "${analytics.roiPct.toStringAsFixed(1)}%", subtext: "Return Rate", icon: Icons.stars_outlined, color: const Color(0xFFF57F17)),
                  ];
                  return kpiList[index];
                },
              ),
              const SizedBox(height: 16),

              // Unit Economics & Per-Bird Metrics
              const Text('UNIT ECONOMICS & PER-BIRD METRICS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0A3200))),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(child: FinanceKpiCard(label: "Revenue / Bird", value: "₹${analytics.revenuePerBird.toStringAsFixed(0)}", subtext: "Per Bird Sales", icon: Icons.person, color: const Color(0xFF1B5E20))),
                  const SizedBox(width: 8),
                  Expanded(child: FinanceKpiCard(label: "Cost / Bird", value: "₹${analytics.costPerBird.toStringAsFixed(0)}", subtext: "Per Bird Cost", icon: Icons.person_outline, color: const Color(0xFFE65100))),
                  const SizedBox(width: 8),
                  Expanded(child: FinanceKpiCard(label: "Feed Cost / Bird", value: "₹${analytics.feedCostPerBird.toStringAsFixed(0)}", subtext: "Feed Share", icon: Icons.grass, color: const Color(0xFF00838F))),
                  const SizedBox(width: 8),
                  Expanded(child: FinanceKpiCard(label: "Med Cost / Bird", value: "₹${analytics.medicineCostPerBird.toStringAsFixed(0)}", subtext: "Vet Share", icon: Icons.medication, color: Colors.purple.shade700)),
                ],
              ),
              const SizedBox(height: 18),

              // Business Analytics Charts
              const RevenueExpenseChart(),
              const SizedBox(height: 14),
              const ExpensePieChart(),
              const SizedBox(height: 18),

              // Business Insights & Predictions
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BUSINESS INSIGHTS & AI PREDICTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1B5E20))),
                    const SizedBox(height: 10),
                    _insightRow(Icons.account_tree_outlined, 'Highest Expense Category', '${analytics.highestExpenseCategory} (₹${(analytics.highestExpenseAmount / 1000).toStringAsFixed(0)}k)'),
                    _insightRow(Icons.emoji_events_outlined, 'Best Performing Batch', analytics.mostProfitableBatch),
                    _insightRow(Icons.trending_up, 'Expected Harvest Revenue', '₹${(analytics.expectedHarvestRevenue / 1000).toStringAsFixed(1)}k (Projected)'),
                    _insightRow(Icons.savings_outlined, 'Expected Monthly Income', '₹${(analytics.expectedMonthlyIncome / 1000).toStringAsFixed(1)}k'),
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
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Record Income'),
                      onPressed: () => _openTransactionDialog(FinanceTransactionType.income),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('Record Expense'),
                      onPressed: () => _openTransactionDialog(FinanceTransactionType.expense),
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
                        hintText: 'Search invoice, customer, supplier...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('All'),
                    selected: filter.typeFilter == null,
                    onSelected: (_) => filterNotifier.setTypeFilter(null),
                  ),
                  const SizedBox(width: 4),
                  FilterChip(
                    label: const Text('Income'),
                    selected: filter.typeFilter == FinanceTransactionType.income,
                    onSelected: (_) => filterNotifier.setTypeFilter(FinanceTransactionType.income),
                  ),
                  const SizedBox(width: 4),
                  FilterChip(
                    label: const Text('Expense'),
                    selected: filter.typeFilter == FinanceTransactionType.expense,
                    onSelected: (_) => filterNotifier.setTypeFilter(FinanceTransactionType.expense),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Transaction Ledger Table
              const Text('TRANSACTION LEDGER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0A3200))),
              const SizedBox(height: 8),

              if (filteredTxs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No transactions match the selected filters.'),
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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? Colors.green.shade100 : Colors.orange.shade100,
                          child: Icon(
                            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isIncome ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          '${t.category} • ${t.customerOrSupplier}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          '${DateFormat('dd MMM yyyy').format(t.date)} • Invoice: ${t.invoiceNumber}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isIncome ? '+' : '-'}₹${t.totalAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isIncome ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
                              ),
                            ),
                            Text(
                              t.paymentStatus.name.toUpperCase(),
                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
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

  Widget _insightRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 8),
          Text('$title: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, color: Colors.black54))),
        ],
      ),
    );
  }
}
