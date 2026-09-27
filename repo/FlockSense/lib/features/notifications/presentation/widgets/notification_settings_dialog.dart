import 'package:flutter/material.dart';
import 'package:flock_sense/core/services/notification_service.dart';
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
  late bool _dailyReminderEnabled;
  late String _dailyReminderTime;
  late bool _dailySmartTipsEnabled;

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
    _dailyReminderEnabled = widget.currentSettings.dailyReminderEnabled;
    _dailyReminderTime = widget.currentSettings.dailyReminderTime;
    _dailySmartTipsEnabled = widget.currentSettings.dailySmartTipsEnabled;
  }

  String _formatTimeDisplay(String timeStr) {
    final parts = timeStr.split(':');
    final h = int.tryParse(parts[0]) ?? 18;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final displayM = m.toString().padLeft(2, '0');
    return '${displayH.toString().padLeft(2, '0')}:$displayM $period';
  }

  Future<void> _pickDailyTime() async {
    final parts = _dailyReminderTime.split(':');
    final initialHour = int.tryParse(parts[0]) ?? 18;
    final initialMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _dailyReminderTime = '$hh:$mm';
      });
    }
  }

  Future<void> _pickQuietHour({required bool isStart}) async {
    final timeStr = isStart ? _quietHoursStart : _quietHoursEnd;
    final parts = timeStr.split(':');
    final initialHour = int.tryParse(parts[0]) ?? (isStart ? 22 : 6);
    final initialMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      setState(() {
        if (isStart) {
          _quietHoursStart = '$hh:$mm';
        } else {
          _quietHoursEnd = '$hh:$mm';
        }
      });
    }
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
      dailyReminderEnabled: _dailyReminderEnabled,
      dailyReminderTime: _dailyReminderTime,
      dailySmartTipsEnabled: _dailySmartTipsEnabled,
    );

    await NotificationFirestoreService.updateSettings(updated);

    final parts = _dailyReminderTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 18;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final prefsMap = await NotificationService.getPreferences();
    await NotificationService.savePreferences(
      daily: _dailyReminderEnabled,
      mortality: prefsMap['mortality'] ?? true,
      vaccine: prefsMap['vaccine'] ?? true,
      feed: prefsMap['feed'] ?? false,
      dailyHour: hour,
      dailyMinute: minute,
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Notification Preferences',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section 1: Daily Telemetry & Smart Guidance ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.today, size: 18, color: Color(0xFF1B5E20)),
                  SizedBox(width: 8),
                  Text(
                    'Daily Telemetry & Smart Guidance',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Daily Data Push Reminder',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Remind you each day to log mortality, feed & water',
                style: TextStyle(fontSize: 11),
              ),
              value: _dailyReminderEnabled,
              onChanged: (v) => setState(() => _dailyReminderEnabled = v),
            ),
            if (_dailyReminderEnabled) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reminder Time',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTimeDisplay(_dailyReminderTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        side: const BorderSide(color: Color(0xFF1B5E20)),
                      ),
                      icon: const Icon(Icons.access_time, size: 16, color: Color(0xFF1B5E20)),
                      label: const Text('Change Time', style: TextStyle(fontSize: 11, color: Color(0xFF1B5E20))),
                      onPressed: _pickDailyTime,
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Smart Breed Guidance',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Include age-specific feed targets & health tips with reminders',
                  style: TextStyle(fontSize: 11),
                ),
                value: _dailySmartTipsEnabled,
                onChanged: (v) => setState(() => _dailySmartTipsEnabled = v),
              ),
            ],
            const Divider(),

            // --- Section 2: Delivery Channels ---
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Push Notifications (FCM)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Receive push alerts when app is closed',
                style: TextStyle(fontSize: 11),
              ),
              value: _pushEnabled,
              onChanged: (v) => setState(() => _pushEnabled = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Local Device Notifications',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Show banners & reminders locally',
                style: TextStyle(fontSize: 11),
              ),
              value: _localEnabled,
              onChanged: (v) => setState(() => _localEnabled = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'AI Predictive Insights',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Get smart alerts for mortality spikes & feed ratios',
                style: TextStyle(fontSize: 11),
              ),
              value: _aiEnabled,
              onChanged: (v) => setState(() => _aiEnabled = v),
            ),
            const Divider(),

            // --- Section 3: Audio & Vibration ---
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Sound Alerts',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              value: _soundEnabled,
              onChanged: (v) => setState(() => _soundEnabled = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Vibration Alerts',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              value: _vibrationEnabled,
              onChanged: (v) => setState(() => _vibrationEnabled = v),
            ),
            const Divider(),

            // --- Section 4: Quiet Hours ---
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Quiet Hours (Do Not Disturb)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Silence alerts between ${_formatTimeDisplay(_quietHoursStart)} and ${_formatTimeDisplay(_quietHoursEnd)}',
                style: const TextStyle(fontSize: 11),
              ),
              value: _quietHoursEnabled,
              onChanged: (v) => setState(() => _quietHoursEnabled = v),
            ),
            if (_quietHoursEnabled) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        icon: const Icon(Icons.bedtime_outlined, size: 16),
                        label: Text('From: ${_formatTimeDisplay(_quietHoursStart)}', style: const TextStyle(fontSize: 11)),
                        onPressed: () => _pickQuietHour(isStart: true),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        icon: const Icon(Icons.wb_sunny_outlined, size: 16),
                        label: Text('To: ${_formatTimeDisplay(_quietHoursEnd)}', style: const TextStyle(fontSize: 11)),
                        onPressed: () => _pickQuietHour(isStart: false),
                      ),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Emergency Alerts Override',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                subtitle: const Text(
                  'Allow critical mortality & disease alerts during Quiet Hours',
                  style: TextStyle(fontSize: 11),
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
