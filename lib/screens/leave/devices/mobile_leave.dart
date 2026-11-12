import 'package:auto_size_text/auto_size_text.dart';
import 'package:cn_pocket_hr/services/leave_service.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localstorage/localstorage.dart';
import 'package:cn_pocket_hr/constants/slideanimation.dart';
import 'package:cn_pocket_hr/screens/leave/devices/card1.dart';
import 'package:cn_pocket_hr/screens/notifications/notifications.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/helpers/design_config.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';
import 'package:cn_pocket_hr/models/hr/leave_model.dart';
import 'package:cn_pocket_hr/models/hr/me_model.dart';

import 'package:cn_pocket_hr/screens/leave/devices/mobile_leave_request_page.dart';

class MobileLeave extends StatefulWidget {
  const MobileLeave({Key? key}) : super(key: key);

  @override
  MobileLeaveState createState() => MobileLeaveState();
}

class MobileLeaveState extends State<MobileLeave>
    with TickerProviderStateMixin {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AnimationController? _animationController;
  late final TabController _tab;
  Future<List<MyLeavesModel>>? myLeaves;
  Future<List<MeSubsModel>>? otherLeaves;
  final LocalStorage storage = LocalStorage('pocketHR');
  List list = [];
  // Timer? _timer; // unused
  bool isLoading = false;
  APIService apiService = APIService();
  int _leaveListCount = 0;
  int _meListCount = 0;
  bool isOthers = false;
  bool leaveManageForm = false;
  bool leaveApprove = true;
  int _activeMainTab = 0;

  Map<String, dynamic>? _leaveBalances;

  // History filter tabs
  String _historyFilter = 'all'; // all|annual|casual|sick|unpaid

  // Bottom-sheet wizard
  // int _applyStep = 0; // 0=type, 1=mode+dates, 2=desc+confirm

  static const Color _pageBg = Color.fromARGB(255, 248, 250, 252);

  // Colors matching the mockup theme
  static Color get _maroon => HRColors.brandPrimary;
  static Color get _greyBrown => HRColors.brandGreyText;
  static Color get _gold => HRColors.brandAccent;
  static Color get _borderColor => HRColors.brandBorder;

  Widget _leaveBalanceSummary() {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    dynamic find(Map? m, String k) {
      if (m == null) return null;
      if (m.containsKey(k)) return m[k];
      final lowerK = k.toLowerCase();
      for (var entry in m.entries) {
        final sk = entry.key.toString().toLowerCase();
        if (sk == lowerK || sk == '${lowerK}_leave' || sk == 'leave_$lowerK') return entry.value;
      }
      return null;
    }

    int getQuota(String type) {
      if (_leaveBalances == null) {
        return toInt(storage.getItem('${type}Quota') ?? storage.getItem('${type}_quota'));
      }
      final quotaMap = (_leaveBalances!['quota'] ?? _leaveBalances!['leave_quota']) as Map?;
      var quota = find(quotaMap, type);
      quota ??= find(_leaveBalances, '${type}_quota') ?? find(_leaveBalances, 'quota_$type');
      quota ??= storage.getItem('${type}Quota') ?? storage.getItem('${type}_quota');
      return toInt(quota);
    }

    int getUsed(String type) {
      if (_leaveBalances == null) {
        final storageBal = storage.getItem('leave${type[0].toUpperCase()}${type.substring(1)}') ?? storage.getItem('leave_$type');
        final quota = getQuota(type);
        if (storageBal != null) {
          return quota - toInt(storageBal);
        }
        return 0;
      }
      final usedMap = (_leaveBalances!['used'] ?? _leaveBalances!['taken'] ?? _leaveBalances!['leave_used'] ?? _leaveBalances!['leave_taken']) as Map?;
      final balanceMap = (_leaveBalances!['balance'] ?? _leaveBalances!['leave_balance'] ?? _leaveBalances!['remaining']) as Map?;

      var used = find(usedMap, type);
      used ??= find(_leaveBalances, '${type}_used') ?? find(_leaveBalances, 'used_$type') ?? find(_leaveBalances, '${type}_taken');

      if (used == null && balanceMap != null) {
        final bal = find(balanceMap, type);
        if (bal != null) {
          final quota = getQuota(type);
          used = quota - toInt(bal);
        }
      }
      return toInt(used);
    }

    double getAvailable(String type) {
      if (_leaveBalances == null) {
        final storageBal = storage.getItem('leave${type[0].toUpperCase()}${type.substring(1)}') ?? storage.getItem('leave_$type');
        if (storageBal != null) return toDouble(storageBal);
        return toDouble(getQuota(type) - getUsed(type));
      }
      final availableMap = (_leaveBalances!['available'] ?? _leaveBalances!['balance'] ?? _leaveBalances!['leave_balance'] ?? _leaveBalances!['remaining']) as Map?;
      var av = find(availableMap, type);
      av ??= find(_leaveBalances, '${type}_available') ?? find(_leaveBalances, '${type}_balance') ?? find(_leaveBalances, 'available_$type') ?? find(_leaveBalances, 'balance_$type');
      av ??= storage.getItem('leave${type[0].toUpperCase()}${type.substring(1)}') ?? storage.getItem('leave_$type');
      return toDouble(av ?? (getQuota(type) - getUsed(type)));
    }

    String formatVal(double v) {
      if (v == v.toInt()) {
        return v.toInt().toString();
      }
      return v.toString();
    }

    final annualQuota = getQuota('annual');
    final annualAvailable = getAvailable('annual');

    final casualQuota = getQuota('casual');
    final casualAvailable = getAvailable('casual');

    final medicalQuota = getQuota('medical');
    final medicalAvailable = getAvailable('medical');

    final totalQuota = _leaveBalances != null && _leaveBalances!.containsKey('totalEntitled')
        ? toInt(_leaveBalances!['totalEntitled'])
        : (annualQuota + casualQuota + medicalQuota);

    final totalAvailable = _leaveBalances != null && _leaveBalances!.containsKey('totalAvailable')
        ? toDouble(_leaveBalances!['totalAvailable'])
        : (annualAvailable + casualAvailable + medicalAvailable);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: HRColors.brandLight,
        borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _balanceColumn(
            label: AppLocalizations.of(context)!.annualLabel.toUpperCase(),
            value: '${formatVal(annualAvailable)}/${formatVal(annualQuota.toDouble())}',
            valueColor: const Color(0xFF2E7D32),
          ),
          _balanceDivider(),
          _balanceColumn(
            label: AppLocalizations.of(context)!.casualLabel.toUpperCase(),
            value: '${formatVal(casualAvailable)}/${formatVal(casualQuota.toDouble())}',
            valueColor: _greyBrown,
          ),
          _balanceDivider(),
          _balanceColumn(
            label: AppLocalizations.of(context)!.medicalLabel.toUpperCase(),
            value: '${formatVal(medicalAvailable)}/${formatVal(medicalQuota.toDouble())}',
            valueColor: _greyBrown,
          ),
          _balanceDivider(),
          _balanceColumn(
            label: AppLocalizations.of(context)!.totalLabel.toUpperCase(),
            value: '${formatVal(totalAvailable)}/${formatVal(totalQuota.toDouble())}',
            valueColor: _gold,
          ),
        ],
      ),
    );
  }

  Widget _balanceDivider() {
    return Container(
      width: 1,
      height: 35,
      color: _borderColor,
    );
  }

  Widget _balanceColumn({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoSizeText(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _maroon,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          AutoSizeText(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        setState(() {
          switch (_tab.index) {
            case 0:
              _historyFilter = 'all';
              break;
            case 1:
              _historyFilter = 'approved';
              break;
            case 2:
              _historyFilter = 'pending';
              break;
            case 3:
              _historyFilter = 'rejected';
              break;
          }
        });
      }
    });

    // Ensure profile (quotas / balances) is loaded, then load leaves
    _initProfileAndLeaves();
    _animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 2000));
  }

  @override
  void dispose() {
    _tab.dispose();
    _animationController!.dispose();
    super.dispose();
  }

  Future<void> _initProfileAndLeaves() async {
    try {
      await apiService.fetchMeProfileWithBearer();
      _loadBalance();
    } catch (_) {}
    // Load leaves after profile fetch (ensures storage values exist)
    getMyLeaves();
  }

  Future<void> _loadBalance() async {
    final data = await apiService.getLeaveBalance();
    debugPrint('[LEAVE BALANCE] data: $data');
    if (mounted && data != null) {
      setState(() {
        _leaveBalances = data;
      });
    }
  }

  getMyLeaves() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      myLeaves = LeaveService.getMyLeaves();
    });

    // Refresh balance too
    _loadBalance();

    try {
      final value = await myLeaves;
      if (!mounted) return;
      setState(() {
        _leaveListCount = (value ?? <MyLeavesModel>[]).length;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _leaveListCount = 0;
        isLoading = false;
      });
    }
  }

  handleTimeout() {
    if (_meListCount > 0) {
      setState(() {
        isOthers = true;
      });
    }
  }

  getOthersLeaves() async {
    setState(() {
      final Future<List<MeSubsModel>> others = apiService.getMeSubs();
      others.then((value) {
        _meListCount = value.length;
      });
      otherLeaves = others;

      Timer(Duration(milliseconds: 1000), handleTimeout);
      if (_meListCount > 0) {
        isOthers = true;
      } else {
        isOthers = false;
      }
    });
  }

  Widget othersLeaves() {
    return FutureBuilder<List<MeSubsModel>>(
        future: otherLeaves,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SlideAnimation(
              position: 4,
              itemCount: _meListCount > 6 ? 6 : _meListCount,
              slideDirection: SlideDirection.fromLeft,
              animationController: _animationController,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 20, bottom: 3, left: 16),
                    alignment: Alignment.bottomLeft,
                    // margin: const EdgeInsets.only(bottom: 8, ),
                    child: AutoSizeText(
                      AppLocalizations.of(context)!.others,
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.red[400],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 3, bottom: 3, left: 16),
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: 70,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        // color: Color(0xff5AD2F1).withOpacity(0.50),
                        borderRadius: BorderRadius.all(
                          Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin:
                        EdgeInsets.only(bottom: 0, top: 15, right: 8, left: 4),
                    height: MediaQuery.of(context).size.height / 2 - 290,
                    child: ListView.builder(
                      physics: ScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _meListCount,
                      itemBuilder: (BuildContext context, int index) {
                        return WrCard1(
                          localimg: snapshot.data![index].avatar,
                          image: snapshot.data![index].avatar,
                          blurUrl: "LlF70ZnNsmbv_Noze.RjkXxaogV@",
                          title: snapshot.data![index].nickName,
                          country: snapshot.data![index].epfNo,
                          price: 240,
                          press: () {},
                        );
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 3, left: 16),
                    alignment: Alignment.topLeft,
                    child: Container(
                      child: ElevatedButton(
                        onPressed: () {
                          apiService.showToast('Already loaded');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10), // <-- Radius
                          ),
                        ),
                        child: AutoSizeText(
                          AppLocalizations.of(context)!.leaveText,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 3, left: 16),
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: 70,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        // color: Color(0xff5AD2F1).withOpacity(0.50),
                        borderRadius: BorderRadius.all(
                          Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            isOthers = false;
            return SizedBox();
          }
        });
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _getTabLabel(String raw) {
    if (raw.toLowerCase() == 'rejected') return 'Reject';
    return _capitalize(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawerScrimColor: Colors.transparent,
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: DesignConfig.drawerContent(_scaffoldKey, context),
      ),
      backgroundColor: _pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: HRColors.flavorIconBackgroundColor ??
                              Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          border:
                              Border.all(color: Colors.black.withOpacity(0.06)),
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
                    AutoSizeText(
                      AppLocalizations.of(context)!.leaveText,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
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
                                color: HRColors.flavorIconBackgroundColor ??
                                    Colors.white,
                                borderRadius: BorderRadius.circular(40),
                                border:
                                    Border.all(color: Colors.black.withOpacity(0.06)),
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
                const SizedBox(height: 6),

                _leaveBalanceSummary(),

                const SizedBox(height: 18),

                 // Main navigation tabs under balance card
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: HRColors.brandLight,
                    borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _activeMainTab = 0;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _activeMainTab == 0 ? _maroon : Colors.transparent,
                              borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius - 3),
                            ),
                            child: AutoSizeText(
                              AppLocalizations.of(context)!.leaveRequest,
                              style: TextStyle(
                                color: _activeMainTab == 0 ? Colors.white : _maroon,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _activeMainTab = 1;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _activeMainTab == 1 ? _maroon : Colors.transparent,
                              borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius - 3),
                            ),
                            child: AutoSizeText(
                              AppLocalizations.of(context)!.leaveHistory,
                              style: TextStyle(
                                color: _activeMainTab == 1 ? Colors.white : _maroon,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                if (_activeMainTab == 1) ...[
                  // tabs
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: HRColors.brandLight,
                      borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
                    ),
                    child: TabBar(
                      controller: _tab,
                      isScrollable: true,
                      dividerColor: Colors.transparent,
                      indicatorColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabAlignment: TabAlignment.start,
                      indicatorPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 2),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 25),
                      indicator: BoxDecoration(
                        color: _maroon,
                        borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: _maroon.withOpacity(0.65),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: [
                        Tab(text: _getTabLabel(AppLocalizations.of(context)!.allLabel)),
                        Tab(text: _getTabLabel(AppLocalizations.of(context)!.approvedLable)),
                        Tab(text: _getTabLabel(AppLocalizations.of(context)!.pendindingLable)),
                        Tab(text: _getTabLabel(AppLocalizations.of(context)!.rejectedLable)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // History list
                  showLeave(),
                ] else ...[
                  MobileLeaveRequestPage(
                    isEdit: false,
                    initial: null,
                    isEmbed: true,
                    onSuccess: () {
                      _loadBalance();
                      getMyLeaves();
                      setState(() {
                        _activeMainTab = 1; // Switch to Leave History tab on success
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: null,
    );
  }

  getIcon(status) {
    if (status == "pending") {
      return Icon(
        Icons.pending_actions,
        color: HRColors.darkOrangeColor,
      );
    } else if (status == "approved") {
      return Icon(
        Icons.check_circle_outline,
        color: Colors.green,
      );
    } else if (status == "rejected") {
      return Icon(
        Icons.dangerous_outlined,
        color: Colors.red,
      );
    }
  }

  Widget showLeave() {
    return Container(
      margin: const EdgeInsets.only(),
      padding: EdgeInsets.only(
        top: 8,
      ),
      child: Column(
        children: [
          _buildList(context, Axis.horizontal),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, Axis direction) {
    return FutureBuilder<List<MyLeavesModel>>(
      future: myLeaves,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.active) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 90),
            child: Center(
                child: CupertinoActivityIndicator(
              color: HRColors.orangeColor,
              radius: 16.0,
            )),
          );
        }

        if (snapshot.hasError) {
          final friendlyMsg = DesignConfig.getFriendlyErrorMessage(context, snapshot.error);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: DesignConfig.buildErrorState(
              context,
              message: friendlyMsg,
              onRetry: getMyLeaves,
            ),
          );
        }

        if (snapshot.hasData) {
          final all = snapshot.data ?? <MyLeavesModel>[];
          List<MyLeavesModel> filtered = all;
          if (_historyFilter != 'all') {
            filtered = all.where((e) {
              final status = e.status.toString().toLowerCase();
              if (_historyFilter == 'approved') return status == 'approved';
              if (_historyFilter == 'pending')
                return status == 'pending' || status == 'requested';
              if (_historyFilter == 'rejected') return status == 'rejected';
              return true;
            }).toList();
          }
          _leaveListCount = filtered.length;

          if (_leaveListCount == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                  child: AutoSizeText(AppLocalizations.of(context)!.noRecords)),
            );
          }

          return SlideAnimation(
            position: 4,
            itemCount: _leaveListCount > 6 ? 6 : _leaveListCount,
            slideDirection: SlideDirection.fromLeft,
            animationController: _animationController,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _leaveListCount,
              itemBuilder: (_, i) => _leaveHistoryCard(filtered[i], direction),
            ),
          );
        }

        // Future completed but returned null (should not happen) => empty state
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
              child: AutoSizeText(AppLocalizations.of(context)!.noRecords)),
        );
      },
    );
  }

  void setLeaveValue(MyLeavesModel value) {
    // kept for approve/reject flow (if used elsewhere)
  }

  Widget _GradientPillButton({
    required String label,
    required VoidCallback onTap,
  }) {
    final iconOnly = label.trim().isEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: iconOnly ? 56 : 52,
        width: iconOnly ? 56 : null,
        padding: iconOnly
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(iconOnly ? 56 : 30),
          color: _maroon,
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: iconOnly
              ? const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AutoSizeText(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _leaveHistoryCard(MyLeavesModel model, Axis direction) {
    return _LeaveHistoryCardWidget(model: model);
  }
}

class _LeaveHistoryCardWidget extends StatefulWidget {
  final MyLeavesModel model;
  const _LeaveHistoryCardWidget({Key? key, required this.model}) : super(key: key);

  @override
  State<_LeaveHistoryCardWidget> createState() => _LeaveHistoryCardWidgetState();
}

class _LeaveHistoryCardWidgetState extends State<_LeaveHistoryCardWidget> {
  bool _isExpanded = false;

  int _calculateDays(String fromDate, String toDate) {
    try {
      final fromParts = fromDate.split('/');
      final toParts = toDate.split('/');
      if (fromParts.length == 3 && toParts.length == 3) {
        final from = DateTime(int.parse(fromParts[2]), int.parse(fromParts[1]), int.parse(fromParts[0]));
        final to = DateTime(int.parse(toParts[2]), int.parse(toParts[1]), int.parse(toParts[0]));
        final diff = to.difference(from).inDays + 1;
        return diff > 0 ? diff : 1;
      }
    } catch (_) {}
    return 1;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _localizedLeaveTypeLabel(BuildContext context, String raw) {
    final s = raw.toLowerCase().trim();
    if (s.contains('annual')) return AppLocalizations.of(context)!.annualLabel;
    if (s.contains('casual')) return AppLocalizations.of(context)!.casualLabel;
    if (s.contains('medical') || s.contains('sick')) {
      return AppLocalizations.of(context)!.medicalLabel;
    }
    if (s.contains('short')) return AppLocalizations.of(context)!.shortLeave;
    if (s.contains('nopay') || s.contains('unpaid')) {
      return AppLocalizations.of(context)!.nopayLabel;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final typeLabel = _localizedLeaveTypeLabel(context, model.leaveType.toString());
    final from = model.fromDate.toString();
    final to = model.toDate.toString();

    final isHalfDay = model.session == 'morning' ||
        model.session == 'evening' ||
        model.session == 'half' ||
        model.leaveType == 'half' ||
        model.type == 'half';

    final days = _calculateDays(from, to);
    final durationLabel = days == 1
        ? '1 ${AppLocalizations.of(context)!.day}'
        : '$days ${AppLocalizations.of(context)!.days}';

    final String tagLabel = days > 1
        ? durationLabel
        : (isHalfDay ? AppLocalizations.of(context)!.halfDay : AppLocalizations.of(context)!.fullDay);
    final Color tagBg = isHalfDay ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9);
    final Color tagFg = isHalfDay ? const Color(0xFFE65100) : const Color(0xFF2E7D32);

    final status = model.status.toString().toLowerCase();
    String statusLabel = AppLocalizations.of(context)!.pendingLabel;
    Color statusBg = const Color(0xFFFFF3E0);
    Color statusFg = const Color(0xFFE65100);
    IconData statusIcon = Icons.hourglass_empty_rounded;

    if (status == 'approved') {
      statusLabel = AppLocalizations.of(context)!.approvedLable;
      statusBg = const Color(0xFFEAF7EE);
      statusFg = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle;
    } else if (status == 'rejected') {
      statusLabel = AppLocalizations.of(context)!.rejectedLable;
      statusBg = const Color(0xFFFFEBEE);
      statusFg = const Color(0xFFC91032);
      statusIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignConfig.defaultBorderRadius),
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Type, Session Badge, Status Badge
                Row(
                  children: [
                    AutoSizeText(
                      _capitalize(typeLabel),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: HRColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tagLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: tagFg,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusFg),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusFg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Row 2: Date, Chevron
                Row(
                  children: [
                    Expanded(
                      child: AutoSizeText(
                        (days > 1 && from.isNotEmpty && to.isNotEmpty)
                            ? '$from - $to'
                            : (from.isNotEmpty ? from : ''),
                        style: TextStyle(
                          color: HRColors.brandGreyText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HRColors.brandLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REASON',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: HRColors.brandGreyText,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model.description.isNotEmpty ? model.description : 'No reason provided',
                          style: TextStyle(
                            fontSize: 14,
                            color: HRColors.brandDarkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
