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
  static const double defaultBorderRadius = 14.0;

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
    final Color brandPrimary = HRColors.brandPrimary;
    final Color brandLight = HRColors.brandLight;
    final Color brandDark = HRColors.brandDarkText;

    String resolveUserName() {
      final flat = (storage.getItem('name') ??
              storage.getItem('username') ??
              storage.getItem('userName') ??
              '')
          .toString()
          .trim();
      if (flat.isNotEmpty) return flat;
      final profile = storage.getItem('me_profile');
      if (profile is Map) {
        final d = profile['data'] ?? profile['result'] ?? profile['user'] ?? profile;
        if (d is Map) {
          final fn = (d['name'] ?? d['full_name'] ?? d['first_name'] ?? '').toString().trim();
          if (fn.isNotEmpty) return fn;
        }
      }
      return AppLocalizations.of(context)!.menuText;
    }

    String resolveSubtitle() {
      final comp = (storage.getItem('company') ??
              storage.getItem('tenant') ??
              FlavorConfig.instance.appName)
          .toString()
          .trim();
      if (comp.isEmpty) return '';
      return comp[0].toUpperCase() + comp.substring(1);
    }

    Widget buildTile({
      required IconData icon,
      required String title,
      required bool isSelected,
      required VoidCallback onTap,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brandPrimary.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.18)
                        : brandLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: isSelected ? Colors.white : brandPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AutoSizeText(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : brandDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isSelected
                      ? Colors.white.withOpacity(0.85)
                      : Colors.black26,
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
        decoration: const BoxDecoration(
          color: HRColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16.0,
              offset: Offset(4, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu List with User Profile Header inside FutureBuilder so storage is ready
            Expanded(
              child: FutureBuilder<bool>(
                future: storage.ready,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userName = resolveUserName();
                  final subtitle = resolveSubtitle();
                  final initial =
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Profile Header Card
                      Container(
                        margin: EdgeInsets.fromLTRB(
                          14,
                          MediaQuery.of(context).padding.top + 12,
                          14,
                          10,
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: brandLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: brandPrimary.withOpacity(0.10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: brandPrimary,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AutoSizeText(
                                    userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: brandDark,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: HRColors.brandGreyText,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.06),
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: brandDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(top: 4, bottom: 20),
                          children: [
                            ...activeKeys
                                .map((key) => buildMenuItem(key))
                                .whereType<Widget>()
                                .toList(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              child: Divider(
                                height: 1,
                                color: Colors.black.withOpacity(0.07),
                              ),
                            ),
                            const _RefreshListTile(),
                          ],
                        ),
                      ),
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
              decoration: BoxDecoration(
                color: HRColors.white,
                border: Border(
                  top: BorderSide(color: Colors.black.withOpacity(0.06)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  langPicker(),
                  const SizedBox(height: 4),
                  // Logout button
                  GestureDetector(
                    onTap: () => LogoutHelper.logout(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: FlavorConfig.instance.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                              color: Colors.white, size: 19),
                          const SizedBox(width: 8),
                          AutoSizeText(
                            AppLocalizations.of(context)!.logoutText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
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
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final info = snapshot.data!;
                      final version = info.buildNumber.isNotEmpty
                          ? "${info.version} (Build ${info.buildNumber})"
                          : info.version;
                      return Center(
                        child: AutoSizeText(
                          'App Version $version',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
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
    final selectedBg = HRColors.brandPrimary;

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
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? selectedBg : HRColors.brandLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? selectedBg
                      : HRColors.brandPrimary.withOpacity(0.10),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: AutoSizeText(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : HRColors.brandDarkText,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: _isRefreshing ? null : _onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: HRColors.brandLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: RotationTransition(
                  turns: _spinController,
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 19,
                    color: HRColors.brandPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AutoSizeText(
                  _isRefreshing
                      ? AppLocalizations.of(context)!.refreshing
                      : AppLocalizations.of(context)!.refresh,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: HRColors.brandDarkText,
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
