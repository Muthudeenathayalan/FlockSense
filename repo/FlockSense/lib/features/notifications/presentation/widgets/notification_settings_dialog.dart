import 'package:flutter/material.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';
import 'package:flock_sense/features/notifications/data/services/notification_firestore_service.dart';

class NotificationSettingsDialog extends StatefulWidget {
  final NotificationSettingsModel currentSettings;

  const NotificationSettingsDialog({super.key, required this.currentSettings});

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
  late bool _pushEnabled;
  late bool _localEnabled;
  late bool _aiEnabled;
  late bool _soundEnabled;
  late bool _vibrationEnabled;
  late bool _quietHoursEnabled;
  late String _quietHoursStart;
  late String _quietHoursEnd;
  late bool _emergencyOverride;

  @override
  void initState() {
    super.initState();
    _pushEnabled = widget.currentSettings.pushEnabled;
    _localEnabled = widget.currentSettings.localEnabled;
    _aiEnabled = widget.currentSettings.aiEnabled;
    _soundEnabled = widget.currentSettings.soundEnabled;
    _vibrationEnabled = widget.currentSettings.vibrationEnabled;
    _quietHoursEnabled = widget.currentSettings.quietHoursEnabled;
    _quietHoursStart = widget.currentSettings.quietHoursStart;
    _quietHoursEnd = widget.currentSettings.quietHoursEnd;
    _emergencyOverride = widget.currentSettings.emergencyOverride;
  }

  Future<void> _save() async {
    final updated = NotificationSettingsModel(
      pushEnabled: _pushEnabled,
      localEnabled: _localEnabled,
      aiEnabled: _aiEnabled,
      soundEnabled: _soundEnabled,
      vibrationEnabled: _vibrationEnabled,
      quietHoursEnabled: _quietHoursEnabled,
      quietHoursStart: _quietHoursStart,
      quietHoursEnd: _quietHoursEnd,
      emergencyOverride: _emergencyOverride,
    );

    await NotificationFirestoreService.updateSettings(updated);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Preferences & Quiet Hours'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text(
                'Push Notifications (FCM)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Receive push alerts when app is closed',
                style: TextStyle(fontSize: 10),
              ),
              value: _pushEnabled,
              onChanged: (v) => setState(() => _pushEnabled = v),
            ),
            SwitchListTile(
              title: const Text(
                'Local Device Notifications',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Show banners & reminders locally',
                style: TextStyle(fontSize: 10),
              ),
              value: _localEnabled,
              onChanged: (v) => setState(() => _localEnabled = v),
            ),
            SwitchListTile(
              title: const Text(
                'AI Predictive Recommendations',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Get smart insights for mortality & feed usage',
                style: TextStyle(fontSize: 10),
              ),
              value: _aiEnabled,
              onChanged: (v) => setState(() => _aiEnabled = v),
            ),
            const Divider(),

            SwitchListTile(
              title: const Text(
                'Sound Alerts',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              value: _soundEnabled,
              onChanged: (v) => setState(() => _soundEnabled = v),
            ),
            SwitchListTile(
              title: const Text(
                'Vibration Alerts',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              value: _vibrationEnabled,
              onChanged: (v) => setState(() => _vibrationEnabled = v),
            ),
            const Divider(),

            SwitchListTile(
              title: const Text(
                'Quiet Hours (Do Not Disturb)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Silence alerts between $_quietHoursStart and $_quietHoursEnd',
                style: const TextStyle(fontSize: 10),
              ),
              value: _quietHoursEnabled,
              onChanged: (v) => setState(() => _quietHoursEnabled = v),
            ),
            if (_quietHoursEnabled) ...[
              SwitchListTile(
                title: const Text(
                  'Emergency Alerts Override',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                subtitle: const Text(
                  'Allow Critical mortality & disease alerts during Quiet Hours',
                  style: TextStyle(fontSize: 10),
                ),
                value: _emergencyOverride,
                onChanged: (v) => setState(() => _emergencyOverride = v),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
          ),
          onPressed: _save,
          child: const Text('Save Settings'),
        ),
      ],
    );
  }
}
