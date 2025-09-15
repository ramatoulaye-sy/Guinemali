import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart';

/// Provider pour la gestion de l'état d'authentification
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  /// Utilisateur actuellement connecté
  UserModel? get currentUser => _currentUser;
  
  /// Indique si une opération est en cours
  bool get isLoading => _isLoading;
  
  /// Message d'erreur actuel
  String? get errorMessage => _errorMessage;
  
  /// Indique si l'utilisateur est connecté
  bool get isAuthenticated => _currentUser != null;

  /// Initialise le provider et vérifie l'état de connexion
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _authService.initialize();
      
      // Charger l'utilisateur depuis le service d'authentification
      _currentUser = _authService.currentUser;
      
      if (AppConstants.enableLogging) {
        print('✅ AuthProvider initialisé - Utilisateur: ${_currentUser?.prenom ?? 'Aucun'}');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur initialisation AuthProvider: $e');
      }
      _setError('Erreur d\'initialisation: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Charge les informations de l'utilisateur actuel
  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = _authService.currentUser;
      
      if (AppConstants.enableLogging) {
        print('👤 Utilisateur chargé dans AuthProvider: ${_currentUser?.prenom ?? 'Aucun'}');
        print('👤 ID utilisateur: ${_currentUser?.id ?? 'Aucun'}');
        print('👤 Type utilisateur: ${_currentUser?.typeUtilisateur.value ?? 'Aucun'}');
      }
      
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Erreur de chargement utilisateur: $e');
      if (AppConstants.enableLogging) {
        print('❌ Erreur chargement utilisateur dans AuthProvider: $e');
      }
    }
  }

  /// Force le rechargement de l'utilisateur
  Future<void> refreshUser() async {
    try {
      await _loadCurrentUser();
      if (AppConstants.enableLogging) {
        print('🔄 Utilisateur rechargé dans AuthProvider');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur rechargement utilisateur: $e');
      }
    }
  }

  /// Connecte un utilisateur
  Future<bool> login({
    required String pseudo,
    required String pin,
  }) async {
    _setLoading(true);
    try {
      final loginData = LoginData(pseudo: pseudo, pin: pin);
      final user = await _authService.login(loginData);
      
      _currentUser = user;
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur de connexion: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Inscrit un nouvel utilisateur
  Future<bool> register({
    required String prenom,
    required String pseudo, // Ajout du paramètre pseudo
    required String pin,
    required String numTel,
    required String userType,
    String? langue,
    String? region,
  }) async {
    _setLoading(true);
    try {
      final registrationData = RegistrationData(
        prenom: prenom,
        pseudo: pseudo, // Utiliser le pseudo fourni
        pin: pin,
        numTel: numTel,
        typeUtilisateur: UserType.fromString(userType),
        langue: langue,
        region: region,
      );
      final user = await _authService.register(registrationData);
      
      _currentUser = user;
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur d\'inscription: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Déconnecte l'utilisateur
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _currentUser = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Erreur de déconnexion: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Met à jour le profil utilisateur
  Future<bool> updateProfile({
    String? prenom,
    String? numTel,
    String? langue,
    String? region,
  }) async {
    if (_currentUser == null) return false;
    
    _setLoading(true);
    try {
      final updates = <String, dynamic>{};
      if (prenom != null) updates['prenom'] = prenom;
      if (numTel != null) updates['num_tel'] = numTel;
      if (langue != null) updates['langue'] = langue;
      if (region != null) updates['region'] = region;
      
      final updatedUser = await _authService.updateProfile(updates);
      
      _currentUser = updatedUser;
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur de mise à jour: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Vérifie la disponibilité d'un pseudo
  Future<Map<String, dynamic>> checkPseudoAvailability(String pseudo) async {
    try {
      final isAvailable = await _authService.isPseudoAvailable(pseudo);
      return {
        'available': isAvailable,
        'message': isAvailable ? 'Pseudo disponible' : 'Pseudo déjà utilisé',
        'suggestions': isAvailable ? [] : ['${pseudo}_1', '${pseudo}_2', '${pseudo}_3'],
        'status': 'success',
      };
    } catch (e) {
      _setError('Erreur de vérification du pseudo: $e');
      return {
        'available': false,
        'message': 'Erreur de vérification: $e',
        'suggestions': [],
        'status': 'error',
      };
    }
  }

  /// Définit l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Définit un message d'erreur
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Efface le message d'erreur
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }


}
