import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

/// Service de gestion du stockage local (SQLite + SharedPreferences)
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  
  StorageService._();

  Database? _database;
  SharedPreferences? _prefs;

  /// Initialise le service de stockage
  Future<void> initialize() async {
    try {
      // Initialiser SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      
      // Initialiser SQLite
      await _initializeDatabase();

      if (AppConstants.enableLogging) {
        print('✅ StorageService initialisé');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur initialisation storage: $e');
      }
      rethrow;
    }
  }

  /// Initialise la base de données SQLite locale
  Future<void> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'guinemali_local.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Crée les tables locales
  Future<void> _createTables(Database db, int version) async {
    // Table pour les alertes hors ligne
    await db.execute('''
      CREATE TABLE local_alerts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        type_alert TEXT NOT NULL,
        danger_level INTEGER NOT NULL,
        description TEXT,
        timestamp TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Table pour les preuves locales
    await db.execute('''
      CREATE TABLE local_evidence (
        id TEXT PRIMARY KEY,
        alert_id TEXT NOT NULL,
        type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER,
        timestamp TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Table pour les positions GPS locales (tracking)
    await db.execute('''
      CREATE TABLE local_locations (
        id TEXT PRIMARY KEY,
        alert_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        timestamp TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Table pour les contacts en cache
    await db.execute('''
      CREATE TABLE cached_contacts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        relation TEXT,
        priority INTEGER NOT NULL,
        active INTEGER DEFAULT 1,
        date_added TEXT NOT NULL
      )
    ''');

    // Table pour les données utilisateur en cache
    await db.execute('''
      CREATE TABLE cached_user_data (
        user_id TEXT PRIMARY KEY,
        pseudo TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        user_type TEXT NOT NULL,
        language TEXT,
        region TEXT,
        last_sync TEXT NOT NULL
      )
    ''');
    
    // Table pour la file de synchronisation
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_attempt TEXT,
        next_retry TEXT,
        last_error TEXT
      )
    ''');
    
    // Table pour les éléments de synchronisation échoués
    await db.execute('''
      CREATE TABLE failed_sync_items (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        failed_at TEXT NOT NULL,
        error_message TEXT NOT NULL
      )
    ''');

    if (AppConstants.enableLogging) {
      print('✅ Tables SQLite créées');
    }
  }

  /// Met à niveau la base de données
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Gestion des migrations futures
    if (AppConstants.enableLogging) {
      print('🔄 Migration base de données: $oldVersion -> $newVersion');
    }
  }

  // ===== GESTION SHARED PREFERENCES =====

  /// Sauvegarde une chaîne de caractères
  Future<void> saveString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  /// Récupère une chaîne de caractères
  String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// Sauvegarde un booléen
  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  /// Récupère un booléen
  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  /// Sauvegarde un entier
  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  /// Récupère un entier
  int getInt(String key, {int defaultValue = 0}) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  /// Sauvegarde un objet JSON
  Future<void> saveJson(String key, Map<String, dynamic> json) async {
    final jsonString = jsonEncode(json);
    await saveString(key, jsonString);
  }

  /// Récupère un objet JSON
  Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        if (AppConstants.enableLogging) {
          print('❌ Erreur décodage JSON pour $key: $e');
        }
      }
    }
    return null;
  }

  /// Supprime une clé
  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  /// Efface toutes les données
  Future<void> clear() async {
    await _prefs?.clear();
  }

  // ===== GESTION ALERTES LOCALES =====

  /// Sauvegarde une alerte localement
  Future<void> saveAlert(Map<String, dynamic> alertData) async {
    if (_database == null) return;

    await _database!.insert(
      'local_alerts',
      {
        'id': alertData['id'],
        'user_id': alertData['utilisateur_id'],
        'latitude': alertData['latitude'],
        'longitude': alertData['longitude'],
        'type_alert': alertData['type_alerte'],
        'danger_level': alertData['niveau_danger'],
        'description': alertData['description'],
        'timestamp': alertData['timestamp'],
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (AppConstants.enableLogging) {
      print('✅ Alerte sauvegardée localement: ${alertData['id']}');
    }
  }

  /// Récupère les alertes non synchronisées
  Future<List<Map<String, dynamic>>> getLocalAlerts() async {
    if (_database == null) return [];

    final List<Map<String, dynamic>> maps = await _database!.query(
      'local_alerts',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => {
      'id': map['id'],
      'utilisateur_id': map['user_id'],
      'latitude': map['latitude'],
      'longitude': map['longitude'],
      'type_alerte': map['type_alert'],
      'niveau_danger': map['danger_level'],
      'description': map['description'],
      'timestamp': map['timestamp'],
    }).toList();
  }

  /// Marque une alerte comme synchronisée
  Future<void> markAlertSynced(String alertId) async {
    if (_database == null) return;

    await _database!.update(
      'local_alerts',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  /// Supprime une alerte locale
  Future<void> removeLocalAlert(String alertId) async {
    if (_database == null) return;

    await _database!.delete(
      'local_alerts',
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  // ===== GESTION PREUVES LOCALES =====

  /// Sauvegarde une preuve localement
  Future<void> saveEvidence({
    required String id,
    required String alertId,
    required String type,
    required String filePath,
    int? fileSize,
  }) async {
    if (_database == null) return;

    await _database!.insert(
      'local_evidence',
      {
        'id': id,
        'alert_id': alertId,
        'type': type,
        'file_path': filePath,
        'file_size': fileSize,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (AppConstants.enableLogging) {
      print('✅ Preuve sauvegardée localement: $id');
    }
  }

  /// Récupère les preuves non synchronisées
  Future<List<Map<String, dynamic>>> getLocalEvidence() async {
    if (_database == null) return [];

    return await _database!.query(
      'local_evidence',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );
  }

  /// Marque une preuve comme synchronisée
  Future<void> markEvidenceSynced(String evidenceId) async {
    if (_database == null) return;

    await _database!.update(
      'local_evidence',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [evidenceId],
    );
  }

  /// Récupère les preuves pour une alerte spécifique
  Future<List<Map<String, dynamic>>> getEvidenceForAlert(String alertId) async {
    if (_database == null) return [];

    try {
      final evidence = await _database!.query(
        'local_evidence',
        where: 'alert_id = ?',
        whereArgs: [alertId],
        orderBy: 'timestamp DESC',
      );

      if (AppConstants.enableLogging) {
        print('✅ Preuves récupérées pour alerte $alertId: ${evidence.length}');
      }

      return evidence;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur récupération preuves pour alerte $alertId: $e');
      }
      return [];
    }
  }

  // ===== GESTION CACHE =====

  /// Nettoie le cache expiré
  Future<void> cleanExpiredCache() async {
    final now = DateTime.now();
    final expirationTime = now.subtract(
      const Duration(hours: AppConstants.cacheExpirationHours),
    );

    if (_database != null) {
      await _database!.delete(
        'cached_user_data',
        where: 'last_sync < ?',
        whereArgs: [expirationTime.toIso8601String()],
      );
    }

    if (AppConstants.enableLogging) {
      print('✅ Cache expiré nettoyé');
    }
  }

  // ===== GESTION CONTACTS EN CACHE =====

  /// Sauvegarde/Met à jour un contact d'urgence en cache
  Future<void> saveCachedContact({
    required String id,
    required String userId,
    required String name,
    required String phoneNumber,
    String? relation,
    required int priority,
    bool active = true,
    DateTime? dateAdded,
  }) async {
    if (_database == null) return;

    await _database!.insert(
      'cached_contacts',
      {
        'id': id,
        'user_id': userId,
        'name': name,
        'phone_number': phoneNumber,
        'relation': relation,
        'priority': priority,
        'active': active ? 1 : 0,
        'date_added': (dateAdded ?? DateTime.now()).toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère les contacts en cache pour un utilisateur
  Future<List<Map<String, dynamic>>> getCachedContacts(String userId) async {
    if (_database == null) return [];

    final contacts = await _database!.query(
      'cached_contacts',
      where: 'user_id = ? AND active = 1',
      whereArgs: [userId],
      orderBy: 'priority ASC',
    );

    return contacts;
  }

  /// Récupère la taille de la base de données
  Future<int> getDatabaseSize() async {
    if (_database == null) return 0;

    final path = _database!.path;
    try {
      final file = await _database!.rawQuery('PRAGMA page_count');
      final pageSize = await _database!.rawQuery('PRAGMA page_size');
      
      if (file.isNotEmpty && pageSize.isNotEmpty) {
        final pages = file.first['page_count'] as int;
        final size = pageSize.first['page_size'] as int;
        return pages * size;
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur calcul taille DB: $e');
      }
    }
    
    return 0;
  }

  /// Nettoie complètement la base de données locale
  Future<void> clearDatabase() async {
    if (_database != null) {
      await _database!.delete('local_alerts');
      await _database!.delete('local_evidence');
      await _database!.delete('local_locations');
      await _database!.delete('cached_contacts');
      await _database!.delete('cached_user_data');
      
      if (AppConstants.enableLogging) {
        print('✅ Base de données locale nettoyée');
      }
    }
  }

  /// Ferme la base de données
  Future<void> close() async {
    await _database?.close();
    _database = null;
    
    if (AppConstants.enableLogging) {
      print('✅ StorageService fermé');
    }
  }

  /// Nettoie les ressources
  void dispose() {
    close();
  }

  // ===== GESTION POSITIONS LOCALES =====

  Future<void> saveLocation({
    required String id,
    required String alertId,
    required double latitude,
    required double longitude,
    double? accuracy,
    DateTime? timestamp,
  }) async {
    if (_database == null) return;
    await _database!.insert(
      'local_locations',
      {
        'id': id,
        'alert_id': alertId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getLocalLocations() async {
    if (_database == null) return [];
    return _database!.query(
      'local_locations',
      where: 'synced = 0',
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> markLocationSynced(String id) async {
    if (_database == null) return;
    await _database!.update(
      'local_locations',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeLocationsForAlert(String alertId) async {
    if (_database == null) return;
    await _database!.delete(
      'local_locations',
      where: 'alert_id = ?',
      whereArgs: [alertId],
    );
  }

  // ===== GESTION SYNCHRONISATION =====

  /// Sauvegarde un élément dans la file de synchronisation
  Future<void> saveSyncQueueItem(Map<String, dynamic> item) async {
    if (_database == null) return;
    
    await _database!.insert(
      'sync_queue',
      {
        'id': item['id'],
        'type': item['type'],
        'data': jsonEncode(item['data']),
        'created_at': item['created_at'],
        'retry_count': item['retry_count'] ?? 0,
        'last_attempt': item['last_attempt'],
        'next_retry': item['next_retry'],
        'last_error': item['last_error'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère tous les éléments de la file de synchronisation
  Future<List<Map<String, dynamic>>> getSyncQueueItems() async {
    if (_database == null) return [];
    
    final results = await _database!.query(
      'sync_queue',
      orderBy: 'created_at ASC',
    );
    
    return results.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      return {
        'id': row['id'],
        'type': row['type'],
        'data': data,
        'created_at': row['created_at'],
        'retry_count': row['retry_count'],
        'last_attempt': row['last_attempt'],
        'next_retry': row['next_retry'],
        'last_error': row['last_error'],
      };
    }).toList();
  }

  /// Met à jour un élément de la file de synchronisation
  Future<void> updateSyncQueueItem(Map<String, dynamic> item) async {
    if (_database == null) return;
    
    await _database!.update(
      'sync_queue',
      {
        'retry_count': item['retry_count'],
        'last_attempt': item['last_attempt'],
        'next_retry': item['next_retry'],
        'last_error': item['last_error'],
      },
      where: 'id = ?',
      whereArgs: [item['id']],
    );
  }

  /// Supprime un élément de la file de synchronisation
  Future<void> removeSyncQueueItem(String id) async {
    if (_database == null) return;
    
    await _database!.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Sauvegarde un élément échoué
  Future<void> saveFailedSyncItem(Map<String, dynamic> item) async {
    if (_database == null) return;
    
    await _database!.insert(
      'failed_sync_items',
      {
        'id': item['id'],
        'type': item['type'],
        'data': jsonEncode(item['data']),
        'created_at': item['created_at'],
        'failed_at': DateTime.now().toIso8601String(),
        'error_message': item['last_error'] ?? 'Erreur inconnue',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère tous les éléments échoués
  Future<List<Map<String, dynamic>>> getFailedSyncItems() async {
    if (_database == null) return [];
    
    final results = await _database!.query(
      'failed_sync_items',
      orderBy: 'failed_at DESC',
    );
    
    return results.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      return {
        'id': row['id'],
        'type': row['type'],
        'data': data,
        'created_at': row['created_at'],
        'failed_at': row['failed_at'],
        'error_message': row['error_message'],
      };
    }).toList();
  }

  /// Nettoie tous les éléments échoués
  Future<void> clearFailedSyncItems() async {
    if (_database == null) return;
    
    await _database!.delete('failed_sync_items');
  }

  /// Nettoie la file de synchronisation
  Future<void> clearSyncQueue() async {
    if (_database == null) return;
    
    await _database!.delete('sync_queue');
  }
}