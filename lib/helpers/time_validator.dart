import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cn_pocket_hr/helpers/logout.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';

class TimeValidator {
  static bool _isLoggingOut = false;

  static void validate(http.Response response) {
    if (_isLoggingOut) return;

    try {
      DateTime? serverTime;

      // 1. Try to parse from response body JSON "timestamp" field
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('timestamp')) {
          final timestampStr = decoded['timestamp']?.toString();
          if (timestampStr != null && timestampStr.isNotEmpty) {
            serverTime = DateTime.parse(timestampStr);
          }
        }
      } catch (_) {
        // Not a JSON response or failed to parse
      }

      // 2. Fallback to HTTP "Date" header if timestamp body field was not found
      if (serverTime == null) {
        final dateStr = response.headers['date'] ?? response.headers['Date'];
        if (dateStr != null && dateStr.isNotEmpty) {
          try {
            serverTime = HttpDate.parse(dateStr);
          } catch (_) {}
        }
      }

      if (serverTime == null) return;

      // Compare difference in UTC with 3 minute (180 seconds) accuracy
      final difference = DateTime.now().toUtc().difference(serverTime.toUtc()).inSeconds.abs();
      
      debugPrint('[TimeValidator] Server time (UTC): ${serverTime.toUtc()}, Device time (UTC): ${DateTime.now().toUtc()}, Diff: $difference seconds');

      if (difference > 180) { // 3 minutes = 180 seconds
        _isLoggingOut = true;
        
        final errorMessage = _getTimeErrorMessage();
        
        Future.microtask(() {
          LogoutHelper.forceLogout(errorMessage: errorMessage);
        });
      }
    } catch (e) {
      debugPrint('[TimeValidator] Error validating time: $e');
    }
  }

  static String _getTimeErrorMessage() {
    try {
      final context = FCMService.navigatorKey.currentContext;
      if (context != null) {
        final localizations = AppLocalizations.of(context);
        if (localizations != null) {
          return localizations.incorrectDateTimeError;
        }
      }
    } catch (_) {}

    return 'Device date/time is incorrect. Please correct settings and log in again.';
  }

  static void reset() {
    _isLoggingOut = false;
  }
}
