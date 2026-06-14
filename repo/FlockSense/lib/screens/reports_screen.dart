import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('Build snapshots for your flock performance and batch reports.', style: TextStyle(fontSize: 16)),
              SizedBox(height: 24),
              Text('Coming soon: CSV export, PDF summary, and trend charts.', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
