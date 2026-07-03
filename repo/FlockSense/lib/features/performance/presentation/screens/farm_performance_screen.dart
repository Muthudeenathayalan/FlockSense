import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

class FarmPerformanceScreen extends StatelessWidget {
  const FarmPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farm Performance'), backgroundColor: AppColors.primary),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          SizedBox(height: 12),
          Text('Farm Performance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('Charts and KPIs for farm-level performance.'),
        ]),
      ),
    );
  }
}
