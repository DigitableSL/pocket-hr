import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:octo_image/octo_image.dart';
import 'package:cn_pocket_hr/constants/slideanimation.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/helpers/design_config.dart';
import 'package:cn_pocket_hr/helpers/glass_box.dart';
import 'package:cn_pocket_hr/helpers/glass_box_curve.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/helpers/hr_constant.dart';
import 'package:cn_pocket_hr/helpers/hr_strings.dart';
import 'package:intl/intl.dart';
import 'package:cn_pocket_hr/helpers/custom_blur_hash.dart';
import 'package:cn_pocket_hr/models/hr/me_model.dart';

class MobileLeaveRequest extends StatefulWidget {
  const MobileLeaveRequest({Key? key}) : super(key: key);

  @override
  _MobileLeaveRequestState createState() => _MobileLeaveRequestState();
}

class _MobileLeaveRequestState extends State<MobileLeaveRequest>
    with SingleTickerProviderStateMixin {
  bool descTextShowFlag = false,
      _keyboardVisible = false,
      isSwitchValueTrack = true;
  String dummy = "Full Day Selected";

  List<String> reasonList = [
    "Select Leave Reason",
    "Duty Leave",
    "Annual Vacation",
    "Examination",
    "Family Function"
  ];
  String? reasonListValue = "Select Leave Reason";

  // List<String> leaveList = ["full_day", "half"];
  String? leave_typeValue = "full_day";

  List<String> firstsecondList = ["First", "Second"];
  String? firstsecondValue = "First";

  List<String> leaveTypeList = [
    "Select Leave Type",
    "Annual",
    "Casual",
    "Medical"
  ];
  String? typeValue = "Select Leave Type";
  AnimationController? _animationController;
  String fromText = "From";
  DateTime fDate = DateTime.now();
  String toText = "To";
  DateTime tDate = DateTime.now();
  bool halfDayToggle = false;
  String description = "";
  APIService apiService = APIService();
  bool _leaveTypeValidation = false;
  bool _fromDateValidation = false;
  bool _toDateValidation = false;
  bool _leaveReasonValidation = false;
  bool loader = false;
  bool buttonEnable = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 2000));
  }

  @override
  void dispose() {
    super.dispose();
    _animationController!.dispose();
  }

  Future<void> selectFDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final init = fDate.isBefore(today) ? today : fDate;
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: init,
        firstDate: today,
        lastDate: DateTime(now.year, now.month + 2, now.day));
    if (pickedDate != null && pickedDate != fDate) {
      setState(() {
        fDate = pickedDate;
        fromText = DateFormat("yyyy-MM-dd").format(pickedDate).toString();
        _fromDateValidation = false;
      });
    }
  }

  Future<void> selectTDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final init = tDate.isBefore(today) ? today : tDate;
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: init,
        firstDate: today,
        lastDate: DateTime(now.year, now.month + 2, now.day));
    if (pickedDate != null && pickedDate != tDate) {
      setState(() {
        tDate = pickedDate;
        toText = DateFormat("yyyy-MM-dd").format(pickedDate).toString();
        _toDateValidation = false;
      });
    }
  }

  leaveTypeError() {
    if (_leaveTypeValidation) {
      return AutoSizeText(
        AppLocalizations.of(context)!.pleaseSelectLeaveType,
        style: const TextStyle(
            color: HRColors.red, fontWeight: FontWeight.w500, fontSize: 16),
      );
    }
    return const SizedBox(
      height: 1,
    );
  }

  fromDateError() {
    if (_fromDateValidation) {
      return AutoSizeText(
        AppLocalizations.of(context)!.pleaseSelectFromDate,
        style: const TextStyle(
            color: HRColors.red, fontWeight: FontWeight.w500, fontSize: 16),
      );
    }
    return const SizedBox(
      height: 1,
    );
  }

  toDateError() {
    if (_toDateValidation) {
      return AutoSizeText(
        AppLocalizations.of(context)!.pleaseSelectToDate,
        style: const TextStyle(
            color: HRColors.red, fontWeight: FontWeight.w500, fontSize: 16),
      );
    }
    return const SizedBox(
      height: 1,
    );
  }

  leaveReasonError() {
    if (_leaveReasonValidation) {
      return AutoSizeText(
        AppLocalizations.of(context)!.pleaseSelectLeaveReason,
        style: const TextStyle(
            color: HRColors.red, fontWeight: FontWeight.w500, fontSize: 16),
      );
    }
    return const SizedBox(
      height: 1,
    );
  }

  submit() async {
    if (!buttonEnable) return;

    setState(() {
      loader = true;
      buttonEnable = false;
      typeValue == 'Select Leave Type'
          ? _leaveTypeValidation = true
          : _leaveTypeValidation = false;

      fromText == "From"
          ? _fromDateValidation = true
          : _fromDateValidation = false;

      toText == "To" ? _toDateValidation = true : _toDateValidation = false;

      reasonListValue == 'Select Leave Reason'
          ? _leaveReasonValidation = true
          : _leaveReasonValidation = false;
    });

    try {
      if (!_leaveTypeValidation &&
          !_fromDateValidation &&
          !_toDateValidation &&
          !_leaveReasonValidation) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final fDateOnly = DateTime(fDate.year, fDate.month, fDate.day);
        final tDateOnly = DateTime(tDate.year, tDate.month, tDate.day);

        if (fDateOnly.isBefore(today) || tDateOnly.isBefore(today)) {
          apiService.showToast(AppLocalizations.of(context)!.cannotSelectPastDate);
          return;
        }

        var data = {
          'leave_title': reasonListValue,
          'from_date': DateFormat('d/MM/y').format(fDate).toString(),
          'to_date': DateFormat('d/MM/y').format(tDate).toString(),
          'leave_type': leave_typeValue,
          'session': firstsecondValue,
          'type': typeValue,
          'description': description
        };

        await apiService.leave(data);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          loader = false;
          buttonEnable = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _keyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    double point = 3.5;
    if (_keyboardVisible) {
      point = 12;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: OctoImage(
                    image: CachedNetworkImageProvider(
                        'https://images.pexels.com/photos/1047051/pexels-photo-1047051.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'),
                    placeholderBuilder: OctoBlurHashFix.placeHolder(
                      'LA7{HstRnNyEK-.SkDkWMJXT%zWB',
                    ),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    errorBuilder: OctoError.icon(color: HRColors.bottomColor),
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                    padding: EdgeInsets.all(5.0),
                    margin: EdgeInsets.only(top: 50.0, left: 7.0),
                    child: GlassBox(
                        redius: 40.0,
                        width: 50,
                        height: 50,
                        backgroundColor: HRColors.flavorIconBackgroundColor,
                        child: Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Icon(Icons.arrow_back_ios_sharp,
                                  color: HRColors.flavorIconColor),
                            )))),
              ),
            ),
            leaveForm(point)
          ],
        ),
      ),
    );
  }

  _onTap() {
    submit();
  }

  Widget leaveForm(point) {
    return SlideAnimation(
      position: 4,
      itemCount: 8,
      slideDirection: SlideDirection.fromBottom,
      animationController: _animationController,
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height / 3.4),
        height: MediaQuery.of(context).size.height,
        child: GlassBoxCurve(
          height: MediaQuery.of(context).size.height * .5,
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            reverse: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40.0, bottom: 10),
                  child: AutoSizeText(
                    AppLocalizations.of(context)!.leaveRequestLabel,
                    style: TextStyle(
                        fontSize: 35,
                        color: HRColors.black,
                        fontWeight: FontWeight.normal),
                  ),
                ),
                CupertinoSwitch(
                  activeColor: Colors.green,
                  trackColor: Colors.orangeAccent,
                  value: isSwitchValueTrack,
                  onChanged: (bool val) {
                    isSwitchValueTrack = val;
                    setState(() {
                      if (isSwitchValueTrack) {
                        leave_typeValue = "full_day";
                        dummy = "Full Day Selected";
                      } else {
                        leave_typeValue = "half";
                        dummy = "Half Day Selected";
                      }
                    });
                  },
                ),
                AutoSizeText(
                  leave_typeValue == "full_day"
                      ? '${AppLocalizations.of(context)!.fullDay} Selected'
                      : '${AppLocalizations.of(context)!.halfDay} Selected',
                  style: const TextStyle(fontSize: 18),
                ),
                // showLeaveType(),
                if (halfDayToggle) showFirstSecond(),

                showType(),
                leaveTypeError(),
                showFDate(),
                fromDateError(),
                showTDate(),
                toDateError(),
                showSelectLeaveType(),
                leaveReasonError(),
                showDetail(),
                SizedBox(width: 10.0),

                if (loader)
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        const Color.fromARGB(255, 243, 145, 33)),
                  ),

                GestureDetector(
                  onTap: buttonEnable ? _onTap : null,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2.5,
                      decoration: DesignConfig.boxDecorationButtonColor(
                          HRColors.darkOrangeColor,
                          HRColors.darkOrangeColor,
                          25),
                      alignment: AlignmentDirectional.center,
                      margin: EdgeInsets.only(
                          left: 30.0,
                          top: MediaQuery.of(context).size.height / 40,
                          right: 30.0,
                          bottom: MediaQuery.of(context).size.height / 35),
                      padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AutoSizeText(
                            AppLocalizations.of(context)!.submit,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: HRColors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(width: 5),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom))
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showhidehalfday(newValue) {
    setState(() {
      leave_typeValue = newValue;
    });
    if (leave_typeValue == "Half Day") {
      setState(() {
        halfDayToggle = !halfDayToggle;
      });
    } else {
      setState(() {
        halfDayToggle = false;
      });
    }
  }

  Widget showFirstSecond() {
    return Container(
      margin: EdgeInsets.only(top: 15.0, left: 30.0, right: 30.0),
      decoration: DesignConfig.boxDecorationButtonColor(
          Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.8), 50),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
      child: DropdownButton<String>(
        underline: Container(color: Colors.transparent, height: 2.0),
        dropdownColor: HRColors.white,
        hint: AutoSizeText(
          HRStrings.countryText,
          style: TextStyle(
            color: HRColors.grayColor,
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
        ),
        value: firstsecondValue,
        iconSize: 24,
        elevation: 16,
        iconDisabledColor: HRColors.grayColor,
        iconEnabledColor: HRColors.grayColor,
        isExpanded: true,
        style: TextStyle(
          color: HRColors.grayColor,
          fontSize: 18,
          fontWeight: FontWeight.normal,
        ),
        onChanged: (String? newValue) {
          showhidehalfday(newValue);
        }, //leaveList
        items: firstsecondList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: AutoSizeText(
              value,
              textAlign: TextAlign.right,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget showDetail() {
    return Container(
      margin: EdgeInsets.only(top: 15.0, left: 30.0, right: 30.0),
      decoration: DesignConfig.boxDecorationButtonColor(
          Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.8), 50),
      padding: const EdgeInsets.only(left: 20.0),
      child: TextFormField(
        onChanged: (value) => setState(() {
          description = value;
        }),
        maxLines: null,
        minLines: 2,
        style: TextStyle(color: HRColors.black),
        cursorColor: HRColors.black,
        decoration: InputDecoration(
          hintText:
              '${AppLocalizations.of(context)!.fromToDescription} (${AppLocalizations.of(context)!.optional})',
          hintStyle: Theme.of(context).textTheme.titleSmall!.merge(TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 18,
              color: HRColors.grayColor)),
          border: InputBorder.none,
        ),
        keyboardType: TextInputType.multiline,
      ),
    );
  }

  Widget showSelectLeaveType() {
    return Container(
      margin: EdgeInsets.only(top: 15.0, left: 30.0, right: 30.0),
      decoration: DesignConfig.boxDecorationButtonColor(
          Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.8), 50),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
      child: DropdownButton<String>(
        underline: Container(color: Colors.transparent, height: 2.0),
        dropdownColor: HRColors.white,
        hint: AutoSizeText(HRStrings.countryText,
            style: TextStyle(
              color: HRColors.grayColor,
              fontSize: 18,
              fontWeight: FontWeight.normal,
            )),
        value: reasonListValue,
        iconSize: 24,
        elevation: 16,
        iconDisabledColor: HRColors.grayColor,
        iconEnabledColor: HRColors.grayColor,
        isExpanded: true,
        style: TextStyle(
          color: HRColors.grayColor,
          fontSize: 18,
          fontWeight: FontWeight.normal,
        ),
        onChanged: (String? newValue) {
          setState(() {
            reasonListValue = newValue;
            _leaveReasonValidation = false;
          });
        },
        items: reasonList.map<DropdownMenuItem<String>>((String value) {
          if (value == "Select Leave Reason") {
            return DropdownMenuItem<String>(
              child: AutoSizeText(AppLocalizations.of(context)!.selectLeaveReason,
                  style: const TextStyle(color: Colors.grey)),
              value: value,
              onTap: () => null,
              enabled: false, // disable this item
            );
          }
          String displayValue = value;
          if (value == 'Duty Leave') {
            displayValue = AppLocalizations.of(context)!.dutyLeave;
          } else if (value == 'Annual Vacation') {
            displayValue = AppLocalizations.of(context)!.annualVacation;
          } else if (value == 'Examination') {
            displayValue = AppLocalizations.of(context)!.examination;
          } else if (value == 'Family Function') {
            displayValue = AppLocalizations.of(context)!.familyFunction;
          }
          return DropdownMenuItem<String>(
            value: value,
            child: AutoSizeText(
              displayValue,
              textAlign: TextAlign.right,
            ),
          );
        }).toList(),
      ),
    );
  }

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  Widget showType() {
    return Container(
      margin: EdgeInsets.only(top: 15.0, left: 30.0, right: 30.0),
      decoration: DesignConfig.boxDecorationButtonColor(
          Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.8), 50),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
      child: DropdownButton<String>(
        underline: Container(color: Colors.transparent, height: 2.0),
        dropdownColor: HRColors.white,
        hint: AutoSizeText(HRStrings.countryText,
            style: TextStyle(
              color: HRColors.grayColor,
              fontSize: 18,
              fontWeight: FontWeight.normal,
            )),
        value: typeValue,
        iconSize: 24,
        elevation: 16,
        iconDisabledColor: HRColors.grayColor,
        iconEnabledColor: HRColors.grayColor,
        isExpanded: true,
        style: TextStyle(
          color: HRColors.grayColor,
          fontSize: 18,
          fontWeight: FontWeight.normal,
        ),
        onChanged: (String? newValue) {
          setState(() {
            _leaveTypeValidation = false;
            typeValue = newValue;
          });
        },
        items: leaveTypeList.map<DropdownMenuItem<String>>((String value) {
          if (value == 'Select Leave Type') {
            return DropdownMenuItem<String>(
              child: AutoSizeText(AppLocalizations.of(context)!.selectLeaveType,
                  style: const TextStyle(color: Colors.grey)),
              value: value,
              onTap: () => null,
              enabled: false, // disable this item
            );
          }
          String displayValue = value;
          if (value == 'Annual') {
            displayValue = AppLocalizations.of(context)!.annualLabel;
          } else if (value == 'Casual') {
            displayValue = AppLocalizations.of(context)!.casualLabel;
          } else if (value == 'Medical') {
            displayValue = AppLocalizations.of(context)!.medicalLabel;
          }
          return DropdownMenuItem<String>(
            value: value,
            child: AutoSizeText(
              displayValue,
              textAlign: TextAlign.right,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget showFDate() {
    return GestureDetector(
      onTap: () {
        selectFDate(context);
      },
      child: Container(
        margin: EdgeInsets.only(top: 15.0, left: 30.0, right: 30.0),
        decoration: DesignConfig.boxDecorationButtonColor(
            Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.8), 50),
        padding: const EdgeInsets.only(
            left: 20.0, right: 20.0, top: 12.0, bottom: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoSizeText(fromText == "From" ? AppLocalizations.of(context)!.fromLabel : fromText,
                style: const TextStyle(
                    color: HRColors.grayColor,
                    fontWeight: FontWeight.normal,
                    fontSize: 18)),
            Icon(Icons.arrow_drop_down, color: HRColors.grayColor),
          ],
        ),
      ),
    );
  }

  Widget showTDate() {
    return GestureDetector(
      onTap: () {
        selectTDate(context);
      },
      child: Container(
        margin: EdgeInsets.only(top: 15.0, left: 30.0, right: 30.0),
        decoration: DesignConfig.boxDecorationButtonColor(
            Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.8), 50),
        padding: const EdgeInsets.only(
            left: 20.0, right: 20.0, top: 12.0, bottom: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoSizeText(toText == "To" ? AppLocalizations.of(context)!.toLabel : toText,
                style: const TextStyle(
                    color: HRColors.grayColor,
                    fontWeight: FontWeight.normal,
                    fontSize: 18)),
            Icon(Icons.arrow_drop_down, color: HRColors.grayColor),
          ],
        ),
      ),
    );
  }
}
