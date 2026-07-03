import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Settings'), backgroundColor: AppColors.primary),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(title: const Text('Dark mode'), trailing: const Icon(Icons.chevron_right)),
        ListTile(title: const Text('Language'), subtitle: const Text('English'), trailing: const Icon(Icons.chevron_right)),
        ListTile(title: const Text('Data sync'), subtitle: const Text('Manual or Auto'), trailing: const Icon(Icons.chevron_right)),
      ]),
    );
  }
}
