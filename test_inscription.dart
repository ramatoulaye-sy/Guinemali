import 'package:flutter/material.dart';
import 'lib/core/services/auth_service.dart';
import 'lib/core/services/supabase_service.dart';
import 'lib/protected_person/models/auth_models.dart';
import 'lib/core/models/user_model.dart';

/// Script de test pour diagnostiquer les problèmes d'inscription
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔍 === DIAGNOSTIC INSCRIPTION GUINEMALI ===');
  
  try {
    // 1. Initialiser Supabase
    print('\n1️⃣ Initialisation Supabase...');
    await SupabaseService.initialize();
    print('✅ Supabase initialisé');
    
    // 2. Tester la connexion
    print('\n2️⃣ Test de connexion Supabase...');
    final testResponse = await SupabaseService.instance.select(
      'utilisateurs',
      limit: 1,
    );
    print('✅ Connexion OK: ${testResponse?.length ?? 0} utilisateurs trouvés');
    
    // 3. Tester l'inscription
    print('\n3️⃣ Test d\'inscription...');
    final authService = AuthService.instance;
    
    final registrationData = RegistrationData(
      prenom: 'TestDiagnostic',
      pseudo: 'test_diagnostic_${DateTime.now().millisecondsSinceEpoch}',
      pin: '123456',
      numTel: '+224123456789',
      typeUtilisateur: UserType.victime,
      langue: 'fr',
      region: 'Conakry',
    );
    
    print('📝 Données d\'inscription: ${registrationData.toJson()}');
    
    final user = await authService.register(registrationData);
    print('✅ Inscription réussie: ${user.prenom} (ID: ${user.id})');
    
    // 4. Tester la connexion
    print('\n4️⃣ Test de connexion...');
    final loginData = LoginData(
      prenom: registrationData.pseudo,
      pin: registrationData.pin,
    );
    
    final loggedUser = await authService.login(loginData);
    print('✅ Connexion réussie: ${loggedUser.prenom}');
    
    print('\n🎉 === DIAGNOSTIC TERMINÉ AVEC SUCCÈS ===');
    
  } catch (e, stackTrace) {
    print('\n❌ === ERREUR LORS DU DIAGNOSTIC ===');
    print('❌ Erreur: $e');
    print('📚 Stack trace: $stackTrace');
    
    // Suggestions de résolution
    print('\n🔧 === SUGGESTIONS DE RÉSOLUTION ===');
    if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
      print('1. Exécuter le schéma SQL dans Supabase Dashboard');
      print('2. Vérifier que les tables sont créées');
    } else if (e.toString().contains('function') && e.toString().contains('does not exist')) {
      print('1. Exécuter les fonctions RPC du schéma SQL');
      print('2. Vérifier que login_by_pseudo_hash existe');
    } else if (e.toString().contains('row-level security')) {
      print('1. Désactiver temporairement RLS: ALTER TABLE utilisateurs DISABLE ROW LEVEL SECURITY;');
      print('2. Ou vérifier les politiques RLS');
    } else if (e.toString().contains('connection') || e.toString().contains('network')) {
      print('1. Vérifier la connexion internet');
      print('2. Vérifier les clés Supabase dans supabase_config.dart');
    }
  }
}
