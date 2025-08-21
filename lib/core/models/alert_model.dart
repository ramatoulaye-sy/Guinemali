/// Modèle de données pour les alertes d'urgence
class AlertModel {
  final String id;
  final String utilisateurId;
  final double? latitude;
  final double? longitude;
  final String? adresseApproximative;
  final DateTime timestamp;
  final AlertStatus statut;
  final AlertType typeAlerte;
  final int niveauDanger;
  final int nombreAidantsNotifies;
  final DateTime? dateResolution;
  final String? notesResolution;

  const AlertModel({
    required this.id,
    required this.utilisateurId,
    this.latitude,
    this.longitude,
    this.adresseApproximative,
    required this.timestamp,
    this.statut = AlertStatus.active,
    this.typeAlerte = AlertType.urgence,
    this.niveauDanger = 3,
    this.nombreAidantsNotifies = 0,
    this.dateResolution,
    this.notesResolution,
  });

  /// Crée un AlertModel à partir des données JSON de Supabase
  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      utilisateurId: json['utilisateur_id'] as String,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      adresseApproximative: json['adresse_approximative'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      statut: AlertStatus.fromString(json['statut'] as String),
      typeAlerte: AlertType.fromString(json['type_alerte'] as String),
      niveauDanger: json['niveau_danger'] as int? ?? 3,
      nombreAidantsNotifies: json['nombre_aidants_notifies'] as int? ?? 0,
      dateResolution: json['date_resolution'] != null
          ? DateTime.parse(json['date_resolution'] as String)
          : null,
      notesResolution: json['notes_resolution'] as String?,
    );
  }

  /// Convertit l'AlertModel en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'utilisateur_id': utilisateurId,
      'latitude': latitude,
      'longitude': longitude,
      'adresse_approximative': adresseApproximative,
      'timestamp': timestamp.toIso8601String(),
      'statut': statut.value,
      'type_alerte': typeAlerte.value,
      'niveau_danger': niveauDanger,
      'nombre_aidants_notifies': nombreAidantsNotifies,
      'date_resolution': dateResolution?.toIso8601String(),
      'notes_resolution': notesResolution,
    };
  }

  /// Crée une copie de l'AlertModel avec des modifications
  AlertModel copyWith({
    String? id,
    String? utilisateurId,
    double? latitude,
    double? longitude,
    String? adresseApproximative,
    DateTime? timestamp,
    AlertStatus? statut,
    AlertType? typeAlerte,
    int? niveauDanger,
    int? nombreAidantsNotifies,
    DateTime? dateResolution,
    String? notesResolution,
  }) {
    return AlertModel(
      id: id ?? this.id,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      adresseApproximative: adresseApproximative ?? this.adresseApproximative,
      timestamp: timestamp ?? this.timestamp,
      statut: statut ?? this.statut,
      typeAlerte: typeAlerte ?? this.typeAlerte,
      niveauDanger: niveauDanger ?? this.niveauDanger,
      nombreAidantsNotifies: nombreAidantsNotifies ?? this.nombreAidantsNotifies,
      dateResolution: dateResolution ?? this.dateResolution,
      notesResolution: notesResolution ?? this.notesResolution,
    );
  }

  /// Vérifie si l'alerte est active
  bool get isActive => statut == AlertStatus.active;

  /// Vérifie si l'alerte est résolue
  bool get isResolved => statut == AlertStatus.resolue;

  /// Retourne la durée depuis le déclenchement
  Duration get dureeDepuisDeclenchement => DateTime.now().difference(timestamp);

  /// Vérifie si l'alerte a une localisation
  bool get hasLocation => latitude != null && longitude != null;

  @override
  String toString() {
    return 'AlertModel(id: $id, statut: ${statut.value}, type: ${typeAlerte.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlertModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// États possibles d'une alerte
enum AlertStatus {
  active('active'),
  resolue('resolue'),
  fausseAlerte('fausse_alerte'),
  enCours('en_cours');

  const AlertStatus(this.value);

  final String value;

  static AlertStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return AlertStatus.active;
      case 'resolue':
        return AlertStatus.resolue;
      case 'fausse_alerte':
        return AlertStatus.fausseAlerte;
      case 'en_cours':
        return AlertStatus.enCours;
      default:
        throw ArgumentError('Statut d\'alerte non reconnu: $value');
    }
  }

  String get displayName {
    switch (this) {
      case AlertStatus.active:
        return 'Active';
      case AlertStatus.resolue:
        return 'Résolue';
      case AlertStatus.fausseAlerte:
        return 'Fausse alerte';
      case AlertStatus.enCours:
        return 'En cours';
    }
  }

  /// Couleur associée au statut
  String get colorHex {
    switch (this) {
      case AlertStatus.active:
        return '#FF0000'; // Rouge
      case AlertStatus.resolue:
        return '#00FF00'; // Vert
      case AlertStatus.fausseAlerte:
        return '#FFA500'; // Orange
      case AlertStatus.enCours:
        return '#FFFF00'; // Jaune
    }
  }
}

