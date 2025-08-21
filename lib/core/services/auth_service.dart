import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert';
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
      final userId = await _storage.getString(AppConstants.keyUserId);
      final userPrenom = await _storage.getString(AppConstants.keyUserPrenom);
      final userType = await _storage.getString(AppConstants.keyUserType);
      final isLoggedIn = await _storage.getBool(AppConstants.keyIsLoggedIn) ?? false;

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

  // Générer un email temporaire unique
  String _generateTempEmail(String prenom) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedPrenom = prenom.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '${sanitizedPrenom}_$timestamp@gmail.com';
  }

  /// Inscription d'un nouvel utilisateur
  Future<UserModel> register(RegistrationData registrationData) async {
    try {
      // Créer un email temporaire unique valide basé sur le prénom
      final tempEmail = _generateTempEmail(registrationData.prenom);
      
      // Chiffrer le PIN
      final hashedPin = _hashPin(registrationData.pin);

      // Créer le compte d'authentification
      final authResponse = await _supabase.signUpWithEmail(
        email: tempEmail,
        password: registrationData.pin, // Utiliser le PIN comme mot de passe
        data: {
          'prenom': registrationData.prenom,
          'type_utilisateur': registrationData.typeUtilisateur.value,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Erreur lors de la création du compte');
      }

      // Créer le profil utilisateur dans la table publique
      final userData = registrationData.toJson();
      // Aligner avec le schéma: inclure explicitement `prenom` en base
      userData['prenom'] = registrationData.prenom;
      userData['id'] = authResponse.user!.id;
      userData['pin_chiffre'] = hashedPin;
      // S'assurer que pseudo a une valeur (utiliser le prénom par défaut)
      if (userData['pseudo'] == null || userData['pseudo'] == '') {
        userData['pseudo'] = registrationData.prenom;
      }

      final userResponse = await _supabase.insert(
        'utilisateurs',
        userData,
      );

      // userResponse est maintenant directement une List
      if (userResponse == null || userResponse.isEmpty) {
        throw Exception('Erreur lors de la création du profil utilisateur');
      }

      // Créer l'objet UserModel
      final userModel = UserModel.fromJson(userResponse.first);
      _currentUser = userModel;

      // Sauvegarder localement
      await _saveUserDataLocally(userModel);

      // Journaliser l'inscription
      await _logAction('inscription', {
        'prenom': registrationData.prenom,
        'type_utilisateur': registrationData.typeUtilisateur.value,
      });

      if (AppConstants.enableLogging) {
        print('✅ Utilisateur inscrit: ${userModel.prenom}');
      }

      return userModel;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur inscription: $e');
      }
      throw _handleAuthError(e);
    }
  }

  /// Connexion d'un utilisateur existant
  Future<UserModel> login(LoginData loginData) async {
    try {
      print('🔐 === DÉBUT DE LA CONNEXION ===');
      print('🔍 Tentative de connexion pour: ${loginData.prenom}');
      
      // Utiliser une fonction RPC (SECURITY DEFINER) pour respecter RLS et vérifier le couple pseudo + PIN
      final hashedPin = _hashPin(loginData.pin);
      final userResponse = await _supabase.rpc(
        'login_by_pseudo_hash',
        params: {
          'p_pseudo': loginData.prenom,
          'p_pin_hash': hashedPin,
        },
      );

      print('📊 Réponse RPC: $userResponse');

      if (userResponse == null || userResponse.isEmpty) {
        print('❌ Utilisateur non trouvé ou PIN incorrect');
        await _handleFailedLogin(loginData.prenom);
        throw Exception('Identifiants incorrects');
      }

      final userData = userResponse.first;
      print('📝 Données utilisateur récupérées: ${userData.keys}');
      print('✅ Identifiants valides, connexion autorisée');

      // Créer l'objet UserModel directement depuis nos données
      final userModel = UserModel.fromJson(userData);
      _currentUser = userModel;

      // Mettre à jour la dernière connexion
      await _updateLastLogin(userModel.id);

      // Sauvegarder localement
      await _saveUserDataLocally(userModel);

      // Journaliser la connexion
      await _logAction('connexion', {
        'prenom': loginData.prenom,
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

  /// Vérifie si un prénom/pseudo est disponible
  Future<bool> isPrenomAvailable(String prenom) async {
    try {
      print('🔍 Vérification prénom: $prenom');
      
      // Vérifier le pseudo (colonne existante en base)
      final response = await _supabase.select(
        'utilisateurs',
        columns: 'id',
        filters: {'pseudo': prenom},
        limit: 1,
      );

      print('📊 Réponse vérification prénom: $response');
      
      // response est maintenant directement une List
      final isAvailable = response == null || response.isEmpty;
      print('✅ Prénom disponible: $isAvailable');
      
      return isAvailable;
    } catch (e) {
      print('❌ Erreur vérification prénom: $e');
      // En cas d'erreur, on considère que le prénom est disponible pour permettre l'inscription
      // Cela évite de bloquer l'inscription à cause d'un problème de connexion
      print('⚠️ Erreur de connexion, on considère le prénom comme disponible');
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

  /// Met à jour la dernière connexion
  Future<void> _updateLastLogin(String userId) async {
    try {
      await _supabase.update(
        'utilisateurs',
        {'derniere_connexion': DateTime.now().toIso8601String()},
        idColumn: 'id',
        idValue: userId,
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
