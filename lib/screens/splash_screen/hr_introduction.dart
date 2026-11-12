import 'package:localstorage/localstorage.dart';
import 'package:cn_pocket_hr/screens/home/devices/mobile_home.dart';
import 'package:cn_pocket_hr/screens/splash_screen/devices/mobile_intro.dart';
import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/ui/responsive_layout.dart';

class HRIntroduction extends StatefulWidget {
  static String routeName = "/intro";

  @override
  HRIntroductionState createState() => HRIntroductionState();
}

class HRIntroductionState extends State<HRIntroduction> {
  final LocalStorage storage = LocalStorage('pocketHR');
  APIService apiService = APIService();
  late bool isLogin = false;

  @override
  void initState() {
    super.initState();
    if (storage.getItem('login') == true ||
        storage.getItem('login') == "true") {
      setState(() {
        isLogin = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLogin
        ? const ResponsiveLayout(mobileBody: MobileHome())
        : ResponsiveLayout(
            mobileBody: MobileIntro(),
          );
  }
}
