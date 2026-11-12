import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/screens/team/devices/mobile_team.dart';
import 'package:cn_pocket_hr/ui/responsive_layout.dart';

class HRTeam extends StatefulWidget {
  static String routeName = "/team";

  const HRTeam({Key? key}) : super(key: key);

  @override
  State<HRTeam> createState() => _HRTeamState();
}

class _HRTeamState extends State<HRTeam> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: MobileTeam(),
    );
  }
}
