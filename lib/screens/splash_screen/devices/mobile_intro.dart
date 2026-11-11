import 'package:auto_size_text/auto_size_text.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cn_pocket_hr/screens/login/login_screen.dart';

class MobileIntro extends StatefulWidget {
  const MobileIntro({Key? key}) : super(key: key);

  @override
  State<MobileIntro> createState() => _MobileIntroState();
}

class _MobileIntroState extends State<MobileIntro> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, HRLogin.routeName);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1D4ED8),
                Color(0xFF3B82F6),
                Color(0xFF60A5FA),
              ],
            ),
          ),
          child: Stack(
            children: [
              // subtle curves
              Positioned(
                left: -120,
                bottom: -200,
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(260),
                  ),
                ),
              ),
              Positioned(
                right: -140,
                bottom: -240,
                child: Container(
                  width: 520,
                  height: 520,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(320),
                  ),
                ),
              ),

              // content
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(color: Color(0x33000000), blurRadius: 28, offset: Offset(0, 14)),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.shield_outlined, size: 64, color: Color(0xFF2563EB)),
                        ),
                      ),
                      const SizedBox(height: 22),

                      AutoSizeText(
                        'HR Connect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Animated loader
                      AnimatedBuilder(
                        animation: _anim,
                        builder: (context, _) {
                          return Transform.rotate(
                            angle: _anim.value * 6.283185307179586,
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                backgroundColor: Colors.white.withOpacity(0.25),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
