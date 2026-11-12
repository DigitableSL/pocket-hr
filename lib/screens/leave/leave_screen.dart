import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/screens/leave/devices/mobile_leave.dart';
import 'package:cn_pocket_hr/ui/responsive_layout.dart';

class HRLeave extends StatefulWidget {
  static String routeName = "/leave";

  const HRLeave({Key? key}) : super(key: key);

  @override
  _HRLeaveState createState() => _HRLeaveState();
}

class _HRLeaveState extends State<HRLeave> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: MobileLeave(),
    );
  }
}
