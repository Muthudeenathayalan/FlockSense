import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/models/sync_status.dart';
import 'package:flock_sense/core/providers/connectivity_provider.dart';

class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key, required this.syncStatus});
  final SyncStatus syncStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).maybeWhen(
      data: (v) => v,
      orElse: () => true,
    );

    String? message;
    Color color;
    IconData icon;

    if (!isOnline) {
      message = "You're offline. Changes are saved locally and will sync when back online.";
      color = Colors.orange.shade800;
      icon = Icons.cloud_off_outlined;
    } else if (syncStatus.hasPendingWrites) {
      message = 'Syncing your changes to the cloud...';
      color = Colors.blue.shade700;
      icon = Icons.cloud_sync_outlined;
    } else {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      color: color.withValues(alpha: 0.13),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
