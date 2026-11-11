import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cn_pocket_hr/api/custom_http.dart' as http;
import 'package:localstorage/localstorage.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cn_pocket_hr/helpers/app_update_helper.dart';
import 'package:cn_pocket_hr/services/secure_token_service.dart';

class ApiClient {
  static final LocalStorage storage = LocalStorage('pocketHR');
  static String? _cachedAppVersion;

  static Future<String> getAppVersion() async {
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
  
  static Future<Map<String, String>> getHeaders({bool isJson = true}) async {
    await storage.ready;
    final appVer = await getAppVersion();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': isJson ? 'application/json' : 'application/x-www-form-urlencoded',
      'app_version': appVer,
      'app-version': appVer,
    };
    
    final accessToken = await SecureTokenService.getAccessToken();
    final oauthToken = await SecureTokenService.getOauthToken();
    final tenant = storage.getItem('tenant')?.toString() ?? storage.getItem('company')?.toString();
    
    if (accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    if (oauthToken.isNotEmpty) {
      headers['Oauth-Token'] = oauthToken;
    }
    if (tenant != null && tenant.isNotEmpty) {
      headers['Tenant'] = tenant;
    }
    
    return headers;
  }
  
  static Future<String?> getResolvedUserId() async {
    await storage.ready;
    final uid = storage.getItem('uid')?.toString();
    if (uid != null && uid.isNotEmpty) return uid;
    
    final me = storage.getItem('me_profile');
    if (me is Map) {
      final m = Map<String, dynamic>.from(me);
      final dataAny = m['data'] ?? m['result'] ?? m['user'];
      if (dataAny is Map) {
        final data = Map<String, dynamic>.from(dataAny);
        final id = (data['_id'] ?? data['id'] ?? data['user_id'] ?? data['sub'] ?? '').toString();
        if (id.isNotEmpty) return id;
      }
    }
    
    final api = APIService();
    final jwtUid = await api.ensureUidFromAccessToken();
    if (jwtUid != null && jwtUid.isNotEmpty) return jwtUid;
    
    return null;
  }

  static Future<http.Response> get(String url, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    final headers = await getHeaders();
    debugPrint('[API GET] $uri');
    final res = await http.get(uri, headers: headers);
    AppUpdateHelper.handlePotentialUpdateRequired(res.statusCode, res.body);
    return res;
  }

  static Future<http.Response> post(String url, {Map<String, dynamic>? body, bool isJson = true}) async {
    final uri = Uri.parse(url);
    final headers = await getHeaders(isJson: isJson);
    debugPrint('[API POST] $uri');
    
    Object? encodedBody;
    if (body != null) {
       encodedBody = isJson ? jsonEncode(body) : body.map((k, v) => MapEntry(k, v.toString()));
    }
    
    final res = await http.post(uri, headers: headers, body: encodedBody, encoding: Encoding.getByName("utf-8"));
    AppUpdateHelper.handlePotentialUpdateRequired(res.statusCode, res.body);
    return res;
  }
}
