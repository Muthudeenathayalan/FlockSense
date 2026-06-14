import 'package:flutter/material.dart';

class FeedInventoryScreen extends StatelessWidget {
  const FeedInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed Inventory')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Text('Feed Inventory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('Track feed stock, purchases, and consumption for every batch.'),
              SizedBox(height: 24),
              Text('Coming soon: live feed stock, reorder alerts, and consumption analytics.'),
            ],
          ),
        ),
      ),
    );
  }
}
