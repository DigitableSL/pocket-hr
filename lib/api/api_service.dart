import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/models/hr/location_model.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cn_pocket_hr/api/custom_http.dart' as http;
import 'package:localstorage/localstorage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cn_pocket_hr/helpers/api_config.dart';
import 'package:cn_pocket_hr/api/config.dart';
import 'package:cn_pocket_hr/models/hr/attendance_model.dart';
import 'package:cn_pocket_hr/models/hr/leave_model.dart';
import 'package:cn_pocket_hr/models/hr/leave_eligibility_model.dart';
import 'package:cn_pocket_hr/models/hr/me_model.dart';
import 'package:cn_pocket_hr/models/hr/todo_model.dart';
import 'package:cn_pocket_hr/services/device_details_service.dart';
import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:cn_pocket_hr/api/api_client.dart';
import 'package:cn_pocket_hr/services/secure_token_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cn_pocket_hr/helpers/app_update_helper.dart';

class APIService {
  final LocalStorage storage = LocalStorage('pocketHR');
  final APIConfig api = APIConfig();
  String get baseUrl => AppConfig.baseUrl;
  bool qrEnable = true;

  Future<String> _getAppVersion() async {
    return await ApiClient.getAppVersion();
  }

  // remoteEnable and remoteValue are fetched entirely dynamically through fetchMeProfileWithBearer and retrieved globally.

  int get remoteValue {
    // 🧪 TESTING OVERRIDE: Uncomment/change the return value below to test remote permissions without backend changes:
    // 0 = disabled, 1 = Check-In only, 2 = Check-Out only, 3 = Check-In & Check-Out enabled
    // return 3; 

    final cached = storage.getItem('me_profile');
    if (cached != null && cached is Map) {
      final dataAny = cached['data'] ?? cached['result'] ?? cached['user'] ?? cached;
      if (dataAny is Map) {
        final remoteVal = dataAny['remote'];
        final remoteModeVal = dataAny['remote_mode'];

        // Evaluate boolean/truthiness of 'remote'
        bool isRemoteActive = false;
        int? legacyIntRemote;

        if (remoteVal == true || remoteVal == 'true' || remoteVal == 1 || remoteVal == '1') {
          isRemoteActive = true;
        } else if (remoteVal is int && remoteVal > 0) {
          isRemoteActive = true;
          legacyIntRemote = remoteVal;
        } else if (remoteVal is String) {
          final parsed = int.tryParse(remoteVal);
          if (parsed != null && parsed > 0) {
            isRemoteActive = true;
            legacyIntRemote = parsed;
          }
        }

        // If 'remote' is false/0, do not show any remote button
        if (!isRemoteActive) {
          return 0;
        }

        // Parse 'remote_mode'
        int mode = 0;
        if (remoteModeVal != null) {
          if (remoteModeVal is int) {
            mode = remoteModeVal;
          } else if (remoteModeVal is String) {
            mode = int.tryParse(remoteModeVal) ?? 0;
          }
        } else if (legacyIntRemote != null) {
          mode = legacyIntRemote;
        } else {
          // Default to 3 (both buttons) if remote is true but remote_mode is unspecified
          mode = 3;
        }

        // Evaluated modes:
        // 0 -> don't show any remote button
        // 1 -> only Check-In button show to user
        // 2 -> only Check-Out button show to user
        // 3 -> Check-In and Check-Out both buttons show to user
        if (mode == 1) return 1;
        if (mode == 2) return 2;
        if (mode == 3) return 3;
        return 0;
      }
    }
    return 0; // Default fallback
  }

  bool get remoteEnable {
    return remoteValue > 0;
  }

  Future<void> showToast(dynamic text, {bool isError = true}) async {
    String msg;
    try {
      if (text is List) {
        msg = text.map((e) => e?.toString() ?? '').join('\n');
      } else if (text is Map) {
        // Try common keys in order of priority
        if (text.containsKey('message')) {
          msg = text['message']?.toString() ?? '';
        } else if (text.containsKey('msg')) {
          msg = text['msg']?.toString() ?? '';
        } else if (text.containsKey('error')) {
          msg = text['error']?.toString() ?? '';
        } else if (text.containsKey('errors')) {
          final errs = text['errors'];
          if (errs is List)
            msg = errs.map((e) => e?.toString() ?? '').join('\n');
          else
            msg = errs?.toString() ?? '';
        } else {
          msg = text.toString();
        }
      } else {
        msg = text?.toString() ?? '';
      }
    } catch (_) {
      msg = text.toString();
    }

    // Ensure non-empty fallback
    if (msg.trim().isEmpty) msg = 'Message';

    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 4,
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade600,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  Future checkInCheckout(date, type,
      {String? latitude,
      String? longitude,
      String? address,
      String? accuracy,
      bool isRemotePunch = false}) async {
    await storage.ready;

    // Silently refresh token if expired before making the request.
    await _ensureValidToken();

    String url = "${baseUrl}/attendance/check-in";
    String uid = storage.getItem('uid')?.toString() ?? '';

    if (uid.isEmpty) {
      final token = await SecureTokenService.getOauthToken();
      final access = await SecureTokenService.getAccessToken();
      if (access.isEmpty && token.isNotEmpty) {
        await SecureTokenService.saveTokens(accessToken: token);
      }
      final ensured = await ensureUidFromAccessToken();
      if (ensured != null && ensured.isNotEmpty) {
        uid = ensured;
      }
      if (uid.isEmpty) {
        final me = await fetchMeProfileWithBearer();
        if (me != null) {
          final dataAny = me['data'] ?? me['result'] ?? me['user'];
          if (dataAny is Map) {
            final data = Map<String, dynamic>.from(dataAny);
            final id = (data['_id'] ?? data['id'] ?? '').toString();
            if (id.isNotEmpty) {
              uid = id;
              await storage.setItem('uid', uid);
            }
          }
        }
      }
    }

    Map<String, String> data = {
      'uid': uid,
      'checked_at': date,
      'user-id': uid,
      'remote': isRemotePunch.toString()
    };
    if (type == 'checkout') {
      url = "${baseUrl}/attendance/check-out";
      data = {
        'uid': uid,
        'checkout_at': date,
        'user-id': uid,
        'remote': isRemotePunch.toString()
      };
    }
    if (latitude != null && latitude.isNotEmpty) {
      data['lat'] = latitude;
    }
    if (longitude != null && longitude.isNotEmpty) {
      data['lng'] = longitude;
    }
    if (address != null && address.isNotEmpty) data['address'] = address;
    if (accuracy != null && accuracy.isNotEmpty)
      data['location_accuracy'] = accuracy;
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
      final version = (dev['version'] ?? '').toString();
      final identifier =
          (dev['identifierForVendor'] ?? dev['androidId'] ?? '').toString();
      final ip = (details['ip'] ?? '').toString();
      final batteryLevel = (details['battery'] is Map)
          ? (details['battery']['level']?.toString() ?? '')
          : '';

      if (deviceId.isNotEmpty) data['device_id'] = deviceId;
      if (model.isNotEmpty) data['device_model'] = model;
      if (brand.isNotEmpty) data['device_brand'] = brand;
      if (platform.isNotEmpty) data['device_platform'] = platform;
      if (version.isNotEmpty) data['device_version'] = version;
      if (identifier.isNotEmpty) data['device_identifier'] = identifier;
      if (ip.isNotEmpty) data['device_ip'] = ip;
      if (batteryLevel.isNotEmpty) data['battery_level'] = batteryLevel;
    } catch (e) {
      debugPrint('[CHECK] device details collect failed: $e');
    }
    try {
      await _injectTenantToBody(data);
    } catch (_) {}
    final appVer = await _getAppVersion();
    final headers = {
      "Accept": "application/json",
      "Content-Type": "application/x-www-form-urlencoded",
      "app_version": appVer,
      "app-version": appVer,
    };
    final oauthToken = SecureTokenService.getOauthTokenSync();
    final accessToken = SecureTokenService.getAccessTokenSync();
    if (oauthToken != null && oauthToken.isNotEmpty)
      headers['Oauth-Token'] = oauthToken;
    if (accessToken != null && accessToken.isNotEmpty)
      headers['Authorization'] = 'Bearer $accessToken';
      headers['app_version'] = await _getAppVersion();
    try {
      debugPrint('[CHECK] POST $url');
      debugPrint('[CHECK] body => $data');
    } catch (_) {}

    try {
      final response = await http.post(Uri.parse(url),
          headers: headers,
          body: data.map((k, v) => MapEntry(k, v)),
          encoding: Encoding.getByName("utf-8"));
      final values = json.decode(response.body);
      debugPrint('[CHECK] response => ' + response.body);
      debugPrint('[CHECK] status ${response.statusCode}');

      if (values is Map && values.containsKey('message'))
        debugPrint(values['message']?.toString());

      // Inject the status code so the UI can check it explicitly
      if (values is Map) {
        final out = Map<String, dynamic>.from(values);
        out['status'] = response.statusCode;
        return out;
      }
      return {'status': response.statusCode, 'body': response.body};
    } catch (e) {
      debugPrint('[CHECK] ERROR => $e');
      return null;
    }
  }

