import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/evidence_record.dart';

/// High-fidelity service that renders a clean, large, high-contrast GPS Map Camera
/// watermark banner overlay onto evidence photos when downloaded by an Officer.
class GeoTagImageStampService {
  static final Map<String, ui.Image> _tileCache = {};

  /// Stamps the image with an enlarged, ultra-neat GPS Map Camera watermark banner.
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

    // 3. Fetch Satellite / Map Tile
    final mapTile = await _fetchMapTile(record.latitude, record.longitude);

    // 4. Setup Canvas
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, Rect.fromLTWH(0, 0, imgWidth, imgHeight));

    // Draw original photographic evidence
    canvas.drawImage(originalImage, Offset.zero, Paint());

    // Proportional scaling factor (optimized for large, sharp, readable text on all resolutions)
    final baseScale = math.max(imgWidth / 960.0, 1.0);
    final bannerHeight = 310.0 * baseScale;
    final padding = 20.0 * baseScale;
    final mapSize = bannerHeight - (padding * 2);

    // ── 5. DRAW SOLID DARK BANNER WITH SUBTLE TOP BORDER ───────────────────────
    final bannerRect = Rect.fromLTWH(0, imgHeight - bannerHeight, imgWidth, bannerHeight);
    final bannerPaint = Paint()..color = const Color(0xF2070D18);
    canvas.drawRect(bannerRect, bannerPaint);

    // Glowing cyan/blue top divider border
    final topBorderPaint = Paint()
      ..color = const Color(0x6638BDF8)
      ..strokeWidth = 2.0 * baseScale;
    canvas.drawLine(
      Offset(0, imgHeight - bannerHeight),
      Offset(imgWidth, imgHeight - bannerHeight),
      topBorderPaint,
    );

    // ── 6. DRAW MINI SATELLITE / MAP TILE (LEFT BOX) ───────────────────────────
    final mapRect = Rect.fromLTWH(
      padding,
      imgHeight - bannerHeight + padding,
      mapSize,
      mapSize,
    );
    final mapRRect = RRect.fromRectAndRadius(mapRect, Radius.circular(12 * baseScale));

    canvas.save();
    canvas.clipRRect(mapRRect);

    if (mapTile != null) {
      canvas.drawImageRect(
        mapTile,
        Rect.fromLTWH(0, 0, mapTile.width.toDouble(), mapTile.height.toDouble()),
        mapRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      _drawTacticalMapFallback(canvas, mapRect, record.latitude, record.longitude, baseScale);
    }

    // Draw 3D Red Location Pin Marker at center of map
    final pinCenterX = mapRect.center.dx;
    final pinCenterY = mapRect.center.dy - (4 * baseScale);
    _drawMapPin(canvas, pinCenterX, pinCenterY, baseScale);

    // Draw "Google" logo watermark at bottom-left of map box
    _drawGoogleWatermark(canvas, mapRect.left + (8 * baseScale), mapRect.bottom - (20 * baseScale), baseScale);

    canvas.restore();

    // Map rounded border outline
    final mapBorderPaint = Paint()
      ..color = const Color(0x88FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * baseScale;
    canvas.drawRRect(mapRRect, mapBorderPaint);

    // ── 7. DRAW TOP-RIGHT "GPS Map Camera" BADGE ─────────────────────────────
    final badgeHeight = 28.0 * baseScale;
    final badgeWidth = 155.0 * baseScale;
    final badgeRect = Rect.fromLTWH(
      imgWidth - padding - badgeWidth,
      imgHeight - bannerHeight + (padding * 0.75),
      badgeWidth,
      badgeHeight,
    );
    _drawBadge(canvas, badgeRect, baseScale);

    // ── 8. DRAW STRUCTURED TEXT DATA (RIGHT SIDE) ─────────────────────────────
    final textLeft = mapRect.right + (20 * baseScale);
    final textRight = imgWidth - padding;
    final textWidth = textRight - textLeft;
    var currentY = imgHeight - bannerHeight + (padding * 0.85);

    // Line 1: Bold Large Locality Title (e.g. Thalavapalayam, Tamil Nadu, India)
    final locationTitle = _extractShortLocation(resolvedAddress, record.latitude, record.longitude);
    _drawText(
      canvas,
      locationTitle,
      x: textLeft,
      y: currentY,
      maxWidth: textWidth - badgeWidth - (10 * baseScale),
      fontSize: 22.0 * baseScale,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      maxLines: 1,
    );
    currentY += 32.0 * baseScale;

    // Line 2: Detailed Full Street Address / Plus Code
    final fullAddress = resolvedAddress ?? locationTitle;
    _drawText(
      canvas,
      fullAddress,
      x: textLeft,
      y: currentY,
      maxWidth: textWidth,
      fontSize: 14.5 * baseScale,
      fontWeight: FontWeight.w400,
      color: const Color(0xFFF1F5F9),
      maxLines: 2,
    );
    currentY += 40.0 * baseScale;

    // Line 3: High Precision Coordinates (Lat ... Long ...)
    final latStr = record.latitude.toStringAsFixed(6);
    final lonStr = record.longitude.toStringAsFixed(6);
    final coordText = 'Lat $latStr° Long $lonStr°';
    _drawText(
      canvas,
      coordText,
      x: textLeft,
      y: currentY,
      maxWidth: textWidth,
      fontSize: 16.0 * baseScale,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      maxLines: 1,
    );
    currentY += 26.0 * baseScale;

    // Line 4: Formatted Date, Time & GMT Offset (e.g. 14/08/2026 02:17 PM GMT +05:30)
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
      fontSize: 16.0 * baseScale,
      fontWeight: FontWeight.w600,
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
        height: 1.25,
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

  static void _drawGoogleWatermark(ui.Canvas canvas, double x, double y, double scale) {
    // Subtle shadow for legibility over any map tile
    _drawText(
      canvas,
      'Google',
      x: x + (1 * scale),
      y: y + (1 * scale),
      maxWidth: 100 * scale,
      fontSize: 13.0 * scale,
      fontWeight: FontWeight.bold,
      color: const Color(0xAA000000),
    );
    _drawText(
      canvas,
      'Google',
      x: x,
      y: y,
      maxWidth: 100 * scale,
      fontSize: 13.0 * scale,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }

  static void _drawMapPin(ui.Canvas canvas, double cx, double cy, double scale) {
    final pinRadius = 10.0 * scale;
    final pinPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    // Drop shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + (15.5 * scale)),
        width: 10 * scale,
        height: 5 * scale,
      ),
      Paint()..color = const Color(0x99000000),
    );

    // Teardrop pin body
    final path = Path();
    path.moveTo(cx, cy + (15.5 * scale));
    path.quadraticBezierTo(cx - (9.5 * scale), cy + (5 * scale), cx - (9.5 * scale), cy - (2 * scale));
    path.arcToPoint(
      Offset(cx + (9.5 * scale), cy - (2 * scale)),
      radius: Radius.circular(pinRadius),
      clockwise: true,
    );
    path.quadraticBezierTo(cx + (9.5 * scale), cy + (5 * scale), cx, cy + (15.5 * scale));
    path.close();

    canvas.drawPath(path, pinPaint);

    // Inner white dot
    canvas.drawCircle(
      Offset(cx, cy - (2 * scale)),
      3.8 * scale,
      Paint()..color = Colors.white,
    );
  }

  static void _drawBadge(ui.Canvas canvas, Rect badgeRect, double scale) {
    final badgeRRect = RRect.fromRectAndRadius(badgeRect, Radius.circular(6 * scale));
    canvas.drawRRect(badgeRRect, Paint()..color = const Color(0xE60F172A));
    canvas.drawRRect(
      badgeRRect,
      Paint()
        ..color = const Color(0x6638BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale,
    );

    final iconSize = 16.0 * scale;
    final iconRect = Rect.fromLTWH(
      badgeRect.left + (6 * scale),
      badgeRect.top + (badgeRect.height - iconSize) / 2,
      iconSize,
      iconSize,
    );

    // Cyan camera icon box
    canvas.drawRRect(
      RRect.fromRectAndRadius(iconRect, Radius.circular(3.0 * scale)),
      Paint()..color = const Color(0xFF38BDF8),
    );

    // Dark lens circle
    canvas.drawCircle(
      iconRect.center,
      3.0 * scale,
      Paint()..color = const Color(0xFF0F172A),
    );

    // Badge text
    _drawText(
      canvas,
      'GPS Map Camera',
      x: iconRect.right + (6 * scale),
      y: badgeRect.top + (5.0 * scale),
      maxWidth: badgeRect.width - iconSize - (12 * scale),
      fontSize: 11.5 * scale,
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
    // Satellite dark terrain base
    canvas.drawRect(mapRect, Paint()..color = const Color(0xFF1E293B));

    // Terrain patches
    canvas.drawOval(
      Rect.fromLTWH(
        mapRect.left + (mapRect.width * 0.1),
        mapRect.top + (mapRect.height * 0.2),
        mapRect.width * 0.6,
        mapRect.height * 0.5,
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

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0x3338BDF8)
      ..strokeWidth = 1.0 * scale;

    for (double x = mapRect.left + (20 * scale); x < mapRect.right; x += 25 * scale) {
      canvas.drawLine(Offset(x, mapRect.top), Offset(x, mapRect.bottom), gridPaint);
    }
    for (double y = mapRect.top + (20 * scale); y < mapRect.bottom; y += 25 * scale) {
      canvas.drawLine(Offset(mapRect.left, y), Offset(mapRect.right, y), gridPaint);
    }

    // Radar concentric rings
    final radarPaint = Paint()
      ..color = const Color(0x4438BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawCircle(mapRect.center, 22 * scale, radarPaint);
    canvas.drawCircle(mapRect.center, 44 * scale, radarPaint);
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

      // 1. Primary: Satellite Imagery (Esri World Imagery)
      try {
        final satelliteUrl = Uri.parse('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$zoom/$y/$x');
        final satResponse = await http.get(satelliteUrl).timeout(const Duration(seconds: 3));
        if (satResponse.statusCode == 200 && satResponse.bodyBytes.isNotEmpty) {
          final codec = await ui.instantiateImageCodec(satResponse.bodyBytes);
          final frame = await codec.getNextFrame();
          _tileCache[cacheKey] = frame.image;
          return frame.image;
        }
      } catch (_) {}

      // 2. Secondary Fallback: OpenStreetMap Tile
      final osmUrl = Uri.parse('https://tile.openstreetmap.org/$zoom/$x/$y.png');
      final osmResponse = await http.get(
        osmUrl,
        headers: {'User-Agent': 'Capturovert-GeoEvidence-App/1.0 (Mobile Secure Camera)'},
      ).timeout(const Duration(seconds: 3));

      if (osmResponse.statusCode == 200 && osmResponse.bodyBytes.isNotEmpty) {
        final codec = await ui.instantiateImageCodec(osmResponse.bodyBytes);
        final frame = await codec.getNextFrame();
        _tileCache[cacheKey] = frame.image;
        return frame.image;
      }
    } catch (e) {
      debugPrint('Map tile fetch fallback to tactical radar: $e');
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
