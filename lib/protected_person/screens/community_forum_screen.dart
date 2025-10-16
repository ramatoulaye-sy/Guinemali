import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/community_forum_service.dart';
// duplicate removed
import '../../core/services/storage_service.dart';
import 'dart:convert';

/// Écran principal du nouveau forum communautaire (v1 - squelette fonctionnel)
/// - Header interactif (recherche, notifications, profil)
/// - Catégories (Tous, Soutien, Conseil, Partage)
/// - Flux (placeholder, à connecter Supabase)
/// - Bouton "+ Nouveau post" (ouvre composer v1 minimal)
class CommunityForumScreen extends StatefulWidget {
  const CommunityForumScreen({Key? key}) : super(key: key);

  @override
  State<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends State<CommunityForumScreen> with TickerProviderStateMixin {
  final List<String> _categories = const ['Tous', 'Soutien', 'Conseil', 'Partage'];
  int _selectedIndex = 0;
  final _forum = CommunityForumService.instance;
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;
  String _searchQuery = '';
  // double _scrollY = 0; // removed (unused)
  bool _loadingFeed = true;
  static const int _pageSize = 20;
  int _page = 1;
  bool _isLoadingMore = false;
  DateTime _lastLoadMore = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fabScale = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fabCtrl.forward());
    // Précharger la liste (simule un chargement pour afficher les skeletons)
    () async {
      try { await _forum.listPosts(); } catch (_) {}
      if (mounted) setState(() { _loadingFeed = false; });
    }();
  }


// (déplacé plus bas en top-level)
  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF945acb),
        foregroundColor: Colors.white,
        toolbarHeight: 64,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
          iconSize: 28,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.push(AppConstants.routeVictimDashboard);
            }
          },
        ),
        titleSpacing: 0,
        title: InkWell(
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          onTap: () {
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentMaterialBanner();
            messenger.showMaterialBanner(
              MaterialBanner(
                backgroundColor: const Color(0xFF945acb),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                leading: const Icon(Icons.info_outline, color: Colors.white),
                content: const Text('Communauté', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                actions: const [SizedBox.shrink()],
              ),
            );
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            });
          },
          child: const SizedBox(
            height: 56,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Communauté', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
            iconSize: 24,
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () async {
              final res = await Navigator.of(context).push<Map<String, dynamic>?>(
                MaterialPageRoute(
                  builder: (_) => SearchPage(initialQuery: _searchQuery, categories: _categories, selectedIndex: _selectedIndex),
                ),
              );
              if (res != null) {
                setState(() {
                  _searchQuery = (res['query'] as String?) ?? '';
                  _selectedIndex = (res['index'] as int?) ?? _selectedIndex;
                });
              }
            },
            tooltip: 'Rechercher',
          ),
          IconButton(
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
            iconSize: 24,
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
            },
            tooltip: 'Notifications',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () { context.push(AppConstants.routeVictimProfile); },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<dynamic>(
                      future: SupabaseService.instance.select(
                        'utilisateurs',
                        columns: 'photo_url',
                        filters: {'id': SupabaseService.instance.currentUserId},
                        limit: 1,
                      ),
                      builder: (context, snapshot) {
                        String? url;
                        final list = snapshot.data as List<dynamic>?;
                        if (list != null && list.isNotEmpty) {
                          url = (list.first['photo_url'] as String?);
                        }
                        return CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFee82ee),
                          backgroundImage: (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
                          child: (url == null || url.isEmpty)
                              ? const Icon(Icons.person, size: 18, color: Colors.white)
                              : null,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        (context.read<AuthProvider>().currentUser?.prenom) ?? 'Utilisateur',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _CategoriesBar(
            categories: _categories,
            selectedIndex: _selectedIndex,
            onSelected: (i) => setState(() => _selectedIndex = i),
          ),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: AnimatedBuilder(
                key: ValueKey(_selectedIndex),
                animation: _forum,
                builder: (context, _) {
                  final focusId = CommunityForumService.focusPostId;
                  final base = _forum.posts;
                  // Si une cible est définie, prioriser son affichage en haut
                  final prioritized = focusId == null
                      ? base
                      : ([...base]..sort((a,b) => (a.id == focusId ? -1 : 0) - (b.id == focusId ? -1 : 0)));
                  final posts = prioritized.where((p) {
                    final cat = _categories[_selectedIndex];
                    final byCat = cat == 'Tous' || p.category == cat;
                    if (!byCat) return false;
                    if (_searchQuery.isEmpty) return true;
                    final q = _searchQuery.toLowerCase();
                    return p.text.toLowerCase().contains(q) ||
                           p.authorName.toLowerCase().contains(q) ||
                           p.category.toLowerCase().contains(q);
                  }).toList();
                  if (focusId != null) CommunityForumService.focusPostId = null;
                  if (_loadingFeed) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      itemBuilder: (_, i) => const _PostSkeletonCard(),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: 6,
                    );
                  }
                  if (posts.isEmpty) {
                    return _FeedPlaceholder(category: _categories[_selectedIndex]);
                  }
                  // Cursor-like pagination: on garde la tranche visible calculée localement,
                  // et on déclenche des fetchs "before" côté service.
                  final int end = (_page * _pageSize).clamp(0, posts.length);
                  final visible = posts.sublist(0, end);
                  final hasMore = end < posts.length;
                  return NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
                        _maybeLoadMore();
                      }
                      // (removed) scrollY tracking
                      return false;
                    },
                    child: RefreshIndicator(
                    color: const Color(0xFF945acb),
                    onRefresh: () async {
                      setState(() { _page = 1; });
                      try { await CommunityForumService.instance.listPostsBefore(before: DateTime.now().toUtc(), limit: _pageSize); } catch (_) {}
                      if (mounted) setState(() {});
                    },
                    child: ListView.separated(
                    key: PageStorageKey('feed-cat-$_selectedIndex'),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (_, i) {
                      if (hasMore && i == visible.length) {
                        // Demander une nouvelle page basée sur le dernier createdAt
                        final last = visible.isNotEmpty ? visible.last.createdAt : null;
                        if (!_isLoadingMore) {
                          _isLoadingMore = true;
                          CommunityForumService.instance
                              .listPostsBefore(before: last, limit: _pageSize)
                              .then((_) { if (mounted) setState(() { _page += 1; _isLoadingMore = false; }); })
                              .catchError((_) { if (mounted) setState(() { _isLoadingMore = false; }); });
                        }
                        return const _InfiniteLoader();
                      }
                      return _AnimatedPostCard(child: _PostCard(post: visible[i], index: i), index: i);
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: hasMore ? visible.length + 1 : visible.length,
                  )));
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: SafeArea(
        child: ScaleTransition(
          scale: _fabScale,
          child: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF945acb),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Nouveau post'),
            onPressed: () => _openComposer(context),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _openComposer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        final double targetHeight = (size.height - MediaQuery.of(ctx).viewPadding.top) * 0.98;
        return Container(
          height: targetHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: _ComposerSheet(onSubmit: (payload) async {
            final auth = context.read<AuthProvider>();
            final user = auth.currentUser;
            if (user == null) return;
            await _forum.createPost(
              authorId: user.id,
              authorName: user.prenom,
              category: payload.category,
              text: payload.text,
              medias: payload.medias,
              anonymous: payload.anonymous,
              hideAvatar: payload.hideAvatar,
            );
          }),
        );
      },
    );
  }

  void _maybeLoadMore() {
    final now = DateTime.now();
    if (_isLoadingMore) return;
    if (now.difference(_lastLoadMore).inMilliseconds < 500) return; // throttle
    _lastLoadMore = now;
    setState(() { _isLoadingMore = true; _page += 1; });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() { _isLoadingMore = false; });
    });
  }

}

