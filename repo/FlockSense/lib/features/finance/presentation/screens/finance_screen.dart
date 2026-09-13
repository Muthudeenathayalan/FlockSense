import 'package:flutter/material.dart';
import 'package:flock_sense/features/finance/presentation/screens/finance_dashboard_screen.dart';

/// Legacy navigation alias routing directly to [FinanceDashboardScreen].
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FinanceDashboardScreen();
  }
}
