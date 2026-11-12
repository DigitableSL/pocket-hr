import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/screens/top_bar/devices/mobile_top_bar.dart';
import 'package:cn_pocket_hr/ui/responsive_layout.dart';

class TopBar extends StatefulWidget {
  const TopBar(
      {Key? key,
      required this.extendBody,
      required this.drawerScrimColor,
      required this.drawer})
      : super(key: key);

  final extendBody;
  final drawerScrimColor;
  final drawer;

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: MobileTopBar(
          extendBody: widget.extendBody,
          drawerScrimColor: widget.drawerScrimColor,
          drawer: widget.drawer),
    );
  }
}
