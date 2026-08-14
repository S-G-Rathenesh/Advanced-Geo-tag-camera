import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_routes.dart';
import '../../models/evidence_record.dart';
import '../../models/sync_status.dart';
import '../../services/evidence_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class EvidenceDetailsScreen extends StatefulWidget {
  const EvidenceDetailsScreen({super.key});

  @override
  State<EvidenceDetailsScreen> createState() => _EvidenceDetailsScreenState();
}

class _EvidenceDetailsScreenState extends State<EvidenceDetailsScreen> {
  EvidenceRecord? _record;
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isVerified = false;
  bool _isVerifying = true;

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
      _triggerAuditAndVerify(args.captureId);
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
        _triggerAuditAndVerify(args);
      }
      return;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _triggerAuditAndVerify(String captureId) async {
    final apiService = context.read<ApiService>();
    try {
      await apiService.getEvidence(captureId);
    } catch (_) {}
    try {
      final verifyRes = await apiService.verifyEvidence(captureId);
      if (mounted) {
        setState(() {
          _isVerified = verifyRes['hash_match'] == true;
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerified = false;
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _downloadImage() async {
    if (_record == null || !_record!.imagePath.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image unavailable')));
      return;
    }
    setState(() => _isDownloading = true);
    try {
      final response = await http.get(Uri.parse(_record!.imagePath));
      if (response.statusCode == 200) {
        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download');
          if (!dir.existsSync()) dir = await getExternalStorageDirectory();
        } else {
          dir = await getApplicationDocumentsDirectory();
        }
        if (dir != null) {
          final file = File('/GeoEvidence_.jpg');
          await file.writeAsBytes(response.bodyBytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Image downloaded successfully'),
              backgroundColor: Color(0xFF10B981),
            ));
          }
        }
      } else {
        throw Exception('Download failed');
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

  void _openImageViewer() {
    if (_record == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: Hero(
              tag: 'evidence_image_',
              child: _buildEvidenceImage(_record!.imagePath),
            ),
          ),
        ),
      ),
    ));
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied to clipboard',
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF060B14),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
      );
    }

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
          child: Text(
            'Evidence record not found',
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
    }

    final record = _record!;

    final displayHash = record.sha256Hash.length > 28
        ? '${record.sha256Hash.substring(0, 18)}...${record.sha256Hash.substring(record.sha256Hash.length - 8)}'
        : record.sha256Hash;

    final latFormatted =
        '${record.latitude.abs().toStringAsFixed(4)}° ${record.latitude >= 0 ? "N" : "S"}';
    final lonFormatted =
        '${record.longitude.abs().toStringAsFixed(4)}° ${record.longitude >= 0 ? "E" : "W"}';
    final coords = '$latFormatted  $lonFormatted';

    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF060B14),
          border: Border(
            top: BorderSide(color: Color(0xFF1E293B), width: 1),
          ),
        ),
        child: SafeArea(
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF060B14),
            expandedHeight: MediaQuery.of(context).size.height * 0.40,
            pinned: true,
            actions: [
              if (context.watch<AuthService>().currentUser?.role == UserRole.officer)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _isDownloading
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 2),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF060B14).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                            onPressed: _downloadImage,
                            tooltip: 'Download Image',
                          ),
                        ),
                ),
            ],
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF060B14).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: _openImageViewer,
                child: Hero(
                  tag: 'evidence_image_',
                  child: _buildEvidenceImage(record.imagePath),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0B1322),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border.all(color: const Color(0xFF1E293B)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // IDENTIFICATION SECTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IDENTIFICATION',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildCopyableRow('Capture ID', record.captureId),
                              _buildCopyableRow('User ID (Owner)', record.userId),
                              _buildCopyableRow('Device ID', record.deviceId),
                            ],
                          ),
                        ),
                        // Top Right Badges (Sync Status)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (record.syncStatus == SyncStatus.synced)
                              _buildBadge(Icons.cloud_done, 'Synced', const Color(0xFF10B981))
                            else if (record.syncStatus == SyncStatus.pending)
                              _buildBadge(Icons.cloud_upload, 'Pending', const Color(0xFFF59E0B))
                            else
                              _buildBadge(Icons.cloud_off, 'Failed', const Color(0xFFEF4444)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    const SizedBox(height: 24),

                    // LOCATION SECTION
                    Text(
                      'LOCATION & METADATA',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetaRow('Address', record.address ?? 'Unavailable'),
                    _buildMetaRow('Coordinates', coords),
                    _buildMetaRow('Altitude', record.altitude != null ? '${record.altitude!.toStringAsFixed(1)}m' : 'Unavailable'),
                    _buildMetaRow('GPS Accuracy', '±${record.accuracy.toStringAsFixed(0)}m'),
                    
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    const SizedBox(height: 24),

                    // TIMESTAMPS SECTION
                    Text(
                      'TIMESTAMPS',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetaRow('Captured At', DateFormat('dd MMM yyyy • hh:mm:ss a').format(record.timestamp)),
                    _buildMetaRow('Created At', DateFormat('dd MMM yyyy • hh:mm:ss a').format(record.createdAt)),
                    _buildMetaRow('Updated At', DateFormat('dd MMM yyyy • hh:mm:ss a').format(record.updatedAt)),

                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    const SizedBox(height: 24),

                    // INTEGRITY & SECURITY SECTION
                    Text(
                      'INTEGRITY & SECURITY',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SHA-256 Hash',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: OutlinedButton(
                            onPressed: () => _copyToClipboard(record.sha256Hash),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F1E36),
                              side: const BorderSide(color: Color(0xFF1E3A8A)),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Copy',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF60A5FA),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 12),
                    _buildMetaRow('Encryption', 'AES-256-GCM', isMonospace: true, highlightColor: const Color(0xFF10B981)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Integrity Verification', style: GoogleFonts.inter(color: const Color(0xFF8E9EB5), fontSize: 13, fontWeight: FontWeight.w500)),
                        _isVerifying
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8E9EB5)))
                            : _buildBadge(
                                _isVerified ? Icons.check_circle_rounded : Icons.error_rounded,
                                _isVerified ? 'VERIFIED' : 'VERIFICATION FAILED',
                                _isVerified ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    const SizedBox(height: 24),
                    
                    // AUDIT SECTION
                    Text(
                      'AUDIT LOG',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'System audit logs are tracked securely on the backend database and restricted to authorized personnel.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF8E9EB5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              color: const Color(0xFF8E9EB5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _copyToClipboard(value),
              child: Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isMonospace = false, Color? highlightColor}) {
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
              style: isMonospace
                  ? GoogleFonts.jetBrainsMono(
                      color: highlightColor ?? Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    )
                  : GoogleFonts.inter(
                      color: highlightColor ?? Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
        errorBuilder: (_, __, ___) => _buildFallbackImage(),
      );
    }

    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      color: const Color(0xFF0F1E36),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Color(0xFF64748B), size: 48),
            const SizedBox(height: 12),
            Text(
              'Encrypted cloud payload',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
