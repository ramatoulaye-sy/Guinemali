// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Guinemali';

  @override
  String get welcomeScreenTitle => 'Bienvenue sur Guinemali';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get registerButton => 'S\'inscrire';

  @override
  String get homeScreenGreeting => 'Bonjour';

  @override
  String helloUser(Object name) {
    return 'Bonjour, $name';
  }

  @override
  String get securityPriority => 'Votre sécurité est notre priorité';

  @override
  String get quickActionSoundAlert => 'Alerte sonore';

  @override
  String get quickActionEmergencyCall => 'Appel d\'urgence';

  @override
  String get quickActionMyContacts => 'Mes contacts';

  @override
  String get quickActionRecordEvidence => 'Enregistrer preuve';

  @override
  String get quickActionShareLocation => 'Partager position';

  @override
  String get alertLoading => 'Chargement de l\'alerte...';

  @override
  String get noActiveAlertTitle => 'Aucune alerte active';

  @override
  String get noActiveAlertBody => 'Aucune alerte d\'urgence n\'est actuellement active.';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get emergencyActiveTitle => '🚨 ALERTE D\'URGENCE ACTIVE';

  @override
  String get emergencyActiveSubtitle => 'Aide en route - Restez calme';

  @override
  String get alertStatus => 'Statut de l\'alerte';

  @override
  String get statusActive => 'ACTIVE';

  @override
  String triggeredAt(Object date) {
    return 'Déclenchée à: $date';
  }

  @override
  String dangerLevel(Object level) {
    return 'Niveau de danger: $level';
  }

  @override
  String get yourPosition => 'Votre position';

  @override
  String get emergencyContactsNotified => 'Contacts d\'urgence notifiés';

  @override
  String get callNextContact => 'Appeler le contact suivant';

  @override
  String get cancelAlert => 'Annuler l\'alerte';

  @override
  String get cancelling => 'Annulation...';

  @override
  String get helpMessage => 'Restez calme et en sécurité. L\'aide arrive. Vos contacts d\'urgence ont été notifiés.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsNotificationsSection => 'Notifications';

  @override
  String get settingsPushNotifications => 'Notifications push';

  @override
  String get settingsPushNotificationsSubtitle => 'Recevoir des notifications push';

  @override
  String get settingsSMSNotifications => 'Notifications SMS';

  @override
  String get settingsSMSNotificationsSubtitle => 'Recevoir des notifications par SMS';

  @override
  String get settingsEmailNotifications => 'Notifications email';

  @override
  String get settingsEmailNotificationsSubtitle => 'Recevoir des notifications par email';

  @override
  String get settingsSound => 'Son';

  @override
  String get settingsSoundSubtitle => 'Activer les sons de notification';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsVibrationSubtitle => 'Activer les vibrations';

  @override
  String get settingsPrivacySection => 'Confidentialité';

  @override
  String get settingsLocationSharing => 'Partage de localisation';

  @override
  String get settingsLocationSharingSubtitle => 'Autoriser le partage de position';

  @override
  String get settingsAutoSync => 'Synchronisation automatique';

  @override
  String get settingsAutoSyncSubtitle => 'Synchroniser automatiquement les données';

  @override
  String get settingsPreferencesSection => 'Préférences';

  @override
  String get settingsDarkMode => 'Mode sombre';

  @override
  String get settingsDarkModeSubtitle => 'Activer le thème sombre';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSubtitle => 'Choisir la langue de l\'application';

  @override
  String get settingsTextSize => 'Taille du texte';

  @override
  String get settingsTextSizeSubtitle => 'Ajuster la taille du texte';

  @override
  String get settingsAboutSection => 'À propos';

  @override
  String get settingsAppVersion => 'Version de l\'application';

  @override
  String get settingsTermsOfUse => 'Conditions d\'utilisation';

  @override
  String get settingsTermsOfUseSubtitle => 'Lire les conditions d\'utilisation';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsPrivacyPolicySubtitle => 'Lire la politique de confidentialité';

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsSupportSubtitle => 'Contacter le support';
}
