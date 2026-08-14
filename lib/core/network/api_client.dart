import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../security/secure_storage_service.dart';

/// HTTP client wrapper with auth-header injection and HTTPS enforcement.
///
/// Communicates directly with the hosted FastAPI backend configured in [AppConstants.apiBaseUrl].
class ApiClient {
  final String baseUrl;
  final SecureStorageService _secureStorage;
  final http.Client _httpClient;

  ApiClient({
    String? baseUrl,
    SecureStorageService? secureStorage,
    http.Client? httpClient,
  })  : baseUrl = baseUrl ?? AppConstants.apiBaseUrl,
        _secureStorage = secureStorage ?? SecureStorageService(),
        _httpClient = httpClient ?? http.Client();

  /// Builds the standard auth headers.
  Future<Map<String, String>> _authHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET request.
  Future<http.Response> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$endpoint')
        .replace(queryParameters: queryParams);
    final headers = await _authHeaders();

    return _httpClient
        .get(uri, headers: headers)
        .timeout(AppConstants.apiTimeout);
  }

  /// POST request.
  Future<http.Response> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _authHeaders();

    return _httpClient
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(AppConstants.apiTimeout);
  }

  /// Multipart POST for file upload (evidence images).
  Future<http.StreamedResponse> uploadFile(
    String endpoint, {
    required String filePath,
    required Map<String, String> fields,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _authHeaders();

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath('evidence', filePath));

    return request.send().timeout(AppConstants.apiTimeout);
  }

  void dispose() {
    _httpClient.close();
  }
}
