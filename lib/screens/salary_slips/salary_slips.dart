import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/screens/salary_slips/devices/mobile_salary_slip.dart';
import 'package:cn_pocket_hr/ui/responsive_layout.dart';

class HRSalarySlips extends StatefulWidget {
  static String routeName = "/salary-slips";

  const HRSalarySlips({Key? key}) : super(key: key);

  @override
  State<HRSalarySlips> createState() => _HRSalarySlipsState();
}

class _HRSalarySlipsState extends State<HRSalarySlips> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: MobileSalarySlip(),
    );
  }
}
