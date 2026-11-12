import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/screens/home/devices/mobile_home.dart';
import 'package:cn_pocket_hr/ui/responsive_layout.dart';

class HRHome extends StatefulWidget {
  static String routeName = "/home";
  HRHome({Key? key}) : super(key: key);

  @override
  _HRHomeState createState() => _HRHomeState();
}

class _HRHomeState extends State<HRHome> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: MobileHome(),
    );
  }
}
