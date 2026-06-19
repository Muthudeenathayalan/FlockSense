import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/action_tile.dart';
import 'package:flock_sense/core/widgets/section_header.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('More'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Explore more tools', subtitle: 'Helpful services and farm resources'),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    ActionTile(icon: Icons.smart_toy, label: 'FlockSense AI', onTap: () {}),
                    ActionTile(icon: Icons.bar_chart, label: 'Reports', onTap: () {}),
                    ActionTile(icon: Icons.cloud, label: 'Weather', onTap: () {}),
                    ActionTile(icon: Icons.show_chart, label: 'FCR', onTap: () {}),
                    ActionTile(icon: Icons.help_outline, label: 'FAQ', onTap: () {}),
                    ActionTile(icon: Icons.support_agent, label: 'Contact Us', onTap: () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
