import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/device_info_helper.dart';
import '../../models/evidence_record.dart';
import '../../services/auth_service.dart';
import '../../services/camera_service.dart';
import '../../services/evidence_service.dart';
import '../../services/sync_service.dart';

enum CaptureState {
  initializing,
  gpsAcquiring,
  gpsInaccurate,
  ready,
  capturing,
  processing,
  success,
  error,
}

/// Full-screen professional field-evidence camera.
class SecureCameraScreen extends StatefulWidget {
  const SecureCameraScreen({super.key});

  @override
  State<SecureCameraScreen> createState() => _SecureCameraScreenState();
}

class _SecureCameraScreenState extends State<SecureCameraScreen>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final DeviceInfoHelper _deviceInfoHelper = DeviceInfoHelper();

  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  
  CaptureState _captureState = CaptureState.initializing;
  String _statusMessage = 'Initializing Secure Camera...';
  String? _errorMessage;

  EvidenceRecord? _securedEvidence;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _initGps();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStream?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
      _positionStream?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
      _initGps();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _captureState = CaptureState.initializing;
      _statusMessage = 'Initializing Secure Camera...';
    });

    try {
      await _cameraService.initialize();
      _checkReadyState();
    } catch (e) {
      if (mounted) {
        setState(() {
          _captureState = CaptureState.error;
          _errorMessage = 'Camera initialization failed: $e';
        });
      }
    }
  }

  void _initGps() {
    if (kIsWeb) {
      _checkReadyState();
      return; 
    }

    setState(() {
      if (_captureState == CaptureState.initializing || _captureState == CaptureState.ready) {
        _captureState = CaptureState.gpsAcquiring;
        _statusMessage = 'Acquiring GPS signal...';
      }
    });

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((Position position) {
      if (!mounted) return;
      _currentPosition = position;
      _checkReadyState();
    }, onError: (e) {
      if (!mounted) return;
      setState(() {
        _captureState = CaptureState.error;
        _errorMessage = 'GPS Error: $e';
      });
    });
  }

  void _checkReadyState() {
    if (!mounted || _captureState == CaptureState.capturing || _captureState == CaptureState.processing || _captureState == CaptureState.success) {
      return;
    }

    if (!_cameraService.isInitialized) return;

    if (!kIsWeb) {
      if (_currentPosition == null) {
        setState(() {
          _captureState = CaptureState.gpsAcquiring;
          _statusMessage = 'Acquiring GPS signal...';
        });
        return;
      }

      if (_currentPosition!.accuracy > AppConstants.gpsAccuracyThresholdMetres) {
        setState(() {
          _captureState = CaptureState.gpsInaccurate;
          _statusMessage = 'GPS accuracy is ${_currentPosition!.accuracy.toStringAsFixed(0)}m (Max: ${AppConstants.gpsAccuracyThresholdMetres}m)';
        });
        return;
      }
    }

    setState(() {
      _captureState = CaptureState.ready;
      _statusMessage = kIsWeb 
          ? 'Ready to capture' 
          : 'GPS verified • Accuracy ${_currentPosition!.accuracy.toStringAsFixed(0)}m';
    });
  }

  Future<String?> _fetchAddress(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon');
      final response = await http.get(url, headers: {
        'User-Agent': 'Capturovert-App/1.0',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'];
      }
    } catch (_) {}
    return null;
  }

  Future<void> _captureEvidence() async {
    if (_captureState != CaptureState.ready) return;

    final authService = context.read<AuthService>();
    final evidenceService = context.read<EvidenceService>();

    setState(() {
      _captureState = CaptureState.capturing;
      _statusMessage = 'Capturing evidence...';
    });

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    try {
      // 1. Capture Image
      final imagePath = await _cameraService.captureImage();

      if (!mounted) return;

      setState(() {
        _captureState = CaptureState.processing;
        _statusMessage = 'Securing evidence...';
      });

      // 2. Validate GPS (already checked by state, but grab snapshot)
      final pos = _currentPosition;
      String? address;

      if (!kIsWeb && pos != null) {
        address = await _fetchAddress(pos.latitude, pos.longitude);
      }

      // 3. Metadata & Identity
      String deviceId;
      try {
        deviceId = await _deviceInfoHelper.getDeviceId();
      } catch (_) {
        deviceId = 'DEV-UNKNOWN';
      }

      final userId = authService.currentUser?.username ?? 'demo_officer';

      // 4. Encrypt, Hash, Save via EvidenceService
      final evidence = await evidenceService.createEvidence(
        userId: userId,
        deviceId: deviceId,
        imagePath: imagePath,
        latitude: pos?.latitude ?? 0.0,
        longitude: pos?.longitude ?? 0.0,
        altitude: pos?.altitude ?? 0.0,
        accuracy: pos?.accuracy ?? 0.0,
        address: address,
      );

      if (!mounted) return;
      HapticFeedback.lightImpact();

      setState(() {
        _securedEvidence = evidence;
        _captureState = CaptureState.success;
        _statusMessage = 'Evidence secured locally';
      });

      // Auto-sync: trigger background upload immediately
      if (mounted) {
        final syncService = context.read<SyncService>();
        syncService.syncAll().then((_) {
          if (mounted && _captureState == CaptureState.success) {
            setState(() {
              _statusMessage = 'Evidence secured & synced';
            });
          }
        }).catchError((_) {
          // Sync failed silently — will retry when connectivity returns
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _captureState = CaptureState.error;
          _errorMessage = 'Capture failed: $e';
        });
      }
    }
  }

  void _resetCapture() {
    setState(() {
      _securedEvidence = null;
      _errorMessage = null;
    });
    _checkReadyState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Viewfinder
          _buildCameraPreview(),

          // 2. Tactical Overlay
          if (_captureState != CaptureState.success) _buildTacticalOverlay(),

          // 3. Top Navigation & Controls
          if (_captureState != CaptureState.success) _buildTopControls(),

          // 4. Bottom Controls & Shutter
          if (_captureState != CaptureState.success) _buildBottomControls(),

          // 5. Success Panel Overlay
          if (_captureState == CaptureState.success) _buildSuccessPanel(),

          // 6. Error Overlay
          if (_captureState == CaptureState.error) _buildErrorPanel(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_cameraService.isInitialized) {
      return Container(color: Colors.black);
    }

    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(color: Colors.black);
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * controller.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildTacticalOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withAlpha(40), width: 1.0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Center Crosshair
              const Center(
                child: Icon(Icons.add, color: Colors.white38, size: 24),
              ),
              // Corner Accents
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white, width: 2),
                      left: BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white, width: 2),
                      right: BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white, width: 2),
                      left: BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white, width: 2),
                      right: BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    // Determine colors based on state
    Color pillColor;
    Color pillBorderColor;
    Color textColor;
    IconData gpsIcon = Icons.gps_fixed_rounded;

    if (_captureState == CaptureState.ready) {
      pillColor = const Color(0xFF052E16).withAlpha(220);
      pillBorderColor = const Color(0xFF10B981);
      textColor = const Color(0xFF10B981);
    } else if (_captureState == CaptureState.gpsInaccurate) {
      pillColor = const Color(0xFF451A03).withAlpha(220);
      pillBorderColor = const Color(0xFFF59E0B);
      textColor = const Color(0xFFF59E0B);
      gpsIcon = Icons.gps_off_rounded;
    } else {
      // Acquiring, Processing, etc.
      pillColor = const Color(0xFF1E293B).withAlpha(220);
      pillBorderColor = const Color(0xFF475569);
      textColor = Colors.white70;
      gpsIcon = Icons.satellite_alt_rounded;
    }

    final isFront = _cameraService.controller?.description.lensDirection == CameraLensDirection.front;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1322).withAlpha(180),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                ),
              ),

              // GPS Status Pill
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: pillBorderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_captureState == CaptureState.gpsAcquiring || _captureState == CaptureState.processing)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                          )
                        else
                          Icon(gpsIcon, color: textColor, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          _statusMessage,
                          style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isFront)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7F1D1D).withAlpha(220),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'FRONT CAMERA ACTIVE',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFCA5A5),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Camera Controls
              Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await _cameraService.toggleFlash();
                      setState(() {});
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1322).withAlpha(180),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getFlashIcon(),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_cameraService.hasMultipleCameras)
                    GestureDetector(
                      onTap: () async {
                        await _cameraService.switchCamera();
                        setState(() {});
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1322).withAlpha(180),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cameraswitch_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFlashIcon() {
    switch (_cameraService.currentFlashMode) {
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.torch:
      case FlashMode.always:
        return Icons.flash_on_rounded;
      case FlashMode.off:
        return Icons.flash_off_rounded;
    }
  }

  void _onCapturePressed() {
    if (_captureState == CaptureState.gpsAcquiring) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Waiting for GPS signal to meet ${AppConstants.gpsAccuracyThresholdMetres}m threshold...', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFF59E0B),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_captureState == CaptureState.gpsInaccurate) {
      final acc = _currentPosition?.accuracy.toStringAsFixed(0) ?? '?';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GPS accuracy too low (${acc}m). Must be under ${AppConstants.gpsAccuracyThresholdMetres}m to securely capture evidence.', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    if (_captureState == CaptureState.ready) {
      _captureEvidence();
    }
  }

  Widget _buildBottomControls() {
    final bool isReady = _captureState == CaptureState.ready;
    final bool isProcessing = _captureState == CaptureState.capturing || _captureState == CaptureState.processing;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status text
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  isProcessing ? _statusMessage : (isReady ? 'Ready to capture' : _statusMessage),
                  style: GoogleFonts.inter(
                    color: isProcessing 
                        ? Colors.white 
                        : (isReady ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B)),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Professional Circular Shutter
              GestureDetector(
                onTap: isProcessing ? null : _onCapturePressed,
                child: AnimatedScale(
                  scale: isProcessing ? 0.9 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isReady ? Colors.transparent : const Color(0xFF1E293B),
                      border: Border.all(
                        color: isReady ? Colors.white : const Color(0xFF475569), 
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isProcessing 
                              ? const Color(0xFF38BDF8) 
                              : isReady ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessPanel() {
    if (_securedEvidence == null) return const SizedBox.shrink();
    
    return SafeArea(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1322),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E293B)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(120),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF052E16),
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Evidence Secured',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              
              _buildDetailRow('Capture ID', _securedEvidence!.captureId.substring(0, 8).toUpperCase()),
              const SizedBox(height: 8),
              _buildDetailRow('Integrity', 'VERIFIED SHA-256', color: const Color(0xFF10B981)),
              const SizedBox(height: 8),
              _buildDetailRow('Storage', 'ENCRYPTED LOCAL', color: const Color(0xFF38BDF8)),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _resetCapture,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Capture Another',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: color ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPanel() {
    return SafeArea(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1322),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF451A03)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 16),
              Text(
                'Camera Error',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'An unknown error occurred.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _resetCapture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
