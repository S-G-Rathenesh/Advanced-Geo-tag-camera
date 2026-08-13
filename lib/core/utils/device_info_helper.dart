import 'package:device_info_plus/device_info_plus.dart';

/// Collects device identification information for evidence metadata.
///
/// The device ID is a combination of brand, model, and Android ID
/// to uniquely identify the capture device without requiring
/// additional permissions.
class DeviceInfoHelper {
  final DeviceInfoPlugin _deviceInfo;

  DeviceInfoHelper({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// Returns a map of relevant device metadata.
  Future<Map<String, String>> getDeviceInfo() async {
    final androidInfo = await _deviceInfo.androidInfo;

    return {
      'deviceId': androidInfo.id,
      'brand': androidInfo.brand,
      'model': androidInfo.model,
      'androidVersion': androidInfo.version.release,
      'sdkInt': androidInfo.version.sdkInt.toString(),
      'manufacturer': androidInfo.manufacturer,
    };
  }

  /// Returns a unique device identifier string.
  Future<String> getDeviceId() async {
    final androidInfo = await _deviceInfo.androidInfo;
    return '${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}';
  }
}
