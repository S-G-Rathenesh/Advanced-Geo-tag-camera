import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/evidence_record.dart';
import '../models/sync_status.dart';

class ApiService {
  final _secureStorage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: AppConstants.jwtStorageKey);
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
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  Future<void> grantSupervisor(String userId) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/users/$userId/grant-supervisor');
    final response = await http.post(url, headers: await _getHeaders());

    if (response.statusCode != 200) {
      throw Exception('Failed to grant supervisor: ${response.statusCode}');
    }
  }

  Future<void> revokeSupervisor(String userId) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/users/$userId/revoke-supervisor');
    final response = await http.post(url, headers: await _getHeaders());

    if (response.statusCode != 200) {
      throw Exception('Failed to revoke supervisor: ${response.statusCode}');
    }
  }

  // --- Evidence API ---

  Future<List<EvidenceRecord>> getAllEvidence() async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/evidence');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _parseCloudEvidence(json)).toList();
    } else {
      throw Exception('Failed to load all evidence: ${response.statusCode}');
    }
  }

  Future<List<EvidenceRecord>> getMyEvidence() async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/evidence/my');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _parseCloudEvidence(json)).toList();
    } else {
      throw Exception('Failed to load my evidence: ${response.statusCode}');
    }
  }

  Future<List<EvidenceRecord>> getUserEvidence(String userId) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/users/$userId/evidence');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _parseCloudEvidence(json)).toList();
    } else {
      throw Exception('Failed to load user evidence: ${response.statusCode}');
    }
  }

  EvidenceRecord _parseCloudEvidence(Map<String, dynamic> json) {
    return EvidenceRecord(
      captureId: json['capture_id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      imagePath: json['image_url'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
      altitude: json['altitude'],
      accuracy: json['gps_accuracy'],
      timestamp: DateTime.parse(json['capture_timestamp']),
      sha256Hash: json['sha256_hash'],
      syncStatus: SyncStatus.synced,
      createdAt: DateTime.parse(json['capture_timestamp']),
      updatedAt: DateTime.parse(json['capture_timestamp']),
    );
  }
}
