import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

enum ProtectionState { safe, monitoring, suspicious, triggered, occluded, error }

class EvidenceViewProtectionService {
  static final EvidenceViewProtectionService _instance = EvidenceViewProtectionService._internal();
  factory EvidenceViewProtectionService() => _instance;
  EvidenceViewProtectionService._internal();

  CameraController? _controller;
  ImageLabeler? _imageLabeler;

  final StreamController<ProtectionState> _stateController = StreamController<ProtectionState>.broadcast();
  Stream<ProtectionState> get stateStream => _stateController.stream;

  StreamSubscription<dynamic>? _proximitySubscription;
  static const EventChannel _proximityChannel = EventChannel('com.geotag.evidence/proximity');

  bool _isProcessing = false;
  bool _isProximityOccluded = false;
  int _consecutiveThreats = 0;
  int _consecutiveOcclusions = 0;
  int _consecutiveSafeFrames = 0;
  bool _isMonitoring = false;
  DateTime _lastProcessedTime = DateTime.fromMillisecondsSinceEpoch(0);
  String _lastThreatName = '';
  String _lastThreatReason = '';
  
  ProtectionState _currentState = ProtectionState.safe;
  ProtectionState get currentState => _currentState;
  String get lastThreatName => _lastThreatName;
  String get lastThreatReason => _lastThreatReason;

  // Primary keywords for cameras, phones, and recording devices
  static const List<String> _directThreatKeywords = [
    'mobile phone',
    'cell phone',
    'cellular telephone',
    'smartphone',
    'smart phone',
    'feature phone',
    'telephone',
    'camera',
    'digital camera',
    'point and shoot camera',
    'single-lens reflex camera',
    'reflex camera',
    'cameras & optics',
    'camcorder',
    'camera lens',
    'telephoto lens',
    'lens cover',
    'tablet computer',
    'ipad',
    'display device',
    'screen',
  ];

  static const List<String> _secondaryThreatKeywords = [
    'gadget',
    'electronic device',
    'handheld device',
    'communication device',
    'portable communications device',
    'optical instrument',
    'optics',
    'multimedia',
    'consumer electronics',
    'webcam',
    'technology',
  ];

  // Whitelist of benign items (face, mouse, clothing, desk items, audio gear)
  static const List<String> _benignKeywords = [
    'face',
    'person',
    'human',
    'forehead',
    'cheek',
    'chin',
    'neck',
    'eyebrow',
    'eye',
    'nose',
    'mouth',
    'lip',
    'hair',
    'beard',
    'mustache',
    'smile',
    'selfie',
    'skin',
    'clothing',
    'shirt',
    't-shirt',
    'collar',
    'sleeve',
    'glasses',
    'eyewear',
    'sunglasses',
    'vision care',
    'mouse',
    'computer mouse',
    'trackball',
    'keyboard',
    'computer keyboard',
    'laptop',
    'computer',
    'desk',
    'table',
    'chair',
    'office equipment',
    'furniture',
    'microphone',
    'headphone',
    'headphones',
    'earphone',
    'earphones',
    'headset',
    'cable',
    'wire',
    'pen',
    'pencil',
    'paper',
    'book',
    'cup',
    'bottle',
    'wall',
    'ceiling',
    'room',
    'lighting',
  ];

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _isProximityOccluded = false;
    _consecutiveThreats = 0;
    _consecutiveOcclusions = 0;
    _consecutiveSafeFrames = 0;
    _lastThreatReason = '';
    
    _emitState(ProtectionState.monitoring);

