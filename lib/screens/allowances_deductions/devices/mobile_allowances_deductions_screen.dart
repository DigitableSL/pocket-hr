import 'package:cn_pocket_hr/helpers/design_config.dart';
import 'package:cn_pocket_hr/helpers/format_utils.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/models/hr/variable_model.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:auto_size_text/auto_size_text.dart';

class MobileAllowancesDeductionsScreen extends StatefulWidget {
  const MobileAllowancesDeductionsScreen({Key? key}) : super(key: key);

  @override
  State<MobileAllowancesDeductionsScreen> createState() =>
      _MobileAllowancesDeductionsScreenState();
}

class _MobileAllowancesDeductionsScreenState
    extends State<MobileAllowancesDeductionsScreen>
    with SingleTickerProviderStateMixin {
  final _api = APIService();
  final _storage = LocalStorage('pocketHR');

  late final TabController _tab;
  bool _loading = true;
  String? _error;
  List<VariableItem> _items = [];
  String _query = '';

  // Spacing system (8pt grid + golden-ratio-ish steps)
  static const double _g8 = 8;
  static const double _g12 = 12;
  static const double _g16 = 16;
  static const double _g20 = 20;
  static const double _g24 = 24;

  static const Color _pageBg = Colors.white;
  static const Color _surface = Color.fromARGB(255, 248, 250, 252);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = await ApiClient.getResolvedUserId();
      if (uid == null || uid.isEmpty) throw Exception('Missing user id (uid).');

      final raw = await _api.fetchVariablesForUser(uid);
      final parsed = raw
          .whereType<Map>()
          .map((e) => VariableItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      parsed.sort((a, b) => b.issuedDate.compareTo(a.issuedDate));

      setState(() {
        _items = parsed;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('[VAR][ERROR] $e');
      debugPrint('$st');
      setState(() {
        _error = DesignConfig.getFriendlyErrorMessage(context, e);
        _loading = false;
      });
    }
  }

  Widget _itemCard(VariableItem item) {
    final isAllowance = item.type.toLowerCase() == 'allowance';
    final amountColor = isAllowance ? Colors.green.shade800 : Colors.black87;
    final sign = isAllowance ? '+' : '-';
    final icon =
        isAllowance ? Icons.add_circle_outline : Icons.remove_circle_outline;
    final iconColor = isAllowance ? Colors.green.shade700 : Colors.red.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _g12, vertical: _g8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _surface,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: _g12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AutoSizeText(
                          item.allowance,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: _g12),
                      AutoSizeText(
                        '$sign${FormatUtils.money(item.amount)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _g8),
                  Row(
                    children: [
                      Icon(Icons.calendar_month,
                          size: 14, color: Colors.black54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: AutoSizeText(
                          FormatUtils.dateFromUnixSeconds(item.issuedDate),
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 11),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: (item.processed ? Colors.green : Colors.orange)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: AutoSizeText(
                          item.processed
                              ? AppLocalizations.of(context)!.processedLabel
                              : AppLocalizations.of(context)!.pendindingLable,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.processed
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _items;
    final allowances =
        _items.where((e) => e.type.toLowerCase() == 'allowance').toList();
    final deductions =
        _items.where((e) => e.type.toLowerCase() == 'deduction').toList();

    List<VariableItem> filter(List<VariableItem> list) {
      if (_query.isEmpty) return list;
      final q = _query.toLowerCase();
      return list.where((e) => e.allowance.toLowerCase().contains(q)).toList();
    }

    final filteredAll = filter(allItems);
    final filteredAllowances = filter(allowances);
    final filteredDeductions = filter(deductions);

    Widget tabBody;
    if (_loading) {
      tabBody = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      tabBody = DesignConfig.buildErrorState(
        context,
        message: _error!,
        onRetry: _load,
      );
    } else {
      tabBody = TabBarView(
        controller: _tab,
        children: [
          // All
          RefreshIndicator(
            onRefresh: _load,
            child: filteredAll.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 60),
                      Center(
                          child: AutoSizeText(
                              AppLocalizations.of(context)!.noRecords,
                              style: const TextStyle(color: Colors.black54))),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 30),
                    itemCount: filteredAll.length,
                    itemBuilder: (_, i) => _itemCard(filteredAll[i]),
                  ),
          ),
          RefreshIndicator(
            onRefresh: _load,
            child: filteredAllowances.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 60),
                      Center(
                        child: AutoSizeText(
                            AppLocalizations.of(context)!.noAllowancesFound,
                            style: const TextStyle(color: Colors.black54)),
                      )
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 30),
                    itemCount: filteredAllowances.length,
                    itemBuilder: (_, i) => _itemCard(filteredAllowances[i]),
                  ),
          ),
          RefreshIndicator(
            onRefresh: _load,
            child: filteredDeductions.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 60),
                      Center(
                        child: AutoSizeText(
                            AppLocalizations.of(context)!.noDeductionsFound,
                            style: const TextStyle(color: Colors.black54)),
                      )
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 30),
                    itemCount: filteredDeductions.length,
                    itemBuilder: (_, i) => _itemCard(filteredDeductions[i]),
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            // header
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
                        color:
                            HRColors.flavorIconBackgroundColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        border:
                            Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Icon(Icons.navigate_before,
                          color: HRColors.flavorIconColor),
                    ),
                  ),
                  const SizedBox(width: _g12),
                  Expanded(
                    child: AutoSizeText(
                      AppLocalizations.of(context)!.allowanceDeductions,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: HRColors.brandDarkText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: _g16),

            // tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _g16),
              child: Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: TabBar(
                  controller: _tab,
                  dividerColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(6),
                  indicator: BoxDecoration(
                    color: HRColors.tabColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: HRColors.tabLabelColor,
                  unselectedLabelColor: Colors.black54,
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.allLabel),
                    Tab(text: AppLocalizations.of(context)!.allowancesLabel),
                    Tab(text: AppLocalizations.of(context)!.deductionsLabel),
                  ],
                ),
              ),
            ),

            const SizedBox(height: _g24),
            Expanded(child: tabBody),
          ],
        ),
      ),
    );
  }
}
