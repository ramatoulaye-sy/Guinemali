import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

/// Service de gestion des contacts d'urgence (appels et SMS)
class EmergencyContactService {
  static EmergencyContactService? _instance;
  static EmergencyContactService get instance => _instance ??= EmergencyContactService._();
  
  EmergencyContactService._();

  final SupabaseService _supabase = SupabaseService.instance;
  List<Map<String, dynamic>> _callQueue = [];
  int _currentIndex = 0;

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