  Future<dynamic> leave(dynamic details) async {
    try {
      await storage.ready;
      // access_token is the Bearer token, token is the oauth token used as Oauth-Token
      final accessToken = SecureTokenService.getAccessTokenSync();
      final oauthToken = SecureTokenService.getOauthTokenSync();
      final tenant = await _resolveTenant();
      final url = '${baseUrl}/leave/store';

      // Safe extraction of fields
      final uidStr = storage.getItem('uid')?.toString() ?? '';

      final rawLeaveTitle = details is Map && details['leave_title'] != null
          ? details['leave_title'].toString().trim()
          : '';
      final description = details is Map && details['description'] != null
          ? details['description'].toString()
          : '';
      final cleanDesc = description.trim();

      String leaveTitle = rawLeaveTitle;
      if (cleanDesc.isNotEmpty) {
        if (leaveTitle.isEmpty || leaveTitle == 'Leave Request') {
          leaveTitle = cleanDesc;
        } else if (!leaveTitle.contains(cleanDesc)) {
          leaveTitle = '$leaveTitle - $cleanDesc';
        }
      } else if (leaveTitle.isEmpty) {
        leaveTitle = 'Leave Request';
      }

      final fromDate = details is Map && details['from_date'] != null
          ? details['from_date'].toString()
          : '';
      final toDate = details is Map && details['to_date'] != null
          ? details['to_date'].toString()
          : '';
      final leaveType = details is Map && details['leave_type'] != null
          ? details['leave_type'].toString()
          : '';
      final typeStr = details is Map && details['type'] != null
          ? details['type'].toString()
          : '';
      final session = details is Map && details['session'] != null
          ? details['session'].toString()
          : '';
      final shortLeavePeriod = details is Map && details['short_leave_period'] != null
          ? details['short_leave_period'].toString()
          : '';

      final isShortLeave = leaveType == 'short_leave' || typeStr == 'short_leave';

      final data = isShortLeave
          ? {
              'uid': uidStr,
              'from_date': fromDate,
              'leave_type': 'short_leave',
              'type': 'short_leave',
              if (shortLeavePeriod.isNotEmpty) 'short_leave_period': shortLeavePeriod,
              'leave_title': leaveTitle,
            }
          : {
              'leave_title': leaveTitle,
              'from_date': fromDate,
              'to_date': toDate,
              'user-id': uidStr,
              'uid': uidStr,
              'leave_type': leaveType,
              'type': typeStr,
              'session': session,
              'description': description,
            };
      await _injectTenantToBody(data);

      // Build headers as Map<String, String> and only include keys with non-empty values
      final appVer = await _getAppVersion();
      final headers = <String, String>{
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
        "app_version": appVer,
        "app-version": appVer,
      };
      // Include both auth forms when available: Bearer for access_token, Oauth-Token for legacy oauth token
      if (accessToken.isNotEmpty)
        headers['Authorization'] = 'Bearer $accessToken';
      if (oauthToken.isNotEmpty) headers['Oauth-Token'] = oauthToken;
      if (tenant != null && tenant.isNotEmpty) headers['Tenant'] = tenant;

      // Debug (use debugPrint and interpolation)
      debugPrint('[LEAVE] POST $url');
      debugPrint('[LEAVE] headers => $headers');
      debugPrint('[LEAVE] body => $data');
      debugPrint('=================== LEAVE REQUEST FULL BODY ===================');
      debugPrint(jsonEncode(data));
      debugPrint('==============================================================');

      final response = await http.post(Uri.parse(url),
          headers: headers, body: data, encoding: Encoding.getByName("utf-8"));

      debugPrint('=================== LEAVE RESPONSE FULL BODY ===================');
      debugPrint(response.body);
      debugPrint('================================================================');
      debugPrint('[LEAVE] response => ${response.body}');
      final values = json.decode(response.body);

      // Inject status code so UI checks it safely
      if (values is Map) {
        final out = Map<String, dynamic>.from(values);
        out['statusCode'] = response.statusCode;
        return out;
      }
      return values;
    } catch (e, st) {
      debugPrint('[LEAVE] ERROR => $e');
      debugPrint(st.toString());
      showToast('Failed to submit leave.');
      return {'status': false, 'message': 'Failed to submit leave.'};
    }
  }

