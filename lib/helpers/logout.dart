import 'dart:async';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cn_pocket_hr/screens/login/login_screen.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cn_pocket_hr/helpers/time_validator.dart';
import 'package:cn_pocket_hr/services/security_service.dart';
import 'package:cn_pocket_hr/services/secure_token_service.dart';
import 'package:cn_pocket_hr/helpers/session_validator.dart';

class LogoutHelper {
  static Future<void> logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          AppLocalizations.of(dialogContext)!.logoutText,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.of(dialogContext)!.logoutConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              // 🔥 CLEAR ALL USER DATA FROM LOCAL STORAGE
              // Save device-level preferences first so they survive the wipe
              try {
                final ls = LocalStorage('pocketHR');
                await ls.ready;
                final savedLang = ls.getItem('lang')?.toString();
                // Wipe everything — this removes stale profile, leave data,
                // attendance state, tokens, etc. so the next user sees fresh data
                await ls.clear();
                // Restore device preference
                if (savedLang != null && savedLang.isNotEmpty) {
                  await ls.setItem('lang', savedLang);
                }
              } catch (_) {}

              // 🔥 CLEAR SECURE STORAGE & TOKENS
              await SecureTokenService.clearTokens();
              try {
                const secure = FlutterSecureStorage();
                await secure.deleteAll();
              } catch (_) {}

              // 🔥 STOP CONTINUOUS SECURITY TIMER
              SecurityService.stopContinuousMonitoring();

              // 🔥 CLEAR FCM PENDING BUFFER & BADGE
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('fcm_pending_notifications');
              } catch (_) {}
              await FCMService.reset();

              if (!context.mounted) return;

              // 🔥 NAVIGATE LOGIN
              Navigator.of(context, rootNavigator: true)
                  .pushNamedAndRemoveUntil(HRLogin.routeName, (route) => false);
            },
            child: Text(
              AppLocalizations.of(dialogContext)!.logoutText,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> forceLogout({required String errorMessage}) async {
    // 🔥 CLEAR ALL USER DATA FROM LOCAL STORAGE
    try {
      final ls = LocalStorage('pocketHR');
      await ls.ready;
      final savedLang = ls.getItem('lang')?.toString();
      await ls.clear();
      if (savedLang != null && savedLang.isNotEmpty) {
        await ls.setItem('lang', savedLang);
      }
    } catch (_) {}

    // 🔥 CLEAR SECURE STORAGE & TOKENS
    await SecureTokenService.clearTokens();
    try {
      const secure = FlutterSecureStorage();
      await secure.deleteAll();
    } catch (_) {}

    // 🔥 STOP CONTINUOUS SECURITY TIMER
    SecurityService.stopContinuousMonitoring();

    // 🔥 CLEAR FCM PENDING BUFFER & BADGE (unawaited network reset so UI navigation is instant)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_pending_notifications');
    } catch (_) {}
    unawaited(FCMService.reset());

    // Show error toast message
    try {
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.shade700,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (_) {}

    // 🔥 NAVIGATE LOGIN IMMEDIATELY
    final navState = FCMService.navigatorKey.currentState;
    if (navState != null) {
      navState.pushNamedAndRemoveUntil(HRLogin.routeName, (route) => false);
    } else {
      final context = FCMService.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil(HRLogin.routeName, (route) => false);
      }
    }

    // Reset the time validation, security service, and session flags AFTER navigation
    // with a brief debounce so any in-flight checks from disposed screens are ignored.
    Future.delayed(const Duration(milliseconds: 1200), () {
      TimeValidator.reset();
      SecurityService.reset();
      SessionValidator.reset();
    });
  }
}

