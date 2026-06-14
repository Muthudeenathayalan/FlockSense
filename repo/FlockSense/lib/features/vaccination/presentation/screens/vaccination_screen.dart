import 'package:flutter/material.dart';

class VaccinationScreen extends StatelessWidget {
  const VaccinationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vaccination Schedule')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Vaccination Schedule', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('View due vaccines, completed schedules, and reminders.'),
              SizedBox(height: 24),
              Text('Coming soon: calendar view, due alerts, and vaccine history.'),
            ],
          ),
        ),
      ),
    );
  }
}
