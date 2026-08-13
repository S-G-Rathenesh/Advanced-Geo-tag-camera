/// API endpoint path constants.
///
/// Paths only – the base URL is configured in [ApiClient].
/// These will map 1-to-1 to FastAPI routes when the backend is built.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Authentication ────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/auth/profile';

  // ── Evidence ──────────────────────────────────────────────────────────
  static const String uploadEvidence = '/evidence/upload';
  static const String listEvidence = '/evidence/list';
  static const String evidenceDetail = '/evidence/'; // + captureId

  // ── Sync ──────────────────────────────────────────────────────────────
  static const String syncStatus = '/sync/status';
}
