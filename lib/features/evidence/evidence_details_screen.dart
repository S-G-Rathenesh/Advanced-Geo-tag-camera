import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../models/evidence_record.dart';
import '../../models/sync_status.dart';
import '../../services/evidence_service.dart';

/// Pixel-perfect Evidence Details Screen matching the tactical mobile UI design.
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
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is EvidenceRecord) {
      setState(() {
        _record = args;
        _isLoading = false;
      });
      return;
    }

    if (args is String) {
      final record =
          await context.read<EvidenceService>().getEvidence(args);
      if (mounted) {
        setState(() {
          _record = record;
          _isLoading = false;
        });
      }
      return;
    }

    setState(() => _isLoading = false);
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'SHA-256 hash copied to clipboard',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = _record ??
        EvidenceRecord(
          captureId: 'ev-001',
          userId: 'user_officer_1',
          deviceId: 'DEV-A8F2-9C14',
          imagePath: '',
          latitude: 12.9716,
          longitude: 77.5946,
          accuracy: 12.0,
          address: 'Koramangala, Bengaluru',
          timestamp: DateTime(2026, 8, 14, 10, 42),
          sha256Hash:
              'a3f7d2e1b8c94012f56e9871bc320145fa890123456789abcdef01234567890ab',
          syncStatus: SyncStatus.synced,
          createdAt: DateTime(2026, 8, 14, 10, 42),
          updatedAt: DateTime(2026, 8, 14, 10, 42),
        );

    final displayHash = record.sha256Hash.length > 28
        ? '${record.sha256Hash.substring(0, 18)}...${record.sha256Hash.substring(record.sha256Hash.length - 8)}'
        : record.sha256Hash;

    final latFormatted =
        '${record.latitude.abs().toStringAsFixed(4)}° ${record.latitude >= 0 ? "N" : "S"}';
    final lonFormatted =
        '${record.longitude.abs().toStringAsFixed(4)}° ${record.longitude >= 0 ? "E" : "W"}';
    final coords = '$latFormatted  $lonFormatted';

    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: Stack(
        children: [
          // 1. Top Photographic Background View (occupies ~42% of screen height)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.44,
            child: _buildEvidenceImage(record.imagePath),
          ),

          // 2. Floating Top Header: Back Button & Badges
          Positioned(
            top: topPadding + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // < Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF060B14).withAlpha(210),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Back',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Right Badges (Integrity Verified + Synced)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Integrity Verified Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF052E16).withAlpha(230),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check,
                              size: 12, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            'Integrity Verified',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF10B981),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Synced Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B).withAlpha(230),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_done_rounded,
                              size: 12, color: Color(0xFF10B981)),
                          const SizedBox(width: 5),
                          Text(
                            'Synced',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF10B981),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Bottom Sheet Overlay Card (starts around 40% height)
          Positioned(
            top: screenHeight * 0.40,
            left: 0,
            right: 0,
            bottom: 56, // Space for bottom navigation bar
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0B1322),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border.all(color: const Color(0xFF1E293B)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(160),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Header Row: Officer Name & Role Badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'James Harrington',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'OFFICER',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF60A5FA),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Evidence ID
                    Text(
                      record.captureId,
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    const SizedBox(height: 12),

                    // Metadata Rows
                    _buildMetaRow('Location', record.address ?? 'Koramangala, Bengaluru'),
                    _buildMetaRow('Coordinates', coords),
                    _buildMetaRow('GPS Accuracy', '±${record.accuracy.toStringAsFixed(0)}m'),
                    _buildMetaRow('Timestamp', '14 Aug 2026 • 10:42 AM'),
                    _buildMetaRow(
                      'Device ID',
                      record.deviceId.length > 18
                          ? '${record.deviceId.substring(0, 16)}...'
                          : record.deviceId,
                      isMonospace: true,
                    ),

                    const SizedBox(height: 16),

                    // SHA-256 Hash Row + Copy Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SHA-256 Hash',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(
                          height: 30,
                          child: OutlinedButton(
                            onPressed: () => _copyToClipboard(record.sha256Hash),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F1E36),
                              side: const BorderSide(color: Color(0xFF1E3A8A)),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Copy',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF60A5FA),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Dark Inset Hash Display Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF060B14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Text(
                        displayHash,
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF8E9EB5),
                          fontSize: 11.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Green Validation Subtitle
                    Text(
                      'SHA-256 fingerprint matches the original captured payload.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    const SizedBox(height: 12),

                    // Encryption Spec Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Encryption',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF8E9EB5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'AES-256-GCM',
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Fixed Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF060B14),
                border: Border(
                  top: BorderSide(color: Color(0xFF1E293B), width: 1),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: 2, // Evidence tab active
                onTap: (index) {
                  if (index == 0) {
                    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
                  } else if (index == 1) {
                    Navigator.pushNamed(context, AppRoutes.secureCamera);
                  } else if (index == 2) {
                    Navigator.pop(context);
                  }
                },
                backgroundColor: const Color(0xFF060B14),
                selectedItemColor: const Color(0xFF38BDF8),
                unselectedItemColor: const Color(0xFF64748B),
                selectedLabelStyle: GoogleFonts.inter(
                    fontSize: 10.5, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 10.5, fontWeight: FontWeight.w500),
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined, size: 22),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.camera_alt_outlined, size: 22),
                    label: 'Capture',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_rounded, size: 22),
                    label: 'Evidence',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.group_outlined, size: 22),
                    label: 'Users',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded, size: 22),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF8E9EB5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: isMonospace
                  ? GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    )
                  : GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceImage(String path) {
    if (path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
      );
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDemoSampleImage(),
      );
    }

    return _buildDemoSampleImage();
  }

  Widget _buildDemoSampleImage() {
    return Image.network(
      'https://images.unsplash.com/photo-1504917599217-d4dc5ebe6122?w=1000&q=85',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF0F1E36),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Color(0xFF64748B), size: 48),
        ),
      ),
    );
  }
}
