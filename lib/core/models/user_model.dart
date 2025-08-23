/// Modèle de données pour les utilisateurs de Guinèmali
/// Représente tous les types d'utilisateurs : victimes, aidants, ONG, admins
class UserModel {
  final String id;
  final String prenom;
  final String pseudo;
  final String? pinChiffre;
  final String? numTel;
  final String langue;
  final String? region;
  final UserType typeUtilisateur;
  final bool actif;
  final DateTime dateCreation;
  final DateTime? derniereConnexion;
  final bool profilComplete;

  const UserModel({
    required this.id,
    required this.prenom,
    required this.pseudo,
    this.pinChiffre,
    this.numTel,
    this.langue = 'fr',
    this.region,
    required this.typeUtilisateur,
    this.actif = true,
    required this.dateCreation,
    this.derniereConnexion,
    this.profilComplete = false,
  });

  /// Crée un UserModel à partir des données JSON de Supabase
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      prenom: json['prenom'] as String,
      pseudo: json['pseudo'] as String,
      pinChiffre: json['pin_chiffre'] as String?,
      numTel: json['num_tel'] as String?,
      langue: json['langue'] as String? ?? 'fr',
      region: json['region'] as String?,
      typeUtilisateur: UserType.fromString(json['type_utilisateur'] as String),
      actif: json['actif'] as bool? ?? true,
      dateCreation: DateTime.parse(json['date_creation'] as String),
      derniereConnexion: json['derniere_connexion'] != null
          ? DateTime.parse(json['derniere_connexion'] as String)
          : null,
      profilComplete: json['profil_complete'] as bool? ?? false,
    );
  }

  /// Convertit le UserModel en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prenom': prenom,
      'pseudo': pseudo,
      'pin_chiffre': pinChiffre,
      'num_tel': numTel,
      'langue': langue,
      'region': region,
      'type_utilisateur': typeUtilisateur.value,
      'actif': actif,
      'date_creation': dateCreation.toIso8601String(),
      'derniere_connexion': derniereConnexion?.toIso8601String(),
      'profil_complete': profilComplete,
    };
  }

  /// Crée une copie du UserModel avec des modifications
  UserModel copyWith({
    String? id,
    String? prenom,
    String? pseudo,
    String? pinChiffre,
    String? numTel,
    String? langue,
    String? region,
    UserType? typeUtilisateur,
    bool? actif,
    DateTime? dateCreation,
    DateTime? derniereConnexion,
    bool? profilComplete,
  }) {
    return UserModel(
      id: id ?? this.id,
      prenom: prenom ?? this.prenom,
      pseudo: pseudo ?? this.pseudo,
      pinChiffre: pinChiffre ?? this.pinChiffre,
      numTel: numTel ?? this.numTel,
      langue: langue ?? this.langue,
      region: region ?? this.region,
      typeUtilisateur: typeUtilisateur ?? this.typeUtilisateur,
      actif: actif ?? this.actif,
      dateCreation: dateCreation ?? this.dateCreation,
      derniereConnexion: derniereConnexion ?? this.derniereConnexion,
      profilComplete: profilComplete ?? this.profilComplete,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, prenom: $prenom, pseudo: $pseudo, type: ${typeUtilisateur.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Énumération des types d'utilisateurs
enum UserType {
  victime('victime'),
  aidant('aidant'),
  ong('ong'),
  admin('admin');

  const UserType(this.value);

  final String value;

  /// Convertit une chaîne en UserType
  static UserType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'victime':
        return UserType.victime;
      case 'aidant':
        return UserType.aidant;
      case 'ong':
        return UserType.ong;
      case 'admin':
        return UserType.admin;
      default:
        throw ArgumentError('Type d\'utilisateur non reconnu: $value');
    }
  }

  /// Retourne le nom d'affichage du type d'utilisateur
  String get displayName {
    switch (this) {
      case UserType.victime:
        return 'Personne à protéger';
      case UserType.aidant:
        return 'Aidant bénévole';
      case UserType.ong:
        return 'ONG/Organisation';
      case UserType.admin:
        return 'Administrateur';
    }
  }

  /// Retourne la description du type d'utilisateur
  String get description {
    switch (this) {
      case UserType.victime:
        return 'Femme ou jeune fille cherchant protection et soutien';
      case UserType.aidant:
        return 'Personne volontaire pour aider en cas d\'urgence';
      case UserType.ong:
        return 'Organisation de soutien aux femmes et filles';
      case UserType.admin:
        return 'Gestionnaire de la plateforme';
    }
  }
}


