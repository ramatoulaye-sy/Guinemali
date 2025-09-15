import 'package:guinemali/core/services/auth_service.dart';
import 'package:guinemali/core/models/auth_models.dart';

/// Script de test pour vérifier la connexion avec pseudo
void main() async {
  print('🧪 === TEST DE CONNEXION AVEC PSEUDO ===');
  
  try {
    // Initialiser le service d'authentification
    final authService = AuthService.instance;
    await authService.initialize();
    
    // Test de connexion avec pseudo
    print('🔍 Test de connexion avec pseudo: amadou20');
    
    final loginData = LoginData(
      pseudo: 'amadou20', // Utiliser pseudo au lieu de prenom
      pin: '1234',
    );
    
    final user = await authService.login(loginData);
    print('✅ Connexion réussie!');
    print('👤 Utilisateur: ${user.prenom}');
    print('🆔 Pseudo: ${user.pseudo}');
    print('📧 Type: ${user.typeUtilisateur.value}');
    
  } catch (e) {
    print('❌ Erreur de connexion: $e');
  }
}
