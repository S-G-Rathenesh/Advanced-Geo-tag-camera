import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// SHA-256 integrity hashing service.
///
/// Generates a deterministic hash of the raw image bytes so that
/// any subsequent tampering can be detected by re-hashing.
class HashService {
  const HashService();

  /// Returns the SHA-256 hex digest of [data].
  String generateSha256(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  /// Verifies that [data] matches the expected [hash].
  bool verifySha256(Uint8List data, String hash) {
    return generateSha256(data) == hash;
  }
}
