import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// Service principal pour la gestion de Supabase
/// Singleton pour gérer la connexion et les opérations de base
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();

  /// Instance du client Supabase
  SupabaseClient get client => Supabase.instance.client;

  static bool _initialized = false;

  /// Vérifie/assure l'initialisation de Supabase
  static Future<void> ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => client.auth.currentUser != null;

  /// Utilisateur actuel
  User? get currentUser => client.auth.currentUser;

  /// ID de l'utilisateur actuel
  String? get currentUserId => currentUser?.id;

  /// Initialise Supabase avec les configurations
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
        debug: AppConstants.enableDebugMode,
      );
      _initialized = true;
      
      if (AppConstants.enableLogging) {
        print('✅ Supabase initialisé avec succès');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur lors de l\'initialisation de Supabase: $e');
      }
      rethrow;
    }
  }

  /// Écoute les changements d'état d'authentification
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Inscrit un nouvel utilisateur avec email/mot de passe
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      await SupabaseService.ensureInitialized();
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      
      if (AppConstants.enableLogging) {
        print('✅ Inscription réussie pour: $email');
      }
      
      return response;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur lors de l\'inscription: $e');
      }
      rethrow;
    }
  }

  /// Connecte un utilisateur avec email/mot de passe
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await SupabaseService.ensureInitialized();
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (AppConstants.enableLogging) {
        print('✅ Connexion réussie pour: $email');
      }
      
      return response;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur lors de la connexion: $e');
      }
      rethrow;
    }
  }

  /// Déconnecte l'utilisateur actuel
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
      
      if (AppConstants.enableLogging) {
        print('✅ Déconnexion réussie');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur lors de la déconnexion: $e');
      }
      rethrow;
    }
  }

  /// Remet à zéro le mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
      
      if (AppConstants.enableLogging) {
        print('✅ Email de réinitialisation envoyé à: $email');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur lors de la réinitialisation: $e');
      }
      rethrow;
    }
  }

  /// Exécute une requête SELECT
  Future<dynamic> select(
    String table, {
    String columns = '*',
    String? where,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      await SupabaseService.ensureInitialized();
      dynamic query = client.from(table).select(columns);

      // Appliquer les filtres
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Appliquer la clause WHERE personnalisée
      if (where != null) {
        // Note: Pour une clause WHERE complexe, il faudrait utiliser .filter()
        // Cette implémentation basique peut être étendue
      }

      // Appliquer l'ordre
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Appliquer la limite
      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      
      if (AppConstants.enableLogging) {
        print('✅ SELECT réussi sur $table: ${response.toString()}');
      }
      
      return response;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur SELECT sur $table: $e');
      }
      rethrow;
    }
  }

  /// Exécute une requête INSERT
  Future<dynamic> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      await SupabaseService.ensureInitialized();
      final response = await client
          .from(table)
          .insert(data)
          .select();
      
      if (AppConstants.enableLogging) {
        print('✅ INSERT réussi sur $table');
      }
      
      return response;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur INSERT sur $table: $e');
      }
      rethrow;
    }
  }

  /// Exécute une requête UPDATE
  Future<dynamic> update(
    String table,
    Map<String, dynamic> data, {
    required String idColumn,
    required dynamic idValue,
  }) async {
    try {
      await SupabaseService.ensureInitialized();
      final response = await client
          .from(table)
          .update(data)
          .eq(idColumn, idValue)
          .select();
      
      if (AppConstants.enableLogging) {
        print('✅ UPDATE réussi sur $table');
      }
      
      return response;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur UPDATE sur $table: $e');
      }
      rethrow;
    }
  }

  /// Exécute une requête DELETE
  Future<dynamic> delete(
    String table, {
    required String idColumn,
    required dynamic idValue,
  }) async {
    try {
      await SupabaseService.ensureInitialized();
      final response = await client
          .from(table)
          .delete()
          .eq(idColumn, idValue)
          .select();
      
      if (AppConstants.enableLogging) {
        print('✅ DELETE réussi sur $table');
      }
      
      return response;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur DELETE sur $table: $e');
      }
      rethrow;
    }
  }

  /// Exécute une fonction RPC
  Future<dynamic> rpc(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    try {
      await SupabaseService.ensureInitialized();
      final response = await client.rpc(functionName, params: params);
      
      if (AppConstants.enableLogging) {
        print('✅ RPC $functionName exécuté avec succès');
      }
      
      return response;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur RPC $functionName: $e');
      }
      rethrow;
    }
  }

  /// Upload un fichier vers Supabase Storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> file,
    Map<String, String>? metadata,
  }) async {
    try {
      await client.storage.from(bucket).uploadBinary(
        path,
        Uint8List.fromList(file),
        fileOptions: FileOptions(
          upsert: true,
          metadata: metadata,
        ),
      );

      final url = client.storage.from(bucket).getPublicUrl(path);
      
      if (AppConstants.enableLogging) {
        print('✅ Fichier uploadé: $path');
      }
      
      return url;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur upload fichier: $e');
      }
      rethrow;
    }
  }

  /// Télécharge un fichier depuis Supabase Storage
  Future<List<int>> downloadFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final file = await client.storage.from(bucket).download(path);
      
      if (AppConstants.enableLogging) {
        print('✅ Fichier téléchargé: $path');
      }
      
      return file;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur téléchargement fichier: $e');
      }
      rethrow;
    }
  }

  /// Supprime un fichier de Supabase Storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await client.storage.from(bucket).remove([path]);
      
      if (AppConstants.enableLogging) {
        print('✅ Fichier supprimé: $path');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur suppression fichier: $e');
      }
      rethrow;
    }
  }

  /// Écoute les changements en temps réel sur une table
  RealtimeChannel subscribeToTable(
    String table,
    void Function(PostgresChangePayload) callback, {
    String event = '*',
    String? schema = 'public',
  }) {
    try {
      final channel = client
          .channel('$table-changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: schema!,
            table: table,
            callback: callback,
          )
          .subscribe();

      if (AppConstants.enableLogging) {
        print('✅ Souscription temps réel activée pour $table');
      }

      return channel;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur souscription temps réel: $e');
      }
      rethrow;
    }
  }

  /// Annule une souscription temps réel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    try {
      await client.removeChannel(channel);
      
      if (AppConstants.enableLogging) {
        print('✅ Souscription temps réel annulée');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur annulation souscription: $e');
      }
      rethrow;
    }
  }

  /// Vérifie la connexion réseau
  Future<bool> checkConnection() async {
    try {
      await client.from('utilisateurs').select('id').limit(1);
      return true;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Pas de connexion réseau');
      }
      return false;
    }
  }

  /// Teste la connexion à Supabase et vérifie la structure de la base
  Future<Map<String, dynamic>> testConnection() async {
    try {
      await SupabaseService.ensureInitialized();
      print('🔌 Test de connexion Supabase...');
      
      // Test 1: Vérifier si le client est initialisé
      // (client getter lance une erreur si non initialisé)
      print('✅ Client Supabase initialisé');
      
      // Test 2: Vérifier la connexion en testant une requête simple
      final testResponse = await client.from('utilisateurs').select('count').limit(1);
      print('✅ Requête de test réussie: $testResponse');
      
      // Test 3: Vérifier la structure de la table utilisateurs
      try {
        final structureResponse = await client.rpc('get_table_info', params: {'table_name': 'utilisateurs'});
        print('✅ Structure de la table récupérée: $structureResponse');
      } catch (e) {
        print('⚠️ Impossible de récupérer la structure de la table: $e');
        // Test alternatif: essayer de récupérer quelques colonnes
        final columnsResponse = await client.from('utilisateurs').select('id, pseudo, type_utilisateur').limit(1);
        print('✅ Colonnes de base accessibles: $columnsResponse');
      }
      
      return {
        'status': 'success',
        'message': 'Connexion Supabase réussie',
        'client_initialized': true,
        'table_accessible': true,
      };
      
    } catch (e) {
      print('❌ Erreur lors du test de connexion: $e');
      return {
        'status': 'error',
        'message': 'Erreur de connexion: $e',
        'client_initialized': client != null,
        'table_accessible': false,
      };
    }
  }

  /// Nettoie les ressources
  void dispose() {
    // Nettoyer les souscriptions et autres ressources si nécessaire
    if (AppConstants.enableLogging) {
      print('✅ SupabaseService nettoyé');
    }
  }
}