bool _isUrl(String s) {
  return s.startsWith('http://') || s.startsWith('https://');
}

class _FeedAudio extends StatefulWidget {
  final String path;
  const _FeedAudio({Key? key, required this.path}) : super(key: key);
  @override
  State<_FeedAudio> createState() => _FeedAudioState();
}

class _FeedAudioState extends State<_FeedAudio> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _preloaded = false;
  String? _loadedPath;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((d) { if (mounted) setState(() => _pos = d); });
    _player.onDurationChanged.listen((d) { if (mounted) setState(() => _dur = d); });
    _player.onPlayerComplete.listen((_) { if (mounted) setState(() { _playing = false; _pos = Duration.zero; }); });
    _preloadIfNeeded();
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final hasPath = widget.path.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_fill, color: const Color(0xFF945acb)),
            onPressed: !hasPath ? null : () async {
              if (_playing) {
                await _player.pause();
                setState(() => _playing = false);
              } else {
                try {
                  await _ensureSource();
                  await _player.play(_isUrl(widget.path) ? UrlSource(widget.path) : DeviceFileSource(widget.path));
                  setState(() => _playing = true);
                } catch (_) {}
              }
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: (_dur.inMilliseconds == 0 || !_playing) ? 0 : (_pos.inMilliseconds / _dur.inMilliseconds).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade300,
                  color: const Color(0xFF945acb),
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Text(hasPath ? (_format(_pos) + ' / ' + _format(_dur)) : 'Audio non lisible', style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _preloadIfNeeded() async {
    if (_preloaded || widget.path.isEmpty) return;
    try {
      if (_isUrl(widget.path)) {
        await _player.setSource(UrlSource(widget.path));
    } else {
        await _player.setSource(DeviceFileSource(widget.path));
      }
      if (_dur == Duration.zero) {
        await _player.setVolume(0);
        await _player.resume();
        await Future.delayed(const Duration(milliseconds: 150));
        await _player.pause();
        await _player.setVolume(1);
      }
      _preloaded = true;
      _loadedPath = widget.path;
    } catch (_) {}
  }

  Future<void> _ensureSource() async {
    if (_loadedPath == widget.path && _preloaded) return;
    _preloaded = false;
    await _preloadIfNeeded();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// (supprimé) _GreetingTitle inutilisé

class SearchPage extends StatefulWidget {
  final String initialQuery;
  final List<String> categories;
  final int selectedIndex;
  const SearchPage({Key? key, required this.initialQuery, required this.categories, required this.selectedIndex}) : super(key: key);
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _index = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Rechercher', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF945acb),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Mot-clé... (texte, autrice, catégorie)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (int i = 0; i < widget.categories.length; i++)
                  _SearchPill(
                    label: widget.categories[i],
                    selected: _index == i,
                    onTap: () => setState(() => _index = i),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop({'query': '', 'index': _index}),
                    child: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF945acb), foregroundColor: Colors.white),
                    onPressed: () => Navigator.of(context).pop({'query': _controller.text, 'index': _index}),
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SearchPill({Key? key, required this.label, required this.selected, required this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF945acb);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary, width: 1.2),
          boxShadow: selected ? [BoxShadow(color: primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0,2))] : null,
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : primary, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _PostSkeletonCard extends StatelessWidget {
  const _PostSkeletonCard({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _ShimmerBar(width: 140, height: 14),
            SizedBox(height: 8),
            _ShimmerBar(width: 90, height: 10),
            SizedBox(height: 12),
            _ShimmerBar(width: double.infinity, height: 12),
            SizedBox(height: 6),
            _ShimmerBar(width: double.infinity, height: 12),
            SizedBox(height: 6),
            _ShimmerBar(width: 180, height: 12),
            SizedBox(height: 12),
            _ShimmerBox(height: 160),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBar extends StatefulWidget {
  final double width;
  final double height;
  const _ShimmerBar({Key? key, required this.width, required this.height}) : super(key: key);
  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 0.9).animate(_a),
      child: Container(
        width: widget.width == double.infinity ? double.infinity : widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  const _ShimmerBox({Key? key, required this.height}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _InfiniteLoader extends StatelessWidget {
  const _InfiniteLoader({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _SkeletonDot(),
          SizedBox(width: 8),
          _SkeletonDot(delayMs: 120),
          SizedBox(width: 8),
          _SkeletonDot(delayMs: 240),
        ],
      ),
    );
  }
}

class _SkeletonDot extends StatefulWidget {
  final int delayMs;
  const _SkeletonDot({Key? key, this.delayMs = 0}) : super(key: key);
  @override
  State<_SkeletonDot> createState() => _SkeletonDotState();
}

class _SkeletonDotState extends State<_SkeletonDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: const Color(0xFF945acb).withOpacity(0.6), shape: BoxShape.circle),
      ),
    );
  }
}

