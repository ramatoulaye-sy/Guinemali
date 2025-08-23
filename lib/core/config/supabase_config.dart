/// Configuration Supabase pour l'application Guinemali
/// 
/// IMPORTANT: Remplacez ces valeurs par vos vraies clés Supabase
/// Vous pouvez obtenir ces informations depuis votre dashboard Supabase:
/// 1. Allez sur https://supabase.com/dashboard
/// 2. Sélectionnez votre projet
/// 3. Allez dans Settings > API
/// 4. Copiez l'URL et la clé anon/public

class SupabaseConfig {
  // URL de votre projet Supabase
  // REMPLACEZ cette valeur par votre vraie URL Supabase
  static const String url = 'https://yhviixdwqkydmdzhzobv.supabase.co';
  
  // Clé anonyme de votre projet Supabase
  // REMPLACEZ cette valeur par votre vraie clé anon
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlodmlpeGR3cWt5ZG1kemh6b2J2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ3MzUxNDcsImV4cCI6MjA3MDMxMTE0N30.vK4GPn1h1ANMMjOGroDFCXcz9uLXqvURSqRqRE10-jg';
  
  // Vérification de la configuration
  static bool get isConfigured {
    return url != 'https://your-project.supabase.co' && 
           anonKey != 'your-anon-key';
  }
  
  // Message d'erreur si la configuration est manquante
  static String get configurationError {
    if (!isConfigured) {
      return '''
⚠️ Configuration Supabase manquante!

Pour résoudre ce problème:

1. Créez un projet sur https://supabase.com
2. Allez dans Settings > API de votre projet
3. Copiez l'URL et la clé anon
4. Modifiez ce fichier (lib/core/config/supabase_config.dart) avec vos vraies valeurs:

   static const String url = 'https://votre-projet.supabase.co';
   static const String anonKey = 'votre-cle-anon-ici';

5. Redémarrez l'application

Exemple de configuration:
   static const String url = 'https://abcdefghijklmnop.supabase.co';
   static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
''';
    }
    return '';
  }
  
  // Instructions détaillées pour la configuration
  static String get setupInstructions => '''
🔧 Configuration Supabase - Guide étape par étape:

1. Créez un compte sur https://supabase.com
2. Créez un nouveau projet
3. Attendez que le projet soit prêt (cela peut prendre quelques minutes)
4. Allez dans Settings > API
5. Copiez l'URL du projet (Project URL)
6. Copiez la clé anon/public (anon/public key)
7. Modifiez ce fichier avec vos vraies valeurs
8. Redémarrez l'application

Tables nécessaires dans votre base Supabase:
- utilisateurs (id, email, pseudo, type_utilisateur, etc.)
- alertes (id, utilisateur_id, statut, position, etc.)
- contacts_urgence (id, utilisateur_id, nom, telephone, etc.)
- preuves (id, alerte_id, type, fichier_url, etc.)

Vous pouvez utiliser les scripts SQL fournis dans le dossier databases/ pour créer ces tables.
''';
}
