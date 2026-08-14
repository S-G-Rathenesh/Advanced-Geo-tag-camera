import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/device_info_helper.dart';
import '../../services/auth_service.dart';
import '../../services/evidence_service.dart';
import '../../services/location_service.dart';

/// Tactical Capture Confirmation Screen matching the design system.
class CaptureConfirmationScreen extends StatefulWidget {
  const CaptureConfirmationScreen({super.key});

  @override
  State<CaptureConfirmationScreen> createState() =>
      _CaptureConfirmationScreenState();
}

class _CaptureConfirmationScreenState
    extends State<CaptureConfirmationScreen> {
  final LocationService _locationService = LocationService();
  final DeviceInfoHelper _deviceInfoHelper = DeviceInfoHelper();

  Position? _position;
  String? _deviceId;
  String? _address;
  bool _isLoadingLocation = true;
  bool _isProcessing = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _fetchAddress(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon');
      final response = await http.get(url, headers: {
        'User-Agent': 'Capturovert-App/1.0',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _address = data['display_name'];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadMetadata() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
      _address = null;
    });

    try {
      _position = await _locationService.getCurrentPosition();
      if (_position != null) {
        _fetchAddress(_position!.latitude, _position!.longitude);
      }
    } catch (e) {
      _locationError = e.toString();
    }

    try {
      _deviceId = await _deviceInfoHelper.getDeviceId();
    } catch (_) {
      _deviceId = 'DEV-A8F2-9C14';
    }

    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _acceptCapture(String imagePath) async {
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot accept capture without GPS lock.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final authService = context.read<AuthService>();
      final evidenceService = context.read<EvidenceService>();

      final userId = authService.currentUser?.username ?? 'demo_officer';

      await evidenceService.createEvidence(
        userId: userId,
        deviceId: _deviceId ?? 'DEV-A8F2-9C14',
        imagePath: imagePath,
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        altitude: _position!.altitude,
        accuracy: _position!.accuracy,
        address: _address,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Evidence captured, hashed & encrypted.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFF052E16),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process evidence: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';

    final latFormatted = _position != null
        ? '${_position!.latitude.abs().toStringAsFixed(4)}° ${_position!.latitude >= 0 ? "N" : "S"}'
        : 'Acquiring...';
    final lonFormatted = _position != null
        ? '${_position!.longitude.abs().toStringAsFixed(4)}° ${_position!.longitude >= 0 ? "E" : "W"}'
        : '';
    final coords = lonFormatted.isNotEmpty ? '$latFormatted  $lonFormatted' : latFormatted;

    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed(
                        AppRoutes.secureCamera,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1322),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chevron_left_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 2),
                          Text(
                            'Retake',
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
                  Text(
                    'Confirm Evidence',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 60), // Balance header
                ],
              ),
            ),

            // Image Preview (Top)
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF0B1322),
                    child: imagePath.isNotEmpty && File(imagePath).existsSync()
                        ? Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(Icons.image_outlined,
                                size: 48, color: Color(0xFF64748B)),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Metadata Box (Bottom)
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1322),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: _isLoadingLocation
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                                color: Color(0xFF2563EB)),
                            const SizedBox(height: 12),
                            Text(
                              'Locking GPS and acquiring precision coordinates...',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF8E9EB5),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRow('Location', _address ?? 'Bengaluru, India'),
                            _buildRow('Coordinates', coords),
                            _buildRow(
                              'GPS Accuracy',
                              _position != null
                                  ? '±${_position!.accuracy.toStringAsFixed(0)}m'
                                  : 'N/A',
                            ),
                            _buildRow(
                              'Timestamp',
                              DateFormat('dd MMM yyyy • hh:mm a')
                                  .format(DateTime.now()),
                            ),
                            _buildRow(
                              'Device ID',
                              _deviceId != null && _deviceId!.length > 18
                                  ? '${_deviceId!.substring(0, 16)}...'
                                  : (_deviceId ?? 'DEV-A8F2-9C14'),
                              isMonospace: true,
                            ),
                            _buildRow('Encryption', 'AES-256-GCM', isGreen: true),
                          ],
                        ),
                      ),
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed(
                            AppRoutes.secureCamera,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F1E36),
                          side: const BorderSide(color: Color(0xFF1E3A8A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Retake',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF60A5FA),
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _position != null && !_isProcessing
                            ? () => _acceptCapture(imagePath)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Accept & Encrypt',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isMonospace = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF8E9EB5),
              fontSize: 12.5,
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
              style: isMonospace || isGreen
                  ? GoogleFonts.jetBrainsMono(
                      color: isGreen ? const Color(0xFF10B981) : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )
                  : GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
