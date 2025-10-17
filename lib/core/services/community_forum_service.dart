import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

/// Modèles simples pour le forum (cache local)
class ForumPost {
  final String id;
  final String authorId;
  final String authorName;
  final String category;
  final String text;
  final List<ForumMedia> medias;
  final DateTime createdAt;
  final Set<String> likedBy;
  final List<ForumComment> comments;
  final String? moderation; // pending | approved | rejected (optionnel)
  final bool anonymous;
  final bool hideAvatar;

  ForumPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.category,
    required this.text,
    required this.medias,
    required this.createdAt,
    Set<String>? likedBy,
    List<ForumComment>? comments,
    this.moderation,
    this.anonymous = false,
    this.hideAvatar = false,
  })  : likedBy = likedBy ?? <String>{},
        comments = comments ?? <ForumComment>[];

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'category': category,
        'text': text,
        'medias': medias.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'likedBy': likedBy.toList(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'moderation': moderation,
        'anonymous': anonymous,
        'hideAvatar': hideAvatar,
      };

  static ForumPost fromJson(Map<String, dynamic> json) => ForumPost(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        category: json['category'] as String,
        text: json['text'] as String,
        medias: (json['medias'] as List<dynamic>)
            .map((e) => ForumMedia.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        likedBy: {...((json['likedBy'] as List<dynamic>).cast<String>())},
        comments: (json['comments'] as List<dynamic>)
            .map((e) => ForumComment.fromJson(e as Map<String, dynamic>))
            .toList(),
        moderation: json['moderation'] as String?,
        anonymous: json['anonymous'] as bool? ?? false,
        hideAvatar: json['hideAvatar'] as bool? ?? false,
      );

  /// Crée un ForumPost depuis une ligne Supabase (colonnes snake_case)
  static ForumPost fromSupabase(Map<String, dynamic> row) {
    final mediasList = (row['medias'] as List?) ?? [];
    final medias = mediasList.map((m) {
      final Map<String, dynamic> mm = (m as Map).cast<String, dynamic>();
      final kind = (mm['kind'] ?? 'image').toString();
      final url = (mm['url'] ?? mm['localPath'] ?? '').toString();
      return ForumMedia(kind: kind, localPath: url);
    }).toList();
    
    final likedBy = {...(((row['liked_by'] as List?) ?? []).cast<String>())};
    
    // 🔥 PARSER LES COMMENTAIRES DEPUIS SUPABASE
    final commentsList = (row['comments'] as List?) ?? [];
    final comments = commentsList.map((c) {
      final Map<String, dynamic> commentMap = (c as Map).cast<String, dynamic>();
      return ForumComment.fromJson(commentMap);
    }).toList();
    
    return ForumPost(
      id: row['id'] as String,
      authorId: row['author_id'] as String,
      authorName: row['author_name'] as String,
      category: row['category'] as String,
      text: row['text'] as String,
      medias: medias,
      createdAt: DateTime.parse(row['created_at'].toString()),
      likedBy: likedBy,
      comments: comments,
      moderation: row['moderation'] as String?,
      anonymous: row['anonymous'] as bool? ?? false,
      hideAvatar: row['hide_avatar'] as bool? ?? false,
    );
  }
}

class ForumMedia {
  final String kind; // image | video | audio
  final String localPath; // chemin local OU URL Supabase

  ForumMedia({required this.kind, required this.localPath});

  Map<String, dynamic> toJson() => {'kind': kind, 'localPath': localPath};
  static ForumMedia fromJson(Map<String, dynamic> json) => ForumMedia(
        kind: json['kind'] as String,
        localPath: json['localPath'] as String,
      );
}

class ForumComment {
  final String id;
  final String authorId;
  final String authorName;
  String text;
  final DateTime createdAt;
  final Set<String> likedBy;
  final List<ForumComment> replies;

  ForumComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    Set<String>? likedBy,
    List<ForumComment>? replies,
  })  : likedBy = likedBy ?? <String>{},
        replies = replies ?? <ForumComment>[];

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'likedBy': likedBy.toList(),
        'replies': replies.map((r) => r.toJson()).toList(),
      };

  static ForumComment fromJson(Map<String, dynamic> json) => ForumComment(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        likedBy: {...((json['likedBy'] as List<dynamic>).cast<String>())},
        replies: (json['replies'] as List<dynamic>)
            .map((e) => ForumComment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Service local (cache) + hooks Supabase (à brancher ensuite)
class CommunityForumService with ChangeNotifier {
  CommunityForumService._();
  static final CommunityForumService instance = CommunityForumService._();
  static String? focusPostId; // pour navigation depuis notifications

  void setFocusPost(String postId) {
    focusPostId = postId;
    notifyListeners();
  }

  static const String _kPosts = 'community_forum_posts_v1';

  List<ForumPost> _posts = [];
  bool _loaded = false;

  List<ForumPost> get posts => List.unmodifiable(_posts);

  /// Invalider le cache (à appeler lors de la déconnexion ou changement d'utilisateur)
  void invalidateCache() {
    print('🗑️ Invalidation du cache forum');
    _loaded = false;
    _posts = [];
  }

  /// Forcer le rechargement depuis Supabase
  Future<void> reload() async {
    print('🔄 FORCE RELOAD demandé, reset _loaded flag');
    _loaded = false;
    await _ensureLoaded();
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      print('ℹ️ Posts déjà chargés (_loaded=true), skip');
      return;
    }
    
    print('🔄 DÉBUT chargement posts forum...');
    
    // 1. Essayer de charger DIRECTEMENT depuis Supabase (priorité à la source de vérité)
    try {
      print('📡 Connexion à Supabase pour charger les posts...');
      await SupabaseService.ensureInitialized();
      
      print('📡 Exécution SELECT sur forum_posts...');
      final rows = await SupabaseService.instance.select(
        'forum_posts',
        columns: 'id, author_id, author_name, category, text, medias, created_at, liked_by, comments', // 🔥 AJOUTER COMMENTS
        orderBy: 'created_at', 
        ascending: false,
        limit: 50, // Charger les 50 derniers posts
      );
      
      print('📡 SELECT terminé, ${rows.length} rows reçues');
      
      if (rows.isNotEmpty) {
        // REMPLACER complètement le cache par les données de Supabase
        _posts = rows.map<ForumPost>((row) => ForumPost.fromSupabase(row)).toList();
        print('✅ ${_posts.length} posts chargés depuis Supabase');
        print('📋 Auteurs: ${_posts.map((p) => p.authorName).toSet().join(", ")}');
        
        // Sauvegarder le cache mis à jour
        await _persist();
        print('💾 Cache local mis à jour avec ${_posts.length} posts');
      } else {
        print('⚠️ Aucun post trouvé dans Supabase, chargement du cache local...');
        // Si Supabase est vide, charger le cache local
        _loadFromCache();
      }
    } catch (e, stackTrace) {
      print('❌ Erreur chargement posts Supabase: $e');
      print('❌ Stack trace: $stackTrace');
      // En cas d'erreur, fallback sur le cache local
      _loadFromCache();
    }
    
    _loaded = true;
    print('✅ FIN chargement posts forum (_loaded=true)');
  }
  
  /// Charger les posts depuis le cache local (fallback)
  void _loadFromCache() {
    final raw = StorageService.instance.getString(_kPosts);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List<dynamic>);
        _posts = list.map((e) => ForumPost.fromJson(e as Map<String, dynamic>)).toList();
        print('✅ ${_posts.length} posts chargés depuis le cache local');
      } catch (e) {
        print('❌ Erreur lecture cache local: $e');
        _posts = [];
      }
    } else {
      print('⚠️ Cache local vide');
      _posts = [];
    }
  }

  Future<List<ForumPost>> listPosts() async {
    // TOUJOURS forcer le rechargement depuis Supabase
    _loaded = false;
    await _ensureLoaded();
    // tri desc par date
    _posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  /// Liste paginée depuis Supabase si possible, sinon depuis le cache.
  /// page démarre à 1, pageSize par défaut 20.
  Future<List<ForumPost>> listPostsPaged({required int page, int pageSize = 20}) async {
    await _ensureLoaded();
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    try {
      await SupabaseService.ensureInitialized();
      final rows = await SupabaseService.instance.select(
        'forum_posts',
        columns: 'id, author_id, author_name, category, text, medias, created_at, liked_by',
        orderBy: 'created_at', ascending: false,
        rangeFrom: from,
        rangeTo: to,
      );
      final fetched = (rows as List).map((e) {
        // Adapter les colonnes supabase -> modèles locaux
        final mediasList = (e['medias'] as List?) ?? [];
        final medias = mediasList.map((m) {
          final Map<String, dynamic> mm = (m as Map).cast<String, dynamic>();
          final kind = (mm['kind'] ?? 'image').toString();
          final url = (mm['url'] ?? mm['localPath'] ?? '').toString();
          return ForumMedia(kind: kind, localPath: url);
        }).toList();
        final likedBy = {...(((e['liked_by'] as List?) ?? []).cast<String>())};
        final comments = <ForumComment>[]; // à hydrater si besoin
        return ForumPost(
          id: e['id'] as String,
          authorId: e['author_id'] as String,
          authorName: e['author_name'] as String,
          category: e['category'] as String,
          text: e['text'] as String,
          medias: medias,
          createdAt: DateTime.parse(e['created_at'].toString()),
          likedBy: likedBy,
          comments: comments,
        );
      }).toList();

      // Fusionner dans le cache en évitant les doublons
      final existingIds = _posts.map((p) => p.id).toSet();
      for (final p in fetched) {
        if (!existingIds.contains(p.id)) {
          _posts.add(p);
        }
      }
      await _persist();
      notifyListeners();
    } catch (_) {
      // Offline: utiliser le cache
    }
    _posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    // Retourner la tranche visible
    final end = (page * pageSize).clamp(0, _posts.length);
    return _posts.sublist(0, end);
  }

  /// Cursor pagination: fetch posts before a given timestamp from Supabase, fallback cache.
  Future<List<ForumPost>> listPostsBefore({DateTime? before, int limit = 20}) async {
    await _ensureLoaded();
    try {
      await SupabaseService.ensureInitialized();
      final filters = <String, dynamic>{};
      if (before != null) {
        filters['created_at__lt'] = before.toUtc().toIso8601String();
      }
      final rows = await SupabaseService.instance.select(
        'forum_posts',
        columns: 'id, author_id, author_name, category, text, medias, created_at, liked_by',
        filters: filters,
        orderBy: 'created_at', ascending: false,
        limit: limit,
      );
      final fetched = (rows as List).map((e) {
        final mediasList = (e['medias'] as List?) ?? [];
        final medias = mediasList.map((m) {
          final Map<String, dynamic> mm = (m as Map).cast<String, dynamic>();
          final kind = (mm['kind'] ?? 'image').toString();
          final url = (mm['url'] ?? mm['localPath'] ?? '').toString();
          return ForumMedia(kind: kind, localPath: url);
        }).toList();
        final likedBy = {...(((e['liked_by'] as List?) ?? []).cast<String>())};
        return ForumPost(
          id: e['id'] as String,
          authorId: e['author_id'] as String,
          authorName: e['author_name'] as String,
          category: e['category'] as String,
          text: e['text'] as String,
          medias: medias,
          createdAt: DateTime.parse(e['created_at'].toString()),
          likedBy: likedBy,
        );
      }).toList();
      final existingIds = _posts.map((p) => p.id).toSet();
      for (final p in fetched) {
        if (!existingIds.contains(p.id)) {
          _posts.add(p);
        }
      }
      await _persist();
      notifyListeners();
    } catch (_) {
      // offline: rely on cache
    }
    _posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    // Return the newest first (since cache now merged)
    return posts;
  }

  Future<ForumPost> createPost({
    required String authorId,
    required String authorName,
    required String category,
    required String text,
    required List<ForumMedia> medias,
    bool anonymous = false,
    bool hideAvatar = false,
  }) async {
    await _ensureLoaded();
    final post = ForumPost(
      id: const Uuid().v4(),
      authorId: authorId,
      authorName: authorName,
      category: category,
      text: text,
      medias: medias,
      createdAt: DateTime.now().toUtc(),
      moderation: 'pending',
      anonymous: anonymous,
      hideAvatar: hideAvatar,
    );
    _posts.insert(0, post);
    await _persist();
    notifyListeners();
    // Tenter la persistance distante en tâche de fond
    _persistToSupabase(post).catchError((_) {});
    return post;
  }

  static const String _bucket = 'forum';

  Future<void> _persistToSupabase(ForumPost post) async {
    try {
      print('📤 Début upload post vers Supabase: ${post.id}');
      await SupabaseService.ensureInitialized();
      final List<Map<String, dynamic>> remoteMedias = [];
      
      // Upload des médias
      if (post.medias.isNotEmpty) {
        print('📎 Upload de ${post.medias.length} média(s)...');
      }
      
      for (final m in post.medias) {
        String url = m.localPath;
        if (!m.localPath.startsWith('http')) {
          print('📤 Upload fichier local: ${m.localPath}');
          final bytes = await _readBytesSafe(m.localPath);
          if (bytes.isEmpty) {
            print('⚠️ Fichier vide ou illisible: ${m.localPath}');
            continue;
          }
          final filename = _basename(m.localPath);
          final path = '${post.authorId}/${post.id}/$filename';
          print('📤 Upload vers: $_bucket/$path (${bytes.length} bytes)');
          
          url = await SupabaseService.instance.uploadFile(
            bucket: _bucket,
            path: path,
            file: bytes,
            metadata: {'kind': m.kind},
          );
          print('✅ Média uploadé: $url');
        }
        remoteMedias.add({'kind': m.kind, 'url': url});
      }

      // Créer le post dans Supabase
      print('📤 Insertion post dans forum_posts...');
      await SupabaseService.instance.upsert('forum_posts', {
        'id': post.id,
        'author_id': post.authorId,
        'author_name': post.anonymous ? 'Anonyme' : post.authorName,
        'category': post.category,
        'text': post.text,
        'medias': remoteMedias,
        'created_at': post.createdAt.toIso8601String(),
        'liked_by': post.likedBy.toList(),
        'comments': post.comments.map((c) => c.toJson()).toList(), // 🔥 AJOUTER LES COMMENTAIRES
        'moderation': post.moderation ?? 'pending',
        'anonymous': post.anonymous,
        'hide_avatar': post.hideAvatar,
      }, onConflict: 'id', ignoreDuplicates: true);
      print('✅ Post sauvegardé dans Supabase: ${post.id}');

      // Mettre à jour le cache local avec les URLs uploadées si besoin
      bool changed = false;
      for (int i = 0; i < post.medias.length; i++) {
        final local = post.medias[i];
        final remote = remoteMedias[i]['url'] as String;
        if (remote.isNotEmpty && remote != local.localPath) {
          post.medias[i] = ForumMedia(kind: local.kind, localPath: remote);
          changed = true;
        }
      }
      if (changed) {
        await _persist();
        notifyListeners();
      }
    } catch (e, stackTrace) {
      print('❌ ERREUR upload post vers Supabase: $e');
      print('❌ Stack trace: $stackTrace');
      // offline: on gardera le cache et on réessaiera plus tard si nécessaire
    }
  }

  Future<List<int>> _readBytesSafe(String path) async {
    try {
      final f = File(path);
      return await f.readAsBytes();
    } catch (_) {
      return <int>[];
    }
  }

  String _basename(String p) {
    final i = p.lastIndexOf(RegExp(r'[\\/]'));
    if (i == -1) return p;
    return p.substring(i + 1);
  }

  Future<void> toggleLike({required String postId, required String userId}) async {
    await _ensureLoaded();
    final p = _posts.firstWhere((e) => e.id == postId, orElse: () => throw StateError('post introuvable'));
    final wasLiked = p.likedBy.contains(userId);
    if (wasLiked) {
      p.likedBy.remove(userId);
    } else {
      p.likedBy.add(userId);
    }
    await _persist();
    notifyListeners();

    // 🔥 SYNCHRONISER avec Supabase
    try {
      await SupabaseService.ensureInitialized();
      await SupabaseService.instance.update('forum_posts', {
        'liked_by': p.likedBy.toList(),
      }, idColumn: 'id', idValue: postId);
      print('✅ Like synchronisé avec Supabase pour post $postId');
    } catch (e) {
      print('⚠️ Erreur synchronisation like: $e');
      // Continuer même si Supabase échoue (offline mode)
    }

    // Notification Supabase quand un like est ajouté par une autre personne
    if (!wasLiked && userId != p.authorId) {
      _notify(kind: 'like',
        title: 'Nouveau like',
        message: 'Votre post a reçu un like',
        postId: p.id,
        userId: p.authorId,
      );
    }
  }

  Future<ForumComment> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String text,
    String? parentCommentId,
  }) async {
    await _ensureLoaded();
    final p = _posts.firstWhere((e) => e.id == postId, orElse: () => throw StateError('post introuvable'));
    final c = ForumComment(
      id: const Uuid().v4(),
      authorId: authorId,
      authorName: authorName,
      text: text,
      createdAt: DateTime.now().toUtc(),
    );
    if (parentCommentId == null) {
      p.comments.add(c);
    } else {
      final parent = _findComment(p.comments, parentCommentId);
      if (parent == null) throw StateError('commentaire parent introuvable');
      parent.replies.add(c);
    }
    await _persist();
    notifyListeners();

    // 🔥 SYNCHRONISER avec Supabase
    try {
      await SupabaseService.ensureInitialized();
      final commentsJson = p.comments.map((c) => c.toJson()).toList();
      await SupabaseService.instance.update('forum_posts', {
        'comments': commentsJson,
      }, idColumn: 'id', idValue: postId);
      print('✅ Commentaire synchronisé avec Supabase pour post $postId');
    } catch (e) {
      print('⚠️ Erreur synchronisation commentaire: $e');
      // Continuer même si Supabase échoue (offline mode)
    }

    // Notifications: commentaire sur le post, ou reponse a un commentaire
    if (parentCommentId == null) {
      if (authorId != p.authorId) {
        _notify(
          kind: 'comment',
          title: 'Nouveau commentaire',
          message: 'Quelqu\'un a commente votre post',
          postId: p.id,
          userId: p.authorId,
        );
      }
    } else {
      final parent = _findComment(p.comments, parentCommentId);
      if (parent != null && authorId != parent.authorId) {
        _notify(
          kind: 'reply',
          title: 'Nouvelle reponse',
          message: 'Quelqu\'un a repondu a votre commentaire',
          postId: p.id,
          userId: parent.authorId,
        );
      }
    }
    return c;
  }

  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    await _ensureLoaded();
    final p = _posts.firstWhere((e) => e.id == postId, orElse: () => throw StateError('post introuvable'));
    final c = _findComment(p.comments, commentId);
    if (c == null) throw StateError('commentaire introuvable');
    // Toggle optimiste puis persist
    final wasLiked = c.likedBy.contains(userId);
    if (wasLiked) {
      c.likedBy.remove(userId);
    } else {
      c.likedBy.add(userId);
    }
    notifyListeners();
    await _persist();

    // 🔥 SYNCHRONISER avec Supabase
    try {
      await SupabaseService.ensureInitialized();
      final commentsJson = p.comments.map((c) => c.toJson()).toList();
      await SupabaseService.instance.update('forum_posts', {
        'comments': commentsJson,
      }, idColumn: 'id', idValue: postId);
      print('✅ Like de commentaire synchronisé avec Supabase pour post $postId');
    } catch (e) {
      print('⚠️ Erreur synchronisation like de commentaire: $e');
      // Continuer même si Supabase échoue (offline mode)
    }

    if (!wasLiked && userId != c.authorId) {
      _notify(
        kind: 'like',
        title: 'Votre commentaire a ete aime',
        message: 'Quelqu\'un a aime votre commentaire',
        postId: p.id,
        userId: c.authorId,
      );
    }
  }

  Future<void> editComment({
    required String postId,
    required String commentId,
    required String userId,
    required String newText,
  }) async {
    await _ensureLoaded();
    final pIndex = _posts.indexWhere((e) => e.id == postId);
    if (pIndex == -1) return;
    final c = _findComment(_posts[pIndex].comments, commentId);
    if (c == null) throw StateError('commentaire introuvable');
    if (c.authorId != userId) throw StateError('Autorisation requise pour modifier ce commentaire');
    c.text = newText;
    await _persist();
    notifyListeners();
    
    // 🔥 SYNCHRONISER avec Supabase (mise à jour de la colonne JSON comments)
    try {
      await SupabaseService.ensureInitialized();
      final p = _posts[pIndex];
      final commentsJson = p.comments.map((c) => c.toJson()).toList();
      await SupabaseService.instance.update('forum_posts', {
        'comments': commentsJson,
      }, idColumn: 'id', idValue: postId);
      print('✅ Édition de commentaire synchronisée avec Supabase pour post $postId');
    } catch (e) {
      print('⚠️ Erreur synchronisation édition commentaire: $e');
    }
  }

  /// Supprime un commentaire (ou réponse) d'un post si l'utilisatrice en est l'autrice
  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    await _ensureLoaded();
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    bool removed = _removeCommentIfOwner(_posts[postIndex].comments, commentId, userId);
    if (!removed) {
      throw StateError("Autorisation requise pour supprimer ce commentaire");
    }
    await _persist();
    notifyListeners();

    // 🔥 SYNCHRONISER avec Supabase (mise à jour de la colonne JSON comments)
    try {
      await SupabaseService.ensureInitialized();
      final p = _posts[postIndex];
      final commentsJson = p.comments.map((c) => c.toJson()).toList();
      await SupabaseService.instance.update('forum_posts', {
        'comments': commentsJson,
      }, idColumn: 'id', idValue: postId);
      print('✅ Suppression de commentaire synchronisée avec Supabase pour post $postId');
    } catch (e) {
      print('⚠️ Erreur synchronisation suppression commentaire: $e');
    }
  }

  bool _removeCommentIfOwner(List<ForumComment> list, String targetId, String userId) {
    for (int i = 0; i < list.length; i++) {
      final c = list[i];
      if (c.id == targetId) {
        if (c.authorId != userId) return false;
        list.removeAt(i);
        return true;
      }
      if (_removeCommentIfOwner(c.replies, targetId, userId)) {
        return true;
      }
    }
    return false;
  }

  /// Supprime un post (local + tentative Supabase)
  Future<void> deletePost({required String postId, required String userId}) async {
    await _ensureLoaded();
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];
    // Autoriser uniquement l'autrice
    if (post.authorId != userId) {
      throw StateError("Autorisation requise pour supprimer ce post");
    }
    _posts.removeAt(idx);
    await _persist();
    notifyListeners();
    // Effacer côté Supabase si connecté
    try {
      await SupabaseService.ensureInitialized();
      // Supprimer les fichiers du bucket
      for (final m in post.medias) {
        if (m.localPath.startsWith('http')) {
          // best-effort: extraire le chemin après le bucket si URL publique
          try {
            final uri = Uri.parse(m.localPath);
            final parts = uri.path.split('/');
            final idxBucket = parts.indexWhere((e) => e == 'object');
            if (idxBucket != -1 && idxBucket + 2 < parts.length) {
              final path = parts.sublist(idxBucket + 2).join('/');
              await SupabaseService.instance.deleteFile(bucket: _bucket, path: path);
            }
          } catch (_) {}
        }
      }
      await SupabaseService.instance.delete('forum_posts', idColumn: 'id', idValue: postId);
    } catch (_) {
      // silencieux en offline, le prochain sync réglera
    }
  }

  ForumComment? _findComment(List<ForumComment> list, String id) {
    for (final c in list) {
      if (c.id == id) return c;
      final r = _findComment(c.replies, id);
      if (r != null) return r;
    }
    return null;
  }

  Future<void> _persist() async {
    final raw = jsonEncode(_posts.map((e) => e.toJson()).toList());
    await StorageService.instance.saveString(_kPosts, raw);
  }

  // --- Notifications helper ---
  void _notify({required String kind, required String title, required String message, required String postId, required String userId}) async {
    try {
      await SupabaseService.ensureInitialized();
      await SupabaseService.instance.insert('notifications', {
        'kind': kind,
        'title': title,
        'message': message,
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // silencieux en offline
    }
  }
}


