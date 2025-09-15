/// Configuration Supabase pour Guinèmali
/// ⚠️ ATTENTION : Ne pas commiter ce fichier avec de vraies clés en production
class SupabaseConfig {
  // Remplacez ces valeurs par vos vraies clés Supabase
  static const String projectUrl = 'https://yhviixdwqkydmdzhzobv.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlodmlpeGR3cWt5ZG1kemh6b2J2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ3MzUxNDcsImV4cCI6MjA3MDMxMTE0N30.vK4GPn1h1ANMMjOGroDFCXcz9uLXqvURSqRqRE10-jg';
  
  // Vérification que les clés ne sont pas des placeholders
  static bool get isConfigured => 
      projectUrl != 'https://your-project.supabase.co' && 
      anonKey != 'your-anon-key';
      
  // Message d'erreur si les clés ne sont pas configurées
  static String get configurationError => 
      'Les clés Supabase ne sont pas configurées. '
      'Veuillez mettre à jour lib/core/config/supabase_config.dart';
}
