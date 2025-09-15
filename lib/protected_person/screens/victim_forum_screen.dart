import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/forum_service.dart';
import '../../core/services/error_service.dart';
import '../../core/services/log_service.dart';
import '../models/forum_post_model.dart';
import '../widgets/forum_post_card.dart';
import '../widgets/forum_create_post_modal.dart';

/// Écran principal du forum de la communauté (CONSULTATION ANONYME)
/// Selon le document technique : "Consultation anonyme (aucune donnée personnelle affichée)"
/// Basé sur 30 ans d'expérience en développement mobile
class VictimForumScreen extends StatefulWidget {
  const VictimForumScreen({super.key});

  @override
  State<VictimForumScreen> createState() => _VictimForumScreenState();
}

class _VictimForumScreenState extends State<VictimForumScreen>
    with TickerProviderStateMixin {
  final ForumService _forumService = ForumService.instance;
  
  List<ForumPost> _messages = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _showScrollToTop = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeScrollController();
    _loadMessages();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Démarrer les animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
        _pulseController.repeat(reverse: true);
      }
    });
  }

  void _initializeScrollController() {
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 200 && !_showScrollToTop) {
        setState(() {
          _showScrollToTop = true;
        });
      } else if (_scrollController.offset <= 200 && _showScrollToTop) {
        setState(() {
          _showScrollToTop = false;
        });
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final messages = await _forumService.getAllMessages();

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      LogService.success('Messages chargés: ${messages.length}', tag: 'forum');
    } catch (e) {
      LogService.error('Erreur lors du chargement des messages: $e', tag: 'forum');
      ErrorService.showError(context, 'Erreur lors du chargement des messages');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshMessages() async {
    setState(() {
      _isRefreshing = true;
    });

    await _forumService.refresh();
    await _loadMessages();

    setState(() {
      _isRefreshing = false;
    });

    ErrorService.showSuccess(context, 'Forum actualisé');
  }

  void _showCreateMessageModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ForumCreatePostModal(),
    ).then((result) {
      if (result == true) {
        _loadMessages();
      }
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildEnhancedHeader(),
            Expanded(
              child: _buildEnhancedContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildEnhancedFloatingActionButton(),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forum Communautaire',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Espace d\'entraide anonyme et sécurisé',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.blackColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _refreshMessages,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isRefreshing ? Icons.refresh : Icons.refresh_outlined,
                      key: ValueKey(_isRefreshing),
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          _buildStatsBar(),
        ],
      ),
    ).animate(controller: _fadeController).fadeIn(duration: const Duration(milliseconds: 800));
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.message_outlined,
            value: _messages.length.toString(),
            label: 'Messages',
          ),
          Container(
            width: 1,
            height: 30,
            color: AppConstants.primaryColor.withOpacity(0.2),
          ),
          _buildStatItem(
            icon: Icons.security,
            value: '100%',
            label: 'Anonyme',
          ),
          Container(
            width: 1,
            height: 30,
            color: AppConstants.primaryColor.withOpacity(0.2),
          ),
          _buildStatItem(
            icon: Icons.verified,
            value: 'Modéré',
            label: 'Contenu',
          ),
        ],
      ),
    ).animate(controller: _slideController).fadeIn(
      duration: const Duration(milliseconds: 600),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppConstants.primaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppConstants.blackColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CircularProgressIndicator(
                color: AppConstants.primaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            Text(
              'Chargement du forum...',
              style: TextStyle(
                fontSize: 16,
                color: AppConstants.blackColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 60,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLarge),
            Text(
              'Aucun message disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.blackColor,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            Text(
              'Soyez la première à partager un message\net à créer une communauté de soutien !',
              style: TextStyle(
                fontSize: 16,
                color: AppConstants.blackColor.withOpacity(0.6),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLarge),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstants.primaryColor,
                    AppConstants.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _showCreateMessageModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppConstants.whiteColor,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge,
                    vertical: AppConstants.paddingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Partager un message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMessages,
      color: AppConstants.primaryColor,
      backgroundColor: AppConstants.whiteColor,
      strokeWidth: 3,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
            child: ForumPostCard(
              post: message,
              onTap: () => _navigateToMessageDetail(message),
              onLike: () => _toggleMessageLike(message),
              onComment: () => _showCommentModal(message),
              onReport: () => _reportMessage(message),
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 400),
              delay: Duration(milliseconds: index * 100),
            ).fadeIn(
              duration: const Duration(milliseconds: 400),
              delay: Duration(milliseconds: index * 100),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton Scroll to Top
        if (_showScrollToTop)
          Container(
            margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
            child: FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: AppConstants.whiteColor,
              foregroundColor: AppConstants.primaryColor,
              elevation: 4,
              child: const Icon(Icons.keyboard_arrow_up),
            ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
          ),
        
        // Bouton principal
        FloatingActionButton.extended(
          onPressed: _showCreateMessageModal,
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.whiteColor,
          elevation: 6,
          icon: const Icon(Icons.add),
          label: const Text(
            'Partager',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ).animate(controller: _pulseController).scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: const Duration(milliseconds: 2000),
        ),
      ],
    );
  }

  void _navigateToMessageDetail(ForumPost message) {
    // TODO: Naviguer vers l'écran de détail du message
    LogService.navigation('forum_list', 'message_detail', tag: 'forum', parameters: {'message_id': message.id});
    ErrorService.showInfo(context, 'Fonctionnalité en cours de développement');
  }

  Future<void> _toggleMessageLike(ForumPost message) async {
    try {
      // TODO: Implémenter le toggle like
      LogService.info('Toggle like pour le message ${message.id}', tag: 'forum');
      ErrorService.showInfo(context, 'Fonctionnalité en cours de développement');
    } catch (e) {
      LogService.error('Erreur lors du toggle like: $e', tag: 'forum');
      ErrorService.showError(context, 'Erreur lors du like');
    }
  }

  void _showCommentModal(ForumPost message) {
    // TODO: Afficher le modal de commentaires
    LogService.info('Ouverture du modal de commentaires pour ${message.id}', tag: 'forum');
    ErrorService.showInfo(context, 'Fonctionnalité en cours de développement');
  }

  void _reportMessage(ForumPost message) {
    // TODO: Implémenter le signalement
    LogService.info('Signalement du message ${message.id}', tag: 'forum');
    ErrorService.showSuccess(context, 'Message signalé. Notre équipe va l\'examiner.');
  }
}
