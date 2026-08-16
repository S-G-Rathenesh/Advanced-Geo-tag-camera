import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/network/api_endpoints.dart';
import '../core/security/secure_storage_service.dart';
import '../core/storage/evidence_queue_dao.dart';
import '../models/evidence_record.dart';
import '../models/sync_status.dart';

/// Synchronization service for uploading pending evidence to the backend.
///
/// Executes multi-part binary uploads of AES-encrypted evidence to the FastAPI backend,
/// verifying payload SHA-256 integrity and persisting metadata in Neon PostgreSQL.
///
/// Supports automatic sync: listens for connectivity changes and retries pending
/// uploads whenever network becomes available.
class SyncService extends ChangeNotifier {
  final EvidenceQueueDao _dao;
  final Connectivity _connectivity;

  bool _isSyncing = false;
  String? _lastError;
  DateTime? _lastSyncTime;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  SyncService({
    EvidenceQueueDao? dao,
    Connectivity? connectivity,
  })  : _dao = dao ?? EvidenceQueueDao(),
        _connectivity = connectivity ?? Connectivity();

  // ── Public getters ────────────────────────────────────────────────────

  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;

  // ── Auto-Sync Lifecycle ───────────────────────────────────────────────

  /// Start listening for connectivity changes and auto-sync pending evidence.
  /// Call this once when the app starts (e.g. after login or from main).
  void startAutoSync() {
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final hasNetwork = !results.contains(ConnectivityResult.none);
      if (hasNetwork && !_isSyncing) {
        debugPrint('[SYNC] Network restored — auto-syncing pending evidence...');
        syncAll();
      }
    });
    // Also attempt an immediate sync on start
    syncAll();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

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

    // Web platform guard — dart:io File not available on web
    if (kIsWeb) {
      _lastError = 'Sync is available on the Android application';
      notifyListeners();
      return;
    }

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

      // Upload encrypted payload to FastAPI backend
      final success = await _uploadToServer(record);

      if (success) {
        await _dao.updateSyncStatus(record.captureId, SyncStatus.synced);
        if (record.encryptedPath != null && record.encryptedPath!.isNotEmpty) {
          try {
            final file = File(record.encryptedPath!);
            if (await file.exists()) {
              await file.delete();
              debugPrint('[SYNC] Purged synced encrypted file: ${record.encryptedPath}');
            }
          } catch (e) {
            debugPrint('[SYNC] Warning: Failed to delete encrypted file after sync (${record.captureId}): $e');
          }
        }
      } else {
        await _dao.updateSyncStatus(record.captureId, SyncStatus.failed);
        await _dao.incrementRetryCount(record.captureId);
      }
    } catch (e) {
      await _dao.updateSyncStatus(record.captureId, SyncStatus.failed);
      await _dao.incrementRetryCount(record.captureId);
    }
  }

  /// Uploads directly to FastAPI backend.
  Future<bool> _uploadToServer(EvidenceRecord record) async {
    try {
      if (record.encryptedPath == null) return false;
      final encryptedFile = File(record.encryptedPath!);
      if (!encryptedFile.existsSync()) return false;

      // Read the encrypted bytes for upload
      final encryptedBytes = await encryptedFile.readAsBytes();
      
      // Calculate payload hash
      final payloadHash = sha256.convert(encryptedBytes).toString();

      // 2. Prepare Multipart Request for FastAPI
      final url = Uri.parse('${AppConstants.apiBaseUrl}${ApiEndpoints.uploadEvidence}');
      final request = http.MultipartRequest('POST', url)
        ..fields['capture_id'] = record.captureId
        ..fields['device_id'] = record.deviceId
        ..fields['sha256_hash'] = record.sha256Hash
        ..fields['payload_hash'] = payloadHash
        ..fields['latitude'] = record.latitude.toString()
        ..fields['longitude'] = record.longitude.toString()
        ..fields['gps_accuracy'] = record.accuracy.toString()
        ..fields['capture_timestamp'] = record.timestamp.toIso8601String();
        
      if (record.altitude != null) {
        request.fields['altitude'] = record.altitude.toString();
      }
      if (record.address != null) {
        request.fields['address'] = record.address!;
      }
      if (record.gnssConstellations.isNotEmpty) {
        request.fields['gnss_constellations'] = jsonEncode(record.gnssConstellations);
      }
      if (record.ivBase64 != null) {
        request.fields['iv_base64'] = record.ivBase64!;
      }
        
      request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            encryptedBytes,
            filename: '${record.captureId}.enc',
          ),
      );

      // Add auth token (using SecureStorageService implicitly via DI or a new instance)
      // Since ApiClient isn't injected, we'll fetch it locally or we can use ApiClient if we added it.
      // For now, fetch from SecureStorageService.
      final secureStorageService = SecureStorageService();
      final token = await secureStorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      print('\n[upload]');
      print('capture_id=${request.fields['capture_id']}');
      print('owner_id=${record.userId}');
      print('latitude=${request.fields['latitude']}');
      print('longitude=${request.fields['longitude']}');
      print('accuracy=${request.fields['gps_accuracy']}');
      print('capture_timestamp=${request.fields['capture_timestamp']}');
      print('sha256_hash=${request.fields['sha256_hash']}');
      print('iv_present=${request.fields['iv_base64'] != null}');
      print('gnss_constellations=${request.fields['gnss_constellations']}');
      print('------\n');

      // 3. Execute Upload
      final response = await request.send().timeout(AppConstants.apiTimeout);
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Validate that the server actually stored the IV
        try {
          final data = jsonDecode(respStr);
          if (data['iv_base64'] == null || (data['iv_base64'] as String).isEmpty) {
            debugPrint('FastAPI upload succeeded but iv_base64 is missing in response. Rejecting sync.');
            return false;
          }
          return true;
        } catch (e) {
          debugPrint('Failed to parse FastAPI response: $e');
          return false;
        }
      } else {
        debugPrint('FastAPI upload failed: ${response.statusCode} - $respStr');
        return false;
      }
    } catch (e) {
      debugPrint('FastAPI upload error: $e');
      return false;
    }
  }

}
