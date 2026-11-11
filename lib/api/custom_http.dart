import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as origin_http;
import 'package:cn_pocket_hr/helpers/time_validator.dart';
import 'package:cn_pocket_hr/helpers/session_validator.dart';
import 'package:cn_pocket_hr/services/device_details_service.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:cn_pocket_hr/helpers/app_update_helper.dart';

export 'package:http/http.dart' show Response, Client;

Map<String, String>? _cachedDeviceHeaders;
DateTime? _lastCacheTime;
String? _cachedAppVersion;

Future<String> _getAppVersion() async {
  if (_cachedAppVersion != null && _cachedAppVersion!.isNotEmpty) {
    return _cachedAppVersion!;
  }
  try {
    final info = await PackageInfo.fromPlatform();
    final version = info.version;
    final buildNumber = info.buildNumber;
    if (buildNumber.isNotEmpty) {
      _cachedAppVersion = '$version+$buildNumber';
    } else {
      _cachedAppVersion = version;
    }
  } catch (_) {
    _cachedAppVersion = '1.0.0+1';
  }
  return _cachedAppVersion!;
}

Future<Map<String, String>> _getDeviceHeaders() async {
  final now = DateTime.now();
  if (_cachedDeviceHeaders != null &&
      _lastCacheTime != null &&
      now.difference(_lastCacheTime!) < const Duration(minutes: 5)) {
    return _cachedDeviceHeaders!;
  }

  try {
    final deviceService = DeviceDetailsService();
    final details = await deviceService.collectAll();
    final dev = details['device'] as Map<String, dynamic>? ?? {};

    final deviceId = (dev['androidId'] ??
            dev['identifierForVendor'] ??
            dev['device'] ??
            '')
        .toString();
    final model = (dev['model'] ?? '').toString();
    final brand = (dev['brand'] ?? '').toString();
    final platform = (dev['platform'] ?? '').toString();
    final version = (dev['systemVersion'] ?? dev['version'] ?? '').toString();
    final identifier =
        (dev['identifierForVendor'] ?? dev['androidId'] ?? '').toString();
    final ip = (details['ip'] ?? '').toString();
    final batteryLevel = (details['battery'] is Map)
        ? (details['battery']['level']?.toString() ?? '')
        : '';

    final headers = <String, String>{};
    if (deviceId.isNotEmpty) {
      headers['device-id'] = deviceId;
    }
    if (model.isNotEmpty) {
      headers['device-model'] = model;
    }
    if (brand.isNotEmpty) {
      headers['device-brand'] = brand;
    }
    if (platform.isNotEmpty) {
      headers['device-platform'] = platform;
    }
    if (version.isNotEmpty) {
      headers['device-version'] = version;
    }
    if (identifier.isNotEmpty) {
      headers['device-identifier'] = identifier;
    }
    if (ip.isNotEmpty) {
      headers['device-ip'] = ip;
    }
    if (batteryLevel.isNotEmpty) {
      headers['battery-level'] = batteryLevel;
    }

    _cachedDeviceHeaders = headers;
    _lastCacheTime = now;
    return headers;
  } catch (e) {
    return _cachedDeviceHeaders ?? {};
  }
}

Future<Map<String, String>> _buildHeaders(Map<String, String>? headers) async {
  final Map<String, String> finalHeaders = headers != null ? Map.from(headers) : {};
  finalHeaders['Device-Time'] = DateTime.now().toUtc().toIso8601String();

  final deviceHeaders = await _getDeviceHeaders();
  finalHeaders.addAll(deviceHeaders);

  // Automatically attach app-version and app_version to all API headers
  final appVersion = await _getAppVersion();
  finalHeaders['app-version'] = appVersion;
  finalHeaders['app_version'] = appVersion;

  return finalHeaders;
}

Future<origin_http.Response> get(Uri url, {Map<String, String>? headers}) async {
  final finalHeaders = await _buildHeaders(headers);

  debugPrint('[custom_http GET] url => $url');
  debugPrint('[custom_http GET] headers => $finalHeaders');

  final res = await origin_http.get(url, headers: finalHeaders);
  TimeValidator.validate(res);
  AppUpdateHelper.handlePotentialUpdateRequired(res.statusCode, res.body);
  SessionValidator.validate(res, url: url);
  return res;
}

Future<origin_http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final finalHeaders = await _buildHeaders(headers);

  debugPrint('[custom_http POST] url => $url');
  debugPrint('[custom_http POST] headers => $finalHeaders');

  final res = await origin_http.post(url, headers: finalHeaders, body: body, encoding: encoding);
  TimeValidator.validate(res);
  AppUpdateHelper.handlePotentialUpdateRequired(res.statusCode, res.body);
  SessionValidator.validate(res, url: url);
  return res;
}

Future<origin_http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final finalHeaders = await _buildHeaders(headers);

  debugPrint('[custom_http PUT] url => $url');
  debugPrint('[custom_http PUT] headers => $finalHeaders');

  final res = await origin_http.put(url, headers: finalHeaders, body: body, encoding: encoding);
  TimeValidator.validate(res);
  AppUpdateHelper.handlePotentialUpdateRequired(res.statusCode, res.body);
  SessionValidator.validate(res, url: url);
  return res;
}

Future<origin_http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final finalHeaders = await _buildHeaders(headers);

  debugPrint('[custom_http DELETE] url => $url');
  debugPrint('[custom_http DELETE] headers => $finalHeaders');

  final res = await origin_http.delete(url, headers: finalHeaders, body: body, encoding: encoding);
  TimeValidator.validate(res);
  AppUpdateHelper.handlePotentialUpdateRequired(res.statusCode, res.body);
  SessionValidator.validate(res, url: url);
  return res;
}

Future<origin_http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final finalHeaders = await _buildHeaders(headers);

  debugPrint('[custom_http PATCH] url => $url');
  debugPrint('[custom_http PATCH] headers => $finalHeaders');

  final res = await origin_http.patch(url, headers: finalHeaders, body: body, encoding: encoding);
  TimeValidator.validate(res);
  AppUpdateHelper.handlePotentialUpdateRequired(res.statusCode, res.body);
  SessionValidator.validate(res, url: url);
  return res;
}

Future<origin_http.Response> head(Uri url, {Map<String, String>? headers}) async {
  final finalHeaders = await _buildHeaders(headers);

  debugPrint('[custom_http HEAD] url => $url');
  debugPrint('[custom_http HEAD] headers => $finalHeaders');

  final res = await origin_http.head(url, headers: finalHeaders);
  TimeValidator.validate(res);
  AppUpdateHelper.handlePotentialUpdateRequired(res.statusCode, res.body);
  SessionValidator.validate(res, url: url);
  return res;
}
