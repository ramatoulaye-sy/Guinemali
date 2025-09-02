import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../protected_person/models/forum_post_model.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';
import 'log_service.dart';

/// Service centralisé pour la gestion du forum selon le document technique
/// Basé sur 30 ans d'expérience en développement mobile
class ForumService {
  static ForumService? _instance;
  static ForumService get instance => _instance ??= ForumService._();

  ForumService._();

  final SupabaseClient _supabase = Supabase.instance.client;
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

      // Pour l'instant, retourner des données de test conformes au document technique
      // TODO: Implémenter la vraie requête Supabase quand la table sera créée
      final testMessages = [
        ForumPost(
          utilisateurId: 'user_1',
          contenu: 'Partagez vos conseils et astuces pour rester en sécurité au quotidien. La solidarité entre nous est notre force.',
          valide: true, // Approuvé par la modération
        ),
        ForumPost(
          utilisateurId: 'user_2',
          contenu: 'Un espace pour s\'entraider et se soutenir mutuellement. N\'hésitez pas à partager vos expériences.',
          valide: true, // Approuvé par la modération
        ),
        ForumPost(
          utilisateurId: 'user_3',
          contenu: 'Informations sur les droits et les ressources juridiques disponibles. Connaître ses droits est essentiel.',
          valide: true, // Approuvé par la modération
        ),
        ForumPost(
          utilisateurId: 'user_4',
          contenu: 'Message en attente de modération...',
          valide: false, // En attente de modération
        ),
      ];

      // Mettre à jour le cache
      _allMessages.clear();
      _allMessages.addAll(testMessages);
      
      for (final message in testMessages) {
        _messagesCache[message.id] = message;
      }

      // Retourner seulement les messages approuvés (CONSULTATION ANONYME)
      final approvedMessages = testMessages.where((msg) => msg.isApproved).toList();

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

      final message = ForumPost(
        utilisateurId: userId,
        contenu: contenu,
        valide: false, // Par défaut en attente de modération (MODÉRATION A PRIORI)
      );

      // Pour l'instant, simuler la création
      // TODO: Implémenter la vraie insertion Supabase quand la table sera créée
      _messagesCache[message.id] = message;
      _allMessages.insert(0, message);

      LogService.success('Message créé et en attente de modération: ${message.id}', tag: 'forum');
      return message;
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
      
      // Retourner seulement les messages en attente
      return _allMessages.where((msg) => msg.isPendingModeration).toList();
    } catch (e) {
      LogService.error('Erreur lors de la récupération des messages en attente: $e', tag: 'forum');
      return [];
    }
  }

  /// Approuve un message (pour les modérateurs)
  Future<bool> approveMessage(String messageId) async {
    try {
      LogService.info('Approbation du message: $messageId', tag: 'forum');
      
      final message = _messagesCache[messageId];
      if (message != null) {
        final approvedMessage = message.copyWith(valide: true);
        _messagesCache[messageId] = approvedMessage;
        
        // Mettre à jour dans la liste
        final index = _allMessages.indexWhere((msg) => msg.id == messageId);
        if (index != -1) {
          _allMessages[index] = approvedMessage;
        }
        
        LogService.success('Message approuvé: $messageId', tag: 'forum');
        return true;
      }
      
      return false;
    } catch (e) {
      LogService.error('Erreur lors de l\'approbation du message: $e', tag: 'forum');
      return false;
    }
  }

  /// Rejette un message (pour les modérateurs)
  Future<bool> rejectMessage(String messageId) async {
    try {
      LogService.info('Rejet du message: $messageId', tag: 'forum');
      
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
}
