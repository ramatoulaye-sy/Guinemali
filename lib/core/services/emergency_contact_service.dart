import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';
import 'auth_service.dart';
import 'geolocation_service.dart';
import 'storage_service.dart';
import 'dart:async';

/// Service de gestion des contacts d'urgence (appels et SMS)
class EmergencyContactService {
  static EmergencyContactService? _instance;
  static EmergencyContactService get instance => _instance ??= EmergencyContactService._();
  
  EmergencyContactService._();

  final SupabaseService _supabase = SupabaseService.instance;
  List<Map<String, dynamic>> _callQueue = [];
  int _currentIndex = 0;

  // Etat observables pour l'UI
  final ValueNotifier<bool> isRunning = ValueNotifier(false);
  final ValueNotifier<int> current = ValueNotifier(0);
  final ValueNotifier<int> total = ValueNotifier(0);
  final ValueNotifier<String> statusText = ValueNotifier('');

  // Paramètre: envoi automatique des SMS de secours
  final ValueNotifier<bool> autoSmsEnabled = ValueNotifier(true);

  Future<void> loadSettings() async {
    final saved = StorageService.instance.getBool('emergency_auto_sms', defaultValue: true);
    autoSmsEnabled.value = saved;
  }

  Future<void> setAutoSmsEnabled(bool enabled) async {
    autoSmsEnabled.value = enabled;
    await StorageService.instance.saveBool('emergency_auto_sms', enabled);
  }

  /// Lance une cascade d'appels (jusqu'à 3) avec SMS de secours et pauses.
  /// - callWindow: durée d'attente entre lancement d'appel et envoi du SMS.
  /// - waitBetween: pause entre deux contacts.
  Future<void> callAllContactsWithFallback({
    Duration callWindow = const Duration(seconds: 25),
    Duration waitBetween = const Duration(seconds: 5),
    String? customMessage,
  }) async {
    try {
      await loadSettings();
      _callQueue = await getEmergencyContacts();
      _currentIndex = 0;

      if (_callQueue.isEmpty) {
        // Fallback: numéro d'urgence officiel configuré, sinon 117
        final configured = StorageService.instance.getString('official_emergency_number');
        final fallback = (configured != null && configured.trim().isNotEmpty) ? configured.trim() : '117';
        final uri = Uri.parse('tel:$fallback');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (AppConstants.enableLogging) {
            print('📞 Appel d\'urgence vers $fallback');
          }
        }
        return;
      }

      // Init état UI
      isRunning.value = true;
      total.value = _callQueue.length.clamp(0, AppConstants.maxEmergencyContacts);
      current.value = 0;
      statusText.value = 'Préparation…';

      // Préparer un message SMS (inclure localisation si possible)
      // Priorité: customMessage param -> message paramétré utilisateur -> ancien template fallback
      final customSosMessage = StorageService.instance.getString('custom_sos_message');
      final emergencyTemplate = StorageService.instance.getString('emergency_message_template');
      
      if (AppConstants.enableLogging) {
        print('🔍 Debug SMS:');
        print('  - customMessage param: $customMessage');
        print('  - custom_sos_message: $customSosMessage');
        print('  - emergency_message_template: $emergencyTemplate');
      }
      
      String template = customMessage ??
          (customSosMessage?.isNotEmpty == true ? customSosMessage : null) ??
          (emergencyTemplate?.isNotEmpty == true ? emergencyTemplate : null) ??
          'Alerte SOS – j\'ai besoin d\'aide.\nMa position: {lat},{lon}\n{link}';
      
      if (AppConstants.enableLogging) {
        print('📱 Template SMS final utilisé: $template');
      }
      String message = template;
      try {
        final pos = await GeolocationService.instance.getLastKnownPosition() 
                  ?? await GeolocationService.instance.getCurrentPosition();
        final lat = pos.latitude.toStringAsFixed(6);
        final lon = pos.longitude.toStringAsFixed(6);
        final mapsUrl = 'https://maps.google.com/?q=$lat,$lon';
        // Remplacer placeholders si présents, sinon injecter la position à la fin
        final replaced = template
          .replaceAll('{lat}', lat)
          .replaceAll('{lon}', lon)
          .replaceAll('{link}', mapsUrl);
        if (replaced == template) {
          // pas de placeholders, on ajoute un bloc position lisible
          message = '${template.trim()}\n\nMa position: $lat,$lon\n$mapsUrl';
        } else {
          message = replaced;
        }
      } catch (_) {
        // pas de localisation, garder message simple
      }

      while (_currentIndex < _callQueue.length && _currentIndex < AppConstants.maxEmergencyContacts) {
        final contact = _callQueue[_currentIndex];
        final phone = (contact['numero_telephone'] ?? contact['phone_number'] ?? '').toString();
        if (phone.isEmpty) {
          _currentIndex++;
          continue;
        }

        // 1) Lancer l'appel
        current.value = _currentIndex + 1;
        statusText.value = 'Appel ${current.value}/${total.value}';
        final callUri = Uri.parse('tel:$phone');
        if (await canLaunchUrl(callUri)) {
          await launchUrl(callUri, mode: LaunchMode.externalApplication);
          if (AppConstants.enableLogging) {
            print('📞 Appel lancé vers $phone');
          }
        }

        // 2) Attendre la fenêtre d\'appel
        await Future.delayed(callWindow);

        // 3) Envoyer un SMS de secours (si activé)
        if (autoSmsEnabled.value) {
          statusText.value = 'Préparation SMS ${current.value}/${total.value}…';
          // Note: les plateformes restreignent l'envoi totalement silencieux.
          // On tente d'abord le composeur SMS prérempli. Si non dispo, fallback vers schéma "smsto:".
          final body = Uri.encodeComponent(message);
          final smsUri = Uri.parse('sms:$phone?body=$body');
          final smsToUri = Uri.parse('smsto:$phone?body=$body');
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri, mode: LaunchMode.externalApplication);
            if (AppConstants.enableLogging) {
              print('✉️ SMS de secours préparé pour $phone');
            }
          } else if (await canLaunchUrl(smsToUri)) {
            await launchUrl(smsToUri, mode: LaunchMode.externalApplication);
          }
        }

