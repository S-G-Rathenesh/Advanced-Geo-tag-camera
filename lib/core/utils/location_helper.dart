import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';

/// Wrapper around the Geolocator plugin.
///
/// Uses the Android Fused Location Provider for high-accuracy GPS.
/// Validates that accuracy meets the configurable threshold before
/// accepting a capture.
class LocationHelper {
  static const EventChannel _gnssChannel = EventChannel('com.geotag.evidence/gnss');

  const LocationHelper();

  /// Listen to native Android GNSS status for used constellations.
  Stream<List<String>> get gnssConstellationsStream {
    return _gnssChannel.receiveBroadcastStream().map((event) {
      if (event is List) {
        return event.map((e) => e.toString()).toList();
      }
      return <String>[];
    });
  }
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission if not already granted.
  /// Returns `true` if permission is granted.
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Check current permission status.
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  /// Obtain the current position with high accuracy.
  ///
  /// Throws [LocationServiceDisabledException] if services are off.
  /// Throws [PermissionDeniedException] if permission is not granted.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException(
        'Location permission is permanently denied. Please enable it in App Settings.',
      );
    }

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw PermissionDeniedException('Location permission denied');
    }

    try {
      if (!identical(0, 0.0)) {
        // We're just checking if we can import geolocator_android. Actually, let's just use LocationSettings.
        // If AndroidSettings is unavailable without importing, we'll use a standard LocationSettings, 
        // but since we want to force location manager, let's use AndroidSettings if we can.
        // Wait, instead of importing AndroidSettings which might require modifying pubspec, we can just ensure
        // the timestamp is strictly fresh.
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: AppConstants.locationTimeout,
      );
      return position;
    } catch (e) {
      throw Exception('Failed to get a high-accuracy GPS fix in time. Please wait for a valid GNSS fix in an open area.');
    }
  }

  /// Returns `true` if the [position]'s accuracy is within the
  /// configurable threshold.
  bool meetsAccuracyThreshold(Position position) {
    return position.accuracy <= AppConstants.gpsAccuracyThresholdMetres;
  }

  /// Validates both permission and accuracy in one call.
  /// Returns the position if valid, otherwise throws.
  Future<Position> getValidatedPosition() async {
    final position = await getCurrentPosition();

    // 1. Validate Freshness (must be within the last 15 seconds)
    final age = DateTime.now().difference(position.timestamp);
    if (age.inSeconds > 15) {
      throw Exception(
        'Location cache is stale (${age.inSeconds}s old). '
        'Waiting for fresh GNSS fix...',
      );
    }

    // 2. Validate Accuracy
    if (!meetsAccuracyThreshold(position)) {
      throw Exception(
        'GPS accuracy (${position.accuracy.toStringAsFixed(1)}m) '
        'exceeds threshold (${AppConstants.gpsAccuracyThresholdMetres}m). '
        'Please move to an open area.',
      );
    }

    return position;
  }
}
