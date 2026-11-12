import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/screens/attendance/devices/mobile_attendance.dart';
import 'package:cn_pocket_hr/ui/responsive_layout.dart';

class HRAttendance extends StatefulWidget {
  static String routeName = "/attendance";
  const HRAttendance({Key? key}) : super(key: key);

  @override
  _HRAttendanceState createState() => _HRAttendanceState();
}

class _HRAttendanceState extends State<HRAttendance> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: MobileAttendance(),
    );
  }
}
