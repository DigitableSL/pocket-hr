import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cn_pocket_hr/screens/allowances_deductions/allowance.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/screens/salary_slips/salary_slips.dart';
import 'package:cn_pocket_hr/helpers/flutter_rating_bar.dart';
import 'package:cn_pocket_hr/providers/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:cn_pocket_hr/screens/debts_and_loans/debts_and_loans_screen.dart';
import 'package:cn_pocket_hr/screens/todos/todos_screen.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/helpers/logout.dart';
import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cn_pocket_hr/screens/team/team.dart';

class DesignConfig {
  static const double defaultBorderRadius = 8.0;

  static String getFriendlyErrorMessage(BuildContext context, Object? err) {
    if (err == null) return '';
    final l = AppLocalizations.of(context)!;
    String raw = err.toString();

    // Strip leading "Exception:", "Error:", "Exception: Error:", colons and whitespace
    raw = raw.replaceAll(RegExp(r'^(Exception|Error|\s|:)+', caseSensitive: false), '').trim();
    final lower = raw.toLowerCase();

    if (lower.contains('socketexception') ||
        lower.contains('timeoutexception') ||
        lower.contains('timed out') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('handshakeexception') ||
        lower.contains('connectexception') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection reset') ||
        lower.contains('software caused connection abort')) {
      return l.failedToConnectToServer;
    }

    if (lower.contains('401') ||
        lower.contains('403') ||
        lower.contains('unauthenticated') ||
        lower.contains('unauthorized')) {
      return l.sessionExpired;
    }

    if (lower.contains('500') ||
        lower.contains('internal server error') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('<!doctype') ||
        lower.contains('<html') ||
        lower.contains('formatexception')) {
      return l.serverError;
    }

    if (lower.contains('direct manager') || lower.contains('target employee')) {
      return l.todoDirectManagerApprovalRequired;
    }

    return raw;
  }

  static Widget buildErrorState(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AutoSizeText(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: HRColors.orangeColor,
              ),
              child: AutoSizeText(
                AppLocalizations.of(context)!.retryLabel,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static ImageProvider getHomeBgProvider(String path) {
    if (path.startsWith('http') || path.startsWith('https')) {
      return CachedNetworkImageProvider(path);
    } else {
      return AssetImage(path);
    }
  }

  static String getPngImagePath(String imageName) {
    return "assets/images/img/$imageName";
  }

  static String getSvgImagePath(String imageName) {
    return "assets/svg/$imageName";
  }

  static BoxDecoration boxDecorationIntroductionColor(
      Color color1, Color color2, double sizes) {
    return BoxDecoration(
      gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(sizes),
        topRight: Radius.circular(sizes),
      ),
    );
  }

  static RoundedRectangleBorder setRoundedBorder(
      Color bordercolor, double bradius, bool issetside) {
    return RoundedRectangleBorder(
        side: BorderSide(color: bordercolor, width: 0),
        borderRadius: BorderRadius.circular(bradius));
  }

  static BoxDecoration boxDecorationButton(Color color1, Color color2) {
    return BoxDecoration(
      gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight),
      borderRadius: BorderRadius.circular(10),
    );
  }

  static BoxDecoration boxDecorationContainer(Color color, double radius) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration boxDecorationBorderButtonColor(
      Color color, double sizes) {
    return BoxDecoration(
        borderRadius: BorderRadius.circular(sizes),
        border: Border.all(color: color, width: 1));
  }

