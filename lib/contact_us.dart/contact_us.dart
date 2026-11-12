import 'package:cn_pocket_hr/contact_us.dart/devices/mobile_contact_us.dart';
import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/ui/responsive_layout.dart';

class HRContactUs extends StatefulWidget {
  static String routeName = "/contact-us";
  HRContactUs({Key? key}) : super(key: key);

  @override
  _HRContactUsState createState() => _HRContactUsState();
}

class _HRContactUsState extends State<HRContactUs> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: ContactUsMobileScreen(),
    );
  }
}
