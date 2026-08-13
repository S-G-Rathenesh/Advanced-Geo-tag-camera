import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/device_info_helper.dart';
import '../../services/auth_service.dart';
import '../../services/evidence_service.dart';
import '../../services/location_service.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/secure_app_bar.dart';

/// Capture confirmation screen showing image preview and metadata.
///
/// Officer can accept (triggers hash → encrypt → queue) or retake.
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
  bool _isLoadingLocation = true;
  bool _isProcessing = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    // Get location
    try {
      _position = await _locationService.getCurrentPosition();
    } catch (e) {
      _locationError = e.toString();
    }

    // Get device info
    try {
      _deviceId = await _deviceInfoHelper.getDeviceId();
    } catch (_) {
      _deviceId = 'unknown_device';
    }

    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _acceptCapture(String imagePath) async {
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Cannot save evidence without GPS coordinates'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!_locationService.meetsAccuracyThreshold(_position!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'GPS accuracy (±${_position!.accuracy.toStringAsFixed(1)}m) exceeds required threshold (±${AppConstants.gpsAccuracyThresholdMetres.toStringAsFixed(1)}m). Capture rejected.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final authService = context.read<AuthService>();
      final evidenceService = context.read<EvidenceService>();

      await evidenceService.createEvidence(
        userId: authService.currentUser?.userId ?? 'unknown',
        deviceId: _deviceId ?? 'unknown',
        imagePath: imagePath,
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        altitude: _position!.altitude,
        accuracy: _position!.accuracy,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Evidence captured and queued for sync'),
          backgroundColor: AppTheme.statusSynced,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save evidence: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = ModalRoute.of(context)?.settings.arguments as String?;

    if (imagePath == null) {
      return Scaffold(
        appBar: const SecureAppBar(title: 'Capture Error'),
        body: const Center(child: Text('No image captured')),
      );
    }

    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isProcessing,
        message: 'Hashing & encrypting evidence...',
        child: GradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Confirm Capture',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Image preview
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF1A2940),
                          child: const Center(
                            child: Icon(Icons.broken_image_rounded,
                                size: 48, color: Colors.white38),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Metadata panel
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2940),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withAlpha(10),
                      ),
                    ),
                    child: _isLoadingLocation
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: Color(0xFF00BFA6)),
                                SizedBox(height: 12),
                                Text(
                                  'Acquiring GPS position...',
                                  style:
                                      TextStyle(color: Color(0xFF6B7A8D)),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (_locationError != null)
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.statusFailed
                                          .withAlpha(20),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_rounded,
                                            color: AppTheme.statusFailed,
                                            size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _locationError!,
                                            style: TextStyle(
                                              color: AppTheme.statusFailed,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                                          onPressed: _loadMetadata,
                                          tooltip: 'Retry GPS',
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  _MetadataRow(
                                    icon: Icons.location_on_rounded,
                                    label: 'Latitude',
                                    value: _position!.latitude
                                        .toStringAsFixed(6),
                                  ),
                                  _MetadataRow(
                                    icon: Icons.location_on_rounded,
                                    label: 'Longitude',
                                    value: _position!.longitude
                                        .toStringAsFixed(6),
                                  ),
                                  _MetadataRow(
                                    icon: Icons.height_rounded,
                                    label: 'Altitude',
                                    value:
                                        '${_position!.altitude.toStringAsFixed(1)}m',
                                  ),
                                  _MetadataRow(
                                    icon: Icons.gps_fixed_rounded,
                                    label: 'Accuracy',
                                    value:
                                        '±${_position!.accuracy.toStringAsFixed(1)}m',
                                    valueColor:
                                        _locationService
                                                .meetsAccuracyThreshold(
                                                    _position!)
                                            ? AppTheme.statusSynced
                                            : AppTheme.statusPending,
                                  ),
                                  if (!_locationService.meetsAccuracyThreshold(_position!))
                                    Container(
                                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.statusPending.withAlpha(25),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.statusPending.withAlpha(60)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.gps_not_fixed_rounded, color: AppTheme.statusPending, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Accuracy ±${_position!.accuracy.toStringAsFixed(1)}m exceeds ±${AppConstants.gpsAccuracyThresholdMetres.toStringAsFixed(1)}m threshold.',
                                              style: TextStyle(color: AppTheme.statusPending, fontSize: 11),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _loadMetadata,
                                            child: const Text('Retry GPS', style: TextStyle(fontSize: 11, color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                                _MetadataRow(
                                  icon: Icons.access_time_rounded,
                                  label: 'Timestamp',
                                  value: DateFormat('dd MMM yyyy, HH:mm:ss')
                                      .format(DateTime.now()),
                                ),
                                _MetadataRow(
                                  icon: Icons.phone_android_rounded,
                                  label: 'Device',
                                  value: _deviceId ?? 'Unknown',
                                ),
                              ],
                            ),
                          ),
                  ),
                ),

                // Action buttons
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    children: [
                      // Retake button
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed(
                                  AppRoutes.secureCamera);
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Retake'),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF6B7A8D),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Accept button
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _position != null
                                ? () => _acceptCapture(imagePath)
                                : null,
                            icon: const Icon(
                                Icons.check_circle_rounded),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Accept & Queue'),
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
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7A8D)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7A8D),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
