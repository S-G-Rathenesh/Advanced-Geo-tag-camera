import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/evidence_record.dart';
import 'status_badge.dart';

/// Evidence list item card with thumbnail, metadata, and status badge.
class EvidenceCard extends StatelessWidget {
  final EvidenceRecord record;
  final String? userName;
  final VoidCallback? onTap;
  final VoidCallback? onUserTap;

  const EvidenceCard({
    super.key,
    required this.record,
    this.userName,
    this.onTap,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildThumbnail(),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ID: ${record.captureId.substring(0, 8)}…',
                            style: theme.textTheme.labelLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(status: record.syncStatus),
                      ],
                    ),
                    if (userName != null) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: onUserTap,
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                userName!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${record.latitude.toStringAsFixed(5)}, ${record.longitude.toStringAsFixed(5)}',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(record.timestamp),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withAlpha(100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    // On web, dart:io File is not available
    if (kIsWeb) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2940),
          borderRadius: BorderRadius.circular(10),
        ),
        child: record.imagePath.startsWith('http')
            ? Image.network(
                record.imagePath,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholderIcon(),
              )
            : _placeholderIcon(),
      );
    }

    final file = File(record.imagePath);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2940),
        borderRadius: BorderRadius.circular(10),
      ),
      child: file.existsSync()
          ? Image.file(
              file,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholderIcon(),
            )
          : _placeholderIcon(),
    );
  }

  Widget _placeholderIcon() {
    return const Center(
      child: Icon(
        Icons.photo_camera_rounded,
        color: Color(0xFF6B7A8D),
        size: 24,
      ),
    );
  }
}
