import 'package:flutter/material.dart';
import 'package:flock_sense/features/finance/domain/finance_analytics_engine.dart';
import 'package:flock_sense/features/finance/presentation/widgets/finance_kpi_card.dart';

/// Renders executive financial summary cards including the 10-KPI grid
/// and unit economics breakdown (FS-069).
class FinanceSummaryCards extends StatelessWidget {
  final FinanceAnalyticsResult analytics;

  const FinanceSummaryCards({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EXECUTIVE FINANCIAL DASHBOARD',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 10),
        FinanceExecutiveKpiGrid(analytics: analytics),
        const SizedBox(height: 16),
        const Text(
          'UNIT ECONOMICS & PER-BIRD METRICS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Color(0xFF0A3200),
          ),
        ),
        const SizedBox(height: 8),
        FinanceUnitEconomicsRow(analytics: analytics),
      ],
    );
  }
}

/// 10-card KPI Grid covering daily, monthly, cash flow, and efficiency metrics.
class FinanceExecutiveKpiGrid extends StatelessWidget {
  final FinanceAnalyticsResult analytics;

  const FinanceExecutiveKpiGrid({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final kpiList = [
      FinanceKpiCard(
        label: "Today's Income",
        value: "₹${analytics.todayIncome.toStringAsFixed(0)}",
        subtext: "Daily Gross",
        icon: Icons.arrow_downward,
        color: const Color(0xFF1B5E20),
      ),
      FinanceKpiCard(
        label: "Today's Expenses",
        value: "₹${analytics.todayExpense.toStringAsFixed(0)}",
        subtext: "Daily Outflow",
        icon: Icons.arrow_upward,
        color: const Color(0xFFE65100),
      ),
      FinanceKpiCard(
        label: "Today's Profit",
        value: "₹${analytics.todayProfit.toStringAsFixed(0)}",
        subtext: "Net Daily",
        icon: Icons.attach_money,
        color: analytics.todayProfit >= 0
            ? const Color(0xFF1B5E20)
            : Colors.red,
      ),
      FinanceKpiCard(
        label: "Monthly Revenue",
        value: "₹${(analytics.monthlyRevenue / 1000).toStringAsFixed(1)}k",
        subtext: "Month Gross",
        icon: Icons.account_balance,
        color: const Color(0xFF1B5E20),
      ),
      FinanceKpiCard(
        label: "Monthly Expenses",
        value: "₹${(analytics.monthlyExpenses / 1000).toStringAsFixed(1)}k",
        subtext: "Month Outflow",
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFFE65100),
      ),
      FinanceKpiCard(
        label: "Net Profit (Month)",
        value: "₹${(analytics.monthlyProfit / 1000).toStringAsFixed(1)}k",
        subtext: "Net Margin",
        icon: Icons.trending_up,
        color: analytics.monthlyProfit >= 0
            ? const Color(0xFF1B5E20)
            : Colors.red,
      ),
      FinanceKpiCard(
        label: "Current Cash Flow",
        value: "₹${(analytics.currentCashFlow / 1000).toStringAsFixed(1)}k",
        subtext: "Available Reserve",
        icon: Icons.savings_outlined,
        color: analytics.currentCashFlow >= 0
            ? const Color(0xFF00838F)
            : Colors.red,
      ),
      FinanceKpiCard(
        label: "Outstanding Balances",
        value:
            "₹${(analytics.outstandingPayments / 1000).toStringAsFixed(1)}k",
        subtext: "Unpaid / Credit",
        icon: Icons.pending_actions,
        color: const Color(0xFFC2185B),
      ),
      FinanceKpiCard(
        label: "Profit Margin",
        value: "${analytics.profitMarginPct.toStringAsFixed(1)}%",
        subtext: "Sales Efficiency",
        icon: Icons.pie_chart_outline,
        color: const Color(0xFF1B5E20),
      ),
      FinanceKpiCard(
        label: "ROI Index",
        value: "${analytics.roiPct.toStringAsFixed(1)}%",
        subtext: "Return Rate",
        icon: Icons.stars_outlined,
        color: const Color(0xFFF57F17),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 94,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: kpiList.length,
      itemBuilder: (context, index) => kpiList[index],
    );
  }
}

/// Unit economics per-bird metrics row.
class FinanceUnitEconomicsRow extends StatelessWidget {
  final FinanceAnalyticsResult analytics;

  const FinanceUnitEconomicsRow({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FinanceKpiCard(
            label: "Revenue / Bird",
            value: "₹${analytics.revenuePerBird.toStringAsFixed(0)}",
            subtext: "Per Bird Sales",
            icon: Icons.person,
            color: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FinanceKpiCard(
            label: "Cost / Bird",
            value: "₹${analytics.costPerBird.toStringAsFixed(0)}",
            subtext: "Per Bird Cost",
            icon: Icons.person_outline,
            color: const Color(0xFFE65100),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FinanceKpiCard(
            label: "Feed Cost / Bird",
            value: "₹${analytics.feedCostPerBird.toStringAsFixed(0)}",
            subtext: "Feed Share",
            icon: Icons.grass,
            color: const Color(0xFF00838F),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FinanceKpiCard(
            label: "Med Cost / Bird",
            value: "₹${analytics.medicineCostPerBird.toStringAsFixed(0)}",
            subtext: "Vet Share",
            icon: Icons.medication,
            color: Colors.purple.shade700,
          ),
        ),
      ],
    );
  }
}
