import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/services/log_service.dart';
import 'package:guinemali/core/models/contact_model.dart';

/// Service de notification locale qui ne dépend pas de Supabase
/// Gère les notifications aux contacts d'urgence via SMS et appels
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  static LocalNotificationService get instance => _instance;

  final StorageService _storage = StorageService.instance;

  /// Notifie tous les contacts d'urgence
  Future<void> notifyEmergencyContacts({
    required String alertId,
    required double latitude,
    required double longitude,
    String? customMessage,
  }) async {
    try {
      LogService.info('Début de la notification des contacts d\'urgence', tag: 'notification');
      
      // Récupérer les contacts d'urgence
      final contacts = await _getEmergencyContacts();
      
      if (contacts.isEmpty) {
        LogService.warning('Aucun contact d\'urgence trouvé', tag: 'notification');
        return;
      }

      // Générer le message d'urgence
      final message = _generateEmergencyMessage(
        latitude: latitude,
        longitude: longitude,
        customMessage: customMessage,
      );

      // Notifier chaque contact
      for (final contact in contacts) {
        await _notifyContact(contact, message, alertId);
      }

      LogService.success('Tous les contacts d\'urgence ont été notifiés', tag: 'notification');
    } catch (e) {
      LogService.error('Erreur lors de la notification des contacts: $e', tag: 'notification');
    }
  }

  /// Récupère les contacts d'urgence depuis le stockage local
  Future<List<ContactModel>> _getEmergencyContacts() async {
    try {
      final contactsData = _storage.getString('emergency_contacts');
      if (contactsData != null && contactsData.isNotEmpty) {
        final List<dynamic> contactsList = jsonDecode(contactsData);
        return contactsList
            .map((json) => ContactModel.fromJson(json as Map<String, dynamic>))
            .where((contact) => contact.actif)
            .toList();
      }
      return [];
    } catch (e) {
      LogService.error('Erreur lors de la récupération des contacts: $e', tag: 'notification');
      return [];
    }
  }

  /// Génère le message d'urgence
  String _generateEmergencyMessage({
    required double latitude,
    required double longitude,
    String? customMessage,
  }) {
    final googleMapsUrl = 'https://www.google.com/maps?q=$latitude,$longitude';
    final timestamp = DateTime.now().toIso8601String();
    
    if (customMessage != null && customMessage.isNotEmpty) {
      return '$customMessage\n\n📍 Position: $googleMapsUrl\n🕐 Heure: $timestamp';
    }
    
    return '🚨 ALERTE D\'URGENCE 🚨\n\nJe suis en danger et j\'ai besoin d\'aide immédiate.\n\n📍 Ma position: $googleMapsUrl\n🕐 Heure: $timestamp\n\nVeuillez me contacter ou appeler les secours.';
  }

  /// Notifie un contact spécifique
  Future<void> _notifyContact(ContactModel contact, String message, String alertId) async {
    try {
      LogService.info('Notification du contact: ${contact.nom}', tag: 'notification');
      
      // Enregistrer la tentative de notification
      await _logNotificationAttempt(contact, alertId);
      
      // Essayer d'appeler le contact
      await _callContact(contact);
      
      // Essayer d'envoyer un SMS
      await _sendSMS(contact, message);
      
    } catch (e) {
      LogService.error('Erreur lors de la notification de ${contact.nom}: $e', tag: 'notification');
    }
  }

  /// Appelle un contact
  Future<void> _callContact(ContactModel contact) async {
    try {
      if (contact.numeroTelephone.isNotEmpty) {
        final Uri telUri = Uri(scheme: 'tel', path: contact.numeroTelephone);
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
        LogService.success('Appel lancé vers ${contact.nom}', tag: 'notification');
      }
    } catch (e) {
      LogService.error('Erreur lors de l\'appel vers ${contact.nom}: $e', tag: 'notification');
    }
  }

  /// Envoie un SMS à un contact
  Future<void> _sendSMS(ContactModel contact, String message) async {
    try {
      if (contact.numeroTelephone.isNotEmpty) {
        final Uri smsUri = Uri(
          scheme: 'sms',
          path: contact.numeroTelephone,
          queryParameters: {'body': message},
        );
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        LogService.success('SMS envoyé à ${contact.nom}', tag: 'notification');
      }
    } catch (e) {
      LogService.error('Erreur lors de l\'envoi du SMS à ${contact.nom}: $e', tag: 'notification');
    }
  }

  /// Enregistre une tentative de notification
  Future<void> _logNotificationAttempt(ContactModel contact, String alertId) async {
    try {
      final notification = {
        'contactId': contact.id,
        'contactName': contact.nom,
        'alertId': alertId,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'attempted',
      };

      final notificationsData = _storage.getString('notification_log') ?? '[]';
      final List<dynamic> notifications = jsonDecode(notificationsData);
      notifications.add(notification);
      
      await _storage.saveString('notification_log', jsonEncode(notifications));
    } catch (e) {
      LogService.error('Erreur lors de l\'enregistrement de la notification: $e', tag: 'notification');
    }
  }

  /// Récupère l'historique des notifications
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final notificationsData = _storage.getString('notification_log');
      if (notificationsData != null && notificationsData.isNotEmpty) {
        final List<dynamic> notifications = jsonDecode(notificationsData);
        return notifications.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      LogService.error('Erreur lors de la récupération de l\'historique des notifications: $e', tag: 'notification');
      return [];
    }
  }

  /// Supprime l'historique des notifications
  Future<void> clearNotificationHistory() async {
    try {
      await _storage.remove('notification_log');
      LogService.success('Historique des notifications supprimé', tag: 'notification');
    } catch (e) {
      LogService.error('Erreur lors de la suppression de l\'historique des notifications: $e', tag: 'notification');
    }
  }

  /// Teste la notification d'un contact
  Future<void> testNotification(ContactModel contact) async {
    try {
      final testMessage = '🧪 TEST - Ceci est un test de notification d\'urgence depuis l\'application Guinemali.';
      await _notifyContact(contact, testMessage, 'test_${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      LogService.error('Erreur lors du test de notification: $e', tag: 'notification');
    }
  }
}