class _AnimatedPostCard extends StatelessWidget {
  final Widget child;
  final int index;
  const _AnimatedPostCard({Key? key, required this.child, required this.index}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      tween: Tween(begin: 0.96, end: 1.0),
      builder: (context, value, c) => Transform.translate(
        offset: Offset(0, (1 - value) * 14),
        child: Transform.scale(scale: value, child: Opacity(opacity: value, child: c)),
      ),
      child: child,
    );
  }
}
class _NotificationsSheet extends StatefulWidget {
  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];
  String _filter = 'Tous'; // Tous | Likes | Commentaires | Réponses

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await SupabaseService.ensureInitialized();
      final rows = await SupabaseService.instance.select(
        'notifications',
        columns: 'id, kind, title, message, created_at, is_read, read, read_at',
        orderBy: 'created_at', ascending: false,
        limit: 20,
      );
      setState(() {
        _items = (rows as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['Tous','Likes','Commentaires','Réponses'].map((f) => ChoiceChip(
                label: Text(f),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              )).toList(),
            ),
            const SizedBox(height: 8),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_loading) const SizedBox(height: 12),
            if (!_loading && _items.isEmpty)
              const Text('Aucune notification pour le moment.', style: TextStyle(color: Colors.black54)),
            if (_items.isNotEmpty)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filtered().length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = _filtered()[i];
                    final when = DateTime.tryParse(n['created_at']?.toString() ?? '');
                    return ListTile(
                      dense: true,
                      leading: Icon(_iconFor(n['kind']?.toString()), color: const Color(0xFF945acb)),
                      title: Text(n['title']?.toString() ?? ''),
                      subtitle: Text(n['message']?.toString() ?? ''),
                      trailing: Text(
                        when == null ? '' : _formatRelative(when),
                        style: const TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filtered() {
    if (_filter == 'Tous') return _items;
    final k = _filter.toLowerCase();
    return _items.where((n) => (n['kind']?.toString().toLowerCase() ?? '').contains(k.substring(0, k.length-1))).toList();
  }

  IconData _iconFor(String? kind) {
    switch ((kind ?? '').toLowerCase()) {
      case 'likes':
      case 'like':
        return Icons.favorite;
      case 'commentaires':
      case 'commentaire':
      case 'comments':
      case 'comment':
        return Icons.mode_comment;
      case 'reponses':
      case 'réponses':
      case 'reply':
      case 'replies':
        return Icons.reply;
      default:
        return Icons.notifications;
    }
  }

  String _formatRelative(DateTime dt) {
    final now = DateTime.now().toUtc();
    final d = now.difference(dt.toUtc());
    if (d.inMinutes < 1) return 'maintenant';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours} h';
    return '${d.inDays} j';
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];
  String _filter = 'Tous';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await SupabaseService.ensureInitialized();
      final userId = SupabaseService.instance.currentUserId;
      final rows = await SupabaseService.instance.select(
        'notifications',
        columns: 'id, kind, title, message, post_id, created_at, is_read, read, read_at, user_id',
        filters: userId == null ? null : {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
        limit: 50,
      );
      setState(() { _items = (rows as List).cast<Map<String, dynamic>>(); _loading = false; });
      // marquer lu tout de suite si souhaité
      try {
        for (final n in _items) {
          if (!(n['is_read'] == true || n['read'] == true || n['read_at'] != null)) {
            await SupabaseService.instance.update('notifications', {
              'is_read': true,
              'read': true,
              'read_at': DateTime.now().toIso8601String(),
            }, idColumn: 'id', idValue: n['id']);
          }
        }
      } catch (_) {}
    } catch (_) { setState(() { _loading = false; }); }
  }

  Future<void> _markAllRead() async {
    try {
      await SupabaseService.ensureInitialized();
      final ids = _items.map((e) => e['id']).toList();
      for (final id in ids) {
        try {
          await SupabaseService.instance.update('notifications', {'is_read': true, 'read': true, 'read_at': DateTime.now().toIso8601String()}, idColumn: 'id', idValue: id);
        } catch (_) {}
      }
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF945acb);
    const secondary = Color(0xFFee82ee);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _loading || _items.isEmpty ? null : _markAllRead,
            child: const Text('Tout marquer lu', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: ['Tous','Likes','Commentaires','Réponses'].map((f) => ChoiceChip(
                label: Text(
                  f,
                  style: TextStyle(
                    color: _filter == f ? Colors.white : primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                selected: _filter == f,
                selectedColor: primary,
                backgroundColor: Colors.white,
                shape: const StadiumBorder(side: BorderSide(color: primary)),
                onSelected: (_) => setState(() => _filter = f),
              )).toList(),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Aucune notification', style: TextStyle(color: Colors.black54)))
                : ListView.separated(
                    itemCount: _filtered().length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final n = _filtered()[i];
                      final when = DateTime.tryParse(n['created_at']?.toString() ?? '');
                      final isRead = (n['is_read'] == true) || (n['read'] == true) || (n['read_at'] != null);
                      return ListTile(
                        leading: Container(
                          decoration: BoxDecoration(color: secondary.withOpacity(0.18), shape: BoxShape.circle),
                          padding: const EdgeInsets.all(8),
                          child: Icon(_iconFor(n['kind']?.toString()), color: primary),
                        ),
                        title: Text(n['title']?.toString() ?? '', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
                        subtitle: Text(n['message']?.toString() ?? '', style: const TextStyle(color: Colors.black54)),
                        trailing: Text(when == null ? '' : _formatRelativeGlobal(when), style: const TextStyle(fontSize: 12, color: Colors.black45)),
                        tileColor: isRead ? Colors.white : const Color(0xFFF8F5FF),
                        onTap: () async {
                          final postId = n['post_id'] ?? n['postId'];
                          // Naviguer en priorité immédiatement
                          if (postId != null) {
                            try {
                              CommunityForumService.instance.setFocusPost(postId.toString());
                              if (mounted) Navigator.of(context).maybePop();
                            } catch (_) {}
                          }
                          // Marquer lu en arrière-plan (sans bloquer l'UI)
                          () async {
                            try {
                              await SupabaseService.ensureInitialized();
                              await SupabaseService.instance.update('notifications', {
                                'is_read': true,
                                'read': true,
                                'read_at': DateTime.now().toIso8601String(),
                              }, idColumn: 'id', idValue: n['id']);
                            } catch (_) {}
                          }();
                          // Mettre à jour la liste visuelle
                          if (mounted) setState(() {
                            n['is_read'] = true; n['read'] = true; n['read_at'] = DateTime.now().toIso8601String();
                          });
                        },
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filtered() {
    if (_filter == 'Tous') return _items;
    final k = _filter.toLowerCase();
    return _items.where((n) => (n['kind']?.toString().toLowerCase() ?? '').contains(k.substring(0, k.length-1))).toList();
  }

  IconData _iconFor(String? kind) {
    switch ((kind ?? '').toLowerCase()) {
      case 'likes':
      case 'like':
        return Icons.favorite;
      case 'commentaires':
      case 'commentaire':
      case 'comments':
      case 'comment':
        return Icons.mode_comment;
      case 'reponses':
      case 'réponses':
      case 'reply':
      case 'replies':
        return Icons.reply;
      default:
        return Icons.notifications;
    }
  }
}

String _formatRelativeGlobal(DateTime dt) {
  final now = DateTime.now().toUtc();
  final d = now.difference(dt.toUtc());
  if (d.inMinutes < 1) return 'maintenant';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  if (d.inHours < 24) return '${d.inHours} h';
  return '${d.inDays} j';
}

class _AnonHelpModal extends StatefulWidget {
  const _AnonHelpModal({Key? key}) : super(key: key);
  @override
  State<_AnonHelpModal> createState() => _AnonHelpModalState();
}

class _AnonHelpModalState extends State<_AnonHelpModal> {
  final TextEditingController _text = TextEditingController();
  bool _sending = false;
  final List<Map<String, dynamic>> _messages = [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: const [
                Icon(Icons.lock_outline, color: Color(0xFF945acb)),
                SizedBox(width: 8),
                Text('Entraide anonyme', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Votre message sera pseudonymisé côté serveur. Pas de donnée personnelle locale.', style: TextStyle(color: Colors.black54, fontSize: 12)),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i];
                  final mine = m['mine'] == true;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
                        color: mine ? const Color(0xFF945acb) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        m['text'] ?? '',
                        style: TextStyle(color: mine ? Colors.white : Colors.black87),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    decoration: const InputDecoration(hintText: 'Écrire...', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF945acb), foregroundColor: Colors.white, minimumSize: const Size(48,48), padding: EdgeInsets.zero),
                    onPressed: _sending ? null : _send,
                    child: _sending ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2, color: Colors.white)) : const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final content = _text.text.trim();
    if (content.isEmpty) return;
    setState(() { _sending = true; _messages.add({'text': content, 'mine': true}); _text.clear(); });
    try {
      await SupabaseService.ensureInitialized();
      await SupabaseService.instance.insert('entraide_messages', {
        'content': content,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      setState(() { _sending = false; });
    } catch (_) {
      setState(() { _sending = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec envoi. Réessayez.')));
    }
  }
}
class _CategoriesBar extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _CategoriesBar({
    Key? key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, i) {
            final selected = i == selectedIndex;
            final String label = categories[i];
            IconData? icon;
            switch (label.toLowerCase()) {
              case 'tous':
                icon = Icons.grid_view_rounded; break;
              case 'soutien':
                icon = Icons.favorite; break;
              case 'conseil':
                icon = Icons.lightbulb; break;
              case 'partage':
                icon = Icons.share_rounded; break;
            }
            const Color primary = Color(0xFF945acb);
            final Color selBg = primary;
            final Color unselBg = Colors.white;
            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => onSelected(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
                  color: selected ? selBg : unselBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primary, width: 1),
                  boxShadow: selected ? [BoxShadow(color: primary.withOpacity(0.35), blurRadius: 8, offset: const Offset(0,2))] : null,
      ),
                      child: Row(
        children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: selected ? Colors.white : primary),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: TextStyle(color: selected ? Colors.white : primary, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemCount: categories.length,
        ),
      ),
    );
  }
}

class _FeedPlaceholder extends StatelessWidget {
  final String category;
  const _FeedPlaceholder({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
            width: 80,
            height: 80,
                            decoration: BoxDecoration(
              color: const Color(0xFFee82ee).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.forum_outlined, size: 40, color: Color(0xFF945acb)),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun post dans "$category"',
            style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Soyez la première à partager quelque chose !',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
                          ),
                        ],
                      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final ForumPost post;
  final int index;
  const _PostCard({Key? key, required this.post, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final forum = CommunityForumService.instance;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final userId = user?.id ?? '';
    final isLiked = post.likedBy.contains(userId);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      tween: Tween(begin: 0.2, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20 + (index % 2 == 0 ? 0 : 3)),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 3,
        shadowColor: Colors.black26,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                _AvatarOrPlaceholder(post: post),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
                      post.anonymous ? 'Anonyme' : post.authorName,
            style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: post.anonymous ? const Color(0xFF945acb) : Colors.black87,
                        fontStyle: post.anonymous ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _categoryColor(post.category).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        post.category,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _categoryColor(post.category)),
                      ),
                    ),
                  ]),
                ),
                Text(_formatTime(post.createdAt), style: const TextStyle(fontSize: 12, color: Colors.black45)),
                const SizedBox(width: 4),
                _PostMenu(post: post),
              ],
            ),
            if ((post.moderation ?? 'approved') != 'approved') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  border: Border.all(color: const Color(0xFFFFC107)),
                borderRadius: BorderRadius.circular(12),
              ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 18, color: Color(0xFFFFC107)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.moderation == 'pending'
                            ? 'En attente de modération'
                            : 'Refusé par la modération',
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(post.text, style: const TextStyle(color: Colors.black87, height: 1.4)),
            if (post.medias.isNotEmpty) ...[
              const SizedBox(height: 10),
              _MediaGallery(medias: post.medias),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: isLiked ? 1.15 : 1),
                  duration: const Duration(milliseconds: 180),
                  builder: (context, s, child) => Transform.scale(scale: s, child: child),
                  child: IconButton(
                    icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? const Color(0xFF945acb) : Colors.black54),
                    onPressed: userId.isEmpty ? null : () => forum.toggleLike(postId: post.id, userId: userId),
                  ),
                ),
                Text(post.likedBy.length.toString(), style: const TextStyle(color: Colors.black54)),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined, color: Colors.black54),
                  onPressed: () => _openComments(context, post),
                  tooltip: 'Commentaires',
                ),
                Text(_countComments(post).toString(), style: const TextStyle(color: Colors.black54)),
                const Spacer(),
                InkResponse(
                  radius: 24,
                  onTap: () {
                    final firstMediaUrl = post.medias.isNotEmpty ? post.medias.first.localPath : null;
                    final text = '${post.authorName} • ${post.category}\n\n${post.text}';
                    if (firstMediaUrl != null && firstMediaUrl.startsWith('http')) {
                      Share.share('$text\n\n$firstMediaUrl');
                    } else {
                      Share.share(text);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.share_outlined, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ],
          ),
        ),
      ),
    );

  }

  static Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'soutien':
        return const Color(0xFF4A90E2);
      case 'conseil':
        return const Color(0xFF2ECC71);
      case 'partage':
        return const Color(0xFFF1C40F);
      default:
        return const Color(0xFF945acb);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now().toUtc();
    final d = now.difference(dt.toUtc());
    if (d.inMinutes < 1) return 'maintenant';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours} h';
    return '${d.inDays} j';
  }

  int _countComments(ForumPost p) {
    int total = 0;
    void walk(List<ForumComment> list) {
      for (final c in list) {
        total++;
        walk(c.replies);
      }
    }
    walk(p.comments);
    return total;
  }

  void _openComments(BuildContext context, ForumPost post) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: _CommentsSheet(post: post),
          );
        },
      ),
    );
  }
}

