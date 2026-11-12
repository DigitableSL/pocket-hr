import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum Flavor { digitable, domex, mahajana, malkey }

class FlavorConfig {
  final Flavor flavor;
  final String appName;
  final String apiBaseUrl;
  final String packageName;

  /// Asset path for the splash screen logo, e.g. 'assets/images/app_logo.png'
  final String splashLogoAsset;

  /// Primary brand color — used for Check-In button and app primary
  final Color primaryColor;

  /// Secondary brand color — used for Check-Out button
  final Color secondaryColor;

  /// Icon foreground color (e.g. for dashboard/menu icons)
  final Color iconColor;

  /// Icon background/badge color (e.g. the circle behind dashboard icons).
  /// Null means use the default glass/blur style.
  final Color? iconBackgroundColor;

  /// Full MaterialApp theme built from the brand colors
  final ThemeData theme;

  /// Optional hardcoded tenant name — when set, the app skips tenant input
  /// on the login screen and uses this value everywhere (API headers, SSO, etc.).
  final String? tenant;

  /// Styling overrides for different tenants
  final Color backgroundColor;
  final Color containerShadowColor;
  final Color lightWhiteColor;
  final Color splashBackgroundColor;
  final Color cardColor;

  /// Tab indicator/background color for selected tabs
  final Color tabColor;

  /// Tab label text color for selected tabs
  final Color tabLabelColor;

  /// Selected icon color in the bottom navigation bar
  final Color bottomNavIconColor;

  /// Background circle color for selected bottom navigation icon
  final Color bottomNavIconBgColor;

  /// Background color for bottom navigation bar container
  final Color bottomNavBarBgColor;

  /// Button background color
  final Color buttonColor;

  /// Accent / primary brand color for screens (e.g., Domex burgundy, Malkey royal blue)
  final Color brandPrimary;

  /// Soft light tint for card headers, balance summaries, tabs
  final Color brandLight;

  /// Dark text color matching the tenant
  final Color brandDarkText;

  /// Subtle grey text color
  final Color brandGreyText;

  /// Border color for cards, tabs, and dividers
  final Color brandBorder;

  /// Accent / highlight color (Domex gold #C59B27, Malkey sky blue #0284C7)
  final Color brandAccent;

  /// Home page background images
  final String morningBg;
  final String afternoonBg;
  final String eveningBg;
  final String nightBg;

  static FlavorConfig? _instance;

  FlavorConfig._({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.packageName,
    required this.splashLogoAsset,
    required this.primaryColor,
    required this.secondaryColor,
    required this.iconColor,
    this.iconBackgroundColor,
    required this.theme,
    required this.morningBg,
    required this.afternoonBg,
    required this.eveningBg,
    required this.nightBg,
    this.tenant,
    this.backgroundColor = const Color(0xfffff9ef),
    this.containerShadowColor = const Color(0xffffe8b7),
    this.lightWhiteColor = const Color(0xfffee8c6),
    this.splashBackgroundColor = const Color(0xff7a1b28),
    this.cardColor = Colors.white,
    Color? tabColor,
    Color? tabLabelColor,
    Color? bottomNavIconColor,
    Color? bottomNavIconBgColor,
    Color? bottomNavBarBgColor,
    Color? buttonColor,
    Color? brandPrimary,
    Color? brandLight,
    Color? brandDarkText,
    Color? brandGreyText,
    Color? brandBorder,
    Color? brandAccent,
  }) : this.tabColor = tabColor ?? primaryColor,
       this.tabLabelColor = tabLabelColor ?? secondaryColor,
       this.bottomNavIconColor = bottomNavIconColor ?? (flavor == Flavor.domex ? secondaryColor : Colors.white),
       this.bottomNavIconBgColor = bottomNavIconBgColor ?? (flavor == Flavor.domex ? const Color(0xFF791b27) : primaryColor),
       this.bottomNavBarBgColor = bottomNavBarBgColor ?? Colors.grey.withOpacity(0.6),
       this.buttonColor = buttonColor ?? primaryColor,
       this.brandPrimary = brandPrimary ?? (flavor == Flavor.domex ? const Color(0xFF701A27) : primaryColor),
       this.brandLight = brandLight ?? (flavor == Flavor.domex ? const Color(0xFFFAF2EB) : (flavor == Flavor.malkey ? const Color(0xFFEAEEF1) : lightWhiteColor)),
       this.brandDarkText = brandDarkText ?? (flavor == Flavor.domex ? const Color(0xFF4A1521) : (flavor == Flavor.malkey ? const Color(0xFF334C5F) : const Color(0xFF1F2A36))),
       this.brandGreyText = brandGreyText ?? (flavor == Flavor.domex ? const Color(0xFF7D6C6F) : const Color(0xFF6B7280)),
       this.brandBorder = brandBorder ?? (flavor == Flavor.domex ? const Color(0xFFF0E5D9) : const Color(0xFFD5DFE6)),
       this.brandAccent = brandAccent ?? (flavor == Flavor.domex ? const Color(0xFFC59B27) : (flavor == Flavor.malkey ? const Color(0xFF4F708B) : secondaryColor));

