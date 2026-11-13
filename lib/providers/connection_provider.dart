import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cn_pocket_hr/services/offline_attendance_service.dart';
import 'package:cn_pocket_hr/config/flavor_config.dart';

class ConnectionProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityResult? _lastResult;
  ConnectivityResult? get lastResult => _lastResult;

  bool get isWifi => _lastResult == ConnectivityResult.wifi;
  bool get isMobile => _lastResult == ConnectivityResult.mobile;
  String get connectionType => _lastResult?.toString().split('.').last ?? 'none';

  // transient banner state: when true the UI should show the connection message briefly
  bool _showBanner = false;
  bool get showBanner => _showBanner;
  Timer? _bannerTimer;

  late final StreamSubscription<dynamic> _subscription;
  int _currentCheckId = 0;

  ConnectionProvider() {
    _init();
  }

  Future<void> _init() async {
    final connectivity = Connectivity();
    try {
      final raw = await connectivity.checkConnectivity();
      _lastResult = _toConnectivityResult(raw);
      notifyListeners();
      
      // Check internet access asynchronously without flashing online banner on cold start
      _runInternetCheck(_currentCheckId, isInitial: true);
    } catch (_) {
      _isOnline = true;
      notifyListeners();
    }

    _subscription = connectivity.onConnectivityChanged.listen((rawResult) {
      _currentCheckId++;
      _lastResult = _toConnectivityResult(rawResult);
      
      // If we got disconnected completely, we can set online to false immediately
      if (_lastResult == ConnectivityResult.none) {
        _isOnline = false;
        _showTransientBanner();
        notifyListeners();
      } else {
        // Otherwise, notify immediately about connection type change (e.g. Wi-Fi)
        notifyListeners();
        // Check internet access in background with the updated check ID
        _runInternetCheck(_currentCheckId);
      }
    });
  }

  Future<void> _runInternetCheck(int checkId, {bool isInitial = false}) async {
    final nowOnline = await _checkInternetAccess();

    // Ignore if this is a stale check
    if (checkId != _currentCheckId) return;

    _isOnline = nowOnline;

    // debug
    try {
      debugPrint('[ConnectionProvider] normalized=$_lastResult online=$_isOnline');
    } catch (_) {}

    if (!isInitial || !_isOnline) {
      _showTransientBanner();
    }

    if (_isOnline) {
      unawaited(() async {
        try {
          await OfflineAttendanceService.instance.syncPending(ignoreMaxAttempts: true);
        } catch (_) {}
      }());
    }

    notifyListeners();
  }

  void _showTransientBanner({Duration duration = const Duration(seconds: 3)}) {
    try {
      _bannerTimer?.cancel();
    } catch (_) {}
    _showBanner = true;
    notifyListeners();
    _bannerTimer = Timer(duration, () {
      _showBanner = false;
      notifyListeners();
    });
  }

  ConnectivityResult _toConnectivityResult(dynamic raw) {
    try {
      if (raw is List) {
        if (raw.isEmpty) return ConnectivityResult.none;
        for (final item in raw) {
          final res = _parseSingle(item);
          if (res != ConnectivityResult.none) return res;
        }
        return ConnectivityResult.none;
      }
      return _parseSingle(raw);
    } catch (_) {
      return ConnectivityResult.none;
    }
  }

  ConnectivityResult _parseSingle(dynamic item) {
    if (item == null) return ConnectivityResult.none;
    if (item is ConnectivityResult) return item;
    final s = item.toString().toLowerCase();
    if (s.contains('wifi')) return ConnectivityResult.wifi;
    if (s.contains('mobile') || s.contains('cellular')) return ConnectivityResult.mobile;
    if (s.contains('ethernet')) return ConnectivityResult.ethernet;
    if (s.contains('vpn')) return ConnectivityResult.vpn;
    if (s.contains('bluetooth')) return ConnectivityResult.bluetooth;
    return ConnectivityResult.none;
  }

  Future<bool> _checkInternetAccess({Duration timeout = const Duration(seconds: 3)}) async {
    if (_lastResult == ConnectivityResult.none) return false;

    String? apiHost;
    try {
      apiHost = Uri.parse(FlavorConfig.instance.apiBaseUrl).host;
    } catch (_) {}

    final hostsToCheck = [
      if (apiHost != null && apiHost.isNotEmpty) apiHost,
      'google.com',
      'example.com',
    ];

    const retries = 3;
    const retryDelays = [
      Duration(seconds: 1),
      Duration(seconds: 2),
    ];

    for (int attempt = 0; attempt < retries; attempt++) {
      for (final host in hostsToCheck) {
        try {
          final lookup = await InternetAddress.lookup(host).timeout(timeout);
          if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
            return true;
          }
        } catch (_) {
          // Fallback to next host/attempt
        }
      }

      if (attempt < retries - 1) {
        // Wait before retrying to allow interface DHCP/DNS configuration to stabilize
        await Future.delayed(retryDelays[attempt]);
      }
    }

    return false;
  }

  @override
  void dispose() {
    try {
      _subscription.cancel();
    } catch (_) {}
    try { _bannerTimer?.cancel(); } catch (_) {}
    super.dispose();
  }
}

