import 'dart:async';

import 'package:cn_pocket_hr/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:cn_pocket_hr/screens/main/main_screen.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:cn_pocket_hr/screens/location/location_permission_dialog.dart';
import 'package:cn_pocket_hr/providers/locale_provider.dart';
import 'package:provider/provider.dart';

import 'package:cn_pocket_hr/services/security_service.dart';
import 'package:cn_pocket_hr/services/secure_token_service.dart';

class MobileSplash extends StatefulWidget {
  const MobileSplash({Key? key}) : super(key: key);

  @override
  _MobileSplashState createState() => _MobileSplashState();
}

class _MobileSplashState extends State<MobileSplash>
    with TickerProviderStateMixin {
  LocalStorage storage = LocalStorage('pocketHR');
  APIService apiService = APIService();

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 5000),
    vsync: this,
  )..forward();

  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 0.1,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  ));

  late final Animation<double> _fadeAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
  ));

  @override
  void initState() {
    super.initState();
    startTime();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  startTime() async {
    var _duration = Duration(milliseconds: 5000);
    return Timer(_duration, navigationPage);
  }

  var email = null;
  var token = null;
  var password = null;
  var pin = null;
  var saveLang = null;

  navigationPage() async {
    await storage.ready;
    await SecureTokenService.ensureInitialized();
    saveLang = storage.getItem('lang');
    setLanguage(saveLang);

    // Check developer mode, auto date/time, and mock location before doing anything else
    if (!mounted) return;
    final isSecure = await SecurityService.verifyDeviceSecurity(context: context);
    if (!isSecure) return;

    // Require location service & permission before initiating any API or background services
    if (!mounted) return;
    final granted = await showLocationPermissionDialog(context);
    if (granted != true) return;

    // Require both saved tenant + access token
    final savedTenant = (storage.getItem('tenant') ?? '').toString();
    final hasSavedTenant = savedTenant.trim().isNotEmpty;

    // Try auto-login via valid access token
    try {
      final hasToken = await apiService.hasValidAccessToken();
      if (hasSavedTenant && hasToken) {
        final me = await apiService.fetchMeProfileWithBearer();
        if (me != null) {
          if (!mounted) return;
          Navigator.pushNamed(context, HRMain.routeName);
          return;
        }
      }
    } catch (_) {}

    // Default -> login screen
    try {
      await SecureTokenService.clearTokens();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushNamed(context, HRLogin.routeName);
  }

  setLanguage(saveLang) async {
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    if (saveLang != null) {
      if (saveLang == 'en') {
        provider.setLocale(Locale('en'));
      }
      if (saveLang == 'si') {
        provider.setLocale(Locale('si'));
      }
      if (saveLang == 'ta') {
        provider.setLocale(Locale('ta'));
      }
    }
  }

  void autoLogin(email, password) async {
    // Legacy email/password auto-login removed. Proceed to login screen.
    try {
      await SecureTokenService.clearTokens();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushNamed(context, HRLogin.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
   child: Scaffold(
  backgroundColor: HRColors.splashred,
  body: Container(
    color: HRColors.splashred,
    alignment: Alignment.center,
    child: FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Image.asset(
          FlavorConfig.instance.splashLogoAsset,
          width: 192.0,
          fit: BoxFit.contain,
        ),
      ),
    ),
  ),
),
    );
  }
}
