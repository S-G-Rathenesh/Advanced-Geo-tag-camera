import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Camera lifecycle management service.
///
/// Provides controlled in-app camera access without any gallery picker.
/// Images are saved to the app-private documents directory, never to
/// the public gallery.
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  // ── Public getters ────────────────────────────────────────────────────

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  List<CameraDescription> get cameras => _cameras;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  /// Discover available cameras on the device.
  Future<void> discoverCameras() async {
    _cameras = await availableCameras();
  }

  /// Initialize the camera controller.
  ///
  /// Defaults to the rear camera for evidence capture.
  Future<void> initialize({
    CameraDescription? camera,
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    if (_cameras.isEmpty) {
      await discoverCameras();
    }

    if (_cameras.isEmpty) {
      throw CameraException('noCameras', 'No cameras available on device');
    }

    // Default to rear camera
    final selectedCamera = camera ??
        _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );

    _controller = CameraController(
      selectedCamera,
      resolution,
      enableAudio: false, // Evidence capture – no audio needed
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    _isInitialized = true;
  }

  /// Capture a photograph and save to app-private directory.
  ///
  /// Returns the absolute path to the captured image file.
  /// The image is NOT placed in the device's public gallery.
  Future<String> captureImage() async {
    if (_controller == null || !_isInitialized) {
      throw CameraException('notInitialized', 'Camera not initialized');
    }

    final xFile = await _controller!.takePicture();

    // Move to app-private directory
    final appDir = await getApplicationDocumentsDirectory();
    final evidenceDir = Directory('${appDir.path}/evidence_captures');
    if (!await evidenceDir.exists()) {
      await evidenceDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetPath = '${evidenceDir.path}/capture_$timestamp.jpg';

    // Copy to private directory (xFile.path may be in temp cache)
    final originalFile = File(xFile.path);
    await originalFile.copy(targetPath);

    // Delete the temp file if it's different from target
    if (xFile.path != targetPath && await originalFile.exists()) {
      await originalFile.delete();
    }

    return targetPath;
  }

  /// Switch between front and rear cameras.
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    final currentDirection = _controller?.description.lensDirection;
    final newCamera = _cameras.firstWhere(
      (c) => c.lensDirection != currentDirection,
      orElse: () => _cameras.first,
    );

    await dispose();
    await initialize(camera: newCamera);
  }

  /// Toggle flash mode.
  Future<void> toggleFlash() async {
    if (_controller == null) return;

    final modes = [FlashMode.off, FlashMode.auto, FlashMode.always];
    int currentIndex = modes.indexOf(_controller!.value.flashMode);
    
    // Try setting the next modes until one succeeds
    for (int i = 1; i <= modes.length; i++) {
      final nextMode = modes[(currentIndex + i) % modes.length];
      try {
        await _controller!.setFlashMode(nextMode);
        return; // Success, stop trying
      } catch (e) {
        debugPrint('Flash mode $nextMode not supported: $e');
      }
    }
  }

  /// Dispose the camera controller.
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
