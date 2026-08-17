import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/evidence_record.dart';

/// Service responsible for embedding the tactical GPS Map Camera watermark
/// overlay directly onto evidence photos upon download by an Officer.
class GeoTagImageStampService {
  static final Map<String, ui.Image> _tileCache = {};

  /// Stamps the provided image with the complete GPS Map Camera banner overlay,
  /// including mini map tile, red pin, address, coordinates, and timestamp.
  static Future<Uint8List> stampEvidenceImage(
    Uint8List rawBytes,
    EvidenceRecord record,
  ) async {
    // 1. Decode original image
    final codec = await ui.instantiateImageCodec(rawBytes);
    final frame = await codec.getNextFrame();
    final originalImage = frame.image;
    final imgWidth = originalImage.width.toDouble();
    final imgHeight = originalImage.height.toDouble();

    // 2. Fetch reverse geocode address if missing
    String? resolvedAddress = record.address;
    if (resolvedAddress == null || resolvedAddress.isEmpty) {
      resolvedAddress = await _reverseGeocode(record.latitude, record.longitude);
    }

    // 3. Fetch Map Tile
    final mapTile = await _fetchMapTile(record.latitude, record.longitude);

    // 4. Setup Canvas
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, Rect.fromLTWH(0, 0, imgWidth, imgHeight));

    // Draw original photographic evidence
    canvas.drawImage(originalImage, Offset.zero, Paint());

    // Calculate dynamic scaling based on image width (standard reference: 1080p)
    final baseScale = math.max(imgWidth / 1080.0, 0.65);
    final bannerHeight = 250.0 * baseScale;
    final padding = 16.0 * baseScale;
    final mapSize = bannerHeight - (padding * 2);

    // ── 5. DRAW BOTTOM OVERLAY BANNER ──────────────────────────────────────────
    final bannerRect = Rect.fromLTWH(0, imgHeight - bannerHeight, imgWidth, bannerHeight);
    final bannerPaint = Paint()..color = const Color(0xE6050B14);
    canvas.drawRect(bannerRect, bannerPaint);

    // Top accent border
    final topBorderPaint = Paint()
      ..color = const Color(0x3338BDF8)
      ..strokeWidth = 1.5 * baseScale;
    canvas.drawLine(
      Offset(0, imgHeight - bannerHeight),
      Offset(imgWidth, imgHeight - bannerHeight),
      topBorderPaint,
    );

    // ── 6. DRAW MINI MAP TILE & PIN (LEFT BOX) ─────────────────────────────────
    final mapRect = Rect.fromLTWH(
      padding,
      imgHeight - bannerHeight + padding,
      mapSize,
      mapSize,
    );
    final mapRRect = RRect.fromRectAndRadius(mapRect, Radius.circular(8 * baseScale));

    canvas.save();
    canvas.clipRRect(mapRRect);

    if (mapTile != null) {
      canvas.drawImageRect(
        mapTile,
        Rect.fromLTWH(0, 0, mapTile.width.toDouble(), mapTile.height.toDouble()),
        mapRect,
        Paint(),
      );
    } else {
      _drawTacticalMapFallback(canvas, mapRect, record.latitude, record.longitude, baseScale);
    }

    // Draw Red Map Pin Marker at center of map
    final pinCenterX = mapRect.center.dx;
    final pinCenterY = mapRect.center.dy - (4 * baseScale);
    _drawMapPin(canvas, pinCenterX, pinCenterY, baseScale);

