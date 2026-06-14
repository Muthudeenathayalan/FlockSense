import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Frequently Asked Questions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                '1. How do I add a new flock batch?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Use the "Batch" section under My Farms to create and manage batches.',
              ),
              SizedBox(height: 16),
              Text(
                '2. Where can I view farm reports?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Open the Reports section from the More tab to see weekly and monthly summaries.',
              ),
              SizedBox(height: 16),
              Text(
                '3. How do I contact support?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Use the Contact Us page under More to send your questions or feedback.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
