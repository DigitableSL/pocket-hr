import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/screens/organization/devices/mobile_organization.dart';
import 'package:cn_pocket_hr/ui/responsive_layout.dart';

class HROrganization extends StatefulWidget {
  static String routeName = "/organization";

  const HROrganization({Key? key}) : super(key: key);

  @override
  State<HROrganization> createState() => _HROrganizationState();
}

class _HROrganizationState extends State<HROrganization> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: MobileOrganization(),
    );
  }
}
