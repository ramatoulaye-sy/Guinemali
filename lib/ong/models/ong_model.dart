import 'package:flutter/foundation.dart';

/// Modèle représentant une Organisation Non Gouvernementale (ONG)
@immutable
class ONGModel {
  final String id;
  final String nom;
  final String description;
  final String logoUrl;
  final String adresse;
  final String telephone;
  final String email;
  final String siteWeb;
  final List<String> zonesIntervention;
  final List<String> typesUrgence;
  final int nombreEquipes;
  final bool actif;
  final DateTime dateCreation;
  final DateTime? dateDerniereActivite;
  final Map<String, dynamic> metadonnees;

  const ONGModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.logoUrl,
    required this.adresse,
    required this.telephone,
    required this.email,
    this.siteWeb = '',
    required this.zonesIntervention,
    required this.typesUrgence,
    required this.nombreEquipes,
    this.actif = true,
    required this.dateCreation,
    this.dateDerniereActivite,
    this.metadonnees = const {},
  });

  /// Crée une ONG depuis un JSON
  factory ONGModel.fromJson(Map<String, dynamic> json) {
    return ONGModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      description: json['description'] as String,
      logoUrl: json['logo_url'] as String? ?? '',
      adresse: json['adresse'] as String,
      telephone: json['telephone'] as String,
      email: json['email'] as String,
      siteWeb: json['site_web'] as String? ?? '',
      zonesIntervention: List<String>.from(json['zones_intervention'] ?? []),
      typesUrgence: List<String>.from(json['types_urgence'] ?? []),
      nombreEquipes: json['nombre_equipes'] as int? ?? 0,
      actif: json['actif'] as bool? ?? true,
      dateCreation: DateTime.parse(json['date_creation'] as String),
      dateDerniereActivite: json['date_derniere_activite'] != null
          ? DateTime.parse(json['date_derniere_activite'] as String)
          : null,
      metadonnees: Map<String, dynamic>.from(json['metadonnees'] ?? {}),
    );
  }

  /// Convertit l'ONG en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'logo_url': logoUrl,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
      'site_web': siteWeb,
      'zones_intervention': zonesIntervention,
      'types_urgence': typesUrgence,
      'nombre_equipes': nombreEquipes,
      'actif': actif,
      'date_creation': dateCreation.toIso8601String(),
      'date_derniere_activite': dateDerniereActivite?.toIso8601String(),
      'metadonnees': metadonnees,
    };
  }

  /// Crée une copie de l'ONG avec des modifications
  ONGModel copyWith({
    String? id,
    String? nom,
    String? description,
    String? logoUrl,
    String? adresse,
    String? telephone,
    String? email,
    String? siteWeb,
    List<String>? zonesIntervention,
    List<String>? typesUrgence,
    int? nombreEquipes,
    bool? actif,
    DateTime? dateCreation,
    DateTime? dateDerniereActivite,
    Map<String, dynamic>? metadonnees,
  }) {
    return ONGModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      siteWeb: siteWeb ?? this.siteWeb,
      zonesIntervention: zonesIntervention ?? this.zonesIntervention,
      typesUrgence: typesUrgence ?? this.typesUrgence,
      nombreEquipes: nombreEquipes ?? this.nombreEquipes,
      actif: actif ?? this.actif,
      dateCreation: dateCreation ?? this.dateCreation,
      dateDerniereActivite: dateDerniereActivite ?? this.dateDerniereActivite,
      metadonnees: metadonnees ?? this.metadonnees,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ONGModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ONGModel(id: $id, nom: $nom, actif: $actif)';
  }
}
