import 'package:auto_size_text/auto_size_text.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/models/hr/todo_model.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/helpers/design_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';


class MobileTodosScreen extends StatefulWidget {
  const MobileTodosScreen({super.key});

  @override
  State<MobileTodosScreen> createState() => _MobileTodosScreenState();
}

class _MobileTodosScreenState extends State<MobileTodosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final AutoSizeGroup _tabGroup = AutoSizeGroup();
  bool _loading = true;
  String? _error;
  List<TodoItem> _remoteAttendanceTodos = [];
  List<TodoItem> _otherTodos = [];

  static const double _g8 = 8;
  static const double _g12 = 12;
  static const double _g16 = 16;
  static const double _g20 = 20;
  static const double _g24 = 24;

  static const Color _pageBg = Color.fromARGB(255, 248, 250, 252);
  static const Color _surface = Color.fromARGB(255, 248, 250, 252);
  static Color get _burgundy => HRColors.brandPrimary;
  static Color get _burgundyLight => HRColors.brandLight;
  static Color get _textBurgundy => HRColors.brandDarkText;
  static const Color _textGrey = Color(0xFF7D6C6F); // Soft grey text

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await APIService().getTodos(approvableByMe: true);
      if (!mounted) return;
      setState(() {
        _remoteAttendanceTodos = results.where((e) => e.type == 'remote_attendance').toList();
        _otherTodos = results.where((e) => e.type != 'remote_attendance').toList();
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('[TODOS][ERROR] $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() {
        _error = DesignConfig.getFriendlyErrorMessage(context, e);
        _loading = false;
      });
    }
  }

  Future<void> _approveTodoItem(String todoId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final response = await APIService().approveTodo(todoId);
      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response['success'] == true) {
        DesignConfig.showTopToast(
          context,
          AppLocalizations.of(context)!.todoApproveSuccess,
          background: Colors.green,
        );
        _load();
      } else {
        DesignConfig.showTopToast(
          context,
          DesignConfig.getFriendlyErrorMessage(
            context,
            response['message']?.toString() ?? AppLocalizations.of(context)!.todoApproveFailed,
          ),
          background: Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      DesignConfig.showTopToast(
        context,
        DesignConfig.getFriendlyErrorMessage(context, e),
        background: Colors.red,
      );
    }
  }

  Future<void> _rejectTodoItem(String todoId, String reason) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final response = await APIService().rejectTodo(todoId, reason);
      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response['success'] == true) {
        DesignConfig.showTopToast(
          context,
          AppLocalizations.of(context)!.todoRejectSuccess,
          background: Colors.orange,
        );
        _load();
      } else {
        DesignConfig.showTopToast(
          context,
          DesignConfig.getFriendlyErrorMessage(
            context,
            response['message']?.toString() ?? AppLocalizations.of(context)!.todoRejectFailed,
          ),
          background: Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      DesignConfig.showTopToast(
        context,
        DesignConfig.getFriendlyErrorMessage(context, e),
        background: Colors.red,
      );
    }
  }

  Future<bool?> _showApproveConfirmation(TodoItem item) {
    final employeeName = item.user?.name ?? 'Employee';
    return showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.todoApproveTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 160),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocalizations.of(context)!.todoApproveConfirmMessage(employeeName),
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[800],
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(AppLocalizations.of(context)!.cancelLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                AppLocalizations.of(context)!.approvedLable,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showRejectConfirmation(TodoItem item) {
    final reasonController = TextEditingController();
    final employeeName = item.user?.name ?? 'Employee';
    return showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isValid = reasonController.text.trim().isNotEmpty;
            return AlertDialog(
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.cancel_outlined, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.todoRejectTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppLocalizations.of(context)!.todoRejectConfirmMessage(employeeName),
                          style: const TextStyle(color: Colors.black87, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: TextField(
                          controller: reasonController,
                          maxLines: 3,
                          maxLength: 300,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.todoReasonHint,
                            counterText: '',
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${reasonController.text.trim().length}/300',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[800],
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(AppLocalizations.of(context)!.cancelLabel),
                ),
                ElevatedButton(
                  onPressed: isValid
                      ? () {
                          final reason = reasonController.text.trim();
                          Navigator.of(ctx).pop(reason);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.withOpacity(0.45),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.rejectedLable,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTodoDetailsBottomSheet(TodoItem item) {
    if (item.type == 'remote_attendance') {
      _showRemoteAttendanceBottomSheet(item);
    } else if (item.type == 'profile_unlock') {
      _showProfileUnlockBottomSheet(item);
    } else {
      _showOtherTodoBottomSheet(item);
    }
  }

  String _formatDateTime(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return '-';
    int milliseconds = timestamp;
    if (timestamp <= 9999999999) {
      milliseconds = timestamp * 1000;
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return DateFormat('yyyy-MM-dd hh:mm a').format(dt);
  }

  String _stripPlusCode(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    // Strip leading Plus Code (e.g., "VW7X+55P, Bandarawela" -> "Bandarawela")
    final stripped = trimmed.replaceAll(RegExp(r'^[A-Z0-9]{2,8}\+[A-Z0-9]{2,4}\s*,?\s*'), '').trim();
    if (stripped.contains('+') && RegExp(r'^[A-Z0-9]{2,8}\+[A-Z0-9]{2,4}$').hasMatch(stripped)) {
      return '';
    }
    return stripped;
  }

  Future<String> _resolveAddress(Map<String, dynamic> p) async {
    final rawAddr = p['address']?.toString().trim() ?? '';
    if (rawAddr.isNotEmpty && rawAddr != '-') {
      final cleaned = _stripPlusCode(rawAddr);
      if (cleaned.isNotEmpty) return cleaned;
    }

    final latStr = p['lat']?.toString() ?? '';
    final lngStr = p['lng']?.toString() ?? '';
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
            return parts.join(', ');
          }
        }
      } catch (e) {
        debugPrint('Reverse geocode error: $e');
      }
      return '$lat, $lng';
    }
    return '-';
  }

  void _showRemoteAttendanceBottomSheet(TodoItem item) {
    final statusColor = item.completed
        ? Colors.green
        : (item.waitingForPreviousStage ? Colors.red : Colors.orange);
    final isPending = !item.completed;
    final displayStatus = item.completed
        ? AppLocalizations.of(context)!.completedLabel
        : (item.waitingForPreviousStage
            ? AppLocalizations.of(context)!.todoWaitingForPreviousStage
            : AppLocalizations.of(context)!.todoPending);
    final l10n = AppLocalizations.of(context)!;
    final p = item.payload ?? {};

    final punchTypeRaw = p['type']?.toString().toUpperCase() ?? '-';
    String punchType = punchTypeRaw;
    Color punchColor = HRColors.orangeColor;
    IconData punchIcon = Icons.login;
    if (punchTypeRaw == 'CHECK_IN' || punchTypeRaw == 'CHECKIN' || punchTypeRaw == 'IN') {
      punchType = l10n.checkIn;
      punchColor = Colors.green;
      punchIcon = Icons.login;
    } else if (punchTypeRaw == 'CHECK_OUT' || punchTypeRaw == 'CHECKOUT' || punchTypeRaw == 'OUT') {
      punchType = l10n.checkOut;
      punchColor = Colors.blue;
      punchIcon = Icons.logout;
    }

    final checkedAtRaw = p['checked_at'];
    String checkedAt = '-';
    if (checkedAtRaw != null) {
      if (checkedAtRaw is int) {
        checkedAt = _formatDateTime(checkedAtRaw);
      } else if (checkedAtRaw is String) {
        final parsed = DateTime.tryParse(checkedAtRaw);
        if (parsed != null) {
          checkedAt = DateFormat('yyyy-MM-dd hh:mm a').format(parsed.toLocal());
        } else {
          checkedAt = checkedAtRaw;
        }
      } else {
        checkedAt = checkedAtRaw.toString();
      }
    }

    final rawAccuracy = p['location_accuracy'];
    String accuracy = '-';
    if (rawAccuracy != null) {
      final parsed = double.tryParse(rawAccuracy.toString());
      if (parsed != null) {
        accuracy = parsed.toStringAsFixed(2);
      } else {
        accuracy = rawAccuracy.toString();
      }
    }
    final battery = p['battery_level']?.toString() ?? '-';
    final lat = p['lat']?.toString() ?? '-';
    final lng = p['lng']?.toString() ?? '-';
    final deviceId = p['device_id']?.toString() ?? '-';

    final completedByJson = item.raw['completed_by'];
    TodoUser? completedBy = completedByJson is Map ? TodoUser.fromJson(Map<String, dynamic>.from(completedByJson)) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetHeight = MediaQuery.of(ctx).size.height * 0.82;
        return Container(
          height: sheetHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.contains(':') ? item.title.split(':').first.trim() : item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              displayStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      Text(
                        l10n.employeeDetails,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEmployeeCard(item),
                      const SizedBox(height: 20),
                      Text(
                        l10n.todoRequestDetails,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _burgundyLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: punchColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(punchIcon, size: 16, color: punchColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        punchType,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: punchColor),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.pin_drop_outlined, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  item.zone,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const Divider(height: 20, thickness: 1),
                            _buildInfoRow(Icons.schedule, l10n.todoDetailCheckedAt, checkedAt),
                            _buildInfoRow(Icons.devices, l10n.todoDetailDeviceId, deviceId),
                            _buildInfoRow(Icons.calendar_today_outlined, l10n.todoDetailRequestedAt, _formatDateTime(item.cts)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildBadge(Icons.my_location, l10n.todoDetailAccuracy, '$accuracy m'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildBadge(Icons.battery_std, l10n.todoDetailBattery, '$battery%'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            FutureBuilder<String>(
                              future: _resolveAddress(p),
                              builder: (context, snapshot) {
                                final locationText = snapshot.data ??
                                    (p['address']?.toString().isNotEmpty == true
                                        ? p['address'].toString()
                                        : (lat != '-' && lng != '-' ? '$lat, $lng' : '-'));
                                return _buildClickableInfoRow(
                                  Icons.location_on_outlined,
                                  'Location Address',
                                  locationText,
                                  onTap: () async {
                                    if (lat != '-' && lng != '-') {
                                      final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                                      final uri = Uri.parse(url);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                            if (completedBy != null) ...[
                              const Divider(height: 20, thickness: 1),
                              _buildInfoRow(
                                Icons.person_outline,
                                l10n.todoDetailCompletedBy,
                                completedBy.name,
                              ),
                              _buildInfoRow(Icons.done_all, l10n.todoDetailCompletedAt, _formatDateTime(item.uts)),
                            ],
                          ],
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 20),
                        Text(
                          l10n.todoActionsTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildActionButtons(item, ctx),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProfileUnlockBottomSheet(TodoItem item) {
    final statusColor = item.completed
        ? Colors.green
        : (item.waitingForPreviousStage ? Colors.red : Colors.orange);
    final isPending = !item.completed;
    final displayStatus = item.completed
        ? AppLocalizations.of(context)!.completedLabel
        : (item.waitingForPreviousStage
            ? AppLocalizations.of(context)!.todoWaitingForPreviousStage
            : AppLocalizations.of(context)!.todoPending);
    final l10n = AppLocalizations.of(context)!;
    final m = item.meta ?? {};
    final reason = m['reason']?.toString() ?? m['summary']?.toString() ?? '-';
    final summary = m['summary']?.toString() ?? '-';
    final action = m['action']?.toString() ?? '-';

    TodoUser? requestedForUser = item.user;
    if (requestedForUser == null && item.meta != null && item.meta!['user_id'] != null) {
      requestedForUser = TodoUser(
        id: item.meta!['user_id']?.toString() ?? '',
        name: item.meta!['user_name']?.toString() ?? item.meta!['user_email']?.toString() ?? '',
        email: item.meta!['user_email']?.toString() ?? '',
        epfPretty: item.meta!['user_epf_no']?.toString(),
      );
    }

    TodoUser? requestedByUser = item.by;
    if (requestedByUser == null && item.meta != null && item.meta!['requested_by_user_id'] != null) {
      requestedByUser = TodoUser(
        id: item.meta!['requested_by_user_id']?.toString() ?? '',
        name: item.meta!['requested_by_name']?.toString() ?? item.meta!['requested_by_email']?.toString() ?? '',
        email: item.meta!['requested_by_email']?.toString() ?? '',
        epfPretty: null,
      );
    }

    final completedByJson = item.raw['completed_by'];
    TodoUser? completedBy = completedByJson is Map ? TodoUser.fromJson(Map<String, dynamic>.from(completedByJson)) : null;
    final epfPretty = requestedForUser?.epfPretty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetHeight = MediaQuery.of(ctx).size.height * 0.82;
        return Container(
          height: sheetHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              displayStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      Text(
                        l10n.todoDetailRequestedFor,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _burgundyLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 20, color: Colors.black54),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AutoSizeText(
                                    requestedForUser?.name ?? 'Unknown User',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (epfPretty != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('EPF', style: TextStyle(fontSize: 8, color: Colors.black54)),
                                    const SizedBox(height: 2),
                                    Text(epfPretty, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.todoRequestDetails,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _burgundyLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(Icons.layers_outlined, l10n.todoDetailCategory, item.type.toUpperCase()),
                            _buildInfoRow(Icons.pin_drop_outlined, l10n.todoDetailZone, item.zone),
                            _buildInfoRow(Icons.info_outline, l10n.todoDetailSummary, summary),
                            _buildInfoRow(Icons.touch_app_outlined, 'Action', action),
                            if (requestedByUser != null)
                              _buildInfoRow(
                                Icons.person,
                                l10n.todoDetailRequestedBy,
                                requestedByUser.name,
                              ),
                            _buildInfoRow(Icons.calendar_today_outlined, l10n.todoDetailRequestedAt, _formatDateTime(item.cts)),
                            if (completedBy != null) ...[
                              const Divider(height: 20, thickness: 1),
                              _buildInfoRow(
                                Icons.person_outline,
                                l10n.todoDetailCompletedBy,
                                completedBy.name,
                              ),
                              _buildInfoRow(Icons.done_all, l10n.todoDetailCompletedAt, _formatDateTime(item.uts)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.todoDetailReason,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _burgundyLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.format_quote, color: Colors.orange, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                reason,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 20),
                        Text(
                          l10n.todoActionsTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildActionButtons(item, ctx),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOtherTodoBottomSheet(TodoItem item) {
    final statusColor = item.completed
        ? Colors.green
        : (item.waitingForPreviousStage ? Colors.red : Colors.orange);
    final isPending = !item.completed;
    final displayStatus = item.completed
        ? AppLocalizations.of(context)!.completedLabel
        : (item.waitingForPreviousStage
            ? AppLocalizations.of(context)!.todoWaitingForPreviousStage
            : AppLocalizations.of(context)!.todoPending);
    final l10n = AppLocalizations.of(context)!;

    final completedByJson = item.raw['completed_by'];
    TodoUser? completedBy = completedByJson is Map ? TodoUser.fromJson(Map<String, dynamic>.from(completedByJson)) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetHeight = MediaQuery.of(ctx).size.height * 0.82;
        return Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: HRColors.backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              displayStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      Text(
                        l10n.employeeDetails,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEmployeeCard(item),
                      const SizedBox(height: 20),
                      Text(
                        l10n.todoRequestDetails,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: HRColors.lightOrangeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.layers_outlined, l10n.todoDetailCategory, item.type.toUpperCase()),
                            _buildInfoRow(Icons.pin_drop_outlined, l10n.todoDetailZone, item.zone),
                            if (item.by != null)
                              _buildInfoRow(
                                Icons.person,
                                l10n.todoDetailRequestedBy,
                                item.by!.name,
                              ),
                            _buildInfoRow(Icons.calendar_today_outlined, l10n.todoDetailRequestedAt, _formatDateTime(item.cts)),
                            if (item.type == 'attendance' && item.meta != null) ...[
                              const Divider(height: 20, thickness: 1),
                              if (item.meta!['rates'] is Map) ...[
                                _buildInfoRow(
                                  Icons.lock_clock_outlined,
                                  l10n.todoDetailPunctualityIncentive,
                                  item.meta!['rates']['punctuality_incentive'] == true ? l10n.yesLabel : l10n.noLabel,
                                ),
                                _buildInfoRow(
                                  Icons.payments_outlined,
                                  l10n.todoDetailAttendanceAllowance,
                                  item.meta!['rates']['attendance_allowance'] == true ? l10n.yesLabel : l10n.noLabel,
                                ),
                              ] else ...[
                                _buildInfoRow(Icons.payments_outlined, l10n.todoDetailRatesInfo, item.meta!['rates']?.toString() ?? '-'),
                              ]
                            ],
                            if (completedBy != null) ...[
                              const Divider(height: 20, thickness: 1),
                              _buildInfoRow(
                                Icons.person_outline,
                                l10n.todoDetailCompletedBy,
                                completedBy.name,
                              ),
                              _buildInfoRow(Icons.done_all, l10n.todoDetailCompletedAt, _formatDateTime(item.uts)),
                            ],
                          ],
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 20),
                        Text(
                          l10n.todoActionsTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildActionButtons(item, ctx),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmployeeCard(TodoItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  item.user?.name ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (item.user?.epfPretty != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('EPF', style: TextStyle(fontSize: 8, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(item.user!.epfPretty!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.black38),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableInfoRow(
    IconData icon,
    String label,
    String value, {
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.black38),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 12,
                          color: HRColors.orangeColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: HRColors.orangeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.open_in_new,
                        size: 13,
                        color: HRColors.orangeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.black45),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 8, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(TodoItem item, BuildContext ctx) {
    final l10n = AppLocalizations.of(context)!;
    final isEnabled = !item.waitingForPreviousStage;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isEnabled ? () async {
              final navigator = Navigator.of(ctx);
              final reason = await _showRejectConfirmation(item);
              if (reason != null) {
                navigator.pop();
                await _rejectTodoItem(item.id, reason);
              }
            } : null,
            icon: const Icon(Icons.close, size: 18),
            label: AutoSizeText(
              l10n.rejectAction,
              maxLines: 1,
              minFontSize: 10,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isEnabled ? Colors.red.shade700 : Colors.grey,
              side: BorderSide(color: isEnabled ? Colors.red.shade400 : Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isEnabled ? () async {
              final navigator = Navigator.of(ctx);
              final confirmed = await _showApproveConfirmation(item);
              if (confirmed == true) {
                navigator.pop();
                await _approveTodoItem(item.id);
              }
            } : null,
            icon: Icon(Icons.check, size: 18, color: isEnabled ? Colors.white : Colors.grey),
            label: AutoSizeText(
              l10n.approveAction,
              maxLines: 1,
              minFontSize: 10,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isEnabled ? Colors.white : Colors.grey, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled ? _burgundy : Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabBody(List<TodoItem> list) {
    if (list.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.black26),
                  const SizedBox(height: 16),
                  AutoSizeText(
                    AppLocalizations.of(context)!.noTodosFound,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 12,
                    style: const TextStyle(color: Colors.black45, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 30),
      itemCount: list.length,
      itemBuilder: (_, i) => TodoCardWidget(
        item: list[i],
        onTap: () => _showTodoDetailsBottomSheet(list[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = DesignConfig.buildErrorState(
        context,
        message: _error!,
        onRetry: _load,
      );
    } else {
      content = TabBarView(
        controller: _tab,
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: _tabBody(_remoteAttendanceTodos),
          ),
          RefreshIndicator(
            onRefresh: _load,
            child: _tabBody(_otherTodos),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(_g16, _g12, _g16, 0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: HRColors.flavorIconBackgroundColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Icon(Icons.navigate_before, color: HRColors.flavorIconColor),
                    ),
                  ),
                  const SizedBox(width: _g12),
                  Expanded(
                    child: AutoSizeText(
                      AppLocalizations.of(context)!.todos,
                      maxLines: 1,
                      minFontSize: 16,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textBurgundy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _g16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _g16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _burgundyLight,
                  borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
                ),
                child: TabBar(
                  controller: _tab,
                  dividerColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  indicator: BoxDecoration(
                    color: _burgundy,
                    borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius - 3),
                    boxShadow: [
                      BoxShadow(
                        color: _burgundy.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: _textGrey,
                  tabs: [
                    Tab(
                      child: AutoSizeText(
                        AppLocalizations.of(context)!.todoTabRemoteAttendance,
                        maxLines: 1,
                        minFontSize: 11,
                        group: _tabGroup,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Tab(
                      child: AutoSizeText(
                        AppLocalizations.of(context)!.todoTabOthers,
                        maxLines: 1,
                        minFontSize: 11,
                        group: _tabGroup,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: _g24),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

class TodoCardWidget extends StatelessWidget {
  final TodoItem item;
  final VoidCallback onTap;

  const TodoCardWidget({
    super.key,
    required this.item,
    required this.onTap,
  });

  DateTime? _getTimestamp(int? cts, Map<String, dynamic>? payload) {
    final raw = payload?['checked_at'];
    if (raw != null) {
      if (raw is int) {
        int ms = raw <= 9999999999 ? raw * 1000 : raw;
        return DateTime.fromMillisecondsSinceEpoch(ms);
      } else if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed.toLocal();
      }
    }
    if (cts != null && cts > 0) {
      int ms = cts <= 9999999999 ? cts * 1000 : cts;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Color badgeColor = const Color(0xFFFFF3E0);
    Color textColor = const Color(0xFFE65100);
    IconData statusIcon = Icons.hourglass_bottom;
    
    if (item.completed) {
      badgeColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle;
    } else if (item.waitingForPreviousStage) {
      badgeColor = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFC62828);
      statusIcon = Icons.hourglass_bottom;
    }

    final String displayStatus = item.completed
        ? AppLocalizations.of(context)!.completedLabel
        : (item.waitingForPreviousStage
            ? AppLocalizations.of(context)!.todoWaitingForPreviousStage
            : AppLocalizations.of(context)!.todoPending);

    IconData typeIcon = Icons.assignment_outlined;
    if (item.type == 'remote_attendance') {
      typeIcon = Icons.fingerprint;
    } else if (item.type == 'profile_unlock') {
      typeIcon = Icons.lock_open_outlined;
    } else if (item.type == 'attendance') {
      typeIcon = Icons.calendar_today_outlined;
    }

    final String userName = item.user?.name ?? 'Unknown User';
    final isRemoteAttendance = item.type == 'remote_attendance';

    String punchDetails = '';
    if (isRemoteAttendance && item.payload != null) {
      final punchType = item.payload!['type']?.toString().toUpperCase() ?? '';
      if (punchType.isNotEmpty) {
        punchDetails = (punchType == 'CHECK_IN' || punchType == 'CHECKIN' || punchType == 'IN')
            ? 'Check In'
            : 'Check Out';
      }
    }

    String todoTypeLabel = '';
    if (isRemoteAttendance) {
      todoTypeLabel = '';
    } else if (item.type == 'profile_unlock') {
      todoTypeLabel = 'Profile Unlock';
    } else if (item.type == 'attendance') {
      todoTypeLabel = 'Attendance';
    } else {
      todoTypeLabel = item.type.replaceAll('_', ' ').split(' ').map((str) => str.isEmpty ? '' : '${str[0].toUpperCase()}${str.substring(1)}').join(' ');
    }

    final dt = _getTimestamp(item.cts, item.payload);
    final dateStr = dt != null ? DateFormat('yyyy-MM-dd').format(dt) : '-';
    final timeStr = dt != null ? DateFormat('hh:mm a').format(dt) : '-';
    final fullDateTimeStr = dt != null ? DateFormat('yyyy-MM-dd hh:mm a').format(dt) : '-';

    final cardWidget = Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withOpacity(0.04)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: HRColors.brandPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: HRColors.brandPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              AutoSizeText(
                                userName,
                                minFontSize: 11,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: HRColors.brandDarkText,
                                ),
                              ),
                              if (item.user?.epfPretty != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: HRColors.brandPrimary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: AutoSizeText(
                                    item.user!.epfPretty!,
                                    style: TextStyle(
                                      color: HRColors.brandPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isRemoteAttendance && punchDetails.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: punchDetails.toUpperCase().contains('OUT')
                                  ? const Color(0xFFFFF3E0)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              punchDetails,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: punchDetails.toUpperCase().contains('OUT')
                                    ? const Color(0xFFE65100)
                                    : const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          if (item.completed || item.waitingForPreviousStage) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 12, color: textColor),
                                  const SizedBox(width: 4),
                                  AutoSizeText(
                                    displayStatus,
                                    maxLines: 1,
                                    minFontSize: 8,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 13, color: textColor),
                                const SizedBox(width: 4),
                                AutoSizeText(
                                  displayStatus,
                                  maxLines: 1,
                                  minFontSize: 8,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (isRemoteAttendance) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AutoSizeText(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          AutoSizeText(
                            timeStr,
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          if (todoTypeLabel.isNotEmpty) ...[
                            AutoSizeText(
                              todoTypeLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: HRColors.brandPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          AutoSizeText(
                            fullDateTimeStr,
                            maxLines: 1,
                            minFontSize: 10,
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 12,
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
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: cardWidget,
    );
  }
}
