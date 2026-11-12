import 'package:cn_pocket_hr/screens/allowances_deductions/devices/mobile_allowances_deductions_screen.dart';
import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/ui/responsive_layout.dart';

class HRAllowancesDeductions extends StatefulWidget {
  static String routeName = "/allowances-deductions";
  HRAllowancesDeductions({Key? key}) : super(key: key);

  @override
  _HRAllowancesDeductionsState createState() => _HRAllowancesDeductionsState();
}

class _HRAllowancesDeductionsState extends State<HRAllowancesDeductions> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: MobileAllowancesDeductionsScreen(),
    );
  }
}
