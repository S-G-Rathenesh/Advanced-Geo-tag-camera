import 'sync_status.dart';

/// Primary evidence data model.
///
/// Represents a single geo-tagged photographic evidence record captured
/// by a field officer. Contains all metadata required for chain-of-custody
/// integrity: location, device info, hashing, and sync state.
class EvidenceRecord {
  final String captureId;
  final String userId;
  final String deviceId;
  final String imagePath;
  final String? encryptedPath;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double accuracy;
  final DateTime timestamp;
  final String sha256Hash;
  final SyncStatus syncStatus;
  final String? ivBase64;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EvidenceRecord({
    required this.captureId,
    required this.userId,
    required this.deviceId,
    required this.imagePath,
    this.encryptedPath,
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.accuracy,
    required this.timestamp,
    required this.sha256Hash,
    this.syncStatus = SyncStatus.pending,
    this.ivBase64,
    this.retryCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with modified fields.
  EvidenceRecord copyWith({
    String? captureId,
    String? userId,
    String? deviceId,
    String? imagePath,
    String? encryptedPath,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    DateTime? timestamp,
    String? sha256Hash,
    SyncStatus? syncStatus,
    String? ivBase64,
    int? retryCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EvidenceRecord(
      captureId: captureId ?? this.captureId,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      imagePath: imagePath ?? this.imagePath,
      encryptedPath: encryptedPath ?? this.encryptedPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      syncStatus: syncStatus ?? this.syncStatus,
      ivBase64: ivBase64 ?? this.ivBase64,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── SQLite serialization ──────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'captureId': captureId,
      'userId': userId,
      'deviceId': deviceId,
      'imagePath': imagePath,
      'encryptedPath': encryptedPath,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'sha256Hash': sha256Hash,
      'syncStatus': syncStatus.name,
      'ivBase64': ivBase64,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EvidenceRecord.fromMap(Map<String, dynamic> map) {
    return EvidenceRecord(
      captureId: map['captureId'] as String,
      userId: map['userId'] as String,
      deviceId: map['deviceId'] as String,
      imagePath: map['imagePath'] as String,
      encryptedPath: map['encryptedPath'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: map['altitude'] != null
          ? (map['altitude'] as num).toDouble()
          : null,
      accuracy: (map['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      sha256Hash: map['sha256Hash'] as String,
      syncStatus:
          SyncStatusExtension.fromString(map['syncStatus'] as String),
      ivBase64: map['ivBase64'] as String?,
      retryCount: (map['retryCount'] as int?) ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // ── JSON serialization (for API) ──────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'capture_id': captureId,
      'user_id': userId,
      'device_id': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'sha256_hash': sha256Hash,
      'sync_status': syncStatus.name,
    };
  }

  factory EvidenceRecord.fromJson(Map<String, dynamic> json) {
    return EvidenceRecord(
      captureId: json['capture_id'] as String,
      userId: json['user_id'] as String,
      deviceId: json['device_id'] as String,
      imagePath: json['image_path'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: json['altitude'] != null
          ? (json['altitude'] as num).toDouble()
          : null,
      accuracy: (json['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      sha256Hash: json['sha256_hash'] as String,
      syncStatus: SyncStatusExtension.fromString(
          json['sync_status'] as String? ?? 'pending'),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  String toString() =>
      'EvidenceRecord(captureId: $captureId, status: ${syncStatus.name})';
}
