import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

class BirdSalesScreen extends StatelessWidget {
  const BirdSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bird Sales'), backgroundColor: AppColors.primary),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          SizedBox(height: 12),
          Text('Bird Sales', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('Track sold birds, weight, average weight, and closing stock.'),
        ]),
      ),
    );
  }
}
