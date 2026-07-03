import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

class VaccineRecordsScreen extends StatelessWidget {
  const VaccineRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vaccine Records'), backgroundColor: AppColors.primary),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          SizedBox(height: 12),
          Text('Vaccine Records', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('Track vaccine schedule, given date, batch number, and expiry.'),
        ]),
      ),
    );
  }
}
