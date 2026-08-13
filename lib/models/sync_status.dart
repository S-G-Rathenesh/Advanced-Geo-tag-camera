/// Synchronization status for an evidence record.
enum SyncStatus {
  /// Evidence captured, queued, waiting for upload.
  pending,

  /// Currently being uploaded to the server.
  syncing,

  /// Successfully uploaded and confirmed by the server.
  synced,

  /// Upload attempted but failed; eligible for retry.
  failed,
}

/// Extension to convert between the enum and its string name.
extension SyncStatusExtension on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Failed';
    }
  }

  /// Parse from a string (e.g. from SQLite or JSON).
  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncStatus.pending,
    );
  }
}
