import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/auth_models.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';
import 'storage_service.dart';

/// Service d'authentification pour Guinèmali
/// Gère l'inscription, la connexion et la gestion des sessions utilisateur
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  AuthService._();

  final SupabaseService _supabase = SupabaseService.instance;
  final StorageService _storage = StorageService.instance;
  final _uuid = const Uuid();

  /// Stream des changements d'état d'authentification
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;

  /// Utilisateur actuellement connecté
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  /// Indique si l'utilisateur est connecté
  bool get isLoggedIn => _currentUser != null;

  /// Retourne l'ID de l'utilisateur actuel
  String? get userId => _currentUser?.id;

  /// Retourne le type d'utilisateur actuel
  UserType? get userType => _currentUser?.typeUtilisateur;

  /// Initialise le service d'authentification
  Future<void> initialize() async {
    try {
      // Charger l'utilisateur depuis le stockage local
      await _loadUserFromLocalStorage();
      
      if (AppConstants.enableLogging) {
        print('✅ AuthService initialisé');
        if (_currentUser != null) {
          print('👤 Utilisateur chargé depuis le stockage local: ${_currentUser!.prenom}');
        } else {
          print('👤 Aucun utilisateur connecté');
        }
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur initialisation AuthService: $e');
      }
    }
  }

  /// Charge l'utilisateur depuis le stockage local
  Future<void> _loadUserFromLocalStorage() async {
    try {
      final userId = _storage.getString(AppConstants.keyUserId);
      final userPrenom = _storage.getString(AppConstants.keyUserPrenom);
      final userType = _storage.getString(AppConstants.keyUserType);
      final isLoggedIn = _storage.getBool(AppConstants.keyIsLoggedIn, defaultValue: false);

      if (isLoggedIn && userId != null && userPrenom != null && userType != null) {
        // Récupérer les données complètes depuis la base de données
        final response = await _supabase.select(
          'utilisateurs',
          filters: {'id': userId},
          limit: 1,
        );

        if (response != null && response.isNotEmpty) {
          _currentUser = UserModel.fromJson(response.first);
          if (AppConstants.enableLogging) {
            print('✅ Utilisateur chargé depuis la base de données: ${_currentUser!.prenom}');
          }
        }
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur chargement utilisateur local: $e');
      }
    }
  }



  /// Inscription d'un nouvel utilisateur
  Future<UserModel> register(RegistrationData registrationData) async {
    try {
      print(' === DÉBUT DE L\'INSCRIPTION ===');
      print(' Données reçues: ${registrationData.toJson()}');
      
      // Test de connexion Supabase
      print('🔌 Test de connexion Supabase...');
      try {
        final testResponse = await _supabase.select(
          'utilisateurs',
          limit: 1,
        );
        print('✅ Connexion Supabase OK: $testResponse');
      } catch (e) {
        print('❌ Erreur connexion Supabase: $e');
        throw Exception('Impossible de se connecter à Supabase: $e');
      }
      
      // Vérifier d'abord si le pseudo existe déjà
      print('🔍 Vérification de la disponibilité du pseudo...');
      final existingUser = await _supabase.select(
        'utilisateurs',
        columns: 'id',
        filters: {'pseudo': registrationData.pseudo},
        limit: 1,
      );
      
      if (existingUser != null && existingUser.isNotEmpty) {
        throw Exception('Ce pseudo est déjà utilisé');
      }
      
      // Générer un UUID pour l'utilisateur (sans Supabase Auth)
      print('📝 Génération de l\'ID utilisateur...');
      final userId = _uuid.v4();
      print('✅ ID utilisateur généré: $userId');
      
       // Préparer les données avec gestion des champs obligatoires et optionnels
      final userData = <String, dynamic>{
        'id': userId,
        'pseudo': registrationData.pseudo,
        'prenom': registrationData.prenom.isNotEmpty ? registrationData.prenom : registrationData.pseudo, // Prénom obligatoire
        'pin_chiffre': _hashPin(registrationData.pin), // Hasher le PIN
        'type_utilisateur': registrationData.typeUtilisateur == UserType.victime ? 'victime' : 'aidant',
        'actif': true,
      };
      
      // Ajouter les champs optionnels seulement s'ils existent
      if (registrationData.numTel.isNotEmpty) {
        userData['num_tel'] = registrationData.numTel;
      }
      if (registrationData.langue != null) {
        userData['langue'] = registrationData.langue;
      }
      if (registrationData.region != null) {
        userData['region'] = registrationData.region;
      }
      
      print(' Données à insérer: $userData');
      
      final result = await _supabase.insert(
        'utilisateurs',
        userData,
      );
      
      if (result == null || result.isEmpty) {
        throw Exception('Échec de l\'insertion dans la table utilisateurs');
      }
      
      print('✅ Utilisateur inséré dans la table: ${result.first['id']}');
      
      // Créer et retourner le UserModel
      final user = UserModel(
        id: result.first['id'],
        prenom: result.first['prenom'],
        pseudo: result.first['pseudo'],
        typeUtilisateur: result.first['type_utilisateur'] == 'victime' ? UserType.victime : UserType.aidant,
        dateCreation: DateTime.now(),
      );
      
      print('✅ Inscription réussie pour: ${user.prenom}');
      return user;
      
    } catch (e) {
      print('❌ Erreur détaillée lors de l\'inscription: $e');
      print('📚 Stack trace: ${StackTrace.current}');
      
      // Analyser le type d'erreur pour donner un message plus précis
      String errorMessage = 'Échec de l\'inscription';
      
      if (e.toString().contains('duplicate key value')) {
        if (e.toString().contains('pseudo')) {
          errorMessage = 'Ce pseudo est déjà utilisé';
        } else if (e.toString().contains('num_tel')) {
          errorMessage = 'Ce numéro de téléphone est déjà utilisé';
        } else {
          errorMessage = 'Cette information est déjà utilisée par un autre utilisateur';
        }
      } else if (e.toString().contains('violates check constraint')) {
        errorMessage = 'Les données saisies ne respectent pas les contraintes';
      } else if (e.toString().contains('permission denied')) {
        errorMessage = 'Erreur de permissions - contactez le support';
      } else if (e.toString().contains('connection')) {
        errorMessage = 'Erreur de connexion - vérifiez votre réseau';
      } else {
        errorMessage = 'Erreur lors de l\'inscription: ${e.toString()}';
      }
      
      throw Exception(errorMessage);
    }
  }

  /// Connexion d'un utilisateur existant
  Future<UserModel> login(LoginData loginData) async {
    try {
      print('🔐 === DÉBUT DE LA CONNEXION ===');
      print('🔍 Tentative de connexion pour: ${loginData.pseudo}');
      
      // Protection anti-bruteforce simple (stockage local)
      const int maxAttempts = 5;
      const int cooldownSeconds = 60;

      final String keyAttempts = 'login_failed_count_${loginData.pseudo}';
      final String keyLockUntil = 'login_lock_until_${loginData.pseudo}';

      final int failedAttempts = _storage.getInt(keyAttempts, defaultValue: 0);
      final String? lockUntilIso = _storage.getString(keyLockUntil);
      if (lockUntilIso != null) {
        final lockUntil = DateTime.tryParse(lockUntilIso);
        if (lockUntil != null && DateTime.now().isBefore(lockUntil)) {
          final remaining = lockUntil.difference(DateTime.now()).inSeconds;
          throw Exception('Trop de tentatives. Réessayez dans ${remaining}s');
        }
      }

      // MODE DE TEST TEMPORAIRE - Contourner Supabase pour les tests
      if (AppConstants.enableTestMode) {
        print('🧪 MODE DE TEST ACTIVÉ - Connexion simulée');
        
        // Créer un utilisateur de test
        final testUser = UserModel(
          id: 'test_user_id_${DateTime.now().millisecondsSinceEpoch}',
          prenom: loginData.pseudo, // Utiliser pseudo comme prenom pour le test
          pseudo: loginData.pseudo,
          typeUtilisateur: UserType.victime,
          dateCreation: DateTime.now(),
        );
        
        _currentUser = testUser;
        await _saveUserDataLocally(testUser);
        
        print('✅ Connexion de test réussie: ${testUser.prenom}');
        return testUser;
      }
      
      // MODE NORMAL - Utiliser Supabase
      final hashedPin = _hashPin(loginData.pin);

      // 1) Récupérer l'utilisateur par pseudo et actif
      final userResponse = await _supabase.select(
        'utilisateurs',
        filters: {
          'pseudo': loginData.pseudo,
          'actif': true,
        },
        limit: 1,
      );

      print('📊 Réponse utilisateur: $userResponse');

      if (userResponse == null || userResponse.isEmpty) {
        print('❌ Utilisateur introuvable ou inactif');
        await _handleFailedLogin(loginData.pseudo);
        // Incrémente les échecs et applique cooldown si nécessaire
        await _storage.setInt(keyAttempts, failedAttempts + 1);
        if (failedAttempts + 1 >= maxAttempts) {
          final until = DateTime.now().add(const Duration(seconds: cooldownSeconds));
          await _storage.saveString(keyLockUntil, until.toIso8601String());
        }
        throw Exception('Pseudo introuvable');
      }

      final userData = userResponse.first;

      // 2) Vérifier le PIN localement pour éviter tout problème de filtre côté serveur
      final storedHash = (userData['pin_chiffre'] ?? '').toString();
      if (storedHash.isEmpty || storedHash != hashedPin) {
        print('❌ PIN incorrect pour ${loginData.pseudo}');
        await _handleFailedLogin(loginData.pseudo);
        // Incrémente les échecs et applique cooldown si nécessaire
        await _storage.setInt(keyAttempts, failedAttempts + 1);
        if (failedAttempts + 1 >= maxAttempts) {
          final until = DateTime.now().add(const Duration(seconds: cooldownSeconds));
          await _storage.saveString(keyLockUntil, until.toIso8601String());
        }
        throw Exception('PIN incorrect');
      }
      print('📝 Données utilisateur récupérées: ${userData.keys}');
      print('✅ Identifiants valides, connexion autorisée');

      // Créer l'objet UserModel directement depuis nos données
      final userModel = UserModel.fromJson(userData);
      _currentUser = userModel;

      // Mettre à jour la dernière connexion avec la fonction RPC existante
      await _updateLastLoginSecure(userModel.id);

      // Sauvegarder localement
      await _saveUserDataLocally(userModel);

      // Réinitialiser le compteur d'échecs
      await _storage.setInt(keyAttempts, 0);
      await _storage.remove(keyLockUntil);

      // Journaliser la connexion
      await _logAction('connexion', {
        'pseudo': loginData.pseudo,
      });

      if (AppConstants.enableLogging) {
        print('✅ Connexion réussie: ${userModel.prenom}');
      }

      return userModel;
    } catch (e) {
      print('❌ === ERREUR LORS DE LA CONNEXION ===');
      print('❌ Erreur: $e');
      if (AppConstants.enableLogging) {
        print('❌ Erreur connexion: $e');
      }
      throw _handleAuthError(e);
    }
  }

  /// Déconnexion de l'utilisateur
  Future<void> logout() async {
    try {
      // Journaliser la déconnexion
      if (_currentUser != null) {
        await _logAction('deconnexion', {
          'prenom': _currentUser!.prenom,
        });
      }

      // Déconnexion de Supabase
      await _supabase.signOut();

      // Nettoyer les données locales
      await _clearUserData();

      if (AppConstants.enableLogging) {
        print('✅ Déconnexion réussie');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur déconnexion: $e');
      }
      throw _handleAuthError(e);
    }
  }

  /// Met à jour le profil utilisateur
  Future<UserModel> updateProfile(Map<String, dynamic> updates) async {
    try {
      if (_currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Chiffrer le PIN si présent dans les mises à jour
      if (updates.containsKey('pin')) {
        updates['pin_chiffre'] = _hashPin(updates['pin']);
        updates.remove('pin');
      }

      final response = await _supabase.update(
        'utilisateurs',
        updates,
        idColumn: 'id',
        idValue: _currentUser!.id,
      );

      // response est maintenant directement une List
      if (response == null || response.isEmpty) {
        throw Exception('Erreur lors de la mise à jour du profil');
      }

      final updatedUser = UserModel.fromJson(response.first);
      _currentUser = updatedUser;

      // Sauvegarder localement
      await _saveUserDataLocally(updatedUser);

      // Journaliser la mise à jour
      await _logAction('mise_a_jour_profil', updates);

      if (AppConstants.enableLogging) {
        print('✅ Profil mis à jour');
      }

      return updatedUser;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur mise à jour profil: $e');
      }
      throw _handleAuthError(e);
    }
  }

  /// Vérifie si un pseudo est disponible
  Future<bool> isPseudoAvailable(String pseudo) async {
    try {
      print('🔍 Vérification pseudo: $pseudo');
      
      // Vérifier le pseudo (colonne existante en base)
      final response = await _supabase.select(
        'utilisateurs',
        columns: 'id',
        filters: {'pseudo': pseudo},
        limit: 1,
      );

      print('📊 Réponse vérification pseudo: $response');
      
      // response est maintenant directement une List
      final isAvailable = response == null || response.isEmpty;
      print('✅ Pseudo disponible: $isAvailable');
      
      return isAvailable;
    } catch (e) {
      print('❌ Erreur vérification pseudo: $e');
      // En cas d'erreur, on considère que le pseudo est disponible pour permettre l'inscription
      // Cela évite de bloquer l'inscription à cause d'un problème de connexion
      print('⚠️ Erreur de connexion, on considère le pseudo comme disponible');
      return true;
    }
  }

  /// Sauvegarde les données utilisateur localement
  Future<void> _saveUserDataLocally(UserModel user) async {
    try {
      await _storage.saveString(AppConstants.keyUserId, user.id);
      await _storage.saveString(AppConstants.keyUserPrenom, user.prenom);
      await _storage.saveString(AppConstants.keyUserType, user.typeUtilisateur.value);
      await _storage.setBool(AppConstants.keyIsLoggedIn, true);
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur sauvegarde locale: $e');
      }
    }
  }

  /// Nettoie les données utilisateur locales
  Future<void> _clearUserData() async {
    try {
      _currentUser = null;
      await _storage.remove(AppConstants.keyUserId);
      await _storage.remove(AppConstants.keyUserPrenom);
      await _storage.remove(AppConstants.keyUserType);
      await _storage.setBool(AppConstants.keyIsLoggedIn, false);
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur nettoyage données: $e');
      }
    }
  }

  /// Met à jour la dernière connexion avec la fonction RPC existante
  Future<void> _updateLastLoginSecure(String userId) async {
    try {
      // Adapter au nom de paramètre réel de la fonction RPC (p_id)
      await _supabase.rpc(
        'update_last_login_secure',
        params: {'p_id': userId},
      );
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur mise à jour dernière connexion: $e');
      }
    }
  }

  /// Gère les tentatives de connexion échouées
  Future<void> _handleFailedLogin(String prenom) async {
    // Pour l'instant, on journalise simplement en local
    if (AppConstants.enableLogging) {
      print('⚠️ Tentative de connexion échouée pour: $prenom');
    }
    // TODO: Implémenter une logique de limitation des tentatives si nécessaire
  }

  /// Journalise une action utilisateur
  Future<void> _logAction(String action, Map<String, dynamic> details) async {
    try {
      // Pour l'instant, on journalise simplement en local
      if (AppConstants.enableLogging) {
        print('📝 Action journalisée: $action - $details');
      }
      // TODO: Implémenter la journalisation en base de données si nécessaire
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur journalisation: $e');
      }
    }
  }

  /// Chiffre un PIN
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'guinemali_salt'); // Ajout d'un salt
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Gère les erreurs d'authentification
  Exception _handleAuthError(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return Exception('Identifiants incorrects');
        case 'Email already registered':
          return Exception('Cet email est déjà utilisé');
        case 'Password should be at least 6 characters':
          return Exception('Le mot de passe doit contenir au moins 6 caractères');
        default:
          return Exception('Erreur d\'authentification: ${error.message}');
      }
    }
    
    if (error is PostgrestException) {
      if (error.code == '23505') { // Violation de contrainte unique
        return Exception('Ce pseudo est déjà utilisé');
      }
      return Exception('Erreur de base de données: ${error.message}');
    }

    return Exception('Erreur inattendue: $error');
  }

  /// Nettoie les ressources
  void dispose() {
    _currentUser = null;
    if (AppConstants.enableLogging) {
      print('✅ AuthService nettoyé');
    }
  }
}
