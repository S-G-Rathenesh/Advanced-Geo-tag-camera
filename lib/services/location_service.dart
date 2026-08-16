import 'package:geolocator/geolocator.dart';

import '../core/utils/location_helper.dart';

/// Location service providing GPS data for evidence captures.
///
/// Wraps [LocationHelper] with additional state management for
/// the UI to display location status and results.
class LocationService {
  final LocationHelper _locationHelper;

  LocationService({LocationHelper? locationHelper})
      : _locationHelper = locationHelper ?? const LocationHelper();

  Stream<List<String>> get gnssConstellationsStream => _locationHelper.gnssConstellationsStream;

  /// Check if location services are available and permitted.
  Future<LocationStatus> checkStatus() async {
    final serviceEnabled = await _locationHelper.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationStatus.serviceDisabled;
    }

    final permission = await _locationHelper.checkPermission();
    switch (permission) {
      case LocationPermission.denied:
        return LocationStatus.permissionDenied;
      case LocationPermission.deniedForever:
        return LocationStatus.permissionDeniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationStatus.ready;
      default:
        return LocationStatus.permissionDenied;
    }
  }

  /// Request location permission.
  Future<bool> requestPermission() async {
    return _locationHelper.requestPermission();
  }

  /// Get current position with validation.
  /// Throws if permission denied or accuracy below threshold.
  Future<Position> getValidatedPosition() async {
    return _locationHelper.getValidatedPosition();
  }

  /// Get current position without accuracy validation.
  Future<Position> getCurrentPosition() async {
    return _locationHelper.getCurrentPosition();
  }

  /// Check if a position meets the accuracy threshold.
  bool meetsAccuracyThreshold(Position position) {
    return _locationHelper.meetsAccuracyThreshold(position);
  }
}

/// Status of location services and permissions.
enum LocationStatus {
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}
