import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app/app_builder.dart';

/// Point d'entrée principal de l'application Guinèmali
void main() async {
  // Assurer que Flutter est initialisé
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialiser les services de l'application
    await AppBuilder.initializeServices();
    
    // Lancer l'application
    runApp(AppBuilder.buildApp());
  } catch (e) {
    print('❌ Erreur fatale lors du lancement de l\'application: $e');
    
    // Afficher une application d'erreur simple
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Erreur de lancement',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Impossible de démarrer l\'application: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Redémarrer l'application
                    SystemNavigator.pop();
                  },
                  child: const Text('Redémarrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
