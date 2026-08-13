import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// AES-256-GCM encryption service for evidence files.
///
/// The encryption key is generated once and persisted in secure storage
/// (Android Keystore). Evidence images are encrypted before being stored
/// in the offline queue to prevent tampering.
class EncryptionService {
  final FlutterSecureStorage _secureStorage;

  EncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// Returns the persisted AES-256 key, creating one if it doesn't exist.
  Future<enc.Key> _getOrCreateKey() async {
    String? stored =
        await _secureStorage.read(key: AppConstants.encryptionKeyStorageKey);

    if (stored != null) {
      return enc.Key(base64Decode(stored));
    }

    // Generate a new 32-byte (256-bit) key
    final key = enc.Key.fromSecureRandom(32);
    await _secureStorage.write(
      key: AppConstants.encryptionKeyStorageKey,
      value: base64Encode(key.bytes),
    );
    return key;
  }

  /// Encrypts [plainBytes] using AES-256-GCM.
  /// Returns a map with `iv` (base64) and `ciphertext` (base64).
  Future<Map<String, String>> encryptBytes(Uint8List plainBytes) async {
    final key = await _getOrCreateKey();
    final iv = enc.IV.fromSecureRandom(12); // 96-bit nonce for GCM

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    return {
      'iv': base64Encode(iv.bytes),
      'ciphertext': encrypted.base64,
    };
  }

  /// Decrypts AES-256-GCM encrypted data.
  Future<Uint8List> decryptBytes({
    required String ciphertextBase64,
    required String ivBase64,
  }) async {
    final key = await _getOrCreateKey();
    final iv = enc.IV(base64Decode(ivBase64));

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final decrypted = encrypter.decryptBytes(
      enc.Encrypted(base64Decode(ciphertextBase64)),
      iv: iv,
    );

    return Uint8List.fromList(decrypted);
  }

  /// Wipe the encryption key (e.g. on account logout).
  Future<void> deleteKey() async {
    await _secureStorage.delete(key: AppConstants.encryptionKeyStorageKey);
  }
}
