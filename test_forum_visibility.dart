// Script de test : Visibilité des posts du forum
// Utilisation : dart run test_forum_visibility.dart

import 'package:guinemali/core/services/supabase_service.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/constants/app_constants.dart';

void main() async {
  print('🔍 TEST : Visibilité des posts du forum\n');
  
  try {
    // Initialiser StorageService (requis pour SupabaseService)
    await StorageService.ensureInitialized();
    print('✅ StorageService initialisé\n');
    
    // Initialiser Supabase
    await SupabaseService.ensureInitialized();
    print('✅ SupabaseService initialisé\n');
    
    // Test 1 : Récupérer TOUS les posts sans filtre
    print('📊 TEST 1 : Récupération de TOUS les posts\n');
    print('   Requête : SELECT * FROM forum_posts ORDER BY created_at DESC LIMIT 10');
    
    final allPosts = await SupabaseService.instance.select(
      'forum_posts',
      columns: 'id, author_id, author_name, category, text, created_at',
      orderBy: 'created_at',
      ascending: false,
      limit: 10,
    );
    
    print('   Résultat : ${allPosts.length} posts récupérés\n');
    
    if (allPosts.isEmpty) {
      print('   ❌ PROBLÈME : Aucun post trouvé !');
      print('   → Vérifiez que la table forum_posts contient des données\n');
    } else {
      print('   ✅ Posts récupérés avec succès :');
      for (var i = 0; i < allPosts.length; i++) {
        final post = allPosts[i] as Map<String, dynamic>;
        final authorName = post['author_name'] ?? 'Anonyme';
        final text = (post['text'] as String? ?? '').substring(0, (post['text'] as String? ?? '').length.clamp(0, 50));
        final createdAt = post['created_at'];
        print('   ${i + 1}. $authorName : "$text..." ($createdAt)');
      }
      print('');
      
      // Vérifier la diversité des auteurs
      final uniqueAuthors = <String>{};
      for (var post in allPosts) {
        final authorName = (post as Map<String, dynamic>)['author_name'] as String?;
        if (authorName != null) uniqueAuthors.add(authorName);
      }
      
      print('   📊 Nombre d\'auteurs uniques : ${uniqueAuthors.length}');
      print('   👥 Auteurs : ${uniqueAuthors.join(', ')}');
      
      if (uniqueAuthors.length == 1) {
        print('   ⚠️ ATTENTION : Un seul auteur visible !');
        print('   → Cela suggère un problème de RLS ou de données\n');
      } else {
        print('   ✅ Plusieurs auteurs visibles (diversité OK)\n');
      }
    }
    
    // Test 2 : Vérifier les politiques RLS (via une requête qui échouerait si RLS bloque)
    print('📊 TEST 2 : Vérification des politiques RLS\n');
    print('   Test : Récupérer les posts d\'un autre utilisateur (ex: Saliou Djiba)\n');
    
    try {
      final otherUserPosts = await SupabaseService.instance.select(
        'forum_posts',
        columns: 'id, author_name, text',
        filters: {'author_name': 'Saliou Djiba'},
        limit: 5,
      );
      
      if (otherUserPosts.isEmpty) {
        print('   ⚠️ Aucun post trouvé pour "Saliou Djiba"');
        print('   → Soit cet utilisateur n\'a pas de posts, soit les données sont filtrées\n');
      } else {
        print('   ✅ ${otherUserPosts.length} posts de "Saliou Djiba" récupérés');
        print('   → Les politiques RLS permettent de voir les posts des autres utilisateurs\n');
      }
    } catch (e) {
      print('   ❌ ERREUR lors de la récupération des posts : $e');
      print('   → Cela suggère un problème de RLS restrictif\n');
    }
    
    // Test 3 : Compter le nombre total de posts
    print('📊 TEST 3 : Comptage total des posts\n');
    
    final countResult = await SupabaseService.instance.select(
      'forum_posts',
      columns: 'id',
    );
    
    final totalCount = countResult.length;
    print('   Nombre total de posts dans la base : $totalCount\n');
    
    if (totalCount == 0) {
      print('   ❌ PROBLÈME : La table est vide !');
      print('   → Aucun post n\'a été créé ou ils ont été supprimés\n');
    } else if (totalCount < 5) {
      print('   ⚠️ Peu de posts dans la base ($totalCount)');
      print('   → Créez plus de posts pour tester la visibilité\n');
    } else {
      print('   ✅ Nombre de posts suffisant pour les tests\n');
    }
    
    // Résumé final
    print('═══════════════════════════════════════════════════════════');
    print('📋 RÉSUMÉ DES TESTS\n');
    
    if (allPosts.length > 0 && uniqueAuthors.length > 1) {
      print('✅ TOUT EST OK !');
      print('   - Les posts sont récupérés correctement');
      print('   - Plusieurs auteurs sont visibles');
      print('   - Les politiques RLS fonctionnent correctement\n');
      print('💡 Si l\'app ne montre toujours qu\'un seul auteur :');
      print('   1. Redémarre l\'app avec hot restart (R)');
      print('   2. Vide le cache : flutter clean && flutter pub get');
      print('   3. Vérifie le code de CommunityForumService.listPosts()');
    } else if (allPosts.isEmpty) {
      print('❌ PROBLÈME CRITIQUE : Aucun post récupéré');
      print('   → Vérifiez la table forum_posts dans Supabase');
      print('   → Créez des posts de test avec différents utilisateurs');
    } else if (uniqueAuthors.length == 1) {
      print('⚠️ PROBLÈME POSSIBLE : Un seul auteur visible');
      print('   → Vérifiez les politiques RLS sur forum_posts');
      print('   → Appliquez la migration fix_forum_posts_rls_v2.sql');
      print('   → Utilisez le guide FIX_FORUM_POSTS_GUIDE.md');
    }
    
    print('═══════════════════════════════════════════════════════════\n');
    
  } catch (e, stackTrace) {
    print('❌ ERREUR CRITIQUE : $e');
    print('Stack trace : $stackTrace');
  }
}
