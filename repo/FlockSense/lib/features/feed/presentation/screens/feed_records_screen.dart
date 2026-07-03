import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

class FeedRecordsScreen extends StatelessWidget {
  const FeedRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed Records'), backgroundColor: AppColors.primary),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          SizedBox(height: 12),
          Text('Feed Records', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('Track feed received, consumed, and closing feed stock.'),
        ]),
      ),
    );
  }
}
