import 'user_model.dart';

/// Modèle de données pour la connexion
class LoginData {
  final String prenom;
  final String pin;

  const LoginData({
    required this.prenom,
    required this.pin,
  });

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'prenom': prenom,
      'pin': pin,
    };
  }

  /// Validation des données
  List<String> validate() {
    List<String> errors = [];

    if (prenom.trim().isEmpty) {
      errors.add('Le prénom est requis');
    }

    if (pin.trim().isEmpty) {
      errors.add('Le PIN est requis');
    } else if (pin.length < 4) {
      errors.add('Le PIN doit contenir au moins 4 chiffres');
    }

    return errors;
  }
}

/// Modèle de données pour l'inscription
class RegistrationData {
  final String prenom;
  final String pseudo; // Ajout du champ pseudo
  final String pin;
  final String numTel;
  final UserType typeUtilisateur;
  final String? langue;
  final String? region;

  const RegistrationData({
    required this.prenom,
    required this.pseudo, // Ajout du paramètre pseudo
    required this.pin,
    required this.numTel,
    required this.typeUtilisateur,
    this.langue,
    this.region,
  });

  /// Convertit en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'prenom': prenom,
      'pseudo': pseudo, // Ajout du champ pseudo
      'num_tel': numTel,
      'type_utilisateur': typeUtilisateur.value,
      'langue': langue ?? 'fr',
      'region': region,
      'actif': true,
      'date_creation': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Validation des données
  List<String> validate() {
    List<String> errors = [];

    // Validation du prénom
    if (prenom.trim().isEmpty) {
      errors.add('Le prénom est requis');
    } else if (prenom.length < 2) {
      errors.add('Le prénom doit contenir au moins 2 caractères');
    } else if (prenom.length > 30) {
      errors.add('Le prénom ne doit pas dépasser 30 caractères');
    } else if (!RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(prenom)) {
      errors.add('Le prénom ne peut contenir que des lettres et espaces');
    }

    // Validation du PIN
    if (pin.trim().isEmpty) {
      errors.add('Le PIN est requis');
    } else if (pin.length < 4) {
      errors.add('Le PIN doit contenir au moins 4 chiffres');
    } else if (pin.length > 8) {
      errors.add('Le PIN ne doit pas dépasser 8 chiffres');
    } else if (!RegExp(r'^\d+$').hasMatch(pin)) {
      errors.add('Le PIN ne doit contenir que des chiffres');
    }

    // Validation du numéro de téléphone
    if (numTel.trim().isEmpty) {
      errors.add('Le numéro de téléphone est requis');
    } else {
      final cleanPhone = numTel.replaceAll(RegExp(r'[^\d+]'), '');
      if (cleanPhone.length < 8) {
        errors.add('Numéro de téléphone invalide');
      }
    }

    return errors;
  }

  /// Crée une copie avec des modifications
  RegistrationData copyWith({
    String? prenom,
    String? pseudo, // Ajout du paramètre pseudo
    String? pin,
    String? numTel,
    UserType? typeUtilisateur,
    String? langue,
    String? region,
  }) {
    return RegistrationData(
      prenom: prenom ?? this.prenom,
      pseudo: pseudo ?? this.pseudo, // Ajout du paramètre pseudo
      pin: pin ?? this.pin,
      numTel: numTel ?? this.numTel,
      typeUtilisateur: typeUtilisateur ?? this.typeUtilisateur,
      langue: langue ?? this.langue,
      region: region ?? this.region,
    );
  }
}

/// Modèle de réponse d'authentification
class AuthResponse {
  final UserModel user;
  final String? token;
  final bool isNewUser;

  const AuthResponse({
    required this.user,
    this.token,
    this.isNewUser = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      token: json['token'] as String?,
      isNewUser: json['is_new_user'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'is_new_user': isNewUser,
    };
  }
}

/// Modèle d'erreur d'authentification
class AuthError {
  final String code;
  final String message;
  final String? details;

  const AuthError({
    required this.code,
    required this.message,
    this.details,
  });

  factory AuthError.fromException(Exception exception) {
    final message = exception.toString();
    
    if (message.contains('Invalid login credentials')) {
      return const AuthError(
        code: 'invalid_credentials',
        message: 'Identifiants incorrects',
      );
    } else if (message.contains('Email already registered')) {
      return const AuthError(
        code: 'email_exists',
        message: 'Cet email est déjà utilisé',
      );
    } else if (message.contains('pseudo')) {
      return const AuthError(
        code: 'pseudo_exists',
        message: 'Ce pseudo est déjà utilisé',
      );
    }

    return AuthError(
      code: 'unknown_error',
      message: 'Une erreur inattendue s\'est produite',
      details: message,
    );
  }

  @override
  String toString() => message;
}
