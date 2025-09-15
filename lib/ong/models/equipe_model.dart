import 'package:flutter/foundation.dart';

/// Statut d'une équipe de secours
enum StatutEquipe {
  disponible('Disponible'),
  enIntervention('En intervention'),
  enPause('En pause'),
  horsService('Hors service');

  const StatutEquipe(this.label);
  final String label;
}

/// Modèle représentant une équipe de secours d'une ONG
@immutable
class EquipeModel {
  final String id;
  final String ongId;
  final String nom;
  final String description;
  final List<String> membres;
  final String chefEquipe;
  final List<String> specialites;
  final List<String> zonesCouverture;
  final StatutEquipe statut;
  final DateTime? dateDerniereIntervention;
  final int nombreInterventions;
  final bool actif;
  final DateTime dateCreation;
  final Map<String, dynamic> metadonnees;

  const EquipeModel({
    required this.id,
    required this.ongId,
    required this.nom,
    required this.description,
    required this.membres,
    required this.chefEquipe,
    required this.specialites,
    required this.zonesCouverture,
    this.statut = StatutEquipe.disponible,
    this.dateDerniereIntervention,
    this.nombreInterventions = 0,
    this.actif = true,
    required this.dateCreation,
    this.metadonnees = const {},
  });

  /// Crée une équipe depuis un JSON
  factory EquipeModel.fromJson(Map<String, dynamic> json) {
    return EquipeModel(
      id: json['id'] as String,
      ongId: json['ong_id'] as String,
      nom: json['nom'] as String,
      description: json['description'] as String,
      membres: List<String>.from(json['membres'] ?? []),
      chefEquipe: json['chef_equipe'] as String,
      specialites: List<String>.from(json['specialites'] ?? []),
      zonesCouverture: List<String>.from(json['zones_couverture'] ?? []),
      statut: StatutEquipe.values.firstWhere(
        (e) => e.name == json['statut'],
        orElse: () => StatutEquipe.disponible,
      ),
      dateDerniereIntervention: json['date_derniere_intervention'] != null
          ? DateTime.parse(json['date_derniere_intervention'] as String)
          : null,
      nombreInterventions: json['nombre_interventions'] as int? ?? 0,
      actif: json['actif'] as bool? ?? true,
      dateCreation: DateTime.parse(json['date_creation'] as String),
      metadonnees: Map<String, dynamic>.from(json['metadonnees'] ?? {}),
    );
  }

  /// Convertit l'équipe en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ong_id': ongId,
      'nom': nom,
      'description': description,
      'membres': membres,
      'chef_equipe': chefEquipe,
      'specialites': specialites,
      'zones_couverture': zonesCouverture,
      'statut': statut.name,
      'date_derniere_intervention': dateDerniereIntervention?.toIso8601String(),
      'nombre_interventions': nombreInterventions,
      'actif': actif,
      'date_creation': dateCreation.toIso8601String(),
      'metadonnees': metadonnees,
    };
  }

  /// Crée une copie de l'équipe avec des modifications
  EquipeModel copyWith({
    String? id,
    String? ongId,
    String? nom,
    String? description,
    List<String>? membres,
    String? chefEquipe,
    List<String>? specialites,
    List<String>? zonesCouverture,
    StatutEquipe? statut,
    DateTime? dateDerniereIntervention,
    int? nombreInterventions,
    bool? actif,
    DateTime? dateCreation,
    Map<String, dynamic>? metadonnees,
  }) {
    return EquipeModel(
      id: id ?? this.id,
      ongId: ongId ?? this.ongId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      membres: membres ?? this.membres,
      chefEquipe: chefEquipe ?? this.chefEquipe,
      specialites: specialites ?? this.specialites,
      zonesCouverture: zonesCouverture ?? this.zonesCouverture,
      statut: statut ?? this.statut,
      dateDerniereIntervention: dateDerniereIntervention ?? this.dateDerniereIntervention,
      nombreInterventions: nombreInterventions ?? this.nombreInterventions,
      actif: actif ?? this.actif,
      dateCreation: dateCreation ?? this.dateCreation,
      metadonnees: metadonnees ?? this.metadonnees,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EquipeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EquipeModel(id: $id, nom: $nom, statut: ${statut.label})';
  }
}
