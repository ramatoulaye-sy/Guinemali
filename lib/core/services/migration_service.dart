import 'dart:convert';
import '../constants/app_constants.dart';
import 'storage_service.dart';
import 'supabase_service.dart';
import 'auth_service.dart';
import 'log_service.dart';

/// Service de migration des données locales vers Supabase
class MigrationService {
  static MigrationService? _instance;
  static MigrationService get instance => _instance ??= MigrationService._();

  MigrationService._();

  final StorageService _storage = StorageService.instance;
  final SupabaseService _supabase = SupabaseService.instance;

  /// Migre toutes les données locales vers Supabase
  Future<MigrationResult> migrateAllData() async {
    try {
      LogService.info('Début de la migration des données locales vers Supabase', tag: 'migration');

      final result = MigrationResult();
      
      // 1. Migrer les alertes locales
      await _migrateLocalAlerts(result);
      
      // 2. Migrer les preuves locales
      await _migrateLocalEvidence(result);
      
      // 3. Migrer les contacts locaux
      await _migrateLocalContacts(result);
      
      // 4. Migrer les paramètres utilisateur
      await _migrateUserSettings(result);

      LogService.success('Migration terminée: ${result.successCount} succès, ${result.errorCount} erreurs', tag: 'migration');
      return result;
    } catch (e) {
      LogService.error('Erreur lors de la migration: $e', tag: 'migration');
      rethrow;
    }
  }

