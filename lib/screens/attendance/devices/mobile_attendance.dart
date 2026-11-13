import 'package:auto_size_text/auto_size_text.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localstorage/localstorage.dart';
import 'package:geocoding/geocoding.dart';

import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/helpers/design_config.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/models/hr/attendance_model.dart';
import 'package:cn_pocket_hr/constants/slideanimation.dart';
import 'package:cn_pocket_hr/screens/notifications/notifications.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';

class MobileAttendance extends StatefulWidget {
  const MobileAttendance({Key? key}) : super(key: key);

  @override
  State<MobileAttendance> createState() => _MobileAttendanceState();
}

class _MobileAttendanceState extends State<MobileAttendance>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final LocalStorage storage = LocalStorage('pocketHR');
  final APIService apiService = APIService();

  late AnimationController _animationController;
  Future<List<AttendanceModel>>? attendanceFuture;

  String _tabType = 'cur';
  String? _selectedPayroll; // format: M-YYYY (e.g., 1-2026)

  String? _resolvedLocation;
  String? _resolvedUser;

  // Theme colors dynamically resolved from HRColors
  static const Color _pageBg = Color.fromARGB(255, 248, 250, 252); // Warm cream base
  static const Color _surface = Colors.white;
  static Color get _burgundy => HRColors.brandPrimary;
  static Color get _burgundyLight => HRColors.brandLight;
  static Color get _textBurgundy => HRColors.brandDarkText;
  static const Color _textGrey = Color(0xFF7D6C6F); // Greyish brown text

  // Track expanded dates
  final Set<String> _expandedDates = {};
  bool _hasExpandedFirstTime = false;

  static const double _g12 = 12;
  static const double _g16 = 16;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _initLoad();
  }

  Future<void> _initLoad() async {
    await storage.ready;
    _loadAttendance('cur');
  }

  void _showTopToast(String msg) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 45,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _burgundy,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: AutoSizeText(
                    msg,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  String _attendanceErrorMessageFromStatus(int? statusCode) {
    final l = AppLocalizations.of(context)!;
    if (statusCode == 401 || statusCode == 403) return l.sessionExpired;
    if (statusCode == 404) return l.noRecords;
    if (statusCode != null && statusCode >= 500) return l.serverError;
    return l.serverError;
  }

  String _attendanceErrorMessageFromException(Object? err) {
    final l = AppLocalizations.of(context)!;
    if (err == null) return l.serverError;

    if (err is SocketException) return l.noInternetConnection;

    final s = err.toString().toLowerCase();
    if (s.contains('401') || s.contains('403')) return l.sessionExpired;
    if (s.contains('404')) return l.noRecords;
    if (s.contains('socketexception') || s.contains('failed host lookup')) {
      return l.noInternetConnection;
    }
    return l.serverError;
  }

  void _toastAttendanceError(Object? err) {
    final msg = _attendanceErrorMessageFromException(err);
    _showTopToast(msg);
  }

  void _loadAttendance(String type) {
    _tabType = type;
    setState(() {
      _expandedDates.clear(); // reset expansions
      _hasExpandedFirstTime = false;
      String? payroll = type == 'cur'
          ? storage.getItem('payroll_active_tag')?.toString()
          : (_selectedPayroll ??
              storage.getItem('payroll_past_tag')?.toString());
      if ((payroll == null || payroll.trim().isEmpty) && type == 'cur') {
        final now = DateTime.now();
        payroll = '${now.month}-${now.year}';
      }

      if (payroll == null || payroll.trim().isEmpty) {
        attendanceFuture = Future.value(<AttendanceModel>[]);
        return;
      }
      attendanceFuture = apiService.getAttendanceForUserMonth(payroll: payroll);
    });
  }

  Future<void> _pickMonthAndLoad() async {
    final picked = await _showMonthYearPicker();
    if (picked == null) return;
    final mm = picked.month.toString();
    final yyyy = picked.year.toString();
    _selectedPayroll = '$mm-$yyyy';
    _loadAttendance('prv');
  }

  Future<DateTime?> _showMonthYearPicker() async {
    final now = DateTime.now();
    final initialTag = _selectedPayroll;

    int selectedMonth = now.month;
    int selectedYear = now.year;

    if (initialTag != null && initialTag.contains('-')) {
      final parts = initialTag.split('-');
      if (parts.length == 2) {
        final mm = int.tryParse(parts[0]);
        final yy = int.tryParse(parts[1]);
        if (mm != null && mm >= 1 && mm <= 12) selectedMonth = mm;
        if (yy != null) selectedYear = yy;
      }
    }

    final months = List<String>.generate(12, (i) {
      final dt = DateTime(now.year, i + 1, 1);
      var label = MaterialLocalizations.of(context).formatMonthYear(dt);
      label = label
          .replaceAll(RegExp(r'\b\d{4}\b'), '')
          .replaceAll(RegExp(r',[\s]*'), '')
          .trim();
      return label;
    });

    final years = List<int>.generate(11, (i) => now.year - 10 + i);
    final monthController =
        FixedExtentScrollController(initialItem: selectedMonth - 1);
    final yearController = FixedExtentScrollController(
      initialItem: years.indexOf(selectedYear).clamp(0, years.length - 1),
    );

    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: _g16, vertical: _g12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Color(0x24000000), blurRadius: 24)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: _burgundy, shape: BoxShape.circle),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 180,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 44,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: CupertinoPicker(
                              scrollController: monthController,
                              itemExtent: 40,
                              magnification: 1.05,
                              useMagnifier: true,
                              selectionOverlay: const SizedBox.shrink(),
                              onSelectedItemChanged: (i) =>
                                  selectedMonth = i + 1,
                              children: months
                                  .map((m) => Center(
                                        child: AutoSizeText(
                                          m,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: yearController,
                              itemExtent: 40,
                              magnification: 1.05,
                              useMagnifier: true,
                              selectionOverlay: const SizedBox.shrink(),
                              onSelectedItemChanged: (i) =>
                                  selectedYear = years[i],
                              children: years
                                  .map((y) => Center(
                                        child: AutoSizeText(
                                          y.toString(),
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _burgundy,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () => Navigator.pop(
                          ctx, DateTime(selectedYear, selectedMonth, 1)),
                      child: AutoSizeText(
                        AppLocalizations.of(context)!.confirmLabel,
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        side: BorderSide(color: Colors.black.withOpacity(0.06)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: AutoSizeText(
                        AppLocalizations.of(context)!.cancelLabel,
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.black87, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  int _parseWorkedMinutes(dynamic raw) {
    if (raw == null) return 0;
    final s = raw.toString().trim();
    if (s.isEmpty || s == '-' || s == ' - ') return 0;
    final hmMatch = RegExp(r'(\d+)\s*h\s*(\d*)\s*m?').firstMatch(s);
    if (hmMatch != null) {
      final h = int.tryParse(hmMatch.group(1) ?? '') ?? 0;
      final m = int.tryParse(hmMatch.group(2) ?? '') ?? 0;
      return h * 60 + m;
    }
    final colonParts = s.split(':');
    if (colonParts.length >= 2) {
      final h = int.tryParse(colonParts[0]) ?? 0;
      final m = int.tryParse(colonParts[1]) ?? 0;
      return h * 60 + m;
    }
    final d = double.tryParse(s);
    if (d != null) return (d * 60).round();
    return 0;
  }


  String _getLocalizedDow(BuildContext context, String dow) {
    final clean = dow.trim().toLowerCase();
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'en') {
      if (clean.contains('mon')) return 'Mon';
      if (clean.contains('tue')) return 'Tue';
      if (clean.contains('wed')) return 'Wed';
      if (clean.contains('thu')) return 'Thu';
      if (clean.contains('fri')) return 'Fri';
      if (clean.contains('sat')) return 'Sat';
      if (clean.contains('sun')) return 'Sun';
    } else {
      final l10n = AppLocalizations.of(context)!;
      if (clean.contains('mon')) return l10n.monday;
      if (clean.contains('tue')) return l10n.tuesday;
      if (clean.contains('wed')) return l10n.wednesday;
      if (clean.contains('thu')) return l10n.thursday;
      if (clean.contains('fri')) return l10n.friday;
      if (clean.contains('sat')) return l10n.saturday;
      if (clean.contains('sun')) return l10n.sunday;
    }
    return dow;
  }

  String _formatCoord(dynamic val) {
    if (val == null) return '';
    if (val is num) {
      return val.toStringAsFixed(5);
    }
    final d = double.tryParse(val.toString());
    if (d != null) {
      return d.toStringAsFixed(5);
    }
    return val.toString();
  }

  // ===== dashboard widgets =====

  Widget _topActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_g16, _g12, _g16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Drawer Menu Trigger
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: HRColors.flavorIconBackgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Center(
                child: SvgPicture.asset(
                  "assets/svg/drawer_icon.svg",
                  colorFilter: ColorFilter.mode(
                      HRColors.flavorIconColor, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          
          // Header Title
          AutoSizeText(
            AppLocalizations.of(context)!.myAttendance,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _textBurgundy,
            ),
          ),
          
          // Right Controls: Sync & Notification Bell
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notifications
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
        ],
      ),
    );
  }

  Widget _monthTabs() {
    final thisMonthLabel = storage.getItem('payroll_active_tag')?.toString() ??
        AppLocalizations.of(context)!.thisMonthLabel;
    final pastMonthLabel = storage.getItem('payroll_past_tag')?.toString() ??
        AppLocalizations.of(context)!.pastMonthLabel;

    return Container(
      margin: const EdgeInsets.only(top: _g12),
      padding: const EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _burgundyLight,
        borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
      ),
      child: Row(
        children: [
          // This Month
          Expanded(
            child: InkWell(
              onTap: () => _loadAttendance('cur'),
              borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius - 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _tabType == 'cur'
                      ? _burgundy
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius - 3),
                  boxShadow: _tabType == 'cur'
                      ? [
                          BoxShadow(
                            color: _burgundy.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: AutoSizeText(
                    thisMonthLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _tabType == 'cur'
                          ? Colors.white
                          : _textGrey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Past Month / Date Picker
          Expanded(
            child: InkWell(
              onTap: _pickMonthAndLoad,
              borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius - 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _tabType == 'prv'
                      ? _burgundy
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius - 3),
                  boxShadow: _tabType == 'prv'
                      ? [
                          BoxShadow(
                            color: _burgundy.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: AutoSizeText(
                    _tabType == 'prv' && _selectedPayroll != null
                        ? _selectedPayroll!
                        : pastMonthLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _tabType == 'prv'
                          ? Colors.white
                          : _textGrey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthSummary(List<AttendanceModel> items) {
    final l10n = AppLocalizations.of(context)!;
    int presentCount = 0;
    int lateInCount = 0;
    int totalWorkedMins = 0;

    for (final it in items) {
      if (it.isOffday) continue;
      
      final bp = it.boilerPlate;
      final inTime = bp['in_time_only']?.toString() ?? '';
      
      if (inTime.isNotEmpty && inTime != ' - ') {
        presentCount++;
        if (inTime.contains(':')) {
          final parts = inTime.split(':');
          final hh = int.tryParse(parts[0]) ?? 0;
          final mm = int.tryParse(parts[1]) ?? 0;
          if (hh * 60 + mm > 8 * 60 + 30) {
            lateInCount++;
          }
        }
      }

      final workedRaw = bp['wrkd_hours_fmtd']?.toString() ?? '';
      final parsedMins = _parseWorkedMinutes(workedRaw);
      if (parsedMins > 0) {
        totalWorkedMins += parsedMins;
      } else {
        final dynamic secondsVal = bp['workedSeconds'] ?? bp['worked_seconds'] ?? it.boilerPlate['worked_hours'];
        if (secondsVal != null) {
          final secs = _toInt(secondsVal);
          totalWorkedMins += secs ~/ 60;
        }
      }
    }

    final totalWorkedHrs = totalWorkedMins ~/ 60;
    final totalWorkedMinsPart = totalWorkedMins % 60;
    final totalWorkedText = totalWorkedMinsPart > 0
        ? "${totalWorkedHrs}h ${totalWorkedMinsPart}m"
        : "${totalWorkedHrs}h";

    Widget statTile(String label, String value, Color valColor) {
      return Expanded(
        child: Column(
          children: [
            AutoSizeText(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: _textGrey,
                fontWeight: FontWeight.w600,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            AutoSizeText(
              value,
              maxLines: 1,
              style: TextStyle(
                color: valColor,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: _g12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _burgundyLight,
        borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          statTile(l10n.presentLabel.toUpperCase(), presentCount.toString(), const Color(0xFF2E7D32)),
          statTile(l10n.absentsLabel.toUpperCase(), "00", _textGrey),
          statTile(l10n.lateInLabel.toUpperCase(), lateInCount.toString().padLeft(2, '0'), _textGrey),
          statTile(l10n.workingHrs.toUpperCase(), totalWorkedText, HRColors.brandAccent),
        ],
      ),
    );
  }

  // ===== empty state =====

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: _textGrey.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            AutoSizeText(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: const TextStyle(
                color: _textGrey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== list =====

  Widget _attendanceList() {
    return FutureBuilder<List<AttendanceModel>>(
      future: attendanceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.active) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CupertinoActivityIndicator(
                color: _burgundy,
                radius: 16.0,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          final friendlyMsg = DesignConfig.getFriendlyErrorMessage(context, snapshot.error);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: DesignConfig.buildErrorState(
              context,
              message: friendlyMsg,
              onRetry: () => _loadAttendance(_tabType),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CupertinoActivityIndicator(
                color: _burgundy,
                radius: 16.0,
              ),
            ),
          );
        }

        var data = snapshot.data!;

        int? statusCode;
        if (data.isNotEmpty) {
          try {
            final bp = data.first.boilerPlate;
            final scAny = bp['statusCode'] ?? bp['status'] ?? bp['code'];
            statusCode =
                (scAny is int) ? scAny : int.tryParse(scAny?.toString() ?? '');
          } catch (_) {}
        }

        if (statusCode != null && statusCode >= 500) {
          return _buildEmptyState(AppLocalizations.of(context)!.serverError);
        }
        if (statusCode == 401 || statusCode == 403 || statusCode == 404) {
          return _buildEmptyState(_attendanceErrorMessageFromStatus(statusCode));
        }
        if ((statusCode == 200 || statusCode == null) && data.isEmpty) {
          return _buildEmptyState(AppLocalizations.of(context)!.noRecords);
        }
        if (statusCode != null && statusCode != 200 && data.isEmpty) {
          return _buildEmptyState(AppLocalizations.of(context)!.serverError);
        }

        if (data.isNotEmpty) {
          final bp0 = data.first.boilerPlate;
          final loc = bp0['location']?.toString();
          if ((_resolvedLocation == null || _resolvedLocation!.isEmpty) &&
              loc != null &&
              loc.isNotEmpty) {
            _resolvedLocation = loc;
          }
          if (_resolvedUser == null || _resolvedUser!.isEmpty) {
            final uid = storage.getItem('uid')?.toString() ?? '';
            _resolvedUser = uid.isNotEmpty ? uid : null;
          }
        }

        // Sort latest to oldest (descending)
        data = List<AttendanceModel>.from(data)
          ..sort((a, b) {
            final ta = _toInt(
                a.boilerPlate['firstCheckIn'] ?? a.boilerPlate['time'] ?? 0);
            final tb = _toInt(
                b.boilerPlate['firstCheckIn'] ?? b.boilerPlate['time'] ?? 0);
            return tb.compareTo(ta);
          });

        if (data.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
                child: AutoSizeText(AppLocalizations.of(context)!.noRecords)),
          );
        }

        // Auto-expand the very first item on load if user hasn't toggled anything
        if (!_hasExpandedFirstTime && data.isNotEmpty) {
          _expandedDates.add(data.first.day);
          _hasExpandedFirstTime = true;
        }

        return SlideAnimation(
          position: 4,
          itemCount: 8,
          slideDirection: SlideDirection.fromLeft,
          animationController: _animationController,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            itemBuilder: (_, index) {
              final record = data[index];
              return _attendanceCard(record);
            },
          ),
        );
      },
    );
  }

  Widget _attendanceCard(AttendanceModel data) {
    final String day = data.day;
    final String dow = data.dow;

    // Extract only day number from full YYYY-MM-DD or DD/MM/YYYY string
    String dayNumber = day;
    if (day.contains('-')) {
      final parts = day.split('-');
      if (parts.length == 3) {
        dayNumber = parts[2];
      }
    } else if (day.contains('/')) {
      final parts = day.split('/');
      if (parts.length == 3) {
        dayNumber = parts[0];
      }
    }
    try {
      final parsed = int.tryParse(dayNumber);
      if (parsed != null) {
        dayNumber = parsed.toString();
      }
    } catch (_) {}

    final bp = data.boilerPlate;
    final String inTime = bp['in_time_only']?.toString() ?? ' - ';
    final String outTime = bp['out_time_only']?.toString() ?? ' - ';
    final bool isExpanded = _expandedDates.contains(day);

    String workedHrs = ' - ';
    final workedRaw = bp['wrkd_hours_fmtd']?.toString() ?? '';
    if (workedRaw.isNotEmpty && workedRaw != ' - ') {
      workedHrs = workedRaw;
    } else {
      final dynamic secondsVal = bp['workedSeconds'] ?? bp['worked_seconds'] ?? bp['worked_hours'];
      if (secondsVal != null) {
        final secs = _toInt(secondsVal);
        final hrs = secs ~/ 3600;
        final mins = (secs % 3600) ~/ 60;
        workedHrs = "${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}";
      }
    }


    final isPending = data.isPending;
    final isOffday = data.isOffday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              if (_expandedDates.contains(day)) {
                _expandedDates.remove(day);
              } else {
                _expandedDates.add(day);
              }
            });
          },
          borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 54,
                          height: 66,
                          decoration: BoxDecoration(
                            color: _burgundy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayNumber,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                _getLocalizedDow(context, dow),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isPending)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AutoSizeText(
                                  inTime,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AutoSizeText(
                                  AppLocalizations.of(context)!.checkIn,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _verticalDivider(),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AutoSizeText(
                                  outTime,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AutoSizeText(
                                  AppLocalizations.of(context)!.checkOut,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _verticalDivider(),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AutoSizeText(
                                  workedHrs,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: HRColors.brandAccent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AutoSizeText(
                                  AppLocalizations.of(context)!.workingHrs,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isOffday) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEBE9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.dayOffLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4E342E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  _expandedContent(data, inTime, outTime),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 36,
      color: HRColors.brandBorder,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  String _stripPlusCode(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final stripped = trimmed.replaceAll(RegExp(r'^[A-Z0-9]{2,8}\+[A-Z0-9]{2,4}\s*,?\s*'), '').trim();
    if (stripped.contains('+') && RegExp(r'^[A-Z0-9]{2,8}\+[A-Z0-9]{2,4}$').hasMatch(stripped)) {
      return '';
    }
    return stripped;
  }

  Future<String> _resolveAddressFirstPart(Map<dynamic, dynamic> meta) async {
    final latStr = meta['lat']?.toString() ?? '';
    final lngStr = meta['lng']?.toString() ?? '';
    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lngStr);

    if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = <String>[];
          
          void addPart(String? val) {
            if (val == null) return;
            final cleaned = _stripPlusCode(val);
            if (cleaned.isNotEmpty && !parts.contains(cleaned)) {
              parts.add(cleaned);
            }
          }

          addPart(place.street);
          addPart(place.subLocality);
          addPart(place.locality);
          addPart(place.administrativeArea);
          addPart(place.country);

          if (parts.isNotEmpty) {
            final firstPart = parts.first.toUpperCase();
            if (firstPart != "OFFICE") {
              return firstPart;
            }
          }
        }
      } catch (e) {
        debugPrint('Reverse geocode error: $e');
      }
      return "${_formatCoord(lat)}, ${_formatCoord(lng)}";
    }
    final site = (meta['site_name'] ?? meta['sensor_pool'] ?? "REMOTE").toString().toUpperCase();
    return site == "OFFICE" ? "REMOTE" : site;
  }

  Widget _expandedContent(AttendanceModel data, String inTime, String outTime) {
    final l10n = AppLocalizations.of(context)!;
    final bool hasOut = outTime.isNotEmpty && outTime != ' - ';

    final bool isRemoteAttendance = (data.boilerPlate['remote'] == true) || (data.type == 'remote_attendance');

    String? distIn;
    String? distOut;
    Map<dynamic, dynamic>? metaIn;
    Map<dynamic, dynamic>? metaOut;
    String siteNameIn = 'OFFICE';
    String siteNameOut = 'OFFICE';

    String? formatDistance(dynamic dist) {
      if (dist == null) return null;
      if (dist is num) {
        if (dist >= 1000) {
          return '${(dist / 1000).toStringAsFixed(1)} km';
        }
        return '${dist.round()} m';
      }
      final s = dist.toString().trim();
      if (s.isEmpty || s == 'null') return null;
      if (s.endsWith('m') || s.endsWith('km')) return s;
      final d = double.tryParse(s);
      if (d != null) {
        if (d >= 1000) {
          return '${(d / 1000).toStringAsFixed(1)} km';
        }
        return '${d.round()} m';
      }
      return '$s m';
    }

    final punches = data.boilerPlate['attendance'] ?? [];
    if (punches is List && punches.isNotEmpty) {
      Map<dynamic, dynamic>? punchIn;
      Map<dynamic, dynamic>? punchOut;

      for (final p in punches) {
        if (p is Map) {
          final pType = p['type']?.toString().toLowerCase() ?? '';
          if (pType == 'in') {
            if (punchIn == null) {
              punchIn = p;
            } else {
              final tCurrent = int.tryParse(punchIn['time']?.toString() ?? '') ?? 0;
              final tNew = int.tryParse(p['time']?.toString() ?? '') ?? 0;
              if (tNew < tCurrent) {
                punchIn = p;
              }
            }
          } else if (pType == 'out') {
            if (punchOut == null) {
              punchOut = p;
            } else {
              final tCurrent = int.tryParse(punchOut['time']?.toString() ?? '') ?? 0;
              final tNew = int.tryParse(p['time']?.toString() ?? '') ?? 0;
              if (tNew > tCurrent) {
                punchOut = p;
              }
            }
          }
        }
      }

      if (punchIn == null) {
        final firstMap = punches.firstWhere((e) => e is Map, orElse: () => <String, dynamic>{});
        if (firstMap.isNotEmpty) punchIn = firstMap;
      }
      if (punchOut == null) {
        punchOut = punchIn;
      }

      if (punchIn != null) {
        metaIn = punchIn['meta'] ?? {};
        if (isRemoteAttendance) {
          distIn = formatDistance(metaIn?['distance'] ?? metaIn?['dist']);
        } else {
          siteNameIn = (metaIn?['site_name'] ?? data.boilerPlate['location'] ?? "OFFICE").toString();
        }
      }

      if (punchOut != null && hasOut) {
        metaOut = punchOut['meta'] ?? {};
        if (isRemoteAttendance) {
          distOut = formatDistance(metaOut?['distance'] ?? metaOut?['dist']);
        } else {
          siteNameOut = (metaOut?['site_name'] ?? data.boilerPlate['location'] ?? "OFFICE").toString();
        }
      } else {
        siteNameOut = ' - ';
      }
    } else {
      siteNameIn = isRemoteAttendance ? l10n.remoteLabel : (data.boilerPlate['location'] ?? "OFFICE").toString();
      siteNameOut = hasOut ? siteNameIn : ' - ';
    }

    if (siteNameIn.toUpperCase() == "OFFICE") {
      siteNameIn = isRemoteAttendance ? l10n.remoteLabel : l10n.qrLabel;
    }
    if (hasOut && siteNameOut.toUpperCase() == "OFFICE") {
      siteNameOut = isRemoteAttendance ? l10n.remoteLabel : l10n.qrLabel;
    }

    final Future<String> locationInFuture = isRemoteAttendance && metaIn != null
        ? _resolveAddressFirstPart(metaIn)
        : Future.value(siteNameIn.toUpperCase());

    final Future<String> locationOutFuture = hasOut && isRemoteAttendance && metaOut != null
        ? _resolveAddressFirstPart(metaOut)
        : Future.value(siteNameOut.toUpperCase());

    // Late computation
    int lateMins = _toInt(data.boilerPlate['lateMinutes'] ?? data.boilerPlate['late'] ?? 0);
    if (lateMins <= 0 && inTime.isNotEmpty && inTime != ' - ' && inTime.contains(':')) {
      final parts = inTime.split(':');
      final hh = int.tryParse(parts[0]) ?? 0;
      final mm = int.tryParse(parts[1]) ?? 0;
      if (hh * 60 + mm > 8 * 60 + 30) {
        lateMins = (hh * 60 + mm) - (8 * 60 + 30);
      }
    }

    // Overtime computation
    int otMins = _toInt(data.boilerPlate['overMinutes'] ?? data.boilerPlate['over'] ?? 0);
    if (otMins <= 0) {
      final workedRaw = data.boilerPlate['wrkd_hours_fmtd']?.toString() ?? '';
      final workedMins = _parseWorkedMinutes(workedRaw);
      if (workedMins > 9 * 60) {
        otMins = workedMins - 9 * 60;
      }
    }

    // Required Hours dynamic fetch
    final int reqHrs = _toInt(
      data.boilerPlate['required_hrs'] ??
      data.boilerPlate['package']?['terms']?['working_hours'] ??
      data.boilerPlate['working_hours'] ??
      9
    );

    // Entry Type text formatting
    final entryIn = isRemoteAttendance ? l10n.remoteLabel : l10n.qrLabel;
    final entryOut = hasOut ? (isRemoteAttendance ? l10n.remoteLabel : l10n.qrLabel) : ' - ';
    final entryTypeText = hasOut ? "$entryIn / $entryOut" : entryIn;

    final displayDistIn = distIn;
    final displayDistOut = distOut;

    String formatMinutes(int totalMins) {
      if (totalMins <= 0) return "00";
      final hrs = totalMins ~/ 60;
      final mins = totalMins % 60;
      if (hrs > 0) {
        return "${hrs}h ${mins}m";
      }
      return "${mins}m";
    }

    Widget middleBoxItem(String label, String value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _textGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: HRColors.brandDarkText,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inner Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6F0),
            borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: middleBoxItem(l10n.entryTypeHeader, entryTypeText)),
                  Expanded(child: middleBoxItem(l10n.reqHoursHeader, "${reqHrs}h")),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: middleBoxItem(l10n.lateHeader, formatMinutes(lateMins))),
                  Expanded(child: middleBoxItem(l10n.overtimeHeader, formatMinutes(otMins))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.inLocationHeader,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _textGrey,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<String>(
                          future: locationInFuture,
                          builder: (context, snapshot) {
                            final val = snapshot.data ?? (isRemoteAttendance ? l10n.loading.toUpperCase() : siteNameIn.toUpperCase());
                            return Text(
                              val,
                              style: TextStyle(
                                fontSize: 14,
                                color: HRColors.brandDarkText,
                              ),
                            );
                          },
                        ),
                        if (displayDistIn != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            "${AppLocalizations.of(context)!.distance}: $displayDistIn",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _textGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.outLocationHeader,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _textGrey,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<String>(
                          future: locationOutFuture,
                          builder: (context, snapshot) {
                            final val = snapshot.data ?? (isRemoteAttendance ? l10n.loading.toUpperCase() : siteNameOut.toUpperCase());
                            return Text(
                              val,
                              style: TextStyle(
                                fontSize: 14,
                                color: HRColors.brandDarkText,
                              ),
                            );
                          },
                        ),
                        if (displayDistOut != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            "${AppLocalizations.of(context)!.distance}: $displayDistOut",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _textGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== screen build =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: DesignConfig.drawerContent(_scaffoldKey, context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _topActions(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _monthTabs(),
                    FutureBuilder<List<AttendanceModel>>(
                      future: attendanceFuture,
                      builder: (context, snap) {
                        final list = snap.data ?? const <AttendanceModel>[];
                        return _monthSummary(list);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Title and list
              Column(
                children: [
                  _attendanceList(),
                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
      backgroundColor: _pageBg,
    );
  }
}