    // 1. Start Hardware Proximity Sensor Stream (0ms instant finger/palm cover detection)
    try {
      _proximitySubscription?.cancel();
      _proximitySubscription = _proximityChannel.receiveBroadcastStream().listen(
        (event) {
          final isNear = event == true;
          _isProximityOccluded = isNear;
          if (isNear) {
            _lastThreatReason = 'Camera Proximity Sensor Blocked';
            _lastThreatName = 'Covered / Finger Detected';
            if (_currentState != ProtectionState.occluded && _currentState != ProtectionState.triggered) {
              _emitState(ProtectionState.occluded);
              debugPrint('SECURITY ALERT: Hardware proximity sensor triggered (Camera covered)!');
            }
          } else {
            if (_currentState == ProtectionState.occluded) {
              _emitState(ProtectionState.monitoring);
              debugPrint('SECURITY INFO: Proximity cleared. Screen unshielded.');
            }
          }
        },
        onError: (err) {
          debugPrint('Proximity sensor stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('Proximity sensor setup error: $e');
    }

    // 2. Start Front Camera Stream for Recording Device & Optical Occlusion Detection
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!_isProximityOccluded) {
          _emitState(ProtectionState.error);
        }
        return;
      }
      
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.30));

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (!_isMonitoring) {
        await stopMonitoring();
        return;
      }
      
      await _controller!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint('EvidenceViewProtectionService camera error: $e');
      if (!_isProximityOccluded) {
        _emitState(ProtectionState.error);
      }
    }
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _isProcessing = false;
    _isProximityOccluded = false;
    _consecutiveThreats = 0;
    _consecutiveOcclusions = 0;
    _consecutiveSafeFrames = 0;

    try {
      await _proximitySubscription?.cancel();
      _proximitySubscription = null;
    } catch (e) {
      debugPrint('Error canceling proximity stream: $e');
    }
    
    try {
      if (_controller?.value.isStreamingImages == true) {
        await _controller?.stopImageStream();
      }
      await _controller?.dispose();
      _controller = null;
      
      _imageLabeler?.close();
      _imageLabeler = null;
    } catch (e) {
      debugPrint('Error stopping camera: $e');
    }
    
    _emitState(ProtectionState.safe);
  }

  void resetShield() {
    _consecutiveThreats = 0;
    _consecutiveOcclusions = 0;
    _consecutiveSafeFrames = 5;
    _lastThreatReason = '';
    if (_isMonitoring) {
      _emitState(ProtectionState.monitoring);
    } else {
      _emitState(ProtectionState.safe);
    }
  }

  void _emitState(ProtectionState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// High-accuracy optical detection for finger covering, tape, palm, or lens occlusion
  bool _checkCameraOcclusion(CameraImage image) {
    if (image.planes.isEmpty) return true;
    final yBytes = image.planes[0].bytes;
    if (yBytes.isEmpty) return true;

    int totalLuma = 0;
    int sampleCount = 0;
    const step = 8;

    for (int i = 0; i < yBytes.length; i += step) {
      totalLuma += yBytes[i];
      sampleCount++;
    }

    if (sampleCount == 0) return true;
    final double avgLuma = totalLuma / sampleCount;

    // 1. Blackout detection (tape, palm, flat on table)
    if (avgLuma < 22.0) {
      return true;
    }

    // 2. High-frequency edge gradient detection (lens cover creates complete defocus blur)
    double edgeDiffSum = 0;
    int edgeCount = 0;
    for (int i = 0; i < yBytes.length - 1; i += step) {
      edgeDiffSum += (yBytes[i] - yBytes[i + 1]).abs();
      edgeCount++;
    }
    final double avgEdgeDiff = edgeCount > 0 ? (edgeDiffSum / edgeCount) : 0.0;

    if (avgEdgeDiff < 2.8) {
      return true;
    }

    // 3. Chrominance: Blood / Tissue Transillumination (finger placed over lens)
    if (image.planes.length >= 3) {
      final uBytes = image.planes[1].bytes;
      final vBytes = image.planes[2].bytes;

      int sumU = 0;
      int sumV = 0;
      int uvCount = 0;
      const uvStep = 8;

      for (int i = 0; i < uBytes.length && i < vBytes.length; i += uvStep) {
        sumU += uBytes[i];
        sumV += vBytes[i];
        uvCount++;
      }

      if (uvCount > 0) {
        final double avgU = sumU / uvCount;
        final double avgV = sumV / uvCount;
        final double redExcess = avgV - avgU;

        if (redExcess > 20.0 && avgEdgeDiff < 5.0) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || !_isMonitoring || _controller == null) return;

    final now = DateTime.now();
    if (now.difference(_lastProcessedTime).inMilliseconds < 200) {
      return;
    }
    _lastProcessedTime = now;
    _isProcessing = true;

    try {
      // ── CHECK 1: Hardware Proximity & Optical Camera Occlusion ────────────
      final isOpticalOccluded = _checkCameraOcclusion(image);
      final isOccluded = _isProximityOccluded || isOpticalOccluded;

      if (isOccluded) {
        _consecutiveOcclusions++;
        _consecutiveSafeFrames = 0;

        if (_consecutiveOcclusions >= 1) {
          _lastThreatReason = 'Camera Sensor Blocked / Covered';
          _lastThreatName = 'Obstruction / Finger Detected';
          if (_currentState != ProtectionState.occluded && _currentState != ProtectionState.triggered) {
            _emitState(ProtectionState.occluded);
            debugPrint('SECURITY ALERT: Camera is covered or occluded!');
          }
          _isProcessing = false;
          return;
        }
      } else {
        _consecutiveOcclusions = 0;
      }

      // ── CHECK 2: External Camera / Phone Detection (All Angles) ──────────
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final labels = await _imageLabeler!.processImage(inputImage);
      bool threatDetected = false;
      double highestScore = 0.0;
      String threatLabel = '';
      bool hasMouse = false;

      for (final label in labels) {
        final text = label.label.toLowerCase().trim();
        if (text.contains('mouse') || text.contains('trackball') || text.contains('keyboard')) {
          hasMouse = true;
          break;
        }
      }

      for (final label in labels) {
        final text = label.label.toLowerCase().trim();

        // 1. Skip benign objects (faces, mice, clothing, desk items)
        bool isBenign = false;
        for (final bk in _benignKeywords) {
          if (text == bk || text.contains(bk)) {
            if (!text.contains('phone') && !text.contains('camera')) {
              isBenign = true;
              break;
            }
          }
        }
        if (isBenign) continue;

        if (text.contains('microphone') || text.contains('headphone') || text.contains('earphone')) {
          continue;
        }

        // 2. Direct threat check (mobile phone, camera, lens, screen, tablet)
        for (final dtk in _directThreatKeywords) {
          if (text == dtk || text.contains(dtk)) {
            if (label.confidence >= 0.30) {
              threatDetected = true;
              if (label.confidence > highestScore) {
                highestScore = label.confidence;
                threatLabel = label.label;
              }
            }
          }
        }

        // 3. Secondary threat check (gadget, electronic device)
        if (!hasMouse) {
          for (final stk in _secondaryThreatKeywords) {
            if (text == stk || text.contains(stk)) {
              if (label.confidence >= 0.45) {
                threatDetected = true;
                if (label.confidence * 0.9 > highestScore) {
                  highestScore = label.confidence * 0.9;
                  threatLabel = label.label;
                }
              }
            }
          }
        }
      }

      if (threatDetected) {
        _lastThreatName = threatLabel.isNotEmpty ? threatLabel : 'External Camera';
        _lastThreatReason = 'External Recording Device Detected ($threatLabel)';
        _consecutiveThreats++;
        _consecutiveSafeFrames = 0;

        if (_consecutiveThreats >= 1) {
          if (_currentState != ProtectionState.triggered) {
            _emitState(ProtectionState.triggered);
            debugPrint('SECURITY ALERT: Recording device detected ($threatLabel, conf: $highestScore)');
          }
        }
      } else if (!isOccluded) {
        _consecutiveSafeFrames++;
        if (_consecutiveSafeFrames >= 2) {
          _consecutiveThreats = 0;
          _consecutiveOcclusions = 0;
          if (_currentState == ProtectionState.triggered || 
              _currentState == ProtectionState.occluded || 
              _currentState == ProtectionState.suspicious) {
            _emitState(ProtectionState.monitoring);
            debugPrint('SECURITY INFO: Camera clear & safe. Screen unshielded.');
          }
        }
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

    final Uint8List allBytes = _convertCameraImageToBytes(image);

    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888,
      bytesPerRow: image.width,
    );

    return InputImage.fromBytes(bytes: allBytes, metadata: inputImageData);
  }

  Uint8List _convertCameraImageToBytes(CameraImage image) {
    if (Platform.isAndroid) {
      if (image.planes.length == 1) {
        return image.planes[0].bytes;
      }

      final int width = image.width;
      final int height = image.height;
      final int ySize = width * height;
      final int uvSize = width * height ~/ 2;
      final Uint8List nv21 = Uint8List(ySize + uvSize);

      final Plane yPlane = image.planes[0];
      final Plane uPlane = image.planes[1];
      final Plane vPlane = image.planes[2];

      final Uint8List yBuffer = yPlane.bytes;
      final Uint8List uBuffer = uPlane.bytes;
      final Uint8List vBuffer = vPlane.bytes;

      final int yRowStride = yPlane.bytesPerRow;
      final int yPixelStride = yPlane.bytesPerPixel ?? 1;

      int pos = 0;
      if (yRowStride == width && yPixelStride == 1) {
        nv21.setRange(0, ySize, yBuffer);
        pos = ySize;
      } else {
        for (int row = 0; row < height; row++) {
          final int rowOffset = row * yRowStride;
          for (int col = 0; col < width; col++) {
            nv21[pos++] = yBuffer[rowOffset + col * yPixelStride];
          }
        }
      }

      final int uvRowStride = vPlane.bytesPerRow;
      final int uvPixelStride = vPlane.bytesPerPixel ?? 1;
      final int uvHeight = height ~/ 2;
      final int uvWidth = width ~/ 2;

      for (int row = 0; row < uvHeight; row++) {
        final int rowOffset = row * uvRowStride;
        for (int col = 0; col < uvWidth; col++) {
          final int colOffset = col * uvPixelStride;
          nv21[pos++] = vBuffer[rowOffset + colOffset]; // V
          nv21[pos++] = uBuffer[rowOffset + colOffset]; // U
        }
      }

      return nv21;
    } else {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      return allBytes.done().buffer.asUint8List();
    }
  }
}