  static void init({
    required Flavor flavor,
    required String appName,
    required String apiBaseUrl,
    required String packageName,
    required String splashLogoAsset,
    required Color primaryColor,
    required Color secondaryColor,
    required String morningBg,
    required String afternoonBg,
    required String eveningBg,
    required String nightBg,
    Color iconColor = Colors.white,
    Color? iconBackgroundColor,
    required ThemeData theme,
    String? tenant,
    Color backgroundColor = const Color(0xfffff9ef),
    Color containerShadowColor = const Color(0xffffe8b7),
    Color lightWhiteColor = const Color(0xfffee8c6),
    Color splashBackgroundColor = const Color(0xff7a1b28),
    Color cardColor = Colors.white,
    Color? tabColor,
    Color? tabLabelColor,
    Color? bottomNavIconColor,
    Color? bottomNavIconBgColor,
    Color? bottomNavBarBgColor,
    Color? buttonColor,
    Color? brandPrimary,
    Color? brandLight,
    Color? brandDarkText,
    Color? brandGreyText,
    Color? brandBorder,
    Color? brandAccent,
  }) {
    _instance = FlavorConfig._(
      flavor: flavor,
      appName: appName,
      apiBaseUrl: apiBaseUrl,
      packageName: packageName,
      splashLogoAsset: splashLogoAsset,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      theme: theme,
      tenant: tenant,
      backgroundColor: backgroundColor,
      containerShadowColor: containerShadowColor,
      lightWhiteColor: lightWhiteColor,
      splashBackgroundColor: splashBackgroundColor,
      cardColor: cardColor,
      tabColor: tabColor,
      tabLabelColor: tabLabelColor,
      bottomNavIconColor: bottomNavIconColor,
      bottomNavIconBgColor: bottomNavIconBgColor,
      bottomNavBarBgColor: bottomNavBarBgColor,
      buttonColor: buttonColor,
      brandPrimary: brandPrimary,
      brandLight: brandLight,
      brandDarkText: brandDarkText,
      brandGreyText: brandGreyText,
      brandBorder: brandBorder,
      brandAccent: brandAccent,
      morningBg: morningBg,
      afternoonBg: afternoonBg,
      eveningBg: eveningBg,
      nightBg: nightBg,
    );
  }

  static FlavorConfig get instance {
    assert(_instance != null,
        'FlavorConfig not initialized. Call FlavorConfig.init() in main.');
    return _instance!;
  }

  static bool get isDigitable => instance.flavor == Flavor.digitable;
  static bool get isDomex => instance.flavor == Flavor.domex;
  static bool get isMahajana => instance.flavor == Flavor.mahajana;
  static bool get isMalkey => instance.flavor == Flavor.malkey;

