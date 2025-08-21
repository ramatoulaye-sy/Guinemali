// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Guinemali';

  @override
  String get welcomeScreenTitle => 'Welcome to Guinemali';

  @override
  String get loginButton => 'Login';

  @override
  String get registerButton => 'Register';

  @override
  String get homeScreenGreeting => 'Hello';

  @override
  String helloUser(Object name) {
    return 'Hello, $name';
  }

  @override
  String get securityPriority => 'Your safety is our priority';

  @override
  String get quickActionSoundAlert => 'Sound alert';

  @override
  String get quickActionEmergencyCall => 'Emergency call';

  @override
  String get quickActionMyContacts => 'My contacts';

  @override
  String get quickActionRecordEvidence => 'Record evidence';

  @override
  String get quickActionShareLocation => 'Share location';

  @override
  String get alertLoading => 'Loading alert...';

  @override
  String get noActiveAlertTitle => 'No active alert';

  @override
  String get noActiveAlertBody => 'No emergency alert is currently active.';

  @override
  String get backToHome => 'Back to home';

  @override
  String get emergencyActiveTitle => '🚨 EMERGENCY ALERT ACTIVE';

  @override
  String get emergencyActiveSubtitle => 'Help is on the way - Stay calm';

  @override
  String get alertStatus => 'Alert status';

  @override
  String get statusActive => 'ACTIVE';

  @override
  String triggeredAt(Object date) {
    return 'Triggered at: $date';
  }

  @override
  String dangerLevel(Object level) {
    return 'Danger level: $level';
  }

  @override
  String get yourPosition => 'Your position';

  @override
  String get emergencyContactsNotified => 'Emergency contacts notified';

  @override
  String get callNextContact => 'Call next contact';

  @override
  String get cancelAlert => 'Cancel alert';

  @override
  String get cancelling => 'Cancelling...';

  @override
  String get helpMessage => 'Stay calm and safe. Help is coming. Your emergency contacts have been notified.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNotificationsSection => 'Notifications';

  @override
  String get settingsPushNotifications => 'Push notifications';

  @override
  String get settingsPushNotificationsSubtitle => 'Receive push notifications';

  @override
  String get settingsSMSNotifications => 'SMS notifications';

  @override
  String get settingsSMSNotificationsSubtitle => 'Receive SMS notifications';

  @override
  String get settingsEmailNotifications => 'Email notifications';

  @override
  String get settingsEmailNotificationsSubtitle => 'Receive email notifications';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsSoundSubtitle => 'Enable notification sounds';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsVibrationSubtitle => 'Enable vibrations';

  @override
  String get settingsPrivacySection => 'Privacy';

  @override
  String get settingsLocationSharing => 'Location sharing';

  @override
  String get settingsLocationSharingSubtitle => 'Allow location sharing';

  @override
  String get settingsAutoSync => 'Auto sync';

  @override
  String get settingsAutoSyncSubtitle => 'Automatically sync data';

  @override
  String get settingsPreferencesSection => 'Preferences';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get settingsDarkModeSubtitle => 'Enable dark theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose app language';

  @override
  String get settingsTextSize => 'Text size';

  @override
  String get settingsTextSizeSubtitle => 'Adjust text size';

  @override
  String get settingsAboutSection => 'About';

  @override
  String get settingsAppVersion => 'App version';

  @override
  String get settingsTermsOfUse => 'Terms of use';

  @override
  String get settingsTermsOfUseSubtitle => 'Read terms of use';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsPrivacyPolicySubtitle => 'Read privacy policy';

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsSupportSubtitle => 'Contact support';
}
