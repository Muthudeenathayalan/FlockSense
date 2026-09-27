import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/models/sync_status.dart';
import 'package:flock_sense/core/providers/connectivity_provider.dart';
import 'package:flock_sense/core/providers/sync_provider.dart';
import 'package:flock_sense/core/services/sync_service.dart';

class SyncStatusBanner extends ConsumerStatefulWidget {
  const SyncStatusBanner({super.key, this.syncStatus});
  final SyncStatus? syncStatus;

  @override
  ConsumerState<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends ConsumerState<SyncStatusBanner> {
  bool _isManualSyncing = false;

  Future<void> _handleManualSync() async {
    if (_isManualSyncing) return;
    setState(() => _isManualSyncing = true);
    try {
      await SyncService().syncPendingOperations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synced offline records with cloud successfully.'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync failed. Will retry automatically when stable.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isManualSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref
        .watch(connectivityProvider)
        .maybeWhen(data: (v) => v, orElse: () => true);

    final pendingOps = ref
        .watch(pendingOpsCountProvider)
        .maybeWhen(data: (v) => v, orElse: () => 0);

    String? message;
    Color color;
    IconData icon;
    bool showSyncButton = false;

    if (!isOnline) {
      if (pendingOps > 0) {
        message =
            "You're offline ($pendingOps ${pendingOps == 1 ? 'change' : 'changes'} queued). Records saved locally.";
      } else {
        message =
            "You're offline. Changes are saved locally and will sync when back online.";
      }
      color = Colors.orange.shade800;
      icon = Icons.cloud_off_outlined;
    } else if (pendingOps > 0) {
      message =
          'Syncing $pendingOps pending ${pendingOps == 1 ? 'record' : 'records'} to cloud...';
      color = Colors.blue.shade700;
      icon = Icons.cloud_sync_outlined;
      showSyncButton = true;
    } else if (widget.syncStatus?.hasPendingWrites == true) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showSyncButton) ...[
            const SizedBox(width: 8),
            _isManualSyncing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : TextButton(
                    onPressed: _handleManualSync,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: color.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Sync Now',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}

