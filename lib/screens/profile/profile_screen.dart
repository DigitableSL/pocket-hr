import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/screens/profile/devices/mobile_profile.dart';
import 'package:cn_pocket_hr/ui/responsive_layout.dart';

class HRProfile extends StatefulWidget {
  static String routeName = "/profile";
  const HRProfile({Key? key}) : super(key: key);

  @override
  _HRProfileState createState() => _HRProfileState();
}

class _HRProfileState extends State<HRProfile> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: MobileProfile(),
    );
  }
}
