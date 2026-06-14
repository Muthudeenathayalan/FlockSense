import 'package:flutter/material.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flock AI')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Flock AI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('Get disease prediction, symptom insights, and recommended actions.'),
              SizedBox(height: 24),
              Text('Coming soon: AI-powered disease risk detection and action plans.'),
            ],
          ),
        ),
      ),
    );
  }
}
