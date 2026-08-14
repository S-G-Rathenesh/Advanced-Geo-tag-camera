import 'package:flutter/foundation.dart';

/// App-wide constants for the Geo Evidence application.
///
/// All configurable thresholds and identifiers are centralized here
/// to avoid magic numbers scattered across the codebase.
class AppConstants {
  AppConstants._();

  // 🛡️ App Identity 🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️🛡️
  static const String appName = 'Capturovert';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Secure Field Evidence Capture';

  // 🌐 API Configuration 🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐
  /// Hosted FastAPI backend on Render or localhost for debug.
  static String get apiBaseUrl {
    if (kDebugMode) {
      // We use localhost for debug mode, but since web requires IP or localhost we just use localhost.
      return 'http://127.0.0.1:8000/api/v1';
    }
    return 'https://advanced-geo-tag-camera.onrender.com/api/v1';
  }
  static const Duration apiTimeout = Duration(seconds: 30);

  // ── GPS / Location ────────────────────────────────────────────────────
  /// Minimum acceptable GPS accuracy in metres.
  /// Captures with accuracy worse than this value will be rejected.
  static const double gpsAccuracyThresholdMetres = 50.0;

  /// Location request timeout.
  static const Duration locationTimeout = Duration(seconds: 15);

  // Cloudinary configuration (Moved to FastAPI backend)
  // static const String cloudinaryCloudName = '...';

  // ── Synchronization ───────────────────────────────────────────────────
  static const Duration syncRetryInterval = Duration(minutes: 5);
  static const int maxSyncRetries = 3;

  // ── Security ──────────────────────────────────────────────────────────
  static const String jwtStorageKey = 'auth_jwt_token';
  static const String refreshTokenKey = 'auth_refresh_token';
  static const String encryptionKeyStorageKey = 'evidence_enc_key';

  // ── Local Database ────────────────────────────────────────────────────
  static const String databaseName = 'capturovert.db';
  static const int databaseVersion = 1;
  static const String evidenceTable = 'evidence_queue';
}
