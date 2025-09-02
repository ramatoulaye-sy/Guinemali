import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/providers/auth_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/evidence_service.dart';
import '../../core/services/evidence_test_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

// Constantes pour les animations
const Duration _animationDuration = Duration(milliseconds: 300);
const Duration _staggerDelay = Duration(milliseconds: 100);


class VictimProfileScreen extends StatefulWidget {
  const VictimProfileScreen({super.key});

  @override
  State<VictimProfileScreen> createState() => _VictimProfileScreenState();
}

class _VictimProfileScreenState extends State<VictimProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;
  Map<String, dynamic>? _userProfile;
  
  // Variables pour la photo de profil
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;
      
      if (userId != null) {
        final response = await SupabaseService.instance.select(
          'utilisateurs',
          columns: 'id, prenom, nom, telephone, email, type_compte, date_creation',
          filters: {'id': userId}
        );
        
        if (response.isNotEmpty) {
          _userProfile = response.first;
          _firstNameController.text = _userProfile!['prenom'] ?? '';
          _lastNameController.text = _userProfile!['nom'] ?? '';
          _phoneController.text = _userProfile!['telephone'] ?? '';
          _emailController.text = _userProfile!['email'] ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Affiche le dialogue de sélection de photo de profil
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.photo_camera, color: AppConstants.primaryColor),
            const SizedBox(width: 12),
            Text(
              'Photo de Profil',
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choisissez comment ajouter votre photo de profil',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromGallery();
                  },
                ),
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'Caméra',
                  onTap: () {
                    Navigator.of(context).pop();
                    _takePhotoWithCamera();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  /// Construit une option de sélection d'image
  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sélectionne une image depuis la galerie
  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        _isImageLoading = true;
      });
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
          _isImageLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Photo de profil mise à jour depuis la galerie'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isImageLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isImageLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de la sélection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Prend une photo avec la caméra
  Future<void> _takePhotoWithCamera() async {
    try {
      setState(() {
        _isImageLoading = true;
      });
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
          _isImageLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Photo de profil prise avec la caméra'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isImageLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isImageLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de la prise de photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;
      
      if (userId != null) {
        final updateData = {
          'prenom': _firstNameController.text.trim(),
          'nom': _lastNameController.text.trim(),
          'telephone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
        };
        
        await SupabaseService.instance.update(
          'utilisateurs',
          updateData,
          idColumn: 'id',
          idValue: userId
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil mis à jour avec succès')),
          );
          setState(() => _isEditing = false);
          await _loadUserProfile();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
             appBar: AppBar(
         title: Row(
           children: [
             Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                 color: Colors.white.withValues(alpha: 0.2),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Icon(
                 Icons.person,
                 color: Colors.white,
                 size: 20,
               ),
             ),
             const SizedBox(width: 12),
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   'Mon Profil',
                   style: TextStyle(
                     color: Colors.white,
                     fontWeight: FontWeight.bold,
                     fontSize: 18,
                   ),
                 ),
                                   Flexible(
                    child: Text(
                      'Gérez vos informations',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
               ],
             ),
           ],
         ),
         backgroundColor: AppConstants.primaryColor,
         foregroundColor: Colors.white,
         elevation: 0,
         shape: const RoundedRectangleBorder(
           borderRadius: BorderRadius.vertical(
             bottom: Radius.circular(20),
           ),
         ),



                   actions: [
            if (!_isEditing) ...[
              _buildActionButton(
                icon: Icons.share_rounded,
                onPressed: _shareProfile,
                tooltip: 'Partager le profil',
              ),
              const SizedBox(width: 4),
              _buildActionButton(
                icon: Icons.edit_rounded,
                onPressed: () => setState(() => _isEditing = true),
                tooltip: 'Modifier le profil',
              ),
              const SizedBox(width: 8),
            ],
          ],
       ),
      body: _isLoading
          ? Container(
              color: AppConstants.backgroundColor,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppConstants.primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chargement du profil...',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              color: AppConstants.backgroundColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     _buildProfileHeader().animate().fadeIn(duration: _animationDuration).slideY(begin: 0.3, end: 0),
                     const SizedBox(height: 24),
                     _buildProfileForm().animate().fadeIn(delay: _staggerDelay, duration: _animationDuration).slideY(begin: 0.3, end: 0),
                     if (_isEditing) ...[
                       const SizedBox(height: 24),
                       _buildActionButtons().animate().fadeIn(delay: _staggerDelay * 2, duration: _animationDuration).slideY(begin: 0.3, end: 0),
                     ],
                     const SizedBox(height: 24),
                     _buildProfileStats().animate().fadeIn(delay: _staggerDelay * 3, duration: _animationDuration).slideY(begin: 0.3, end: 0),
                     const SizedBox(height: 24),
                     _buildQuickSettings().animate().fadeIn(delay: _staggerDelay * 4, duration: _animationDuration).slideY(begin: 0.3, end: 0),
                     const SizedBox(height: 24),
                     _buildBadgesSection().animate().fadeIn(delay: _staggerDelay * 5, duration: _animationDuration).slideY(begin: 0.3, end: 0),
                     const SizedBox(height: 24),
                     _buildSecuritySection().animate().fadeIn(delay: _staggerDelay * 6, duration: _animationDuration).slideY(begin: 0.3, end: 0),
                     const SizedBox(height: 32),
                   ],
                 ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.secondaryColor,
            AppConstants.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
                                // Photo de profil cliquable
           GestureDetector(
             onTap: _showImagePickerDialog,
             child: Stack(
               children: [
                 AnimatedContainer(
                   duration: _animationDuration,
                   width: 120,
                   height: 120,
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     border: Border.all(
                       color: Colors.white,
                       width: 5,
                     ),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withValues(alpha: 0.3),
                         blurRadius: 15,
                         offset: const Offset(0, 6),
                         spreadRadius: 1,
                       ),
                     ],
                   ),
                   child: ClipOval(
                     child: _profileImage != null
                         ? Image.file(
                             _profileImage!,
                             fit: BoxFit.cover,
                             errorBuilder: (context, error, stackTrace) {
                               return _buildDefaultProfileIcon();
                             },
                           )
                         : _buildDefaultProfileIcon(),
                   ),
                 ),
                 // Indicateur de modification
                 Positioned(
                   bottom: 0,
                   right: 0,
                   child: Container(
                     width: 36,
                     height: 36,
                     decoration: BoxDecoration(
                       color: AppConstants.accentColor,
                       shape: BoxShape.circle,
                       border: Border.all(
                         color: Colors.white,
                         width: 3,
                       ),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withValues(alpha: 0.2),
                           blurRadius: 8,
                           offset: const Offset(0, 2),
                         ),
                       ],
                     ),
                     child: const Icon(
                       Icons.camera_alt_rounded,
                       color: Colors.white,
                       size: 20,
                     ),
                   ),
                 ),
                 // Indicateur de chargement
                 if (_isImageLoading)
                   Positioned.fill(
                     child: Container(
                       decoration: BoxDecoration(
                         color: Colors.black.withValues(alpha: 0.6),
                         shape: BoxShape.circle,
                       ),
                       child: const Center(
                         child: CircularProgressIndicator(
                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                           strokeWidth: 3,
                         ),
                       ),
                     ),
                   ),
               ],
             ),
           ),
          const SizedBox(height: 20),
          // Nom de l'utilisateur
          Text(
            _userProfile?['prenom'] ?? 'Utilisateur',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          // Statut en ligne et informations
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Indicateur de statut en ligne
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'En ligne',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Type d'utilisateur
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Personne à Protéger',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Informations supplémentaires
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem(
                icon: Icons.calendar_today,
                label: 'Membre depuis',
                value: _getMemberSinceText(),
              ),
              _buildInfoItem(
                icon: Icons.location_on,
                label: 'Localisation',
                value: 'Conakry, Guinée',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit l'icône de profil par défaut
  Widget _buildDefaultProfileIcon() {
    return Container(
      color: AppConstants.primaryColor.withValues(alpha: 0.1),
      child: Icon(
        Icons.person,
        size: 50,
        color: AppConstants.primaryColor,
      ),
    );
  }

  /// Construit un élément d'information
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Retourne le texte "Membre depuis"
  String _getMemberSinceText() {
    if (_userProfile?['date_creation'] != null) {
      try {
        final date = DateTime.parse(_userProfile!['date_creation']);
        final now = DateTime.now();
        final difference = now.difference(date);
        
        if (difference.inDays < 30) {
          return '${difference.inDays} jours';
        } else if (difference.inDays < 365) {
          final months = (difference.inDays / 30).floor();
          return '$months mois';
        } else {
          final years = (difference.inDays / 365).floor();
          return '$years an${years > 1 ? 's' : ''}';
        }
      } catch (e) {
        return 'Récemment';
      }
    }
    return 'Récemment';
  }

  Widget _buildProfileForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de la section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Informations Personnelles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Champs du formulaire
            _buildTextField(
              controller: _firstNameController,
              label: 'Prénom',
              icon: Icons.person_outline,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le prénom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _lastNameController,
              label: 'Nom',
              icon: Icons.person_outline,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Téléphone',
              icon: Icons.phone_outlined,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le téléphone est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'email est requis';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Format d\'email invalide';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: enabled ? Colors.black87 : Colors.grey.shade600,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? AppConstants.primaryColor : Colors.grey.shade400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.errorColor,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.errorColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
        labelStyle: TextStyle(
          color: enabled ? AppConstants.primaryColor : Colors.grey.shade400,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre de la section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.save,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: AppConstants.primaryColor.withValues(alpha: 0.3),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Sauvegarder',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _isEditing = false);
                    _loadUserProfile(); // Restaurer les valeurs originales
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: AppConstants.secondaryColor,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel,
                        size: 20,
                        color: AppConstants.secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
                     const SizedBox(height: 24),
           // Cartes de statistiques
           Row(
             children: [
               Expanded(
                 child: _buildStatCard(
                   icon: Icons.warning_amber_rounded,
                   title: 'Alertes',
                   value: '0',
                   color: AppConstants.warningColor,
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: _buildStatCard(
                   icon: Icons.location_on,
                   title: 'Positions',
                   value: '0',
                   color: AppConstants.primaryColor,
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: _buildStatCard(
                   icon: Icons.mic,
                   title: 'Enregistrements',
                   value: '0',
                   color: AppConstants.secondaryColor,
                 ),
               ),
             ],
           ),
           const SizedBox(height: 16),
           // Boutons de test d'enregistrement
           Column(
             children: [
               Center(
                 child: ElevatedButton.icon(
                   onPressed: _testEvidenceRecording,
                   icon: const Icon(Icons.mic, color: Colors.white),
                   label: const Text(
                     'Test Enregistrement Audio',
                     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                   ),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppConstants.primaryColor,
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(12),
                     ),
                   ),
                 ),
               ),
               const SizedBox(height: 8),
               Center(
                 child: ElevatedButton.icon(
                   onPressed: 
                   _runAdvancedTest,
                   icon: const Icon(Icons.bug_report, color: Colors.white),
                   label: const Text(
                     'Test Avancé (Diagnostic)',
                     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                   ),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppConstants.secondaryColor,
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(12),
                     ),
                   ),
                 ),
               ),
             ],
           ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la section des paramètres rapides
  Widget _buildQuickSettings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.settings,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Paramètres Rapides',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
                     // Grille de paramètres
           GridView.count(
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             crossAxisCount: 2,
             crossAxisSpacing: 12,
             mainAxisSpacing: 12,
             childAspectRatio: 1.8,
            children: [
              _buildQuickSettingCard(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Gérer les alertes',
                color: AppConstants.primaryColor,
                onTap: () => _navigateToSettings(),
              ),
              _buildQuickSettingCard(
                icon: Icons.contacts,
                title: 'Contacts',
                subtitle: 'Gérer les contacts',
                color: AppConstants.secondaryColor,
                onTap: () => _navigateToContacts(),
              ),
              _buildQuickSettingCard(
                icon: Icons.emergency,
                title: 'SOS',
                subtitle: 'Configurer l\'urgence',
                color: AppConstants.warningColor,
                onTap: () => _navigateToEmergency(),
              ),
              _buildQuickSettingCard(
                icon: Icons.help,
                title: 'Aide',
                subtitle: 'Support & FAQ',
                color: Colors.blue,
                onTap: () => _navigateToHelp(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit une carte de paramètre rapide
  Widget _buildQuickSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color.withValues(alpha: 0.5),
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigation vers les paramètres
  void _navigateToSettings() {
    Navigator.of(context).pushNamed(AppConstants.routeVictimSettings);
  }

  /// Navigation vers les contacts
  void _navigateToContacts() {
    Navigator.of(context).pushNamed(AppConstants.routeVictimContacts);
  }

  /// Navigation vers l'urgence
  void _navigateToEmergency() {
    Navigator.of(context).pushNamed(AppConstants.routeVictimEmergencyPlan);
  }

  /// Navigation vers l'aide
  void _navigateToHelp() {
    Navigator.of(context).pushNamed(AppConstants.routeVictimHelp);
  }

  /// Construit la section des badges et accomplissements
  Widget _buildBadgesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
                             Flexible(
                 child: Text(
                   'Badges & Accomplissements',
                   style: TextStyle(
                     fontSize: 18,
                     fontWeight: FontWeight.bold,
                     color: AppConstants.primaryColor,
                   ),
                   overflow: TextOverflow.ellipsis,
                   maxLines: 1,
                 ),
               ),
            ],
          ),
          const SizedBox(height: 24),
                     // Grille de badges
           GridView.count(
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             crossAxisCount: 3,
             crossAxisSpacing: 12,
             mainAxisSpacing: 12,
            children: [
              _buildBadge(
                icon: Icons.security,
                title: 'Sécurisé',
                description: 'Profil complet',
                color: AppConstants.primaryColor,
                isUnlocked: true,
              ),
              _buildBadge(
                icon: Icons.verified_user,
                title: 'Vérifié',
                description: 'Compte vérifié',
                color: AppConstants.secondaryColor,
                isUnlocked: true,
              ),
              _buildBadge(
                icon: Icons.emergency,
                title: 'Prêt',
                description: 'SOS configuré',
                color: AppConstants.warningColor,
                isUnlocked: true,
              ),
              _buildBadge(
                icon: Icons.location_on,
                title: 'Localisé',
                description: 'GPS activé',
                color: Colors.blue,
                isUnlocked: false,
              ),
              _buildBadge(
                icon: Icons.mic,
                title: 'Enregistreur',
                description: 'Audio activé',
                color: Colors.green,
                isUnlocked: false,
              ),
              _buildBadge(
                icon: Icons.wifi,
                title: 'Connecté',
                description: 'En ligne',
                color: Colors.orange,
                isUnlocked: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit un badge individuel
  Widget _buildBadge({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isUnlocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? color.withValues(alpha: 0.3) : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isUnlocked ? color : Colors.grey.shade400,
            size: 28,
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? color : Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 9,
                color: isUnlocked ? color.withValues(alpha: 0.7) : Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la section de sécurité
  Widget _buildSecuritySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sécurité & Confidentialité',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Options de sécurité
          _buildSecurityOption(
            icon: Icons.fingerprint,
            title: 'Authentification biométrique',
            subtitle: 'Utiliser l\'empreinte digitale',
            isEnabled: true,
            onTap: () => _showSecurityDialog('Biométrie'),
          ),
          const SizedBox(height: 16),
          _buildSecurityOption(
            icon: Icons.notifications_off,
            title: 'Notifications discrètes',
            subtitle: 'Mode silencieux activé',
            isEnabled: true,
            onTap: () => _showSecurityDialog('Notifications'),
          ),
          const SizedBox(height: 16),
                     _buildSecurityOption(
             icon: Icons.visibility_off,
             title: 'Mode discret',
             subtitle: 'Interface masquée',
             isEnabled: false,
             onTap: () => _showSecurityDialog('Mode discret'),
           ),
           const SizedBox(height: 16),
           _buildSecurityOption(
             icon: Icons.mic,
             title: 'Test Enregistrement',
             subtitle: 'Tester l\'enregistrement des preuves',
             isEnabled: true,
             onTap: () => _showSecurityDialog('Test Enregistrement'),
           ),
        ],
      ),
    );
  }

  /// Construit une option de sécurité
  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled ? AppConstants.primaryColor.withValues(alpha: 0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? AppConstants.primaryColor.withValues(alpha: 0.2) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled ? AppConstants.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isEnabled ? AppConstants.primaryColor : Colors.grey.shade400,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isEnabled ? AppConstants.primaryColor : Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Partage le profil de l'utilisateur
  void _shareProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.share, color: AppConstants.primaryColor),
            const SizedBox(width: 12),
            Text(
              'Partager le Profil',
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Partager votre profil avec vos contacts de confiance ?',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  icon: Icons.message,
                  label: 'SMS',
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareViaSMS();
                  },
                ),
                _buildShareOption(
                  icon: Icons.email,
                  label: 'Email',
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareViaEmail();
                  },
                ),
                _buildShareOption(
                  icon: Icons.copy,
                  label: 'Copier',
                  onTap: () {
                    Navigator.of(context).pop();
                    _copyProfileLink();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  /// Construit une option de partage
  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Partage via SMS
  void _shareViaSMS() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Lien du profil copié pour SMS'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Partage via Email
  void _shareViaEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Lien du profil copié pour Email'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Copie le lien du profil
  void _copyProfileLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Lien du profil copié dans le presse-papiers'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Construit un bouton d'action pour l'AppBar
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(6),
          minimumSize: const Size(36, 36),
        ),
      ),
    );
  }

  /// Affiche un dialogue de sécurité
  void _showSecurityDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.security, color: AppConstants.primaryColor),
            const SizedBox(width: 12),
            Text(
              feature,
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cette fonctionnalité de sécurité sera bientôt disponible.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            if (feature == 'Test Enregistrement') ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _testEvidenceRecording();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tester l\'enregistrement'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  /// Test de l'enregistrement des preuves
  Future<void> _testEvidenceRecording() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎙️ Test d\'enregistrement en cours...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Créer un ID d'alerte de test
      const testAlertId = 'test-alert-123';
      
      // Initialiser le service d'enregistrement
      await EvidenceService.instance.initialize();
      
      // Test simple d'enregistrement audio seulement
      await EvidenceService.instance.startAudioRecording(testAlertId);
      
      // Attendre 3 secondes
      await Future.delayed(const Duration(seconds: 3));
      
      // Arrêter l'enregistrement
      await EvidenceService.instance.stopAudioRecording();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test d\'enregistrement audio terminé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors du test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Erreur détaillée: $e');
    }
  }

  /// Test avancé avec diagnostic complet
  Future<void> _runAdvancedTest() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔍 Diagnostic en cours...'),
          backgroundColor: Colors.orange,
        ),
      );

      // Exécuter le test complet
      final results = await EvidenceTestService.instance.runFullTest();
      
      // Générer le rapport
      final report = EvidenceTestService.instance.getTestReport(results);
      
      // Afficher le rapport dans un dialogue
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🔍 Rapport de Diagnostic'),
            content: SingleChildScrollView(
              child: Text(
                report,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  EvidenceTestService.instance.cleanupTestFiles();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🧹 Fichiers de test nettoyés')),
                  );
                },
                child: const Text('Nettoyer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur diagnostic: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Erreur diagnostic détaillée: $e');
    }
  }
}