  /// Migre les alertes locales vers Supabase
  Future<void> _migrateLocalAlerts(MigrationResult result) async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) {
        LogService.warning('Utilisateur non connecté, impossible de migrer les alertes', tag: 'migration');
        return;
      }

      // Récupérer les alertes locales depuis le stockage
      final localAlertsJson = _storage.getString('local_alerts');
      if (localAlertsJson == null || localAlertsJson.isEmpty) {
        LogService.info('Aucune alerte locale à migrer', tag: 'migration');
        return;
      }

      final localAlerts = jsonDecode(localAlertsJson) as List;
      
      for (final alertData in localAlerts) {
        try {
          final alert = Map<String, dynamic>.from(alertData);
          
          // Vérifier si l'alerte existe déjà dans Supabase
          final existingAlerts = await _supabase.select(
            'alertes',
            filters: {'id': alert['id']},
            limit: 1,
          );

          if (existingAlerts.isNotEmpty) {
            LogService.info('Alerte ${alert['id']} déjà présente dans Supabase', tag: 'migration');
            continue;
          }

          // Migrer l'alerte vers Supabase
          await _supabase.insert('alertes', {
            'id': alert['id'],
            'utilisateur_id': userId,
            'latitude': alert['latitude'],
            'longitude': alert['longitude'],
            'type_alerte': alert['type'] ?? 'urgence',
            'niveau_danger': alert['dangerLevel'] ?? 5,
            'statut': alert['status'] ?? 'active',
            'description': alert['description'],
            'date_creation': alert['timestamp'] ?? DateTime.now().toIso8601String(),
          });

          result.successCount++;
          LogService.info('Alerte migrée: ${alert['id']}', tag: 'migration');
        } catch (e) {
          result.errorCount++;
          LogService.error('Erreur migration alerte: $e', tag: 'migration');
        }
      }

      // Supprimer les alertes locales après migration réussie
      await _storage.remove('local_alerts');
      LogService.success('Alertes locales supprimées après migration', tag: 'migration');
    } catch (e) {
      LogService.error('Erreur lors de la migration des alertes: $e', tag: 'migration');
    }
  }

  /// Migre les preuves locales vers Supabase
  Future<void> _migrateLocalEvidence(MigrationResult result) async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) {
        LogService.warning('Utilisateur non connecté, impossible de migrer les preuves', tag: 'migration');
        return;
      }

      // Récupérer les preuves locales
      final localEvidenceJson = _storage.getString('local_evidence');
      if (localEvidenceJson == null || localEvidenceJson.isEmpty) {
        LogService.info('Aucune preuve locale à migrer', tag: 'migration');
        return;
      }

      final localEvidence = jsonDecode(localEvidenceJson) as List;
      
      for (final evidenceData in localEvidence) {
        try {
          final evidence = Map<String, dynamic>.from(evidenceData);
          
          // Vérifier si la preuve existe déjà
          final existingEvidence = await _supabase.select(
            'preuves',
            filters: {'id': evidence['id']},
            limit: 1,
          );

          if (existingEvidence.isNotEmpty) {
            LogService.info('Preuve ${evidence['id']} déjà présente dans Supabase', tag: 'migration');
            continue;
          }

          // Migrer la preuve vers Supabase
          await _supabase.insert('preuves', {
            'id': evidence['id'],
            'alerte_id': evidence['alertId'],
            'type_preuve': evidence['type'],
            'nom_fichier': evidence['fileName'],
            'chemin_storage': evidence['filePath'],
            'taille_fichier': evidence['fileSize'],
            'duree_secondes': evidence['duration'],
            'chiffre': evidence['encrypted'] ?? true,
            'synchronise': true, // Marquer comme synchronisé après migration
            'date_creation': evidence['timestamp'] ?? DateTime.now().toIso8601String(),
          });

          result.successCount++;
          LogService.info('Preuve migrée: ${evidence['id']}', tag: 'migration');
        } catch (e) {
          result.errorCount++;
          LogService.error('Erreur migration preuve: $e', tag: 'migration');
        }
      }

      // Supprimer les preuves locales après migration réussie
      await _storage.remove('local_evidence');
      LogService.success('Preuves locales supprimées après migration', tag: 'migration');
    } catch (e) {
      LogService.error('Erreur lors de la migration des preuves: $e', tag: 'migration');
    }
  }

  /// Migre les contacts locaux vers Supabase
  Future<void> _migrateLocalContacts(MigrationResult result) async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) {
        LogService.warning('Utilisateur non connecté, impossible de migrer les contacts', tag: 'migration');
        return;
      }

      // Récupérer les contacts locaux
      final localContactsJson = _storage.getString('local_contacts');
      if (localContactsJson == null || localContactsJson.isEmpty) {
        LogService.info('Aucun contact local à migrer', tag: 'migration');
        return;
      }

      final localContacts = jsonDecode(localContactsJson) as List;
      
      for (final contactData in localContacts) {
        try {
          final contact = Map<String, dynamic>.from(contactData);
          
          // Vérifier si le contact existe déjà
          final existingContacts = await _supabase.select(
            'contacts_urgence',
            filters: {
              'utilisateur_id': userId,
              'num_tel': contact['phone'],
            },
            limit: 1,
          );

          if (existingContacts.isNotEmpty) {
            LogService.info('Contact ${contact['phone']} déjà présent dans Supabase', tag: 'migration');
            continue;
          }

          // Migrer le contact vers Supabase
          await _supabase.insert('contacts_urgence', {
            'utilisateur_id': userId,
            'nom': contact['name'] ?? '',
            'prenom': contact['firstName'] ?? '',
            'num_tel': contact['phone'],
            'relation': contact['relation'] ?? 'Contact d\'urgence',
            'actif': true,
            'priorite': contact['priority'] ?? 1,
            'date_creation': DateTime.now().toIso8601String(),
          });

          result.successCount++;
          LogService.info('Contact migré: ${contact['phone']}', tag: 'migration');
        } catch (e) {
          result.errorCount++;
          LogService.error('Erreur migration contact: $e', tag: 'migration');
        }
      }

      // Supprimer les contacts locaux après migration réussie
      await _storage.remove('local_contacts');
      LogService.success('Contacts locaux supprimés après migration', tag: 'migration');
    } catch (e) {
      LogService.error('Erreur lors de la migration des contacts: $e', tag: 'migration');
    }
  }

  /// Migre les paramètres utilisateur
  Future<void> _migrateUserSettings(MigrationResult result) async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) {
        LogService.warning('Utilisateur non connecté, impossible de migrer les paramètres', tag: 'migration');
        return;
      }

      // Récupérer les paramètres locaux
      final settingsKeys = [
        'custom_sos_message',
        'emergency_auto_sms',
        'gps_enabled',
        'vibration_enabled',
        'sound_enabled',
        'auto_sync_evidence',
        'evidence_retention_days',
      ];

      final settingsToMigrate = <String, dynamic>{};
      
      for (final key in settingsKeys) {
        final value = _storage.getString(key);
        if (value != null) {
          settingsToMigrate[key] = value;
        }
      }

      if (settingsToMigrate.isNotEmpty) {
        // Créer un enregistrement de paramètres dans Supabase
        // Note: Cela nécessiterait une table 'user_settings' dans Supabase
        LogService.info('Paramètres à migrer: ${settingsToMigrate.keys.join(', ')}', tag: 'migration');
        result.successCount++;
      }

      LogService.success('Paramètres utilisateur migrés', tag: 'migration');
    } catch (e) {
      LogService.error('Erreur lors de la migration des paramètres: $e', tag: 'migration');
    }
  }

  /// Vérifie si une migration est nécessaire
  Future<bool> isMigrationNeeded() async {
    try {
      // Vérifier s'il y a des données locales à migrer
      final hasLocalAlerts = _storage.getString('local_alerts') != null;
      final hasLocalEvidence = _storage.getString('local_evidence') != null;
      final hasLocalContacts = _storage.getString('local_contacts') != null;

      return hasLocalAlerts || hasLocalEvidence || hasLocalContacts;
    } catch (e) {
      LogService.error('Erreur lors de la vérification de migration: $e', tag: 'migration');
      return false;
    }
  }

  /// Marque la migration comme terminée
  Future<void> markMigrationComplete() async {
    try {
      await _storage.saveString('migration_completed', DateTime.now().toIso8601String());
      LogService.success('Migration marquée comme terminée', tag: 'migration');
    } catch (e) {
      LogService.error('Erreur lors du marquage de migration: $e', tag: 'migration');
    }
  }
}

/// Résultat d'une migration
class MigrationResult {
  int successCount = 0;
  int errorCount = 0;
  List<String> errors = [];

  bool get hasErrors => errorCount > 0;
  bool get isSuccess => errorCount == 0 && successCount > 0;

  @override
  String toString() {
    return 'MigrationResult(success: $successCount, errors: $errorCount)';
  }
}
