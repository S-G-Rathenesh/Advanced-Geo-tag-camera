import 'package:flutter/material.dart';

import '../core/constants/app_theme.dart';
import '../models/sync_status.dart';

/// Colour-coded sync status badge indicator.
class StatusBadge extends StatelessWidget {
  final SyncStatus status;
  final double size;
  final bool showLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.size = 12,
    this.showLabel = true,
  });

  Color get _color {
    switch (status) {
      case SyncStatus.synced:
        return AppTheme.statusSynced;
      case SyncStatus.pending:
        return AppTheme.statusPending;
      case SyncStatus.failed:
        return AppTheme.statusFailed;
      case SyncStatus.syncing:
        return AppTheme.statusSyncing;
    }
  }

  IconData get _icon {
    switch (status) {
      case SyncStatus.synced:
        return Icons.cloud_done_rounded;
      case SyncStatus.pending:
        return Icons.schedule_rounded;
      case SyncStatus.failed:
        return Icons.error_outline_rounded;
      case SyncStatus.syncing:
        return Icons.sync_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 10 : 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: size),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: _color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