    // Draw "Google" logo watermark at bottom-left of map box
    _drawText(
      canvas,
      'Google',
      x: mapRect.left + (6 * baseScale),
      y: mapRect.bottom - (16 * baseScale),
      maxWidth: mapSize - (12 * baseScale),
      fontSize: 11.5 * baseScale,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    canvas.restore();

    // Map border outline
    final mapBorderPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * baseScale;
    canvas.drawRRect(mapRRect, mapBorderPaint);

    // ── 7. DRAW TOP-RIGHT "GPS Map Camera" BADGE ─────────────────────────────
    final badgeHeight = 24.0 * baseScale;
    final badgeWidth = 135.0 * baseScale;
    final badgeRect = Rect.fromLTWH(
      imgWidth - padding - badgeWidth,
      imgHeight - bannerHeight + (padding * 0.7),
      badgeWidth,
      badgeHeight,
    );
    _drawBadge(canvas, badgeRect, baseScale);

    // ── 8. DRAW TEXT DATA (RIGHT SIDE) ────────────────────────────────────────
    final textLeft = mapRect.right + (14 * baseScale);
    final textRight = imgWidth - padding;
    final textWidth = textRight - textLeft;
    var currentY = imgHeight - bannerHeight + (padding * 0.85);

    // Line 1: Short Locality Title (e.g. Thalavapalayam, Tamil Nadu, India)
    final locationTitle = _extractShortLocation(resolvedAddress, record.latitude, record.longitude);
    _drawText(
      canvas,
      locationTitle,
      x: textLeft,
      y: currentY,
      maxWidth: textWidth - badgeWidth - (8 * baseScale),
      fontSize: 18.0 * baseScale,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      maxLines: 1,
    );
    currentY += 24.0 * baseScale;

    // Line 2: Full Address / Plus Code
    final fullAddress = resolvedAddress ?? locationTitle;
    _drawText(
      canvas,
      fullAddress,
      x: textLeft,
      y: currentY,
      maxWidth: textWidth,
      fontSize: 12.5 * baseScale,
      fontWeight: FontWeight.w400,
      color: const Color(0xFFE2E8F0),
      maxLines: 2,
    );
    currentY += 34.0 * baseScale;

    // Line 3: Latitude & Longitude Coordinates
    final latStr = record.latitude.toStringAsFixed(6);
    final lonStr = record.longitude.toStringAsFixed(6);
    final coordText = 'Lat $latStr° Long $lonStr°';
    _drawText(
      canvas,
      coordText,
      x: textLeft,
      y: currentY,
      maxWidth: textWidth,
      fontSize: 13.5 * baseScale,
      fontWeight: FontWeight.w500,
      color: Colors.white,
      maxLines: 1,
    );
    currentY += 22.0 * baseScale;

    // Line 4: Timestamp with Timezone Offset (e.g. 14/08/2026 02:17 PM GMT +05:30)
    final localTime = record.timestamp.toLocal();
    final datePart = DateFormat('dd/MM/yyyy').format(localTime);
    final timePart = DateFormat('hh:mm a').format(localTime);
    final offsetPart = 'GMT ${_formatTimeZoneOffset(localTime.timeZoneOffset)}';
    final timestampText = '$datePart  $timePart $offsetPart';
    _drawText(
      canvas,
      timestampText,
      x: textLeft,
      y: currentY,
      maxWidth: textWidth,
      fontSize: 13.5 * baseScale,
      fontWeight: FontWeight.w500,
      color: Colors.white,
      maxLines: 1,
    );

    // ── 9. EXPORT COMPOSITED IMAGE ───────────────────────────────────────────
    final picture = recorder.endRecording();
    final compositedImage = await picture.toImage(imgWidth.toInt(), imgHeight.toInt());
    final byteData = await compositedImage.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  // ── HELPER DRAWING METHODS ──────────────────────────────────────────────────

  static void _drawText(
    ui.Canvas canvas,
    String text, {
    required double x,
    required double y,
    required double maxWidth,
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
    int maxLines = 1,
  }) {
    final pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        fontWeight: fontWeight,
        maxLines: maxLines,
        ellipsis: '...',
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ))
      ..addText(text);

