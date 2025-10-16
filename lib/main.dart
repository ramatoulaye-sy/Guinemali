import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/app/app_builder.dart';
import 'core/services/fcm_service.dart';

/// Point d'entrée principal de l'application Guinèmali
void main() async {
  // Assurer que Flutter est initialisé
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialiser Firebase (vérifier si déjà initialisé pour éviter les erreurs au Hot Restart)
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialisé');
    } else {
      print('ℹ️ Firebase déjà initialisé');
    }
    
    // Configurer le handler de messages en arrière-plan
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialiser les services de l'application
    await AppBuilder.initializeServices();
    
    // Initialiser FCM (après les autres services pour avoir l'utilisateur)
    await FCMService.instance.initialize();
    
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
