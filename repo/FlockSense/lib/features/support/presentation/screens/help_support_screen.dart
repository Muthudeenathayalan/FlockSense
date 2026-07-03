import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support'), backgroundColor: AppColors.primary),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          SizedBox(height: 12),
          Text('Help & Support', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('Contact support or view FAQs.'),
        ]),
      ),
    );
  }
}
