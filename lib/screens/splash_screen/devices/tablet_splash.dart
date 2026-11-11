import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:cn_pocket_hr/screens/main/main_screen.dart';
import 'package:cn_pocket_hr/screens/login/login_screen.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:cn_pocket_hr/screens/location/location_permission_dialog.dart';
import 'package:cn_pocket_hr/providers/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:cn_pocket_hr/services/security_service.dart';

class TabletSplash extends StatefulWidget {
  const TabletSplash({Key? key}) : super(key: key);

  @override
  _TabletSplashState createState() => _TabletSplashState();
}

class _TabletSplashState extends State<TabletSplash>
    with TickerProviderStateMixin {
  LocalStorage storage = LocalStorage('pocketHR');
  APIService apiService = APIService();

  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  )..forward();
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.fastOutSlowIn,
  );

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
    var _duration = Duration(milliseconds: 1000);
    return Timer(_duration, navigationPage);
  }

  var email = null;
  var token = null;
  var epf = null;
  var pin = null;
  var saveLang = null;

  navigationPage() async {
    // Check developer mode and mock location before doing anything else
    final isSecure = await SecurityService.verifyDeviceSecurity(context: context);
    if (!isSecure) return;

    await storage.ready;
    saveLang = storage.getItem('lang');
    setLanguage(saveLang);

    // Domex: require location permission before proceeding.
  //   if (FlavorConfig.instance.tenant.toString().toLowerCase() == 'domex') {
  // final granted = await showLocationPermissionDialog(context);
  // if (granted != true) return;
  //   }

    // Require both saved tenant + access token
    final savedTenant = (storage.getItem('tenant') ?? '').toString();
    final hasSavedTenant = savedTenant.trim().isNotEmpty;

    // Try access token first
    try {
      final hasToken = await apiService.hasValidAccessToken();
      if (hasSavedTenant && hasToken) {
        final me = await apiService.fetchMeProfileWithBearer();
        if (me != null) {
          Navigator.pushNamed(context, HRMain.routeName);
          return;
        }
      }
    } catch (_) {}

    // Fallback: login
    storage.clear();
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

  void autoLogin(email, pin, epf) async {
    // Legacy auto login removed. Proceed to introduction/login.
    storage.clear();
  Navigator.pushNamed(context, HRLogin.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return true as Future<bool>;
      },
      child: Scaffold(
        backgroundColor: HRColors.splashbackgroundColor,
        body: Container(
          color: HRColors.white,
          alignment: Alignment.center,
          child: Padding(
            padding:
                EdgeInsets.only(left: MediaQuery.of(context).size.width * .35),
            child: SizeTransition(
              sizeFactor: _animation,
              child: Image.asset(
                FlavorConfig.instance.splashLogoAsset,
                width: MediaQuery.of(context).size.width / 3.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
