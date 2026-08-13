import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';

/// Wrapper around the Geolocator plugin.
///
/// Uses the Android Fused Location Provider for high-accuracy GPS.
/// Validates that accuracy meets the configurable threshold before
/// accepting a capture.
class LocationHelper {
  const LocationHelper();

  /// Check whether location services are enabled.
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

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw PermissionDeniedException('Location permission denied');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: AppConstants.locationTimeout,
    );
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
