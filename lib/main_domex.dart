import 'package:cn_pocket_hr/config/firebase_options_domex.dart';
import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:cn_pocket_hr/helpers/http_override.dart';
import 'package:cn_pocket_hr/main.dart'; // Ensure this points to your app widget
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // Required for splash control

Future<void> main() async {
  // 1. Initialize binding and immediately preserve the native splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 2. Run initialization tasks
  setupHttpOverride();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, 
    DeviceOrientation.portraitDown,
  ]);

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DomexFirebaseOptions.currentPlatform);
  }

  // 3. Define branding/config
  FlavorConfig.initDomex();

  // 5. Remove the splash screen now that app is ready
  FlutterNativeSplash.remove();

  // 6. Launch the application
  runApp( PocketHR());
}