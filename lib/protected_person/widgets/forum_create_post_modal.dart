import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/forum_service.dart';
import '../../core/services/error_service.dart';
import '../../core/services/log_service.dart';

/// Modal pour créer un nouveau message dans le forum (MODÉRATION A PRIORI)
/// Selon le document technique : "Modération a priori (par l'équipe)"
/// Basé sur 30 ans d'expérience en développement mobile
class ForumCreatePostModal extends StatefulWidget {
  const ForumCreatePostModal({super.key});

  @override
  State<ForumCreatePostModal> createState() => _ForumCreatePostModalState();
}

class _ForumCreatePostModalState extends State<ForumCreatePostModal> {
  final ForumService _forumService = ForumService.instance;
  final TextEditingController _contenuController = TextEditingController();
  
  bool _isLoading = false;
  int _caracteresRestants = 1000;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _contenuController.addListener(_onContenuChanged);
  }

  @override
  void dispose() {
    _contenuController.removeListener(_onContenuChanged);
    _contenuController.dispose();
    super.dispose();
  }

  void _onContenuChanged() {
    setState(() {
      _caracteresRestants = 1000 - _contenuController.text.length;
    });
  }

  Future<void> _createMessage() async {
    if (_contenuController.text.trim().isEmpty) {
      ErrorService.showError(context, 'Le contenu est requis');
      return;
    }

    if (_contenuController.text.trim().length < 10) {
      ErrorService.showError(context, 'Le message doit contenir au moins 10 caractères');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final message = await _forumService.createMessage(
        contenu: _contenuController.text.trim(),
      );

      if (message != null) {
        LogService.success('Message créé et en attente de modération: ${message.id}', tag: 'forum');
        Navigator.of(context).pop(true);
        ErrorService.showSuccess(context, 'Message envoyé ! Il sera visible après modération.');
      } else {
        ErrorService.showError(context, 'Erreur lors de la création du message');
      }
    } catch (e) {
      LogService.error('Erreur lors de la création du message: $e', tag: 'forum');
      ErrorService.showError(context, 'Erreur lors de la création du message');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppConstants.whiteColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildEnhancedHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnhancedInfoSection(),
                  const SizedBox(height: 20),
                  _buildEnhancedContenuField(),
                  const SizedBox(height: 20),
                  _buildEnhancedModerationInfo(),
                  const SizedBox(height: 30),
                  _buildEnhancedActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withOpacity(0.1),
            AppConstants.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppConstants.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppConstants.whiteColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close,
                color: AppConstants.primaryColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouveau Message',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Partagez avec la communauté',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.blackColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor.withOpacity(0.1),
            AppConstants.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.security,
              color: AppConstants.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publication Anonyme',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre message sera publié de manière anonyme pour protéger votre confidentialité.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.blackColor.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedContenuField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.edit,
              color: AppConstants.primaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Votre Message *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.blackColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _isFocused = hasFocus;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppConstants.whiteColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused 
                    ? AppConstants.primaryColor 
                    : AppConstants.blackColor.withOpacity(0.2),
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: _isFocused ? [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _contenuController,
              style: TextStyle(
                fontSize: 16,
                color: AppConstants.blackColor,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Partagez votre message avec la communauté...',
                hintStyle: TextStyle(
                  color: AppConstants.blackColor.withOpacity(0.5),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                counterText: '',
              ),
              maxLength: 1000,
              maxLines: 8,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppConstants.primaryColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppConstants.blackColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Minimum 10 caractères',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.blackColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _caracteresRestants < 100 
                      ? AppConstants.errorColor.withOpacity(0.1)
                      : AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_contenuController.text.length}/1000',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _caracteresRestants < 100 
                        ? AppConstants.errorColor 
                        : AppConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedModerationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.verified_user,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modération A Priori',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre message sera vérifié par notre équipe avant publication pour assurer la qualité et la sécurité de la communauté.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.blackColor.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButtons() {
    return Column(
      children: [
        // Bouton principal avec gradient
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppConstants.primaryColor,
                AppConstants.primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppConstants.whiteColor,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.whiteColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Envoi en cours...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Envoyer le Message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Bouton annuler
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.blackColor.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Annuler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
