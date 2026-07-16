import 'package:flutter/material.dart';
import 'package:flock_sense/core/services/notification_service.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _daily = true;
  bool _mortality = true;
  bool _vaccine = true;
  bool _feed = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await NotificationService.getPreferences();
    if (!mounted) return;
    setState(() {
      _daily = prefs['daily'] ?? true;
      _mortality = prefs['mortality'] ?? true;
      _vaccine = prefs['vaccine'] ?? true;
      _feed = prefs['feed'] ?? false;
      _loaded = true;
    });
  }

  Future<void> _savePrefs() async {
    await NotificationService.savePreferences(
      daily: _daily,
      mortality: _mortality,
      vaccine: _vaccine,
      feed: _feed,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification preferences saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
      ),
      body: _loaded
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: SwitchListTile(
                    title: const Text('Daily record reminder (7 PM)'),
                    value: _daily,
                    onChanged: (value) => setState(() => _daily = value),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: SwitchListTile(
                    title: const Text('High mortality alerts'),
                    value: _mortality,
                    onChanged: (value) => setState(() => _mortality = value),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: SwitchListTile(
                    title: const Text('Vaccination reminders'),
                    value: _vaccine,
                    onChanged: (value) => setState(() => _vaccine = value),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: SwitchListTile(
                    title: const Text('Low feed stock alerts'),
                    value: _feed,
                    onChanged: null,
                    subtitle: const Text('Coming soon'),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _savePrefs,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Save preferences'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    await NotificationService.showTestNotification();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Send test notification'),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
