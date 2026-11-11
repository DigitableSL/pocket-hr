import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cn_pocket_hr/helpers/logout.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';

enum SecurityViolationType {
  devMode,
  mockLocation,
  autoTimeDisabled,
}

class SecurityService {
  static const MethodChannel _channel =
      MethodChannel('asia.ceynet.pocket/security');

  static bool _isEnforcing = false;
  static bool _isChecking = false;
  static Timer? _monitoringTimer;
  static Position? _lastKnownPosition;

  /// Starts continuous foreground security monitoring (checks Auto Date/Time,
  /// Developer Mode, and Mock GPS every [interval] while app is active).
  /// Automatically pauses when [pauseContinuousMonitoring] is called on app backgrounding
  /// to conserve battery.
  static void startContinuousMonitoring({
    Duration interval = const Duration(seconds: 10),
  }) {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(interval, (_) {
      if (!_isEnforcing && !_isChecking) {
        verifyDeviceSecurity(currentPosition: _lastKnownPosition);
      }
    });
  }

  /// Pauses the periodic security timer when the app enters background to save battery.
  static void pauseContinuousMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Resumes continuous monitoring and performs an immediate check when the app returns to foreground.
  static Future<bool> resumeContinuousMonitoring({BuildContext? context}) async {
    final isClean = await verifyDeviceSecurity(
      currentPosition: _lastKnownPosition,
      context: context,
    );
    if (isClean) {
      startContinuousMonitoring();
    }
    return isClean;
  }

  /// Stops continuous monitoring completely (e.g. on logout).
  static void stopContinuousMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Verifies device developer mode, automatic date & time, and mock location status.
  /// If a violation is detected, shows an error message and logs out the user.
  /// Returns `true` if device is clean and secure, `false` if violation was found.
  static Future<bool> verifyDeviceSecurity({
    Position? currentPosition,
    BuildContext? context,
  }) async {
    if (_isEnforcing) return false;
    if (currentPosition != null) {
      _lastKnownPosition = currentPosition;
    }

    final positionToCheck = currentPosition ?? _lastKnownPosition;

    // 1. Check if current geolocator position is flagged as mock or time-tampered
    if (positionToCheck != null) {
      if (positionToCheck.isMocked) {
        await _handleViolation(
          type: SecurityViolationType.mockLocation,
          fallbackMessage:
              'Mock / Fake location detected. Please disable mock location apps in your device settings to use this app.',
          context: context,
        );
        return false;
      }

      if (positionToCheck.timestamp != null) {
        final clockDrift = DateTime.now()
            .difference(positionToCheck.timestamp!)
            .inSeconds
            .abs();
        // Only check drift against fresh GPS fixes (within 5 minutes) or when device clock drifted away
        if (clockDrift > 180) {
          await _handleViolation(
            type: SecurityViolationType.autoTimeDisabled,
            fallbackMessage:
                'Device time deviates from satellite network time. Please enable "Set time automatically" in settings.',
            context: context,
          );
          return false;
        }
      }
    }

    // 2. Query native Android / iOS checks via MethodChannel
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _isChecking = true;
      try {
        // A. Automatic Date & Time check (strictly required to prevent attendance clock tampering)
        final bool isAutoTime =
            await _channel.invokeMethod<bool>('isAutoTimeEnabled') ?? true;
        if (!isAutoTime && !kDebugMode) {
          await _handleViolation(
            type: SecurityViolationType.autoTimeDisabled,
            fallbackMessage:
                'Automatic Date & Time is disabled. Please enable "Set time automatically" in your device settings to use this app.',
            context: context,
          );
          return false;
        }

        // B. Developer options / USB debugging check
        final bool isDevMode =
            await _channel.invokeMethod<bool>('isDevModeEnabled') ?? false;
        if (isDevMode && !kDebugMode) {
          await _handleViolation(
            type: SecurityViolationType.devMode,
            fallbackMessage:
                'Developer options / USB debugging detected. Please turn off Developer Options in your device settings to use this app.',
            context: context,
          );
          return false;
        }

        // C. Mock location check
        final bool isMock =
            await _channel.invokeMethod<bool>('isMockLocation') ?? false;
        if (isMock) {
          await _handleViolation(
            type: SecurityViolationType.mockLocation,
            fallbackMessage:
                'Mock / Fake location detected. Please disable mock location apps in your device settings to use this app.',
            context: context,
          );
          return false;
        }
      } catch (e) {
        debugPrint('[SecurityService] verifyDeviceSecurity error: $e');
      } finally {
        _isChecking = false;
      }
    }

    return true;
  }

  /// Verifies a specific [Position] instance (e.g. from GPS stream, attendance punch, or QR scan).
  static Future<bool> verifyPosition(
    Position position, {
    BuildContext? context,
  }) async {
    _lastKnownPosition = position;

    if (position.isMocked) {
      await _handleViolation(
        type: SecurityViolationType.mockLocation,
        fallbackMessage:
            'Mock / Fake location detected. Please disable mock location apps in your device settings to use this app.',
        context: context,
      );
      return false;
    }

    if (position.timestamp != null) {
      final clockDrift =
          DateTime.now().difference(position.timestamp!).inSeconds.abs();
      if (clockDrift > 180) {
        await _handleViolation(
          type: SecurityViolationType.autoTimeDisabled,
          fallbackMessage:
              'Device time deviates from satellite network time. Please enable "Set time automatically" in settings.',
          context: context,
        );
        return false;
      }
    }

    return true;
  }

  static Future<void> _handleViolation({
    required SecurityViolationType type,
    required String fallbackMessage,
    BuildContext? context,
  }) async {
    if (_isEnforcing) return;
    _isEnforcing = true;
    stopContinuousMonitoring();

    String errorMessage = fallbackMessage;
    try {
      final effectiveContext =
          context ?? FCMService.navigatorKey.currentContext;
      if (effectiveContext != null) {
        final localizations = AppLocalizations.of(effectiveContext);
        if (localizations != null) {
          switch (type) {
            case SecurityViolationType.devMode:
              errorMessage = localizations.developerModeDetectedError;
              break;
            case SecurityViolationType.mockLocation:
              errorMessage = localizations.mockLocationDetectedError;
              break;
            case SecurityViolationType.autoTimeDisabled:
              errorMessage = localizations.autoTimeRequiredError;
              break;
          }
        }
      }
    } catch (_) {}

    debugPrint(
        '[SecurityService] Security violation detected (type=$type). Forcing logout: $errorMessage');

    Future.microtask(() async {
      await LogoutHelper.forceLogout(errorMessage: errorMessage);
    });
  }

  static void reset() {
    _isEnforcing = false;
    _isChecking = false;
    _lastKnownPosition = null;
  }
}
