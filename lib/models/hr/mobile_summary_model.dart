import 'package:flutter/material.dart';

/// Strongly-typed model for `GET /attendance/mobile-summary?date=YYYY-MM-DD`.
class MobileSummaryModel {
  final String displayDate;
  final String activeDate;
  final MobileShiftInfo shift;
  final MobileTodayPunches todayPunches;
  final MobileTimelineProgress timelineProgress;
  final MobileCheckoutCountdown checkoutCountdown;
  final MobilePunctuality punctuality;
  final List<MobileHomeAlert> alerts;
  final MobileQuickMetrics quickMetrics;
  final MobileCalendar calendar;

  const MobileSummaryModel({
    required this.displayDate,
    required this.activeDate,
    required this.shift,
    required this.todayPunches,
    required this.timelineProgress,
    required this.checkoutCountdown,
    required this.punctuality,
    required this.alerts,
    required this.quickMetrics,
    required this.calendar,
  });

  static Color parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    try {
      final cleaned = hex.trim().replaceFirst('#', '');
      if (cleaned.length == 6) {
        return Color(int.parse('FF$cleaned', radix: 16));
      }
      if (cleaned.length == 8) {
        return Color(int.parse(cleaned, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  factory MobileSummaryModel.fromJson(Map<String, dynamic> root) {
    final data = (root['data'] is Map)
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;

    Map<String, dynamic> mapOf(dynamic v) =>
        (v is Map) ? Map<String, dynamic>.from(v) : const {};

    final dateInfo = mapOf(data['date_info']);
    final alertsRaw = data['alerts'];
    final alerts = <MobileHomeAlert>[];
    if (alertsRaw is List) {
      for (final item in alertsRaw) {
        if (item is Map) {
          alerts.add(MobileHomeAlert.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return MobileSummaryModel(
      displayDate: (dateInfo['display_date'] ?? '').toString(),
      activeDate: (dateInfo['active_date'] ?? '').toString(),
      shift: MobileShiftInfo.fromJson(mapOf(data['shift'])),
      todayPunches: MobileTodayPunches.fromJson(mapOf(data['today_punches'])),
      timelineProgress:
          MobileTimelineProgress.fromJson(mapOf(data['timeline_progress'])),
      checkoutCountdown:
          MobileCheckoutCountdown.fromJson(mapOf(data['checkout_countdown'])),
      punctuality: MobilePunctuality.fromJson(mapOf(data['punctuality'])),
      alerts: alerts,
      quickMetrics: MobileQuickMetrics.fromJson(mapOf(data['quick_metrics'])),
      calendar: MobileCalendar.fromJson(mapOf(data['calendar'])),
    );
  }
}

class MobileShiftInfo {
  final bool isScheduledWorkDay;
  final bool isOffDay;
  final bool isHoliday;
  final String holidayName;
  final String startTime;
  final String endTime;

  const MobileShiftInfo({
    required this.isScheduledWorkDay,
    required this.isOffDay,
    required this.isHoliday,
    required this.holidayName,
    required this.startTime,
    required this.endTime,
  });

  factory MobileShiftInfo.fromJson(Map<String, dynamic> m) => MobileShiftInfo(
        isScheduledWorkDay: m['is_scheduled_work_day'] == true,
        isOffDay: m['is_off_day'] == true,
        isHoliday: m['is_holiday'] == true,
        holidayName: (m['holiday_name'] ?? '').toString(),
        startTime:
            (m['effective_start_time'] ?? m['scheduled_start_time'] ?? '')
                .toString(),
        endTime: (m['effective_end_time'] ?? m['scheduled_end_time'] ?? '')
            .toString(),
      );
}

class MobileTodayPunches {
  final String? firstCheckInFormatted;
  final String? lastCheckOutFormatted;
  final bool isCheckedIn;
  final bool isCheckedOut;
  final bool isWorking;
  final String status;

  const MobileTodayPunches({
    required this.firstCheckInFormatted,
    required this.lastCheckOutFormatted,
    required this.isCheckedIn,
    required this.isCheckedOut,
    required this.isWorking,
    required this.status,
  });

  factory MobileTodayPunches.fromJson(Map<String, dynamic> m) =>
      MobileTodayPunches(
        firstCheckInFormatted: m['first_check_in_formatted']?.toString(),
        lastCheckOutFormatted: m['last_check_out_formatted']?.toString(),
        isCheckedIn: m['is_checked_in'] == true,
        isCheckedOut: m['is_checked_out'] == true,
        isWorking: m['is_working'] == true,
        status: (m['status'] ?? '').toString(),
      );
}

class MobileTimelineProgress {
  final double progressPercentage;
  final String workedFormatted;

  const MobileTimelineProgress({
    required this.progressPercentage,
    required this.workedFormatted,
  });

  factory MobileTimelineProgress.fromJson(Map<String, dynamic> m) {
    final pct = (m['progress_percentage'] is num)
        ? (m['progress_percentage'] as num).toDouble()
        : double.tryParse(m['progress_percentage']?.toString() ?? '') ?? 0.0;
    return MobileTimelineProgress(
      progressPercentage: pct.clamp(0.0, 100.0),
      workedFormatted: (m['worked_formatted'] ?? '0h 0m').toString(),
    );
  }
}

class MobileCheckoutCountdown {
  final bool canCheckOut;
  final String timeLeftFormatted;
  final bool isOvertime;
  final int overtimeMinutes;
  final String targetCheckoutTime;

  const MobileCheckoutCountdown({
    required this.canCheckOut,
    required this.timeLeftFormatted,
    required this.isOvertime,
    required this.overtimeMinutes,
    required this.targetCheckoutTime,
  });

  factory MobileCheckoutCountdown.fromJson(Map<String, dynamic> m) =>
      MobileCheckoutCountdown(
        canCheckOut: m['can_check_out'] == true,
        timeLeftFormatted: (m['time_left_formatted'] ?? '').toString(),
        isOvertime: m['is_overtime'] == true,
        overtimeMinutes: (m['overtime_minutes'] is num)
            ? (m['overtime_minutes'] as num).toInt()
            : int.tryParse(m['overtime_minutes']?.toString() ?? '') ?? 0,
        targetCheckoutTime: (m['target_checkout_time'] ?? '').toString(),
      );
}

class MobilePunctuality {
  final String status;
  final String badgeColorHex;
  final String title;
  final String message;

  const MobilePunctuality({
    required this.status,
    required this.badgeColorHex,
    required this.title,
    required this.message,
  });

  factory MobilePunctuality.fromJson(Map<String, dynamic> m) =>
      MobilePunctuality(
        status: (m['status'] ?? '').toString(),
        badgeColorHex: (m['badge_color'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        message: (m['message'] ?? '').toString(),
      );
}

class MobileHomeAlert {
  final String type;
  final String severity;
  final String title;
  final String message;
  final String primaryLabel;
  final String primaryAction;
  final String secondaryLabel;
  final String secondaryAction;

  const MobileHomeAlert({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.primaryAction,
    required this.secondaryLabel,
    required this.secondaryAction,
  });

  factory MobileHomeAlert.fromJson(Map<String, dynamic> m) {
    final p = (m['action_primary'] is Map)
        ? Map<String, dynamic>.from(m['action_primary'] as Map)
        : const <String, dynamic>{};
    final s = (m['action_secondary'] is Map)
        ? Map<String, dynamic>.from(m['action_secondary'] as Map)
        : const <String, dynamic>{};
    return MobileHomeAlert(
      type: (m['type'] ?? '').toString(),
      severity: (m['severity'] ?? 'warning').toString(),
      title: (m['title'] ?? '').toString(),
      message: (m['message'] ?? '').toString(),
      primaryLabel: (p['label'] ?? '').toString(),
      primaryAction: (p['action'] ?? '').toString(),
      secondaryLabel: (s['label'] ?? '').toString(),
      secondaryAction: (s['action'] ?? '').toString(),
    );
  }
}

class MobileQuickMetrics {
  final int presentDays;
  final int absentDays;
  final String overtimeHours;
  final int shortLeavesUsed;
  final int shortLeavesRemaining;
  final double totalLeaveAvailable;

  const MobileQuickMetrics({
    required this.presentDays,
    required this.absentDays,
    required this.overtimeHours,
    required this.shortLeavesUsed,
    required this.shortLeavesRemaining,
    required this.totalLeaveAvailable,
  });

  int get shortLeaveTotal => shortLeavesUsed + shortLeavesRemaining;

  factory MobileQuickMetrics.fromJson(Map<String, dynamic> m) {
    int toInt(dynamic v) =>
        (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
    double toDouble(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

    final balances = (m['leave_balances'] is Map)
        ? Map<String, dynamic>.from(m['leave_balances'] as Map)
        : const <String, dynamic>{};

    return MobileQuickMetrics(
      presentDays: toInt(m['present_days']),
      absentDays: toInt(m['absent_days']),
      overtimeHours: (m['overtime_hours'] ?? '0.0 hrs').toString(),
      shortLeavesUsed: toInt(m['short_leaves_used']),
      shortLeavesRemaining: toInt(m['short_leaves_remaining']),
      totalLeaveAvailable: toDouble(balances['total_available']),
    );
  }
}

class MobileCalendar {
  final String monthName;
  final int year;
  final int month;
  final List<MobileCalendarDay> days;

  const MobileCalendar({
    required this.monthName,
    required this.year,
    required this.month,
    required this.days,
  });

  factory MobileCalendar.fromJson(Map<String, dynamic> m) {
    int toInt(dynamic v) =>
        (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
    final list = <MobileCalendarDay>[];
    if (m['days'] is List) {
      for (final d in m['days'] as List) {
        if (d is Map) {
          list.add(MobileCalendarDay.fromJson(Map<String, dynamic>.from(d)));
        }
      }
    }
    return MobileCalendar(
      monthName: (m['month_name'] ?? '').toString(),
      year: toInt(m['year']),
      month: toInt(m['month']),
      days: list,
    );
  }
}

class MobileCalendarDay {
  final String date;
  final int day;
  final String dayOfWeek;
  final bool isToday;
  final String status;
  final String statusLabel;
  final String badgeColorHex;
  final String? firstCheckIn;
  final String? lastCheckOut;
  final double workedHrs;
  final String? halfPeriod;
  final String? shortPeriod;
  final String? leaveType;
  final String? holidayName;

  const MobileCalendarDay({
    required this.date,
    required this.day,
    required this.dayOfWeek,
    required this.isToday,
    required this.status,
    required this.statusLabel,
    required this.badgeColorHex,
    required this.firstCheckIn,
    required this.lastCheckOut,
    required this.workedHrs,
    required this.halfPeriod,
    required this.shortPeriod,
    required this.leaveType,
    required this.holidayName,
  });

  factory MobileCalendarDay.fromJson(Map<String, dynamic> m) =>
      MobileCalendarDay(
        date: (m['date'] ?? '').toString(),
        day: (m['day'] is num)
            ? (m['day'] as num).toInt()
            : int.tryParse(m['day']?.toString() ?? '') ?? 0,
        dayOfWeek: (m['day_of_week'] ?? '').toString(),
        isToday: m['is_today'] == true,
        status: (m['status'] ?? '').toString(),
        statusLabel: (m['status_label'] ?? '').toString(),
        badgeColorHex: (m['badge_color'] ?? '').toString(),
        firstCheckIn: m['first_check_in']?.toString(),
        lastCheckOut: m['last_check_out']?.toString(),
        workedHrs: (m['worked_hrs'] is num)
            ? (m['worked_hrs'] as num).toDouble()
            : double.tryParse(m['worked_hrs']?.toString() ?? '') ?? 0.0,
        halfPeriod: m['half_period']?.toString(),
        shortPeriod: m['short_period']?.toString(),
        leaveType: m['leave_type']?.toString(),
        holidayName: m['holiday_name']?.toString(),
      );
}
