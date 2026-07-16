import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_list_screen.dart';

class DailyRecordsPlaceholderScreen extends StatelessWidget {
  const DailyRecordsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Daily Records')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_note, size: 62, color: AppColors.primary),
              const SizedBox(height: 14),
              Text(
                'Fast daily entry is ready',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Use Add Records from the bottom navigation on Home, or open a farm and batch to create records.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FarmListScreen()),
                  );
                },
                icon: const Icon(Icons.agriculture_outlined),
                label: const Text('Open Farms'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
