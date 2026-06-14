import 'package:flutter/material.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Finance', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('Track expenses, sales, and P&L for your farm batches.', style: TextStyle(fontSize: 16)),
              SizedBox(height: 24),
              Text('Coming soon: expense logging, sales entry, and profit summaries.', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
