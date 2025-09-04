import 'package:flutter/material.dart';
import 'services/supabase_service.dart';

/// Script de test pour vérifier les fonctions RPC Supabase
class TestRPCFunctions {
  static Future<void> testAllRPCFunctions() async {
    print('🔍 === TEST DES FONCTIONS RPC SUPABASE ===');
    
    try {
      // Initialiser Supabase
      await SupabaseService.ensureInitialized();
      final supabase = SupabaseService.instance;
      
      // Liste des fonctions RPC à tester
      final rpcFunctions = [
        {
          'name': 'update_last_login_secure',
          'params': {'p_user_id': 'test_user_id'},
          'description': 'Met à jour la dernière connexion'
        },
        {
          'name': 'creer_alerte_avec_notifications',
          'params': {
            'p_utilisateur_id': 'test_user_id',
            'p_latitude': 9.6412,
            'p_longitude': -13.5784,
            'p_type_alerte': 'test',
            'p_niveau_danger': 3,
            'p_description': 'Test alerte'
          },
          'description': 'Crée une alerte avec notifications'
        },
        {
          'name': 'resoudre_alerte',
          'params': {
            'p_alerte_id': 'test_alert_id',
            'p_utilisateur_id': 'test_user_id'
          },
          'description': 'Résout une alerte'
        },
        {
          'name': 'trouver_aidants_proximite',
          'params': {
            'alerte_lat': 9.6412,
            'alerte_lon': -13.5784,
            'rayon_metres': 5000
          },
          'description': 'Trouve les aidants à proximité'
        },
        {
          'name': 'check_pseudo_availability',
          'params': {'p_pseudo': 'test_pseudo'},
          'description': 'Vérifie la disponibilité d\'un pseudo'
        },

      ];
      
      // Tester chaque fonction
      for (final function in rpcFunctions) {
        await _testRPCFunction(
          supabase, 
          function['name'] as String, 
          function['params'] as Map<String, dynamic>,
          function['description'] as String
        );
      }
      
      print('✅ === FIN DES TESTS RPC ===');
      
    } catch (e) {
      print('❌ Erreur lors des tests RPC: $e');
    }
  }
  
  static Future<void> _testRPCFunction(
    SupabaseService supabase, 
    String functionName, 
    Map<String, dynamic> params,
    String description
  ) async {
    try {
      print('\n🧪 Test de la fonction: $functionName');
      print('📝 Description: $description');
      print('📊 Paramètres: $params');
      
      final result = await supabase.rpc(functionName, params: params);
      
      print('✅ SUCCÈS - Fonction $functionName existe et fonctionne');
      print('📤 Résultat: $result');
      
    } catch (e) {
      print('❌ ÉCHEC - Fonction $functionName: $e');
      
      // Analyser le type d'erreur
      if (e.toString().contains('function') && e.toString().contains('does not exist')) {
        print('💡 Cette fonction RPC n\'existe pas dans votre base de données');
      } else if (e.toString().contains('permission denied')) {
        print('💡 Cette fonction existe mais vous n\'avez pas les permissions');
      } else {
        print('💡 Erreur inconnue - vérifiez les paramètres');
      }
    }
  }
}

/// Widget de test pour l'interface utilisateur
class TestRPCWidget extends StatelessWidget {
  const TestRPCWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des Fonctions RPC'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bug_report,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Test des Fonctions RPC Supabase',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await TestRPCFunctions.testAllRPCFunctions();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tests terminés - Vérifiez la console'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Lancer les Tests'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Les résultats s\'afficheront dans la console de debug',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
