import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

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

  bool _isSyncing = false;
  String? _lastError;
  DateTime? _lastSyncTime;

  SyncService({
    EvidenceQueueDao? dao,
    Connectivity? connectivity,
  })  : _dao = dao ?? EvidenceQueueDao(),
        _connectivity = connectivity ?? Connectivity();

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

  /// Mock server upload. Replace with real API call when FastAPI is ready.
  Future<bool> _uploadToServer(EvidenceRecord record) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 1200));

    // Mock: 90% success rate to test retry logic
    // In production, this will be an actual HTTP POST
    return DateTime.now().millisecond % 10 != 0;
  }
}
