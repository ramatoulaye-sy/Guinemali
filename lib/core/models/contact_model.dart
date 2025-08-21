/// Modèle de données pour les contacts d'urgence
class ContactModel {
  final String id;
  final String utilisateurId;
  final String nom;
  final String numeroTelephone;
  final String? relation;
  final int priorite;
  final bool actif;
  final DateTime dateAjout;

  const ContactModel({
    required this.id,
    required this.utilisateurId,
    required this.nom,
    required this.numeroTelephone,
    this.relation,
    this.priorite = 1,
    this.actif = true,
    required this.dateAjout,
  });

  /// Crée un ContactModel à partir des données JSON de Supabase
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      utilisateurId: json['utilisateur_id'] as String,
      nom: json['nom'] as String,
      numeroTelephone: json['numero_telephone'] as String,
      relation: json['relation'] as String?,
      priorite: json['priorite'] as int? ?? 1,
      actif: json['actif'] as bool? ?? true,
      dateAjout: DateTime.parse(json['date_ajout'] as String),
    );
  }

  /// Convertit le ContactModel en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'utilisateur_id': utilisateurId,
      'nom': nom,
      'numero_telephone': numeroTelephone,
      'relation': relation,
      'priorite': priorite,
      'actif': actif,
      'date_ajout': dateAjout.toIso8601String(),
    };
  }

  /// Crée une copie du ContactModel avec des modifications
  ContactModel copyWith({
    String? id,
    String? utilisateurId,
    String? nom,
    String? numeroTelephone,
    String? relation,
    int? priorite,
    bool? actif,
    DateTime? dateAjout,
  }) {
    return ContactModel(
      id: id ?? this.id,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      nom: nom ?? this.nom,
      numeroTelephone: numeroTelephone ?? this.numeroTelephone,
      relation: relation ?? this.relation,
      priorite: priorite ?? this.priorite,
      actif: actif ?? this.actif,
      dateAjout: dateAjout ?? this.dateAjout,
    );
  }

  /// Retourne le nom d'affichage avec la relation
  String get displayName {
    if (relation != null && relation!.isNotEmpty) {
      return '$nom ($relation)';
    }
    return nom;
  }

  /// Formate le numéro de téléphone pour l'affichage
  String get formattedPhone {
    String phone = numeroTelephone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Format pour les numéros guinéens (+224)
    if (phone.startsWith('+224') && phone.length == 13) {
      return '+224 ${phone.substring(4, 7)} ${phone.substring(7, 9)} ${phone.substring(9, 11)} ${phone.substring(11)}';
    }
    
    // Format général
    if (phone.length >= 8) {
      return phone.replaceAllMapped(
        RegExp(r'(\+?\d{1,3})?(\d{2,3})(\d{2,3})(\d{2,4})'),
        (match) => '${match.group(1) ?? ''} ${match.group(2)} ${match.group(3)} ${match.group(4)}',
      ).trim();
    }
    
    return phone;
  }

  @override
  String toString() {
    return 'ContactModel(id: $id, nom: $nom, priorite: $priorite)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types de relations prédéfinies
enum ContactRelation {
  famille('famille'),
  ami('ami'),
  collegue('collegue'),
  voisin('voisin'),
  professionnel('professionnel'),
  autre('autre');

  const ContactRelation(this.value);

  final String value;

  static ContactRelation? fromString(String? value) {
    if (value == null) return null;
    
    switch (value.toLowerCase()) {
      case 'famille':
        return ContactRelation.famille;
      case 'ami':
        return ContactRelation.ami;
      case 'collegue':
      case 'collègue':
        return ContactRelation.collegue;
      case 'voisin':
        return ContactRelation.voisin;
      case 'professionnel':
        return ContactRelation.professionnel;
      case 'autre':
        return ContactRelation.autre;
      default:
        return ContactRelation.autre;
    }
  }

  String get displayName {
    switch (this) {
      case ContactRelation.famille:
        return 'Famille';
      case ContactRelation.ami:
        return 'Ami(e)';
      case ContactRelation.collegue:
        return 'Collègue';
      case ContactRelation.voisin:
        return 'Voisin(e)';
      case ContactRelation.professionnel:
        return 'Professionnel';
      case ContactRelation.autre:
        return 'Autre';
    }
  }

  String get iconName {
    switch (this) {
      case ContactRelation.famille:
        return 'family_restroom';
      case ContactRelation.ami:
        return 'people';
      case ContactRelation.collegue:
        return 'work';
      case ContactRelation.voisin:
        return 'home';
      case ContactRelation.professionnel:
        return 'business';
      case ContactRelation.autre:
        return 'person';
    }
  }
}

/// Niveaux de priorité pour les contacts
enum ContactPriority {
  haute(1),
  moyenne(2),
  basse(3);

  const ContactPriority(this.value);

  final int value;

  static ContactPriority fromInt(int value) {
    switch (value) {
      case 1:
        return ContactPriority.haute;
      case 2:
        return ContactPriority.moyenne;
      case 3:
        return ContactPriority.basse;
      default:
        return ContactPriority.moyenne;
    }
  }

  String get displayName {
    switch (this) {
      case ContactPriority.haute:
        return 'Priorité haute';
      case ContactPriority.moyenne:
        return 'Priorité moyenne';
      case ContactPriority.basse:
        return 'Priorité basse';
    }
  }

  String get description {
    switch (this) {
      case ContactPriority.haute:
        return 'Contact alerté en premier';
      case ContactPriority.moyenne:
        return 'Contact alerté si priorité haute indisponible';
      case ContactPriority.basse:
        return 'Contact alerté en dernier recours';
    }
  }

  String get colorHex {
    switch (this) {
      case ContactPriority.haute:
        return '#FF0000'; // Rouge
      case ContactPriority.moyenne:
        return '#FFA500'; // Orange
      case ContactPriority.basse:
        return '#008000'; // Vert
    }
  }
}

/// Modèle pour créer un nouveau contact
class CreateContactModel {
  final String nom;
  final String numeroTelephone;
  final String? relation;
  final int priorite;

  const CreateContactModel({
    required this.nom,
    required this.numeroTelephone,
    this.relation,
    this.priorite = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'numero_telephone': numeroTelephone,
      'relation': relation,
      'priorite': priorite,
      'actif': true,
    };
  }

  /// Valide les données du contact
  List<String> validate() {
    List<String> errors = [];

    if (nom.trim().isEmpty) {
      errors.add('Le nom est requis');
    }

    if (numeroTelephone.trim().isEmpty) {
      errors.add('Le numéro de téléphone est requis');
    } else if (!isValidPhoneNumber(numeroTelephone)) {
      errors.add('Format de numéro de téléphone invalide');
    }

    if (priorite < 1 || priorite > 3) {
      errors.add('La priorité doit être entre 1 et 3');
    }

    return errors;
  }

  /// Valide le format du numéro de téléphone
  static bool isValidPhoneNumber(String phone) {
    // Supprime tous les caractères non numériques sauf le +
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Vérifie les formats acceptés
    return RegExp(r'^\+?[\d]{8,15}$').hasMatch(cleanPhone);
  }
}

/// Modèle pour les statistiques des contacts
class ContactStatistics {
  final int nombreContactsTotal;
  final int nombreContactsActifs;
  final Map<String, int> contactsParRelation;
  final Map<int, int> contactsParPriorite;

  const ContactStatistics({
    required this.nombreContactsTotal,
    required this.nombreContactsActifs,
    required this.contactsParRelation,
    required this.contactsParPriorite,
  });

  factory ContactStatistics.fromContacts(List<ContactModel> contacts) {
    final actifs = contacts.where((c) => c.actif).toList();
    
    Map<String, int> parRelation = {};
    Map<int, int> parPriorite = {1: 0, 2: 0, 3: 0};

    for (final contact in actifs) {
      // Compter par relation
      final relation = contact.relation ?? 'autre';
      parRelation[relation] = (parRelation[relation] ?? 0) + 1;

      // Compter par priorité
      parPriorite[contact.priorite] = (parPriorite[contact.priorite] ?? 0) + 1;
    }

    return ContactStatistics(
      nombreContactsTotal: contacts.length,
      nombreContactsActifs: actifs.length,
      contactsParRelation: parRelation,
      contactsParPriorite: parPriorite,
    );
  }

  /// Vérifie si le maximum de contacts est atteint
  bool get maxContactsReached => nombreContactsActifs >= 3;

  /// Retourne le pourcentage de contacts actifs
  double get pourcentageActifs {
    if (nombreContactsTotal == 0) return 0;
    return (nombreContactsActifs / nombreContactsTotal) * 100;
  }
}
