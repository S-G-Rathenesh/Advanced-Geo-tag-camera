import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../models/evidence_record.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/secure_evidence_image.dart';

/// Secure Detail view for a single evidence record.
class EvidenceDetailsScreen extends StatefulWidget {
  const EvidenceDetailsScreen({super.key});

  @override
  State<EvidenceDetailsScreen> createState() => _EvidenceDetailsScreenState();
}

class _EvidenceDetailsScreenState extends State<EvidenceDetailsScreen> {
  EvidenceRecord? _record;
  bool _isLoading = false;
  bool _isDownloading = false;
  Uint8List? _verifiedBytes;
  String? _verificationError;
  bool _hasLoaded = false;

  String _formatCoordinates(double? lat, double? lon) {
    if (lat == null || lon == null) return 'Location unavailable';
    final latDir = lat >= 0 ? 'N' : 'S';
    final lonDir = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(6)}° $latDir, ${lon.abs().toStringAsFixed(6)}° $lonDir';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is EvidenceRecord) {
        _record = args;
        _hasLoaded = true;
        _refreshRecordFromApi();
      }
    }
  }

  Future<void> _refreshRecordFromApi() async {
    if (_record == null || !_record!.imagePath.startsWith('http')) return;

    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final cloudRecord = await apiService.getEvidence(_record!.captureId);
      
      if (mounted && cloudRecord.ivBase64 != null) {
        setState(() {
          _record = _record!.copyWith(ivBase64: cloudRecord.ivBase64);
        });
      }
    } catch (e) {
      debugPrint('Failed to refresh record from API: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadImage() async {
    if (_verifiedBytes == null) return;
    
    final authService = context.read<AuthService>();
    if (authService.currentUser?.role != UserRole.officer) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Download restricted to Officer role.'),
        backgroundColor: Color(0xFFEF4444),
      ));
      return;
    }

    setState(() => _isDownloading = true);

    try {
      // Create GeoEvidence_<captureId>.jpg in a visible directory
      // For a real app, this would use path_provider to save to Downloads
      // Since this is a test, we will write to a temp directory to simulate
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/GeoEvidence_${_record!.captureId}.jpg');
      await file.writeAsBytes(_verifiedBytes!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Saved to ${file.path}'),
          backgroundColor: const Color(0xFF10B981),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Download failed. Please try again.'),
          backgroundColor: Color(0xFFEF4444),
        ));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard', style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: const Color(0xFF1E3A8A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_record == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF060B14),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text('Evidence record not found', style: GoogleFonts.inter(color: Colors.white)),
        ),
      );
    }

    final record = _record!;
    final isVerified = _verifiedBytes != null;
    final isFailed = _verificationError != null;
    final isVerifying = !isVerified && !isFailed;
    final canDownload = isVerified && !_isDownloading;

    final displayHash = record.sha256Hash.length > 28
        ? '${record.sha256Hash.substring(0, 18)}...${record.sha256Hash.substring(record.sha256Hash.length - 8)}'
        : record.sha256Hash;

    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060B14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: canDownload ? _downloadImage : null,
              icon: _isDownloading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(
                      isFailed ? Icons.error_outline : Icons.download_rounded,
                      size: 18,
                    ),
              label: Text(
                isFailed ? 'Integrity Failed' : (isVerifying ? 'Verifying...' : 'Download'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canDownload ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
                foregroundColor: canDownload ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // IMAGE AREA
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.black,
                    child: SecureEvidenceImage(
                      record: record,
                      fit: BoxFit.contain,
                      onVerified: (bytes) {
                        setState(() {
                          _verifiedBytes = bytes;
                          _verificationError = null;
                        });
                      },
                      onError: (error) {
                        setState(() {
                          _verifiedBytes = null;
                          _verificationError = error;
                        });
                      },
                    ),
                  ),

                  // INTEGRITY VERIFIED
                  if (isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      color: const Color(0xFF052E16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified, color: Color(0xFF10B981), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'INTEGRITY VERIFIED',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'SHA-256: ',
                                style: GoogleFonts.jetBrainsMono(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  displayHash,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: const Color(0xFF34D399),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else if (_verificationError != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      color: const Color(0xFF450A0A),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _verificationError!,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFCA5A5),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // IDENTIFICATION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IDENTIFICATION',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDataRow('Capture ID', record.captureId, canCopy: true),
                        _buildDataRow('Owner', record.userId),
                        _buildDataRow('Owner Role', 'N/A'), // Ideally fetched from user profile if available
                        _buildDataRow('Device', record.deviceId),
                        _buildDataRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp.toLocal())),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Color(0xFF1E293B), thickness: 1),
                  ),

                  // LOCATION & METADATA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOCATION & METADATA',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDataRow('Address', record.address ?? 'Not recorded', canCopy: true),
                        _buildDataRow('Coordinates', _formatCoordinates(record.latitude, record.longitude), canCopy: true),
                        _buildDataRow('Altitude', record.altitude != null ? '${record.altitude!.toStringAsFixed(1)} m' : 'Altitude unavailable'),
                        _buildDataRow('GPS Accuracy', '±${record.accuracy.toStringAsFixed(1)} m'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: canCopy ? () => _copyToClipboard(value) : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (canCopy)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, top: 2),
                      child: Icon(Icons.copy, size: 14, color: Color(0xFF64748B)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