/// Types d'alertes
enum AlertType {
  urgence('urgence'),
  suivi('suivi'),
  harcelement('harcèlement'),
  agression('agression');

  const AlertType(this.value);

  final String value;

  static AlertType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'urgence':
        return AlertType.urgence;
      case 'suivi':
        return AlertType.suivi;
      case 'harcèlement':
      case 'harcelement':
        return AlertType.harcelement;
      case 'agression':
        return AlertType.agression;
      default:
        throw ArgumentError('Type d\'alerte non reconnu: $value');
    }
  }

  String get displayName {
    switch (this) {
      case AlertType.urgence:
        return 'Urgence';
      case AlertType.suivi:
        return 'Suivi suspect';
      case AlertType.harcelement:
        return 'Harcèlement';
      case AlertType.agression:
        return 'Agression';
    }
  }

  String get description {
    switch (this) {
      case AlertType.urgence:
        return 'Situation de danger immédiat';
      case AlertType.suivi:
        return 'Personne suspecte qui suit';
      case AlertType.harcelement:
        return 'Harcèlement verbal ou gestuel';
      case AlertType.agression:
        return 'Agression physique en cours';
    }
  }

  /// Icône suggérée pour le type d'alerte
  String get iconName {
    switch (this) {
      case AlertType.urgence:
        return 'emergency';
      case AlertType.suivi:
        return 'visibility';
      case AlertType.harcelement:
        return 'record_voice_over';
      case AlertType.agression:
        return 'warning';
    }
  }
}

/// Modèle pour créer une nouvelle alerte
class CreateAlertModel {
  final double? latitude;
  final double? longitude;
  final AlertType typeAlerte;
  final int niveauDanger;
  final String? adresseApproximative;

  const CreateAlertModel({
    this.latitude,
    this.longitude,
    this.typeAlerte = AlertType.urgence,
    this.niveauDanger = 3,
    this.adresseApproximative,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'type_alerte': typeAlerte.value,
      'niveau_danger': niveauDanger,
      'adresse_approximative': adresseApproximative,
    };
  }
}

/// Modèle pour les statistiques d'alertes
class AlertStatistics {
  final int nombreAlertesTotal;
  final int nombreAlertesActives;
  final int nombreAlertesResolues;
  final DateTime? derniereAlerte;
  final int nombrePreuves;

  const AlertStatistics({
    required this.nombreAlertesTotal,
    required this.nombreAlertesActives,
    required this.nombreAlertesResolues,
    this.derniereAlerte,
    required this.nombrePreuves,
  });

  factory AlertStatistics.fromJson(Map<String, dynamic> json) {
    return AlertStatistics(
      nombreAlertesTotal: json['nombre_alertes_total'] as int,
      nombreAlertesActives: json['nombre_alertes_actives'] as int,
      nombreAlertesResolues: json['nombre_alertes_resolues'] as int,
      derniereAlerte: json['derniere_alerte'] != null
          ? DateTime.parse(json['derniere_alerte'] as String)
          : null,
      nombrePreuves: json['nombre_preuves'] as int,
    );
  }
}
