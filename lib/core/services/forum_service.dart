import 'dart:async';
import '../../protected_person/models/forum_post_model.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';
import 'supabase_service.dart';
import 'log_service.dart';

/// Service centralisé pour la gestion du forum selon le document technique
/// Basé sur 30 ans d'expérience en développement mobile
class ForumService {
  static ForumService? _instance;
  static ForumService get instance => _instance ??= ForumService._();

  ForumService._();

  final SupabaseService _supabase = SupabaseService.instance;
  final StorageService _storage = StorageService.instance;

  // Cache local pour les messages
  final Map<String, ForumPost> _messagesCache = {};
  final List<ForumPost> _allMessages = [];

  /// Récupère tous les messages du forum (CONSULTATION ANONYME)
  /// Selon le document technique : "Consultation anonyme (aucune donnée personnelle affichée)"
  Future<List<ForumPost>> getAllMessages() async {
    try {
      LogService.info('Récupération des messages du forum (anonyme)', tag: 'forum');
      
      // Si on a des messages en cache, les retourner
      if (_allMessages.isNotEmpty) {
        return _allMessages.where((msg) => msg.isApproved).toList();
      }

      // Récupérer les messages depuis Supabase
      final response = await _supabase.select(
        'forum_messages',
        filters: {'valide': true}, // Seulement les messages approuvés
        orderBy: 'date_post',
        ascending: false,
        limit: 50,
      );

      final messages = (response as List?)?.cast<Map<String, dynamic>>() ?? [];
      final forumPosts = messages.map((data) => _createForumPostFromData(data)).toList();

      // Mettre à jour le cache
      _allMessages.clear();
      _allMessages.addAll(forumPosts);
      
      for (final message in forumPosts) {
        _messagesCache[message.id] = message;
      }

      // Retourner seulement les messages approuvés (CONSULTATION ANONYME)
      final approvedMessages = forumPosts.where((msg) => msg.isApproved).toList();

      LogService.success('${approvedMessages.length} messages approuvés récupérés (anonyme)', tag: 'forum');
      return approvedMessages;
    } catch (e) {
      LogService.error('Erreur lors de la récupération des messages: $e', tag: 'forum');
      // Retourner les messages approuvés en cache en cas d'erreur
      return _allMessages.where((msg) => msg.isApproved).toList();
    }
  }

