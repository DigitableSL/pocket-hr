import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:localstorage/localstorage.dart';
import 'package:cn_pocket_hr/helpers/logout.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';

class SessionValidator {
  static bool _isLoggingOut = false;
  static final LocalStorage _storage = LocalStorage('pocketHR');

  /// Validates whether the API response indicates an expired session or invalid token.
  /// If expired, automatically forces a logout and displays a localized error message.
  static void validate(http.Response response, {Uri? url}) {
    if (_isLoggingOut) return;

    try {
      final statusCode = response.statusCode;
      final body = response.body;

      bool isSessionExpired = false;

      // 1. Check HTTP status code (401 Unauthorized, 419 Authentication Timeout)
      if (statusCode == 401 || statusCode == 419) {
        isSessionExpired = true;
      }

      // 2. Check response body for session or token expiration messages
      if (!isSessionExpired && body.isNotEmpty) {
        final lowerBody = body.toLowerCase();
        if (lowerBody.contains('session expired') ||
            lowerBody.contains('session has expired') ||
            lowerBody.contains('token expired') ||
            lowerBody.contains('token has expired') ||
            lowerBody.contains('token is invalid') ||
            lowerBody.contains('jwt expired') ||
            lowerBody.contains('session_expired') ||
            lowerBody.contains('token_expired') ||
            lowerBody.contains('unauthenticated') ||
            lowerBody.contains('invalid_grant')) {
          isSessionExpired = true;
        } else {
          try {
            final decoded = jsonDecode(body);
            if (decoded is Map) {
              final msg = (decoded['message'] ??
                      decoded['error'] ??
                      decoded['error_description'] ??
                      decoded['msg'] ??
                      '')
                  .toString()
                  .toLowerCase();
              if (msg.contains('session expired') ||
                  msg.contains('token expired') ||
                  msg.contains('jwt expired') ||
                  msg.contains('unauthenticated') ||
                  msg == 'unauthorized') {
                isSessionExpired = true;
              }
            }
          } catch (_) {}
        }
      }

      if (!isSessionExpired) return;

      // Check if user is currently authenticated to avoid false logouts on login screen
      Future.microtask(() async {
        if (_isLoggingOut) return;

        try {
          await _storage.ready;
          final token = _storage.getItem('access_token')?.toString();
          if (token == null || token.trim().isEmpty) {
            // User is not logged in yet (e.g. invalid credentials on login screen)
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