class _PostMenu extends StatelessWidget {
  final ForumPost post;
  const _PostMenu({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    final isOwner = userId != null && userId == post.authorId;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black45),
      onSelected: (value) async {
        if (value == 'delete') {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Supprimer le post'),
              content: const Text('Voulez-vous vraiment supprimer ce post ?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
              ],
            ),
          );
          if (ok == true && userId != null) {
            try {
              await CommunityForumService.instance.deletePost(postId: post.id, userId: userId);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post supprimé')));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de supprimer: $e')));
            }
          }
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        if (isOwner) {
          items.add(const PopupMenuItem<String>(value: 'delete', child: Text('Supprimer')));
        }
        if (items.isEmpty) {
          items.add(const PopupMenuItem<String>(enabled: false, child: Text('Aucune action')));
        }
        return items;
      },
    );
  }
}

class _MediaGallery extends StatelessWidget {
  final List<ForumMedia> medias;
  const _MediaGallery({Key? key, required this.medias}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (medias.length == 1) {
      final m = medias.first;
      return _mediaBox(context, m);
    }
    // Affichage vertical pour respecter les tailles naturelles
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < medias.length; i++) ...[
          _mediaBox(context, medias[i]),
          if (i != medias.length - 1) const SizedBox(height: 8),
        ]
      ],
    );
  }

  Widget _mediaBox(BuildContext context, ForumMedia m) {
    if (m.kind == 'image') {
      final tag = 'forum-image-${m.localPath.hashCode}';
      return GestureDetector(
        onTap: () => _openImagePreview(context, m.localPath, tag),
        child: Hero(
          tag: tag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isUrl(m.localPath)
                ? Image.network(
                    m.localPath,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: child,
                      );
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        height: 180,
                      );
                    },
                  )
                : Image.file(
                    File(m.localPath),
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
            ),
          ),
        ),
      );
    }
    if (m.kind == 'video') {
      return _FeedVideo(path: m.localPath);
    }
    if (m.kind == 'audio') {
      return _FeedAudio(path: m.localPath);
    }
    return const SizedBox.shrink();
  }

  void _openImagePreview(BuildContext context, String path, String tag) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (dialogCtx) => GestureDetector(
        onTap: () => Navigator.of(dialogCtx).pop(),
        child: Center(
          child: Hero(
            tag: tag,
            child: InteractiveViewer(
              child: Builder(
                builder: (_) {
                  if (_isUrl(path)) {
                    return Image.network(path);
                  }
                  final f = File(path);
                  if (!f.existsSync()) {
                    return const Icon(Icons.broken_image, color: Colors.white70, size: 64);
                  }
                  return Image.file(f);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final ForumPost post;
  const _CommentsSheet({Key? key, required this.post}) : super(key: key);

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _text = TextEditingController();
  String? _replyTo; // commentId ciblé pour répondre
  bool _sending = false;
  ForumComment? _replyingTo; // affiche la cible de réponse

  @override
  Widget build(BuildContext context) {
    final forum = CommunityForumService.instance;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final userId = user?.id ?? '';

    final insets = MediaQuery.of(context).viewInsets;
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: SizedBox(
        height: size.height * 0.9,
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: Column(
          children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 8),
              const Text('Commentaires', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
              const Divider(height: 1),
              Expanded(
                child: AnimatedBuilder(
                  animation: forum,
                  builder: (context, _) {
                    return ListView(
                      padding: const EdgeInsets.all(12),
                      children: _buildComments(widget.post.comments, forum, userId),
                    );
                  },
                ),
              ),
              if (_replyingTo != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
                      Expanded(
                        child: Text('Réponse à ${_replyingTo!.authorName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ),
                      TextButton(onPressed: () => setState(() { _replyTo = null; _replyingTo = null; }), child: const Text('Annuler'))
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
            children: [
          Expanded(
                      child: TextField(
                        controller: _text,
                        style: const TextStyle(color: Colors.black87),
                        cursorColor: Color(0xFF945acb),
              decoration: InputDecoration(
                          hintText: _replyTo == null ? 'Écrire un commentaire...' : 'Répondre...',
                          hintStyle: const TextStyle(color: Colors.black87),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF945acb), width: 1.4)),
              ),
            ),
          ),
                    const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: userId.isEmpty || _sending
                          ? null
                          : () async {
                              final content = _text.text.trim();
                              if (content.isEmpty) return;
                              setState(() { _sending = true; });
                              await forum.addComment(
                                postId: widget.post.id,
                                authorId: userId,
                                authorName: user?.prenom ?? 'Anonyme',
                                text: content,
                                parentCommentId: _replyTo,
                              );
              setState(() {
                                _sending = false;
                                _text.clear();
                                _replyTo = null;
                                _replyingTo = null;
                              });
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF945acb), foregroundColor: Colors.white),
                      child: _sending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Envoyer'),
                    ),
                  )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildComments(List<ForumComment> list, CommunityForumService forum, String userId) {
    final widgets = <Widget>[];
    for (final c in list) {
      widgets.add(_CommentTile(
        comment: c,
        onReply: () => setState(() { _replyTo = c.id; _replyingTo = c; }),
        onToggleLike: () => forum.toggleCommentLike(postId: widget.post.id, commentId: c.id, userId: userId),
      ));
      if (c.replies.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Column(children: _buildComments(c.replies, forum, userId)),
        ));
      }
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }
}

class _CommentMenu extends StatelessWidget {
  final ForumComment comment;
  const _CommentMenu({Key? key, required this.comment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    final isOwner = userId != null && userId == comment.authorId;
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert, size: 18, color: Colors.black45),
      onSelected: (v) async {
        if (v == 'edit' && isOwner) {
          final newText = await showDialog<String>(
            context: context,
            builder: (_) => _EditCommentDialog(initialText: comment.text),
          );
          if (newText != null && newText.trim().isNotEmpty) {
            try {
              await CommunityForumService.instance.editComment(
                postId: _findPostId(context),
                commentId: comment.id,
                userId: userId,
                newText: newText.trim(),
              );
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commentaire modifié')));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec modification: $e')));
            }
          }
        } else if (v == 'delete' && isOwner) {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Supprimer le commentaire'),
              content: const Text('Voulez-vous vraiment supprimer ce commentaire ?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
              ],
            ),
          );
          if (ok == true) {
            try {
              await CommunityForumService.instance.deleteComment(postId: _findPostId(context), commentId: comment.id, userId: userId);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commentaire supprimé')));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec suppression: $e')));
            }
          }
        }
      },
      itemBuilder: (_) {
        final items = <PopupMenuEntry<String>>[];
        if (isOwner) {
          items.add(const PopupMenuItem<String>(value: 'edit', child: Text('Modifier')));
          items.add(const PopupMenuItem<String>(value: 'delete', child: Text('Supprimer')));
        }
        if (items.isEmpty) items.add(const PopupMenuItem<String>(enabled: false, child: Text('Aucune action')));
        return items;
      },
    );
  }

  // Remonte jusqu'au sheet pour récupérer l'id du post
  String _findPostId(BuildContext context) {
    // Le sheet possède le post dans son State -> on traverse via context.findAncestorStateOfType
    final st = context.findAncestorStateOfType<_CommentsSheetState>();
    return st!.widget.post.id;
  }
}

