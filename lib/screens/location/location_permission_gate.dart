import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/services/security_service.dart';

/// A lightweight startup gate that requests location permission before showing
/// the main app UI.
///
/// Contract:
/// - On grant: returns `true` (Navigator.pop) so the caller can decide where to go.
/// - On denied/deniedForever: shows a retry + open settings UI.
class LocationPermissionGate extends StatefulWidget {
  static const String routeName = '/location-permission-gate';

  const LocationPermissionGate({
    super.key,
  });

  @override
  State<LocationPermissionGate> createState() => _LocationPermissionGateState();
}

class _LocationPermissionGateState extends State<LocationPermissionGate> {
  bool _busy = true;
  String? _error;
  LocationPermission? _permission;
  bool _serviceEnabled = true;

  @override
  void initState() {
    super.initState();
    _ensurePermission();
  }

  Future<void> _ensurePermission() async {
    final isSecure = await SecurityService.verifyDeviceSecurity(context: context);
    if (!isSecure) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      _serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_serviceEnabled) {
        setState(() {
          _busy = false;
          _permission = null;
          _error = 'LOCATION_SERVICE_DISABLED';
        });
        return;
      }

      _permission = await Geolocator.checkPermission();
      if (_permission == LocationPermission.denied) {
        // This shows the native system dialog
        _permission = await Geolocator.requestPermission();
      }

      if (_permission == LocationPermission.whileInUse ||
          _permission == LocationPermission.always) {
        if (!mounted) return;
        Navigator.of(context).pop(true);  // ✅ Navigation unchanged
        return;
      }

      setState(() {
        _busy = false;
        _error = _permission == LocationPermission.deniedForever
            ? 'DENIED_FOREVER'
            : 'DENIED';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'ERROR';
      });
    }
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) _ensurePermission();
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) _ensurePermission();
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.secondaryColor;

    final String title = 'Location permission';
    final String desc = 'We need your location to use attendance features.';

    String message = '';
    if (_error == 'LOCATION_SERVICE_DISABLED') {
      message = 'Location services are turned off. Please enable them.';
    } else if (_error == 'DENIED_FOREVER') {
      message = 'Location permission is permanently denied. Please enable it from Settings.';
    } else if (_error == 'DENIED') {
      message = 'Location permission is denied. Please allow to continue.';
    } else if (_error == 'ERROR') {
      message = 'Something went wrong. Please try again.';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 18),
              Image.asset(
                FlavorConfig.instance.splashLogoAsset,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(height: 120),
              ),
              const SizedBox(height: 18),
              AutoSizeText(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              AutoSizeText(
                desc,
                maxLines: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 18),
              if (_busy) ...[
                CupertinoActivityIndicator(color: accent, radius: 16),
                const SizedBox(height: 12),
                AutoSizeText(
                  'Requesting permission…',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                if (message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    child: AutoSizeText(
                      message,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _ensurePermission,
                    child: AutoSizeText(
                      AppLocalizations.of(context)!.tryAgain,
                      maxLines: 1,
                      minFontSize: 10,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_error == 'DENIED_FOREVER')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _openSettings,
                      child: AutoSizeText(
                        AppLocalizations.of(context)!.openSettings,
                        maxLines: 1,
                        minFontSize: 10,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                if (_error == 'LOCATION_SERVICE_DISABLED')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _openLocationSettings,
                      child: AutoSizeText(
                        AppLocalizations.of(context)!.locationSettings,
                        maxLines: 1,
                        minFontSize: 10,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
              const Spacer(),
              AutoSizeText(
                Platform.isIOS
                    ? 'iOS: allow "While Using the App"'
                    : 'Android: allow location permission',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}