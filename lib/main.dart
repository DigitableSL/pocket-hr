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
    if (packageName == 'io.digitable.go.domex.human' || packageName == 'io.digitable.go.mydomex.human') {
      const Color primary = Color(0xFF6A1311); // Domex dark crimson red
      const Color secondary = Color(0xffffcc09); // Domex gold
      const Color iconFg = secondary;
      const Color iconBg = Color(0xFF6A1311);
      FlavorConfig.init(
        flavor: Flavor.domex,
        appName: 'My Domex',
        apiBaseUrl: 'https://api.human.go.digitable.io/human/v2/api',
        packageName: packageName,
        splashLogoAsset: 'assets/images/bg_remove_domex_app_logo.png',
        primaryColor: primary,
        secondaryColor: secondary,
        morningBg: 'assets/images/domex_home-banner3.jpg',
        afternoonBg: 'assets/images/domex_home-banner3.jpg',
        eveningBg: 'assets/images/domex_home-banner3.jpg',
        nightBg: 'assets/images/domex_home-banner3.jpg',
        iconColor: iconFg,
        iconBackgroundColor: iconBg,
        tenant: 'domex',
        tabColor: const Color(0xFF791b27),
        tabLabelColor: secondary,
        bottomNavIconColor: secondary,
        bottomNavIconBgColor: const Color(0xFF791b27),
        buttonColor: primary,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            primary: primary,
            secondary: secondary,
          ),
          primaryColor: primary,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: primary),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: const BorderSide(color: primary),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: primary,
            foregroundColor: Colors.white,
          ),
          textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.white),
          fontFamily: 'Poppins',
        ),
      );
    } else if (packageName == 'io.digitable.go.mahajana.human') {
      const Color primary = Color(0xFFC91032); // Mahajana red
      const Color secondary = Color.fromARGB(255, 29, 67, 134); // Mahajana blue
      FlavorConfig.init(
        flavor: Flavor.mahajana,
        appName: 'Mahajana HR',
        apiBaseUrl: 'https://api.human.go.digitable.io/human/v2/api',
        packageName: 'io.digitable.go.mahajana.human',
        splashLogoAsset: 'assets/images/mahajana plash_logo.png',
        primaryColor: primary,
        secondaryColor: secondary,
        morningBg: 'assets/images/mahajana_home.png',
        afternoonBg: 'assets/images/mahajana_home.png',
        eveningBg: 'assets/images/mahajana_home.png',
        nightBg: 'assets/images/mahajana_home.png',
        backgroundColor: const Color(0xFFF4F7FC),
        containerShadowColor: const Color(0xFFE2E8F0),
        lightWhiteColor: const Color(0xFFEBF2FC),
        splashBackgroundColor: primary,
        iconColor: primary,
        iconBackgroundColor: const Color(0xFFFFEBEE),
        tenant: 'mahajana',
        tabColor: primary,
        tabLabelColor: Colors.white,
        bottomNavIconColor: Colors.white,
        bottomNavIconBgColor: primary,
        buttonColor: primary,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            primary: primary,
            secondary: secondary,
          ),
          primaryColor: primary,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(backgroundColor: primary),
          ),
          textSelectionTheme:
              const TextSelectionThemeData(cursorColor: Colors.white),
          fontFamily: 'Poppins',
        ),
      );
    } else if (packageName == 'io.digitable.go.malkey.human') {
      const Color primary = Color(0xFF334C5F); // rgb(51, 76, 95) Deep Slate Blue
      const Color secondary = Color(0xFF4F708B); // Slate accent
      const Color cardColor = Colors.white;
      const Color backgroundColor = Color(0xFFEAEEF1); // rgb(234, 238, 241) Clean Ice Slate
      FlavorConfig.init(
        flavor: Flavor.malkey,
        appName: 'Malkey HR',
        apiBaseUrl: 'https://api.human.go.digitable.io/human/v2/api',
        packageName: packageName,
        splashLogoAsset: 'assets/images/malkey_app_logo.png',
        primaryColor: primary,
        secondaryColor: secondary,
        morningBg: 'assets/images/malkey-banner.jpg',
        afternoonBg: 'assets/images/malkey-banner.jpg',
        eveningBg: 'assets/images/malkey-banner.jpg',
        nightBg: 'assets/images/malkey-banner.jpg',
        backgroundColor: backgroundColor,
        containerShadowColor: const Color(0xFFD2DCE2),
        lightWhiteColor: const Color(0xFFEAEEF1), // rgb(234, 238, 241)
        splashBackgroundColor: primary, // rgb(51, 76, 95) exactly matching native splash
        cardColor: cardColor,
        iconColor: primary,
        iconBackgroundColor: const Color(0xFFEAEEF1), // rgb(234, 238, 241) soft icon backing
        tenant: 'malkey',
        tabColor: primary,
        tabLabelColor: Colors.white,
        bottomNavIconColor: Colors.white,
        bottomNavIconBgColor: primary,
        bottomNavBarBgColor: Colors.grey.withOpacity(0.6),
        buttonColor: primary,
        brandPrimary: primary,
        brandLight: const Color(0xFFEAEEF1), // rgb(234, 238, 241)
        brandDarkText: const Color(0xFF1F2D38),
        brandGreyText: const Color(0xFF64748B),
        brandBorder: const Color(0xFFD5DFE6),
        brandAccent: const Color(0xFF4F708B),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            primary: primary,
            secondary: secondary,
            surface: cardColor,
          ),
          primaryColor: primary,
          cardColor: cardColor,
          scaffoldBackgroundColor: backgroundColor,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: primary),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: const BorderSide(color: primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: primary,
            foregroundColor: Colors.white,
          ),
          cardTheme: const CardThemeData(
            color: cardColor,
            elevation: 1,
          ),
          textSelectionTheme: const TextSelectionThemeData(cursorColor: primary),
          fontFamily: 'Poppins',
        ),
      );
    } else {
      const Color primary = Color(0xFF2D67CC); // Digitable blue
      const Color secondary = Color(0xFFFF6F00); // Digitable orange
      FlavorConfig.init(
        flavor: Flavor.digitable,
        appName: 'Pocket HR',
        apiBaseUrl: 'https://api.human.go.digitable.io/human/v2/api',
        packageName: 'asia.ceynet.human.pocket',
        splashLogoAsset: 'assets/images/app_logo.png',
        primaryColor: primary,
        secondaryColor: secondary,
        morningBg: "https://www.farmersalmanac.com/wp-content/uploads/2020/11/Earliest-Sunrise-June-A191879830.jpg",
        afternoonBg: "https://www.farmersalmanac.com/wp-content/uploads/2020/11/Earliest-Sunrise-June-A191879830.jpg",
        eveningBg: "https://hips.hearstapps.com/hmg-prod.s3.amazonaws.com/images/sunset-quotes-21-1586531574.jpg",
        nightBg: "https://wallpaperaccess.com/full/2113857.jpg",
        backgroundColor: const Color(0xFFF4F7FC),
        containerShadowColor: const Color(0xFFE2E8F0),
        lightWhiteColor: const Color(0xFFEBF2FC),
        splashBackgroundColor: const Color(0xFF2D67CC),
        iconColor: primary,
        iconBackgroundColor: const Color(0xFFEBF2FC),
        tenant: 'domex',
        tabColor: primary,
        tabLabelColor: Colors.white,
        bottomNavIconColor: Colors.white,
        bottomNavIconBgColor: primary,
        buttonColor: primary,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            primary: primary,
            secondary: secondary,
          ),
          primaryColor: primary,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(backgroundColor: primary),
          ),
          textSelectionTheme:
              const TextSelectionThemeData(cursorColor: Colors.white),
          fontFamily: 'Poppins',
        ),
      );
    }
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
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: mediaQuery.textScaler.clamp(
                    minScaleFactor: 0.85,
                    maxScaleFactor: 1.15,
                  ),
                ),
                child: Stack(
                  children: [
                    if (widget != null) widget,
                    if (!conn.isOnline && !conn.showBanner)
                      Positioned(
                        top: mediaQuery.padding.top,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 3.5,
                            color: const Color(0xFFD32F2F),
                          ),
                        ),
                      ),
                    if (conn.showBanner)
                      Positioned(
                        top: mediaQuery.padding.top,
                        left: 0,
                        right: 0,
                        child: Material(
                          color: conn.isOnline
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFD32F2F),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  conn.isOnline
                                      ? Icons.cloud_done_outlined
                                      : Icons.cloud_off_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                AutoSizeText(
                                  conn.isOnline
                                      ? (AppLocalizations.of(context)
                                              ?.youAreOnline ??
                                          'You are online')
                                      : (AppLocalizations.of(context)
                                              ?.youAreOffline ??
                                          'You are offline'),
                                  maxLines: 1,
                                  minFontSize: 11,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
}
