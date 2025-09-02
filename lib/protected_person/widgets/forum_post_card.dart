import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../models/forum_post_model.dart';

/// Widget pour afficher une carte de message du forum (CONSULTATION ANONYME)
/// Selon le document technique : "Consultation anonyme (aucune donnée personnelle affichée)"
/// Basé sur 30 ans d'expérience en développement mobile
class ForumPostCard extends StatefulWidget {
  final ForumPost post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onReport;

  const ForumPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onReport,
  });

  @override
  State<ForumPostCard> createState() => _ForumPostCardState();
}

class _ForumPostCardState extends State<ForumPostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_animationController.value * 0.02),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
              decoration: BoxDecoration(
                color: AppConstants.whiteColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnhancedContent(),
                  _buildEnhancedFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedContent() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.whiteColor,
            AppConstants.backgroundColor.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge de modération en haut
          Row(
            children: [
              if (widget.post.isApproved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.1),
                        Colors.green.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Modéré',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              // Date de publication avec icône
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.post.formattedDatePost,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          
          // Contenu du message avec style amélioré
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppConstants.whiteColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              widget.post.contenu,
              style: TextStyle(
                fontSize: 15,
                color: AppConstants.blackColor.withOpacity(0.8),
                height: 1.5,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFooter() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: AppConstants.primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Bouton Like avec animation
          _buildEnhancedActionButton(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            label: '0',
            onTap: widget.onLike,
            isActive: false,
          ),
          const SizedBox(width: AppConstants.spacingLarge),
          
          // Bouton Commentaires
          _buildEnhancedActionButton(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: '0',
            onTap: widget.onComment,
          ),
          const SizedBox(width: AppConstants.spacingLarge),
          
          // Bouton Signaler
          _buildEnhancedActionButton(
            icon: Icons.flag_outlined,
            activeIcon: Icons.flag,
            label: 'Signaler',
            onTap: widget.onReport,
            isReport: true,
          ),
          
          const Spacer(),
          
          // Indicateur anonyme amélioré
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingSmall,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor.withOpacity(0.1),
                  AppConstants.primaryColor.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.security,
                  size: 14,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Anonyme',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButton({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
    bool isReport = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingSmall,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive 
              ? AppConstants.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive 
                ? AppConstants.primaryColor.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 16,
              color: isActive 
                  ? AppConstants.primaryColor
                  : isReport
                      ? Colors.orange
                      : AppConstants.blackColor.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive 
                    ? AppConstants.primaryColor
                    : isReport
                        ? Colors.orange
                        : AppConstants.blackColor.withOpacity(0.6),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