  static BoxDecoration boxDecorationButtonColor(
      Color color1, Color color2, double sizes) {
    return BoxDecoration(
      gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight),
      borderRadius: BorderRadius.circular(sizes),
    );
  }

  static BoxDecoration boxDecorationLeafButtonColor(
      Color color1, Color color2, double sizes) {
    return BoxDecoration(
      gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(sizes),
        bottomRight: Radius.circular(sizes),
      ),
    );
  }

  // ==================== DRAWER WITH YOUR BG COLOR ====================
  static Widget drawerContent(
      GlobalKey<ScaffoldState> scaffoldKey, BuildContext context) {
    final LocalStorage storage = LocalStorage('pocketHR');

    Widget langPicker() {
      final provider = Provider.of<LocaleProvider>(context);

      return Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            _buildLangButton(provider, storage, 'EN', 'en'),
            _buildLangButton(provider, storage, 'සිං', 'si'),
            _buildLangButton(provider, storage, 'தமிழ்', 'ta'),
          ],
        ),
      );
    }

    final currentRoute = ModalRoute.of(context)?.settings.name;

    Widget buildTile({
      required IconData icon,
      required String title,
      required bool isSelected,
      required VoidCallback onTap,
    }) {
      const selectedBg = Color(0xFF1B172E);
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? Colors.white : Colors.black,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AutoSizeText(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    Widget? buildMenuItem(String key) {
      final l10n = AppLocalizations.of(context)!;
      switch (key) {
        case 'my_team':
          final isSelected = currentRoute == '/team' || currentRoute == HRTeam.routeName;
          return buildTile(
            icon: Icons.people_alt_outlined,
            title: l10n.myTeam,
            isSelected: isSelected,
            onTap: () => Navigator.pushNamed(context, '/team'),
          );
        case 'salary_slips':
          final isSelected = currentRoute == HRSalarySlips.routeName;
          return buildTile(
            icon: Icons.receipt_long_outlined,
            title: l10n.salarySlips,
            isSelected: isSelected,
            onTap: () => Navigator.pushNamed(context, HRSalarySlips.routeName),
          );
        case 'allowance_deductions':
          final isSelected = currentRoute == HRAllowancesDeductions.routeName;
          return buildTile(
            icon: Icons.account_balance_wallet_outlined,
            title: l10n.allowanceDeductions,
            isSelected: isSelected,
            onTap: () => Navigator.pushNamed(
                context, HRAllowancesDeductions.routeName),
          );
        case 'debts_loans':
          final isSelected = currentRoute == HRDebtsAndLoans.routeName;
          return buildTile(
            icon: Icons.payments_outlined,
            title: l10n.debtLoans,
            isSelected: isSelected,
            onTap: () => Navigator.pushNamed(context, HRDebtsAndLoans.routeName),
          );
        case 'todo_list':
          final isSelected = currentRoute == HRTodo.routeName;
          return buildTile(
            icon: Icons.checklist_outlined,
            title: l10n.todos,
            isSelected: isSelected,
            onTap: () => Navigator.pushNamed(context, HRTodo.routeName),
          );
        default:
          return null;
      }
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        height: double.infinity,
        decoration: BoxDecoration(
          color: HRColors.white, // Your requested background color
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12.0,
              offset: Offset(3, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              height: 70,
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: DesignConfig.boxDecorationButtonColor(
                          HRColors.white.withOpacity(0.9),
                          HRColors.white.withOpacity(0.9),
                          50),
                      child: const Icon(Icons.close, color: HRColors.black),
                    ),
                  ),
                  const SizedBox(width: 20),
                  AutoSizeText(
                    AppLocalizations.of(context)!.menuText,
                    style: const TextStyle(
                        fontSize: 20,
                        color: HRColors.black,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Menu List
            Expanded(
              child: FutureBuilder<bool>(
                future: storage.ready,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final profile = storage.getItem('me_profile') as Map<String, dynamic>?;
                  final data = profile != null ? profile['data'] as Map<String, dynamic>? : null;
                  final mobileMenu = data != null ? data['mobileMenu'] as Map<String, dynamic>? : null;
                  final items = mobileMenu != null ? mobileMenu['items'] as List<dynamic>? : null;

                  final defaultKeys = [
                    'my_team',
                    'organization',
                    'salary_slips',
                    'allowance_deductions',
                    'debts_loans',
                    'todo_list'
                  ];

                  List<String> activeKeys = List<String>.from(defaultKeys);
                  if (items != null && items.isNotEmpty) {
                    activeKeys = items
                        .map((e) => e is Map ? (e['key']?.toString() ?? '') : '')
                        .where((k) => k.isNotEmpty)
                        .toList();
                    if (!activeKeys.contains('organization') && !activeKeys.contains('organization_structure')) {
                      final myTeamIdx = activeKeys.indexOf('my_team');
                      if (myTeamIdx != -1) {
                        activeKeys.insert(myTeamIdx + 1, 'organization');
                      } else {
                        activeKeys.insert(0, 'organization');
                      }
                    }
                  }

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      ...activeKeys
                          .map((key) => buildMenuItem(key))
                          .whereType<Widget>()
                          .toList(),
                      const _RefreshListTile(),
                    ],
                  );
                },
              ),
            ),

            // Bottom Section: Language + Logout + Version
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: HRColors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  langPicker(),
                  const SizedBox(height: 4),
                  // Logout button styled like check-in/check-out
                  GestureDetector(
                    onTap: () => LogoutHelper.logout(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: FlavorConfig.instance.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          AutoSizeText(
                            AppLocalizations.of(context)!.logoutText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      String version = "1.0.0";
                      if (snapshot.hasData) {
                        version = snapshot.data!.version;
                        if (snapshot.data!.buildNumber.isNotEmpty) {
                          version =
                              "${snapshot.data!.version}+${snapshot.data!.buildNumber}";
                        }
                      }
                      return Center(
                        child: AutoSizeText(
                          'App Version $version',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildLangButton(LocaleProvider provider, LocalStorage storage,
      String text, String langCode) {
    final currentLang = provider.locale?.languageCode ?? 'en';
    final isSelected = currentLang == langCode;
    const selectedBg = Color(0xFF1B172E);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              provider.setLocale(Locale(langCode));
              storage.setItem('lang', langCode);
            },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? selectedBg : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? selectedBg : Colors.black.withOpacity(0.08),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: AutoSizeText(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13.5,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== FIXED showTopToast (No more TickerProvider error) ====================
  static void showTopToast(BuildContext context, String message,
      {Color? background}) {
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: background ?? const Color(0xFF323232),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                const BoxShadow(color: Colors.black26, blurRadius: 10)
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: AutoSizeText(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  // ==================== OTHER METHODS (unchanged) ====================
  static Widget displayCourseImage(String image, double height, double width) {
    return Image.asset(image, width: width, height: height, fit: BoxFit.fill);
  }

  static Widget displayRating(String rating, bool isfullratingbar) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 5, end: 5),
      child: Row(
        children: <Widget>[
          isfullratingbar
              ? RatingBarIndicator(
                  rating: double.parse(rating),
                  itemBuilder: (context, index) =>
                      const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 14,
                  direction: Axis.horizontal,
                )
              : const Icon(Icons.star, size: 14, color: Colors.amber),
          AutoSizeText("\t\t$rating",
              style: const TextStyle(
                  color: HRColors.white, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  static Widget displayRatingFull(String? rating, bool isfullratingbar) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 5, end: 5),
      child: Row(
        children: <Widget>[
          isfullratingbar
              ? RatingBarIndicator(
                  rating: double.parse(rating!),
                  itemBuilder: (context, index) =>
                      const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 14,
                  direction: Axis.horizontal,
                )
              : const Icon(Icons.star, size: 14, color: Colors.amber),
        ],
      ),
    );
  }
}

// ==================== REFRESH AS LISTTILE (Fixed) ====================
class _RefreshListTile extends StatefulWidget {
  const _RefreshListTile({Key? key}) : super(key: key);

  @override
  __RefreshListTileState createState() => __RefreshListTileState();
}

class __RefreshListTileState extends State<_RefreshListTile>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    _spinController.repeat();

    try {
      final APIService apiService = APIService();
      await apiService.fetchMeProfileWithBearer(forceRefresh: true);

      if (mounted) {
        DesignConfig.showTopToast(
          context,
          AppLocalizations.of(context)!.refreshSuccess,
          background: Colors.green,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        _spinController.stop();
        _spinController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: _isRefreshing ? null : _onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              RotationTransition(
                turns: _spinController,
                child: const Icon(
                  Icons.refresh,
                  size: 22,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AutoSizeText(
                  _isRefreshing
                      ? AppLocalizations.of(context)!.refreshing
                      : AppLocalizations.of(context)!.refresh,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
