import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/network/api_endpoints.dart';
import '../core/security/encryption_service.dart';
import '../core/storage/evidence_queue_dao.dart';
import '../models/evidence_record.dart';
import '../models/sync_status.dart';

/// Synchronization service for uploading pending evidence to the backend.
///
/// Currently uses mock responses. When the FastAPI backend is ready,
/// replace [_uploadToServer] with real HTTP calls via [ApiClient].
class SyncService extends ChangeNotifier {
  final EvidenceQueueDao _dao;
  final Connectivity _connectivity;
  final EncryptionService _encryptionService;

  bool _isSyncing = false;
  String? _lastError;
  DateTime? _lastSyncTime;

  SyncService({
    EvidenceQueueDao? dao,
    Connectivity? connectivity,
    EncryptionService? encryptionService,
  })  : _dao = dao ?? EvidenceQueueDao(),
        _connectivity = connectivity ?? Connectivity(),
        _encryptionService = encryptionService ?? EncryptionService();

  // ── Public getters ────────────────────────────────────────────────────

  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;

  // ── Connectivity ──────────────────────────────────────────────────────

  /// Check if the device has an active network connection.
  Future<bool> hasConnection() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Stream of connectivity changes.
  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  // ── Sync Operations ───────────────────────────────────────────────────

  /// Attempt to sync all pending evidence to the server.
  Future<void> syncAll() async {
    if (_isSyncing) return;

    final connected = await hasConnection();
    if (!connected) {
      _lastError = 'No internet connection';
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final pending = await _dao.getPendingForSync();

      for (final record in pending) {
        await _syncSingleRecord(record);
      }

      _lastSyncTime = DateTime.now();
    } catch (e) {
      _lastError = 'Sync failed: ${e.toString()}';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncSingleRecord(EvidenceRecord record) async {
    try {
      // Mark as syncing
      await _dao.updateSyncStatus(record.captureId, SyncStatus.syncing);
      notifyListeners();

      // Mock upload – simulate server round-trip
      final success = await _uploadToServer(record);

      if (success) {
        await _dao.updateSyncStatus(record.captureId, SyncStatus.synced);
      } else {
        await _dao.updateSyncStatus(record.captureId, SyncStatus.failed);
        await _dao.incrementRetryCount(record.captureId);
      }
    } catch (e) {
      await _dao.updateSyncStatus(record.captureId, SyncStatus.failed);
      await _dao.incrementRetryCount(record.captureId);
    }
  }

  /// Uploads directly to Cloudinary.
  Future<bool> _uploadToServer(EvidenceRecord record) async {
    try {
      // 1. Decrypt the file locally so Cloudinary can process it as an image
      if (record.encryptedPath == null || record.ivBase64 == null) return false;
      final encryptedFile = File(record.encryptedPath!);
      if (!encryptedFile.existsSync()) return false;

      final ciphertextBase64 = await encryptedFile.readAsString();
      final decryptedBytes = await _encryptionService.decryptBytes(
        ciphertextBase64: ciphertextBase64,
        ivBase64: record.ivBase64!,
      );

      // 2. Generate Cloudinary Signature
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final context = 'captureId=${record.captureId}|userId=${record.userId}|lat=${record.latitude}|lng=${record.longitude}|hash=${record.sha256Hash}';
      
      final Map<String, String> paramsToSign = {
        'context': context,
        'timestamp': timestamp.toString(),
      };
      
      final signature = _generateCloudinarySignature(
        paramsToSign, 
        AppConstants.cloudinaryApiSecret
      );

      // 3. Prepare Multipart Request
      final url = Uri.parse(
        ApiEndpoints.cloudinaryUpload(AppConstants.cloudinaryCloudName)
      );
      
      final request = http.MultipartRequest('POST', url)
        ..fields['api_key'] = AppConstants.cloudinaryApiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..fields['context'] = context
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            decryptedBytes,
            filename: '${record.captureId}.jpg',
          ),
        );

      // 4. Execute Upload
      final response = await request.send().timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint('Cloudinary upload failed: ${response.statusCode} - $respStr');
        return false;
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return false;
    }
  }

  String _generateCloudinarySignature(Map<String, String> params, String apiSecret) {
    // 1. Sort parameters alphabetically by key
    final sortedKeys = params.keys.toList()..sort();
    
    // 2. Format as key=value&key=value
    final formattedParams = sortedKeys.map((k) => '$k=${params[k]}').join('&');
    
    // 3. Append API secret
    final stringToSign = '$formattedParams$apiSecret';
    
    // 4. SHA-1 hash and hex encode
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
}
