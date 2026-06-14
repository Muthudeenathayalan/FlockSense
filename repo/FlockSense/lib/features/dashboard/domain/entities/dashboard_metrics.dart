class DashboardMetrics {
  final int totalFlocks;
  final int totalBirds;
  final double averageTargetFcr;
  final int totalMortality;
  final double totalFeedKg;
  final double revenue;
  final double expenses;
  final double profitLoss;
  final int pendingVaccinations;

  const DashboardMetrics({
    required this.totalFlocks,
    required this.totalBirds,
    required this.averageTargetFcr,
    required this.totalMortality,
    required this.totalFeedKg,
    required this.revenue,
    required this.expenses,
    required this.profitLoss,
    required this.pendingVaccinations,
  });

  static const empty = DashboardMetrics(
    totalFlocks: 0,
    totalBirds: 0,
    averageTargetFcr: 0.0,
    totalMortality: 0,
    totalFeedKg: 0.0,
    revenue: 0.0,
    expenses: 0.0,
    profitLoss: 0.0,
    pendingVaccinations: 0,
  );
}
