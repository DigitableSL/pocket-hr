import 'package:auto_size_text/auto_size_text.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
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

class TabletLogin extends StatefulWidget {
  const TabletLogin({Key? key}) : super(key: key);

  @override
  State<TabletLogin> createState() => _TabletLoginState();
}

class _TabletLoginState extends State<TabletLogin> {
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

  static const Color _accent =
      Color(0xFFF59E0B); // close to HRColors.orangeColor
  static const Color _surface = Color.fromARGB(255, 248, 250, 252);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _autoLoginIfPossible();
  }

  Future<void> _autoLoginIfPossible() async {
    try {
      await storage.ready;
      final ok = await apiService.hasValidAccessToken();
      if (!ok) {
        // clear any stale tokens
        try {
          await storage.setItem('access_token', '');
          await storage.setItem('refresh_token', '');
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

        Navigator.of(context).pushReplacementNamed(HRMain.routeName);
        return;
      } catch (e) {
        // fetch failed — clear tokens and show login
        try {
          await storage.setItem('access_token', '');
          await storage.setItem('refresh_token', '');
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
      fillColor: _surface,
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
      apiService.showToast('Failed to login.');
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
      storage.setItem('access_token', result.accessToken);
      storage.setItem('refresh_token', result.refreshToken);
      storage.setItem('tenant', tenantName);

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
      apiService.showToast(e.toString());
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
          body: Center(
              child: CupertinoActivityIndicator(
        color: HRColors.darkOrangeColor,
        radius: 16.0,
      )));
    }

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Top header image
            Positioned.fill(
              child: Container(color: Colors.white),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.52,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
                child: Image.asset(
                  'assets/images/login.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // slight dark overlay for readability
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.82,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(48),
                    bottomRight: Radius.circular(48),
                  ),
                  color: Colors.black.withOpacity(0.10),
                ),
              ),
            ),

            // White bottom sheet
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 22,
                  right: 22,
                  top: 18,
                  bottom: 18 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(34),
                    topRight: Radius.circular(34),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        AutoSizeText(
                          AppLocalizations.of(context)!.signIn,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const SizedBox(height: 4),

                        if (isLoading)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: CupertinoActivityIndicator(
                                color: HRColors.darkOrangeColor,
                                radius: 16.0,
                              ),
                            ),
                          ),

                        const SizedBox(height: 4),
                        // SizedBox(
                        //   width: double.infinity,
                        //   height: 48,
                        //   child: ElevatedButton(
                        //     onPressed: buttonDisable ? null : () async {
                        //       // Validate company and NIC
                        //       setState(() {
                        //         _validateCompany = company.text.isEmpty;
                        //         _validateEmail = nicController.text.isEmpty;
                        //       });
                        //       if (_validateCompany || _validateEmail) return;

                        //       setState(() { isLoading = true; buttonDisable = true; });
                        //       try {
                        //         // collect minimal device info
                        //         Map<String, String> deviceInfo = {};
                        //         try {
                        //           final dsvc = DeviceDetailsService();
                        //           final details = await dsvc.collectAll();
                        //           final dev = details['device'] as Map<String, dynamic>? ?? {};
                        //           deviceInfo['model_number'] = (dev['model'] ?? '').toString();
                        //           deviceInfo['device_id'] = (dev['androidId'] ?? dev['identifierForVendor'] ?? '').toString();
                        //           deviceInfo['ip_address'] = (details['ip'] ?? '').toString();
                        //         } catch (_) {}

                        //         final tenantName = company.text.trim();
                        //         final nic = nicController.text.trim();

                        //         // Request OTP
                        //         final req = await apiService.sendAuthPinMobile(tenant: tenantName, nic: nic, deviceInfo: deviceInfo);
                        //         if (req['status'] == false) {
                        //           apiService.showToast(req['message'] ?? 'Failed to request OTP');
                        //           return;
                        //         }

                        //         // Open OTP page
                        //         final otp = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const OtpPage()));
                        //         if (otp == null || otp.isEmpty) return;

                        //         // Verify OTP
                        //         final verify = await apiService.verifyAuthPinMobile(tenant: tenantName, nic: nic, pin: otp, deviceInfo: deviceInfo);
                        //         if (verify['status'] == false) {
                        //           apiService.showToast(verify['message'] ?? 'OTP verification failed');
                        //           return;
                        //         }

                        //         // verification success: redirect to main
                        //         if (!mounted) return;
                        //         Navigator.pushReplacementNamed(context, HRMain.routeName);
                        //       } catch (e, st) {
                        //         debugPrint('[LOGIN][OTP] ERROR: $e');
                        //         debugPrint(st.toString());
                        //         apiService.showToast('Something went wrong. Please try again');
                        //       } finally {
                        //         if (mounted) setState(() { isLoading = false; buttonDisable = false; });
                        //       }
                        //     },
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: _accent,
                        //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        //       elevation: 0,
                        //     ),
                        //     child: AutoSizeText(AppLocalizations.of(context)!.nextText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        //   ),
                        // ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: buttonDisable ? null : _ssoLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AutoSizeText(
                                  AppLocalizations.of(context)!.continueText,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 22),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        // Center(
                        //   child: Wrap(
                        //     spacing: 4,
                        //     children: [
                        //       AutoSizeText("Don't have an Account?", style: TextStyle(color: Colors.black.withOpacity(0.45), fontWeight: FontWeight.w700, fontSize: 12)),
                        //       TextButton(
                        //          onPressed: () => apiService.showToast('Coming soon'),
                        //         child: AutoSizeText('Sign up', style: TextStyle(fontWeight: FontWeight.w900, color: Color.fromARGB(255, 243, 241, 238))),
                        //       )
                        //     ],
                        //   ),
                        // ),

                        langPicker(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
