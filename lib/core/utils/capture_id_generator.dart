import 'package:uuid/uuid.dart';

/// Generates unique capture IDs for evidence records.
///
/// Uses UUID v4 (cryptographically random) to ensure global uniqueness
/// without requiring a central authority or database sequence.
class CaptureIdGenerator {
  static const _uuid = Uuid();

  const CaptureIdGenerator();

  /// Generate a new unique capture ID.
  String generate() => _uuid.v4();
}
