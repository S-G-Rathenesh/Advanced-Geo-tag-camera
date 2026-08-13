import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/app_theme.dart';
import '../../models/sync_status.dart';
import '../../services/evidence_service.dart';
import '../../services/sync_service.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/secure_app_bar.dart';
import '../../widgets/status_badge.dart';

/// Upload queue view showing all evidence items with sync status.
class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvidenceService>().loadEvidence();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evidenceService = context.watch<EvidenceService>();
    final syncService = context.watch<SyncService>();
    final dateFormat = DateFormat('HH:mm:ss');

    return Scaffold(
      appBar: SecureAppBar(
        title: 'Sync Status',
        actions: [
          if (syncService.isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00BFA6),
                ),
              ),
            ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Status summary cards
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  _StatusCountCard(
                    status: SyncStatus.pending,
                    count: evidenceService.pendingCount,
                  ),
                  const SizedBox(width: 10),
                  _StatusCountCard(
                    status: SyncStatus.synced,
                    count: evidenceService.syncedCount,
                  ),
                  const SizedBox(width: 10),
                  _StatusCountCard(
                    status: SyncStatus.failed,
                    count: evidenceService.failedCount,
                  ),
                ],
              ),
            ),

            // Last sync time and error
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  if (syncService.lastSyncTime != null)
                    Text(
                      'Last sync: ${dateFormat.format(syncService.lastSyncTime!)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  const Spacer(),
                  if (syncService.lastError != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_rounded,
                            size: 14, color: AppTheme.statusFailed),
                        const SizedBox(width: 4),
                        Text(
                          syncService.lastError!,
                          style: TextStyle(
                            color: AppTheme.statusFailed,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const Divider(
              color: Color(0xFF1A2940),
              height: 1,
              indent: 20,
              endIndent: 20,
            ),

            // Evidence list
            Expanded(
              child: evidenceService.evidenceList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_queue_rounded,
                              size: 48, color: Color(0xFF6B7A8D)),
                          const SizedBox(height: 12),
                          Text(
                            'No evidence in queue',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: evidenceService.evidenceList.length,
                      itemBuilder: (context, index) {
                        final record =
                            evidenceService.evidenceList[index];
                        return _SyncItemTile(
                          record: record,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.evidenceDetails,
                              arguments: record.captureId,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: syncService.isSyncing
            ? null
            : () async {
                final evService = context.read<EvidenceService>();
                await syncService.syncAll();
                if (mounted) {
                  evService.loadEvidence();
                }
              },
        icon: Icon(
          syncService.isSyncing
              ? Icons.hourglass_top_rounded
              : Icons.sync_rounded,
        ),
        label: Text(syncService.isSyncing ? 'Syncing...' : 'Sync Now'),
      ),
    );
  }
}

class _StatusCountCard extends StatelessWidget {
  final SyncStatus status;
  final int count;

  const _StatusCountCard({
    required this.status,
    required this.count,
  });

  Color get _color {
    switch (status) {
      case SyncStatus.pending:
        return AppTheme.statusPending;
      case SyncStatus.synced:
        return AppTheme.statusSynced;
      case SyncStatus.failed:
        return AppTheme.statusFailed;
      case SyncStatus.syncing:
        return AppTheme.statusSyncing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: _color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              status.label,
              style: TextStyle(
                color: _color.withAlpha(180),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncItemTile extends StatelessWidget {
  final dynamic record;
  final VoidCallback? onTap;

  const _SyncItemTile({required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, HH:mm');

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2940),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.photo_camera_rounded,
          color: Color(0xFF6B7A8D),
          size: 20,
        ),
      ),
      title: Text(
        'ID: ${record.captureId.substring(0, 8)}…',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        dateFormat.format(record.timestamp),
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A8D)),
      ),
      trailing: StatusBadge(status: record.syncStatus, showLabel: false),
    );
  }
}
