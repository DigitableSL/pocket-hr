import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as origin_http;
import 'package:localstorage/localstorage.dart';
import 'package:cn_pocket_hr/helpers/session_validator.dart';
import 'package:cn_pocket_hr/services/secure_token_service.dart';

/// Process-wide singleton token refresh coordinator.
///
/// Guarantees that concurrent expired-token requests across all [APIService]
/// instances and HTTP callers share a single `/token` exchange, preventing
/// rotating-refresh-token race conditions.
class TokenRefreshService {
  TokenRefreshService._();

  static const int jwtExpirySkewSeconds = 60;
  static const String _clientIdStorageKey = 'sso_client_id';
  static final LocalStorage _storage = LocalStorage('pocketHR');

  static bool _isRefreshing = false;
  static Completer<bool>? _refreshCompleter;

  static Map<String, dynamic>? decodeJwtPayload(String token) {
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

  static bool isJwtExpired(
    String token, {
    int skewSeconds = jwtExpirySkewSeconds,
  }) {
    try {
      final payload = decodeJwtPayload(token);
      if (payload == null) return true;
      final expAny =
          payload['exp'] ?? payload['expiry'] ?? payload['expires_at'];
      if (expAny == null) return true;
      int expSec;
      if (expAny is int) {
        expSec = expAny;
      } else if (expAny is double) {
        expSec = expAny.toInt();
      } else {
        expSec = int.tryParse(expAny.toString()) ?? 0;
      }
      if (expSec <= 0) return true;
      final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      return expSec <= (nowSec + skewSeconds);
    } catch (_) {
      return true;
    }
  }

  /// Ensures a non-expired access token is available, refreshing proactively
  /// within [jwtExpirySkewSeconds] of expiry.
  static Future<bool> ensureValidToken() async {
    try {
      final token = await SecureTokenService.getAccessToken();
      if (token.isEmpty) return false;
      if (!isJwtExpired(token)) return true;
      debugPrint('[TokenRefresh] Token expired or expiring soon — refreshing...');
      return await refreshAccessToken();
    } catch (_) {
      return false;
    }
  }

  /// Alias used by startup/session checks.
  static Future<bool> hasValidAccessToken() => ensureValidToken();

  /// Silently exchanges the stored `refresh_token` for a new `access_token`.
  /// Serialised process-wide so concurrent callers await the same in-flight call.
  static Future<bool> refreshAccessToken() async {
    if (_isRefreshing && _refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    _isRefreshing = true;
    final completer = Completer<bool>();
    _refreshCompleter = completer;

    void finish(bool result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    try {
      try {
        await _storage.ready;
      } catch (_) {}

      final refreshToken = await SecureTokenService.getRefreshToken();
      if (refreshToken.trim().isEmpty) {
        debugPrint('[TokenRefresh] No refresh_token — cannot refresh.');
        finish(false);
        return false;
      }

      // Extract client_id from current access token JWT payload, with stored fallback.
      String clientId = '';
      final currentToken = await SecureTokenService.getAccessToken();
      if (currentToken.isNotEmpty) {
        clientId =
            decodeJwtPayload(currentToken)?['client_id']?.toString().trim() ??
                '';
      }
      if (clientId.isNotEmpty) {
        try {
          await _storage.setItem(_clientIdStorageKey, clientId);
        } catch (_) {}
      } else {
        try {
          clientId =
              _storage.getItem(_clientIdStorageKey)?.toString().trim() ?? '';
        } catch (_) {}
      }

      if (clientId.isEmpty) {
        debugPrint('[TokenRefresh] No client_id available — cannot refresh.');
        finish(false);
        return false;
      }

      debugPrint('[TokenRefresh] Refreshing access token...');
      final tokenUri = Uri.parse('https://accounts.go.digitable.io/token');
      final res = await origin_http
          .post(
            tokenUri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'grant_type': 'refresh_token',
              'refresh_token': refreshToken,
              'client_id': clientId,
            }),
          )
          .timeout(const Duration(seconds: 8));

      debugPrint('[TokenRefresh] status=${res.statusCode}');
      SessionValidator.validate(res, url: tokenUri);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint('[TokenRefresh] Failed: ${res.body}');
        finish(false);
        return false;
      }

      final data = jsonDecode(res.body);
      final newAccess = data['access_token']?.toString().trim() ?? '';
      final rawRefresh = data['refresh_token']?.toString().trim() ?? '';
      final newRefresh = rawRefresh.isNotEmpty ? rawRefresh : refreshToken;

      if (newAccess.isEmpty) {
        debugPrint('[TokenRefresh] Response missing access_token.');
        finish(false);
        return false;
      }

      // Persist client_id from the fresh token as well.
      final freshClientId =
          decodeJwtPayload(newAccess)?['client_id']?.toString().trim() ?? '';
      if (freshClientId.isNotEmpty) {
        try {
          await _storage.setItem(_clientIdStorageKey, freshClientId);
        } catch (_) {}
      }

      await SecureTokenService.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      debugPrint('[TokenRefresh] Tokens refreshed and stored securely.');
      finish(true);
      return true;
    } catch (e) {
      debugPrint('[TokenRefresh] Exception: $e');
      finish(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }
}

