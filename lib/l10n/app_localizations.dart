import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta')
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language;

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @apNameText.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get apNameText;

  /// No description provided for @introductionOneText.
  ///
  /// In en, this message translates to:
  /// **'Organize anything with anyone anywhere.'**
  String get introductionOneText;

  /// No description provided for @introductionTwoText.
  ///
  /// In en, this message translates to:
  /// **'Enhanced in-app communication.'**
  String get introductionTwoText;

  /// No description provided for @introductionThreeText.
  ///
  /// In en, this message translates to:
  /// **'Stay in the know - even on the go.'**
  String get introductionThreeText;

  /// No description provided for @nextText.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextText;

  /// No description provided for @skipText.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipText;

  /// No description provided for @signUpText.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpText;

  /// No description provided for @loginText.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginText;

  /// No description provided for @alreadyHaveAnAccountText.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAnAccountText;

  /// No description provided for @welcomeText.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeText;

  /// No description provided for @userNameText.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get userNameText;

  /// No description provided for @passwordText.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordText;

  /// No description provided for @tenantHint.
  ///
  /// In en, this message translates to:
  /// **'Tenant/Company'**
  String get tenantHint;

  /// No description provided for @rememberMeText.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMeText;

  /// No description provided for @doNotHaveAccountText.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have account?'**
  String get doNotHaveAccountText;

  /// No description provided for @emailText.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailText;

  /// No description provided for @countryText.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryText;

  /// No description provided for @birthdayText.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthdayText;

  /// No description provided for @iAgreeToAllTermsText.
  ///
  /// In en, this message translates to:
  /// **'I agree to all terms'**
  String get iAgreeToAllTermsText;

  /// No description provided for @fullNameText.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameText;

  /// No description provided for @emailAddressText.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressText;

  /// No description provided for @emailOrUsernameText.
  ///
  /// In en, this message translates to:
  /// **'Email / UserName'**
  String get emailOrUsernameText;

  /// No description provided for @iAgreeToReceiveNewslettersText.
  ///
  /// In en, this message translates to:
  /// **'I agree to receive newsletters'**
  String get iAgreeToReceiveNewslettersText;

  /// No description provided for @subscribeText.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribeText;

  /// No description provided for @categoryText.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryText;

  /// No description provided for @punchText.
  ///
  /// In en, this message translates to:
  /// **'Clocking'**
  String get punchText;

  /// No description provided for @searchText.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchText;

  /// No description provided for @profileText.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileText;

  /// No description provided for @readMoreText.
  ///
  /// In en, this message translates to:
  /// **'Read More...'**
  String get readMoreText;

  /// No description provided for @readLessText.
  ///
  /// In en, this message translates to:
  /// **'Read Less'**
  String get readLessText;

  /// No description provided for @searchForText.
  ///
  /// In en, this message translates to:
  /// **'Search for...'**
  String get searchForText;

  /// No description provided for @settingsText.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsText;

  /// No description provided for @logoutText.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutText;

  /// No description provided for @termsText.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsText;

  /// No description provided for @menuText.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuText;

  /// No description provided for @myAccountText.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get myAccountText;

  /// No description provided for @notificationText.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationText;

  /// No description provided for @languageText.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageText;

  /// No description provided for @faqText.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqText;

  /// No description provided for @privacyPolicyText.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyText;

  /// No description provided for @termsConditionsText.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditionsText;

  /// No description provided for @contactUsText.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUsText;

  /// No description provided for @noNotificationFoundText.
  ///
  /// In en, this message translates to:
  /// **'No notification found'**
  String get noNotificationFoundText;

  /// No description provided for @notificationSubTitleText.
  ///
  /// In en, this message translates to:
  /// **'We did not found any notification'**
  String get notificationSubTitleText;

  /// No description provided for @notificationSubTitle2Text.
  ///
  /// In en, this message translates to:
  /// **'Lets start exploring'**
  String get notificationSubTitle2Text;

  /// No description provided for @newText.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newText;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @pinCode.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get pinCode;

  /// No description provided for @forgetPw.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password ?'**
  String get forgetPw;

  /// No description provided for @click.
  ///
  /// In en, this message translates to:
  /// **'Click'**
  String get click;

  /// No description provided for @epfnumber.
  ///
  /// In en, this message translates to:
  /// **'EPF Number'**
  String get epfnumber;

  /// No description provided for @viewMore.
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-Out'**
  String get checkOut;

  /// No description provided for @leaveText.
  ///
  /// In en, this message translates to:
  /// **'My Leaves'**
  String get leaveText;

  /// No description provided for @attendanceText.
  ///
  /// In en, this message translates to:
  /// **'Attend'**
  String get attendanceText;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @leaveRequest.
  ///
  /// In en, this message translates to:
  /// **'Leave Request'**
  String get leaveRequest;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @rosterText.
  ///
  /// In en, this message translates to:
  /// **'My Roster'**
  String get rosterText;

  /// No description provided for @emailValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter email address'**
  String get emailValidation;

  /// No description provided for @tenantValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter company name'**
  String get tenantValidation;

  /// No description provided for @epfValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter epf number'**
  String get epfValidation;

  /// No description provided for @pinCodeValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter pin code'**
  String get pinCodeValidation;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @leaveApprove.
  ///
  /// In en, this message translates to:
  /// **'Leave Approve'**
  String get leaveApprove;

  /// No description provided for @leaveReject.
  ///
  /// In en, this message translates to:
  /// **'Leave Reject'**
  String get leaveReject;

  /// No description provided for @scannText.
  ///
  /// In en, this message translates to:
  /// **'please keep the QR code in the center of the square.It will be scanned automatically.'**
  String get scannText;

  /// No description provided for @salarySlips.
  ///
  /// In en, this message translates to:
  /// **'Salary Slips'**
  String get salarySlips;

  /// No description provided for @salarySlipHistory.
  ///
  /// In en, this message translates to:
  /// **'Salary Slip History'**
  String get salarySlipHistory;

  /// No description provided for @salarySlipLabel.
  ///
  /// In en, this message translates to:
  /// **'Salary Slip'**
  String get salarySlipLabel;

  /// No description provided for @htmlPreviewNotWired.
  ///
  /// In en, this message translates to:
  /// **'HTML preview is not wired yet.'**
  String get htmlPreviewNotWired;

  /// No description provided for @thisMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonthLabel;

  /// No description provided for @pastMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Past Month'**
  String get pastMonthLabel;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get noRecords;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @nic.
  ///
  /// In en, this message translates to:
  /// **'NIC'**
  String get nic;

  /// No description provided for @ssoLogin.
  ///
  /// In en, this message translates to:
  /// **'SSO Login'**
  String get ssoLogin;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully'**
  String get profilePictureUpdated;

  /// No description provided for @failedToUpdatePicture.
  ///
  /// In en, this message translates to:
  /// **'Failed to update picture'**
  String get failedToUpdatePicture;

  /// No description provided for @confirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @leaveRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'Leave Request'**
  String get leaveRequestLabel;

  /// No description provided for @leaveDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Leave Details'**
  String get leaveDetailsLabel;

  /// No description provided for @confirmLeave.
  ///
  /// In en, this message translates to:
  /// **'Confirm Leave'**
  String get confirmLeave;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toLabel;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get daysLabel;

  /// No description provided for @leaveTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Leave Type'**
  String get leaveTypeLabel;

  /// No description provided for @annualLabel.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annualLabel;

  /// No description provided for @casualLabel.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get casualLabel;

  /// No description provided for @medicalLabel.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get medicalLabel;

  /// No description provided for @leaveMode.
  ///
  /// In en, this message translates to:
  /// **'Leave Mode'**
  String get leaveMode;

  /// No description provided for @fullDay.
  ///
  /// In en, this message translates to:
  /// **'Full Day'**
  String get fullDay;

  /// No description provided for @halfDay.
  ///
  /// In en, this message translates to:
  /// **'Half Day'**
  String get halfDay;

  /// No description provided for @alternative.
  ///
  /// In en, this message translates to:
  /// **'Alternative'**
  String get alternative;

  /// No description provided for @fromToDescription.
  ///
  /// In en, this message translates to:
  /// **'Select start and end dates'**
  String get fromToDescription;

  /// No description provided for @leaveBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Balances'**
  String get leaveBalanceTitle;

  /// No description provided for @attendanceForThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Attendance for this Month'**
  String get attendanceForThisMonth;

  /// No description provided for @presentLabel.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get presentLabel;

  /// No description provided for @absentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Absents'**
  String get absentsLabel;

  /// No description provided for @lateInLabel.
  ///
  /// In en, this message translates to:
  /// **'Late in'**
  String get lateInLabel;

  /// No description provided for @dayOffLabel.
  ///
  /// In en, this message translates to:
  /// **'Day Off'**
  String get dayOffLabel;

  /// No description provided for @shiftLabel.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shiftLabel;

  /// No description provided for @inLabel.
  ///
  /// In en, this message translates to:
  /// **'IN :'**
  String get inLabel;

  /// No description provided for @outLabel.
  ///
  /// In en, this message translates to:
  /// **'OUT :'**
  String get outLabel;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @workedHeader.
  ///
  /// In en, this message translates to:
  /// **'WORKED'**
  String get workedHeader;

  /// No description provided for @lateHeader.
  ///
  /// In en, this message translates to:
  /// **'LATE'**
  String get lateHeader;

  /// No description provided for @overHeader.
  ///
  /// In en, this message translates to:
  /// **'OVER'**
  String get overHeader;

  /// No description provided for @allowanceDeductions.
  ///
  /// In en, this message translates to:
  /// **'Allowances & Deductions'**
  String get allowanceDeductions;

  /// No description provided for @debtLoans.
  ///
  /// In en, this message translates to:
  /// **'Debts & Loans'**
  String get debtLoans;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @myProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfileTitle;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// No description provided for @epfLabel.
  ///
  /// In en, this message translates to:
  /// **'EPF: '**
  String get epfLabel;

  /// No description provided for @notAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get notAdded;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @nicLabel.
  ///
  /// In en, this message translates to:
  /// **'NIC'**
  String get nicLabel;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @fromToLabel.
  ///
  /// In en, this message translates to:
  /// **'From / To'**
  String get fromToLabel;

  /// No description provided for @cannotSelectPastDate.
  ///
  /// In en, this message translates to:
  /// **'Cannot select a past date'**
  String get cannotSelectPastDate;

  /// No description provided for @fromDateCannotBeAfterTo.
  ///
  /// In en, this message translates to:
  /// **'From date cannot be after To date'**
  String get fromDateCannotBeAfterTo;

  /// No description provided for @toDateMustBeAfterFrom.
  ///
  /// In en, this message translates to:
  /// **'To date must be after From date'**
  String get toDateMustBeAfterFrom;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @leaveHistory.
  ///
  /// In en, this message translates to:
  /// **'Leave History'**
  String get leaveHistory;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @allowancesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allowances'**
  String get allowancesLabel;

  /// No description provided for @deductionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get deductionsLabel;

  /// No description provided for @noAllowancesFound.
  ///
  /// In en, this message translates to:
  /// **'No allowances found'**
  String get noAllowancesFound;

  /// No description provided for @noDeductionsFound.
  ///
  /// In en, this message translates to:
  /// **'No deductions found'**
  String get noDeductionsFound;

  /// No description provided for @processedLabel.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get processedLabel;

  /// No description provided for @pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingLabel;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @debtsLabel.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get debtsLabel;

  /// No description provided for @loansLabel.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loansLabel;

  /// No description provided for @noDebtsFound.
  ///
  /// In en, this message translates to:
  /// **'No debts found'**
  String get noDebtsFound;

  /// No description provided for @noLoansFound.
  ///
  /// In en, this message translates to:
  /// **'No loans found'**
  String get noLoansFound;

  /// No description provided for @collectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collectedLabel;

  /// No description provided for @scanSiteCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Scan site QR to enable check-in'**
  String get scanSiteCheckIn;

  /// No description provided for @scanSiteCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Scan site QR to enable check-out'**
  String get scanSiteCheckOut;

  /// No description provided for @qrNoCoordinates.
  ///
  /// In en, this message translates to:
  /// **'QR does not contain coordinates'**
  String get qrNoCoordinates;

  /// No description provided for @invalidQrServerError.
  ///
  /// In en, this message translates to:
  /// **'QR code is not valid or the server is unavailable. Please try again.'**
  String get invalidQrServerError;

  /// No description provided for @qrCoordinatesNotMatch.
  ///
  /// In en, this message translates to:
  /// **'QR and company location differ by {meters} m. Move closer or contact admin.'**
  String qrCoordinatesNotMatch(Object meters);

  /// No description provided for @serverDidNotReturnCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates not found. Please try again.'**
  String get serverDidNotReturnCoordinates;

  /// No description provided for @invalidServerCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Invalid coordinates. Please try again.'**
  String get invalidServerCoordinates;

  /// No description provided for @qrMatchesServerLocation.
  ///
  /// In en, this message translates to:
  /// **'QR matches.distence ({meters} m). Check-in/out enabled'**
  String qrMatchesServerLocation(Object meters);

  /// No description provided for @qrCoordinatesDiffer.
  ///
  /// In en, this message translates to:
  /// **'QR and company location differ by {meters} m. Move closer or contact admin.'**
  String qrCoordinatesDiffer(Object meters);

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @qrValidatedTapToPunch.
  ///
  /// In en, this message translates to:
  /// **'QR validated. Tap Check-In / Check-Out within 20 seconds.'**
  String get qrValidatedTapToPunch;

  /// No description provided for @qrValidClickButton.
  ///
  /// In en, this message translates to:
  /// **'QR valid. Click {button} within 5 seconds.'**
  String qrValidClickButton(String button);

  /// No description provided for @remoteCheckClickButton.
  ///
  /// In en, this message translates to:
  /// **'Remote checking active. Click {button} within 5 seconds.'**
  String remoteCheckClickButton(String button);

  /// No description provided for @qrCannotPunchHere.
  ///
  /// In en, this message translates to:
  /// **'Cannot check in/out in this location.'**
  String qrCannotPunchHere(String username);

  /// No description provided for @qrCoordinatesMismatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Check-in/out is not allowed at this location.'**
  String get qrCoordinatesMismatchMessage;

  /// No description provided for @remoteChecking.
  ///
  /// In en, this message translates to:
  /// **'Remote Clocking'**
  String get remoteChecking;

  /// No description provided for @scanCheckInOut.
  ///
  /// In en, this message translates to:
  /// **'Scan Check-In/Out'**
  String get scanCheckInOut;

  /// No description provided for @checkInSuccess.
  ///
  /// In en, this message translates to:
  /// **'CheckIn is successful'**
  String get checkInSuccess;

  /// No description provided for @checkOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Checkout is successful'**
  String get checkOutSuccess;

  /// No description provided for @cantLocate.
  ///
  /// In en, this message translates to:
  /// **'Cannot locate or User Not Found.'**
  String get cantLocate;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @filedToPerform.
  ///
  /// In en, this message translates to:
  /// **'Failed to perform action.'**
  String get filedToPerform;

  /// No description provided for @activeRemoteCheking.
  ///
  /// In en, this message translates to:
  /// **'Remote checking active.Tap Check-In / Check-Out within 20 seconds.'**
  String get activeRemoteCheking;

  /// No description provided for @approvedLable.
  ///
  /// In en, this message translates to:
  /// **'approved'**
  String get approvedLable;

  /// No description provided for @pendindingLable.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get pendindingLable;

  /// No description provided for @rejectedLable.
  ///
  /// In en, this message translates to:
  /// **'rejected'**
  String get rejectedLable;

  /// No description provided for @loadedLeaveLable.
  ///
  /// In en, this message translates to:
  /// **'Loaded leaves'**
  String get loadedLeaveLable;

  /// No description provided for @leaveSummary.
  ///
  /// In en, this message translates to:
  /// **'Leave Summary'**
  String get leaveSummary;

  /// No description provided for @totalRequests.
  ///
  /// In en, this message translates to:
  /// **'Total Requests'**
  String get totalRequests;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @leaveAppliedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Leave applied successfully'**
  String get leaveAppliedSuccessfully;

  /// No description provided for @invalidDetailsPleaseCheckYourForm.
  ///
  /// In en, this message translates to:
  /// **'Invalid details. Please check your form.'**
  String get invalidDetailsPleaseCheckYourForm;

  /// No description provided for @failedToSubmitLeave.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit leave.'**
  String get failedToSubmitLeave;

  /// No description provided for @generalShift.
  ///
  /// In en, this message translates to:
  /// **'General Shift'**
  String get generalShift;

  /// No description provided for @shortLeave.
  ///
  /// In en, this message translates to:
  /// **'Short Leave'**
  String get shortLeave;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **' Two hours in morning'**
  String get morning;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **' Two hours in the Evening'**
  String get evening;

  /// No description provided for @morningLabel.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morningLabel;

  /// No description provided for @eveningLabel.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get eveningLabel;

  /// No description provided for @workingHrs.
  ///
  /// In en, this message translates to:
  /// **'Total Hrs'**
  String get workingHrs;

  /// No description provided for @refreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Refresh successful'**
  String get refreshSuccess;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @myTeam.
  ///
  /// In en, this message translates to:
  /// **'My Team'**
  String get myTeam;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'This page cant be reached. please contact your company'**
  String get serverError;

  /// No description provided for @rs.
  ///
  /// In en, this message translates to:
  /// **'Rs.'**
  String get rs;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @nopayLabel.
  ///
  /// In en, this message translates to:
  /// **'No Pay'**
  String get nopayLabel;

  /// No description provided for @selectTeamMember.
  ///
  /// In en, this message translates to:
  /// **'Select team member'**
  String get selectTeamMember;

  /// No description provided for @employeeDetails.
  ///
  /// In en, this message translates to:
  /// **'Employee Details'**
  String get employeeDetails;

  /// No description provided for @leaveDetails.
  ///
  /// In en, this message translates to:
  /// **'Leave Details'**
  String get leaveDetails;

  /// No description provided for @leaveDuration.
  ///
  /// In en, this message translates to:
  /// **'Leave Duration'**
  String get leaveDuration;

  /// No description provided for @leaveTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Type'**
  String get leaveTypeTitle;

  /// No description provided for @leaveDates.
  ///
  /// In en, this message translates to:
  /// **'Leave Dates'**
  String get leaveDates;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @allTeamMembers.
  ///
  /// In en, this message translates to:
  /// **'All team members'**
  String get allTeamMembers;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get members;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'member'**
  String get member;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'PRESENT'**
  String get present;

  /// No description provided for @inOnly.
  ///
  /// In en, this message translates to:
  /// **'IN ONLY'**
  String get inOnly;

  /// No description provided for @outOnly.
  ///
  /// In en, this message translates to:
  /// **'OUT ONLY'**
  String get outOnly;

  /// No description provided for @leaveApproved.
  ///
  /// In en, this message translates to:
  /// **'Leave approved successfully'**
  String get leaveApproved;

  /// No description provided for @leaveRejected.
  ///
  /// In en, this message translates to:
  /// **'Leave rejected successfully'**
  String get leaveRejected;

  /// No description provided for @leaveApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve leave'**
  String get leaveApproveFailed;

  /// No description provided for @leaveRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject leave'**
  String get leaveRejectFailed;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(Object error);

  /// No description provided for @teamDataLoadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Team data loaded successfully'**
  String get teamDataLoadedSuccessfully;

  /// No description provided for @failedToLoadTeamData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load team data'**
  String get failedToLoadTeamData;

  /// No description provided for @weAreHere.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help'**
  String get weAreHere;

  /// No description provided for @reachOut.
  ///
  /// In en, this message translates to:
  /// **'Reach out to us through any of the channels below.'**
  String get reachOut;

  /// No description provided for @getInTouch.
  ///
  /// In en, this message translates to:
  /// **'Get in touch'**
  String get getInTouch;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @phoneSupport.
  ///
  /// In en, this message translates to:
  /// **'Phone Support'**
  String get phoneSupport;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @chatWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Chat with us on WhatsApp'**
  String get chatWhatsApp;

  /// No description provided for @office.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get office;

  /// No description provided for @headOffice.
  ///
  /// In en, this message translates to:
  /// **'Head Office'**
  String get headOffice;

  /// No description provided for @officeAddress.
  ///
  /// In en, this message translates to:
  /// **'123 Main Street,\nColombo 03,\nSri Lanka.'**
  String get officeAddress;

  /// No description provided for @businessHours.
  ///
  /// In en, this message translates to:
  /// **'Business Hours'**
  String get businessHours;

  /// No description provided for @weekdays.
  ///
  /// In en, this message translates to:
  /// **'Monday – Friday'**
  String get weekdays;

  /// No description provided for @weekdayHours.
  ///
  /// In en, this message translates to:
  /// **'8:30 AM – 5:30 PM'**
  String get weekdayHours;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @saturdayHours.
  ///
  /// In en, this message translates to:
  /// **'8:30 AM – 1:30 PM'**
  String get saturdayHours;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to login. Please try again.'**
  String get loginFailed;

  /// No description provided for @ssoFailed.
  ///
  /// In en, this message translates to:
  /// **'SSO Login failed. Please try again.'**
  String get ssoFailed;

  /// No description provided for @locationAccuracyTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Accuracy'**
  String get locationAccuracyTitle;

  /// No description provided for @locationAccuracyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s location accuracy is {accuracy}m. Select Continue to scan.'**
  String locationAccuracyMessage(String accuracy);

  /// No description provided for @calibratingDevice.
  ///
  /// In en, this message translates to:
  /// **'Calibrating device...'**
  String get calibratingDevice;

  /// No description provided for @calculatingDistance.
  ///
  /// In en, this message translates to:
  /// **'Calculating distance...'**
  String get calculatingDistance;

  /// No description provided for @findingSatellite.
  ///
  /// In en, this message translates to:
  /// **'Finding satellite...'**
  String get findingSatellite;

  /// No description provided for @currentAccuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Accuracy: {accuracy}m'**
  String currentAccuracyLabel(String accuracy);

  /// No description provided for @todos.
  ///
  /// In en, this message translates to:
  /// **'To-Do List'**
  String get todos;

  /// No description provided for @todoTabMyTodos.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get todoTabMyTodos;

  /// No description provided for @todoTabApprovable.
  ///
  /// In en, this message translates to:
  /// **'Approvable By Me'**
  String get todoTabApprovable;

  /// No description provided for @noTodosFound.
  ///
  /// In en, this message translates to:
  /// **'No to-do tasks found.'**
  String get noTodosFound;

  /// No description provided for @failedToLoadTodos.
  ///
  /// In en, this message translates to:
  /// **'Failed to load to-do data.'**
  String get failedToLoadTodos;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @todoTabRemoteAttendance.
  ///
  /// In en, this message translates to:
  /// **'Remote Attendance'**
  String get todoTabRemoteAttendance;

  /// No description provided for @todoTabProfileUnlock.
  ///
  /// In en, this message translates to:
  /// **'Profile Unlock'**
  String get todoTabProfileUnlock;

  /// No description provided for @todoTabOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get todoTabOthers;

  /// No description provided for @todoDetailCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get todoDetailCategory;

  /// No description provided for @todoDetailZone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get todoDetailZone;

  /// No description provided for @todoDetailPunchType.
  ///
  /// In en, this message translates to:
  /// **'Punch Type'**
  String get todoDetailPunchType;

  /// No description provided for @todoDetailCheckedAt.
  ///
  /// In en, this message translates to:
  /// **'Checked At'**
  String get todoDetailCheckedAt;

  /// No description provided for @todoDetailAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get todoDetailAccuracy;

  /// No description provided for @todoDetailBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get todoDetailBattery;

  /// No description provided for @todoDetailCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get todoDetailCoordinates;

  /// No description provided for @todoDetailReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get todoDetailReason;

  /// No description provided for @todoDetailRatesInfo.
  ///
  /// In en, this message translates to:
  /// **'Rates Info'**
  String get todoDetailRatesInfo;

  /// No description provided for @todoRequestDetails.
  ///
  /// In en, this message translates to:
  /// **'Request Details'**
  String get todoRequestDetails;

  /// No description provided for @todoApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve Request'**
  String get todoApproveTitle;

  /// No description provided for @todoRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get todoRejectTitle;

  /// No description provided for @todoApproveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve {name}\'s request?'**
  String todoApproveConfirmMessage(String name);

  /// No description provided for @todoRejectConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject {name}\'s request?'**
  String todoRejectConfirmMessage(String name);

  /// No description provided for @todoReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection *'**
  String get todoReasonHint;

  /// No description provided for @todoApproveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Todo approved successfully'**
  String get todoApproveSuccess;

  /// No description provided for @todoRejectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Todo rejected successfully'**
  String get todoRejectSuccess;

  /// No description provided for @todoApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve Todo'**
  String get todoApproveFailed;

  /// No description provided for @todoRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject Todo'**
  String get todoRejectFailed;

  /// No description provided for @todoRemoteAttendanceDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote Attendance Details'**
  String get todoRemoteAttendanceDetailsTitle;

  /// No description provided for @todoProfileUnlockDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Unlock Details'**
  String get todoProfileUnlockDetailsTitle;

  /// No description provided for @todoOtherDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Details'**
  String get todoOtherDetailsTitle;

  /// No description provided for @todoDetailDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get todoDetailDeviceId;

  /// No description provided for @todoDetailBypassRemote.
  ///
  /// In en, this message translates to:
  /// **'Bypass Remote Check'**
  String get todoDetailBypassRemote;

  /// No description provided for @yesLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesLabel;

  /// No description provided for @noLabel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noLabel;

  /// No description provided for @todoDetailCompletedBy.
  ///
  /// In en, this message translates to:
  /// **'Completed By'**
  String get todoDetailCompletedBy;

  /// No description provided for @todoDetailCompletedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed At'**
  String get todoDetailCompletedAt;

  /// No description provided for @todoDetailRequestedAt.
  ///
  /// In en, this message translates to:
  /// **'Requested At'**
  String get todoDetailRequestedAt;

  /// No description provided for @todoDetailRequestedFor.
  ///
  /// In en, this message translates to:
  /// **'Requested For'**
  String get todoDetailRequestedFor;

  /// No description provided for @todoDetailRequestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested By'**
  String get todoDetailRequestedBy;

  /// No description provided for @todoDetailSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get todoDetailSummary;

  /// No description provided for @todoDetailPunctualityIncentive.
  ///
  /// In en, this message translates to:
  /// **'Punctuality Incentive'**
  String get todoDetailPunctualityIncentive;

  /// No description provided for @todoDetailAttendanceAllowance.
  ///
  /// In en, this message translates to:
  /// **'Attendance Allowance'**
  String get todoDetailAttendanceAllowance;

  /// No description provided for @todoActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get todoActionsTitle;

  /// No description provided for @todoWaitingForPreviousStage.
  ///
  /// In en, this message translates to:
  /// **'for previous person'**
  String get todoWaitingForPreviousStage;

  /// No description provided for @todoPending.
  ///
  /// In en, this message translates to:
  /// **'for you'**
  String get todoPending;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get goodNight;

  /// No description provided for @notificationDetailEmployeeName.
  ///
  /// In en, this message translates to:
  /// **'Employee Name'**
  String get notificationDetailEmployeeName;

  /// No description provided for @notificationDetailPerformedBy.
  ///
  /// In en, this message translates to:
  /// **'Performed By'**
  String get notificationDetailPerformedBy;

  /// No description provided for @notificationDetailPerformerEmail.
  ///
  /// In en, this message translates to:
  /// **'Performer Email'**
  String get notificationDetailPerformerEmail;

  /// No description provided for @notificationDetailPerformerEpfNo.
  ///
  /// In en, this message translates to:
  /// **'Performer EPF No'**
  String get notificationDetailPerformerEpfNo;

  /// No description provided for @notificationDetailEmployeeEpfNo.
  ///
  /// In en, this message translates to:
  /// **'Employee EPF No'**
  String get notificationDetailEmployeeEpfNo;

  /// No description provided for @notificationDetailIpAddress.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get notificationDetailIpAddress;

  /// No description provided for @notificationDetailTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get notificationDetailTime;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get notificationClearAll;

  /// No description provided for @notificationNoNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationNoNotificationsYet;

  /// No description provided for @notificationAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get notificationAllCaughtUp;

  /// No description provided for @notificationMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get notificationMessageLabel;

  /// No description provided for @notificationDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get notificationDetailsLabel;

  /// No description provided for @notificationCloseButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get notificationCloseButton;

  /// No description provided for @teamLeavesText.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get teamLeavesText;

  /// No description provided for @teamAttendanceText.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get teamAttendanceText;

  /// No description provided for @fcmTokenError.
  ///
  /// In en, this message translates to:
  /// **'Failed to get push notification (FCM) token.'**
  String get fcmTokenError;

  /// No description provided for @shortLeaveBalanceExhausted.
  ///
  /// In en, this message translates to:
  /// **'Short leave balance exhausted. You are entitled to a maximum of {max} short leaves per month. (Used/Pending: {used})'**
  String shortLeaveBalanceExhausted(String max, String used);

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @cannotApplyLeaveOnNonWorkingDay.
  ///
  /// In en, this message translates to:
  /// **'You cannot apply leave on {day} — it is not a working day according to your package terms.'**
  String cannotApplyLeaveOnNonWorkingDay(String day);

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @appUpdateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'App Update Required'**
  String get appUpdateRequiredTitle;

  /// No description provided for @appUpdateRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please update your app to the latest version to continue.'**
  String get appUpdateRequiredMessage;

  /// No description provided for @appUpdateRequiredButton.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get appUpdateRequiredButton;

  /// No description provided for @payrollLockedUntilHeader.
  ///
  /// In en, this message translates to:
  /// **'Payroll Locked until {date}'**
  String payrollLockedUntilHeader(String date);

  /// No description provided for @payrollLockedUntilMessage.
  ///
  /// In en, this message translates to:
  /// **'Payroll is locked up to {lockedEnd}. Leave cannot be applied before {minDate}.'**
  String payrollLockedUntilMessage(String lockedEnd, String minDate);

  /// No description provided for @leaveDateCannotBeBefore.
  ///
  /// In en, this message translates to:
  /// **'Leave date cannot be before {date}.'**
  String leaveDateCannotBeBefore(String date);

  /// No description provided for @leaveDateCannotBeAfter.
  ///
  /// In en, this message translates to:
  /// **'Leave date cannot be after {date}.'**
  String leaveDateCannotBeAfter(String date);

  /// No description provided for @allowedLeaveRange.
  ///
  /// In en, this message translates to:
  /// **'Allowed leave application range: {minDate} to {maxDate}'**
  String allowedLeaveRange(String minDate, String maxDate);

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account Request'**
  String get deleteAccountConfirmationTitle;

  /// No description provided for @deleteAccountConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to request deletion of your account? This action will submit an account deletion request to your company administrator.'**
  String get deleteAccountConfirmationMessage;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get confirmDeleteAccount;

  /// No description provided for @deleteAccountRequestedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deletion request submitted successfully.'**
  String get deleteAccountRequestedSuccess;

  /// No description provided for @incorrectDateTimeError.
  ///
  /// In en, this message translates to:
  /// **'Your device date and time are incorrect. Please correct them in settings and log in again.'**
  String get incorrectDateTimeError;

  /// No description provided for @timeHeader.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get timeHeader;

  /// No description provided for @locationsHeader.
  ///
  /// In en, this message translates to:
  /// **'LOCATIONS'**
  String get locationsHeader;

  /// No description provided for @entryTypeHeader.
  ///
  /// In en, this message translates to:
  /// **'ENTRY TYPE'**
  String get entryTypeHeader;

  /// No description provided for @overtimeHeader.
  ///
  /// In en, this message translates to:
  /// **'OVERTIME'**
  String get overtimeHeader;

  /// No description provided for @reqHoursHeader.
  ///
  /// In en, this message translates to:
  /// **'REQ HOURS'**
  String get reqHoursHeader;

  /// No description provided for @remoteLabel.
  ///
  /// In en, this message translates to:
  /// **'REMOTE'**
  String get remoteLabel;

  /// No description provided for @qrLabel.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get qrLabel;

  /// No description provided for @failedToConnectToServer.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Please check your internet connection and try again..'**
  String get failedToConnectToServer;

  /// No description provided for @myAttendance.
  ///
  /// In en, this message translates to:
  /// **'My Attendance'**
  String get myAttendance;

  /// No description provided for @inLocationHeader.
  ///
  /// In en, this message translates to:
  /// **'IN LOCATION'**
  String get inLocationHeader;

  /// No description provided for @outLocationHeader.
  ///
  /// In en, this message translates to:
  /// **'OUT LOCATION'**
  String get outLocationHeader;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @selectLeaveType.
  ///
  /// In en, this message translates to:
  /// **'Select Leave Type'**
  String get selectLeaveType;

  /// No description provided for @selectLeaveReason.
  ///
  /// In en, this message translates to:
  /// **'Select Leave Reason'**
  String get selectLeaveReason;

  /// No description provided for @dutyLeave.
  ///
  /// In en, this message translates to:
  /// **'Duty Leave'**
  String get dutyLeave;

  /// No description provided for @annualVacation.
  ///
  /// In en, this message translates to:
  /// **'Annual Vacation'**
  String get annualVacation;

  /// No description provided for @examination.
  ///
  /// In en, this message translates to:
  /// **'Examination'**
  String get examination;

  /// No description provided for @familyFunction.
  ///
  /// In en, this message translates to:
  /// **'Family Function'**
  String get familyFunction;

  /// No description provided for @pleaseSelectLeaveType.
  ///
  /// In en, this message translates to:
  /// **'Please select leave type'**
  String get pleaseSelectLeaveType;

  /// No description provided for @pleaseSelectFromDate.
  ///
  /// In en, this message translates to:
  /// **'Please select from date'**
  String get pleaseSelectFromDate;

  /// No description provided for @pleaseSelectToDate.
  ///
  /// In en, this message translates to:
  /// **'Please select to date'**
  String get pleaseSelectToDate;

  /// No description provided for @pleaseSelectLeaveReason.
  ///
  /// In en, this message translates to:
  /// **'Please select leave reason'**
  String get pleaseSelectLeaveReason;

  /// No description provided for @halfDayMorning.
  ///
  /// In en, this message translates to:
  /// **' (0.5 Day - Morning)'**
  String get halfDayMorning;

  /// No description provided for @halfDayEvening.
  ///
  /// In en, this message translates to:
  /// **' (0.5 Day - Evening)'**
  String get halfDayEvening;

  /// No description provided for @halfDayLabel.
  ///
  /// In en, this message translates to:
  /// **' (0.5 Day)'**
  String get halfDayLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @failedToRetrieveCoordinatesCheckInOutEnabled.
  ///
  /// In en, this message translates to:
  /// **'Failed to retrieve site coordinates. Check-in/out locally is enabled.'**
  String get failedToRetrieveCoordinatesCheckInOutEnabled;

  /// No description provided for @savedLocallyWillSyncWhenOnline.
  ///
  /// In en, this message translates to:
  /// **'Saved locally, will sync when online'**
  String get savedLocallyWillSyncWhenOnline;

  /// No description provided for @serverErrorSavedLocallyWillSyncLater.
  ///
  /// In en, this message translates to:
  /// **'Server error. Saved locally, will sync later.'**
  String get serverErrorSavedLocallyWillSyncLater;

  /// No description provided for @syncedCountFailedCount.
  ///
  /// In en, this message translates to:
  /// **'Synced: {success}, Failed: {failed}'**
  String syncedCountFailedCount(Object success, Object failed);

  /// No description provided for @todoDirectManagerApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'You must be the direct manager of this employee to approve this request.'**
  String get todoDirectManagerApprovalRequired;

  /// No description provided for @developerModeDetectedError.
  ///
  /// In en, this message translates to:
  /// **'Developer options / USB debugging detected. Please turn off Developer Options in your device settings to use this app.'**
  String get developerModeDetectedError;

  /// No description provided for @mockLocationDetectedError.
  ///
  /// In en, this message translates to:
  /// **'Mock / Fake location detected. Please disable mock location apps in your device settings to use this app.'**
  String get mockLocationDetectedError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
