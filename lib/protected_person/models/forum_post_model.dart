import 'package:uuid/uuid.dart';

/// Modèle pour un message du forum selon le document technique
/// Table Message: id, utilisateur_id, contenu, valide, date_post
class ForumPost {
  final String id;
  final String utilisateurId; // utilisateur_id selon le document
  final String contenu; // contenu selon le document
  final bool valide; // valide selon le document (pour modération)
  final DateTime datePost; // date_post selon le document

  ForumPost({
    String? id,
    required this.utilisateurId,
    required this.contenu,
    this.valide = false, // Par défaut en attente de modération
    DateTime? datePost,
  })  : id = id ?? const Uuid().v4(),
        datePost = datePost ?? DateTime.now();

  /// Crée un ForumPost à partir d'un Map (pour Supabase)
  factory ForumPost.fromMap(Map<String, dynamic> map) {
    return ForumPost(
      id: map['id'] ?? '',
      utilisateurId: map['utilisateur_id'] ?? '',
      contenu: map['contenu'] ?? '',
      valide: map['valide'] ?? false,
      datePost: map['date_post'] != null 
          ? DateTime.parse(map['date_post']) 
          : DateTime.now(),
    );
  }

  /// Convertit le ForumPost en Map (pour Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'utilisateur_id': utilisateurId,
      'contenu': contenu,
      'valide': valide,
      'date_post': datePost.toIso8601String(),
    };
  }

  /// Crée une copie modifiée du ForumPost
  ForumPost copyWith({
    String? id,
    String? utilisateurId,
    String? contenu,
    bool? valide,
    DateTime? datePost,
  }) {
    return ForumPost(
      id: id ?? this.id,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      contenu: contenu ?? this.contenu,
      valide: valide ?? this.valide,
      datePost: datePost ?? this.datePost,
    );
  }

  /// Formate la date de création
  String get formattedDatePost {
    final now = DateTime.now();
    final difference = now.difference(datePost);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  /// Vérifie si le message est modéré et approuvé
  bool get isApproved => valide;

  /// Vérifie si le message est en attente de modération
  bool get isPendingModeration => !valide;
}
