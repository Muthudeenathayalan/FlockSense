/// Describes whether the most recent data shown to the user is fully synced
/// with Firestore's server, or whether there's a local write still waiting
/// to reach it -- typically because the device is offline.
///
/// Firestore's SDK already tracks this for every snapshot via
/// `SnapshotMetadata` (`hasPendingWrites` / `isFromCache`); this class just
/// gives that information a clean, reusable shape so UI (like
/// [SyncStatusBanner]) doesn't need to know about Firestore types directly,
/// and so other features (Sheds, Batches, ...) can expose the same shape
/// later without re-inventing it.
class SyncStatus {
  final bool hasPendingWrites;
  final bool isFromCache;

  const SyncStatus({
    required this.hasPendingWrites,
    required this.isFromCache,
  });

  /// Nothing pending, data confirmed by the server.
  static const synced = SyncStatus(hasPendingWrites: false, isFromCache: false);

  bool get isFullySynced => !hasPendingWrites && !isFromCache;
}
