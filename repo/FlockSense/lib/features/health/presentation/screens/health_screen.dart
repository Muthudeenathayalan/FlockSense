import 'package:flutter/material.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Records')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Health Records', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('Log symptoms, treatments, and health observations for your flocks.'),
              SizedBox(height: 24),
              Text('Coming soon: disease tracking, recovery progress, and treatment history.'),
            ],
          ),
        ),
      ),
    );
  }
}
