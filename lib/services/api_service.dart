import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/security/secure_storage_service.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/evidence_record.dart';
import '../models/sync_status.dart';

class ApiService {
  final _secureStorage = SecureStorageService();

  Future<String?> _getToken() async {
    return await _secureStorage.getToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Users API ---

  Future<List<UserModel>> getUsers() async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/users');
    debugPrint('[API] GET /users');
    final response = await http.get(url, headers: await _getHeaders());
    debugPrint('[API] GET /users -> ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  Future<void> grantSupervisor(String userId) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/users/$userId/grant-supervisor');
    debugPrint('[API] POST /users/$userId/grant-supervisor');
    final response = await http.post(url, headers: await _getHeaders());
    debugPrint('[API] POST grant-supervisor -> ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Failed to grant supervisor: ${response.statusCode}');
    }
  }

  Future<void> revokeSupervisor(String userId) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/users/$userId/revoke-supervisor');
    debugPrint('[API] POST /users/$userId/revoke-supervisor');
    final response = await http.post(url, headers: await _getHeaders());
    debugPrint('[API] POST revoke-supervisor -> ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Failed to revoke supervisor: ${response.statusCode}');
    }
  }

  // --- Evidence API ---

  Future<List<EvidenceRecord>> getAllEvidence() async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/evidence');
    debugPrint('[API] GET /evidence');
    final response = await http.get(url, headers: await _getHeaders());
    debugPrint('[API] GET /evidence -> ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _parseCloudEvidence(json)).toList();
    } else {
      throw Exception('Failed to load all evidence: ${response.statusCode}');
    }
  }

  Future<List<EvidenceRecord>> getMyEvidence() async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/evidence/my');
    debugPrint('[API] GET /evidence/my');
    final response = await http.get(url, headers: await _getHeaders());
    debugPrint('[API] GET /evidence/my -> ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _parseCloudEvidence(json)).toList();
    } else {
      throw Exception('Failed to load my evidence: ${response.statusCode}');
    }
  }

  Future<List<EvidenceRecord>> getUserEvidence(String userId) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/users/$userId/evidence');
    debugPrint('[API] GET /users/$userId/evidence');
    final response = await http.get(url, headers: await _getHeaders());
    debugPrint('[API] GET /users/$userId/evidence -> ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _parseCloudEvidence(json)).toList();
    } else {
      throw Exception('Failed to load user evidence: ${response.statusCode}');
    }
  }

  Future<EvidenceRecord> getEvidence(String captureId) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/evidence/$captureId');
    debugPrint('[API] GET /evidence/$captureId');
    final response = await http.get(url, headers: await _getHeaders());
    debugPrint('[API] GET /evidence/$captureId -> ${response.statusCode}');

    if (response.statusCode == 200) {
      return _parseCloudEvidence(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get evidence: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> verifyEvidence(String captureId) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/evidence/$captureId/verify');
    debugPrint('[API] POST /evidence/$captureId/verify');
    final response = await http.post(url, headers: await _getHeaders());
    debugPrint('[API] POST /evidence/$captureId/verify -> ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to verify evidence: ${response.statusCode}');
    }
  }

  EvidenceRecord _parseCloudEvidence(Map<String, dynamic> json) {
    List<String> parsedConstellations = [];
    if (json['gnss_constellations'] != null) {
      try {
        final decoded = jsonDecode(json['gnss_constellations'] as String);
        if (decoded is List) {
          parsedConstellations = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // Fallback if not valid JSON
      }
    }

    print('\n[api_response]');
    print('capture_id=${json['capture_id']}');
    print('owner_id=${json['user_id']}');
    print('latitude=${json['latitude']}');
    print('longitude=${json['longitude']}');
    print('accuracy=${json['gps_accuracy']}');
    print('capture_timestamp=${json['capture_timestamp']}');
    print('gnss_constellations=${json['gnss_constellations']}');
    print('iv_present=${json['iv_base64'] != null}');
    print('image_url=${json['image_url']}');
    print('------\n');

    return EvidenceRecord(
      captureId: json['capture_id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      imagePath: json['image_url'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: json['altitude'] != null ? (json['altitude'] as num).toDouble() : null,
      accuracy: (json['gps_accuracy'] as num).toDouble(),
      address: json['address'],
      timestamp: DateTime.parse(json['capture_timestamp']),
      sha256Hash: json['sha256_hash'],
      syncStatus: SyncStatus.synced,
      ivBase64: json['iv_base64'],
      gnssConstellations: parsedConstellations,
      createdAt: DateTime.parse(json['upload_timestamp'] ?? json['capture_timestamp']),
      updatedAt: DateTime.parse(json['upload_timestamp'] ?? json['capture_timestamp']),
    );
  }
}
