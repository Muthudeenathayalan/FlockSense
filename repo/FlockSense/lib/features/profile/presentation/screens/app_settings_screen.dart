import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/reports/data/batch_completion_report_service.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _autoDownloadReport = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final pref = await BatchCompletionReportService.isAutoDownloadEnabled();
    if (mounted) {
      setState(() {
        _autoDownloadReport = pref ?? true;
        _loading = false;
      });
    }
  }

  Future<void> _toggleAutoDownload(bool val) async {
    setState(() => _autoDownloadReport = val);
    await BatchCompletionReportService.setAutoDownloadEnabled(val);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            val
                ? 'Auto-download on batch completion enabled'
                : 'Auto-download disabled (you will be prompted on completion)',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile.adaptive(
            title: const Text(
              'Auto-save reports on batch finish',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Automatically download the complete 15-page PDF audit to phone storage when a flock cycle completes',
              style: TextStyle(fontSize: 12),
            ),
            value: _autoDownloadReport,
            activeColor: AppColors.primary,
            onChanged: _loading ? null : _toggleAutoDownload,
          ),
          const Divider(),
          const ListTile(
            title: Text('Dark mode'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            title: Text('Language'),
            subtitle: Text('English'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            title: Text('Data sync'),
            subtitle: Text('Cloud Firestore (Automatic)'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
