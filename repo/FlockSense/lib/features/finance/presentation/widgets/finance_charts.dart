import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RevenueExpenseChart extends StatelessWidget {
  const RevenueExpenseChart({super.key});

  @override
  Widget build(BuildContext context) {
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Track cumulative growth and cost trajectory',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              const Icon(Icons.analytics_outlined, size: 22, color: Color(0xFF1B5E20)),
            ],
          ),
          const SizedBox(height: 12),

          // Legend Row
          Row(
            children: [
              _buildLegendBadge('Revenue (Gross Sales)', const Color(0xFF1B5E20)),
              const SizedBox(width: 16),
              _buildLegendBadge('Expenses (Production Cost)', const Color(0xFFE65100)),
            ],
          ),
          const SizedBox(height: 16),

          // Large Chart Area
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 50000,
                  getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  getDrawingVerticalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('0', style: TextStyle(fontSize: 10, color: Colors.grey));
                        return Text('₹${(value / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold));
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
                          return Text('Wk $week', style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isRevenue = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${isRevenue ? "Revenue" : "Expense"}: ₹${spot.y.toStringAsFixed(0)}',
                          TextStyle(
                            color: isRevenue ? Colors.green.shade200 : Colors.orange.shade200,
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
                    spots: const [
                      FlSpot(1, 40000), FlSpot(2, 85000), FlSpot(3, 160000),
                      FlSpot(4, 240000), FlSpot(5, 320000),
                    ],
                    isCurved: true,
                    color: const Color(0xFF1B5E20),
                    barWidth: 3.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1B5E20).withAlpha((0.08 * 255).toInt()),
                    ),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 35000), FlSpot(2, 70000), FlSpot(3, 125000),
                      FlSpot(4, 175000), FlSpot(5, 235000),
                    ],
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
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}

class ExpensePieChart extends StatelessWidget {
  const ExpensePieChart({super.key});

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20)),
              ),
              Icon(Icons.pie_chart, size: 22, color: Color(0xFF1B5E20)),
            ],
          ),
          const SizedBox(height: 14),

          // Large Pie Chart
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 42,
                      sections: [
                        PieChartSectionData(color: const Color(0xFF1B5E20), value: 68, title: '68%\nFeed', radius: 55, titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        PieChartSectionData(color: const Color(0xFFE65100), value: 18, title: '18%\nChicks', radius: 52, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        PieChartSectionData(color: const Color(0xFF00838F), value: 7, title: '7%\nMed', radius: 48, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        PieChartSectionData(color: Colors.purple.shade700, value: 7, title: '7%\nMisc', radius: 46, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Side Legend Details Table
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPieLegendRow('Feed Pellets', '68% (₹160k)', const Color(0xFF1B5E20)),
                      const SizedBox(height: 8),
                      _buildPieLegendRow('Day-Old Chicks', '18% (₹42k)', const Color(0xFFE65100)),
                      const SizedBox(height: 8),
                      _buildPieLegendRow('Meds & Vaccine', '7% (₹16k)', const Color(0xFF00838F)),
                      const SizedBox(height: 8),
                      _buildPieLegendRow('Labour & Misc', '7% (₹17k)', Colors.purple.shade700),
                    ],
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
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87))),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 1),
          child: Text(share, style: TextStyle(fontSize: 9, color: Colors.grey.shade700)),
        ),
      ],
    );
  }
}
