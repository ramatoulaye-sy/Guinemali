import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Guinemali'**
  String get appTitle;

  /// No description provided for @welcomeScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Guinemali'**
  String get welcomeScreenTitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @homeScreenGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get homeScreenGreeting;

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloUser(Object name);

  /// No description provided for @securityPriority.
  ///
  /// In en, this message translates to:
  /// **'Your safety is our priority'**
  String get securityPriority;

  /// No description provided for @quickActionSoundAlert.
  ///
  /// In en, this message translates to:
  /// **'Sound alert'**
  String get quickActionSoundAlert;

  /// No description provided for @quickActionEmergencyCall.
  ///
  /// In en, this message translates to:
  /// **'Emergency call'**
  String get quickActionEmergencyCall;

  /// No description provided for @quickActionMyContacts.
  ///
  /// In en, this message translates to:
  /// **'My contacts'**
  String get quickActionMyContacts;

  /// No description provided for @quickActionRecordEvidence.
  ///
  /// In en, this message translates to:
  /// **'Record evidence'**
  String get quickActionRecordEvidence;

  /// No description provided for @quickActionShareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share location'**
  String get quickActionShareLocation;

  /// No description provided for @alertLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading alert...'**
  String get alertLoading;

  /// No description provided for @noActiveAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'No active alert'**
  String get noActiveAlertTitle;

  /// No description provided for @noActiveAlertBody.
  ///
  /// In en, this message translates to:
  /// **'No emergency alert is currently active.'**
  String get noActiveAlertBody;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @emergencyActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'🚨 EMERGENCY ALERT ACTIVE'**
  String get emergencyActiveTitle;

  /// No description provided for @emergencyActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help is on the way - Stay calm'**
  String get emergencyActiveSubtitle;

  /// No description provided for @alertStatus.
  ///
  /// In en, this message translates to:
  /// **'Alert status'**
  String get alertStatus;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get statusActive;

  /// No description provided for @triggeredAt.
  ///
  /// In en, this message translates to:
  /// **'Triggered at: {date}'**
  String triggeredAt(Object date);

  /// No description provided for @dangerLevel.
  ///
  /// In en, this message translates to:
  /// **'Danger level: {level}'**
  String dangerLevel(Object level);

  /// No description provided for @yourPosition.
  ///
  /// In en, this message translates to:
  /// **'Your position'**
  String get yourPosition;

  /// No description provided for @emergencyContactsNotified.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts notified'**
  String get emergencyContactsNotified;

  /// No description provided for @callNextContact.
  ///
  /// In en, this message translates to:
  /// **'Call next contact'**
  String get callNextContact;

  /// No description provided for @cancelAlert.
  ///
  /// In en, this message translates to:
  /// **'Cancel alert'**
  String get cancelAlert;

  /// No description provided for @cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling...'**
  String get cancelling;

  /// No description provided for @helpMessage.
  ///
  /// In en, this message translates to:
  /// **'Stay calm and safe. Help is coming. Your emergency contacts have been notified.'**
  String get helpMessage;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsSection;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsPushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications'**
  String get settingsPushNotificationsSubtitle;

  /// No description provided for @settingsSMSNotifications.
  ///
  /// In en, this message translates to:
  /// **'SMS notifications'**
  String get settingsSMSNotifications;

  /// No description provided for @settingsSMSNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive SMS notifications'**
  String get settingsSMSNotificationsSubtitle;

  /// No description provided for @settingsEmailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email notifications'**
  String get settingsEmailNotifications;

  /// No description provided for @settingsEmailNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive email notifications'**
  String get settingsEmailNotificationsSubtitle;

  /// No description provided for @settingsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsSound;

  /// No description provided for @settingsSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable notification sounds'**
  String get settingsSoundSubtitle;

  /// No description provided for @settingsVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingsVibration;

  /// No description provided for @settingsVibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable vibrations'**
  String get settingsVibrationSubtitle;

  /// No description provided for @settingsPrivacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacySection;

  /// No description provided for @settingsLocationSharing.
  ///
  /// In en, this message translates to:
  /// **'Location sharing'**
  String get settingsLocationSharing;

  /// No description provided for @settingsLocationSharingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow location sharing'**
  String get settingsLocationSharingSubtitle;

  /// No description provided for @settingsAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto sync'**
  String get settingsAutoSync;

  /// No description provided for @settingsAutoSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically sync data'**
  String get settingsAutoSyncSubtitle;

  /// No description provided for @settingsPreferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferencesSection;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsDarkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable dark theme'**
  String get settingsDarkModeSubtitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsTextSize;

  /// No description provided for @settingsTextSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust text size'**
  String get settingsTextSizeSubtitle;

  /// No description provided for @settingsAboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutSection;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsAppVersion;

  /// No description provided for @settingsTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get settingsTermsOfUse;

  /// No description provided for @settingsTermsOfUseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read terms of use'**
  String get settingsTermsOfUseSubtitle;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read privacy policy'**
  String get settingsPrivacyPolicySubtitle;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// No description provided for @settingsSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get settingsSupportSubtitle;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
