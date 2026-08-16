import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

enum ProtectionState { safe, monitoring, suspicious, triggered, error }

class EvidenceViewProtectionService {
  static final EvidenceViewProtectionService _instance = EvidenceViewProtectionService._internal();
  factory EvidenceViewProtectionService() => _instance;
  EvidenceViewProtectionService._internal();

  CameraController? _controller;
  ImageLabeler? _imageLabeler;

  final StreamController<ProtectionState> _stateController = StreamController<ProtectionState>.broadcast();
  Stream<ProtectionState> get stateStream => _stateController.stream;

  bool _isProcessing = false;
  int _consecutiveDetections = 0;
  bool _isMonitoring = false;
  
  ProtectionState _currentState = ProtectionState.safe;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _consecutiveDetections = 0;
    
    _emitState(ProtectionState.monitoring);

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _emitState(ProtectionState.error);
        return;
      }
      
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.65));

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (!_isMonitoring) {
        stopMonitoring();
        return;
      }
      
      await _controller!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint('EvidenceViewProtectionService error: $e');
      _emitState(ProtectionState.error);
    }
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _isProcessing = false;
    _consecutiveDetections = 0;
    
    try {
      if (_controller?.value.isStreamingImages == true) {
        await _controller?.stopImageStream();
      }
      await _controller?.dispose();
      _controller = null;
      
      _imageLabeler?.close();
      _imageLabeler = null;
    } catch (e) {
      debugPrint('Error stopping protection service: $e');
    }
    
    _emitState(ProtectionState.safe);
  }

  void _emitState(ProtectionState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || !_isMonitoring || _controller == null) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final labels = await _imageLabeler!.processImage(inputImage);
      bool threatDetected = false;
      double highestConfidence = 0.0;

      for (final label in labels) {
        final text = label.label.toLowerCase();
        if (text.contains('mobile phone') || 
            text.contains('cell phone') || 
            text.contains('camera') || 
            text.contains('electronic device') ||
            text.contains('telephone')) {
          
          if (label.confidence > highestConfidence) {
            highestConfidence = label.confidence;
          }
          
          // Require at least 70% confidence for a threat
          if (label.confidence >= 0.70) {
            threatDetected = true;
          }
        }
      }

      if (threatDetected) {
        _consecutiveDetections++;
        if (_consecutiveDetections == 1) {
          _emitState(ProtectionState.suspicious);
        } else if (_consecutiveDetections >= 3) {
          // Trigger security protocol
          _emitState(ProtectionState.triggered);
          
          // Log security event (metadata only, no frames)
          debugPrint('SECURITY EVENT: Unauthorized recording device detected (Conf: $highestConfidence)');
          
          // Stop monitoring since we triggered
          await stopMonitoring();
          return; // exit early
        }
      } else {
        if (_consecutiveDetections > 0) {
          _emitState(ProtectionState.monitoring);
        }
        _consecutiveDetections = 0;
      }
    } catch (e) {
      debugPrint('Frame processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _controller?.description;
    if (camera == null) return null;

    final sensorOrientation = camera.sensorOrientation;
    final InputImageRotation? rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    
    // Usually, image.planes.first.bytes is sufficient, or we merge planes.
    // For google_mlkit_image_labeling v0.15+, building from planes:
    final bytes = WriteBuffer();
    for (final plane in image.planes) {
      bytes.putUint8List(plane.bytes);
    }
    final allBytes = bytes.done().buffer.asUint8List();

    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format ?? InputImageFormat.nv21,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: allBytes, metadata: inputImageData);
  }
}