class _EditCommentDialog extends StatefulWidget {
  final String initialText;
  const _EditCommentDialog({Key? key, required this.initialText}) : super(key: key);
  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late final TextEditingController _c;
  @override
  void initState() { super.initState(); _c = TextEditingController(text: widget.initialText); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le commentaire'),
      content: TextField(
        controller: _c,
        maxLines: 5,
        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Votre texte...'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.of(context).pop(_c.text.trim()), child: const Text('Enregistrer')),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final ForumComment comment;
  final VoidCallback onReply;
  final VoidCallback onToggleLike;
  const _CommentTile({Key? key, required this.comment, required this.onReply, required this.onToggleLike}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLiked = comment.likedBy.isNotEmpty; // simplifié
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentAuthorAvatar(authorId: comment.authorId, anonymous: false),
        const SizedBox(width: 8),
        Expanded(
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(comment.text, style: const TextStyle(color: Colors.black87, height: 1.35)),
              Row(
                children: [
                  Text(_formatTime(comment.createdAt), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(width: 12),
                  InkWell(onTap: onReply, child: const Text('Répondre', style: TextStyle(fontSize: 12, color: Color(0xFF945acb), fontWeight: FontWeight.w600))),
                  const SizedBox(width: 12),
                  _CommentMenu(comment: comment),
                ],
              )
            ],
          ),
        ),
        IconButton(onPressed: onToggleLike, icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 18, color: isLiked ? const Color(0xFF945acb) : Colors.black54)),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now().toUtc();
    final d = now.difference(dt.toUtc());
    if (d.inMinutes < 1) return 'maintenant';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours} h';
    return '${d.inDays} j';
  }
}

