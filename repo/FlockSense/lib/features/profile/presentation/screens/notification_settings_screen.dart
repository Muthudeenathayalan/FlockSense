import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _mortality = true;
  bool _feed = true;
  bool _vaccine = true;
  bool _daily = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings'), backgroundColor: AppColors.primary),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SwitchListTile(title: const Text('Mortality alerts'), value: _mortality, onChanged: (v) => setState(() => _mortality = v)),
        SwitchListTile(title: const Text('Feed alerts'), value: _feed, onChanged: (v) => setState(() => _feed = v)),
        SwitchListTile(title: const Text('Vaccine reminders'), value: _vaccine, onChanged: (v) => setState(() => _vaccine = v)),
        SwitchListTile(title: const Text('Daily reminders'), value: _daily, onChanged: (v) => setState(() => _daily = v)),
        const SizedBox(height: 12),
        FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved'))), child: const Text('Save')),
      ]),
    );
  }
}
