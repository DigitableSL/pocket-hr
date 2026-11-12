import 'package:auto_size_text/auto_size_text.dart';
import 'package:cn_pocket_hr/services/leave_service.dart';
import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/helpers/design_config.dart';
import 'package:cn_pocket_hr/models/hr/leave_model.dart';
import 'package:cn_pocket_hr/models/hr/leave_eligibility_model.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';

class MobileLeaveRequestPage extends StatefulWidget {
  final bool isEdit;
  final MyLeavesModel? initial;
  final bool isEmbed;
  final VoidCallback? onSuccess;

  const MobileLeaveRequestPage({
    super.key,
    required this.isEdit,
    required this.initial,
    this.isEmbed = false,
    this.onSuccess,
  });

  @override
  State<MobileLeaveRequestPage> createState() => _MobileLeaveRequestPageState();
}

class _MobileLeaveRequestPageState extends State<MobileLeaveRequestPage>
    with TickerProviderStateMixin {
  static Color get _accent => HRColors.orangeColor;
  static const Color _pageBg = Colors.white;
  static const Color _surface = Color.fromARGB(255, 248, 250, 252);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);

  final APIService apiService = APIService();

  final List<String> leaveTypeList = const [
    "annual",
    "casual",
    "medical",
  ];

  String? typeValue = "annual";
  String? leaveTypeValue = "full_day";
  String? shortLeaveSession = "morning";
  String? halfDaySession = "morning";
  final TextEditingController description = TextEditingController();

  DateTime fDate = DateTime.now();
  DateTime tDate = DateTime.now();

  String fromText = 'From';
  String toText = 'To';

  late Future<List<MyLeavesModel>> _myLeavesFuture;
  late Future<Map<String, dynamic>?> _leaveBalanceFuture;
  late Future<List<dynamic>> _combinedFuture;
  Map<String, dynamic>? _balanceData;
  LeaveApplyEligibility? _eligibility;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _myLeavesFuture = LeaveService.getMyLeaves();
    _leaveBalanceFuture = apiService.getLeaveBalance();
    _leaveBalanceFuture.then((val) {
      if (val != null && mounted) {
        setState(() {
          _balanceData = val;
        });
      }
    });
    _combinedFuture = Future.wait([_myLeavesFuture, _leaveBalanceFuture]);
    apiService.getLeaveApplyEligibility().then((val) {
      if (val != null && mounted) {
        setState(() {
          _eligibility = val;
        });
      }
    });

    final m = widget.initial;
    if (m != null) {
      final rawType = m.leaveType.toString().trim().toLowerCase();
      final fallbackType = m.type.toString().trim().toLowerCase();
      final candidate = rawType.isNotEmpty
          ? rawType
          : (fallbackType.isNotEmpty ? fallbackType : 'annual');

      typeValue = leaveTypeList.contains(candidate) ? candidate : 'annual';
      description.text = m.description.toString();

      final fromStr = m.fromDate.toString();
      final toStr = m.toDate.toString();

      DateTime? tryParse(String s) {
        try {
          if (s.contains('/')) return DateFormat('dd/MM/yyyy').parse(s);
          if (s.contains('-')) return DateTime.tryParse(s);
        } catch (_) {}
        return null;
      }

      final fd = tryParse(fromStr);
      final td = tryParse(toStr);

      if (fd != null) {
        fDate = fd;
        fromText = DateFormat('dd/MM/yyyy').format(fd);
      }
      if (td != null) {
        tDate = td;
        toText = DateFormat('dd/MM/yyyy').format(td);
      }
    }

    if (typeValue == null || !leaveTypeList.contains(typeValue)) {
      typeValue = 'annual';
    }

    if (leaveTypeValue == 'short_leave') {
      typeValue = 'casual';
    }

    if (m == null) {
      final today = DateTime.now();
      fDate = today; // Default to today instead of start of week for better UX
      tDate = today;
      fromText = DateFormat('dd/MM/yyyy').format(fDate);
      toText = DateFormat('dd/MM/yyyy').format(tDate);
    }
  }

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  Future<void> _showTopMessage(
    String message, {
    bool error = false,
    Duration duration = const Duration(seconds: 3),
  }) async {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    final topPadding = MediaQuery.of(context).padding.top + 45.0;
    final bg = error ? Colors.red.shade600 : Colors.green.shade600;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: topPadding,
        left: 12,
        right: 12,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Row(
                children: [
                  Icon(
                    error
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AutoSizeText(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      try {
                        entry.remove();
                      } catch (_) {}
                    },
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    await Future.delayed(duration);
    try {
      entry.remove();
    } catch (_) {}
  }

  bool _isDefaultFromTo() => fromText == 'From' || toText == 'To';

  Future<DateTime?> _pickWheelDate({required DateTime initial}) async {
    final months = List<String>.generate(12, (i) {
      final dt = DateTime(DateTime.now().year, i + 1, 1);
      // Use Flutter's MaterialLocalizations to get a localized "Month Year" string,
      // then strip the year to keep only the localized month name.
      var label = MaterialLocalizations.of(context).formatMonthYear(dt);
      label = label
          .replaceAll(RegExp(r'\b\d{4}\b'), '')
          .replaceAll(RegExp(r',[\s]*'), '')
          .trim();
      return label;
    });
    final years = List<int>.generate(30, (i) => DateTime.now().year - 10 + i);
    int selMonth = initial.month;
    int selYear = initial.year;
    int selDay = initial.day;

    final monthController =
        FixedExtentScrollController(initialItem: selMonth - 1);
    final yearController = FixedExtentScrollController(
      initialItem: years.indexOf(selYear).clamp(0, years.length - 1),
    );
    int daysInMonth = DateUtils.getDaysInMonth(selYear, selMonth);
    selDay = selDay.clamp(1, daysInMonth);
    final dayController = FixedExtentScrollController(initialItem: selDay - 1);

    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            daysInMonth = DateUtils.getDaysInMonth(selYear, selMonth);
            final days = List<int>.generate(daysInMonth, (i) => i + 1);
            if (selDay > daysInMonth) selDay = daysInMonth;

            Widget wheel<T>({
              required FixedExtentScrollController controller,
              required List<T> items,
              required String Function(T) label,
              required void Function(int) onSelected,
            }) {
              return Expanded(
                child: SizedBox(
                  height: 170,
                  child: CupertinoPicker(
                    scrollController: controller,
                    itemExtent: 36,
                    useMagnifier: true,
                    magnification: 1.08,
                    selectionOverlay: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top:
                              BorderSide(color: Colors.black.withOpacity(0.08)),
                          bottom:
                              BorderSide(color: Colors.black.withOpacity(0.08)),
                        ),
                      ),
                    ),
                    onSelectedItemChanged: onSelected,
                    children: items
                        .map((e) => Center(
                              child: AutoSizeText(
                                label(e),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              );
            }

            return SafeArea(
              child: Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                decoration: BoxDecoration(
                  color: HRColors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close,
                              size: 16, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        wheel<String>(
                          controller: monthController,
                          items: months,
                          label: (m) => m,
                          onSelected: (i) {
                            setLocal(() {
                              selMonth = i + 1;
                              final dim =
                                  DateUtils.getDaysInMonth(selYear, selMonth);
                              if (selDay > dim) {
                                selDay = dim;
                                dayController.jumpToItem(selDay - 1);
                              }
                            });
                          },
                        ),
                        wheel<int>(
                          controller: dayController,
                          items: days,
                          label: (d) => d.toString(),
                          onSelected: (i) => setLocal(() => selDay = days[i]),
                        ),
                        wheel<int>(
                          controller: yearController,
                          items: years,
                          label: (y) => y.toString(),
                          onSelected: (i) {
                            setLocal(() {
                              selYear = years[i];
                              final dim =
                                  DateUtils.getDaysInMonth(selYear, selMonth);
                              if (selDay > dim) {
                                selDay = dim;
                                dayController.jumpToItem(selDay - 1);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          try {
                            monthController.dispose();
                          } catch (_) {}
                          try {
                            dayController.dispose();
                          } catch (_) {}
                          try {
                            yearController.dispose();
                          } catch (_) {}
                          Navigator.pop(
                              ctx, DateTime(selYear, selMonth, selDay));
                        },
                        child: AutoSizeText(
                          AppLocalizations.of(context)!.confirmLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          side: BorderSide(
                              color: HRColors.black.withOpacity(0.10)),
                        ),
                        onPressed: () {
                          try {
                            monthController.dispose();
                          } catch (_) {}
                          try {
                            dayController.dispose();
                          } catch (_) {}
                          try {
                            yearController.dispose();
                          } catch (_) {}
                          Navigator.pop(ctx);
                        },
                        child: AutoSizeText(
                          AppLocalizations.of(context)!.cancelLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _modeButton(String title, String value, IconData icon) {
    final isSelected = leaveTypeValue == value;

    final String label = title == 'Half Day'
        ? AppLocalizations.of(context)!.halfDay
        : (title == 'Full Day'
            ? AppLocalizations.of(context)!.fullDay
            : (title == 'Short Leave'
                ? AppLocalizations.of(context)!.shortLeave
                : title));

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: InkWell(
          onTap: widget.isEdit
              ? null
              : () {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  setState(() {
                    leaveTypeValue = value;
                    fDate = today;
                    tDate = today;
                    fromText = DateFormat('dd/MM/yyyy').format(fDate);
                    toText = DateFormat('dd/MM/yyyy').format(tDate);
                    if (value == 'short_leave') {
                      typeValue = 'casual';
                    }
                  });
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? HRColors.tabColor : Colors.transparent,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: HRColors.tabColor.withOpacity(0.20),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? HRColors.tabLabelColor : _accent,
                ),
                const SizedBox(height: 3),
                AutoSizeText(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected ? HRColors.tabLabelColor : _textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String text,
    required VoidCallback? onTap,
  }) {
    final isPlaceholder = text == 'From' || text == 'To';
    final displayText = isPlaceholder
        ? (text == 'From'
            ? AppLocalizations.of(context)!.fromLabel
            : AppLocalizations.of(context)!.toLabel)
        : text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.calendar_month_rounded, color: _accent, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AutoSizeText(
                displayText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isPlaceholder ? _textMuted : _textDark,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 11, color: _textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildEligibilityBanner() {
    return const SizedBox.shrink();
  }

  bool _validatePickedDate(DateTime picked) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pickedOnly = DateTime(picked.year, picked.month, picked.day);

    if (pickedOnly.isBefore(today)) {
      _showTopMessage(
        AppLocalizations.of(context)!.cannotSelectPastDate,
        error: true,
      );
      return false;
    }

    if (_eligibility?.minDateTime != null) {
      final minDtOnly = DateTime(
        _eligibility!.minDateTime!.year,
        _eligibility!.minDateTime!.month,
        _eligibility!.minDateTime!.day,
      );
      if (pickedOnly.isBefore(minDtOnly)) {
        final minStr = DateFormat('dd/MM/yyyy').format(minDtOnly);
        if (_eligibility?.restrictedByPayrollLock == true &&
            _eligibility?.lockedPayrollEnd != null) {
          _showTopMessage(
            AppLocalizations.of(context)!.payrollLockedUntilMessage(
                _eligibility!.lockedPayrollEnd!, minStr),
            error: true,
          );
        } else {
          _showTopMessage(
            AppLocalizations.of(context)!.leaveDateCannotBeBefore(minStr),
            error: true,
          );
        }
        return false;
      }
    }
    if (_eligibility?.maxDateTime != null) {
      final maxDtOnly = DateTime(
        _eligibility!.maxDateTime!.year,
        _eligibility!.maxDateTime!.month,
        _eligibility!.maxDateTime!.day,
      );
      final pickedOnly = DateTime(picked.year, picked.month, picked.day);
      if (pickedOnly.isAfter(maxDtOnly)) {
        final maxStr = DateFormat('dd/MM/yyyy').format(maxDtOnly);
        _showTopMessage(
          AppLocalizations.of(context)!.leaveDateCannotBeAfter(maxStr),
          error: true,
        );
        return false;
      }
    }
    return true;
  }

  String _getLiveDurationBadge() {
    if (leaveTypeValue == 'half') {
      return AppLocalizations.of(context)!.halfDay;
    }
    if (leaveTypeValue == 'short_leave') {
      return AppLocalizations.of(context)!.shortLeave;
    }
    final fOnly = DateTime(fDate.year, fDate.month, fDate.day);
    final tOnly = DateTime(tDate.year, tDate.month, tDate.day);
    final diff = tOnly.difference(fOnly).inDays + 1;
    final days = diff > 0 ? diff : 1;
    return days == 1
        ? '1 ${AppLocalizations.of(context)!.day}'
        : '$days ${AppLocalizations.of(context)!.days}';
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: _textMuted,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  String? _getCategoryQuotaBadge(String typeKey) {
    if (_balanceData == null) return null;
    final balMap = (_balanceData!['balance'] ?? _balanceData!['available']) as Map?;
    final quotaMap = (_balanceData!['quota'] ?? _balanceData!['leave_quota']) as Map?;
    final avail = balMap != null ? balMap[typeKey] : null;
    final quota = quotaMap != null ? quotaMap[typeKey] : null;
    if (avail == null) return null;
    String fmt(dynamic v) {
      if (v is num) {
        return v == v.toInt() ? v.toInt().toString() : v.toString();
      }
      return v.toString();
    }
    if (quota != null) {
      return '${fmt(avail)} / ${fmt(quota)}';
    }
    return fmt(avail);
  }

  Widget _buildCategorySelector(bool readOnly) {
    final icons = <String, IconData>{
      'annual': Icons.beach_access_rounded,
      'casual': Icons.wb_sunny_rounded,
      'medical': Icons.medical_services_outlined,
    };

    return Row(
      children: leaveTypeList.map((typeKey) {
        final isSelected = typeValue == typeKey;
        final quotaStr = _getCategoryQuotaBadge(typeKey);
        final icon = icons[typeKey] ?? Icons.event_note_rounded;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: typeKey == leaveTypeList.last ? 0 : 8,
            ),
            child: InkWell(
              onTap: (readOnly || leaveTypeValue == 'short_leave')
                  ? null
                  : () => setState(() => typeValue = typeKey),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected
                      ? HRColors.tabColor.withOpacity(0.10)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? HRColors.tabColor
                        : Colors.grey.shade200,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: HRColors.tabColor.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? HRColors.tabColor
                                : _accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            size: 14,
                            color: isSelected
                                ? HRColors.tabLabelColor
                                : _accent,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: HRColors.tabColor,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AutoSizeText(
                      _getLeaveTypeLabel(typeKey),
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: isSelected ? HRColors.brandPrimary : _textDark,
                      ),
                    ),
                    if (quotaStr != null) ...[
                      const SizedBox(height: 2),
                      AutoSizeText(
                        quotaStr,
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                          color: isSelected
                              ? const Color(0xFF15803D)
                              : _textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUnifiedDateCard(bool readOnly) {
    final isRange = leaveTypeValue == 'full_day';
    final fFormatted = DateFormat('EEE, dd MMM').format(fDate);
    final tFormatted = DateFormat('EEE, dd MMM').format(tDate);
    final fYear = DateFormat('yyyy').format(fDate);
    final tYear = DateFormat('yyyy').format(tDate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: isRange
          ? Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: readOnly
                        ? null
                        : () async {
                            final picked =
                                await _pickWheelDate(initial: fDate);
                            if (picked == null) return;
                            if (!_validatePickedDate(picked)) return;
                            setState(() {
                              fDate = picked;
                              if (tDate.isBefore(fDate)) {
                                tDate = fDate;
                                toText =
                                    DateFormat('dd/MM/yyyy').format(tDate);
                              }
                              fromText =
                                  DateFormat('dd/MM/yyyy').format(picked);
                            });
                          },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 12, color: _accent),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!
                                  .fromLabel
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AutoSizeText(
                          fFormatted,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fYear,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getLiveDurationBadge(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: HRColors.brandPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 15, color: Colors.grey.shade400),
                    ],
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: readOnly
                        ? null
                        : () async {
                            final picked =
                                await _pickWheelDate(initial: tDate);
                            if (picked == null) return;
                            if (!_validatePickedDate(picked)) return;
                            setState(() {
                              tDate = picked;
                              toText =
                                  DateFormat('dd/MM/yyyy').format(picked);
                            });
                          },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.event_rounded,
                                size: 12, color: _accent),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!
                                  .toLabel
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AutoSizeText(
                          tFormatted,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tYear,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: readOnly
                  ? null
                  : () async {
                      final picked = await _pickWheelDate(initial: fDate);
                      if (picked == null) return;
                      if (!_validatePickedDate(picked)) return;
                      setState(() {
                        fDate = picked;
                        tDate = picked;
                        fromText = DateFormat('dd/MM/yyyy').format(picked);
                        toText = DateFormat('dd/MM/yyyy').format(picked);
                      });
                    },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calendar_month_rounded,
                        color: _accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.dateLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$fFormatted, $fYear',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getLiveDurationBadge(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: HRColors.brandPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSubmitButton() {
    final badge = _getLiveDurationBadge();
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isSubmitting
              ? [_accent.withOpacity(0.6), _accent.withOpacity(0.6)]
              : [_accent, HRColors.brandPrimary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(_isSubmitting ? 0.05 : 0.24),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isSubmitting ? null : _confirmAndSubmit,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSubmitting) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 19),
                const SizedBox(width: 8),
              ],
              AutoSizeText(
                '${AppLocalizations.of(context)!.submitRequest} • $badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedDayName(String dayEnglish) {
    final lowerDay = dayEnglish.toLowerCase().trim();
    switch (lowerDay) {
      case 'monday':
        return AppLocalizations.of(context)!.monday;
      case 'tuesday':
        return AppLocalizations.of(context)!.tuesday;
      case 'wednesday':
        return AppLocalizations.of(context)!.wednesday;
      case 'thursday':
        return AppLocalizations.of(context)!.thursday;
      case 'friday':
        return AppLocalizations.of(context)!.friday;
      case 'saturday':
        return AppLocalizations.of(context)!.saturday;
      case 'sunday':
        return AppLocalizations.of(context)!.sunday;
      default:
        return dayEnglish;
    }
  }

  String _getLocalizedErrorMessage(dynamic res) {
    if (res is! Map) {
      return AppLocalizations.of(context)!.failedToSubmitLeave;
    }

    String? backendMsg;
    // Extract message/details in order of availability
    if (res.containsKey('message') && res['message'] != null) {
      backendMsg = res['message'].toString();
    } else if (res.containsKey('details') && res['details'] is Map) {
      final details = res['details'] as Map;
      if (details.containsKey('balance') && details['balance'] != null) {
        backendMsg = details['balance'].toString();
      }
    } else if (res.containsKey('details') && res['details'] != null) {
      backendMsg = res['details'].toString();
    } else if (res.containsKey('errors') && res['errors'] != null) {
      backendMsg = res['errors'].toString();
    }

    // Check inside nested data if not found at root
    if ((backendMsg == null || backendMsg.isEmpty) &&
        res.containsKey('data') &&
        res['data'] is Map) {
      return _getLocalizedErrorMessage(res['data']);
    }

    if (backendMsg == null || backendMsg.isEmpty) {
      return AppLocalizations.of(context)!.failedToSubmitLeave;
    }

    // Match short leave balance exhausted message with dynamic values:
    // "Short leave balance exhausted. You are entitled to a maximum of 2 short leaves per month. (Used/Pending: 2)"
    final regex = RegExp(
      r'Short leave balance exhausted\.\s*You are entitled to a maximum of\s*(\d+)\s*short leaves per month\.\s*\(Used/Pending:\s*(\d+)\)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(backendMsg);
    if (match != null) {
      final maxVal = match.group(1) ?? '2';
      final usedVal = match.group(2) ?? '2';
      return AppLocalizations.of(context)!
          .shortLeaveBalanceExhausted(maxVal, usedVal);
    }

    // Match non-working day message with dynamic day:
    // "You cannot apply leave on Saturday — it is not a working day according to your package terms."
    final nonWorkingDayRegex = RegExp(
      r'You cannot apply leave on\s+([a-zA-Z]+)\s+[\-—–]\s+it is not a working day according to your package terms\.',
      caseSensitive: false,
    );
    final nonWorkingMatch = nonWorkingDayRegex.firstMatch(backendMsg);
    if (nonWorkingMatch != null) {
      final dayEnglish = nonWorkingMatch.group(1) ?? '';
      final localizedDay = _getLocalizedDayName(dayEnglish);
      return AppLocalizations.of(context)!
          .cannotApplyLeaveOnNonWorkingDay(localizedDay);
    }

    return backendMsg;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (typeValue == null || typeValue!.isEmpty) {
      await _showTopMessage(
        'Please select ${AppLocalizations.of(context)!.leaveTypeLabel}',
        error: true,
      );
      return;
    }
    if (_isDefaultFromTo()) {
      await _showTopMessage(
        'Please select ${AppLocalizations.of(context)!.fromToLabel}',
        error: true,
      );
      return;
    }

    final fDateOnly = DateTime(fDate.year, fDate.month, fDate.day);
    final tDateOnly = DateTime(tDate.year, tDate.month, tDate.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (fDateOnly.isBefore(today) || tDateOnly.isBefore(today)) {
      await _showTopMessage(
        AppLocalizations.of(context)!.cannotSelectPastDate,
        error: true,
      );
      return;
    }

    final minDt = _eligibility?.minDateTime;
    final maxDt = _eligibility?.maxDateTime;

    if (minDt != null) {
      final minDtOnly = DateTime(minDt.year, minDt.month, minDt.day);
      if (fDateOnly.isBefore(minDtOnly) || tDateOnly.isBefore(minDtOnly)) {
        final minStr = DateFormat('dd/MM/yyyy').format(minDtOnly);
        if (_eligibility?.restrictedByPayrollLock == true &&
            _eligibility?.lockedPayrollEnd != null) {
          await _showTopMessage(
            AppLocalizations.of(context)!.payrollLockedUntilMessage(
                _eligibility!.lockedPayrollEnd!, minStr),
            error: true,
          );
        } else {
          await _showTopMessage(
            AppLocalizations.of(context)!.leaveDateCannotBeBefore(minStr),
            error: true,
          );
        }
        return;
      }
    }

    if (maxDt != null) {
      final maxDtOnly = DateTime(maxDt.year, maxDt.month, maxDt.day);
      if (fDateOnly.isAfter(maxDtOnly) || tDateOnly.isAfter(maxDtOnly)) {
        final maxStr = DateFormat('dd/MM/yyyy').format(maxDtOnly);
        await _showTopMessage(
          AppLocalizations.of(context)!.leaveDateCannotBeAfter(maxStr),
          error: true,
        );
        return;
      }
    }

    if (tDateOnly.isBefore(fDateOnly)) {
      await _showTopMessage(
        AppLocalizations.of(context)!.toDateMustBeAfterFrom,
        error: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final isShortLeave = leaveTypeValue == 'short_leave';
      final res = await apiService.leave({
        'leave_title': isShortLeave
            ? (description.text.trim().isNotEmpty
                ? description.text.trim()
                : 'Short Leave')
            : 'Leave Request',
        'from_date': isShortLeave
            ? DateFormat('dd/MM/yyyy').format(fDate)
            : DateFormat('yyyy-MM-dd').format(fDate),
        'to_date': DateFormat('yyyy-MM-dd').format(tDate),
        // Always send the user-selected leave type (annual/casual/medical)
        'leave_type': isShortLeave ? 'short_leave' : typeValue,
        'type': isShortLeave ? 'short_leave' : (leaveTypeValue ?? 'full_day'),
        // Pass the session conditionally
        'session': isShortLeave
            ? shortLeaveSession
            : (leaveTypeValue == 'half'
                ? halfDaySession
                : (leaveTypeValue ?? 'full_day')),
        'description': description.text,
        if (isShortLeave) 'short_leave_period': shortLeaveSession,
      });

      if (!mounted) return;

      if (res is Map && res['networkError'] == true) {
        await _showTopMessage(
          DesignConfig.getFriendlyErrorMessage(context, res['error']),
          error: true,
        );
        return;
      }

      final statusCode = (res is Map && res.containsKey('statusCode'))
          ? res['statusCode']
          : 500;

      if (statusCode == 200 || statusCode == 201) {
        // If it's a "success": true response, maybe the inner 'data' payload has success: false (Backend validation)
        if (res['data'] is Map &&
            (res['data']['success'] == false ||
                res['data']['success'] == 'false')) {
          String errMsg = _getLocalizedErrorMessage(res['data']);
          if (errMsg == AppLocalizations.of(context)!.failedToSubmitLeave) {
            errMsg = 'Your leave quota is over. Contact your merchant.';
          }
          await _showTopMessage(errMsg, error: true);
          return;
        }

        await _showTopMessage(
            AppLocalizations.of(context)!.leaveAppliedSuccessfully,
            error: false);
        if (mounted) {
          if (widget.isEmbed) {
            if (widget.onSuccess != null) widget.onSuccess!();
          } else {
            Navigator.pop(context, true);
          }
        }
        return;
      }

      if (statusCode == 401 || statusCode == 403) {
        await _showTopMessage(AppLocalizations.of(context)!.sessionExpired,
            error: true);
        return;
      }

      if (statusCode == 400 || statusCode == 422) {
        final errMsg = _getLocalizedErrorMessage(res);
        await _showTopMessage(
            errMsg != AppLocalizations.of(context)!.failedToSubmitLeave
                ? errMsg
                : AppLocalizations.of(context)!
                    .invalidDetailsPleaseCheckYourForm,
            error: true);
        return;
      }

      final fallbackMsg = _getLocalizedErrorMessage(res);
      await _showTopMessage(fallbackMsg, error: true);
    } catch (e) {
      if (!mounted) return;
      await _showTopMessage(
        DesignConfig.getFriendlyErrorMessage(context, e),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: AutoSizeText(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _textMuted,
                  fontSize: 12,
                ),
              ),
            ),
            AutoSizeText(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _textDark,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showLeaveConfirmationDialog() async {
    final days = tDate.difference(fDate).inDays + 1;

    return showGeneralDialog<bool>(
      context: context,
      barrierLabel: 'Confirm Leave',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, a1, a2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: curved,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.assignment_turned_in_rounded,
                          color: _accent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AutoSizeText(
                        AppLocalizations.of(context)!.confirmLeave,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (leaveTypeValue == 'short_leave') ...[
                        _infoRow(
                          "Date",
                          DateFormat('dd/MM/yyyy').format(fDate),
                        ),
                        _infoRow(
                          "Period",
                          shortLeaveSession == 'morning'
                              ? AppLocalizations.of(context)!.morningLabel
                              : AppLocalizations.of(context)!.eveningLabel,
                        ),
                      ] else ...[
                        _infoRow(
                          AppLocalizations.of(context)!.fromLabel,
                          DateFormat('dd/MM/yyyy').format(fDate),
                        ),
                        _infoRow(
                          AppLocalizations.of(context)!.toLabel,
                          DateFormat('dd/MM/yyyy').format(tDate),
                        ),
                      ],
                      _infoRow(
                        AppLocalizations.of(context)!.daysLabel,
                        leaveTypeValue == 'short_leave'
                            ? AppLocalizations.of(context)!.shortLeave
                            : (leaveTypeValue == 'half' ? '0.5' : '$days'),
                      ),
                      _infoRow(
                        AppLocalizations.of(context)!.leaveTypeLabel,
                        leaveTypeValue == 'short_leave'
                            ? AppLocalizations.of(context)!.shortLeave
                            : _getLeaveTypeLabel(typeValue ?? ''),
                      ),
                      if (description.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AutoSizeText(
                            AppLocalizations.of(context)!.noteLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: AutoSizeText(
                            description.text.trim(),
                            style: const TextStyle(
                              color: _textDark,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: AutoSizeText(
                                AppLocalizations.of(context)!.cancelLabel,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                elevation: 0,
                                minimumSize: const Size.fromHeight(42),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: AutoSizeText(
                                AppLocalizations.of(context)!.confirmLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
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

  Future<void> _confirmAndSubmit() async {
    if (_isSubmitting) return;
    if (typeValue == null || typeValue!.isEmpty) {
      await _showTopMessage(
        'Please select ${AppLocalizations.of(context)!.leaveTypeLabel}',
        error: true,
      );
      return;
    }
    if (_isDefaultFromTo()) {
      await _showTopMessage(
        'Please select ${AppLocalizations.of(context)!.fromToLabel}',
        error: true,
      );
      return;
    }

    final fDateOnlyConfirm = DateTime(fDate.year, fDate.month, fDate.day);
    final tDateOnlyConfirm = DateTime(tDate.year, tDate.month, tDate.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (fDateOnlyConfirm.isBefore(today) || tDateOnlyConfirm.isBefore(today)) {
      await _showTopMessage(
        AppLocalizations.of(context)!.cannotSelectPastDate,
        error: true,
      );
      return;
    }

    final minDt = _eligibility?.minDateTime;
    final maxDt = _eligibility?.maxDateTime;

    if (minDt != null) {
      final minDtOnly = DateTime(minDt.year, minDt.month, minDt.day);
      if (fDateOnlyConfirm.isBefore(minDtOnly) || tDateOnlyConfirm.isBefore(minDtOnly)) {
        final minStr = DateFormat('dd/MM/yyyy').format(minDtOnly);
        if (_eligibility?.restrictedByPayrollLock == true &&
            _eligibility?.lockedPayrollEnd != null) {
          await _showTopMessage(
            AppLocalizations.of(context)!.payrollLockedUntilMessage(
                _eligibility!.lockedPayrollEnd!, minStr),
            error: true,
          );
        } else {
          await _showTopMessage(
            AppLocalizations.of(context)!.leaveDateCannotBeBefore(minStr),
            error: true,
          );
        }
        return;
      }
    }

    if (maxDt != null) {
      final maxDtOnly = DateTime(maxDt.year, maxDt.month, maxDt.day);
      if (fDateOnlyConfirm.isAfter(maxDtOnly) || tDateOnlyConfirm.isAfter(maxDtOnly)) {
        final maxStr = DateFormat('dd/MM/yyyy').format(maxDtOnly);
        await _showTopMessage(
          AppLocalizations.of(context)!.leaveDateCannotBeAfter(maxStr),
          error: true,
        );
        return;
      }
    }

    if (tDateOnlyConfirm.isBefore(fDateOnlyConfirm)) {
      await _showTopMessage(
        AppLocalizations.of(context)!.toDateMustBeAfterFrom,
        error: true,
      );
      return;
    }

    try {
      final balanceData = await _leaveBalanceFuture;
      if (balanceData != null && balanceData['balance'] != null) {
        final currentType = typeValue!.toLowerCase();

        // Skip balance check for unpaid/no-pay leave types or short leaves
        if (currentType != 'nopay' && currentType != 'unpaid' && leaveTypeValue != 'short_leave') {
          final bal = balanceData['balance'][currentType];
          final num availableBalance =
              (bal is num) ? bal : num.tryParse(bal?.toString() ?? '') ?? 0;

          if (availableBalance <= 0) {
            await _showTopMessage(
              'Your leave quota is over. Contact your merchant.',
              error: true,
            );
            return;
          }
        }
      }
    } catch (_) {}

    final confirmed = await _showLeaveConfirmationDialog();
    if (confirmed == true) {
      await _submit();
    }
  }

  String _getLeaveTypeLabel(String v) {
    switch (v) {
      case 'annual':
        return AppLocalizations.of(context)!.annualLabel;
      case 'casual':
        return AppLocalizations.of(context)!.casualLabel;
      case 'medical':
        return AppLocalizations.of(context)!.medicalLabel;
      default:
        return v[0].toUpperCase() + v.substring(1);
    }
  }

  Widget _buildRequestedLeavesCard() {
    // We combine the two futures (leaves history and balance)
    return FutureBuilder(
      future: _combinedFuture,
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: CupertinoActivityIndicator(
                color: _accent,
                radius: 16.0,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink(); // Hide if error
        }

        final leavesData = snapshot.data?[0] as List<MyLeavesModel>? ?? [];
        final balanceData = snapshot.data?[1] as Map<String, dynamic>?;

        final pendingLeavesCount = leavesData
            .where((l) =>
                l.status.trim().toLowerCase() == 'pending' ||
                l.status.trim().toLowerCase() == 'requested')
            .length;

        final totalLeavesCount = leavesData.length;

        // Parse balance
        Map<String, dynamic> balanceNested = {};
        if (balanceData != null && balanceData['balance'] != null) {
          balanceNested = Map<String, dynamic>.from(balanceData['balance']);
        }

        // We filter out 0 values just keeping it clean, or show all
        List<Widget> balanceChips = [];
        balanceNested.forEach((key, value) {
          balanceChips.add(
            Container(
              margin: const EdgeInsets.only(right: 8, top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AutoSizeText(
                    '${_getLeaveTypeLabel(key.toLowerCase())}: ',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                  AutoSizeText(
                    value.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          );
        });

        return Container(
          margin: const EdgeInsets.only(bottom: 20, top: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HRColors.secondaryColor,  
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: HRColors.secondaryColor.withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          AppLocalizations.of(context)!.leaveSummary,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        AutoSizeText(
                          "${AppLocalizations.of(context)!.totalRequests}: $totalLeavesCount • ${AppLocalizations.of(context)!.pendindingLable}: $pendingLeavesCount",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (balanceChips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 8),
                AutoSizeText(
                  AppLocalizations.of(context)!.availableBalance,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Wrap(
                  children: balanceChips,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = widget.isEdit;

    final Widget bodyContent = SingleChildScrollView(
      physics: widget.isEmbed
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: widget.isEmbed
          ? const EdgeInsets.fromLTRB(4, 8, 4, 20)
          : const EdgeInsets.fromLTRB(12, 8, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!readOnly && !widget.isEmbed) _buildRequestedLeavesCard(),
          // _buildHeader(readOnly),
          // const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                // Show Leave Category Selector Cards first (except for Short Leave)
                if (leaveTypeValue != 'short_leave') ...[
                  _buildSectionLabel(AppLocalizations.of(context)!.leaveTypeLabel),
                  _buildCategorySelector(readOnly),
                  const SizedBox(height: 18),
                ],

                Container(
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      _modeButton(
                          'Full Day', 'full_day', Icons.wb_sunny_outlined),
                      _modeButton('Half Day', 'half', Icons.timelapse_rounded),
                      _modeButton('Short Leave', 'short_leave',
                          Icons.access_time_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                _buildEligibilityBanner(),

                _buildSectionLabel(AppLocalizations.of(context)!.fromToLabel),
                _buildUnifiedDateCard(readOnly),

                // Half Day Session Selection (Tab style)
                if (leaveTypeValue == 'half') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _tabButton(
                            label: AppLocalizations.of(context)!.morningLabel,
                            isSelected: halfDaySession == 'morning',
                            onTap: () =>
                                setState(() => halfDaySession = 'morning'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _tabButton(
                            label: AppLocalizations.of(context)!.eveningLabel,
                            isSelected: halfDaySession == 'evening',
                            onTap: () =>
                                setState(() => halfDaySession = 'evening'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Short Leave Session Selection
                if (leaveTypeValue == 'short_leave') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _tabButton(
                            label: AppLocalizations.of(context)!.morning,
                            isSelected: shortLeaveSession == 'morning',
                            onTap: () =>
                                setState(() => shortLeaveSession = 'morning'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _tabButton(
                            label: AppLocalizations.of(context)!.evening,
                            isSelected: shortLeaveSession == 'evening',
                            onTap: () =>
                                setState(() => shortLeaveSession = 'evening'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),
                _buildSectionLabel(
                  '${AppLocalizations.of(context)!.noteLabel} (${AppLocalizations.of(context)!.optional})',
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: description,
                    enabled: !readOnly,
                    minLines: 2,
                    maxLines: 4,
                    style: const TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          '${AppLocalizations.of(context)!.noteLabel} (${AppLocalizations.of(context)!.optional})',
                      hintStyle: const TextStyle(
                        color: _textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (!readOnly) ...[
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbed) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: _pageBg,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: _pageBg,
        surfaceTintColor: _pageBg,
        elevation: 0,
        centerTitle: true,
        title: AutoSizeText(
          readOnly
              ? AppLocalizations.of(context)!.leaveDetailsLabel
              : AppLocalizations.of(context)!.leaveRequestLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: _textDark,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: _textDark),
      ),
      body: bodyContent,
    );
  }

  Widget _tabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: widget.isEdit ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? HRColors.tabColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: HRColors.tabColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Center(
          child: AutoSizeText(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: isSelected ? HRColors.tabLabelColor : _textDark,
            ),
          ),
        ),
      ),
    );
  }
}
