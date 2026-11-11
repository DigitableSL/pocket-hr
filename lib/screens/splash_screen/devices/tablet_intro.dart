import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart' show AppLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:octo_image/octo_image.dart';
import 'package:cn_pocket_hr/screens/login/login_screen.dart';
import 'package:cn_pocket_hr/helpers/design_config.dart';
import 'package:cn_pocket_hr/helpers/glass_box_curve.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/helpers/hr_strings.dart';
import 'package:cn_pocket_hr/helpers/custom_blur_hash.dart';
import 'package:cn_pocket_hr/l10n/l10n.dart';
import 'package:cn_pocket_hr/models/introduction_model.dart';


import 'package:cn_pocket_hr/providers/locale_provider.dart';
import 'package:provider/provider.dart';

class TabletIntro extends StatefulWidget {
  const TabletIntro({Key? key}) : super(key: key);

  @override
  _TabletIntroState createState() => _TabletIntroState();
}

class _TabletIntroState extends State<TabletIntro> {
  int currentIndex = 0;
  PageController? _controller;
  String text = "Skip";
  LocalStorage storage = LocalStorage('pocketHR');

  @override
  void initState() {
    _controller = PageController(initialPage: 0);
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    final locale = provider.locale ?? Locale('en');

    setIntroText(index) {
      if (index == 0) {
        return AppLocalizations.of(context)!.introductionOneText;
      }
      if (index == 1) {
        return AppLocalizations.of(context)!.introductionTwoText;
      }
      if (index == 2) {
        return AppLocalizations.of(context)!.introductionThreeText;
      }
    }

    return WillPopScope(
      onWillPop: () {
        return true as Future<bool>;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: introductionList.length,
                      onPageChanged: (int index) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                      itemBuilder: (_, i) {
                        return Padding(
                          padding: const EdgeInsets.all(0),
                          child: Stack(
                            children: [
                              OctoImage(
                                image: CachedNetworkImageProvider(
                                    introductionList[i].imageUrl!),
                                placeholderBuilder: OctoBlurHashFix.placeHolder(
                                  introductionList[i].blurUrl!,
                                ),
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                                errorBuilder:
                                    OctoError.icon(color: HRColors.black),
                                fit: BoxFit.cover,
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height / 1.4),
                child: GlassBoxCurve(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                            alignment: AlignmentDirectional.center,
                            margin: const EdgeInsets.only(
                                left: 20.0, top: 30.0, right: 20.0),
                            child: AutoSizeText(
                              setIntroText(currentIndex).toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: HRColors.black,
                                fontSize: 25,
                                fontWeight: FontWeight.normal,
                              ),
                            )),
                      ),
                      const SizedBox(height: 30),
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(left: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: List.generate(
                                  introductionList.length,
                                  (index) => buildDot(index, context),
                                ),
                              ),
                            ),
                            GestureDetector(
                              child: ElevatedButton(
                                child: AutoSizeText(
                                  'EN',
                                  style: TextStyle(color: Colors.black),
                                ),
                                onPressed: () {
                                  provider.setLocale(Locale('en'));
                                  storage.setItem('lang', 'en');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                            GestureDetector(
                              child: ElevatedButton(
                                child: AutoSizeText(
                                  'සිං',
                                  style: TextStyle(color: Colors.black),
                                ),
                                onPressed: () {
                                  provider.setLocale(Locale('si'));
                                  storage.setItem('lang', 'si');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                            GestureDetector(
                              child: ElevatedButton(
                                child: AutoSizeText(
                                  'தமிழ்',
                                  style: TextStyle(color: Colors.black),
                                ),
                                onPressed: () {
                                  provider.setLocale(Locale('ta'));
                                  storage.setItem('lang', 'ta');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context, HRLogin.routeName);
                                  },
                                  child: AutoSizeText(
                                    currentIndex == introductionList.length - 1
                                        ? HRStrings.continueText
                                        : HRStrings.skipText,
                                    style: const TextStyle(
                                        fontSize: 18, color: HRColors.black),
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container buildDot(int index, BuildContext context) {
    return Container(
        height: 10,
        width: 10,
        margin: const EdgeInsets.only(right: 5),
        decoration: currentIndex == index
            ? DesignConfig.boxDecorationContainer(HRColors.black, 10)
            : DesignConfig.boxDecorationBorderButtonColor(HRColors.black, 10));
  }
}
