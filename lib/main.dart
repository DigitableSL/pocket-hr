import 'package:auto_size_text/auto_size_text.dart';
import 'package:cn_pocket_hr/config/firebase_options_digitable.dart';
import 'package:cn_pocket_hr/config/firebase_options_domex.dart';
import 'package:cn_pocket_hr/config/firebase_options_mahajana.dart';
import 'package:cn_pocket_hr/config/firebase_options_malkey.dart';
import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cn_pocket_hr/helpers/http_override.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart' show AppLocalizations;
import 'package:cn_pocket_hr/services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cn_pocket_hr/screens/splash_screen/splashscreen.dart';
import 'package:cn_pocket_hr/l10n/l10n.dart';
import 'package:cn_pocket_hr/providers/locale_provider.dart';
import 'package:cn_pocket_hr/routes.dart';
import 'package:provider/provider.dart';
import 'package:cn_pocket_hr/providers/connection_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupHttpOverride();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // Enable true edge-to-edge: status bar and notch area are fully seamless without shadows
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  ));

  // Determine flavor / package name dynamically
  final packageInfo = await PackageInfo.fromPlatform();
  final packageName = packageInfo.packageName;

  FirebaseOptions? options;
  if (packageName == 'io.digitable.go.domex.human' || packageName == 'io.digitable.go.mydomex.human') {
    options = DomexFirebaseOptions.currentPlatform;
  } else if (packageName == 'io.digitable.go.mahajana.human') {
    options = MahajanaFirebaseOptions.currentPlatform;
  } else if (packageName == 'io.digitable.go.malkey.human') {
    options = MalkeyFirebaseOptions.currentPlatform;
  } else {
    options = DigitableFirebaseOptions.currentPlatform;
  }

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: options);
  }

  // Default flavor — used when running `flutter run` without -t flag
  if (!_flavorInitialized()) {
    FlavorConfig.initFromPackageName(packageName);
  }

  runApp(PocketHR());
}

bool _flavorInitialized() {
  try {
    FlavorConfig.instance;
    return true;
  } catch (_) {
    return false;
  }
}

//
class PocketHR extends StatelessWidget {
//
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ],
        builder: (context, child) {
          final provider = Provider.of<LocaleProvider>(context);
          final conn = Provider.of<ConnectionProvider>(context);
          return MaterialApp(
            title: FlavorConfig.instance.appName,
            theme: FlavorConfig.instance.theme,
            navigatorKey: FCMService.navigatorKey,
            supportedLocales: L10n.all,
            locale: provider.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
            initialRoute: SplashScreen.routeName,
            routes: routes,
            builder: (context, widget) {
              return Stack(
                children: [
                  if (widget != null) widget,
                  if (conn.showBanner)
                    Positioned(
                      top: MediaQuery.of(context).padding.top,
                      left: 0,
                      right: 0,
                      child: Material(
                        color: conn.isOnline ? Colors.green : Colors.red,
                        elevation: 6,
                        child: Container(
                          width: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AutoSizeText(
                                conn.isOnline
                                    ? (conn.isWifi
                                        ? 'Connected Wi-Fi'
                                        : (conn.isMobile
                                            ? 'Connected  Mobile Data'
                                            : 'Connected'))
                                    : AppLocalizations.of(context)!
                                        .noInternetConnection,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      );
}
