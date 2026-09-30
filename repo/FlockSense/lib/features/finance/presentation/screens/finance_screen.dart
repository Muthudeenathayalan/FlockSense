import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/section_header.dart';
import 'package:flock_sense/core/widgets/cached_async.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/providers/batch_providers.dart';
import 'package:flock_sense/features/finance/domain/expense_record_model.dart';
import 'package:flock_sense/features/finance/domain/finance_summary.dart';
import 'package:flock_sense/features/finance/presentation/providers/finance_providers.dart';
import 'package:flock_sense/features/finance/presentation/screens/expense_form_screen.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/sales/domain/sales_record_model.dart';
import 'package:flock_sense/features/sales/presentation/screens/sales_form_screen.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  String? _selectedFarmId;
  String? _selectedBatchId;
  FinanceSummary? _cachedSummary;
  FinanceFilter _lastFilter = const FinanceFilter();

  void _setFarm(String? farmId) {
    setState(() {
      _selectedFarmId = farmId;
      _selectedBatchId = null;
      _cachedSummary = null;
    });
  }

  void _setBatch(String? batchId) {
    setState(() {
      _selectedBatchId = batchId;
      _cachedSummary = null;
    });
  }

  int _calculateBatchAgeDays(BatchModel batch) {
    final today = DateTime.now();
    final diff = today.difference(batch.placementDate).inDays + 1;
    return diff < 1 ? 1 : diff;
  }

  @override
  Widget build(BuildContext context) {
    final farmsAsync = ref.watch(farmListProvider);
    final batchesAsync = ref.watch(batchListProvider(_selectedFarmId));
    final filter = FinanceFilter(
      farmId: _selectedFarmId,
      batchId: _selectedBatchId,
    );
    final salesAsync = ref.watch(financeSalesRecordsProvider(filter));
    final expensesAsync = ref.watch(financeExpenseRecordsProvider(filter));
    final summaryAsync = ref.watch(financeSummaryProvider(filter));
    if (filter != _lastFilter) {
      _lastFilter = filter;
      _cachedSummary = null;
    }
    if (summaryAsync is AsyncData<FinanceSummary>) {
      _cachedSummary = summaryAsync.value;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Finance'),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: _buildActionButtons(context, batchesAsync),
      body: SafeArea(
        child: farmsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, __) => _buildErrorState('Unable to load farms'),
          data: (farms) {
            return batchesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => _buildErrorState('Unable to load batches'),
              data: (batches) {
                final batchOptions = _filterBatchOptions(
                  batches,
                  _selectedFarmId,
                );
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(financeExpenseRecordsProvider(filter));
                    ref.invalidate(financeSalesRecordsProvider(filter));
                    ref.invalidate(financeSummaryProvider(filter));
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SectionHeader(
                              title: 'Finance Dashboard',
                              subtitle: 'Income, expense and profit overview',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select farm and batch to drill into financial performance. Use the buttons below to add expense or sale records.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SectionHeader(title: 'Filters'),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String?>(
                              initialValue: _selectedFarmId,
                              decoration: _inputDecoration('Farm'),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All farms'),
                                ),
                                ...farms.map(
                                  (farm) => DropdownMenuItem(
                                    value: farm.id,
                                    child: Text(farm.farmName),
                                  ),
                                ),
                              ],
                              onChanged: _setFarm,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String?>(
                              initialValue: _selectedBatchId,
                              decoration: _inputDecoration('Batch'),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All batches'),
                                ),
                                ...batchOptions.map(
                                  (batch) => DropdownMenuItem(
                                    value: batch.id,
                                    child: Text(
                                      _batchDisplayName(batch, farms),
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: _setBatch,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CachedAsync<FinanceSummary>(
                        value: summaryAsync,
                        cached: _cachedSummary,
                        loading: AppCard(
                          child: SizedBox(
                            height: 120,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Loading finance summary...',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        error: (err, __) => _cachedSummary != null
                            ? _buildSummaryCards(_cachedSummary!)
                            : AppCard(
                                child: SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: Text(
                                      'Unable to load finance summary',
                                      style: TextStyle(
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        data: (summary) {
                          if (summary.saleCount == 0 && summary.expenseCount == 0) {
                            return AppCard(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                  horizontal: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    'No finance records yet. Add sales or expenses to see performance data.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return _buildSummaryCards(summary);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTrendCards(salesAsync, expensesAsync),
                      const SizedBox(height: 16),
                      _buildRecentSections(salesAsync, expensesAsync),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AsyncValue<List<BatchModel>> batchesAsync,
  ) {
    final batchOptions = batchesAsync.value ?? <BatchModel>[];
    BatchModel? activeBatch;
    for (final batch in batchOptions) {
      if (batch.id == _selectedBatchId) {
        activeBatch = batch;
        break;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'expense',
          onPressed: activeBatch == null
              ? null
              : () => _openExpenseForm(context, activeBatch!),
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('Add Expense'),
          backgroundColor: AppColors.danger,
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'sale',
          onPressed: activeBatch == null
              ? null
              : () => _openSalesForm(context, activeBatch!),
          icon: const Icon(Icons.sell_outlined),
          label: const Text('Add Sale'),
        ),
      ],
    );
  }

  List<BatchModel> _filterBatchOptions(
    List<BatchModel> batches,
    String? farmId,
  ) {
    if (farmId == null) return batches;
    return batches.where((batch) => batch.farmId == farmId).toList();
  }

  String _batchDisplayName(BatchModel batch, List<FarmModel> farms) {
    final farmName = farms
        .firstWhere(
          (farm) => farm.id == batch.farmId,
          orElse: () => FarmModel(
            id: '',
            userId: '',
            farmName: '',
            farmType: '',
            flockType: '',
            address: '',
            lengthFt: 0,
            widthFt: 0,
            totalSqFt: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        )
        .farmName;
    return farmName.isEmpty
        ? batch.batchName
        : '${batch.batchName} • $farmName';
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, style: const TextStyle(color: AppColors.danger)),
      ),
    );
  }

  Widget _buildSummaryCards(FinanceSummary summary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _metricCard(
            'Revenue',
            '₹${summary.totalRevenue.toStringAsFixed(0)}',
            AppColors.primary,
            'Income from sales',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard(
            'Expenses',
            '₹${summary.totalExpenses.toStringAsFixed(0)}',
            AppColors.danger,
            'Cost of operations',
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, Color color, String subtitle) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCards(
    AsyncValue<List<SalesRecordModel>> salesAsync,
    AsyncValue<List<ExpenseRecordModel>> expensesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Revenue trend'),
              const SizedBox(height: 12),
              salesAsync.when(
                data: (sales) => _buildSalesChart(sales),
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (_, __) => const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'Unable to load sales trend',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Expenses by category'),
              const SizedBox(height: 12),
              expensesAsync.when(
                data: (expenses) => _buildExpenseCategoryChart(expenses),
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.danger),
                  ),
                ),
                error: (_, __) => const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'Unable to load expenses',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesChart(List<SalesRecordModel> sales) {
    if (sales.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No sales recorded yet.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final sortedSales = [...sales]..sort((a, b) => a.date.compareTo(b.date));
    final spots = sortedSales
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(entry.key.toDouble() + 1, entry.value.totalValue),
        )
        .toList();
    final maxY = math.max(
      50.0,
      spots.map((spot) => spot.y).reduce(math.max) + 20,
    );

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: spots.length.toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.border, strokeWidth: 0.8),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: AppColors.border),
              left: BorderSide(color: AppColors.border),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: maxY / 4,
                getTitlesWidget: (value, _) => Text(
                  '₹${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: spots.length > 1 ? 1 : 1,
                getTitlesWidget: (value, _) {
                  final index = value.toInt() - 1;
                  if (index < 0 || index >= sortedSales.length)
                    return const SizedBox();
                  return Text(
                    'S${index + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.primary,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCategoryChart(List<ExpenseRecordModel> expenses) {
    if (expenses.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No expenses recorded yet.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      final key = expense.category.isEmpty ? 'General' : expense.category;
      categoryTotals[key] = (categoryTotals[key] ?? 0) + expense.amount;
    }

    final sections = categoryTotals.entries.toList().asMap().entries.map((
      entry,
    ) {
      final index = entry.key;
      final category = entry.value.key;
      final value = entry.value.value;
      final colors = [
        AppColors.primary,
        AppColors.danger,
        AppColors.warning,
        AppColors.emerald,
        AppColors.gold,
        AppColors.surfaceVariant,
      ];
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value,
        title: category,
        radius: 40,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
    }).toList();

    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 28,
          sectionsSpace: 4,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildRecentSections(
    AsyncValue<List<SalesRecordModel>> salesAsync,
    AsyncValue<List<ExpenseRecordModel>> expensesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Recent Sales'),
              const SizedBox(height: 12),
              salesAsync.when(
                data: (sales) => _buildRecentSales(sales),
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (_, __) => const SizedBox(
                  height: 140,
                  child: Center(
                    child: Text(
                      'Unable to load sales',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Recent Expenses'),
              const SizedBox(height: 12),
              expensesAsync.when(
                data: (expenses) => _buildRecentExpenses(expenses),
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.danger),
                  ),
                ),
                error: (_, __) => const SizedBox(
                  height: 140,
                  child: Center(
                    child: Text(
                      'Unable to load expenses',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSales(List<SalesRecordModel> sales) {
    if (sales.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No sales records yet.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final latest = sales.take(3).toList();
    return Column(
      children: latest.map((sale) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            sale.customerName.isNotEmpty ? sale.customerName : 'Sale',
          ),
          subtitle: Text(
            '${sale.birdsSold} birds · ₹${sale.totalValue.toStringAsFixed(0)}',
          ),
          trailing: Text(
            _formatDate(sale.date),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentExpenses(List<ExpenseRecordModel> expenses) {
    if (expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No expenses recorded yet.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final latest = expenses.take(3).toList();
    return Column(
      children: latest.map((expense) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(expense.description),
          subtitle: Text(expense.category),
          trailing: Text(
            '₹${expense.amount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      }).toList(),
    );
  }

  void _openExpenseForm(BuildContext context, BatchModel batch) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ExpenseFormScreen(farmId: batch.farmId, batchId: batch.id),
      ),
    );
  }

  void _openSalesForm(BuildContext context, BatchModel batch) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SalesFormScreen(
          farmId: batch.farmId,
          batchId: batch.id,
          currentBatchAge: _calculateBatchAgeDays(batch),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