class _ComposerPayload {
  final String category;
  final String text;
  final List<ForumMedia> medias;
  final bool anonymous;
  final bool hideAvatar;
  _ComposerPayload({required this.category, required this.text, required this.medias, this.anonymous = false, this.hideAvatar = false});
}
class _ComposerSheet extends StatefulWidget {
  final void Function(_ComposerPayload payload) onSubmit;
  const _ComposerSheet({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends State<_ComposerSheet> with TickerProviderStateMixin {
  final TextEditingController _text = TextEditingController();
  String _category = 'Tous';
  final ImagePicker _picker = ImagePicker();
  final List<_PickedMedia> _medias = [];
  bool _pickerBusy = false;
  bool _anonymous = false;
  bool _hideAvatarsInFeed = false;
  // Couleurs de marque (réutilisées dans la déco ci-dessous)
  static const Color _violet = Color(0xFF945acb);
  static const Color _violetSoft = Color(0xFFee82ee);
  static const Color _onViolet = Colors.white;
  late final AnimationController _bgCtrl;
  late final AnimationController _enterCtrl;
  late final Animation<Offset> _enterSlide;
  late final Animation<double> _enterFade;
  bool _published = false;
  static const String _draftKey = 'forum_draft_v1';

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _enterSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));
    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _enterCtrl.forward(); });
    // Charger les préférences par défaut (peuvent être écrasées par un brouillon ensuite)
    try {
      _anonymous = StorageService.instance.getBool('pref_anonymous_default', defaultValue: false);
      _hideAvatarsInFeed = StorageService.instance.getBool('pref_hide_avatar_default', defaultValue: false);
    } catch (_) {}
    _loadDraftIfAny();
  }

  @override
  void dispose() {
    _saveDraftIfNeeded();
    _bgCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: insets.bottom),
          child: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, child) {
              final t = (_bgCtrl.value * 2 - 1).clamp(-1.0, 1.0);
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1, t),
                    end: Alignment(1, -t),
                    colors: [
                      _violet.withOpacity(0.025),
                      Colors.white,
                      _violetSoft.withOpacity(0.035),
                    ],
                  ),
                ),
                child: child,
              );
            },
            child: Material(
              elevation: 2,
              color: Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SlideTransition(
                position: _enterSlide,
                child: FadeTransition(
                  opacity: _enterFade,
      child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Bande décorative en dégradé pour ancrer l'identité visuelle
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [_violet, _violetSoft],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
          ),
          const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                  children: const [
                    CircleAvatar(radius: 18, backgroundColor: _violet, child: Icon(Icons.brush, color: _onViolet, size: 18)),
                    SizedBox(width: 10),
                    Text('Créer un post', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Partage ton histoire, inspire une autre femme.', style: TextStyle(color: Colors.black54)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _CategoryBadge(label: 'Tous', color: const Color(0xFF945acb), selected: _category == 'Tous', onTap: () => setState(() => _category = 'Tous')),
                  _CategoryBadge(label: 'Soutien', color: const Color(0xFF4A90E2), selected: _category == 'Soutien', onTap: () => setState(() => _category = 'Soutien')),
                  _CategoryBadge(label: 'Conseil', color: const Color(0xFF2ECC71), selected: _category == 'Conseil', onTap: () => setState(() => _category = 'Conseil')),
                  _CategoryBadge(label: 'Partage', color: const Color(0xFFF1C40F), selected: _category == 'Partage', onTap: () => setState(() => _category = 'Partage')),
                  _TogglePill(
                    label: 'Publier en anonyme',
                    selected: _anonymous,
                    onTap: () => setState(() => _anonymous = !_anonymous),
                  ),
                  _TogglePill(
                    label: 'Masquer mon avatar (fil)',
                    selected: _hideAvatarsInFeed,
                    onTap: () => setState(() => _hideAvatarsInFeed = !_hideAvatarsInFeed),
          ),
        ],
      ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _text,
                minLines: 3,
                maxLines: 10,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Exprime-toi librement…',
                  hintStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _violet, width: 1.4)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_pickerBusy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_pickerBusy) const SizedBox(height: 8),
            if (_medias.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _MediaPreviewList(
                  medias: _medias,
                  onRemove: (m) => setState(() => _medias.remove(m)),
                ),
              ),
            if (_medias.isNotEmpty) const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(builder: (context, c) {
                final isWide = c.maxWidth > 520;
                final buttons = <Widget>[
                  _MediaActionButton(icon: Icons.photo_outlined, label: 'Image', onTap: _pickImageFromGallery, color: _violet, accent: _violetSoft),
                  _MediaActionButton(icon: Icons.videocam_outlined, label: 'Vidéo', onTap: _pickVideoFromGallery, color: _violet, accent: _violetSoft),
                  _MediaActionButton(icon: Icons.photo_camera_outlined, label: 'Caméra', onTap: _capturePhoto, color: _violet, accent: _violetSoft),
                  _MediaActionButton(icon: Icons.mic_none_outlined, label: 'Audio', onTap: _pickAudioFile, color: _violet, accent: _violetSoft),
                  _MediaActionButton(icon: Icons.videocam_rounded, label: 'Vidéo (caméra)', onTap: _captureVideo, color: _violet, accent: _violetSoft),
                  OutlinedButton(
                    onPressed: _openPreview,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _violet.withOpacity(0.9), width: 1.2),
                      foregroundColor: _violet,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(140, 48),
                    ),
                    child: const Text('Prévisualiser'),
                  ),
                ];
                if (isWide) {
                  return GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.2,
                    children: buttons.map((w) => Center(child: w)).toList(),
                  );
                }
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: buttons,
                );
              }),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.rocket_launch_rounded),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _violet,
                      foregroundColor: _onViolet,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
            onPressed: () {
                      _published = true;
                      final payload = _ComposerPayload(
                        category: _category,
                        text: _text.text.trim(),
                        medias: _medias.map((m) => ForumMedia(
                              kind: m.kind.name,
                              localPath: m.xfile?.path ?? m.platformFile?.path ?? '',
              )).toList(),
                        anonymous: _anonymous,
                        hideAvatar: _hideAvatarsInFeed,
                      );
                      widget.onSubmit(payload);
                      // Clear draft
                      try { StorageService.instance.saveString(_draftKey, ''); } catch (_) {}
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post publié avec succès !')),
                      );
                    },
                    label: const Text('Publier'),
            ),
          ),
        ),
            ),
            const SizedBox(height: 20),
          ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveDraftIfNeeded() {
    if (_published) return;
    final hasContent = _text.text.trim().isNotEmpty || _medias.isNotEmpty || _category != 'Tous';
    if (!hasContent) {
      try { StorageService.instance.saveString(_draftKey, ''); } catch (_) {}
      return;
    }
    try {
      final data = {
        'category': _category,
        'text': _text.text.trim(),
        'anonymous': _anonymous,
        'hideAvatarsInFeed': _hideAvatarsInFeed,
        'medias': _medias.map((m) => {
          'kind': m.kind.name,
          'path': m.xfile?.path ?? m.platformFile?.path ?? '',
        }).where((e) => (e['path'] as String).isNotEmpty).toList(),
      };
      StorageService.instance.saveString(_draftKey, jsonEncode(data));
    } catch (_) {}
  }

  void _loadDraftIfAny() {
    try {
      final raw = StorageService.instance.getString(_draftKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _category = (map['category'] as String?) ?? 'Tous';
      _text.text = (map['text'] as String?) ?? '';
      _anonymous = (map['anonymous'] as bool?) ?? false;
      _hideAvatarsInFeed = (map['hideAvatarsInFeed'] as bool?) ?? false;
      final List medias = (map['medias'] as List?) ?? [];
      for (final m in medias) {
        final kind = m['kind'] as String?;
        final path = m['path'] as String?;
        if (path == null || path.isEmpty) continue;
        if (kind == 'image') {
          _medias.add(_PickedMedia.image(XFile(path)));
        } else if (kind == 'video') {
          _medias.add(_PickedMedia.video(XFile(path)));
        } else if (kind == 'audio') {
          try {
            final f = File(path);
            final size = f.existsSync() ? f.lengthSync() : 0;
            _medias.add(_PickedMedia.audio(PlatformFile(name: path.split('/').last, path: path, size: size)));
          } catch (_) {
            _medias.add(_PickedMedia.audio(PlatformFile(name: path.split('/').last, path: path, size: 0)));
          }
        }
      }
      setState(() {});
    } catch (_) {}
  }

  Future<void> _pickImageFromGallery() async {
    if (_pickerBusy) return; _pickerBusy = true;
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file != null) {
        setState(() => _medias.add(_PickedMedia.image(file)));
      }
    } finally {
      _pickerBusy = false;
    }
  }

  Future<void> _pickVideoFromGallery() async {
    if (_pickerBusy) return; _pickerBusy = true;
    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
      if (file != null) {
        setState(() => _medias.add(_PickedMedia.video(file)));
      }
    } finally {
      _pickerBusy = false;
    }
  }

  Future<void> _capturePhoto() async {
    if (_pickerBusy) return; _pickerBusy = true;
    try {
      final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (file != null) {
        setState(() => _medias.add(_PickedMedia.image(file)));
      }
    } finally {
      _pickerBusy = false;
    }
  }

  Future<void> _captureVideo() async {
    if (_pickerBusy) return; _pickerBusy = true;
    try {
      final file = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(minutes: 2));
      if (file != null) {
        setState(() => _medias.add(_PickedMedia.video(file)));
      }
    } finally {
      _pickerBusy = false;
    }
  }

  Future<void> _pickAudioFile() async {
    if (_pickerBusy) return; _pickerBusy = true;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: false);
      if (result != null && result.files.isNotEmpty) {
        setState(() => _medias.add(_PickedMedia.audio(result.files.first)));
      }
    } finally {
      _pickerBusy = false;
    }
  }

  void _openPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
        backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        final text = _text.text.trim();
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    Row(
                      children: const [
                        Icon(Icons.preview, color: Color(0xFF945acb)),
                        SizedBox(width: 8),
                        Text('Aperçu du post', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(text.isEmpty ? '(Pas de texte)' : text, style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 12),
                    if (_medias.isNotEmpty)
                      _MediaPreviewGrid(medias: _medias),
                    const SizedBox(height: 16),
                    Row(
            children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Modifier'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF945acb), foregroundColor: Colors.white),
            onPressed: () {
                              final payload = _ComposerPayload(
                                category: _category,
                                text: _text.text.trim(),
                                medias: _medias.map((m) => ForumMedia(kind: m.kind.name, localPath: m.xfile?.path ?? m.platformFile?.path ?? '')).toList(),
                                anonymous: _anonymous,
                              );
                              widget.onSubmit(payload);
              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post enregistré (cache)')));
                            },
                            child: const Text('Confirmer et publier'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AvatarOrPlaceholder extends StatelessWidget {
  final ForumPost post;
  const _AvatarOrPlaceholder({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si anonyme OU hideAvatar activé, avatar générique
    if (post.anonymous || post.hideAvatar) {
      return const CircleAvatar(
        radius: 16,
        backgroundColor: Color(0xFFee82ee),
        child: Icon(Icons.person, size: 18, color: Colors.white),
      );
    }
    return _PostAuthorAvatar(authorId: post.authorId);
  }
}

class _PostAuthorAvatar extends StatelessWidget {
  final String authorId;
  const _PostAuthorAvatar({Key? key, required this.authorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: SupabaseService.instance.select('utilisateurs', columns: 'photo_url', filters: {'id': authorId}),
      builder: (context, snapshot) {
        final list = snapshot.data as List<dynamic>?;
        final url = (list != null && list.isNotEmpty)
            ? (list.first['photo_url'] as String?)
            : null;
        return CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFee82ee),
          backgroundImage: (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
          child: (url == null || url.isEmpty)
              ? const Icon(Icons.person, size: 18, color: Colors.white)
              : null,
        );
      },
    );
  }
}

class _CommentAuthorAvatar extends StatelessWidget {
  final String authorId;
  final bool anonymous;
  const _CommentAuthorAvatar({Key? key, required this.authorId, required this.anonymous}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (anonymous) {
      return const CircleAvatar(radius: 14, backgroundColor: Color(0xFFee82ee), child: Icon(Icons.person, size: 16, color: Colors.white));
    }
    return FutureBuilder<dynamic>(
      future: SupabaseService.instance.select('utilisateurs', columns: 'photo_url', filters: {'id': authorId}),
      builder: (context, snapshot) {
        final list = snapshot.data as List<dynamic>?;
        final url = (list != null && list.isNotEmpty)
            ? (list.first['photo_url'] as String?)
            : null;
        return CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFFee82ee),
          backgroundImage: (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
          child: (url == null || url.isEmpty)
              ? const Icon(Icons.person, size: 16, color: Colors.white)
              : null,
        );
      },
    );
  }
}

class _MediaPreviewList extends StatelessWidget {
  final List<_PickedMedia> medias;
  final ValueChanged<_PickedMedia> onRemove;
  const _MediaPreviewList({Key? key, required this.medias, required this.onRemove}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final m = medias[i];
          return Stack(
            clipBehavior: Clip.none,
      children: [
              _MediaTile(media: m),
              Positioned(
                right: -6,
                top: -6,
                child: InkWell(
                  onTap: () => onRemove(m),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black87,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              )
            ],
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: medias.length,
      ),
    );
  }
}

class _MediaActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color accent;
  const _MediaActionButton({Key? key, required this.icon, required this.label, required this.onTap, this.color = const Color(0xFF945acb), this.accent = const Color(0xFFee82ee)}) : super(key: key);

  @override
  State<_MediaActionButton> createState() => _MediaActionButtonState();
}

class _MediaActionButtonState extends State<_MediaActionButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapCancel: () => _c.reverse(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      child: ScaleTransition(
        scale: _scale,
                child: Container(
          height: 48,
                  decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color, width: 1.2),
            color: Colors.white,
            boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.16), blurRadius: 8, offset: const Offset(0,2))],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color),
              const SizedBox(width: 8),
              Text(widget.label, style: TextStyle(color: widget.color, fontWeight: FontWeight.w600)),
            ],
                    ),
                  ),
                ),
    );
  }
}

