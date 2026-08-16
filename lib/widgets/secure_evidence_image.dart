import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../core/security/encryption_service.dart';
import '../core/security/hash_service.dart';
import '../models/evidence_record.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// A secure image widget that downloads, decrypts, and verifies evidence payloads.
/// It uses a global static cache to avoid re-downloading and re-decrypting images
/// when scrolling in list views.
class SecureEvidenceImage extends StatefulWidget {
  final EvidenceRecord record;
  final BoxFit fit;
  final Widget? errorPlaceholder;
  final ValueChanged<Uint8List>? onVerified;
  final ValueChanged<String>? onError;

  const SecureEvidenceImage({
    super.key,
    required this.record,
    this.fit = BoxFit.cover,
    this.errorPlaceholder,
    this.onVerified,
    this.onError,
  });

  @override
  State<SecureEvidenceImage> createState() => _SecureEvidenceImageState();
}

class _SecureEvidenceImageState extends State<SecureEvidenceImage> {
  // Simple in-memory cache to prevent re-decrypting images repeatedly during list scroll
  static final Map<String, Uint8List> _decryptedCache = {};
  static final Map<String, String> _errorCache = {};

  bool _isVerifying = false;
  Uint8List? _decryptedBytes;
  String? _integrityError;

  @override
  void initState() {
    super.initState();
    _triggerAuditAndVerify();
  }

  @override
  void didUpdateWidget(covariant SecureEvidenceImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.captureId != widget.record.captureId ||
        oldWidget.record.ivBase64 != widget.record.ivBase64) {
      _triggerAuditAndVerify();
    }
  }

  Future<void> _triggerAuditAndVerify() async {
    final authService = context.read<AuthService>();
    final isOfficer = authService.currentUser?.role == UserRole.officer;

    if (!isOfficer) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _integrityError = 'Image access restricted to Officer role.';
        });
      }
      return;
    }

    final cacheKey = widget.record.captureId;

    if (_decryptedCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _decryptedBytes = _decryptedCache[cacheKey];
          _isVerifying = false;
          _integrityError = null;
        });
      }
      return;
    }

    if (_errorCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _integrityError = _errorCache[cacheKey];
        });
      }
      return;
    }

    if (mounted) setState(() => _isVerifying = true);

    try {
      Uint8List encryptedBytes;
      if (widget.record.imagePath.startsWith('http')) {
        // Fetch encrypted payload from cloud (Cloudinary raw resource)
        final response = await http.get(Uri.parse(widget.record.imagePath));
        if (response.statusCode != 200) {
          throw Exception('Failed to download encrypted payload');
        }
        encryptedBytes = response.bodyBytes;
      } else if (widget.record.encryptedPath != null &&
          await File(widget.record.encryptedPath!).exists()) {
        // Local encrypted file
        encryptedBytes = await File(widget.record.encryptedPath!).readAsBytes();
      } else {
        throw Exception('Evidence payload not available');
      }

      if (widget.record.ivBase64 != null && widget.record.ivBase64!.isNotEmpty) {
        final encryptionService = EncryptionService();
        final hashService = const HashService();

        // The .enc file was written as a base64 string via writeAsString(),
        // so the raw bytes from Cloudinary are the UTF-8 bytes of a base64 string.
        final ciphertextBase64 = String.fromCharCodes(encryptedBytes).trim();

        final decrypted = await encryptionService.decryptBytes(
          ciphertextBase64: ciphertextBase64,
          ivBase64: widget.record.ivBase64!,
        );

        // Recalculate SHA-256 on decrypted (original) image bytes
        final calculatedHash = hashService.generateSha256(decrypted);

        if (calculatedHash == widget.record.sha256Hash) {
          _decryptedCache[cacheKey] = decrypted;
          if (mounted) {
            setState(() {
              _decryptedBytes = decrypted;
              _isVerifying = false;
              _integrityError = null;
            });
            widget.onVerified?.call(decrypted);
          }
        } else {
          _errorCache[cacheKey] = 'Integrity Verification Failed: Hash mismatch.';
          if (mounted) {
            setState(() {
              _isVerifying = false;
              _integrityError = _errorCache[cacheKey];
            });
            widget.onError?.call(_errorCache[cacheKey]!);
          }
        }
      } else {
        _errorCache[cacheKey] = 'Image unavailable — this evidence was created before secure IV storage was enabled. Re-sync from the original device.';
        if (mounted) {
          setState(() {
            _isVerifying = false;
            _integrityError = _errorCache[cacheKey];
          });
          widget.onError?.call(_errorCache[cacheKey]!);
        }
      }
    } catch (e) {
      _errorCache[cacheKey] = 'Decryption failed: \${e.toString()}';
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _integrityError = _errorCache[cacheKey];
        });
        widget.onError?.call(_errorCache[cacheKey]!);
      }
    }
  }

  Widget _buildFallbackImage() {
    if (widget.errorPlaceholder != null) {
      return widget.errorPlaceholder!;
    }

    return Container(
      color: const Color(0xFF0F1E36),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  color: Color(0xFF64748B), size: 32),
              const SizedBox(height: 8),
              Text(
                _integrityError ?? 'Encrypted Evidence Payload',
                style: GoogleFonts.inter(
                    color: const Color(0xFF64748B), fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerifying) {
      return Container(
        color: const Color(0xFF0F1E36),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Color(0xFF38BDF8), strokeWidth: 2),
              ),
              const SizedBox(height: 12),
              Text(
                'Decrypting & Verifying...',
                style: GoogleFonts.inter(
                    color: const Color(0xFF38BDF8), fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_decryptedBytes != null) {
      return Image.memory(
        _decryptedBytes!,
        fit: widget.fit,
        gaplessPlayback: true,
      );
    }

    return _buildFallbackImage();
  }
}