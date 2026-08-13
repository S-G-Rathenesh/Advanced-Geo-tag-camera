import 'dart:io';


import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../core/security/encryption_service.dart';
import '../core/security/hash_service.dart';
import '../core/storage/evidence_queue_dao.dart';
import '../core/utils/capture_id_generator.dart';
import '../models/evidence_record.dart';
import '../models/sync_status.dart';

/// Evidence lifecycle service.
///
/// Manages the complete evidence pipeline: create record → hash → encrypt
/// → queue for sync → mark synced → delete local file.
class EvidenceService extends ChangeNotifier {
  final EvidenceQueueDao _dao;
  final HashService _hashService;
  final EncryptionService _encryptionService;
  final CaptureIdGenerator _idGenerator;

  List<EvidenceRecord> _evidenceList = [];
  bool _isLoading = false;

  EvidenceService({
    EvidenceQueueDao? dao,
    HashService? hashService,
    EncryptionService? encryptionService,
    CaptureIdGenerator? idGenerator,
  })  : _dao = dao ?? EvidenceQueueDao(),
        _hashService = hashService ?? const HashService(),
        _encryptionService = encryptionService ?? EncryptionService(),
        _idGenerator = idGenerator ?? const CaptureIdGenerator();

  // ── Public getters ────────────────────────────────────────────────────

  List<EvidenceRecord> get evidenceList => _evidenceList;
  bool get isLoading => _isLoading;

  int get pendingCount =>
      _evidenceList.where((e) => e.syncStatus == SyncStatus.pending).length;
  int get syncedCount =>
      _evidenceList.where((e) => e.syncStatus == SyncStatus.synced).length;
  int get failedCount =>
      _evidenceList.where((e) => e.syncStatus == SyncStatus.failed).length;

  // ── Evidence Pipeline ─────────────────────────────────────────────────

  /// Create a new evidence record from a captured image.
  ///
  /// 1. Generates a unique capture ID.
  /// 2. Reads the image file.
  /// 3. Computes SHA-256 hash.
  /// 4. Encrypts and saves to app-private directory.
  /// 5. Inserts into the offline queue.
  Future<EvidenceRecord> createEvidence({
    required String userId,
    required String deviceId,
    required String imagePath,
    required double latitude,
    required double longitude,
    double? altitude,
    required double accuracy,
  }) async {
    final captureId = _idGenerator.generate();
    final now = DateTime.now();

    // Read raw image bytes
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();

    // Generate integrity hash
    final sha256Hash = _hashService.generateSha256(imageBytes);

    // Encrypt image bytes
    final encrypted = await _encryptionService.encryptBytes(imageBytes);

    // Save encrypted file to app-private directory
    final appDir = await getApplicationDocumentsDirectory();
    final encDir = Directory('${appDir.path}/encrypted_evidence');
    if (!await encDir.exists()) {
      await encDir.create(recursive: true);
    }
    final encryptedPath = '${encDir.path}/$captureId.enc';
    await File(encryptedPath).writeAsString(encrypted['ciphertext']!);

    // Build the evidence record
    final record = EvidenceRecord(
      captureId: captureId,
      userId: userId,
      deviceId: deviceId,
      imagePath: imagePath,
      encryptedPath: encryptedPath,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      accuracy: accuracy,
      timestamp: now,
      sha256Hash: sha256Hash,
      syncStatus: SyncStatus.pending,
      ivBase64: encrypted['iv'],
      createdAt: now,
      updatedAt: now,
    );

    // Insert into offline queue
    await _dao.insert(record);

    // Refresh list
    await loadEvidence();

    return record;
  }

  /// Load all evidence records from the local database.
  Future<void> loadEvidence({SyncStatus? status}) async {
    _isLoading = true;
    notifyListeners();

    _evidenceList = await _dao.getAll(status: status);

    _isLoading = false;
    notifyListeners();
  }

  /// Get a single evidence record by ID.
  Future<EvidenceRecord?> getEvidence(String captureId) async {
    return _dao.getById(captureId);
  }

  /// Mark evidence as synced and delete local files.
  Future<void> markSyncedAndCleanup(String captureId) async {
    await _dao.updateSyncStatus(captureId, SyncStatus.synced);

    // Delete local encrypted file
    final record = await _dao.getById(captureId);
    if (record?.encryptedPath != null) {
      final file = File(record!.encryptedPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Delete original image
    if (record?.imagePath != null) {
      final file = File(record!.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await loadEvidence();
  }

  /// Get sync status counts for dashboard display.
  Future<Map<SyncStatus, int>> getSyncCounts() async {
    return _dao.getCounts();
  }
}
