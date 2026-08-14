import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../models/evidence_record.dart';
import '../../models/sync_status.dart';
import '../../services/evidence_service.dart';
import '../../services/sync_service.dart';

/// Tactical Sync Status Queue screen matching the design system.
class SyncStatusScreen extends StatefulWidget {
  final bool showBottomNav;

  const SyncStatusScreen({super.key, this.showBottomNav = false});

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
    final evidenceService = context.watch<EvidenceService>();
    final syncService = context.watch<SyncService>();
    final dateFormat = DateFormat('HH:mm:ss');

    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      appBar: widget.showBottomNav
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF060B14),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Sync Queue',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sync Queue',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (syncService.isSyncing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Syncing',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Summary Metrics Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1322),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCountMetric(
                      'Pending',
                      evidenceService.pendingCount.toString(),
                      const Color(0xFFF59E0B),
                    ),
                    Container(width: 1, height: 28, color: const Color(0xFF1E293B)),
                    _buildCountMetric(
                      'Synced',
                      evidenceService.syncedCount.toString(),
                      const Color(0xFF10B981),
                    ),
                    Container(width: 1, height: 28, color: const Color(0xFF1E293B)),
                    _buildCountMetric(
                      'Failed',
                      evidenceService.failedCount.toString(),
                      const Color(0xFFEF4444),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Last Sync Status Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  if (syncService.lastSyncTime != null)
                    Text(
                      'Last sync: ${dateFormat.format(syncService.lastSyncTime!)}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    )
                  else
                    Text(
                      'Auto-sync standby',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  const Spacer(),
                  if (syncService.lastError != null)
                    Flexible(
                      child: Text(
                        syncService.lastError!,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFEF4444),
                          fontSize: 11.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: Color(0xFF1E293B), height: 1),

            // Evidence Queue List
            Expanded(
              child: evidenceService.evidenceList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_done_outlined,
                            size: 48,
                            color: Color(0xFF334155),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'All evidence synchronized',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8E9EB5),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Local database and cloud hashes match.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 80),
                      itemCount: evidenceService.evidenceList.length,
                      itemBuilder: (context, index) {
                        final record = evidenceService.evidenceList[index];
                        return _buildQueueTile(record);
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
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(
          syncService.isSyncing
              ? Icons.hourglass_top_rounded
              : Icons.sync_rounded,
          size: 20,
        ),
        label: Text(
          syncService.isSyncing ? 'Syncing...' : 'Sync Now',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
      ),
    );
  }

  Widget _buildCountMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF8E9EB5),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueTile(EvidenceRecord record) {
    final isSynced = record.syncStatus == SyncStatus.synced;
    final isFailed = record.syncStatus == SyncStatus.failed;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.evidenceDetails,
          arguments: record,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1322),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            // Status Icon Container
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSynced
                    ? const Color(0xFF052E16)
                    : isFailed
                        ? const Color(0xFF1C1318)
                        : const Color(0xFF1E180A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSynced
                      ? const Color(0xFF10B981)
                      : isFailed
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B),
                ),
              ),
              child: Icon(
                isSynced
                    ? Icons.cloud_done_rounded
                    : isFailed
                        ? Icons.error_outline_rounded
                        : Icons.cloud_upload_outlined,
                color: isSynced
                    ? const Color(0xFF10B981)
                    : isFailed
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          record.captureId,
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    record.address ?? 'Bengaluru, India',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8E9EB5),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: isSynced
                    ? const Color(0xFF052E16)
                    : isFailed
                        ? const Color(0xFF1C1318)
                        : const Color(0xFF451A03),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isSynced
                      ? const Color(0xFF10B981)
                      : isFailed
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B),
                ),
              ),
              child: Text(
                isSynced
                    ? 'Synced'
                    : isFailed
                        ? 'Failed'
                        : 'Pending',
                style: GoogleFonts.inter(
                  color: isSynced
                      ? const Color(0xFF10B981)
                      : isFailed
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
