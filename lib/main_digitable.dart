import 'package:cn_pocket_hr/config/firebase_options_digitable.dart';
import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:cn_pocket_hr/helpers/http_override.dart';
import 'package:cn_pocket_hr/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupHttpOverride();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DigitableFirebaseOptions.currentPlatform);
  }

  FlavorConfig.initDigitable();

  runApp(PocketHR());
}
