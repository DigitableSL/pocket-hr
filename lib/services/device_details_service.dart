import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceDetailsService {
  DeviceDetailsService();

  static const MethodChannel _channel =
      MethodChannel('asia.ceynet.pocket/security');

  final Battery _battery = Battery();
  final NetworkInfo _networkInfo = NetworkInfo();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Returns a map with battery level (0-100) and charging state string.
  Future<Map<String, dynamic>> getBatteryInfo() async {
    if (kIsWeb) return <String, dynamic>{};
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      return <String, dynamic>{'level': level, 'state': state.toString()};
    } catch (e) {
      debugPrint('[DeviceDetails] getBatteryInfo error: $e');
      return <String, dynamic>{};
    }
  }

  /// Returns the device IP address (wifi) or null if unavailable.
  Future<String?> getIpAddress() async {
    if (kIsWeb) return null;
    try {
      final ip = await _networkInfo.getWifiIP();
      return ip;
    } catch (e) {
      debugPrint('[DeviceDetails] getIpAddress error: $e');
      return null;
    }
  }

  /// Returns a map with platform-specific device information.
  Future<Map<String, dynamic>> getDeviceInfo() async {
    if (kIsWeb) return <String, dynamic>{};
    try {
      if (Platform.isAndroid) {
        final android = await _deviceInfo.androidInfo;
        String? secureAndroidId;
        try {
          final id = await _channel.invokeMethod<String>('getAndroidId');
          if (id != null && id.trim().isNotEmpty) {
            secureAndroidId = id.trim();
          }
        } catch (_) {}
        return <String, dynamic>{
          'platform': 'android',
          'model': android.model,
          'brand': android.brand,
          'androidId': secureAndroidId ?? android.id,
          'buildId': android.id,
          'device': android.device,
          'version': android.version.release,
        };
      } else if (Platform.isIOS) {
        final ios = await _deviceInfo.iosInfo;
        return <String, dynamic>{
          'platform': 'ios',
          'model': ios.utsname.machine,
          'systemVersion': ios.systemVersion,
          'identifierForVendor': ios.identifierForVendor,
        };
      } else {
        // Fallback for other platforms
        return <String, dynamic>{'platform': Platform.operatingSystem};
      }
    } catch (e) {
      debugPrint('[DeviceDetails] getDeviceInfo error: $e');
      return <String, dynamic>{};
    }
  }

  /// Convenience helper returning all collected info.
  Future<Map<String, dynamic>> collectAll() async {
    final bat = await getBatteryInfo();
    final ip = await getIpAddress();
    final dev = await getDeviceInfo();
    return {
      'battery': bat,
      'ip': ip,
      'device': dev,
    };
  }
}
