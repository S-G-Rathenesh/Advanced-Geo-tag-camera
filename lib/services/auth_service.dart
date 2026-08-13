

import 'package:flutter/foundation.dart';

import '../core/security/secure_storage_service.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/user_model.dart';

/// Authentication service with mock implementation.
///
/// The mock backend accepts predefined credentials for development.
/// When the FastAPI backend is integrated, only the [login] method
/// body needs to be replaced with a real HTTP call.
class AuthService extends ChangeNotifier {
  final SecureStorageService _secureStorage;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthService({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService();

  // ── Public getters ────────────────────────────────────────────────────

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Mock credentials ──────────────────────────────────────────────────

  static const _mockUsers = {
    'officer@geotag.com': {
      'password': 'password123',
      'user': {
        'user_id': 'usr_001',
        'name': 'Officer James Chen',
        'email': 'officer@geotag.com',
        'role': 'officer',
        'badge_number': 'GE-2024-0451',
      },
      'token': 'mock_jwt_officer_token_v1',
    },
    'supervisor@geotag.com': {
      'password': 'password123',
      'user': {
        'user_id': 'usr_002',
        'name': 'Supervisor Maria Santos',
        'email': 'supervisor@geotag.com',
        'role': 'supervisor',
        'badge_number': 'GE-2024-0102',
      },
      'token': 'mock_jwt_supervisor_token_v1',
    },
  };

  // ── Authentication ────────────────────────────────────────────────────

  /// Attempt to login with mock credentials.
  Future<LoginResponse> login(LoginRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final mockUser = _mockUsers[request.email];

      if (mockUser == null ||
          mockUser['password'] != request.password) {
        _isLoading = false;
        _error = 'Invalid email or password';
        notifyListeners();
        return LoginResponse.error(_error!);
      }

      final userJson = mockUser['user'] as Map<String, dynamic>;
      final token = mockUser['token'] as String;

      // Persist token securely
      await _secureStorage.saveToken(token);

      _currentUser = UserModel.fromJson(userJson);
      _isLoading = false;
      _error = null;
      notifyListeners();

      return LoginResponse(
        success: true,
        token: token,
        user: _currentUser,
      );
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred';
      notifyListeners();
      return LoginResponse.error(_error!);
    }
  }

  /// Try to restore session from secure storage.
  Future<bool> tryAutoLogin() async {
    final hasSession = await _secureStorage.hasValidSession();
    if (!hasSession) return false;

    // In the mock, we restore the officer user by default.
    // In production, we'd call the /auth/profile endpoint.
    _currentUser = UserModel.fromJson(
      _mockUsers['officer@geotag.com']!['user'] as Map<String, dynamic>,
    );
    notifyListeners();
    return true;
  }

  /// Logout and clear all secure data.
  Future<void> logout() async {
    await _secureStorage.clearAll();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
}