class _CategoryBadge extends StatefulWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryBadge({Key? key, required this.label, required this.color, required this.selected, required this.onTap}) : super(key: key);

  @override
  State<_CategoryBadge> createState() => _CategoryBadgeState();
}

class _TogglePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TogglePill({Key? key, required this.label, required this.selected, required this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF945acb);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: primary, width: 1.2),
          boxShadow: selected ? [BoxShadow(color: primary.withOpacity(0.28), blurRadius: 10, offset: const Offset(0,3))] : null,
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : primary, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _CategoryBadgeState extends State<_CategoryBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulse = Tween(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.selected) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _CategoryBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.selected && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.selected;
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pulse,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? widget.color : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: widget.color, width: 1.2),
            boxShadow: selected ? [BoxShadow(color: widget.color.withOpacity(0.28), blurRadius: 10, offset: const Offset(0,3))] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: selected ? Colors.white : widget.color),
              const SizedBox(width: 8),
              Text(widget.label, style: TextStyle(color: selected ? Colors.white : widget.color, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaPreviewGrid extends StatelessWidget {
  final List<_PickedMedia> medias;
  const _MediaPreviewGrid({Key? key, required this.medias}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: medias.map((m) {
        switch (m.kind) {
          case _PickedKind.image:
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(m.xfile!.path), width: 120, height: 120, fit: BoxFit.cover),
            );
          case _PickedKind.video:
            return _VideoPreviewTile(path: m.xfile!.path);
          case _PickedKind.audio:
            return _AudioPreviewTile(path: m.platformFile?.path ?? m.xfile?.path ?? '');
        }
      }).toList(),
    );
  }
}

