import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/security/secure_storage_service.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final SecureStorageService _secureStorage;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthService({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService();

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Officer login via username/password against FastAPI backend.
  Future<LoginResponse> login(LoginRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/officer/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': request.email,
          'password': request.password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;
        final userJson = data['user'] as Map<String, dynamic>;

        await _secureStorage.saveToken(token);
        _currentUser = UserModel.fromJson(userJson);
        
        debugPrint('[AUTH] Officer login success: ${_currentUser?.roleLabel}');
        _isLoading = false;
        notifyListeners();
        return LoginResponse(success: true, token: token, user: _currentUser);
      } else {
        _isLoading = false;
        _error = 'Invalid credentials or unauthorized';
        notifyListeners();
        return LoginResponse.error(_error!);
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error: $e';
      notifyListeners();
      return LoginResponse.error(_error!);
    }
  }

  /// Google-style login via mock JWT sent to FastAPI /auth/google endpoint.
  /// Used by Demo Supervisor, Demo User, and Mock Google login dialog.
  Future<LoginResponse> googleLogin(String mockEmail, String mockSub, String mockName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create a mock JWT to simulate a Google Identity token
      final header = base64UrlEncode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
      final payload = base64UrlEncode(utf8.encode(jsonEncode({
        'email': mockEmail,
        'sub': mockSub,
        'name': mockName,
        'picture': null,
      })));
      final mockIdToken = '$header.$payload.mocksignature';

      final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/google');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': mockIdToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;
        final userJson = data['user'] as Map<String, dynamic>;

        await _secureStorage.saveToken(token);
        _currentUser = UserModel.fromJson(userJson);
        
        debugPrint('[AUTH] Google login success: ${_currentUser?.roleLabel}');
        _isLoading = false;
        notifyListeners();
        return LoginResponse(success: true, token: token, user: _currentUser);
      } else {
        _isLoading = false;
        _error = 'Google Auth Failed: ${response.statusCode}';
        notifyListeners();
        return LoginResponse.error(_error!);
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error: $e';
      notifyListeners();
      return LoginResponse.error(_error!);
    }
  }

  /// Attempt to restore session from stored JWT by calling /auth/me.
  Future<bool> tryAutoLogin() async {
    final hasSession = await _secureStorage.hasValidSession();
    if (!hasSession) return false;

    try {
      final token = await _secureStorage.getToken();
      if (token == null) return false;

      final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/me');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userJson = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userJson);
        debugPrint('[AUTH] Auto-login restored: ${_currentUser?.roleLabel}');
        notifyListeners();
        return true;
      } else {
        debugPrint('[AUTH] Auto-login failed: ${response.statusCode}');
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('[AUTH] Auto-login error: $e');
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.clearAll();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
}
