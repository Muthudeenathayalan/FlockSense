import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

class DailyRecordsPlaceholderScreen extends StatelessWidget {
  const DailyRecordsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Records'), backgroundColor: AppColors.primary),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          SizedBox(height: 12),
          Text('Daily Records', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('Track mortality, feed, water, medicine, vaccine, and weight here.'),
        ]),
      ),
    );
  }
}
