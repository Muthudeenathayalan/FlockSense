import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/finance/data/models/finance_transaction_model.dart';
import 'package:flock_sense/features/finance/domain/finance_providers.dart';

class RevenueExpenseChart extends ConsumerWidget {
  final List<FinanceTransactionModel>? transactions;

  const RevenueExpenseChart({super.key, this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = transactions ??
        ref.watch(financeTransactionsProvider).asData?.value ??
        [];

    final now = DateTime.now();
    // Group transactions by 5 weeks of current month
    final weeklyRevenue = List<double>.filled(5, 0.0);
    final weeklyExpense = List<double>.filled(5, 0.0);

    for (final t in txs) {
      if (t.date.year == now.year && t.date.month == now.month) {
        final day = t.date.day;
        final weekIdx = min(4, (day - 1) ~/ 7);
        if (t.type == FinanceTransactionType.income) {
          weeklyRevenue[weekIdx] += t.totalAmount;
        } else {
          weeklyExpense[weekIdx] += t.totalAmount;
        }
      }
    }

    // Cumulative sums
    double cumRev = 0;
    double cumExp = 0;
    final revSpots = <FlSpot>[];
    final expSpots = <FlSpot>[];

    for (int i = 0; i < 5; i++) {
      cumRev += weeklyRevenue[i];
      cumExp += weeklyExpense[i];
      revSpots.add(FlSpot((i + 1).toDouble(), cumRev));
      expSpots.add(FlSpot((i + 1).toDouble(), cumExp));
    }

    final hasData = cumRev > 0 || cumExp > 0;
    final maxVal = max(cumRev, cumExp);
    final maxY = hasData ? max(10000.0, maxVal * 1.2) : 10000.0;

    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'REVENUE VS EXPENSE TREND (₹)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Track cumulative growth and cost trajectory',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              const Icon(
                Icons.analytics_outlined,
                size: 22,
                color: Color(0xFF1B5E20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Legend Row
          Row(
            children: [
              _buildLegendBadge(
                'Revenue (Gross Sales)',
                const Color(0xFF1B5E20),
              ),
              const SizedBox(width: 16),
              _buildLegendBadge(
                'Expenses (Production Cost)',
                const Color(0xFFE65100),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart Area
          Expanded(
            child: !hasData
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 40,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No Transactions This Month',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Add sales or expense records to visualize weekly trend.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: maxY > 50000 ? maxY / 5 : 10000,
                        getDrawingHorizontalLine: (val) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (val) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) {
                                return const Text(
                                  '0',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                );
                              }
                              return Text(
                                '₹${(value / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final week = value.toInt();
                              if (week >= 1 && week <= 5) {
                                return Text(
                                  'Wk $week',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final isRevenue = spot.barIndex == 0;
                              return LineTooltipItem(
                                '${isRevenue ? "Revenue" : "Expense"}: ₹${spot.y.toStringAsFixed(0)}',
                                TextStyle(
                                  color: isRevenue
                                      ? Colors.green.shade200
                                      : Colors.orange.shade200,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: revSpots,
                          isCurved: true,
                          color: const Color(0xFF1B5E20),
                          barWidth: 3.5,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF1B5E20)
                                .withAlpha((0.08 * 255).toInt()),
                          ),
                        ),
                        LineChartBarData(
                          spots: expSpots,
                          isCurved: true,
                          color: const Color(0xFFE65100),
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBadge(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class ExpensePieChart extends ConsumerWidget {
  final List<FinanceTransactionModel>? transactions;

  const ExpensePieChart({super.key, this.transactions});

  static const _palette = [
    Color(0xFF1B5E20), // Forest Green (Feed)
    Color(0xFFE65100), // Deep Orange (Chicks)
    Color(0xFF00838F), // Teal (Medicine)
    Color(0xFF6A1B9A), // Purple (Vaccine)
    Color(0xFFF57F17), // Amber (Electricity)
    Color(0xFF1565C0), // Blue (Labour)
    Color(0xFFAD1457), // Pink (Transport)
    Color(0xFF455A64), // BlueGrey (Maintenance)
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = transactions ??
        ref.watch(financeTransactionsProvider).asData?.value ??
        [];

    final expenseTxs =
        txs.where((t) => t.type == FinanceTransactionType.expense).toList();

    final categoryTotals = <String, double>{};
    for (final t in expenseTxs) {
      categoryTotals[t.category] =
          (categoryTotals[t.category] ?? 0.0) + t.totalAmount;
    }

    final totalExpense = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hasExpenses = totalExpense > 0 && sortedEntries.isNotEmpty;

    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'EXPENSE BREAKDOWN BY CATEGORY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1B5E20),
                ),
              ),
              Icon(Icons.pie_chart, size: 22, color: Color(0xFF1B5E20)),
            ],
          ),
          const SizedBox(height: 14),

          Expanded(
            child: !hasExpenses
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pie_chart_outline,
                          size: 40,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No Expenses Recorded',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Log feed, medicine, or operational expenses to see breakdown.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 42,
                            sections: List.generate(
                              sortedEntries.length,
                              (i) {
                                final entry = sortedEntries[i];
                                final pct = (entry.value / totalExpense) * 100;
                                final color = _palette[i % _palette.length];
                                return PieChartSectionData(
                                  color: color,
                                  value: entry.value,
                                  title:
                                      '${pct.toStringAsFixed(0)}%\n${entry.key}',
                                  radius: 52,
                                  titleStyle: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Side Legend Details Table
                      Expanded(
                        flex: 2,
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: min(5, sortedEntries.length),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final entry = sortedEntries[i];
                            final pct = (entry.value / totalExpense) * 100;
                            final color = _palette[i % _palette.length];
                            final formattedVal = entry.value >= 1000
                                ? '₹${(entry.value / 1000).toStringAsFixed(1)}k'
                                : '₹${entry.value.toStringAsFixed(0)}';
                            return _buildPieLegendRow(
                              entry.key,
                              '${pct.toStringAsFixed(0)}% ($formattedVal)',
                              color,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieLegendRow(String label, String share, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 1),
          child: Text(
            share,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