  /// Crée un nouveau message (MODÉRATION A PRIORI)
  /// Selon le document technique : "Modération a priori (par l'équipe)"
  Future<ForumPost?> createMessage({
    required String contenu,
  }) async {
    try {
      LogService.info('Création d\'un nouveau message (modération a priori)', tag: 'forum');
      
      final userId = _storage.getString(AppConstants.keyUserId);
      
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Vérification du contenu avec filtrage NLP (simulé)
      if (!_validateContent(contenu)) {
        LogService.warning('Contenu rejeté par le filtrage NLP', tag: 'forum');
        throw Exception('Le contenu contient des éléments inappropriés');
      }

      // Créer l'objet message pour validation (non utilisé pour l'insertion)
      // final message = ForumPost(
      //   utilisateurId: userId,
      //   contenu: contenu,
      //   valide: false, // Par défaut en attente de modération (MODÉRATION A PRIORI)
      // );

      // Insérer le message dans Supabase
      final messageData = {
        'utilisateur_id': userId,
        'contenu': contenu,
        'valide': false, // En attente de modération
        'date_post': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.insert('forum_messages', messageData);
      
      if (response != null && response.isNotEmpty) {
        final createdData = response.first;
        final createdMessage = _createForumPostFromData(createdData);
        
        _messagesCache[createdMessage.id] = createdMessage;
        _allMessages.insert(0, createdMessage);
        
        LogService.success('Message créé et en attente de modération: ${createdMessage.id}', tag: 'forum');
        return createdMessage;
      }
      
      return null;
    } catch (e) {
      LogService.error('Erreur lors de la création du message: $e', tag: 'forum');
      return null;
    }
  }

  /// Filtrage automatique des contenus toxiques (NLP léger)
  /// Selon le document technique : "Filtrage automatique des contenus toxiques grâce à un modèle NLP léger"
  bool _validateContent(String contenu) {
    // Simulation d'un modèle NLP léger
    final motsInterdits = [
      'insulte', 'violence', 'harcèlement', 'discrimination',
      'racisme', 'sexisme', 'homophobie', 'transphobie',
    ];

    final contenuLower = contenu.toLowerCase();
    
    // Vérification des mots interdits
    for (final mot in motsInterdits) {
      if (contenuLower.contains(mot)) {
        LogService.warning('Contenu rejeté - mot interdit détecté: $mot', tag: 'forum');
        return false;
      }
    }

    // Vérification de la longueur minimale
    if (contenu.trim().length < 10) {
      LogService.warning('Contenu rejeté - trop court', tag: 'forum');
      return false;
    }

    // Vérification de la longueur maximale
    if (contenu.length > 1000) {
      LogService.warning('Contenu rejeté - trop long', tag: 'forum');
      return false;
    }

    return true;
  }

  /// Récupère les messages en attente de modération (pour les modérateurs)
  Future<List<ForumPost>> getPendingMessages() async {
    try {
      LogService.info('Récupération des messages en attente de modération', tag: 'forum');
      
      // Récupérer depuis Supabase
      final response = await _supabase.select(
        'forum_messages',
        filters: {'valide': false}, // Messages en attente
        orderBy: 'date_post',
        ascending: false,
      );

      final messages = (response as List?)?.cast<Map<String, dynamic>>() ?? [];
      return messages.map((data) => _createForumPostFromData(data)).toList();
    } catch (e) {
      LogService.error('Erreur lors de la récupération des messages en attente: $e', tag: 'forum');
      return [];
    }
  }

  /// Approuve un message (pour les modérateurs)
  Future<bool> approveMessage(String messageId) async {
    try {
      LogService.info('Approbation du message: $messageId', tag: 'forum');
      
      // Mettre à jour dans Supabase
      await _supabase.update(
        'forum_messages',
        {
          'valide': true,
          'date_moderation': DateTime.now().toIso8601String(),
        },
        idColumn: 'id',
        idValue: messageId,
      );
      
      // Mettre à jour le cache local
      final message = _messagesCache[messageId];
      if (message != null) {
        final approvedMessage = message.copyWith(valide: true);
        _messagesCache[messageId] = approvedMessage;
        
        // Mettre à jour dans la liste
        final index = _allMessages.indexWhere((msg) => msg.id == messageId);
        if (index != -1) {
          _allMessages[index] = approvedMessage;
        }
      }
      
      LogService.success('Message approuvé: $messageId', tag: 'forum');
      return true;
    } catch (e) {
      LogService.error('Erreur lors de l\'approbation du message: $e', tag: 'forum');
      return false;
    }
  }

  /// Rejette un message (pour les modérateurs)
  Future<bool> rejectMessage(String messageId) async {
    try {
      LogService.info('Rejet du message: $messageId', tag: 'forum');
      
      // Supprimer de Supabase
      await _supabase.delete(
        'forum_messages',
        idColumn: 'id',
        idValue: messageId,
      );
      
      // Supprimer du cache et de la liste
      _messagesCache.remove(messageId);
      _allMessages.removeWhere((msg) => msg.id == messageId);
      
      LogService.success('Message rejeté: $messageId', tag: 'forum');
      return true;
    } catch (e) {
      LogService.error('Erreur lors du rejet du message: $e', tag: 'forum');
      return false;
    }
  }

  /// Vide le cache
  void clearCache() {
    _messagesCache.clear();
    _allMessages.clear();
    LogService.info('Cache du forum vidé', tag: 'forum');
  }

  /// Rafraîchit les données
  Future<void> refresh() async {
    clearCache();
    await getAllMessages();
    LogService.info('Données du forum rafraîchies', tag: 'forum');
  }

  /// Crée un objet ForumPost à partir des données de la base
  ForumPost _createForumPostFromData(Map<String, dynamic> data) {
    return ForumPost(
      id: data['id']?.toString() ?? '',
      utilisateurId: data['utilisateur_id']?.toString() ?? '',
      contenu: data['contenu']?.toString() ?? '',
      valide: data['valide'] == true,
      datePost: data['date_post'] != null 
          ? DateTime.tryParse(data['date_post'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
