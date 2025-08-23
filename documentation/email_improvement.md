# Amélioration de la Génération d'Emails Uniques

## Problème Actuel
L'email temporaire `@gmail.com` peut causer des conflits si plusieurs utilisateurs ont le même prénom.

## Solutions Recommandées

### Option 1: Email avec Timestamp (Recommandée)
```dart
String generateUniqueEmail(String prenom) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final sanitizedPrenom = prenom.toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  return '${sanitizedPrenom}_$timestamp@gmail.com';
}
```

### Option 2: Email avec UUID
```dart
String generateUniqueEmail(String prenom) {
  final uuid = const Uuid().v4().substring(0, 8);
  final sanitizedPrenom = prenom.toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  return '${sanitizedPrenom}_$uuid@gmail.com';
}
```

### Option 3: Email avec Hash
```dart
String generateUniqueEmail(String prenom, String pin) {
  final hash = sha256.convert(utf8.encode('$prenom$pin')).toString().substring(0, 8);
  final sanitizedPrenom = prenom.toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  return '${sanitizedPrenom}_$hash@gmail.com';
}
```

## Implémentation dans AuthService

```dart
// Dans lib/core/services/auth_service.dart
String _generateUniqueEmail(String prenom) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final sanitizedPrenom = prenom.toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  return '${sanitizedPrenom}_$timestamp@gmail.com';
}

// Utilisation dans register()
final tempEmail = _generateUniqueEmail(registrationData.prenom);
```

## Avantages
- ✅ Emails uniques garantis
- ✅ Pas de conflits entre utilisateurs
- ✅ Traçabilité avec timestamp
- ✅ Compatible avec Supabase Auth

## Note Importante
Ces emails sont temporaires et servent uniquement à l'authentification Supabase.
L'utilisateur n'a pas besoin de se souvenir de cet email.
