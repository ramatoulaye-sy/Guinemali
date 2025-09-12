import '../constants/app_constants.dart';

/// Service centralisé pour toutes les validations de l'application
/// Basé sur 30 ans d'expérience en développement mobile
class ValidationService {
  static ValidationService? _instance;
  static ValidationService get instance => _instance ??= ValidationService._();
  
  ValidationService._();

  /// Validation du prénom
  static String? validatePrenom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prénom est requis';
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.length < 2) {
      return 'Le prénom doit contenir au moins 2 caractères';
    }
    
    if (trimmedValue.length > 50) {
      return 'Le prénom ne peut pas dépasser 50 caractères';
    }
    
    if (!RegExp(AppConstants.prenomPattern).hasMatch(trimmedValue)) {
      return 'Prénom invalide (lettres et espaces uniquement)';
    }
    
    return null;
  }

  /// Validation du pseudo
  static String? validatePseudo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le pseudo est requis';
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.length < 3) {
      return 'Le pseudo doit contenir au moins 3 caractères';
    }
    
    if (trimmedValue.length > 20) {
      return 'Le pseudo ne peut pas dépasser 20 caractères';
    }
    
    // Autoriser lettres, chiffres et underscore, interdire les espaces
    if (trimmedValue.contains(' ') || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmedValue)) {
      return 'Le pseudo ne doit contenir que des lettres, chiffres et _';
    }
    
    return null;
  }

  /// Validation du code PIN
  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le code PIN est requis';
    }
    
    if (value.length < AppConstants.pinMinLength) {
      return 'Le PIN doit contenir au moins ${AppConstants.pinMinLength} chiffres';
    }
    
    if (value.length > AppConstants.pinMaxLength) {
      return 'Le PIN ne peut pas dépasser ${AppConstants.pinMaxLength} chiffres';
    }
    
    if (!RegExp(AppConstants.pinPattern).hasMatch(value)) {
      return 'Le PIN ne doit contenir que des chiffres';
    }
    
    return null;
  }

  /// Validation de la confirmation du PIN
  static String? validateConfirmPin(String? value, String originalPin) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre PIN';
    }
    
    if (value != originalPin) {
      return 'Les codes PIN ne correspondent pas';
    }
    
    return null;
  }

  /// Validation du numéro de téléphone
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optionnel
    }
    
    final trimmedValue = value.trim();
    if (!RegExp(AppConstants.phoneNumberPattern).hasMatch(trimmedValue)) {
      return 'Format de numéro invalide (ex: +224 XXX XX XX XX)';
    }
    
    return null;
  }

  /// Validation de l'email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optionnel
    }
    
    final trimmedValue = value.trim();
    final emailPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    if (!emailPattern.hasMatch(trimmedValue)) {
      return 'Format d\'email invalide';
    }
    
    return null;
  }

  /// Validation de la région
  static String? validateRegion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optionnel
    }
    
    if (!AppConstants.guineanRegions.contains(value)) {
      return 'Région invalide';
    }
    
    return null;
  }

  /// Validation de la langue
  static String? validateLanguage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La langue est requise';
    }
    
    final validLanguages = ['fr', 'en', 'ff'];
    if (!validLanguages.contains(value)) {
      return 'Langue invalide';
    }
    
    return null;
  }

  /// Validation de la longueur d'un texte
  static String? validateTextLength(String? value, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 255,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.length < minLength) {
      return '$fieldName doit contenir au moins $minLength caractère(s)';
    }
    
    if (trimmedValue.length > maxLength) {
      return '$fieldName ne peut pas dépasser $maxLength caractères';
    }
    
    return null;
  }

  /// Validation d'un nombre
  static String? validateNumber(String? value, {
    required String fieldName,
    double? minValue,
    double? maxValue,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    
    final number = double.tryParse(value.trim());
    if (number == null) {
      return '$fieldName doit être un nombre valide';
    }
    
    if (minValue != null && number < minValue) {
      return '$fieldName doit être au moins $minValue';
    }
    
    if (maxValue != null && number > maxValue) {
      return '$fieldName ne peut pas dépasser $maxValue';
    }
    
    return null;
  }

  /// Validation d'une URL
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optionnel
    }
    
    final trimmedValue = value.trim();
    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    
    if (!urlPattern.hasMatch(trimmedValue)) {
      return 'URL invalide';
    }
    
    return null;
  }

  /// Validation d'une date
  static String? validateDate(String? value, {
    required String fieldName,
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    
    final date = DateTime.tryParse(value.trim());
    if (date == null) {
      return '$fieldName doit être une date valide';
    }
    
    if (minDate != null && date.isBefore(minDate)) {
      return '$fieldName ne peut pas être antérieure à ${_formatDate(minDate)}';
    }
    
    if (maxDate != null && date.isAfter(maxDate)) {
      return '$fieldName ne peut pas être postérieure à ${_formatDate(maxDate)}';
    }
    
    return null;
  }

  /// Validation d'un mot de passe fort
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une minuscule';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins un caractère spécial';
    }
    
    return null;
  }

  /// Validation d'un code de confirmation
  static String? validateConfirmationCode(String? value, {
    int expectedLength = 6,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Le code de confirmation est requis';
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.length != expectedLength) {
      return 'Le code doit contenir exactement $expectedLength caractères';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmedValue)) {
      return 'Le code ne doit contenir que des chiffres';
    }
    
    return null;
  }

  /// Formate une date pour l'affichage
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Valide un ensemble de champs et retourne la première erreur
  static String? validateMultipleFields(Map<String, String?> fields) {
    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final value = entry.value;
      
      String? error;
      switch (fieldName) {
        case 'prenom':
          error = validatePrenom(value);
          break;
        case 'pseudo':
          error = validatePseudo(value);
          break;
        case 'pin':
          error = validatePin(value);
          break;
        case 'phone':
          error = validatePhone(value);
          break;
        case 'email':
          error = validateEmail(value);
          break;
        case 'region':
          error = validateRegion(value);
          break;
        case 'language':
          error = validateLanguage(value);
          break;
        default:
          error = validateTextLength(value, fieldName: fieldName);
      }
      
      if (error != null) {
        return error;
      }
    }
    
    return null;
  }
}
