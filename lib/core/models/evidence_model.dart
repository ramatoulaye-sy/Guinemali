/// Modèle de données pour les preuves (audio, vidéo, photos)
class EvidenceModel {
  final String id;
  final String alerteId;
  final EvidenceType type;
  final String? url;
  final String? urlLocale;
  final String? chiffrement;
  final String? cleChiffrement;
  final int? tailleFichier;
  final int? duree; // En secondes pour audio/vidéo
  final DateTime timestamp;
  final bool synchronise;
  final String? hashVerification;

  const EvidenceModel({
    required this.id,
    required this.alerteId,
    required this.type,
    this.url,
    this.urlLocale,
    this.chiffrement,
    this.cleChiffrement,
    this.tailleFichier,
    this.duree,
    required this.timestamp,
    this.synchronise = false,
    this.hashVerification,
  });

  /// Crée un EvidenceModel à partir des données JSON de Supabase
  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    return EvidenceModel(
      id: json['id'] as String,
      alerteId: json['alerte_id'] as String,
      type: EvidenceType.fromString(json['type'] as String),
      url: json['url'] as String?,
      urlLocale: json['url_locale'] as String?,
      chiffrement: json['chiffrement'] as String?,
      cleChiffrement: json['cle_chiffrement'] as String?,
      tailleFichier: json['taille_fichier'] as int?,
      duree: json['duree'] as int?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      synchronise: json['synchronise'] as bool? ?? false,
      hashVerification: json['hash_verification'] as String?,
    );
  }

  /// Convertit l'EvidenceModel en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alerte_id': alerteId,
      'type': type.value,
      'url': url,
      'url_locale': urlLocale,
      'chiffrement': chiffrement,
      'cle_chiffrement': cleChiffrement,
      'taille_fichier': tailleFichier,
      'duree': duree,
      'timestamp': timestamp.toIso8601String(),
      'synchronise': synchronise,
      'hash_verification': hashVerification,
    };
  }

  /// Crée une copie de l'EvidenceModel avec des modifications
  EvidenceModel copyWith({
    String? id,
    String? alerteId,
    EvidenceType? type,
    String? url,
    String? urlLocale,
    String? chiffrement,
    String? cleChiffrement,
    int? tailleFichier,
    int? duree,
    DateTime? timestamp,
    bool? synchronise,
    String? hashVerification,
  }) {
    return EvidenceModel(
      id: id ?? this.id,
      alerteId: alerteId ?? this.alerteId,
      type: type ?? this.type,
      url: url ?? this.url,
      urlLocale: urlLocale ?? this.urlLocale,
      chiffrement: chiffrement ?? this.chiffrement,
      cleChiffrement: cleChiffrement ?? this.cleChiffrement,
      tailleFichier: tailleFichier ?? this.tailleFichier,
      duree: duree ?? this.duree,
      timestamp: timestamp ?? this.timestamp,
      synchronise: synchronise ?? this.synchronise,
      hashVerification: hashVerification ?? this.hashVerification,
    );
  }

  /// Vérifie si la preuve est disponible localement
  bool get isAvailableLocally => urlLocale != null;

  /// Vérifie si la preuve est uploadée sur le serveur
  bool get isUploadedToServer => url != null && synchronise;

  /// Retourne la taille formatée du fichier
  String get formattedFileSize {
    if (tailleFichier == null) return 'Taille inconnue';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = tailleFichier!.toDouble();
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Retourne la durée formatée pour les fichiers audio/vidéo
  String? get formattedDuration {
    if (duree == null) return null;
    
    final duration = Duration(seconds: duree!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'EvidenceModel(id: $id, type: ${type.value}, synchronise: $synchronise)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types de preuves supportés
enum EvidenceType {
  audio('audio'),
  video('video'),
  photo('photo'),
  texte('texte');

  const EvidenceType(this.value);

  final String value;

  static EvidenceType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'audio':
        return EvidenceType.audio;
      case 'video':
        return EvidenceType.video;
      case 'photo':
        return EvidenceType.photo;
      case 'texte':
        return EvidenceType.texte;
      default:
        throw ArgumentError('Type de preuve non reconnu: $value');
    }
  }

  String get displayName {
    switch (this) {
      case EvidenceType.audio:
        return 'Enregistrement audio';
      case EvidenceType.video:
        return 'Enregistrement vidéo';
      case EvidenceType.photo:
        return 'Photo';
      case EvidenceType.texte:
        return 'Note textuelle';
    }
  }

  String get iconName {
    switch (this) {
      case EvidenceType.audio:
        return 'audiotrack';
      case EvidenceType.video:
        return 'videocam';
      case EvidenceType.photo:
        return 'photo_camera';
      case EvidenceType.texte:
        return 'text_snippet';
    }
  }

  /// Extensions de fichiers acceptées
  List<String> get acceptedExtensions {
    switch (this) {
      case EvidenceType.audio:
        return ['.mp3', '.wav', '.aac', '.m4a'];
      case EvidenceType.video:
        return ['.mp4', '.mov', '.avi', '.mkv'];
      case EvidenceType.photo:
        return ['.jpg', '.jpeg', '.png', '.bmp'];
      case EvidenceType.texte:
        return ['.txt', '.md'];
    }
  }

  /// Taille maximale en bytes
  int get maxFileSize {
    switch (this) {
      case EvidenceType.audio:
        return 50 * 1024 * 1024; // 50 MB
      case EvidenceType.video:
        return 200 * 1024 * 1024; // 200 MB
      case EvidenceType.photo:
        return 10 * 1024 * 1024; // 10 MB
      case EvidenceType.texte:
        return 1 * 1024 * 1024; // 1 MB
    }
  }
}

/// Modèle pour créer une nouvelle preuve
class CreateEvidenceModel {
  final String alerteId;
  final EvidenceType type;
  final String? urlLocale;
  final int? tailleFichier;
  final int? duree;
  final String? contenuTexte;

  const CreateEvidenceModel({
    required this.alerteId,
    required this.type,
    this.urlLocale,
    this.tailleFichier,
    this.duree,
    this.contenuTexte,
  });

  Map<String, dynamic> toJson() {
    return {
      'alerte_id': alerteId,
      'type': type.value,
      'url_locale': urlLocale,
      'taille_fichier': tailleFichier,
      'duree': duree,
      'synchronise': false,
    };
  }
}

/// Modèle pour les paramètres d'enregistrement
class RecordingSettings {
  final EvidenceType type;
  final int qualite; // 1-10
  final bool chiffrementActive;
  final int dureeMaximale; // En secondes
  final bool enregistrementContinu;

  const RecordingSettings({
    required this.type,
    this.qualite = 7,
    this.chiffrementActive = true,
    this.dureeMaximale = 300, // 5 minutes par défaut
    this.enregistrementContinu = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'qualite': qualite,
      'chiffrement_active': chiffrementActive,
      'duree_maximale': dureeMaximale,
      'enregistrement_continu': enregistrementContinu,
    };
  }

  factory RecordingSettings.fromJson(Map<String, dynamic> json) {
    return RecordingSettings(
      type: EvidenceType.fromString(json['type'] as String),
      qualite: json['qualite'] as int? ?? 7,
      chiffrementActive: json['chiffrement_active'] as bool? ?? true,
      dureeMaximale: json['duree_maximale'] as int? ?? 300,
      enregistrementContinu: json['enregistrement_continu'] as bool? ?? false,
    );
  }
}
