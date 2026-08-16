import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

void main() {
  test('End-to-End Secure Evidence Flow', () async {
    const baseUrl = 'http://127.0.0.1:8000';
    
    // 1. Generate Fake Image
    final mockImageBytes = Uint8List.fromList([1, 2, 3, 4, 5, 255, 128, 0]);
    final sha256Hash = sha256.convert(mockImageBytes).toString();
    
    // 2. Encrypt
    final key = enc.Key.fromSecureRandom(32);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    
    final encrypted = encrypter.encryptBytes(mockImageBytes, iv: iv);
    final ciphertextBase64 = encrypted.base64;
    final ivBase64 = iv.base64;
    
    // 3. Upload (Simulating SyncService)
    final captureId = const Uuid().v4();
    final url = Uri.parse('$baseUrl/api/evidence/upload');
    
    final request = http.MultipartRequest('POST', url)
      ..fields['capture_id'] = captureId
      ..fields['device_id'] = 'TEST-DEVICE'
      ..fields['sha256_hash'] = sha256Hash
      ..fields['payload_hash'] = sha256.convert(encrypted.bytes).toString()
      ..fields['latitude'] = '0.0'
      ..fields['longitude'] = '0.0'
      ..fields['gps_accuracy'] = '10.0'
      ..fields['capture_timestamp'] = DateTime.now().toIso8601String()
      ..fields['iv_base64'] = ivBase64;
      
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        encrypted.bytes,
        filename: '$captureId.enc',
      ),
    );
    
    final loginReq = await http.post(
      Uri.parse('$baseUrl/api/auth/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=demo_user&password=password123'
    );
    final token = jsonDecode(loginReq.body)['access_token'];
    
    request.headers['Authorization'] = 'Bearer $token';
    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    
    expect(response.statusCode, 200);
    final uploadData = jsonDecode(respStr);
    expect(uploadData['iv_base64'], ivBase64); // Validates IV preservation
    
    // 4. Officer Fetch
    final offLogin = await http.post(
      Uri.parse('$baseUrl/api/auth/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=demo_officer&password=password123'
    );
    final offToken = jsonDecode(offLogin.body)['access_token'];
    
    // Fetch all evidence
    final allEvReq = await http.get(
      Uri.parse('$baseUrl/api/evidence'),
      headers: {'Authorization': 'Bearer $offToken'}
    );
    final allEv = jsonDecode(allEvReq.body) as List;
    final found = allEv.firstWhere((e) => e['capture_id'] == captureId);
    expect(found, isNotNull);
    expect(found['iv_base64'], ivBase64);
    
    // 5. Decrypt
    final cloudUrl = found['image_url'];
    final cloudReq = await http.get(Uri.parse(cloudUrl));
    final cloudBytes = cloudReq.bodyBytes;
    
    final cloudCiphertext = String.fromCharCodes(cloudBytes).trim();
    final cloudIv = enc.IV(base64Decode(found['iv_base64']));
    final cloudEncrypted = enc.Encrypted.fromBase64(cloudCiphertext);
    
    final decrypted = encrypter.decryptBytes(cloudEncrypted, iv: cloudIv);
    final finalHash = sha256.convert(decrypted).toString();
    
    expect(finalHash, sha256Hash);
    print("E2E Test Passed!");
  });
}