class _VideoPreviewTile extends StatefulWidget {
  final String path;
  const _VideoPreviewTile({Key? key, required this.path}) : super(key: key);
  @override
  State<_VideoPreviewTile> createState() => _VideoPreviewTileState();
}

class _VideoPreviewTileState extends State<_VideoPreviewTile> {
  VideoPlayerController? _controller;
  bool _init = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) { 
        if (mounted) setState(() { _init = true; }); 
        // DÉSACTIVER L'AUTO-PLAY - vidéos en pause par défaut
      });
  }

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _init ? () => setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      }) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 180,
          height: 120,
          color: Colors.black12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_init) AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!))
              else const Icon(Icons.videocam, color: Colors.black54),
              Container(
                decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                padding: const EdgeInsets.all(8),
                child: Icon(_controller?.value.isPlaying == true ? Icons.pause : Icons.play_arrow, color: Colors.white),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioPreviewTile extends StatefulWidget {
  final String path;
  const _AudioPreviewTile({Key? key, required this.path}) : super(key: key);
  @override
  State<_AudioPreviewTile> createState() => _AudioPreviewTileState();
}

class _AudioPreviewTileState extends State<_AudioPreviewTile> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _preloaded = false;
  String? _loadedPath;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((d) { if (mounted) setState(() => _pos = d); });
    _player.onDurationChanged.listen((d) { if (mounted) setState(() => _dur = d); });
    _player.onPlayerComplete.listen((_) { if (mounted) setState(() { _playing = false; _pos = Duration.zero; }); });
    // Précharger la source pour récupérer la durée
    _preloadIfNeeded();
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final hasPath = widget.path.isNotEmpty;
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_fill, color: const Color(0xFF945acb)),
            onPressed: !hasPath ? null : () async {
              if (_playing) {
                await _player.pause();
                setState(() => _playing = false);
    } else {
                try {
                  await _ensureSource();
                  await _player.play(_isUrl(widget.path) ? UrlSource(widget.path) : DeviceFileSource(widget.path));
                  setState(() => _playing = true);
                } catch (_) {}
              }
            },
          ),
          Expanded(
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
                LinearProgressIndicator(
                  value: (_dur.inMilliseconds == 0 || !_playing) ? 0 : (_pos.inMilliseconds / _dur.inMilliseconds).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade300,
                  color: const Color(0xFF945acb),
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Text(hasPath ? (_formatTime(_pos) + ' / ' + _formatTime(_dur)) : 'Audio non lisible', style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _preloadIfNeeded() async {
    if (_preloaded || widget.path.isEmpty) return;
    try {
      if (_isUrl(widget.path)) {
        await _player.setSource(UrlSource(widget.path));
      } else {
        await _player.setSource(DeviceFileSource(widget.path));
      }
      if (_dur == Duration.zero) {
        await _player.setVolume(0);
        await _player.resume();
        await Future.delayed(const Duration(milliseconds: 150));
        await _player.pause();
        await _player.setVolume(1);
      }
      _preloaded = true;
      _loadedPath = widget.path;
    } catch (_) {}
  }

  Future<void> _ensureSource() async {
    if (_loadedPath == widget.path && _preloaded) return;
    _preloaded = false;
    await _preloadIfNeeded();
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _FeedVideo extends StatefulWidget {
  final String path;
  const _FeedVideo({Key? key, required this.path}) : super(key: key);
  @override
  State<_FeedVideo> createState() => _FeedVideoState();
}

class _FeedVideoState extends State<_FeedVideo> {
  VideoPlayerController? _c;
  bool _init = false;

  @override
  void initState() {
    super.initState();
    _c = _isUrl(widget.path)
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) { 
        if (mounted) setState(() { _init = true; }); 
        // DÉSACTIVER L'AUTO-PLAY - vidéos en pause par défaut
      });
  }

  @override
  void dispose() { _c?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _init ? _c!.value.aspectRatio : 16/9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_init) VideoPlayer(_c!) else Container(color: Colors.black12),
            Positioned(
              bottom: 8,
              right: 8,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
                icon: Icon(_c?.value.isPlaying == true ? Icons.pause : Icons.play_arrow, color: Colors.white),
                onPressed: !_init ? null : () {
                  setState(() {
                    if (_c!.value.isPlaying) _c!.pause(); else _c!.play();
                  });
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final _PickedMedia media;
  const _MediaTile({Key? key, required this.media}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final border = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    switch (media.kind) {
      case _PickedKind.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 120,
            height: 80,
            color: Colors.grey.shade200,
            child: Image.file(File(media.xfile!.path), fit: BoxFit.cover),
          ),
        );
      case _PickedKind.video:
        return Material(
          shape: border,
          color: Colors.grey.shade200,
          child: Container(
            width: 120,
            height: 80,
            alignment: Alignment.center,
            child: const Icon(Icons.videocam, color: Colors.black54),
          ),
        );
      case _PickedKind.audio:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 200,
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF945acb).withOpacity(0.08), Colors.white], begin: Alignment.centerLeft, end: Alignment.centerRight),
              border: Border.all(color: const Color(0xFF945acb).withOpacity(0.25)),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.music_note, color: Color(0xFF945acb)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    media.platformFile?.name ?? 'Audio',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      );
    }
  }
}

enum _PickedKind { image, video, audio }

class _PickedMedia {
  final _PickedKind kind;
  final XFile? xfile;
  final PlatformFile? platformFile;

  _PickedMedia._(this.kind, {this.xfile, this.platformFile});
  factory _PickedMedia.image(XFile f) => _PickedMedia._(_PickedKind.image, xfile: f);
  factory _PickedMedia.video(XFile f) => _PickedMedia._(_PickedKind.video, xfile: f);
  factory _PickedMedia.audio(PlatformFile f) => _PickedMedia._(_PickedKind.audio, platformFile: f);
}

class AnonHelpPage extends StatelessWidget {
  const AnonHelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Entraide anonyme', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF945acb),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const _AnonHelpModal(),
    );
  }
}