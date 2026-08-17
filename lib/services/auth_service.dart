import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

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
        await _secureStorage.saveUserJson(jsonEncode(userJson));
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
      _error = 'Network error: $e';
      notifyListeners();
      return LoginResponse.error(_error!);
    }
  }

  /// 1-Tap Demo login via /auth/demo
  Future<LoginResponse> demoLogin(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/demo');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;
        final userJson = data['user'] as Map<String, dynamic>;

        await _secureStorage.saveToken(token);
        await _secureStorage.saveUserJson(jsonEncode(userJson));
        _currentUser = UserModel.fromJson(userJson);
        
        final jwtRole = _decodeJwtRole(token);
        debugPrint('[AUTH] JWT Embedded Role: $jwtRole');
        debugPrint('[AUTH] Demo login success: ${_currentUser?.roleLabel}');
        _isLoading = false;
        notifyListeners();
        return LoginResponse(success: true, token: token, user: _currentUser);
      } else {
        _isLoading = false;
        _error = 'Demo Login Failed: ${response.statusCode}';
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

  final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn(
          clientId: '623719964431-cu0so7n08k2vaea5m2uds8rflq552m0t.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        )
      : GoogleSignIn(
          serverClientId: '623719964431-cu0so7n08k2vaea5m2uds8rflq552m0t.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );

  /// Real Google-style login using native Google Sign In.
  Future<LoginResponse> googleLogin() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Trigger the native Google Sign In flow
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null) {
        // User canceled the sign-in flow
        _isLoading = false;
        _error = 'Sign in canceled by user';
        notifyListeners();
        return LoginResponse.error(_error!);
      }

      // Obtain the auth details (which contains the idToken)
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        _isLoading = false;
        _error = 'Failed to get ID token from Google';
        notifyListeners();
        return LoginResponse.error(_error!);
      }

      final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/google');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': idToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;
        final userJson = data['user'] as Map<String, dynamic>;

        await _secureStorage.saveToken(token);
        await _secureStorage.saveUserJson(jsonEncode(userJson));
        _currentUser = UserModel.fromJson(userJson);
        
        debugPrint('[AUTH] Google login success: ${_currentUser?.roleLabel}');
        _isLoading = false;
        notifyListeners();
        return LoginResponse(success: true, token: token, user: _currentUser);
      } else {
        // We sign out from google so they can try again if the backend rejected them
        await _googleSignIn.signOut();
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

  /// Attempt to restore session from stored JWT by calling /auth/me or loading local user JSON.
  Future<bool> tryAutoLogin() async {
    final hasSession = await _secureStorage.hasValidSession();
    if (!hasSession) return false;

    try {
      final token = await _secureStorage.getToken();
      if (token == null) return false;

      // First try to load the local user data so the app can start instantly
      final localUserJsonStr = await _secureStorage.getUserJson();
      if (localUserJsonStr != null) {
        final userMap = jsonDecode(localUserJsonStr) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userMap);
        notifyListeners();
      }

      // Then ping the server to verify the token is still valid
      final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/me');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final userJson = jsonDecode(response.body) as Map<String, dynamic>;
        await _secureStorage.saveUserJson(jsonEncode(userJson));
        _currentUser = UserModel.fromJson(userJson);
        notifyListeners();
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('[AUTH] Auto-login failed (unauthorized): ${response.statusCode}');
        await logout();
        return false;
      } else {
        // Server error (500 etc), but token is not explicitly rejected.
        // Fall back to local user if available.
        debugPrint('[AUTH] Auto-login warning: Server returned ${response.statusCode}');
        if (_currentUser != null) return true;
        return false;
      }
    } catch (e) {
      // Network error (offline). Fall back to local user.
      debugPrint('[AUTH] Auto-login network error: $e');
      if (_currentUser != null) {
        return true;
      }
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.clearAll();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  String? _decodeJwtRole(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      var normalized = base64Url.normalize(payload);
      final decodedBytes = base64Url.decode(normalized);
      final decodedString = utf8.decode(decodedBytes);
      final json = jsonDecode(decodedString);
      
      return json['role'] as String?;
    } catch (e) {
      debugPrint('[AUTH] Error decoding JWT: $e');
      return null;
    }
  }
}
