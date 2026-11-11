import 'package:auto_size_text/auto_size_text.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:cn_pocket_hr/providers/connection_provider.dart';

import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/screens/main/main_screen.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/providers/locale_provider.dart';
import 'package:cn_pocket_hr/services/sso_service.dart';
import 'package:cn_pocket_hr/services/device_details_service.dart';
import 'package:cn_pocket_hr/screens/login/otp_page.dart';
import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';
import 'package:cn_pocket_hr/services/security_service.dart';
import 'package:cn_pocket_hr/services/secure_token_service.dart';

class MobileLogin extends StatefulWidget {
  const MobileLogin({Key? key}) : super(key: key);

  @override
  State<MobileLogin> createState() => _MobileLoginState();
}

class _MobileLoginState extends State<MobileLogin>
    with TickerProviderStateMixin {
  final email = TextEditingController();
  final password = TextEditingController();
  final company = TextEditingController();
  final nicController = TextEditingController();

  // Focus nodes to support Next/Done keyboard actions
  final FocusNode _companyFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _validateEmail = false;
  bool _validatePassword = false;
  bool _validateCompany = false;

  bool isLoading = false;
  bool buttonDisable = false;

  final LocalStorage storage = LocalStorage('pocketHR');
  final APIService apiService = APIService();
  final SsoService _ssoService = SsoService();

  bool _autoRedirecting = true;

  bool _obscure = true;

  late AnimationController _animController;
  late Animation<double> _logoScale;
  late Animation<double> _bottomFade;
  late Animation<Offset> _bottomSlide;

  late AnimationController _floatController;
  late Animation<double> _floatOffset;

  String _appVersion = '';
  String _appName = '';

  static const Color _accent =
      Color(0xFFF59E0B); // close to HRColors.orangeColor
  static const Color _surface = Color.fromARGB(255, 248, 250, 252);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );

    _bottomFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _bottomSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    ));

    // Floating up/down loop — starts after scale animation finishes
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _floatOffset = Tween<double>(begin: -9.0, end: 9.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _floatController.repeat(reverse: true);
      }
    });

    _loadVersionAndStartAnimation();
    _autoLoginIfPossible();
  }

  Future<void> _loadVersionAndStartAnimation() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted)
        setState(() {
          _appVersion = 'v${info.version}';
          _appName = FlavorConfig.instance.appName;
        });
    } catch (_) {
      if (mounted) setState(() => _appName = FlavorConfig.instance.appName);
    }
    if (mounted) _animController.forward();
  }

  Future<void> _autoLoginIfPossible() async {
    try {
      final isSecure =
          await SecurityService.verifyDeviceSecurity(context: context);
      if (!isSecure) {
        if (mounted) setState(() => _autoRedirecting = false);
        return;
      }

      await storage.ready;
      await SecureTokenService.ensureInitialized();
      final ok = await apiService.hasValidAccessToken();
      if (!ok) {
        // clear any stale tokens
        try {
          await SecureTokenService.clearTokens();
          await storage.setItem('tenant', '');
        } catch (_) {}
        if (mounted) setState(() => _autoRedirecting = false);
        return;
      }

      // Token exists and not expired — try to fetch profile to ensure server accepts it
      try {
        await apiService.fetchMeProfileWithBearer();
        await FCMService.initialize();
        final fcmToken = await FCMService.getToken();
        if (fcmToken == null || fcmToken.isEmpty) {
          apiService.showToast(AppLocalizations.of(context)!.fcmTokenError);
        } else if (fcmToken.startsWith('ERROR:')) {
          apiService.showToast(fcmToken);
        }
        FCMService.sendTokenToBackend();

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(HRMain.routeName);
        return;
      } catch (e) {
        // fetch failed — clear tokens and show login
        try {
          await SecureTokenService.clearTokens();
          await storage.setItem('tenant', '');
        } catch (_) {}
        if (mounted) setState(() => _autoRedirecting = false);
        return;
      }
    } catch (_) {
      if (mounted) setState(() => _autoRedirecting = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _floatController.dispose();
    _companyFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    email.dispose();
    password.dispose();
    nicController.dispose();
    company.dispose();
    super.dispose();
  }

  Widget langPicker() {
    final provider = Provider.of<LocaleProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _langButton('EN', () {
            provider.setLocale(const Locale('en'));
            storage.setItem('lang', 'en');
          }),
          _langButton('සිං', () {
            provider.setLocale(const Locale('si'));
            storage.setItem('lang', 'si');
          }),
          _langButton('தமிழ்', () {
            provider.setLocale(const Locale('ta'));
            storage.setItem('lang', 'ta');
          }),
        ],
      ),
    );
  }

  Widget _langButton(String label, VoidCallback onTap) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _surface,
          foregroundColor: Colors.black87,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: AutoSizeText(label,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  InputDecoration _fieldDecoration(
      {required String label,
      required String hint,
      required IconData icon,
      Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
          color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w800),
      hintText: hint,
      hintStyle: const TextStyle(
          color: Colors.black38, fontSize: 12, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: Colors.black45, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _accent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.6),
      ),
    );
  }

  Widget inputTenant() {
    // Formatter to force lowercase
    final lowerCaseFormatter =
        TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text.toLowerCase();
      return TextEditingValue(
          text: text, selection: TextSelection.collapsed(offset: text.length));
    });

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: company,
        focusNode: _companyFocus,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) =>
            FocusScope.of(context).requestFocus(_emailFocus),
        onChanged: (_) => setState(() => _validateCompany = false),
        style: const TextStyle(
            color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w700),
        cursorColor: _accent,
        inputFormatters: [
          lowerCaseFormatter,
          // allow only simple letters (a-z), numbers and spaces
          FilteringTextInputFormatter.allow(RegExp('[a-z0-9 ]')),
        ],
        decoration: _fieldDecoration(
          label: AppLocalizations.of(context)!.companyName,
          hint: AppLocalizations.of(context)!.tenantHint,
          icon: Icons.apartment_rounded,
        ),
      ),
    );
  }

  // Widget inputEmail() {
  //   return Padding(
  //     padding: const EdgeInsets.only(top: 10),
  //     child: TextFormField(
  //       controller: email,
  //       focusNode: _emailFocus,
  //       textInputAction: TextInputAction.next,
  //       onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
  //       onChanged: (_) => setState(() => _validateEmail = false),
  //       style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w700),
  //       cursorColor: _accent,
  //       decoration: _fieldDecoration(
  //         label: AppLocalizations.of(context)!.emailAddressText,
  //         hint: 'name@email.com',
  //         icon: Icons.mail_outline_rounded,
  //       ),
  //       keyboardType: TextInputType.emailAddress,
  //     ),
  //   );
  // }

  // Widget inputPassword() {
  //   return Padding(
  //     padding: const EdgeInsets.only(top: 10),
  //     child: TextFormField(
  //       controller: password,
  //       focusNode: _passwordFocus,
  //       textInputAction: TextInputAction.done,
  //       onFieldSubmitted: (_) => submit(),
  //       obscureText: _obscure,
  //       onChanged: (_) => setState(() => _validatePassword = false),
  //       style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w700),
  //       cursorColor: _accent,
  //       decoration: _fieldDecoration(
  //         label: AppLocalizations.of(context)!.passwordText,
  //         hint: '',
  //         icon: Icons.lock_outline_rounded,
  //         suffix: IconButton(
  //           onPressed: () => setState(() => _obscure = !_obscure),
  //           icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black45, size: 20),
  //         ),
  //       ),
  //       keyboardType: TextInputType.visiblePassword,
  //     ),
  //   );
  // }

  // Widget inputNic() {
  //   return Padding(
  //     padding: const EdgeInsets.only(top: 10),
  //     child: TextFormField(
  //       controller: nicController,
  //       textInputAction: TextInputAction.next,
  //       onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
  //       onChanged: (_) => setState(() => _validateEmail = false),
  //       style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w700),
  //       cursorColor: _accent,
  //       decoration: _fieldDecoration(
  //         label: AppLocalizations.of(context)!.nic,
  //         hint: AppLocalizations.of(context)!.nic,
  //         icon: Icons.badge_outlined,
  //       ),
  //       keyboardType: TextInputType.text,
  //     ),
  //   );
  // }

  Widget _errorText(bool show, String text) {
    if (!show) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AutoSizeText(text,
            style: const TextStyle(
                color: Colors.red, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void submit() async {
    // Convert submit to use OTP flow (no direct login call)
    setState(() {
      _validateCompany = company.text.isEmpty;
      _validateEmail = nicController.text.isEmpty;
    });
    if (_validateCompany || _validateEmail) return;

    setState(() {
      isLoading = true;
      buttonDisable = true;
    });
    try {
      storage.setItem('company', company.text);
      storage.setItem('email', email.text);
      storage.setItem('password', password.text);

      Map<String, String> deviceInfo = {};
      try {
        final dsvc = DeviceDetailsService();
        final details = await dsvc.collectAll();
        final dev = details['device'] as Map<String, dynamic>? ?? {};
        deviceInfo['model_number'] = (dev['model'] ?? '').toString();
        deviceInfo['device_id'] =
            (dev['androidId'] ?? dev['identifierForVendor'] ?? '').toString();
        deviceInfo['ip_address'] = (details['ip'] ?? '').toString();
      } catch (_) {}

      final tenantName = company.text.trim();
      final nic = nicController.text.trim();

      // final req = await apiService.sendAuthPinMobile(tenant: tenantName, nic: nic, deviceInfo: deviceInfo);
      // if (req['status'] == false) {
      //   apiService.showToast(req['message'] ?? 'Failed to request OTP');
      //   return;
      // }

      final otp = await Navigator.of(context)
          .push<String>(MaterialPageRoute(builder: (_) => const OtpPage()));
      if (otp == null || otp.isEmpty) return;

      // final verify = await apiService.verifyAuthPinMobile(tenant: tenantName, nic: nic, pin: otp, deviceInfo: deviceInfo);
      // if (verify['status'] == false) {
      //   apiService.showToast(verify['message'] ?? 'OTP verification failed');
      //   return;
      // }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, HRMain.routeName);
    } catch (e, st) {
      debugPrint('[SUBMIT][OTP] ERROR: $e');
      debugPrint(st.toString());
      apiService.showToast(AppLocalizations.of(context)!.loginFailed);
    } finally {
      if (mounted)
        setState(() {
          isLoading = false;
          buttonDisable = false;
        });
    }
  }

  Future<void> _ssoLogin() async {
    final conn = Provider.of<ConnectionProvider>(context, listen: false);
    if (!conn.isOnline) {
      apiService.showToast(AppLocalizations.of(context)!.noInternetConnection);
      return;
    }

    final isSecure = await SecurityService.verifyDeviceSecurity(context: context);
    if (!isSecure) {
      return;
    }
    setState(() {
      isLoading = true;
      buttonDisable = true;
    });

    try {
      final tenantName = FlavorConfig.instance.tenant ?? company.text.trim();
      if (tenantName.isEmpty) {
        setState(() {
          _validateCompany = true;
          isLoading = false;
          buttonDisable = false;
        });
        return;
      }

      final result = await _ssoService.signIn(tenant: tenantName, context: context);
      await SecureTokenService.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await storage.setItem('tenant', tenantName);

      // Ensure uid is derived from access token for later API calls (e.g., QR locations-by-userid)
      try {
        final ensuredUid = await apiService.ensureUidFromAccessToken();
        if (ensuredUid != null && ensuredUid.isNotEmpty) {
          await storage.setItem('uid', ensuredUid);
        }
      } catch (_) {}

      await FCMService.initialize();
      final fcmToken = await FCMService.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        apiService.showToast(AppLocalizations.of(context)!.fcmTokenError);
      } else if (fcmToken.startsWith('ERROR:')) {
        apiService.showToast(fcmToken);
      }
      FCMService.sendTokenToBackend();

      setState(() {
        isLoading = false;
        buttonDisable = false;
      });

      if (!mounted) return;
      Navigator.pushNamed(context, HRMain.routeName);
    } catch (e, st) {
      debugPrint('[SSO][UI][ERROR] $e');
      debugPrint(st.toString());
      apiService.showToast(AppLocalizations.of(context)!.ssoFailed);
      setState(() {
        isLoading = false;
        buttonDisable = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_autoRedirecting) {
      return Scaffold(
        backgroundColor: HRColors.splashbackgroundColor,
        body: Center(
          child: CupertinoActivityIndicator(
            color: HRColors.darkOrangeColor,
            radius: 16.0,
          ),
        ),
      );
    }

    final primary = FlavorConfig.instance.primaryColor;
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: HRColors.splashbackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Logo: slightly above center, scale + float animations ────
              Align(
                alignment: const Alignment(0, -0.35),
                child: ScaleTransition(
                  scale: _logoScale,
                  child: AnimatedBuilder(
                    animation: _floatOffset,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _floatOffset.value),
                      child: child,
                    ),
                    child: Image.asset(
                      FlavorConfig.instance.splashLogoAsset,
                      width: 192.0,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // ── Bottom panel: slides + fades in after logo ───────────────
              Align(
                alignment: const Alignment(0, 0.95),
                child: FadeTransition(
                  opacity: _bottomFade,
                  child: SlideTransition(
                    position: _bottomSlide,
                    child: Padding(
                      padding:
                          EdgeInsets.fromLTRB(24, 0, 24, 28 + bottomPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // SSO Login button — centered, wide
                          SizedBox(
                            width: size.width * 0.90,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: buttonDisable ? null : _ssoLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary == HRColors.splashbackgroundColor
                                    ? const Color(0xFF486A85)
                                    : primary,
                                side: primary == HRColors.splashbackgroundColor
                                    ? BorderSide(color: Colors.white.withOpacity(0.25), width: 1.2)
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4, // 👈 small shadow
                                shadowColor: Colors.black
                                    .withOpacity(0.9), // 👈 soft shadow
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 14,
                                ),
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          HRColors.splashred,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AutoSizeText(
                                          AppLocalizations.of(context)!
                                              .continueText,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Language picker
                          langPicker(),

                          const SizedBox(height: 16),

                          // App name + version — centered at bottom
                          Center(
                            child: Text(
                              [_appName, _appVersion]
                                  .where((s) => s.isNotEmpty)
                                  .join('  •  '),
                              style: TextStyle(
                                fontSize: 14,
                                color: HRColors.textYellow,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
// "lat":6.887676381202608,"lng":79.85718849559953,
// lat: 6.887523333333333, lng: 79.857135
//  lat: 6.887676381202608, lng: 79.85718849559953,    bkend 
// lat: 6.8875253, lng: 79.8571109, body 


 //lat: 6.8875595, lng: 79.8571119