import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cn_pocket_hr/services/security_service.dart';

/// Shows a modal dialog to request location permission.
///
/// Contract:
/// - Returns `true` when permission is granted.
/// - Returns `false` when the user dismisses the dialog or permission isn't granted.
Future<bool> showLocationPermissionDialog(BuildContext context) async {
  if (!context.mounted) return false;

  final isSecure = await SecurityService.verifyDeviceSecurity(context: context);
  if (!isSecure) return false;

  // First, try the system dialog
  final permission = await _requestSystemPermission();
  
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  
  if ((permission == LocationPermission.whileInUse ||
       permission == LocationPermission.always) &&
      serviceEnabled) {
    return true;
  }
  
  // Only if system dialog was denied or location services are disabled, show custom dialog
  if (!context.mounted) return false;
  
  return (await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const _LocationPermissionDialog(),
      )) ==
      true;
}

Future<LocationPermission> _requestSystemPermission() async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission(); // System dialog
    }
    return permission;
  } catch (_) {
    return LocationPermission.denied;
  }
}

class _LocationPermissionDialog extends StatefulWidget {
  const _LocationPermissionDialog();

  @override
  State<_LocationPermissionDialog> createState() => _LocationPermissionDialogState();
}

class _LocationPermissionDialogState extends State<_LocationPermissionDialog> with WidgetsBindingObserver {
  bool _busy = false;
  bool _checkingAfterSettings = false;
  bool _permissionGranted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionStatus();
    }
  }

  Future<void> _checkPermissionStatus() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _busy = false;
          _checkingAfterSettings = false;
          _permissionGranted = false;
          _error = 'LOCATION_SERVICE_DISABLED';
        });
        return;
      }

      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        setState(() {
          _busy = false;
          _checkingAfterSettings = false;
          _permissionGranted = true;
          _error = null;
        });
        return;
      }

      setState(() {
        _busy = false;
        _checkingAfterSettings = false;
        _permissionGranted = false;
        _error = permission == LocationPermission.deniedForever
            ? 'DENIED_FOREVER'
            : 'DENIED';
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _checkingAfterSettings = false;
        _permissionGranted = false;
        _error = 'ERROR';
      });
    }
  }

  Future<void> _openAppSettings() async {
    setState(() {
      _checkingAfterSettings = true;
      _busy = true;
    });
    
    await Geolocator.openAppSettings();
  }

  Future<void> _openLocationSettings() async {
    setState(() {
      _checkingAfterSettings = true;
      _busy = true;
    });
    
    await Geolocator.openLocationSettings();
  }

  Future<void> _requestPermission() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        setState(() {
          _busy = false;
          _permissionGranted = true;
          _error = null;
        });
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _busy = false;
          _error = permission == LocationPermission.deniedForever
              ? 'DENIED_FOREVER'
              : 'DENIED';
        });
      }
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'ERROR';
      });
    }
  }

  void _continue() {
    if (_permissionGranted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.secondaryColor;

    final String title = 'Location permission required';
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

    // Determine button text and action based on permission state
    String buttonText = 'Allow permission';
    VoidCallback? buttonAction;
    
    if (_permissionGranted) {
      buttonText = 'Continue';
      buttonAction = _continue;
    } else if (_error == 'DENIED_FOREVER') {
      buttonText = 'Open Settings';
      buttonAction = _openAppSettings;
    } else if (_error == 'DENIED') {
      buttonText = 'Allow permission';
      buttonAction = _requestPermission;
    } else if (_error == 'LOCATION_SERVICE_DISABLED') {
      buttonText = 'Enable Location Services';
      buttonAction = _openLocationSettings;
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AutoSizeText(
                title,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              AutoSizeText(
                desc,
                maxLines: 3,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 14),
              if (_busy || _checkingAfterSettings) ...[
                CupertinoActivityIndicator(color: accent, radius: 16),
                const SizedBox(height: 12),
                AutoSizeText(
                  _checkingAfterSettings 
                      ? 'Checking permission after settings...'
                      : 'Checking permission…',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (_permissionGranted) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  child: AutoSizeText(
                    '✓ Permission granted successfully!',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
              ] else if (message.isNotEmpty) ...[
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
              ],
              if (buttonAction != null)
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: buttonAction,
                    child: AutoSizeText(
                      buttonText,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              if (!_permissionGranted && !_busy && !_checkingAfterSettings)
                AutoSizeText(
                  Platform.isIOS
                      ? 'iOS: allow "While Using the App"'
                      : 'Android: allow location permission',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}