  Future<Map<String, dynamic>?> getLeaveBalance({String? userId}) async {
    try {
      await storage.ready;
      String uid = userId ?? storage.getItem('uid')?.toString() ?? '';
      if (uid.isEmpty) {
        uid = await ensureUidFromAccessToken() ?? '';
      }
      if (uid.isEmpty) return null;

      final url = '${baseUrl}/leave/balance?userId=$uid';
      final uri = await _uriWithTenant(url);
      final accessToken = SecureTokenService.getAccessTokenSync();
      final oauthToken = SecureTokenService.getOauthTokenSync();

      final appVer = await _getAppVersion();
      final headers = <String, String>{
        'Accept': 'application/json',
        'app_version': appVer,
        'app-version': appVer,
      };
      if (accessToken.isNotEmpty)
        headers['Authorization'] = 'Bearer $accessToken';
      if (oauthToken.isNotEmpty) headers['Oauth-Token'] = oauthToken;

      final response = await http.get(uri, headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data']);
        }
      }
    } catch (e) {
      debugPrint('[LEAVE BALANCE] ERROR => $e');
    }
    return null;
  }

  Future<LeaveApplyEligibility?> getLeaveApplyEligibility({String? userId}) async {
    try {
      await storage.ready;
      String uid = userId ?? storage.getItem('uid')?.toString() ?? '';
      if (uid.isEmpty) {
        uid = await ensureUidFromAccessToken() ?? '';
      }
      if (uid.isEmpty) return null;

      final url = '${baseUrl}/leave/apply-eligibility/$uid';
      final uri = await _uriWithTenant(url);
      final accessToken = SecureTokenService.getAccessTokenSync();
      final oauthToken = SecureTokenService.getOauthTokenSync();

      final appVer = await _getAppVersion();
      final headers = <String, String>{
        'Accept': 'application/json',
        'app_version': appVer,
        'app-version': appVer,
      };
      if (accessToken.isNotEmpty)
        headers['Authorization'] = 'Bearer $accessToken';
      if (oauthToken.isNotEmpty) headers['Oauth-Token'] = oauthToken;

      debugPrint('[LEAVE ELIGIBILITY] GET $uri');
      final response = await http.get(uri, headers: headers);
      debugPrint('[LEAVE ELIGIBILITY] status=${response.statusCode} body=${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return LeaveApplyEligibility.fromJson(
              Map<String, dynamic>.from(decoded['data']));
        }
      }
    } catch (e) {
      debugPrint('[LEAVE ELIGIBILITY] ERROR => $e');
    }
    return null;
  }

  Future<List<TodoItem>> getTodos({required bool approvableByMe}) async {
    try {
      await storage.ready;
      final url = '$baseUrl/todos';
      final uri = await _uriWithTenant(url, {
        'approvableByMe': approvableByMe.toString(),
      });
      final accessToken = SecureTokenService.getAccessTokenSync();
      final oauthToken = SecureTokenService.getOauthTokenSync();

      final appVer = await _getAppVersion();
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'app_version': appVer,
        'app-version': appVer,
      };
      if (accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      if (oauthToken.isNotEmpty) {
        headers['Oauth-Token'] = oauthToken;
      }
      
      final tenant = await _resolveTenant();
      if (tenant != null && tenant.isNotEmpty) {
        headers['Tenant'] = tenant;
      }

      debugPrint('[TODOS] GET $uri');
      debugPrint('[TODOS] headers => $headers');

      final response = await http.get(uri, headers: headers);
      debugPrint('[TODOS] status=${response.statusCode}');
      debugPrint('[TODOS] response.body=${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to load todos (Status: ${response.statusCode})');
      }

      final decoded = json.decode(response.body);
      List<dynamic> itemsList = [];
      if (decoded is List) {
        itemsList = decoded;
      } else if (decoded is Map) {
        final nestedData = decoded['data'] ?? decoded['result'] ?? decoded['todos'] ?? decoded['items'];
        if (nestedData is List) {
          itemsList = nestedData;
        } else if (nestedData is Map) {
          final subData = nestedData['data'] ?? nestedData['result'] ?? nestedData['items'] ?? nestedData['todos'];
          if (subData is List) {
            itemsList = subData;
          }
        }
      }

      return itemsList
          .whereType<Map>()
          .map((e) => TodoItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e, st) {
      debugPrint('[TODOS] ERROR => $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<List<MeSubsModel>> getMeSubs() async {
    final url = api.api() + "me";

    final uidStr = storage.getItem('uid')?.toString() ?? '';
    final tokenStr = SecureTokenService.getOauthTokenSync();
    final qParams = {'user-id': uidStr};
    final header = {
      "Accept": "application/json",
      "Content-Type": "application/x-www-form-urlencoded",
      "Oauth-token": tokenStr
    };

    final finalUri = await _uriWithTenant(url, qParams);
    final response = await http.get(finalUri, headers: header);

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      if (jsonData['status']) {
        final detail = (jsonData['result']['subs'] as List)
            .map((data) => MeSubsModel.fromJson(data))
            .toList();
        return detail;
      } else {
        return [];
      }
    } else {
      // showToast("Failed to load leaves");
      throw Exception("Failed to load leaves");
    }
  }

  Future<Map<String, dynamic>?> fetchMeProfileWithBearer(
      {bool forceRefresh = false}) async {
    try {
      await storage.ready;

      // Ensure a valid (non-expired) access token before calling /auth/me.
      await _ensureValidToken();

      String accessToken = await SecureTokenService.getAccessToken();
      if (accessToken.isEmpty) {
        debugPrint('[ME] Missing access_token in storage');
        return null;
      }
      String tenant = storage.getItem('tenant')?.toString() ?? '';
      if (tenant.isEmpty) {
        tenant = storage.getItem('company')?.toString() ?? '';
      }

      if (tenant.isEmpty) {
        try {
          final payload = _decodeJwtPayload(accessToken);
          if (payload != null) {
            if (payload.containsKey('tenant'))
              tenant = payload['tenant']?.toString() ?? '';
            if (tenant.isEmpty && payload.containsKey('client_id')) {
              final cid = payload['client_id']?.toString() ?? '';
              if (cid.isNotEmpty) {
                final parts = cid.split(RegExp(r'[_-]'));
                tenant = parts.isNotEmpty ? parts.last : cid;
              }
            }
            if (tenant.isEmpty && payload.containsKey('company'))
              tenant = payload['company']?.toString() ?? '';
          }
        } catch (_) {}
      }

      // Persist derived tenant for future calls
      if (tenant.isNotEmpty) {
        try {
          await storage.setItem('tenant', tenant);
        } catch (_) {}
      }

      final baseUrl = "${this.baseUrl}/auth/me";
      final uri = await _uriWithTenant(baseUrl);

      final appVer = await _getAppVersion();
      Map<String, String> headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
        "app_version": appVer,
        "app-version": appVer,
      };
      if (tenant.isNotEmpty) headers['Tenant'] = tenant;

      var response = await http.get(uri, headers: headers);

      // If 401 here, try refreshing once and retry.
      if (response.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          accessToken = SecureTokenService.getAccessTokenSync();
          headers['Authorization'] = 'Bearer $accessToken';
          response = await http.get(uri, headers: headers);
        }
      }

      debugPrint('[ME] GET ${uri.toString()} status=${response.statusCode}');
      debugPrint('[ME] body=${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid profile response format');
      }

      await storage.setItem('me_profile', decoded);

      // Persist uid if present in bearer profile response
      final dataAny = decoded['data'] ?? decoded['result'] ?? decoded['user'];
      if (dataAny is Map) {
        final data = Map<String, dynamic>.from(dataAny);

        final id = (data['_id'] ?? data['id'] ?? '').toString();
        if (id.isNotEmpty) {
          await storage.setItem('uid', id);
        }

        // Persist leave quotas if available in profile response
        try {
          // 1) Newer APIs may provide leave_quota directly
          if (data.containsKey('leave_quota') && data['leave_quota'] is Map) {
            final lq = Map<String, dynamic>.from(data['leave_quota']);
            if (lq.containsKey('annual'))
              await storage.setItem('annualQuota', lq['annual']);
            if (lq.containsKey('casual'))
              await storage.setItem('casualQuota', lq['casual']);
            if (lq.containsKey('medical'))
              await storage.setItem('medicalQuota', lq['medical']);
          }

          // 2) Some profiles include package -> leave
          final pkgAny = data['package'];
          if (pkgAny is Map &&
              pkgAny.containsKey('leave') &&
              pkgAny['leave'] is Map) {
            final lp = Map<String, dynamic>.from(pkgAny['leave']);
            if (lp.containsKey('annual'))
              await storage.setItem('annualQuota', lp['annual']);
            if (lp.containsKey('casual'))
              await storage.setItem('casualQuota', lp['casual']);
            if (lp.containsKey('medical'))
              await storage.setItem('medicalQuota', lp['medical']);
          }

          // Persist leave balances if provided, otherwise default to 0
          if (data.containsKey('leave_balance') &&
              data['leave_balance'] is Map) {
            final lb = Map<String, dynamic>.from(data['leave_balance']);
            if (lb.containsKey('annual'))
              await storage.setItem('leaveAnnual', lb['annual']);
            if (lb.containsKey('casual'))
              await storage.setItem('leaveCasual', lb['casual']);
            if (lb.containsKey('medical'))
              await storage.setItem('leaveMedical', lb['medical']);
            if (lb.containsKey('nopay'))
              await storage.setItem('leaveNopay', lb['nopay']);
          } else {
            // Ensure keys exist with default 0 so UI doesn't show null
            await storage.setItem(
                'leaveAnnual', storage.getItem('leaveAnnual') ?? 0);
            await storage.setItem(
                'leaveCasual', storage.getItem('leaveCasual') ?? 0);
            await storage.setItem(
                'leaveMedical', storage.getItem('leaveMedical') ?? 0);
            await storage.setItem(
                'leaveNopay', storage.getItem('leaveNopay') ?? 0);
          }
        } catch (_) {}
      }

      return decoded;
    } catch (e) {
      debugPrint('[ME] ERROR => $e');
      rethrow;
    }
  }

  Future<List<MyLeavesModel>> getMyLeaves() async {
    try {
      await storage.ready;

      final uidStr = storage.getItem('uid')?.toString() ?? '';
      final accessToken = SecureTokenService.getAccessTokenSync();
      final oauthToken = SecureTokenService.getOauthTokenSync();
      final String url = '${baseUrl}/leave';

      final qParams = <String, String>{
        // 'startDate': startSec,
        // 'endDate': endSec,
        'userIds': uidStr,
      };

      final uri = Uri.parse(url).replace(queryParameters: qParams);

      final appVer = await _getAppVersion();
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'app_version': appVer,
        'app-version': appVer,
      };
      if (oauthToken.isNotEmpty) headers['Oauth-Token'] = oauthToken;
      if (accessToken.isNotEmpty)
        headers['Authorization'] = 'Bearer $accessToken';

      // tenant is required by some deployments
      final tenant = await _resolveTenant();
      if (tenant != null && tenant.isNotEmpty) {
        headers['Tenant'] = tenant;
      }

      debugPrint('[LEAVE] GET $uri');
      debugPrint('[LEAVE] headers => $headers');

      final response = await http.get(uri, headers: headers);

      debugPrint('[LEAVE] status=${response.statusCode}');
      String prettyJson;
      try {
        final decodedJson = jsonDecode(response.body);
        prettyJson = const JsonEncoder.withIndent('  ').convert(decodedJson);
      } catch (e) {
        prettyJson = response.body;
      }
      debugPrint('[ME] Response Body:\n$prettyJson');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return [];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return [];

      final map = Map<String, dynamic>.from(decoded);
      if (map['success'] != true) return [];

      final dataAny = map['data'];
      if (dataAny is! List) return [];

      // `MyLeavesModel.fromJson` in your app expects a specific shape (old API).
      // Normalize the new API shape into a minimal compatible map.
      final out = <MyLeavesModel>[];
      for (final item in dataAny) {
        if (item is! Map) continue;
        final it = Map<String, dynamic>.from(item);

        // dates are epoch seconds in an array
        final dateSecs = <int>[];
        try {
          final dates = it['dates'];
          if (dates is List) {
            for (final d in dates) {
              final sec = (d is int) ? d : int.tryParse(d.toString());
              if (sec != null) dateSecs.add(sec);
            }
          }
        } catch (_) {}

        int? fromSec;
        int? toSec;
        if (dateSecs.isNotEmpty) {
          dateSecs.sort();
          fromSec = dateSecs.first;
          toSec = dateSecs.last;
        }

        // Provide formatted dates that UI expects (dd/MM/yyyy)
        String? fmtDdMmYyyy(int? sec) {
          if (sec == null) return null;
          try {
            final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
            final dd = dt.day.toString().padLeft(2, '0');
            final mm = dt.month.toString().padLeft(2, '0');
            final yy = dt.year.toString();
            return '$dd/$mm/$yy';
          } catch (_) {
            return null;
          }
        }

        final fromStr = fmtDdMmYyyy(fromSec);
        final toStr = fmtDdMmYyyy(toSec);

        final reason =
            (it['reason'] ?? it['title'] ?? it['leave_title'] ?? '').toString();
        final type = (it['type'] ?? '').toString();
        final status = (it['status'] ?? '').toString();

        final normalized = <String, dynamic>{
          // keep id for details
          '_id': (it['_id'] ?? it['id'] ?? '').toString(),
          'id': (it['_id'] ?? it['id'] ?? '').toString(),

          // common fields used by leave UI
          'status': status,
          'type': type,
          'leave_type': type,
          'leaveTitle': reason,
          'leave_title': reason,
          'reason': reason,
          'description': reason,

          // date range
          'fromDate': fromStr,
          'toDate': toStr,
          'from_date': fromStr,
          'to_date': toStr,

          // raw dates available if model needs them
          'dates': dateSecs,
          'session': (it['session'] != null && it['session'].toString().isNotEmpty)
              ? it['session'].toString()
              : ((it['leave_type'] == 'half' || it['type'] == 'half')
                  ? (it['half_period'] ?? 'half').toString()
                  : 'full_day'),

          // Safety defaults for bool fields expected by legacy models
          'autoGenerated':
              (it['autoGenerated'] ?? it['auto_generated'] ?? false) == true,
          'auto_generated':
              (it['coveringEmployee'] ?? it['covering_employee'] ?? false) ==
                  true,
          'removed': (it['removed'] ?? false) == true,
          'isHoliday': (it['isHoliday'] ??
                  (it['slot'] is Map
                      ? (it['slot']['isHoliday'] ?? false)
                      : false)) ==
              true,
          'isOffday': (it['isOffday'] ??
                  (it['slot'] is Map
                      ? (it['slot']['isOffday'] ?? false)
                      : false)) ==
              true,
          'coveringEmployee':
              (it['coveringEmployee'] ?? it['covering_employee'] ?? false) ==
                  true,
          'covering_employee':
              (it['coveringEmployee'] ?? it['covering_employee'] ?? false) ==
                  true,

          // extra pass-through
          'employeeName': it['employeeName'],
          'userId': it['userId'],
          'slot': it['slot'],
        };

        try {
          out.add(MyLeavesModel.fromJson(normalized));
        } catch (e) {
          // If parsing fails, log and continue so we can see the error in console.
          debugPrint('[LEAVE] MyLeavesModel.fromJson failed: $e');
          debugPrint('[LEAVE] normalized item: $normalized');
        }
      }

      debugPrint('[LEAVE] parsed leaves count=${out.length}');
      return out;
    } catch (e, st) {
      debugPrint('[LEAVE] getMyLeaves ERROR => $e');
      debugPrint(st.toString());
      return [];
    }
  }

  Future<List<dynamic>> fetchVariablesForUser(String userId) async {
    await storage.ready;

    String? accessToken = SecureTokenService.getAccessTokenSync();
    final oauthToken = SecureTokenService.getOauthTokenSync();
    final tenant = await _resolveTenant();

    final url = '${baseUrl}/variables/variables/$userId';
    final uri = await _uriWithTenant(url);

    Future<Map<String, String>> buildHeaders({
      bool includeAccess = true,
      bool includeOauth = true,
    }) async {
      final appVer = await _getAppVersion();
      final h = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'app_version': appVer,
        'app-version': appVer,
      };

      if (includeAccess && (accessToken != null && accessToken.isNotEmpty)) {
        h['Authorization'] = 'Bearer $accessToken';
      }

      if (includeOauth && oauthToken.isNotEmpty) {
        h['Oauth-Token'] = oauthToken;
      }

      if (tenant != null && tenant.isNotEmpty) {
        h['Tenant'] = tenant;
      }

      return h;
    }

    var res = await http.get(
      uri,
      headers: await buildHeaders(includeAccess: true, includeOauth: true),
    );

    // Retry logic
    if (res.statusCode == 401 || res.statusCode == 403) {
      // Attempt 2 → oauth only
      if (oauthToken.isNotEmpty) {
        try {
          res = await http.get(
            uri,
            headers: await buildHeaders(includeAccess: false, includeOauth: true),
          );
        } catch (_) {}
      }

      // Attempt 3 → Refresh bearer
      if (res.statusCode == 401 || res.statusCode == 403) {
        try {
          await fetchMeProfileWithBearer();
          accessToken = SecureTokenService.getAccessTokenSync();

          res = await http.get(
            uri,
            headers: await buildHeaders(includeAccess: true, includeOauth: true),
          );
        } catch (_) {}
      }
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to load variables (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded['variables'] is List) {
      debugPrint(decoded.toString());
      return List<dynamic>.from(decoded['variables']);
    }
    // Some backends might return list directly.
    if (decoded is List) return decoded;

    return const [];
  }

  Future<List<dynamic>> fetchDebtsForUser(String userId) async {
    try {
      await storage.ready;

      debugPrint('\n[DEBT] ===== FETCH DEBTS START =====');

      String? accessToken = SecureTokenService.getAccessTokenSync();
      final oauthToken = SecureTokenService.getOauthTokenSync();
      final uid = (userId).toString().isNotEmpty
          ? userId.toString()
          : '605b4f4c277bf8660c7b23df';

      debugPrint('[DEBT] User ID: $uid');

      final url = '${baseUrl}/debts/$uid';
      final uri = await _uriWithTenant(url);

      debugPrint('[DEBT] URL: $uri');

      Future<Map<String, String>> buildHeaders({
        bool includeAccess = true,
        bool includeOauth = true,
      }) async {
        final appVer = await _getAppVersion();
        final h = <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'app_version': appVer,
          'app-version': appVer,
        };

        if (includeAccess && (accessToken != null && accessToken.isNotEmpty)) {
          h['Authorization'] = 'Bearer $accessToken';
          debugPrint('[DEBT] Using Access Token: ${accessToken.substring(0, 8)}...');
        }

        if (includeOauth && oauthToken.isNotEmpty) {
          h['Oauth-Token'] = oauthToken;
          debugPrint('[DEBT] Using Oauth Token: ${oauthToken.substring(0, 8)}...');
        }

        return h;
      }

      debugPrint('[DEBT] Attempt 1 → Access + Oauth');

      var res = await http.get(
        uri,
        headers: await buildHeaders(includeAccess: true, includeOauth: true),
      );

      debugPrint('[DEBT] Response Status (Attempt 1): ${res.statusCode}');
      debugPrint('[DEBT] Response Body: ${res.body}');

      // Retry logic
      if (res.statusCode == 401 || res.statusCode == 403) {
        debugPrint('[DEBT] Unauthorized. Trying fallback methods...');

        // Attempt 2 → oauth only
        if (oauthToken.isNotEmpty) {
          try {
            debugPrint('[DEBT] Attempt 2 → Oauth Only');
            res = await http.get(
              uri,
              headers: await buildHeaders(includeAccess: false, includeOauth: true),
            );
            debugPrint('[DEBT] Response Status (Attempt 2): ${res.statusCode}');
          } catch (e) {
            debugPrint('[DEBT] Attempt 2 Failed: $e');
          }
        }

        // Attempt 3 → Refresh bearer
        if (res.statusCode == 401 || res.statusCode == 403) {
          try {
            debugPrint('[DEBT] Attempt 3 → Refreshing Bearer Token...');
            await fetchMeProfileWithBearer();
            accessToken = SecureTokenService.getAccessTokenSync();

            res = await http.get(
              uri,
              headers: await buildHeaders(includeAccess: true, includeOauth: true),
            );

            debugPrint('[DEBT] Response Status (Attempt 3): ${res.statusCode}');
          } catch (e) {
            debugPrint('[DEBT] Attempt 3 Failed: $e');
          }
        }
      }

      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint('[DEBT] Final Failure Status: ${res.statusCode}');
        if (res.statusCode == 401 || res.statusCode == 403) {
          try {
            showToast('Sorry, cannot access this app. Please log in again.');
          } catch (_) {}
        }
        throw Exception('Failed to load debts (${res.statusCode})');
      }

      debugPrint('[DEBT] Parsing response...');
      final decoded = jsonDecode(res.body);

      if (decoded is Map && decoded['data'] is Map) {
        final data = Map<String, dynamic>.from(decoded['data']);
        if (data['debts'] is List) {
          debugPrint('[DEBT] Debts Count: ${(data['debts'] as List).length}');
          debugPrint('[DEBT] ===== FETCH DEBTS SUCCESS =====\n');
          return List<dynamic>.from(data['debts']);
        }
      }

      debugPrint('[DEBT] No debts found.');
      debugPrint('[DEBT] ===== FETCH DEBTS END =====\n');
      return const [];
    } catch (e, st) {
      debugPrint('[DEBT] EXCEPTION: $e');
      debugPrint('[DEBT] STACKTRACE: $st');
      debugPrint('[DEBT] ===== FETCH DEBTS CRASHED =====\n');
      rethrow;
    }
  }

  apiFailedRedirect() async {
    showToast("Sorry, cannot access this app. Please log in again.");
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final obj = jsonDecode(decoded);
      if (obj is Map<String, dynamic>) return obj;
      if (obj is Map) return Map<String, dynamic>.from(obj);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _injectTenantToBody(Map<String, String> body) async {
    try {
      await storage.ready;
      String tenant = storage.getItem('tenant')?.toString() ?? '';
      if (tenant.isEmpty) tenant = storage.getItem('company')?.toString() ?? '';
      if (tenant.isEmpty) {
        final accessToken = SecureTokenService.getAccessTokenSync();
        if (accessToken.isNotEmpty) {
          final payload = _decodeJwtPayload(accessToken);
          if (payload != null) {
            tenant = (payload['tenant'] ?? payload['company'] ?? '').toString();
            if (tenant.isEmpty && payload.containsKey('client_id')) {
              final cid = payload['client_id']?.toString() ?? '';
              if (cid.isNotEmpty) {
                final parts = cid.split(RegExp(r'[_-]'));
                tenant = parts.isNotEmpty ? parts.last : cid;
              }
            }
          }
        }
      }
      if (tenant.isNotEmpty) {
        body['tenant'] = tenant;
      }
    } catch (_) {}
  }

  // Resolve tenant from storage or access token payload
  Future<String?> _resolveTenant() async {
    // Check flavor-level hardcoded tenant first
    try {
      final flavorTenant = FlavorConfig.instance.tenant;
      if (flavorTenant != null && flavorTenant.isNotEmpty) {
        return flavorTenant;
      }
    } catch (_) {}
    try {
      await storage.ready;
      String tenant = storage.getItem('tenant')?.toString() ?? '';
      if (tenant.isEmpty) tenant = storage.getItem('company')?.toString() ?? '';
      if (tenant.isEmpty) {
        final accessToken = SecureTokenService.getAccessTokenSync();
        if (accessToken.isNotEmpty) {
          final payload = _decodeJwtPayload(accessToken);
          if (payload != null) {
            tenant = (payload['tenant'] ?? payload['company'] ?? '').toString();
            if (tenant.isEmpty && payload.containsKey('client_id')) {
              final cid = payload['client_id']?.toString() ?? '';
              if (cid.isNotEmpty) {
                final parts = cid.split(RegExp(r'[_-]'));
                tenant = parts.isNotEmpty ? parts.last : cid;
              }
            }
          }
        }
      }
      return tenant.isNotEmpty ? tenant : null;
    } catch (_) {
      return null;
    }
  }

  // Build a Uri and append tenant as query parameter when available.
  Future<Uri> _uriWithTenant(String url, [Map<String, String>? qParams]) async {
    try {
      final tenant = await _resolveTenant();
      final Uri uri = Uri.parse(url);
      final Map<String, String> merged = {};
      if (uri.queryParameters.isNotEmpty) merged.addAll(uri.queryParameters);
      if (qParams != null && qParams.isNotEmpty) merged.addAll(qParams);
      if (tenant != null && tenant.isNotEmpty) merged['tenant'] = tenant;
      return uri.replace(queryParameters: merged.isNotEmpty ? merged : null);
    } catch (_) {
      return Uri.parse(url);
    }
  }

  bool _isJwtExpired(String token) {
    try {
      final payload = _decodeJwtPayload(token);
      if (payload == null) return true;
      final expAny =
          payload['exp'] ?? payload['expiry'] ?? payload['expires_at'];
      if (expAny == null) return true;
      int expSec;
      if (expAny is int)
        expSec = expAny;
      else if (expAny is double)
        expSec = expAny.toInt();
      else
        expSec = int.tryParse(expAny.toString()) ?? 0;
      if (expSec <= 0) return true;
      final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      return expSec <= nowSec;
    } catch (_) {
      return true;
    }
  }

  Future<bool> hasValidAccessToken() async {
    try {
      await storage.ready;
      final token = await SecureTokenService.getAccessToken();
      if (token.isEmpty) return false;
      if (!_isJwtExpired(token)) return true;
      // Token is expired — try a silent refresh before declaring invalid.
      return await _refreshAccessToken();
    } catch (_) {
      return false;
    }
  }

  // ── Token-refresh machinery ──────────────────────────────────────────────

  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  /// Silently exchanges the stored refresh_token for a new access_token.
  /// Returns true when new tokens have been persisted, false otherwise.
  Future<bool> _refreshAccessToken() async {
    // Serialise concurrent refresh attempts — let the first one run and
    // return its result to everyone else waiting.
    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      await storage.ready;

      // --- Retrieve refresh token from encrypted storage
      final refreshToken = await SecureTokenService.getRefreshToken();
      if (refreshToken.isEmpty) {
        debugPrint('[TokenRefresh] No refresh_token — cannot refresh.');
        _refreshCompleter!.complete(false);
        return false;
      }

      // --- Extract client_id from the current access token JWT payload
      String clientId = '';
      final currentToken = await SecureTokenService.getAccessToken();
      if (currentToken.isNotEmpty) {
        clientId =
            _decodeJwtPayload(currentToken)?['client_id']?.toString() ?? '';
      }
      if (clientId.isEmpty) {
        debugPrint('[TokenRefresh] No client_id in JWT — cannot refresh.');
        _refreshCompleter!.complete(false);
        return false;
      }

      debugPrint('[TokenRefresh] Refreshing access token...');
      final res = await http.post(
        Uri.parse('https://accounts.go.digitable.io/token'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': clientId,
        }),
      );

      debugPrint('[TokenRefresh] status=${res.statusCode}');

      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint('[TokenRefresh] Failed: ${res.body}');
        _refreshCompleter!.complete(false);
        return false;
      }

      final data = jsonDecode(res.body);
      final newAccess = data['access_token']?.toString() ?? '';
      final newRefresh = data['refresh_token']?.toString() ?? refreshToken;

      if (newAccess.isEmpty) {
        debugPrint('[TokenRefresh] Response missing access_token.');
        _refreshCompleter!.complete(false);
        return false;
      }

      // --- Persist both tokens exclusively in encrypted storage
      await SecureTokenService.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      debugPrint('[TokenRefresh] Tokens refreshed and stored securely.');
      _refreshCompleter!.complete(true);
      return true;
    } catch (e) {
      debugPrint('[TokenRefresh] Exception: $e');
      _refreshCompleter?.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  /// Ensures a non-expired access token is available.  Silently refreshes
  /// using the refresh token when the current token has expired.
  /// Returns true when a valid (or freshly refreshed) token exists.
  Future<bool> _ensureValidToken() async {
    try {
      await storage.ready;
      final token = await SecureTokenService.getAccessToken();
      if (token.isEmpty) return false;
      if (!_isJwtExpired(token)) return true;
      debugPrint('[TokenRefresh] Token expired — refreshing proactively...');
      return await _refreshAccessToken();
    } catch (_) {
      return false;
    }
  }

  // ── End token-refresh machinery ─────────────────────────────────────────

  Future<String?> ensureUidFromAccessToken() async {
    await storage.ready;
    final existing = storage.getItem('uid')?.toString();
    if (existing != null && existing.isNotEmpty) return existing;

    final accessToken = await SecureTokenService.getAccessToken();
    if (accessToken.isEmpty) return null;

    final payload = _decodeJwtPayload(accessToken);
    if (payload == null) return null;

    final uid = (payload['user_id'] ?? payload['sub'] ?? '').toString();
    if (uid.isEmpty) return null;

    await storage.setItem('uid', uid);
    return uid;
  }

  Future<List<AttendanceModel>> getAttendanceForUserMonth(
      {String? userId, String? payroll}) async {
    try {
      await storage.ready;

      bool looksLikeMongoId(String s) =>
          RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(s);

      String uid = (userId ?? '').toString();
      if (!looksLikeMongoId(uid)) uid = '';
      if (uid.isEmpty) {
        final stored = storage.getItem('human_user_id')?.toString() ?? '';
        if (looksLikeMongoId(stored)) uid = stored;
      }
      if (uid.isEmpty) {
        final candidate = storage.getItem('uid')?.toString() ?? '';
        if (looksLikeMongoId(candidate)) uid = candidate;
      }

      // Try bearer profile to obtain _id
      if (uid.isEmpty) {
        final me = await fetchMeProfileWithBearer();
        final dataAny = me?['data'] ?? me?['result'] ?? me?['user'];
        if (dataAny is Map) {
          final id = (dataAny['_id'] ?? dataAny['id'] ?? '').toString();
          if (looksLikeMongoId(id)) {
            uid = id;
            await storage.setItem('human_user_id', uid);
          }
        }
      }

      if (uid.isEmpty) return [];
      final tenant = await _resolveTenant() ?? '';
      String baseUrl;
      if (tenant.isNotEmpty) {
        baseUrl = '${this.baseUrl}/attendance/user/$tenant/$uid/';
      } else {
        baseUrl = '${this.baseUrl}/attendance/user/$uid/';
      }
      final p = (payroll ?? '').trim();
      final qParams = <String, String>{};
      if (p.isNotEmpty) qParams['payroll'] = p;
      if (tenant.isNotEmpty) qParams['tenant'] = tenant;
      qParams['mobile'] = 'true';

      final uri = await _uriWithTenant(baseUrl, qParams);
      final token = SecureTokenService.getOauthTokenSync();
      final access = SecureTokenService.getAccessTokenSync();

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (token.isNotEmpty) headers['Oauth-Token'] = token;
      if (access.isNotEmpty) headers['Authorization'] = 'Bearer $access';

      final response = await http.get(uri, headers: headers);
      debugPrint('[ATT] GET $uri status=${response.statusCode}');
      debugPrint('[ATT] body=${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        try {
          final err = json.decode(response.body);
          if (err is Map && (err['message']?.toString().isNotEmpty ?? false)) {
            showToast(err['message'].toString());
          } else {
            // showToast('Failed to load attendance');
          }
        } catch (_) {
          //showToast('Failed to load attendance');
        }
        return [];
      }

      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['success'] == false) {
        try {
          final msg = decoded['message']?.toString();
          if (msg != null && msg.isNotEmpty) showToast(msg);
        } catch (_) {}
        return [];
      }

      if (decoded is Map && decoded['data'] is Map) {
        final data = Map<String, dynamic>.from(decoded['data']);
        final out = <AttendanceModel>[];

        DateTime? parseCheckedAt(String s) {
          try {
            String normalized = s;
            final match = RegExp(r'([+-])(\d{2})(\d{2})$').firstMatch(s);
            if (match != null) {
              final sign = match.group(1);
              final hr = match.group(2);
              final min = match.group(3);
              normalized = s.substring(0, match.start) + '$sign$hr:$min';
            }
            return DateTime.parse(normalized);
          } catch (_) {
            try {
              final ymd = s.substring(0, 10);
              return DateTime.parse(ymd);
            } catch (__) {
              return null;
            }
          }
        }

        String fmtDate(DateTime d) =>
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

        String fmtTime(int seconds) {
          final d = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
        }

        String fmtDow(DateTime d) {
          const dows = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
          return dows[d.weekday % 7];
        }

        if (data['records'] is List) {
          for (final e in (data['records'] as List)) {
            if (e is! Map) continue;
            final raw = Map<String, dynamic>.from(e);
            final normalized = _normalizeAttendanceV2Record(raw);
            try {
              out.add(AttendanceModel.fromJson(normalized));
            } catch (err) {
              debugPrint('[ATT] skip record parse error => $err');
            }
          }
        }

        if (data['pending'] is List) {
          final pendingPunchesByDay = <String, List<Map<String, dynamic>>>{};
          for (final e in (data['pending'] as List)) {
            if (e is! Map) continue;
            final typeStr = e['type']?.toString();
            if (typeStr != 'remote_attendance') continue;

            final payload = e['payload'];
            if (payload is! Map) continue;

            final checkedAtStr = payload['checked_at']?.toString() ?? '';
            if (checkedAtStr.isEmpty) continue;

            final dt = parseCheckedAt(checkedAtStr);
            if (dt == null) continue;

            final dayStr = fmtDate(dt);
            pendingPunchesByDay.putIfAbsent(dayStr, () => []);
            pendingPunchesByDay[dayStr]!.add({
              'type': payload['type']?.toString() ?? 'in',
              'time': dt.millisecondsSinceEpoch ~/ 1000,
              'meta': payload,
            });
          }

          pendingPunchesByDay.forEach((dayStr, punches) {
            punches.sort((a, b) => (a['time'] as int).compareTo(b['time'] as int));

            final firstPunch = punches.first;
            final dt = DateTime.fromMillisecondsSinceEpoch((firstPunch['time'] as int) * 1000);
            final dowStr = fmtDow(dt);

            int? inEpoch;
            int? outEpoch;
            for (final p in punches) {
              if (p['type'] == 'in' && inEpoch == null) inEpoch = p['time'] as int;
              if (p['type'] == 'out') outEpoch = p['time'] as int;
            }
            if (punches.length == 1 && punches.first['type'] == 'out') {
              outEpoch = punches.first['time'] as int;
            }

            final String? inTime = inEpoch != null ? fmtTime(inEpoch) : null;
            final String? outTime = outEpoch != null ? fmtTime(outEpoch) : null;

            final normalized = <String, dynamic>{
              'id': 'pending_$dayStr',
              'day': dayStr,
              'dow': dowStr,
              'type': 'remote_attendance',
              'remote': true,
              'attendance': punches,
              'workedHours': ' - ',
              'workedSeconds': 0,
              'isPending': true,
              'isOffday': false,
              'boilerPlate': <String, dynamic>{
                'day': dayStr,
                'dow': dowStr,
                'in_time_only': inTime,
                'out_time_only': outTime,
                'wrkd_hours_fmtd': ' - ',
                'workedSeconds': 0,
                'worked_hours': 0,
                'location': punches.first['meta']?['site_name'] ?? 'Remote',
                'late': null,
                'over': null,
                'firstCheckIn': inEpoch ?? punches.first['time'],
                'isPending': true,
              }
            };

            try {
              out.add(AttendanceModel.fromJson(normalized));
            } catch (err) {
              debugPrint('[ATT] skip pending record parse error => $err');
            }
          });
        }

        return out;
      }

      if (decoded is List) {
        return decoded
            .map((e) => AttendanceModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      return [];
    } catch (e, st) {
      debugPrint('[ATT] getAttendanceForUserMonth ERROR => $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<List<AttendanceModel>> getAttendanceForUser(String userId) async {
    return await getAttendanceForUserMonth(userId: userId);
  }

  int _toSeconds(int epoch) => epoch > 100000000000 ? epoch ~/ 1000 : epoch;

  String _fmtWorked(String raw, {int? fallbackSeconds}) {
    final s = raw.trim();
    if (s.isNotEmpty && s != '-' && s != ' - ') {
      // Already "Xh Ym"
      if (RegExp(r'^\d+\s*h\s*(\d+\s*m?)?$').hasMatch(s)) return s;
      // "HH:MM:SS" or "HH:MM"
      final colonParts = s.split(':');
      if (colonParts.length >= 2) {
        final h = int.tryParse(colonParts[0]) ?? 0;
        final m = int.tryParse(colonParts[1]) ?? 0;
        return '${h}h ${m}m';
      }
      // Decimal hours ("8.5") or whole-hour string ("8")
      final d = double.tryParse(s);
      if (d != null) {
        final h = d.floor();
        final m = ((d - h) * 60).round();
        return '${h}h ${m}m';
      }
    }
    // Fall back to computed seconds
    if (fallbackSeconds != null && fallbackSeconds > 0) {
      final h = fallbackSeconds ~/ 3600;
      final m = (fallbackSeconds % 3600) ~/ 60;
      return '${h}h ${m}m';
    }
    return '';
  }

  Map<String, dynamic> _normalizeAttendanceV2Record(Map<String, dynamic> r) {
    final att = (r['attendance'] is List)
        ? List<dynamic>.from(r['attendance'])
        : <dynamic>[];

    int? inEpoch;
    int? outEpoch;
    for (final p in att) {
      if (p is! Map) continue;
      final type = (p['type'] ?? '').toString();
      final t = p['time'];
      int? raw = (t is int)
          ? t
          : (t is num ? t.toInt() : int.tryParse(t?.toString() ?? ''));
      if (raw == null) continue;
      final epoch = _toSeconds(raw);
      if (type == 'in' && inEpoch == null) inEpoch = epoch; // first check-in
      if (type == 'out') outEpoch = epoch; // keep overwriting → last check-out
    }

    // Also accept direct fields when attendance punch array is absent
    if (inEpoch == null) {
      final t = r['in_time'] ?? r['check_in'] ?? r['punch_in'];
      if (t != null) {
        final raw =
            t is int ? t : (t is num ? t.toInt() : int.tryParse(t.toString()));
        if (raw != null) inEpoch = _toSeconds(raw);
      }
    }
    if (outEpoch == null) {
      final t = r['out_time'] ?? r['check_out'] ?? r['punch_out'];
      if (t != null) {
        final raw =
            t is int ? t : (t is num ? t.toInt() : int.tryParse(t.toString()));
        if (raw != null) outEpoch = _toSeconds(raw);
      }
    }

    DateTime? base;
    if (inEpoch != null)
      base = DateTime.fromMillisecondsSinceEpoch(inEpoch * 1000);
    if (base == null && outEpoch != null)
      base = DateTime.fromMillisecondsSinceEpoch(outEpoch * 1000);

    String fmtDate(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    String fmtTime(int seconds) {
      final d = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    String fmtDow(DateTime d) {
      const dows = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return dows[d.weekday % 7];
    }

    final dayStr = base != null ? fmtDate(base) : '';
    final dowStr = base != null ? fmtDow(base) : '';

    final workedRaw = (r['workedHours'] ?? r['worked_hours'] ?? '').toString();
    final workedSeconds =
        (r['workedSeconds'] ?? r['worked_seconds'] ?? r['worked_hours']);

    // Compute seconds from punch timestamps when available
    int? computedWorkedSeconds;
    if (inEpoch != null && outEpoch != null && outEpoch > inEpoch) {
      computedWorkedSeconds = outEpoch - inEpoch;
    }

    // Normalise to "Xh Ym" — prefer API string, fall back to computed seconds
    final wrkdFmtd =
        _fmtWorked(workedRaw, fallbackSeconds: computedWorkedSeconds);

    // Try extract a location label from punch meta
    String? sensorPool;
    try {
      for (final p in att) {
        if (p is! Map) continue;
        final metaAny = p['meta'];
        if (metaAny is Map && metaAny['sensor_pool'] != null) {
          sensorPool = metaAny['sensor_pool']?.toString();
          if (sensorPool != null && sensorPool.isNotEmpty) break;
        }
      }
    } catch (_) {}

    return <String, dynamic>{
      // Keep original r fields too
      ...r,

      // Ensure string-ish fields exist
      'id': (r['id'] ?? r['_id'] ?? '').toString(),
      'day': dayStr,
      'dow': dowStr,
      'workedHours': wrkdFmtd,

      // Provide boilerPlate used by UI
      'boilerPlate': <String, dynamic>{
        'day': dayStr,
        'dow': dowStr,
        'in_time_only': inEpoch != null ? fmtTime(inEpoch) : null,
        'out_time_only': outEpoch != null ? fmtTime(outEpoch) : null,
        'wrkd_hours_fmtd': wrkdFmtd.isNotEmpty ? wrkdFmtd : null,
        'workedSeconds': computedWorkedSeconds ?? workedSeconds,
        'worked_hours': computedWorkedSeconds ?? workedSeconds,
        'location': sensorPool,
        'late': null,
        'over': null,
      },
    };
  }

  Future<String?> getProfilePhotoUrl({String size = '150-150'}) async {
    try {
      await storage.ready;

      // Get UID and filename from storage
      final uid = storage.getItem('uid')?.toString() ?? '';
      final fileName =
          storage.getItem('profile_photo_filename')?.toString() ?? '';

      debugPrint('[PHOTO] UID: $uid');
      debugPrint('[PHOTO] Filename: $fileName');

      if (uid.isEmpty || fileName.isEmpty) {
        debugPrint('[PHOTO] ❌ Missing UID or filename');
        return null;
      }
      // Compute document base by removing only a trailing `/api` path segment
      String documentBaseUrl = baseUrl;
      try {
        final parsed = Uri.parse(baseUrl);
        final segments = List<String>.from(parsed.pathSegments);
        if (segments.isNotEmpty && segments.last == 'api')
          segments.removeLast();
        final baseUri = Uri(
          scheme: parsed.scheme,
          userInfo: parsed.userInfo,
          host: parsed.host,
          port: parsed.hasPort ? parsed.port : null,
          pathSegments: segments,
        );
        documentBaseUrl = baseUri.toString().replaceAll(RegExp(r'\/$'), '');
      } catch (e) {
        documentBaseUrl = baseUrl.replaceAll(RegExp(r'\/api$'), '');
      }

      // Build URL: {BASE}/documents/view/{userId}/{fileName}?size=150-150
      final url = '$documentBaseUrl/documents/view/$uid/$fileName?size=$size';

      debugPrint('[PHOTO] ✅ Generated URL: $url');
      return url;
    } catch (e, st) {
      debugPrint('[PHOTO] ❌ Error: $e');
      debugPrint('[PHOTO] Stack trace: $st');
      return null;
    }
  }

  /// Public helper that attempts multiple URL patterns and returns the first
  /// working profile photo URL (performs HEAD checks).
  Future<String?> getResolvedProfilePhotoUrl({String size = '150-150'}) async {
    try {
      await storage.ready;
      final uid = storage.getItem('uid')?.toString() ?? '';
      final fileName =
          storage.getItem('profile_photo_filename')?.toString() ?? '';
      if (uid.isEmpty || fileName.isEmpty) return null;
      final resolved = await _tryMultipleUrlPatterns(uid, fileName, size);
      return resolved;
    } catch (e) {
      debugPrint('[PHOTO] ❌ getResolvedProfilePhotoUrl error: $e');
      return null;
    }
  }

  /// Try different URL patterns to find the correct one
  Future<String?> _tryMultipleUrlPatterns(
      String uid, String fileName, String size) async {
    // Compute a clean base URL and a document base (without final '/api')
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    String documentBase = cleanBaseUrl;
    try {
      final parsed = Uri.parse(cleanBaseUrl);
      final segs = List<String>.from(parsed.pathSegments);
      if (segs.isNotEmpty && segs.last == 'api') segs.removeLast();
      final baseUri = Uri(
        scheme: parsed.scheme,
        userInfo: parsed.userInfo,
        host: parsed.host,
        port: parsed.hasPort ? parsed.port : null,
        pathSegments: segs,
      );
      documentBase = baseUri.toString().replaceAll(RegExp(r'\/$'), '');
    } catch (e) {
      documentBase = cleanBaseUrl.replaceAll(RegExp(r'\/api$'), '');
    }

    // Try different URL patterns
    final urlPatterns = [
      // Pattern 1: baseUrl/documents/view/uid/filename?size=150-150
      '$cleanBaseUrl/documents/view/$uid/$fileName?size=$size',

      // Pattern 2: documentBase/documents/view/uid/filename?size=150-150
      if (documentBase.isNotEmpty)
        '$documentBase/documents/view/$uid/$fileName?size=$size',

      // Pattern 3: baseUrl/uploads/profile/uid/filename?size=150-150
      '$cleanBaseUrl/uploads/profile/$uid/$fileName?size=$size',

      // Pattern 4: Try with thumb_image if available (both bases)
      '$cleanBaseUrl/documents/view/$uid/${fileName.replaceAll('.png', '.png-thumb.png')}?size=$size',
      if (documentBase.isNotEmpty)
        '$documentBase/documents/view/$uid/${fileName.replaceAll('.png', '.png-thumb.png')}?size=$size',
    ];

    for (final url in urlPatterns) {
      debugPrint('[PHOTO] 🔍 Trying URL: $url');

      try {
        // Test if URL is accessible
        final uri = Uri.parse(url);
        // Resolve tenant header if available
        final tenant = await _resolveTenant() ?? '';
        final headers = {
          'Accept': 'image/*',
          if (SecureTokenService.getOauthTokenSync().isNotEmpty)
            'Oauth-Token': SecureTokenService.getOauthTokenSync(),
          if (SecureTokenService.getAccessTokenSync().isNotEmpty)
            'Authorization':
                'Bearer ${SecureTokenService.getAccessTokenSync()}',
          if (tenant.isNotEmpty) 'Tenant': tenant,
        };

        final request = await http.Client().head(uri, headers: headers);

        if (request.statusCode == 200) {
          debugPrint('[PHOTO] ✅ Found working URL: $url');
          return url;
        } else {
          debugPrint('[PHOTO] ❌ URL returned ${request.statusCode}: $url');
        }
      } catch (e) {
        debugPrint('[PHOTO] ❌ URL failed: $url - $e');
      }
    }

    // If no URL works, return the first pattern as default
    debugPrint('[PHOTO] ⚠️ No working URL found, using fallback pattern');
    // Prefer the documentBase pattern if available, otherwise return the first pattern
    try {
      final parsed = Uri.parse(cleanBaseUrl);
      final segs = List<String>.from(parsed.pathSegments);
      if (segs.isNotEmpty && segs.last == 'api') segs.removeLast();
      final baseUri = Uri(
        scheme: parsed.scheme,
        userInfo: parsed.userInfo,
        host: parsed.host,
        port: parsed.hasPort ? parsed.port : null,
        pathSegments: segs,
      );
      final documentBase = baseUri.toString().replaceAll(RegExp(r'\/$'), '');
      if (documentBase.isNotEmpty) {
        return '$documentBase/documents/view/$uid/$fileName?size=$size';
      }
    } catch (_) {}

    return urlPatterns[0];
  }

  Future<Map<String, dynamic>> getSalarySlips() async {
    try {
      await storage.ready;

      // Resolve uid from storage / access token / bearer profile
      String uid = storage.getItem('uid')?.toString() ?? '';
      if (uid.isEmpty) {
        uid = await ensureUidFromAccessToken() ?? '';
      }
      if (uid.isEmpty) {
        final me = await fetchMeProfileWithBearer();
        final dataAny = me?['data'] ?? me?['result'] ?? me?['user'];
        if (dataAny is Map) {
          uid = (dataAny['_id'] ?? dataAny['id'] ?? '').toString();
          if (uid.isNotEmpty) await storage.setItem('uid', uid);
        }
      }

      if (uid.isEmpty) {
        debugPrint('[SLIPS] missing uid, cannot fetch slips');
        return {
          'slips': [],
          'statusCode': 400,
          'message': 'Missing user session'
        };
      }

      final url = '${baseUrl}/payroll/salary-slips/user/$uid';

      final tenant = await _resolveTenant() ?? '';
      final qParams = <String, String>{};
      if (tenant.isNotEmpty) qParams['tenant'] = tenant;

      final uri = await _uriWithTenant(url, qParams);

      final oauthToken = SecureTokenService.getOauthTokenSync();
      final accessToken = SecureTokenService.getAccessTokenSync();

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (oauthToken.isNotEmpty) headers['Oauth-Token'] = oauthToken;
      if (accessToken.isNotEmpty)
        headers['Authorization'] = 'Bearer $accessToken';

      debugPrint('[SLIPS] GET $uri');
      final res = await http.get(uri, headers: headers);

      debugPrint('[SLIPS] status=${res.statusCode}');
      debugPrint('[SLIPS] body=${res.body}');

      final decoded = jsonDecode(res.body);

      // Handle explicit error responses correctly and return status mappings rather than strictly throwing UI toasts directly from the service layer
      if (res.statusCode >= 400) {
        return {
          'slips': [],
          'statusCode': res.statusCode,
          'message': 'serverError'
        };
      }

      List<Map<String, dynamic>> out = <Map<String, dynamic>>[];

      // Parse the new standard response structure
      if (decoded is Map && decoded['success'] == true) {
        final dataAny = decoded['data'];
        if (dataAny is Map && dataAny['items'] is List) {
          out = (dataAny['items'] as List).map((e) {
            if (e is Map) return Map<String, dynamic>.from(e);
            return <String, dynamic>{'raw': e};
          }).toList();
        } else if (dataAny is Map && dataAny['data'] is List) {
          out = (dataAny['data'] as List).map((e) {
            if (e is Map) return Map<String, dynamic>.from(e);
            return <String, dynamic>{'raw': e};
          }).toList();
        }
      } else if (decoded is List) {
        out = decoded.map((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return <String, dynamic>{'raw': e};
        }).toList();
      }

      return {'slips': out, 'statusCode': res.statusCode, 'message': 'Success'};
    } catch (e, st) {
      debugPrint('[SLIPS] ERROR => $e');
      debugPrint(st.toString());
      return {'slips': [], 'statusCode': 500, 'message': 'serverError', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSalarySlipDetail(String id) async {
    try {
      await storage.ready;
      String uid = storage.getItem('uid')?.toString() ?? '';
      if (uid.isEmpty) return {};

      // Standard API URL string structure
      final url = '${baseUrl}/payroll/salary-slips/$id';

      final tenant = await _resolveTenant() ?? '';
      final qParams = <String, String>{};
      if (tenant.isNotEmpty) qParams['tenant'] = tenant;

      final uri = await _uriWithTenant(url, qParams);

      final oauthToken = SecureTokenService.getOauthTokenSync();
      final accessToken = SecureTokenService.getAccessTokenSync();

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (oauthToken.isNotEmpty) headers['Oauth-Token'] = oauthToken;
      if (accessToken.isNotEmpty)
        headers['Authorization'] = 'Bearer $accessToken';

      final res = await http.get(uri, headers: headers);
      debugPrint('[SLIP DETAIL] GET $uri status=${res.statusCode}');
      debugPrint('[SLIP DETAIL] body=${res.body}');

      final decoded = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        return {'statusCode': res.statusCode, 'message': 'serverError'};
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (decoded is Map && decoded['success'] == true) {
          final dataMap = decoded['data'];
          // Check if standard detailed map is returned directly in data
          if (dataMap is Map) {
            if (dataMap.containsKey('items')) {
              final items = dataMap['items'];
              if (items is List && items.isNotEmpty) {
                final outM = Map<String, dynamic>.from(items[0]);
                outM['statusCode'] = res.statusCode;
                return outM;
              }
            }
            // Check if the data block itself is exactly the object payload!
            final outM2 = Map<String, dynamic>.from(dataMap);
            outM2['statusCode'] = res.statusCode;
            return outM2;
          } else if (dataMap is List && dataMap.isNotEmpty) {
            final outM3 = Map<String, dynamic>.from(dataMap[0]);
            outM3['statusCode'] = res.statusCode;
            return outM3;
          }
        }
      }
      return {'statusCode': res.statusCode};
    } catch (e) {
      debugPrint('[SLIP DETAIL] Error => $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> emailSalarySlip(String id) async {
    try {
      await storage.ready;

      // Updated download endpoint structure
      final url = '${baseUrl}/payroll/salary-slips/$id/download';
      final oauthToken = SecureTokenService.getOauthTokenSync();
      final accessToken = SecureTokenService.getAccessTokenSync();

      final tenant = await _resolveTenant() ?? '';
      final qParams = <String, String>{};
      if (tenant.isNotEmpty) qParams['tenant'] = tenant;

      final uri = await _uriWithTenant(url, qParams);

      debugPrint('[SLIP] ==== EMAIL SALARY SLIP START ====');
      debugPrint('[SLIP] ID: $id');
      debugPrint('[SLIP] URL: $uri');

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (oauthToken.isNotEmpty) {
        headers['Oauth-Token'] = oauthToken;
        debugPrint('[SLIP] Oauth-Token present');
      }

      if (accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
        debugPrint('[SLIP] Access-Token present');
      }

      debugPrint('[SLIP] Sending GET request...');

      // Note: Download requests are typically GET. If it was POST before, it's switched to GET here
      final res = await http.get(uri, headers: headers);

      debugPrint('[SLIP] Response Status: ${res.statusCode}');
      // Truncate response body log in case it is a raw PDF byte stream
      debugPrint('[SLIP] Response Body Length: ${res.bodyBytes.length}');
      debugPrint('[SLIP] ==== RESPONSE RECEIVED ====');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {
          'status': true,
          'message': 'Success',
          'data': res
              .bodyBytes, // This returns raw bytes, which can be handled by the UI to save/share
        };
      }

      // Non-2xx response
      return {
        'status': false,
        'message': 'serverError',
        'statusCode': res.statusCode
      };
    } catch (e, st) {
      debugPrint('[SLIP] EXCEPTION: $e');
      debugPrint('[SLIP] STACKTRACE: $st');

      return {'status': false, 'message': 'serverError', 'error': e.toString()};
    }
  }

  Future<List<UserLocation>> getTenantCoordinateFromQr(
    String userId, {
    String? tenant,
  }) async {
    try {
      await storage.ready;

      // 🔹 Ensure userId
      if (userId.isEmpty) {
        userId = storage.getItem('uid')?.toString() ?? '';
      }

      if (userId.isEmpty) {
        final ensured = await ensureUidFromAccessToken();
        if (ensured != null && ensured.isNotEmpty) {
          userId = ensured;
          await storage.setItem('uid', userId);
        }
      }

      if (userId.isEmpty) {
        debugPrint('[QR] Missing userId');
        return [];
      }

      // 🔹 Build URL
      final endpoint = '$baseUrl/teams/locations-by-userid/$userId';
      final uri = Uri.parse(endpoint);

      final accessToken = SecureTokenService.getAccessTokenSync();

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final resolvedTenant = tenant ?? await _resolveTenant();
      if (resolvedTenant != null && resolvedTenant.isNotEmpty) {
        headers['Tenant'] = resolvedTenant;
      }

      debugPrint('[API] GET $uri');

      final response = await http.get(uri, headers: headers);

      debugPrint('[API] Status: ${response.statusCode}');
      debugPrint('[API] Body: ${response.body}');

      if (response.statusCode != 200) {
        throw HttpException('Server returned status code: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        throw HttpException('Server success: false');
      }

      final nestedData = decoded['data'];

      if (nestedData == null || nestedData['success'] != true) {
        throw HttpException('Nested success: false');
      }

      final List<dynamic> locationList = nestedData['data'] ?? [];

      final List<UserLocation> result = locationList
          .map((e) => UserLocation.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      debugPrint(locationList.toString());
      
      // Save last backend coordinates locally for offline fallback
      try {
        await storage.setItem('cached_tenant_coordinates', jsonEncode(locationList));
      } catch (cacheErr) {
        debugPrint('[QR CACHE SAVE ERROR] $cacheErr');
      }

      return result;
    } catch (e, stack) {
      debugPrint('[API ERROR] $e');
      debugPrint(stack.toString());
      
      // Fallback to cached coordinates if backend request fails
      try {
        await storage.ready;
        final cached = storage.getItem('cached_tenant_coordinates');
        if (cached != null) {
          final List<dynamic> cachedList =
              (cached is String) ? jsonDecode(cached) : cached;
          final List<UserLocation> cachedResult = cachedList
              .map((e) => UserLocation.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          debugPrint('[QR CACHE] Using cached tenant coordinates (${cachedResult.length} locations) due to API failure.');
          return cachedResult;
        }
      } catch (cacheErr) {
        debugPrint('[QR CACHE READ ERROR] Failed reading cached coordinates: $cacheErr');
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyTeam() async {
    await storage.ready;
    final accessToken = SecureTokenService.getAccessTokenSync();
    final tenant = storage.getItem('tenant')?.toString() ?? '';

    final url = '$baseUrl/teams/my-team?tenant=$tenant';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    return _handleApiResponse(response, 'getMyTeam');
  }

  Future<Map<String, dynamic>> getTeamMemberLeaves(String userId) async {
    await storage.ready;
    final accessToken = SecureTokenService.getAccessTokenSync();
    final tenant = storage.getItem('tenant')?.toString() ?? '';

    final url = '${baseUrl}/teams/my-team/leaves?tenant=$tenant';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    return _handleApiResponse(response, 'getTeamMemberLeaves');
  }

  Future<Map<String, dynamic>> approveLeave(String leaveId) async {
    await storage.ready;
    final accessToken = SecureTokenService.getAccessTokenSync();
    final tenant = storage.getItem('tenant')?.toString() ?? '';

    final url = '${baseUrl}/leave/$leaveId/approve?tenant=$tenant';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    return _handleApiResponse(response, 'approveLeave');
  }

  Future<Map<String, dynamic>> rejectLeave(
      String leaveId, String reason) async {
    await storage.ready;
    final accessToken = SecureTokenService.getAccessTokenSync();
    final tenant = storage.getItem('tenant')?.toString() ?? '';

    final url = '${baseUrl}/leave/$leaveId/reject?tenant=$tenant';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );

    return _handleApiResponse(response, 'rejectLeave');
  }

  Future<Map<String, dynamic>> approveTodo(String todoId) async {
    await storage.ready;
    final accessToken = SecureTokenService.getAccessTokenSync();
    final tenant = storage.getItem('tenant')?.toString() ?? '';

    final url = '${baseUrl}/todos/$todoId/update?tenant=$tenant';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': todoId,
        'action': 'complete',
      }),
    );

    debugPrint('[approveTodo] Response Body: ${response.body}');
    return _handleApiResponse(response, 'approveTodo');
  }


  Future<Map<String, dynamic>> rejectTodo(String todoId, String reason) async {
    await storage.ready;
    final accessToken = SecureTokenService.getAccessTokenSync();
    final tenant = storage.getItem('tenant')?.toString() ?? '';

    final url = '${baseUrl}/todos/$todoId/update?tenant=$tenant';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': todoId,
        'action': 'reject',
        'reason': reason,
      }),
    );

    return _handleApiResponse(response, 'rejectTodo');
  }

  Future<Map<String, dynamic>> markAttendance(
      String userId, String date, String checkIn, String checkOut) async {
    await storage.ready;
    final accessToken = SecureTokenService.getAccessTokenSync();
    final tenant = storage.getItem('tenant')?.toString() ?? '';
    final appVer = await _getAppVersion();

    final url = '${baseUrl}/attendance/mark?tenant=$tenant';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'app_version': appVer,
        'app-version': appVer,
      },
      body: jsonEncode({
        'userId': userId,
        'date': date,
        'checkIn': checkIn,
        'checkOut': checkOut,
      }),
    );

    return _handleApiResponse(response, 'markAttendance');
  }

  Future<Map<String, dynamic>> getTeamMemberAttendance(String userId) async {
    await storage.ready;
    final accessToken = SecureTokenService.getAccessTokenSync();
    final tenant = storage.getItem('tenant')?.toString() ?? '';
    final appVer = await _getAppVersion();

    final url = '${baseUrl}/teams/my-team/attendance?tenant=$tenant';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'app_version': appVer,
        'app-version': appVer,
      },
    );

    return _handleApiResponse(response, 'getTeamMemberAttendance');
  }

  Future<Map<String, dynamic>> _handleApiResponse(
      http.Response response, String apiName) async {
    debugPrint('[$apiName] Status Code: ${response.statusCode}');
    debugPrint(
        '[$apiName] Response Body: ${response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body}');

    AppUpdateHelper.handlePotentialUpdateRequired(response.statusCode, response.body);

    // If not successful status code
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMsg = 'HTTP ${response.statusCode} Error in $apiName';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          errorMsg = decoded['message'].toString();
        }
      } catch (_) {
        // If not JSON, show raw body (this prevents the <!DOCTYPE html> crash)
        errorMsg = response.body;
      }
      throw Exception(errorMsg);
    }

    // Try to decode JSON
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        throw Exception('Invalid response format from $apiName');
      }
    } catch (e) {
      throw Exception('Failed to parse JSON from $apiName: ${response.body}');
    }
  }


}
