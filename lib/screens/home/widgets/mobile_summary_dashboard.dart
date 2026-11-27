import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/models/hr/mobile_summary_model.dart';
import 'package:flutter/material.dart';

/// Informative Home Dashboard powered by `GET /attendance/mobile-summary`.
///
/// Renders:
/// 1. Contextual Alert Card (only when backend returns `alerts[]`)
/// 2. Today's Status Card (CHECK IN / CHECK OUT tiles + progress bar + shift note)
/// 3. Monthly Summary Card (Present / Absent / Leave Left + OT & Short Leave quota)
/// 4. Expandable My Roster Calendar (Current Week by default, expands to Full Month on tap)
class MobileSummaryDashboard extends StatefulWidget {
  final MobileSummaryModel? summary;
  final bool isLoading;
  final VoidCallback onScanCheckIn;
  final VoidCallback onApplyLeave;

  const MobileSummaryDashboard({
    super.key,
    required this.summary,
    required this.isLoading,
    required this.onScanCheckIn,
    required this.onApplyLeave,
  });

  @override
  State<MobileSummaryDashboard> createState() => _MobileSummaryDashboardState();
}

class _MobileSummaryDashboardState extends State<MobileSummaryDashboard> {
  bool _showFullCalendar = false;
  int? _selectedDayNumber;

