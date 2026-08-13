import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_theme.dart';
import '../../models/evidence_record.dart';
import '../../models/sync_status.dart';
import '../../services/evidence_service.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/secure_app_bar.dart';
import '../../widgets/status_badge.dart';

/// Full evidence metadata display.
class EvidenceDetailsScreen extends StatefulWidget {
  const EvidenceDetailsScreen({super.key});

  @override
  State<EvidenceDetailsScreen> createState() => _EvidenceDetailsScreenState();
}

class _EvidenceDetailsScreenState extends State<EvidenceDetailsScreen> {
  EvidenceRecord? _record;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final captureId =
        ModalRoute.of(context)?.settings.arguments as String?;

    if (captureId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final record =
        await context.read<EvidenceService>().getEvidence(captureId);

    if (mounted) {
      setState(() {
        _record = record;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFA6)),
        ),
      );
    }

    if (_record == null) {
      return Scaffold(
        appBar: const SecureAppBar(title: 'Evidence Not Found'),
        body: const Center(child: Text('Evidence record not found')),
      );
    }

    final record = _record!;

    return Scaffold(
      appBar: SecureAppBar(
        title: 'Evidence Details',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StatusBadge(status: record.syncStatus),
          ),
        ],
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: File(record.imagePath).existsSync()
                      ? Image.file(
                          File(record.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),

              const SizedBox(height: 20),

              // Capture ID
              _DetailSection(
                title: 'Identification',
                children: [
                  _DetailRow('Capture ID', record.captureId),
                  _DetailRow('User ID', record.userId),
                  _DetailRow('Device ID', record.deviceId),
                ],
              ),

              const SizedBox(height: 16),

              // Location
              _DetailSection(
                title: 'Location Data',
                icon: Icons.location_on_rounded,
                iconColor: AppTheme.statusSynced,
                children: [
                  _DetailRow(
                      'Latitude', record.latitude.toStringAsFixed(6)),
                  _DetailRow(
                      'Longitude', record.longitude.toStringAsFixed(6)),
                  _DetailRow(
                    'Altitude',
                    record.altitude != null
                        ? '${record.altitude!.toStringAsFixed(1)}m'
                        : 'N/A',
                  ),
                  _DetailRow(
                    'Accuracy',
                    '±${record.accuracy.toStringAsFixed(1)}m',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Timestamps
              _DetailSection(
                title: 'Timestamps',
                icon: Icons.access_time_rounded,
                iconColor: const Color(0xFF3D8BFF),
                children: [
                  _DetailRow('Captured', dateFormat.format(record.timestamp)),
                  _DetailRow('Created', dateFormat.format(record.createdAt)),
                  _DetailRow('Updated', dateFormat.format(record.updatedAt)),
                ],
              ),

              const SizedBox(height: 16),

              // Security
              _DetailSection(
                title: 'Integrity & Security',
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFFFFAB00),
                children: [
                  _DetailRow('SHA-256 Hash', record.sha256Hash,
                      isMonospace: true),
                  _DetailRow('Sync Status', record.syncStatus.label),
                  _DetailRow(
                      'Retry Count', record.retryCount.toString()),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFF1A2940),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 40, color: Color(0xFF6B7A8D)),
            SizedBox(height: 8),
            Text(
              'Image encrypted or deleted',
              style: TextStyle(color: Color(0xFF6B7A8D), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    this.icon,
    this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2940),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7A8D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMonospace;

  const _DetailRow(this.label, this.value, {this.isMonospace = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7A8D),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
