import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateHelper {
  static bool _isShowing = false;
  static String? _dismissedSoftVersion;

  static String _readHeader(Map<String, String>? headers, String name) {
    if (headers == null || headers.isEmpty) return '';
    final target = name.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == target) {
        return entry.value.trim();
      }
    }
    return '';
  }

  /// Checks response status code, headers, or body for hard/soft app updates.
  ///
  /// Supported response headers:
  /// - `X-App-Update-Available`: `true` | `false`
  /// - `X-App-Force-Update`: `true` | `false`
  /// - `X-App-Latest-Version`: e.g. `2.1.0`
  /// - `X-App-Min-Version`: e.g. `2.0.0`
  /// - `X-App-Update-Url`: platform-specific Play Store / App Store URL
  static bool handlePotentialUpdateRequired(
    int statusCode, [
    dynamic responseBody,
    Map<String, String>? headers,
  ]) {
    final updateAvailable =
        _readHeader(headers, 'x-app-update-available').toLowerCase() == 'true';
    final forceHeader =
        _readHeader(headers, 'x-app-force-update').toLowerCase() == 'true';
    final latestVersion = _readHeader(headers, 'x-app-latest-version');
    final minVersion = _readHeader(headers, 'x-app-min-version');
    final updateUrl = _readHeader(headers, 'x-app-update-url');

    final bool isForceUpdate = statusCode == 426 || forceHeader;

    if (isForceUpdate) {
      showUpdateBottomSheet(
        isForce: true,
        latestVersion: latestVersion,
        minVersion: minVersion,
        updateUrl: updateUrl,
      );
      return true;
    }

    if (updateAvailable) {
      final versionKey =
          latestVersion.isNotEmpty ? latestVersion : 'soft_update';
      if (_dismissedSoftVersion == versionKey) {
        return false;
      }
      showUpdateBottomSheet(
        isForce: false,
        latestVersion: latestVersion,
        minVersion: minVersion,
        updateUrl: updateUrl,
      );
      return true;
    }

    return false;
  }

  static Map<String, String> _getLocalizedTexts(
    BuildContext context, {
    required bool isForce,
    String latestVersion = '',
  }) {
    String lang = 'en';
    try {
      final locale = Localizations.localeOf(context);
      lang = locale.languageCode.toLowerCase();
    } catch (_) {}

    if (isForce) {
      try {
        final loc = AppLocalizations.of(context);
        if (loc != null) {
          return {
            'title': loc.appUpdateRequiredTitle,
            'message': loc.appUpdateRequiredMessage,
            'button': loc.appUpdateRequiredButton,
            'later': '',
          };
        }
      } catch (_) {}

      if (lang == 'si') {
        return {
          'title': 'නව යාවත්කාලීන කිරීමක් අවශ්‍යයි',
          'message':
              'ඉදිරියට යාම සඳහා කරුණාකර ඔබගේ යෙදුම නවතම අනුවාදයට යාවත්කාලීන කරන්න.',
          'button': 'දැන් යාවත්කාලීන කරන්න',
          'later': '',
        };
      } else if (lang == 'ta') {
        return {
          'title': 'பயன்பாட்டை புதுப்பிக்க வேண்டும்',
          'message':
              'தொடர, தயவுசெய்து உங்கள் பயன்பாட்டை புதிய பதிப்பிற்கு புதுப்பிக்கவும்.',
          'button': 'இப்போதே புதுப்பிக்கவும்',
          'later': '',
        };
      } else {
        return {
          'title': 'App Update Required',
          'message':
              'Please update your app to the latest version to continue.',
          'button': 'Update Now',
          'later': '',
        };
      }
    }

    // Soft update localized strings
    final verSuffix = latestVersion.isNotEmpty ? ' (v$latestVersion)' : '';
    if (lang == 'si') {
      return {
        'title': 'නව අනුවාදයක් ඇත',
        'message':
            'නවතම විශේෂාංග සහ වැඩිදියුණු කිරීම් සඳහා යෙදුම$verSuffix යාවත්කාලීන කරන්න.',
        'button': 'යාවත්කාලීන',
        'later': 'පසුව',
      };
    } else if (lang == 'ta') {
      return {
        'title': 'புதிய பதிப்பு கிடைக்கிறது',
        'message':
            'சிறந்த அனுபவத்திற்காக பயன்பாட்டை$verSuffix புதுப்பிக்கவும்.',
        'button': 'புதுப்பி',
        'later': 'பின்னர்',
      };
    } else {
      return {
        'title': 'Update Available',
        'message':
            'A new version$verSuffix is available with improvements and bug fixes.',
        'button': 'Update',
        'later': 'Later',
      };
    }
  }

  static void showUpdateBottomSheet({
    bool isForce = true,
    String latestVersion = '',
    String minVersion = '',
    String updateUrl = '',
  }) {
    if (_isShowing) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = FCMService.navigatorKey.currentContext;
      if (context == null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          showUpdateBottomSheet(
            isForce: isForce,
            latestVersion: latestVersion,
            minVersion: minVersion,
            updateUrl: updateUrl,
          );
        });
        return;
      }

      _showActualBottomSheet(
        context,
        isForce: isForce,
        latestVersion: latestVersion,
        minVersion: minVersion,
        updateUrl: updateUrl,
      );
    });
  }

  static void _showActualBottomSheet(
    BuildContext context, {
    required bool isForce,
    String latestVersion = '',
    String minVersion = '',
    String updateUrl = '',
  }) {
    if (_isShowing) return;
    _isShowing = true;

    Color primaryColor;
    try {
      primaryColor = FlavorConfig.instance.primaryColor;
    } catch (_) {
      primaryColor = HRColors.buttonColor;
    }

    final versionKey =
        latestVersion.isNotEmpty ? latestVersion : 'soft_update';

    showModalBottomSheet(
      context: context,
      isDismissible: !isForce,
      enableDrag: !isForce,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final texts = _getLocalizedTexts(
          ctx,
          isForce: isForce,
          latestVersion: latestVersion,
        );
        return PopScope(
          canPop: !isForce,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isForce)
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isForce
                        ? Icons.system_update_rounded
                        : Icons.new_releases_rounded,
                    size: 36,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  texts['title']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (latestVersion.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'v$latestVersion',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  texts['message']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                if (isForce)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        await openStore(overrideUrl: updateUrl);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        texts['button']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              _dismissedSoftVersion = versionKey;
                              Navigator.of(ctx).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              texts['later']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              _dismissedSoftVersion = versionKey;
                              Navigator.of(ctx).pop();
                              await openStore(overrideUrl: updateUrl);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              texts['button']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (!isForce) {
        _dismissedSoftVersion = versionKey;
      }
      _isShowing = false;
    });
  }

  static Future<void> openStore({String? overrideUrl}) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final packageName = info.packageName;
      Uri? url;

      if (overrideUrl != null && overrideUrl.trim().isNotEmpty) {
        final parsed = Uri.tryParse(overrideUrl.trim());
        if (parsed != null &&
            (parsed.scheme == 'https' || parsed.scheme == 'http')) {
          url = parsed;
        }
      }

      url ??= defaultTargetPlatform == TargetPlatform.iOS
          ? Uri.parse('https://apps.apple.com/app/id6739943444')
          : Uri.parse(
              'https://play.google.com/store/apps/details?id=$packageName');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final fallbackUrl = Uri.parse(
            'https://play.google.com/store/apps/details?id=$packageName');
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('AppUpdateHelper: openStore failed: $e');
    }
  }
}