  @override
  Widget build(BuildContext context) {
    final brandPrimary = FlavorConfig.instance.primaryColor;
    final brandLight = HRColors.brandLight;

    if (widget.isLoading && widget.summary == null) {
      return _buildLoadingSkeleton();
    }

    final summary = widget.summary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Contextual Alert Card (only if backend returned alerts)
          if (summary.alerts.isNotEmpty) ...[
            _buildAlertCard(summary.alerts.first, brandPrimary),
            const SizedBox(height: 12),
          ],

          // 2. Today's Status Card
          _buildTodayStatusCard(summary, brandPrimary),
          const SizedBox(height: 12),

          // 3. Monthly Summary Card (Present / Absent / Leave Left + OT & Short Leave)
          _buildMonthlySummaryCard(
              summary.quickMetrics, brandPrimary, brandLight),
          const SizedBox(height: 12),

          // 4. Expandable My Roster Calendar (Current Week <-> Full Month)
          if (summary.calendar.days.isNotEmpty)
            _buildRosterCard(
                context, summary.calendar, brandPrimary, brandLight),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    Widget box(double height) => Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0F1),
            borderRadius: BorderRadius.circular(18),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Column(
        children: [
          box(128),
          const SizedBox(height: 12),
          box(96),
          const SizedBox(height: 12),
          box(118),
        ],
      ),
    );
  }

  Widget _buildAlertCard(MobileHomeAlert alert, Color brandPrimary) {
    final isDanger = alert.severity.toLowerCase() == 'danger' ||
        alert.severity.toLowerCase() == 'error';
    final bgColor =
        isDanger ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final borderColor =
        isDanger ? const Color(0xFFFECACA) : const Color(0xFFFDE68A);
    final accentColor =
        isDanger ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final titleColor =
        isDanger ? const Color(0xFF991B1B) : const Color(0xFF92400E);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.priority_high_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title.isNotEmpty ? alert.title : 'Attention Needed',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                if (alert.message.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    alert.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: titleColor.withOpacity(0.88),
                      height: 1.35,
                    ),
                  ),
                ],
                if (alert.primaryLabel.isNotEmpty ||
                    alert.secondaryLabel.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (alert.primaryLabel.isNotEmpty)
                        GestureDetector(
                          onTap: () => _handleAlertAction(alert.primaryAction),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: brandPrimary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              alert.primaryLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (alert.secondaryLabel.isNotEmpty)
                        GestureDetector(
                          onTap: () =>
                              _handleAlertAction(alert.secondaryAction),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor),
                            ),
                            child: Text(
                              alert.secondaryLabel,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAlertAction(String action) {
    final a = action.toLowerCase();
    if (a.contains('scan') || a.contains('check')) {
      widget.onScanCheckIn();
    } else if (a.contains('leave')) {
      widget.onApplyLeave();
    }
  }

  Widget _buildTodayStatusCard(MobileSummaryModel summary, Color brandPrimary) {
    final punches = summary.todayPunches;
    final progress = summary.timelineProgress;
    final countdown = summary.checkoutCountdown;
    final punctuality = summary.punctuality;
    final shift = summary.shift;

    final badgeColor = MobileSummaryModel.parseHexColor(
      punctuality.badgeColorHex,
      brandPrimary,
    );

    final inText = (punches.firstCheckInFormatted != null &&
            punches.firstCheckInFormatted!.trim().isNotEmpty)
        ? punches.firstCheckInFormatted!
        : '-- : --';
    final outText = (punches.lastCheckOutFormatted != null &&
            punches.lastCheckOutFormatted!.trim().isNotEmpty)
        ? punches.lastCheckOutFormatted!
        : '-- : --';

    final shiftRange = (shift.startTime.isNotEmpty && shift.endTime.isNotEmpty)
        ? '${shift.startTime} – ${shift.endTime}'
        : (shift.isHoliday && shift.holidayName.isNotEmpty
            ? shift.holidayName
            : (shift.isOffDay ? 'Off Day' : ''));

    final footerText = countdown.isOvertime && countdown.overtimeMinutes > 0
        ? 'Overtime: +${countdown.overtimeMinutes} mins'
        : (countdown.timeLeftFormatted.isNotEmpty
            ? (countdown.targetCheckoutTime.isNotEmpty
                ? '${countdown.timeLeftFormatted}  •  Ends ${countdown.targetCheckoutTime}'
                : countdown.timeLeftFormatted)
            : punctuality.message);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Status",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: HRColors.brandDarkText,
                      ),
                    ),
                    if (shiftRange.isNotEmpty)
                      Text(
                        shiftRange,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: HRColors.brandGreyText,
                        ),
                      ),
                  ],
                ),
              ),
              if (punctuality.title.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    punctuality.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Obvious Color-Coded Check-In / Check-Out Time Tiles
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.login_rounded,
                              size: 13, color: Color(0xFF15803D)),
                          SizedBox(width: 4),
                          Text(
                            'CHECK IN',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        inText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF14532D),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.logout_rounded,
                              size: 13, color: Color(0xFFC2410C)),
                          SizedBox(width: 4),
                          Text(
                            'CHECK OUT',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC2410C),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        outText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7C2D12),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar + Worked / Countdown Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Worked: ${progress.workedFormatted}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: brandPrimary,
                ),
              ),
              Text(
                '${progress.progressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: HRColors.brandGreyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (progress.progressPercentage / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFF1ECEE),
              valueColor: AlwaysStoppedAnimation<Color>(
                punches.isWorking
                    ? const Color(0xFF16A34A)
                    : (progress.progressPercentage > 0
                        ? brandPrimary
                        : badgeColor),
              ),
            ),
          ),
          if (footerText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              footerText,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: HRColors.brandGreyText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard(
    MobileQuickMetrics metrics,
    Color brandPrimary,
    Color brandLight,
  ) {
    final leaveFormatted = metrics.totalLeaveAvailable % 1 == 0
        ? metrics.totalLeaveAvailable.toInt().toString()
        : metrics.totalLeaveAvailable.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statTile(
                  value: '${metrics.presentDays}',
                  label: 'Present',
                  bg: const Color(0xFFF0FDF4),
                  valueColor: const Color(0xFF15803D),
                  labelColor: const Color(0xFF166534),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(
                  value: '${metrics.absentDays}',
                  label: 'Absent',
                  bg: const Color(0xFFFEF2F2),
                  valueColor: const Color(0xFFDC2626),
                  labelColor: const Color(0xFF991B1B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(
                  value: leaveFormatted,
                  label: 'Leave Left',
                  bg: brandLight,
                  valueColor: brandPrimary,
                  labelColor: brandPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HRColors.brandGreyText,
                  ),
                  children: [
                    const TextSpan(text: 'OT: '),
                    TextSpan(
                      text: metrics.overtimeHours,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: HRColors.brandDarkText,
                      ),
                    ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HRColors.brandGreyText,
                  ),
                  children: [
                    const TextSpan(text: 'Short Leave: '),
                    TextSpan(
                      text:
                          '${metrics.shortLeavesUsed} / ${metrics.shortLeaveTotal} used',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String value,
    required String label,
    required Color bg,
    required Color valueColor,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }

  List<MobileCalendarDay> _currentWeekDays(List<MobileCalendarDay> allDays) {
    if (allDays.length <= 7) return allDays;
    int todayIdx = allDays.indexWhere((d) => d.isToday);
    if (todayIdx == -1) todayIdx = 0;

    // Align week window around today (Sun..Sat or 7-day window containing today)
    const dowOrder = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final dowIdx = dowOrder.indexOf(allDays[todayIdx].dayOfWeek.toUpperCase());
    int start = dowIdx >= 0 ? todayIdx - dowIdx : (todayIdx ~/ 7) * 7;
    if (start < 0) start = 0;
    int end = start + 7;
    if (end > allDays.length) {
      end = allDays.length;
      start = (end - 7).clamp(0, allDays.length);
    }
    return allDays.sublist(start, end);
  }

  Widget _buildRosterCard(
    BuildContext context,
    MobileCalendar calendar,
    Color brandPrimary,
    Color brandLight,
  ) {
    final allDays = calendar.days;
    final weekDays = _currentWeekDays(allDays);

    MobileCalendarDay? selectedDay;
    if (_selectedDayNumber != null) {
      for (final d in allDays) {
        if (d.day == _selectedDayNumber) {
          selectedDay = d;
          break;
        }
      }
    }
    selectedDay ??= allDays.firstWhere(
      (d) => d.isToday,
      orElse: () => allDays.first,
    );

    // Leading empty cells for Full Calendar month grid (Sun = 0 .. Sat = 6)
    const dowHeaders = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final firstDowIdx = allDays.isNotEmpty
        ? dowHeaders.indexOf(allDays.first.dayOfWeek.toUpperCase())
        : 0;
    final leadingBlanks = firstDowIdx > 0 ? firstDowIdx : 0;
    final totalSlots = leadingBlanks + allDays.length;
    final monthRowCount = (totalSlots + 6) ~/ 7;
    final legendItems = _buildLegendItems(allDays, brandPrimary);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Expandable Full Calendar / Week View link button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.rosterText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: HRColors.brandDarkText,
                      ),
                    ),
                    if (calendar.monthName.isNotEmpty)
                      Text(
                        calendar.monthName,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: HRColors.brandGreyText,
                        ),
                      ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() => _showFullCalendar = !_showFullCalendar);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: brandLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showFullCalendar ? 'Week View' : 'Full Calendar',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: brandPrimary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        _showFullCalendar
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: brandPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Smooth AnimatedSize switch between Current Week (7 days) & Full Month Grid
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: _showFullCalendar
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: dowHeaders
                            .map(
                              (h) => Expanded(
                                child: Center(
                                  child: Text(
                                    h.substring(0, 1),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: HRColors.brandGreyText,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 6),
                      for (int r = 0; r < monthRowCount; r++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: r == monthRowCount - 1 ? 0 : 4,
                          ),
                          child: Row(
                            children: List.generate(7, (c) {
                              final dayIdx = r * 7 + c - leadingBlanks;
                              if (dayIdx < 0 || dayIdx >= allDays.length) {
                                return const Expanded(child: SizedBox.shrink());
                              }
                              final day = allDays[dayIdx];
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: _buildDayCell(
                                    day: day,
                                    showDow: false,
                                    isSelected: selectedDay?.day == day.day,
                                    brandPrimary: brandPrimary,
                                    brandLight: brandLight,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  )
                : Row(
                    children: weekDays
                        .map(
                          (day) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: _buildDayCell(
                                day: day,
                                showDow: true,
                                isSelected: selectedDay?.day == day.day,
                                brandPrimary: brandPrimary,
                                brandLight: brandLight,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),

          // Color-Dot Legend / Key
          if (legendItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: legendItems.map((item) {
                final isLight = item.color.computeLuminance() > 0.78;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                        border: isLight
                            ? Border.all(
                                color: Colors.black.withOpacity(0.18),
                                width: 0.6,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: HRColors.brandGreyText,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],

          // Selected Day Detail Footer
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: _buildDayDetailFooter(selectedDay, brandPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell({
    required MobileCalendarDay day,
    required bool showDow,
    required bool isSelected,
    required Color brandPrimary,
    required Color brandLight,
  }) {
    final dotColor = MobileSummaryModel.parseHexColor(
      day.badgeColorHex,
      const Color(0xFF94A3B8),
    );

    Color bg = Colors.transparent;
    Border? border;
    Color textColor = HRColors.brandDarkText;

    if (day.isToday) {
      bg = brandPrimary;
      textColor = Colors.white;
    } else if (isSelected) {
      bg = brandLight;
      border = Border.all(color: brandPrimary.withOpacity(0.45));
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedDayNumber = day.day),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showDow && day.dayOfWeek.isNotEmpty) ...[
              Text(
                day.dayOfWeek.substring(0, 1),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: day.isToday
                      ? Colors.white.withOpacity(0.8)
                      : HRColors.brandGreyText,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: textColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: day.isToday ? const Color(0xFFFACC15) : dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetailFooter(MobileCalendarDay day, Color brandPrimary) {
    final dotColor = MobileSummaryModel.parseHexColor(
      day.badgeColorHex,
      brandPrimary,
    );

    String statusText =
        day.statusLabel.isNotEmpty ? day.statusLabel : day.status;
    if (day.holidayName != null && day.holidayName!.trim().isNotEmpty) {
      statusText = day.holidayName!.trim();
    } else if (day.shortPeriod != null && day.shortPeriod!.trim().isNotEmpty) {
      final p = day.shortPeriod!.trim().toLowerCase();
      statusText = p == 'morning' ? '2hr Morning' : '2hr Evening';
    } else if (day.halfPeriod != null && day.halfPeriod!.trim().isNotEmpty) {
      final p = day.halfPeriod!.trim().toLowerCase();
      statusText = p == 'morning' ? 'Half · Morning' : 'Half · Evening';
    }

    final hasIn =
        day.firstCheckIn != null && day.firstCheckIn!.trim().isNotEmpty;
    final hasOut =
        day.lastCheckOut != null && day.lastCheckOut!.trim().isNotEmpty;
    final rightText = (hasIn || hasOut)
        ? '${hasIn ? day.firstCheckIn : '--:--'} → ${hasOut ? day.lastCheckOut : '--:--'}'
        : (day.workedHrs > 0
            ? '${day.workedHrs.toStringAsFixed(1)} hrs'
            : day.dayOfWeek);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Day ${day.day}  •  $statusText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: HRColors.brandDarkText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          rightText,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: HRColors.brandGreyText,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  List<({String label, Color color})> _buildLegendItems(
    List<MobileCalendarDay> allDays,
    Color brandPrimary,
  ) {
    final Map<String, ({String label, Color color})> seen = {};

    for (final day in allDays) {
      String rawLabel = day.statusLabel.trim();
      if (rawLabel.isEmpty && day.status.trim().isNotEmpty) {
        rawLabel = day.status
            .trim()
            .split('_')
            .where((w) => w.isNotEmpty)
            .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' ');
      }
      if (rawLabel.isEmpty) continue;

      final key = rawLabel.toLowerCase();
      if (key == 'today' || seen.containsKey(key)) continue;

      final color = MobileSummaryModel.parseHexColor(
        day.badgeColorHex,
        const Color(0xFF94A3B8),
      );
      seen[key] = (label: rawLabel, color: color);
    }

    const priorityOrder = [
      'present',
      'late',
      'absent',
      'half day',
      'short leave',
      'on leave',
      'leave',
      'holiday',
      'off day',
      'off',
      'scheduled',
      'upcoming',
    ];

    final items = seen.values.toList()
      ..sort((a, b) {
        final ai = priorityOrder.indexOf(a.label.toLowerCase());
        final bi = priorityOrder.indexOf(b.label.toLowerCase());
        if (ai != -1 && bi != -1) return ai.compareTo(bi);
        if (ai != -1) return -1;
        if (bi != -1) return 1;
        return a.label.compareTo(b.label);
      });

    if (allDays.any((d) => d.isToday)) {
      items.add((label: 'Today', color: brandPrimary));
    }

    return items;
  }
}
