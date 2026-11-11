import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cn_pocket_hr/helpers/logout.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';
import 'package:cn_pocket_hr/services/secure_token_service.dart';

class SessionValidator {
  static bool _isLoggingOut = false;

  /// Validates whether the API response indicates an expired session or invalid token.
  /// If expired and unrecoverable, automatically forces a logout and displays a localized error message.
  static void validate(http.Response response, {Uri? url}) {
    if (_isLoggingOut) return;

    try {
      final statusCode = response.statusCode;

      // Only investigate 4xx / 5xx error responses
      if (statusCode < 400) return;

      final urlStr = url?.toString().toLowerCase() ?? '';
      final isTokenEndpoint =
          urlStr.contains('/token') || urlStr.contains('accounts.');
      final isAuthFlowEndpoint = urlStr.contains('/sso/mobile-start') ||
          urlStr.contains('/sso/mobile-callback');

      // Do not interfere with initial SSO login flow
      if (isAuthFlowEndpoint) return;

      bool isSessionExpired = false;

      // 1. If the token refresh endpoint itself failed (400 Bad Request, 401 Unauthorized, 419 Timeout),
      // the refresh token is invalid or expired.
      if (isTokenEndpoint &&
          (statusCode == 400 || statusCode == 401 || statusCode == 419)) {
        isSessionExpired = true;
      }

      // 2. For general endpoints, rely strictly on authoritative HTTP status codes (401 / 419)
      if (!isSessionExpired && (statusCode == 401 || statusCode == 419)) {
        isSessionExpired = true;
      }

      if (!isSessionExpired) return;

      // Check user session and avoid interrupting silent token refresh
      Future.microtask(() async {
        if (_isLoggingOut) return;

        try {
          final token = await SecureTokenService.getAccessToken();
          if (token.trim().isEmpty) {
            // User is not logged in yet (e.g. invalid credentials on login screen)
            return;
          }

          // If this is a 401 on a normal endpoint and a refresh_token is present,
          // do NOT kill the session immediately; allow APIService to refresh it silently.
          // Only force logout if the token endpoint itself failed, or if no refresh token exists.
          final refreshToken = await SecureTokenService.getRefreshToken();
          if (!isTokenEndpoint && refreshToken.trim().isNotEmpty) {
            debugPrint(
                '[SessionValidator] 401 received on regular endpoint ($url). Refresh token is available; deferring to silent refresh.');
            return;
          }
        } catch (_) {}

        _isLoggingOut = true;
        debugPrint(
            '[SessionValidator] Session expired detected (status: $statusCode, url: $url). Forcing logout.');

        final errorMessage = _getSessionExpiredMessage();

        await LogoutHelper.forceLogout(errorMessage: errorMessage);
      });
    } catch (e) {
      debugPrint('[SessionValidator] Error validating session: $e');
    }
  }

  static String _getSessionExpiredMessage() {
    try {
      final context = FCMService.navigatorKey.currentContext;
      if (context != null) {
        final localizations = AppLocalizations.of(context);
        if (localizations != null) {
          return localizations.sessionExpired;
        }
      }
    } catch (_) {}

    return 'Session expired. Please log in again.';
  }

  static void reset() {
    _isLoggingOut = false;
  }
}