  static void initDomex({String? packageName}) {
    const Color primary = Color(0xFF6A1311); // Domex dark crimson red
    const Color secondary = Color(0xffffcc09); // Domex gold
    const Color iconFg = secondary;
    const Color iconBg = Color(0xFF6A1311);

    init(
      flavor: Flavor.domex,
      appName: 'My Domex',
      apiBaseUrl: 'https://api.human.go.digitable.io/human/v2/api',
      packageName: packageName ??
          (defaultTargetPlatform == TargetPlatform.iOS
              ? 'io.digitable.go.mydomex.human'
              : 'io.digitable.go.domex.human'),
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
        textSelectionTheme:
            const TextSelectionThemeData(cursorColor: Colors.white),
        fontFamily: 'Poppins',
      ),
    );
  }

  static void initMahajana({String? packageName}) {
    const Color primary = Color(0xFFC91032); // Mahajana red
    const Color secondary = Color.fromARGB(255, 29, 67, 134); // Mahajana blue

    init(
      flavor: Flavor.mahajana,
      appName: 'Mahajana HR',
      apiBaseUrl: 'https://api.human.go.digitable.io/human/v2/api',
      packageName: packageName ?? 'io.digitable.go.mahajana.human',
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
  }

  static void initMalkey({String? packageName}) {
    const Color primary = Color(0xFF334C5F); // rgb(51, 76, 95) Deep Slate Blue
    const Color secondary = Color(0xFF4F708B); // Slate accent
    const Color cardColor = Colors.white;
    const Color backgroundColor =
        Color(0xFFEAEEF1); // rgb(234, 238, 241) Clean Ice Slate

    init(
      flavor: Flavor.malkey,
      appName: 'Malkey HR',
      apiBaseUrl: 'https://api.human.go.digitable.io/human/v2/api',
      packageName: packageName ??
          (defaultTargetPlatform == TargetPlatform.iOS
              ? 'io.digitable.go.malkey.human'
              : 'io.digitable.go.malkey.human'),
      splashLogoAsset: 'assets/images/malkey_app_logo.png',
      primaryColor: primary,
      secondaryColor: secondary,
      morningBg: 'assets/images/malkey-banner.jpg',
      afternoonBg: 'assets/images/malkey-banner.jpg',
      eveningBg: 'assets/images/malkey-banner.jpg',
      nightBg: 'assets/images/malkey-banner.jpg',
      backgroundColor: backgroundColor,
      containerShadowColor: const Color(0xFFD2DCE2),
      lightWhiteColor: const Color(0xFFEAEEF1),
      splashBackgroundColor: primary,
      cardColor: cardColor,
      iconColor: primary,
      iconBackgroundColor: const Color(0xFFEAEEF1),
      tenant: 'malkey',
      tabColor: primary,
      tabLabelColor: Colors.white,
      bottomNavIconColor: Colors.white,
      bottomNavIconBgColor: primary,
      bottomNavBarBgColor: Colors.grey.withOpacity(0.6),
      buttonColor: primary,
      brandPrimary: primary,
      brandLight: const Color(0xFFEAEEF1),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primary),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  }

  static void initDigitable({String? packageName}) {
    const Color primary = Color(0xFF2D67CC); // Digitable blue
    const Color secondary = Color(0xFFFF6F00); // Digitable orange

    init(
      flavor: Flavor.digitable,
      appName: 'Pocket HR',
      apiBaseUrl: 'https://api.human.go.digitable.io/human/v2/api',
      packageName: packageName ?? 'asia.ceynet.human.pocket',
      splashLogoAsset: 'assets/images/app_logo.png',
      primaryColor: primary,
      secondaryColor: secondary,
      morningBg:
          "https://www.farmersalmanac.com/wp-content/uploads/2020/11/Earliest-Sunrise-June-A191879830.jpg",
      afternoonBg:
          "https://www.farmersalmanac.com/wp-content/uploads/2020/11/Earliest-Sunrise-June-A191879830.jpg",
      eveningBg:
          "https://hips.hearstapps.com/hmg-prod.s3.amazonaws.com/images/sunset-quotes-21-1586531574.jpg",
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

  static void initFromPackageName(String packageName) {
    if (packageName == 'io.digitable.go.domex.human' ||
        packageName == 'io.digitable.go.mydomex.human') {
      initDomex(packageName: packageName);
    } else if (packageName == 'io.digitable.go.mahajana.human') {
      initMahajana(packageName: packageName);
    } else if (packageName == 'io.digitable.go.malkey.human') {
      initMalkey(packageName: packageName);
    } else {
      initDigitable(packageName: packageName);
    }
  }
}
