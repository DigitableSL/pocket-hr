import 'package:cn_pocket_hr/ui/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/screens/debts_and_loans/devices/mobile_debts_and_loans_screen.dart';

class HRDebtsAndLoans extends StatefulWidget {
  static String routeName = '/debts-loans';

  @override
  State<HRDebtsAndLoans> createState() => _HRDebtsAndLoansState();
}

class _HRDebtsAndLoansState extends State<HRDebtsAndLoans> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: MobileDebtsAndLoansScreen(),
    );
  }
}