    final paragraph = pb.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));

    canvas.drawParagraph(paragraph, ui.Offset(x, y));
  }

  static void _drawMapPin(ui.Canvas canvas, double cx, double cy, double scale) {
    final pinRadius = 8.5 * scale;
    final pinPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    // Drop shadow
    canvas.drawCircle(
      Offset(cx, cy + (13 * scale)),
      3.5 * scale,
      Paint()..color = const Color(0x88000000),
    );

    // Teardrop pin body
    final path = Path();
    path.moveTo(cx, cy + (13 * scale));
    path.quadraticBezierTo(cx - (8 * scale), cy + (4 * scale), cx - (8 * scale), cy - (2 * scale));
    path.arcToPoint(
      Offset(cx + (8 * scale), cy - (2 * scale)),
      radius: Radius.circular(pinRadius),
      clockwise: true,
    );
    path.quadraticBezierTo(cx + (8 * scale), cy + (4 * scale), cx, cy + (13 * scale));
    path.close();

    canvas.drawPath(path, pinPaint);

    // Inner white dot
    canvas.drawCircle(
      Offset(cx, cy - (2 * scale)),
      3.2 * scale,
      Paint()..color = Colors.white,
    );
  }

  static void _drawBadge(ui.Canvas canvas, Rect badgeRect, double scale) {
    final badgeRRect = RRect.fromRectAndRadius(badgeRect, Radius.circular(4 * scale));
    canvas.drawRRect(badgeRRect, Paint()..color = const Color(0xCC111827));
    canvas.drawRRect(
      badgeRRect,
      Paint()
        ..color = const Color(0x4438BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale,
    );

    final iconSize = 14.0 * scale;
    final iconRect = Rect.fromLTWH(
      badgeRect.left + (5 * scale),
      badgeRect.top + (badgeRect.height - iconSize) / 2,
      iconSize,
      iconSize,
    );

    // Cyan camera icon box
    canvas.drawRRect(
      RRect.fromRectAndRadius(iconRect, Radius.circular(2.5 * scale)),
      Paint()..color = const Color(0xFF38BDF8),
    );

    // Dark lens circle
    canvas.drawCircle(
      iconRect.center,
      2.5 * scale,
      Paint()..color = const Color(0xFF0F172A),
    );

    // Badge text
    _drawText(
      canvas,
      'GPS Map Camera',
      x: iconRect.right + (5 * scale),
      y: badgeRect.top + (4.5 * scale),
      maxWidth: badgeRect.width - iconSize - (10 * scale),
      fontSize: 10.0 * scale,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }

  static void _drawTacticalMapFallback(
    ui.Canvas canvas,
    Rect mapRect,
    double lat,
    double lon,
    double scale,
  ) {
    // 1. Satellite dark terrain base
    canvas.drawRect(mapRect, Paint()..color = const Color(0xFF1E293B));

    // 2. Terrain patches
    canvas.drawOval(
      Rect.fromLTWH(
        mapRect.left + (mapRect.width * 0.1),
        mapRect.top + (mapRect.height * 0.2),
        mapRect.width * 0.55,
        mapRect.height * 0.45,
      ),
      Paint()..color = const Color(0xFF334155),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        mapRect.left + (mapRect.width * 0.45),
        mapRect.top + (mapRect.height * 0.45),
        mapRect.width * 0.5,
        mapRect.height * 0.45,
      ),
      Paint()..color = const Color(0xFF263342),
    );

    // 3. Grid lines
    final gridPaint = Paint()
      ..color = const Color(0x3338BDF8)
      ..strokeWidth = 1.0 * scale;

    for (double x = mapRect.left + (20 * scale); x < mapRect.right; x += 25 * scale) {
      canvas.drawLine(Offset(x, mapRect.top), Offset(x, mapRect.bottom), gridPaint);
    }
    for (double y = mapRect.top + (20 * scale); y < mapRect.bottom; y += 25 * scale) {
      canvas.drawLine(Offset(mapRect.left, y), Offset(mapRect.right, y), gridPaint);
    }

    // 4. Radar concentric rings
    final radarPaint = Paint()
      ..color = const Color(0x4438BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawCircle(mapRect.center, 18 * scale, radarPaint);
    canvas.drawCircle(mapRect.center, 38 * scale, radarPaint);
  }

  static Future<ui.Image?> _fetchMapTile(double lat, double lon) async {
    try {
      const zoom = 16;
      final x = ((lon + 180.0) / 360.0 * math.pow(2.0, zoom)).floor();
      final latRad = lat * math.pi / 180.0;
      final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * math.pow(2.0, zoom)).floor();

      final cacheKey = '$zoom/$x/$y';
      if (_tileCache.containsKey(cacheKey)) {
        return _tileCache[cacheKey];
      }

      final url = Uri.parse('https://tile.openstreetmap.org/$zoom/$x/$y.png');
      final response = await http.get(
        url,
        headers: {'User-Agent': 'Capturovert-GeoEvidence-App/1.0 (Mobile Secure Camera)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final codec = await ui.instantiateImageCodec(response.bodyBytes);
        final frame = await codec.getNextFrame();
        _tileCache[cacheKey] = frame.image;
        return frame.image;
      }
    } catch (e) {
      debugPrint('Map tile fetch skipped or offline: $e');
    }
    return null;
  }

  static Future<String?> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon');
      final response = await http.get(
        url,
        headers: {'User-Agent': 'Capturovert-GeoEvidence-App/1.0'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] as String?;
      }
    } catch (_) {}
    return null;
  }

  static String _extractShortLocation(String? address, double lat, double lon) {
    if (address == null || address.trim().isEmpty) {
      return 'Lat ${lat.toStringAsFixed(4)}°, Long ${lon.toStringAsFixed(4)}°';
    }

    final parts = address.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'Lat ${lat.toStringAsFixed(4)}°, Long ${lon.toStringAsFixed(4)}°';
    }

    final meaningfulParts = parts.where((p) => !p.contains('+') && !RegExp(r'^\d{5,6}$').hasMatch(p)).toList();

    if (meaningfulParts.length >= 3) {
      final locality = meaningfulParts.first;
      final country = meaningfulParts.last;
      final state = meaningfulParts[meaningfulParts.length - 2].replaceAll(RegExp(r'\d+'), '').trim();
      return '$locality, $state, $country';
    } else if (meaningfulParts.isNotEmpty) {
      return meaningfulParts.join(', ');
    }

    return parts.take(3).join(', ');
  }

  static String _formatTimeZoneOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }
}
