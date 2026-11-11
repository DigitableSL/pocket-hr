import 'package:auto_size_text/auto_size_text.dart';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/screens/attendance/attendance_screen.dart';
import 'package:cn_pocket_hr/screens/home/home_screen.dart';
import 'package:cn_pocket_hr/screens/leave/leave_screen.dart';
import 'package:cn_pocket_hr/screens/profile/profile_screen.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:cn_pocket_hr/helpers/design_config.dart';
import 'package:cn_pocket_hr/helpers/liquid_side_menu.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';
import 'package:cn_pocket_hr/services/security_service.dart';
import 'package:line_icons/line_icons.dart';

class HRMain extends StatefulWidget {
  static String routeName = "/main";

  final int? id;
  const HRMain({Key? key, this.id}) : super(key: key);

  @override
  State<HRMain> createState() => _HRMainState();
}

class _HRMainState extends State<HRMain> with WidgetsBindingObserver {
  int selectedIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<Widget> fragments;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    fragments = [
      HRHome(),
      const HRLeave(),
      const HRAttendance(),
      const HRProfile(),
    ];

    selectedIndex = widget.id ?? 0;

    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isClean = await SecurityService.verifyDeviceSecurity(context: context);
      if (!isClean) return;
      SecurityService.startContinuousMonitoring();
      await FCMService.initialize();
      FCMService.sendTokenToBackend();
    });
  }

  @override
  void dispose() {
    SecurityService.pauseContinuousMonitoring();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SecurityService.resumeContinuousMonitoring(context: context);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      SecurityService.pauseContinuousMonitoring();
    }
  }

  void updateTabSelection(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              Platform.isIOS ? Brightness.light : Brightness.dark,
          statusBarBrightness:
              Platform.isIOS ? Brightness.dark : Brightness.light,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
        child: LiquidSideMenu(
          menu: DesignConfig.drawerContent(_scaffoldKey, context),
          child: Scaffold(
            key: _scaffoldKey,
            extendBody: true,
            backgroundColor: Colors.transparent,
            body: fragments[selectedIndex],

            // Bubble-style bottom navigation (white pill)
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  height: 64,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: HRColors.bottomNavBarBgColor,
                    borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x24000000),
                          blurRadius: 24,
                          offset: Offset(0, 10)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          _navItem(LineIcons.qrcode,
                              AppLocalizations.of(context)!.punchText, 0),
                          _navItem(LineIcons.umbrellaBeach,
                              AppLocalizations.of(context)!.leaveText, 1),
                          _navItem(LineIcons.calendarCheck,
                              AppLocalizations.of(context)!.attendanceText, 2),
                          _navItem(LineIcons.userCircle,
                              AppLocalizations.of(context)!.profileText, 3),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = selectedIndex == index;

    String cleanLabel = label;
    if (label == AppLocalizations.of(context)!.leaveText) {
      final locale = Localizations.localeOf(context).languageCode;
      cleanLabel = locale == 'en' ? 'Leave' : AppLocalizations.of(context)!.teamLeavesText;
    } else if (label == AppLocalizations.of(context)!.attendanceText) {
      cleanLabel = AppLocalizations.of(context)!.attendanceText;
    }

    return Expanded(
      flex: isSelected ? 2 : 1,
      child: GestureDetector(
        onTap: () => updateTabSelection(index),
        child: Container(
          color: Colors.transparent,
          height: 64,
          child: Align(
            alignment: isSelected
                ? (index == 0
                    ? Alignment.centerLeft
                    : (index == 3 ? Alignment.centerRight : Alignment.center))
                : Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              height: 64,
              padding: isSelected
                  ? EdgeInsets.only(
                      left: index == 0 ? 24.0 : 16.0,
                      right: index == 3 ? 24.0 : 16.0,
                    )
                  : const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? HRColors.bottomNavIconBgColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
              ),
              child: Center(
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 24,
                      color: isSelected ? HRColors.bottomNavIconColor : Colors.white,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Text(
                        cleanLabel,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: HRColors.bottomNavIconColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
