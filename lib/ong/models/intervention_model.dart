import 'package:flutter/foundation.dart';

/// Priorité d'une intervention
enum PrioriteIntervention {
  urgente('Urgente', 1),
  importante('Importante', 2),
  normale('Normale', 3);

  const PrioriteIntervention(this.label, this.niveau);
  final String label;
  final int niveau;
}

/// Statut d'une intervention
enum StatutIntervention {
  enAttente('En attente'),
  enCours('En cours'),
  terminee('Terminée'),
  annulee('Annulée');

  const StatutIntervention(this.label);
  final String label;
}

/// Modèle représentant une intervention d'urgence
@immutable
class InterventionModel {
  final String id;
  final String alerteId;
  final String ongId;
  final String? equipeId;
  final String description;
  final PrioriteIntervention priorite;
  final StatutIntervention statut;
  final String localisation;
  final double latitude;
  final double longitude;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final List<String> membresIntervention;
  final String? rapportIntervention;
  final Map<String, dynamic> metadonnees;

  const InterventionModel({
    required this.id,
    required this.alerteId,
    required this.ongId,
    this.equipeId,
    required this.description,
    required this.priorite,
    this.statut = StatutIntervention.enAttente,
    required this.localisation,
    required this.latitude,
    required this.longitude,
    required this.dateDebut,
    this.dateFin,
    this.membresIntervention = const [],
    this.rapportIntervention,
    this.metadonnees = const {},
  });

  /// Crée une intervention depuis un JSON
  factory InterventionModel.fromJson(Map<String, dynamic> json) {
    return InterventionModel(
      id: json['id'] as String,
      alerteId: json['alerte_id'] as String,
      ongId: json['ong_id'] as String,
      equipeId: json['equipe_id'] as String?,
      description: json['description'] as String,
      priorite: PrioriteIntervention.values.firstWhere(
        (e) => e.name == json['priorite'],
        orElse: () => PrioriteIntervention.normale,
      ),
      statut: StatutIntervention.values.firstWhere(
        (e) => e.name == json['statut'],
        orElse: () => StatutIntervention.enAttente,
      ),
      localisation: json['localisation'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateFin: json['date_fin'] != null
          ? DateTime.parse(json['date_fin'] as String)
          : null,
      membresIntervention: List<String>.from(json['membres_intervention'] ?? []),
      rapportIntervention: json['rapport_intervention'] as String?,
      metadonnees: Map<String, dynamic>.from(json['metadonnees'] ?? {}),
    );
  }

  /// Convertit l'intervention en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alerte_id': alerteId,
      'ong_id': ongId,
      'equipe_id': equipeId,
      'description': description,
      'priorite': priorite.name,
      'statut': statut.name,
      'localisation': localisation,
      'latitude': latitude,
      'longitude': longitude,
      'date_debut': dateDebut.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'membres_intervention': membresIntervention,
      'rapport_intervention': rapportIntervention,
      'metadonnees': metadonnees,
    };
  }

  /// Crée une copie de l'intervention avec des modifications
  InterventionModel copyWith({
    String? id,
    String? alerteId,
    String? ongId,
    String? equipeId,
    String? description,
    PrioriteIntervention? priorite,
    StatutIntervention? statut,
    String? localisation,
    double? latitude,
    double? longitude,
    DateTime? dateDebut,
    DateTime? dateFin,
    List<String>? membresIntervention,
    String? rapportIntervention,
    Map<String, dynamic>? metadonnees,
  }) {
    return InterventionModel(
      id: id ?? this.id,
      alerteId: alerteId ?? this.alerteId,
      ongId: ongId ?? this.ongId,
      equipeId: equipeId ?? this.equipeId,
      description: description ?? this.description,
      priorite: priorite ?? this.priorite,
      statut: statut ?? this.statut,
      localisation: localisation ?? this.localisation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      membresIntervention: membresIntervention ?? this.membresIntervention,
      rapportIntervention: rapportIntervention ?? this.rapportIntervention,
      metadonnees: metadonnees ?? this.metadonnees,
    );
  }

  /// Durée de l'intervention
  Duration? get duree {
    if (dateFin == null) return null;
    return dateFin!.difference(dateDebut);
  }

  /// Vérifie si l'intervention est en cours
  bool get estEnCours => statut == StatutIntervention.enCours;

  /// Vérifie si l'intervention est terminée
  bool get estTerminee => statut == StatutIntervention.terminee;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InterventionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InterventionModel(id: $id, statut: ${statut.label}, priorite: ${priorite.label})';
  }
}
