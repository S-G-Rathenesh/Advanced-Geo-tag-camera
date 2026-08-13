import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../services/camera_service.dart';

/// Full-screen camera for evidence capture.
///
/// Security: NO gallery picker is shown. Only the live camera feed
/// and a capture button are available.
class SecureCameraScreen extends StatefulWidget {
  const SecureCameraScreen({super.key});

  @override
  State<SecureCameraScreen> createState() => _SecureCameraScreenState();
}

class _SecureCameraScreenState extends State<SecureCameraScreen>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  bool _isCapturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle camera lifecycle
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

      // Navigate to confirmation screen with captured image path
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.captureConfirmation,
        arguments: imagePath,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_rounded,
                    size: 64, color: Colors.white54),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _initCamera();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_cameraService.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFA6)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1 / _cameraService.controller!.value.aspectRatio,
                child: CameraPreview(_cameraService.controller!),
              ),
            ),
          ),

          // Top bar with close and flash
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    _CircleButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    // Security indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded,
                              color: Color(0xFF00BFA6), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'SECURE CAPTURE',
                            style: TextStyle(
                              color: Color(0xFF00BFA6),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Flash toggle
                    _CircleButton(
                      icon: _flashIcon,
                      onTap: () async {
                        await _cameraService.toggleFlash();
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom capture controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(180),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Spacer / placeholder
                    const SizedBox(width: 56),

                    // Capture button
                    GestureDetector(
                      onTap: _isCapturing ? null : _captureImage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing
                                ? Colors.grey
                                : Colors.white,
                          ),
                          child: _isCapturing
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black54,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),

                    // Camera switch
                    _CircleButton(
                      icon: Icons.flip_camera_android_rounded,
                      onTap: () async {
                        await _cameraService.switchCamera();
                        if (mounted) setState(() {});
                      },
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

  IconData get _flashIcon {
    final mode = _cameraService.controller?.value.flashMode ?? FlashMode.off;
    switch (mode) {
      case FlashMode.off:
        return Icons.flash_off_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.always:
        return Icons.flash_on_rounded;
      case FlashMode.torch:
        return Icons.flashlight_on_rounded;
    }
  }
}

// ── Circle button ─────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withAlpha(100),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