        // 4) Pause entre contacts
        await Future.delayed(waitBetween);

        _currentIndex++;
      }

      if (AppConstants.enableLogging) {
        print('✅ Séquence d\'appels d\'urgence terminée');
      }
      statusText.value = 'Terminé';
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur séquence d\'appels (cascade): $e');
      }
    }
    finally {
      isRunning.value = false;
    }
  }

  /// Récupère les contacts d'urgence (max 3) classés par priorité
  Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) return [];

      final response = await _supabase.select(
        'contacts_urgence',
        filters: {
          'utilisateur_id': userId,
          'actif': true,
        },
        orderBy: 'priorite',
        ascending: true,
        limit: AppConstants.maxEmergencyContacts,
      );

      final contacts = (response as List?)?.cast<Map<String, dynamic>>() ?? [];
      return contacts.take(AppConstants.maxEmergencyContacts).toList();
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur récupération contacts d\'urgence: $e');
      }
      return [];
    }
  }

  /// Démarre ou continue la séquence d'appels des contacts d'urgence
  Future<void> startOrContinueCallSequence() async {
    try {
      if (_callQueue.isEmpty) {
        _callQueue = await getEmergencyContacts();
        _currentIndex = 0;
      }

      if (_callQueue.isEmpty) {
        // Fallback: appeler le numéro d'urgence par défaut (Police 117)
        final uri = Uri.parse('tel:117');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (AppConstants.enableLogging) {
            print('📞 Appel d\'urgence vers 117');
          }
        }
        return;
      }

      if (_currentIndex >= _callQueue.length) {
        if (AppConstants.enableLogging) {
          print('✅ Séquence d\'appels terminée');
        }
        return;
      }

      final contact = _callQueue[_currentIndex];
      final phone = (contact['numero_telephone'] ?? contact['phone_number'] ?? '').toString();
      if (phone.isEmpty) {
        _currentIndex++;
        return await startOrContinueCallSequence();
      }

      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (AppConstants.enableLogging) {
          print('📞 Appel lancé vers $phone');
        }
      } else {
        if (AppConstants.enableLogging) {
          print('❌ Impossible d\'ouvrir l\'app téléphone pour $phone');
        }
      }

      // Préparer l'appel du prochain contact lors du prochain déclenchement
      _currentIndex++;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur séquence d\'appels: $e');
      }
    }
  }
}


