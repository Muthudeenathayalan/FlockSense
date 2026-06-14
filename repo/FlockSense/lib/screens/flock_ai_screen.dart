import 'package:flutter/material.dart';

class FlockAiScreen extends StatelessWidget {
  const FlockAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flock AI')),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Flock AI is coming soon. Get predictions and poultry insights in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
