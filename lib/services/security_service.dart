import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cn_pocket_hr/helpers/logout.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';

class SecurityService {
  static const MethodChannel _channel =
      MethodChannel('asia.ceynet.pocket/security');

  static bool _isEnforcing = false;

  /// Verifies device developer mode and mock location status.
  /// If a violation is detected, shows an error message and logs out the user.
  /// Returns `true` if device is clean and secure, `false` if violation was found.
  static Future<bool> verifyDeviceSecurity({
    Position? currentPosition,
    BuildContext? context,
  }) async {
    if (_isEnforcing) return false;

    // 1. Check if current geolocator position is flagged as mock
    if (currentPosition != null && currentPosition.isMocked) {
      await _handleViolation(
        isDevMode: false,
        fallbackMessage:
            'Mock / Fake location detected. Please disable mock location apps in your device settings to use this app.',
        context: context,
      );
      return false;
    }

    // 2. Query native Android / iOS checks via MethodChannel
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final bool isDevMode =
            await _channel.invokeMethod<bool>('isDevModeEnabled') ?? false;
        if (isDevMode && !kDebugMode) {
          await _handleViolation(
            isDevMode: true,
            fallbackMessage:
                'Developer options / USB debugging detected. Please turn off Developer Options in your device settings to use this app.',
            context: context,
          );
          return false;
        }

        final bool isMock =
            await _channel.invokeMethod<bool>('isMockLocation') ?? false;
        if (isMock) {
          await _handleViolation(
            isDevMode: false,
            fallbackMessage:
                'Mock / Fake location detected. Please disable mock location apps in your device settings to use this app.',
            context: context,
          );
          return false;
        }
      } catch (e) {
        debugPrint('[SecurityService] verifyDeviceSecurity error: $e');
      }
    }

    return true;
  }

  /// Verifies a specific [Position] instance (e.g. from attendance punch or QR scan).
  static Future<bool> verifyPosition(
    Position position, {
    BuildContext? context,
  }) async {
    if (position.isMocked) {
      await _handleViolation(
        isDevMode: false,
        fallbackMessage:
            'Mock / Fake location detected. Please disable mock location apps in your device settings to use this app.',
        context: context,
      );
      return false;
    }
    return true;
  }

  static Future<void> _handleViolation({
    required bool isDevMode,
    required String fallbackMessage,
    BuildContext? context,
  }) async {
    if (_isEnforcing) return;
    _isEnforcing = true;

    String errorMessage = fallbackMessage;
    try {
      final effectiveContext =
          context ?? FCMService.navigatorKey.currentContext;
      if (effectiveContext != null) {
        final localizations = AppLocalizations.of(effectiveContext);
        if (localizations != null) {
          errorMessage = isDevMode
              ? localizations.developerModeDetectedError
              : localizations.mockLocationDetectedError;
        }
      }
    } catch (_) {}

    debugPrint(
        '[SecurityService] Security violation detected (isDevMode=$isDevMode). Forcing logout: $errorMessage');

    Future.microtask(() async {
      await LogoutHelper.forceLogout(errorMessage: errorMessage);
    });
  }

  static void reset() {
    _isEnforcing = false;
  }
}
