import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:cn_pocket_hr/models/hr/leave_model.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';

class MobileLeaveDetailsPage extends StatelessWidget {
  final MyLeavesModel model;

  const MobileLeaveDetailsPage({super.key, required this.model});

  // Use app theme accent
  static const Color _accent = HRColors.blueColor;

  String _fmtDate(String s) {
    final raw = s.toString();
    if (raw.isEmpty) return '';
    // if already dd/MM/yyyy keep
    if (raw.contains('/')) return raw;
    // try parse yyyy-MM-dd
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return DateFormat('dd/MM/yyyy').format(d);
  }

  Widget _tile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: HRColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HRColors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: HRColors.black.withOpacity(0.55))),
          const SizedBox(height: 6),
          AutoSizeText(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: HRColors.black)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = model.leaveTitle.toString();
    final type = model.leaveType.toString();
    final status = model.status.toString();
    final from = _fmtDate(model.fromDate.toString());
    final to = _fmtDate(model.toDate.toString());
    final desc = model.description.toString();

    final isHalfDay = model.session == 'morning' ||
        model.session == 'evening' ||
        model.session == 'half' ||
        model.leaveType == 'half' ||
        model.type == 'half';
    final sessionLabel = isHalfDay
        ? (model.session == 'morning'
            ? AppLocalizations.of(context)!.halfDayMorning
            : (model.session == 'evening' ? AppLocalizations.of(context)!.halfDayEvening : AppLocalizations.of(context)!.halfDayLabel))
        : '';
    final fullTypeLabel = '$type$sessionLabel';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 244, 246),
      appBar: AppBar(
        backgroundColor: HRColors.white,
        surfaceTintColor: HRColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: HRColors.black),
        title: AutoSizeText(AppLocalizations.of(context)!.leaveDetailsLabel, style: const TextStyle(fontWeight: FontWeight.w900, color: HRColors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: HRColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HRColors.black.withOpacity(0.06)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Slidable(
                  key: const ValueKey('leave_header'),
                  startActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          // TODO: Handle Approve action
                        },
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        icon: Icons.check_circle,
                        label: AppLocalizations.of(context)!.approveAction,
                      ),
                    ],
                  ),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          // TODO: Handle Reject action
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.cancel,
                        label: AppLocalizations.of(context)!.rejectAction,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: _accent.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.event_note, color: _accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(title.isEmpty ? 'Leave Request' : title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: HRColors.black)),
                              const SizedBox(height: 4),
                              AutoSizeText('$from  -  $to', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HRColors.black.withOpacity(0.55))),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.swipe_left_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            _tile(AppLocalizations.of(context)!.leaveTypeLabel, fullTypeLabel),
            _tile(AppLocalizations.of(context)!.statusLabel, status),
            _tile(AppLocalizations.of(context)!.fromLabel, from),
            _tile(AppLocalizations.of(context)!.toLabel, to),
            _tile(AppLocalizations.of(context)!.descriptionLabel, desc),
          ],
        ),
      ),
    );
  }
}
