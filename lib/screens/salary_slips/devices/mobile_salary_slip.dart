import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart' show AppLocalizations;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
// import 'package:cn_pocket_hr/screens/salary_slips/devices/mobile_salary_slip_detail.dart';

import 'package:cn_pocket_hr/constants/slideanimation.dart';
import 'package:cn_pocket_hr/screens/notifications/notifications.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';
import 'package:cn_pocket_hr/helpers/design_config.dart';

class MobileSalarySlip extends StatefulWidget {
  const MobileSalarySlip({Key? key}) : super(key: key);

  @override
  State<MobileSalarySlip> createState() => _MobileSalarySlipState();
}

class _MobileSalarySlipState extends State<MobileSalarySlip>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AnimationController? _animationController;
  final APIService _api = APIService();
  bool _shownSalaryMessage =
      false; // guard to show API message only once per page load

  // Theme aligned with Attendance / Leave screens
  static const Color _pageBg = Color.fromARGB(255, 248, 250, 252);
  static const Color _surface = Color.fromARGB(255, 248, 250, 252);
  static const double _g8 = 8;
  static const double _g12 = 12;
  static const double _g16 = 16;

  // Fonts (keep sizes; normalize weights)
  static const FontWeight _wSemi = FontWeight.w600;
  static const FontWeight _wBold = FontWeight.w700;
  static const FontWeight _wBlack = FontWeight.w900;

  // Render HTML only when there is actual content to show.
  bool get _hasHtml => htmlData.trim().isNotEmpty;

  void showTopToast(String message,
      {Color? background,
      Duration duration = const Duration(seconds: 3),
      VoidCallback? onTap}) {
    final overlay = Overlay.of(context);

    final animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    final animation =
        CurvedAnimation(parent: animController, curve: Curves.easeOut);

    late OverlayEntry entry;
    entry = OverlayEntry(builder: (ctx) {
      return Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 12,
        right: 12,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(animation),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                try {
                  animController.reverse();
                  entry.remove();
                  animController.dispose();
                } catch (_) {}
                if (onTap != null) onTap();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: background ?? const Color(0xFF323232),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8)
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: AutoSizeText(message,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });

    overlay.insert(entry);
    animController.forward();

    Future.delayed(duration, () async {
      try {
        await animController.reverse();
        entry.remove();
        animController.dispose();
      } catch (_) {}
    });
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    // kick off load
    _loadSlips();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Widget _topActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_g16, _g8, _g16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: HRColors.flavorIconBackgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Center(
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: HRColors.flavorIconColor, size: 18),
              ),
            ),
          ),
          AutoSizeText(
            AppLocalizations.of(context)!.salarySlips,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: HRColors.brandDarkText,
            ),
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, HRNotifications.routeName);
              await FCMService.loadUnreadCount();
            },
            child: ValueListenableBuilder<int>(
              valueListenable: FCMService.unreadCount,
              builder: (context, count, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: HRColors.flavorIconBackgroundColor ?? Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        "assets/svg/notifications_icon.svg",
                        colorFilter: ColorFilter.mode(
                            HRColors.flavorIconColor, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _topActions(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _g16),
                    child: Column(
                      children: [
                        const SizedBox(height: _g12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AutoSizeText(
                            AppLocalizations.of(context)!.salarySlipHistory,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: _wBold),
                          ),
                        ),
                        const SizedBox(height: _g12),
                        showSlips(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_hasHtml) showHtml(),
          ],
        ),
      ),
    );
  }

  Widget showSlips() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _api.getSalarySlips(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Padding(
              padding: const EdgeInsets.symmetric(vertical: 300),
              child: Center(
                  child: CupertinoActivityIndicator(
                color: HRColors.darkOrangeColor,
                radius: 16.0,
              )));
        }

        final data = snap.data!;
        final int statusCode = (data['statusCode'] ?? 200) as int;
        final String apiMsg = data['message']?.toString() ?? '';
        final List<Map<String, dynamic>> items =
            (data['slips'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        // Check for specific API Network Validation Bounds Mapping logic
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_shownSalaryMessage) {
            String? toastMsg;
            if (statusCode == 401 || statusCode == 403) {
              toastMsg = AppLocalizations.of(context)!.sessionExpired;
              if (apiMsg.isNotEmpty && apiMsg != 'serverError')
                toastMsg = apiMsg;
            }

            if (toastMsg != null && toastMsg.isNotEmpty) {
              showTopToast(
                toastMsg,
                background: HRColors.darkOrangeColor,
                duration: const Duration(seconds: 4),
              );
            }
            _shownSalaryMessage = true;
          }
        });

        if (statusCode >= 400) {
          final rawErr = data['error'];
          final errText = rawErr != null
              ? DesignConfig.getFriendlyErrorMessage(context, rawErr)
              : (apiMsg == 'serverError'
                  ? AppLocalizations.of(context)!.serverError
                  : (apiMsg.isNotEmpty ? apiMsg : AppLocalizations.of(context)!.serverError));
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: DesignConfig.buildErrorState(
              context,
              message: errText,
              onRetry: _loadSlips,
            ),
          );
        }

        if (items.isEmpty)
          return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                  child:
                      AutoSizeText(AppLocalizations.of(context)!.noRecords)));

        // convert to _HomeItem list taking dynamic fields from the backend
        final list = items.map((m) {
          final belongsToStr = (m['belongs_to'] ?? '').toString();

          String titleStr =
              AppLocalizations.of(context)!.salarySlips; // default title
          String subStr = '';

          if (belongsToStr.isNotEmpty) {
            final parts = belongsToStr.split('-');
            if (parts.length == 2) {
              try {
                final monthNum = int.parse(parts[0]);
                final dt = DateTime(2000, monthNum, 1);
                final formattedMonth = DateFormat('MMM').format(dt);
                titleStr = "$formattedMonth ${parts[1]}";
                subStr = AppLocalizations.of(context)!.salarySlipLabel;
              } catch (_) {
                titleStr = belongsToStr;
              }
            } else {
              titleStr = belongsToStr;
            }
          } else {
            titleStr = (m['month'] ?? m['title'] ?? 'Salary Slip').toString();
            subStr = (m['year'] ?? m['subtitle'] ?? 'Slip details').toString();
            titleStr = "$titleStr $subStr".trim();
            subStr = AppLocalizations.of(context)!.salarySlips;
          }

          final netPay = (m['net_pay'] ?? 0).toString();

          return _HomeItem(
            items.indexOf(m),
            titleStr,
            subStr,
            HRColors.darkOrangeColor,
            from: '',
            to: '',
            pdfUrl: (m['pdfUrl'] ?? '').toString(),
            id: (m['_id'] ?? m['id'] ?? '').toString(),
            amountStr: AppLocalizations.of(context)!.rs + " $netPay",
            rawData: m, // Pass the entire map as rawData
          );
        }).toList();

        return _buildListFromData(context, list);
      },
    );
  }

  Widget _buildListFromData(BuildContext context, List<_HomeItem> items) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: items.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        final it = items[index];

        return SlideAnimation(
          position: index,
          itemCount: items.length,
          slideDirection: SlideDirection.fromLeft,
          animationController: _animationController,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  showTopToast(
                    AppLocalizations.of(context)!.loading,
                    background: HRColors.darkOrangeColor,
                    duration: const Duration(seconds: 1),
                  );

                  final resp = await _api.emailSalarySlip(it.id);
                  final status = resp['status'] ?? false;
                  final msg = resp['message'] ?? '';
                  final dataBytes = resp['data'] as List<int>?;

                  if (status && dataBytes != null) {
                    try {
                      final dir = await getTemporaryDirectory();
                      final file = File('${dir.path}/salary_slip_${it.id}.pdf');
                      await file.writeAsBytes(dataBytes);

                      showTopToast(
                        "Downloaded successfully!",
                        background: Colors.green,
                        duration: const Duration(seconds: 3),
                      );

                      await OpenAppFile.open(file.path);
                    } catch (e) {
                      showTopToast(
                        "Failed to save slip: $e",
                        background: Colors.red,
                        duration: const Duration(seconds: 3),
                      );
                    }
                  } else {
                    final rawErr = resp['error'];
                    showTopToast(
                      rawErr != null
                          ? DesignConfig.getFriendlyErrorMessage(context, rawErr)
                          : (msg.isEmpty ? "Failed to download" : msg),
                      background: Colors.red,
                      duration: const Duration(seconds: 3),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              it.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: _wBold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AutoSizeText(
                              it.subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: _wSemi,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AutoSizeText(
                            it.amountStr ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _wBlack,
                              color: HRColors.darkOrangeColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.black26,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _loadSlips() async {
    setState(() {});
  }

  final htmlData = r"""   """;

  Widget showHtml() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() {}),
        child: Container(
          color: Colors.black.withOpacity(0.25),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AutoSizeText(
                'HTML preview is not wired yet.',
                style: TextStyle(fontWeight: _wSemi, color: Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeItem {
  const _HomeItem(this.index, this.title, this.subtitle, this.color,
      {required this.from,
      required this.to,
      required this.pdfUrl,
      required this.id,
      this.amountStr,
      required this.rawData});

  final int index;
  final String id;
  final String title;
  final String subtitle;
  final Color color;
  final String from;
  final String to;
  final String pdfUrl;
  final String? amountStr;
  final Map<String, dynamic> rawData;
}

List<_HomeItem> homeList = [];
