import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_routes.dart';
import '../../services/camera_service.dart';
import '../../services/location_service.dart';

/// Full-screen tactical camera for evidence capture matching mockup.
class SecureCameraScreen extends StatefulWidget {
  const SecureCameraScreen({super.key});

  @override
  State<SecureCameraScreen> createState() => _SecureCameraScreenState();
}

class _SecureCameraScreenState extends State<SecureCameraScreen>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  bool _isCapturing = false;
  bool _hasGpsFix = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    if (!kIsWeb) {
      _locationService.getCurrentPosition().then((pos) {
        if (mounted) {
          setState(() {
            _hasGpsFix = pos != null;
          });
        }
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      await _cameraService.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Camera initialization failed: $e');
      }
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final imagePath = await _cameraService.captureImage();

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.captureConfirmation,
        arguments: imagePath,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Viewfinder / Preview
          _buildCameraPreview(),

          // 2. Tactical Reticle & Crosshair Overlay
          _buildTacticalOverlay(),

          // 3. Top Navigation & Status Bar
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1322).withAlpha(220),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),

                    // Top GPS Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _hasGpsFix
                            ? const Color(0xFF052E16).withAlpha(220)
                            : const Color(0xFF451A03).withAlpha(220),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _hasGpsFix ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _hasGpsFix ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _hasGpsFix ? 'GPS LOCKED (±12m)' : 'ACQUIRING GPS',
                            style: GoogleFonts.inter(
                              color: _hasGpsFix ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 42), // Spacer to balance back button
                  ],
                ),
              ),
            ),
          ),

          // 4. Bottom Controls & Capture Shutter
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status text
                    Text(
                      _hasGpsFix ? 'Ready to capture evidence' : 'Acquiring GPS signal...',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF38BDF8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Concentric Circular Shutter Button
                    GestureDetector(
                      onTap: _captureImage,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E293B),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(120),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCapturing ? const Color(0xFF38BDF8) : const Color(0xFF475569),
                            ),
                          ),
                        ),
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

  Widget _buildCameraPreview() {
    if (_error != null || !_cameraService.isInitialized) {
      return Container(
        color: const Color(0xFF060B14),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2563EB)),
              const SizedBox(height: 16),
              Text(
                'Initializing Secure Camera...',
                style: GoogleFonts.inter(color: const Color(0xFF8E9EB5), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(color: Colors.black);
    }

    return CameraPreview(controller);
  }

  Widget _buildTacticalOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Center Crosshair
              const Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white38,
                  size: 28,
                ),
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
                      top: BorderSide(color: Colors.white, width: 3),
                      left: BorderSide(color: Colors.white, width: 3),
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
                      top: BorderSide(color: Colors.white, width: 3),
                      right: BorderSide(color: Colors.white, width: 3),
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
                      bottom: BorderSide(color: Colors.white, width: 3),
                      left: BorderSide(color: Colors.white, width: 3),
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
                      bottom: BorderSide(color: Colors.white, width: 3),
                      right: BorderSide(color: Colors.white, width: 3),
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
