import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Wrapper around [FlutterSecureStorage] for JWT token management.
///
/// Tokens are stored in the Android Keystore (hardware-backed) and
/// are never accessible outside this application.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  // ── JWT Token ─────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.jwtStorageKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.jwtStorageKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.jwtStorageKey);
  }

  // ── Refresh Token ─────────────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  // ── Session management ────────────────────────────────────────────────

  /// Returns `true` if a JWT token exists in secure storage.
  Future<bool> hasValidSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clears all authentication data from secure storage.
  Future<void> clearAll() async {
    await deleteToken();
    await deleteRefreshToken();
    // Intentionally omitting _storage.deleteAll() to prevent wiping the
    // local AES-256-GCM encryption key used for evidence decryption.
  }
}
