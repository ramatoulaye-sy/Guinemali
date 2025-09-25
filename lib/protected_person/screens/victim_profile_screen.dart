import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';
// imports de tests/preuves retirés pour épurer l'écran Profil
import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
// import thème non utilisé retiré

// Constantes pour les animations
const Duration _animationDuration = Duration(milliseconds: 300);
const Duration _staggerDelay = Duration(milliseconds: 100);


class VictimProfileScreen extends StatefulWidget {
  const VictimProfileScreen({super.key});

  @override
  State<VictimProfileScreen> createState() => _VictimProfileScreenState();
}

class _VictimProfileScreenState extends State<VictimProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _langue;
  String? _region;
  String? _photoUrl;
  bool _prefHideAvatar = false;
  bool _prefAnonymousDefault = false;
  bool _prefNotifications = true;
  
  bool _isLoading = false;
  bool _isEditing = false;
  Map<String, dynamic>? _userProfile;
  
  // Variables pour la photo de profil
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isImageLoading = false;
  late final AnimationController _haloCtrl;

  static const List<String> _allowedRegions = <String>[
    'Conakry',
    'Kindia',
    'Labé',
    'Kankan',
    'Mamou',
    'Boké',
    'Faranah',
    'Nzérékoré',
  ];

  String? _normalizeRegion(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim();
    // Corrections simples d'accents/orthographes courantes
    if (v.toLowerCase() == 'labe') return 'Labé';
    if (v.toLowerCase() == 'nzerekore') return 'Nzérékoré';
    // Si déjà dans la liste autorisée
    if (_allowedRegions.contains(v)) return v;
    // Tenter une correspondance insensible à la casse
    for (final r in _allowedRegions) {
      if (r.toLowerCase() == v.toLowerCase()) return r;
    }
    // Valeur non reconnue → nul pour éviter le crash dropdown
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadPreferences();
    _haloCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  
  Widget _buildLanguageAndRegion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Préférences de langue et région',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.primaryColor,
          ),
        ),
            const SizedBox(height: 16),
        if (!_isEditing)
          Row(
            children: [
              Expanded(child: _StaticInfoRow(icon: Icons.language, label: 'Langue', value: (_langue ?? 'fr') == 'fr' ? 'Français' : 'English')),
              const SizedBox(width: 12),
              Expanded(child: _StaticInfoRow(icon: Icons.map_outlined, label: 'Région', value: _region ?? '—')),
            ],
          )
        else
          Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _langue ?? 'fr',
                decoration: _dropdownDecoration('Langue'),
                items: const [
                  DropdownMenuItem(value: 'fr', child: Text('Français', style: TextStyle(color: Colors.black87))),
                  DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Colors.black87))),
                ],
                style: const TextStyle(color: Colors.black87),
                dropdownColor: Colors.white,
                iconEnabledColor: Colors.black54,
                iconDisabledColor: Colors.black26,
                onChanged: _isEditing ? (v) => setState(() => _langue = v) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _allowedRegions.contains(_region ?? '') ? _region : null,
                decoration: _dropdownDecoration('Région'),
                items: const [
                  DropdownMenuItem(value: 'Conakry', child: Text('Conakry', style: TextStyle(color: Colors.black87))),
                  DropdownMenuItem(value: 'Kindia', child: Text('Kindia', style: TextStyle(color: Colors.black87))),
                  DropdownMenuItem(value: 'Labé', child: Text('Labé', style: TextStyle(color: Colors.black87))),
                  DropdownMenuItem(value: 'Kankan', child: Text('Kankan', style: TextStyle(color: Colors.black87))),
                  DropdownMenuItem(value: 'Mamou', child: Text('Mamou', style: TextStyle(color: Colors.black87))),
                  DropdownMenuItem(value: 'Boké', child: Text('Boké', style: TextStyle(color: Colors.black87))),
                  DropdownMenuItem(value: 'Faranah', child: Text('Faranah', style: TextStyle(color: Colors.black87))),
                  DropdownMenuItem(value: 'Nzérékoré', child: Text('Nzérékoré', style: TextStyle(color: Colors.black87))),
                ],
                style: const TextStyle(color: Colors.black87),
                dropdownColor: Colors.white,
                iconEnabledColor: Colors.black54,
                iconDisabledColor: Colors.black26,
                onChanged: _isEditing ? (v) => setState(() => _region = v) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.black87),
      hintStyle: const TextStyle(color: Colors.black54),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _haloCtrl.dispose();
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
          columns: 'id, prenom, pseudo, num_tel, langue, region, photo_url, type_utilisateur, date_creation',
          filters: {'id': userId}
        );
        
        if (response.isNotEmpty) {
          _userProfile = response.first;
          _firstNameController.text = _userProfile!['prenom'] ?? '';
          _lastNameController.text = _userProfile!['pseudo'] ?? '';
          _phoneController.text = _userProfile!['num_tel'] ?? '';
          // Email: depuis la table si présente, sinon depuis Supabase Auth
          final tableEmail = _userProfile!['email'] as String?;
          final authEmail = SupabaseService.instance.currentUser?.email;
          _emailController.text = (tableEmail?.isNotEmpty == true)
              ? tableEmail!
              : (authEmail ?? _emailController.text);
          _langue = _userProfile!['langue'] ?? 'fr';
          _region = _normalizeRegion(_userProfile!['region'] as String?);
          _photoUrl = _userProfile!['photo_url'];
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
        final file = File(image.path);
        _profileImage = file;
        await _uploadAndSaveProfileImage(file);
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
      final file = File(image.path);
        _profileImage = file;
        await _uploadAndSaveProfileImage(file);
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
          'pseudo': _lastNameController.text.trim(),
          'num_tel': _phoneController.text.trim(),
          'langue': _langue ?? 'fr',
          'region': _region,
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

  Future<void> _loadPreferences() async {
    try {
      await StorageService.instance.initialize();
      setState(() {
        _prefHideAvatar = StorageService.instance.getBool('pref_hide_avatar_default', defaultValue: false);
        _prefAnonymousDefault = StorageService.instance.getBool('pref_anonymous_default', defaultValue: false);
        _prefNotifications = StorageService.instance.getBool('pref_notifications_enabled', defaultValue: true);
      });
    } catch (_) {}
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      await StorageService.instance.saveBool(key, value);
    } catch (_) {}
  }

  Future<void> _uploadAndSaveProfileImage(File file) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;
      if (userId == null) return;

      setState(() => _isImageLoading = true);

      final fileBytes = await file.readAsBytes();
      final path = 'users/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final publicUrl = await SupabaseService.instance.uploadFile(
        bucket: 'profiles',
        path: path,
        file: fileBytes,
        metadata: {'contentType': 'image/jpeg'},
      );

      await SupabaseService.instance.update(
        'utilisateurs',
        {'photo_url': publicUrl},
        idColumn: 'id',
        idValue: userId,
      );

      if (mounted) {
        setState(() {
          _photoUrl = publicUrl;
          _isImageLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Photo de profil mise à jour')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImageLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur upload photo: $e')),
        );
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
                 color: Colors.white.withOpacity(0.2),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Icon(
                 Icons.person,
                 color: Colors.white,
                 size: 20,
               ),
             ),
             const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Text(
                    'Gérez vos informations',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFee82ee), Color(0xFF945acb)],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     _buildProfileHeader().animate().fadeIn(duration: _animationDuration).slideY(begin: 0.3, end: 0),
                     const SizedBox(height: 24),
                    _buildProfileForm().animate().fadeIn(delay: _staggerDelay, duration: _animationDuration).slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 24),
                    _buildPreferencesSection().animate().fadeIn(delay: _staggerDelay * 2, duration: _animationDuration).slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 24),
                    _buildActionsSection().animate().fadeIn(delay: _staggerDelay * 3, duration: _animationDuration).slideY(begin: 0.3, end: 0),
                    if (_isEditing) ...[
                      const SizedBox(height: 24),
                      _buildActionButtons().animate().fadeIn(delay: _staggerDelay * 4, duration: _animationDuration).slideY(begin: 0.3, end: 0),
                    ],
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
            color: AppConstants.primaryColor.withOpacity(0.4),
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
                // Halo animé
                AnimatedBuilder(
                  animation: _haloCtrl,
                  builder: (context, child) {
                    final t = 0.8 + 0.2 * _haloCtrl.value;
                    return Container(
                      width: 140 * t,
                      height: 140 * t,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.35 * _haloCtrl.value),
                            blurRadius: 28,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    );
                  },
                ),
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
                         color: Colors.black.withOpacity(0.3),
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
                            errorBuilder: (context, error, stackTrace) => _buildDefaultProfileIcon(),
                          )
                        : (_photoUrl != null && _photoUrl!.isNotEmpty)
                            ? Image.network(
                                _photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildDefaultProfileIcon(),
                              )
                            : _buildDefaultProfileIcon(),
                  ),
                 ),
                 // Indicateur de modification
                 Positioned(
                   bottom: 0,
                   right: 0,
                   child: Container(
                     width: 40,
                     height: 40,
                     decoration: BoxDecoration(
                       color: AppConstants.secondaryColor,
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.white, width: 3),
                       boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
                       ],
                     ),
                     child: const Icon(Icons.edit, color: Colors.white, size: 20),
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
              shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0,1))],
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
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
            const SizedBox(height: 16),
          // chip statut simplifié
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Construit l'icône de profil par défaut
  Widget _buildDefaultProfileIcon() {
    return Container(
      color: AppConstants.primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 50,
        color: AppConstants.primaryColor,
      ),
    );
  }

  // éléments "membre depuis" et autres supprimés pour épurer l'entête

  Widget _buildProfileForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _isEditing
            ? Form(
                key: _formKey,
                child: Column(
                  key: const ValueKey('edit'),
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
                Text('Informations Personnelles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
              ],
            ),
            const SizedBox(height: 20),
            // Champs du formulaire
            _buildTextField(
              controller: _firstNameController,
              label: 'Prénom',
              icon: Icons.person_outline,
              enabled: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le prénom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _lastNameController,
              label: 'Pseudo',
              icon: Icons.alternate_email,
              enabled: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le pseudo est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _phoneController,
              label: 'Téléphone',
              icon: Icons.phone_outlined,
              enabled: true,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le téléphone est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              enabled: true,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final regex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!regex.hasMatch(value)) {
                    return 'Format d\'email invalide';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLanguageAndRegion(),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Enregistrer'),
              ),
            ),
          ],
        ))
            : Column(
                key: const ValueKey('static'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppConstants.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.person, color: AppConstants.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Informations Personnelles',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() => _isEditing = !_isEditing),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isEditing
                                ? AppConstants.secondaryColor.withOpacity(0.15)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: _isEditing
                                ? [
                                    BoxShadow(
                                      color: AppConstants.secondaryColor.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _isEditing ? Icons.close : Icons.edit,
                            color: AppConstants.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StaticInfoRow(icon: Icons.person_outline, label: 'Prénom', value: _firstNameController.text.isEmpty ? '—' : _firstNameController.text),
                const SizedBox(height: 16),
                  _StaticInfoRow(icon: Icons.alternate_email, label: 'Pseudo', value: _lastNameController.text.isEmpty ? '—' : _lastNameController.text),
                const SizedBox(height: 12),
                  _StaticInfoRow(icon: Icons.phone_outlined, label: 'Téléphone', value: _phoneController.text.isEmpty ? '—' : _phoneController.text),
                const SizedBox(height: 12),
                  _StaticInfoRow(icon: Icons.email_outlined, label: 'Email', value: _emailController.text.isEmpty ? 'Non renseigné' : _emailController.text, mutedIfEmpty: true),
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
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
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
        fillColor: Colors.white,
        labelStyle: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Colors.black54),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tune,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text('Préférences', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _prefHideAvatar,
            onChanged: (v) {
              setState(() => _prefHideAvatar = v);
              _savePreference('pref_hide_avatar_default', v);
            },
            title: const Text('Masquer mon avatar (par défaut dans le fil)', style: TextStyle(color: Colors.black87)),
            activeColor: AppConstants.primaryColor,
          ),
          SwitchListTile(
            value: _prefAnonymousDefault,
            onChanged: (v) {
              setState(() => _prefAnonymousDefault = v);
              _savePreference('pref_anonymous_default', v);
            },
            title: const Text('Publier en anonyme par défaut', style: TextStyle(color: Colors.black87)),
            activeColor: AppConstants.primaryColor,
          ),
          SwitchListTile(
            value: _prefNotifications,
            onChanged: (v) {
              setState(() => _prefNotifications = v);
              _savePreference('pref_notifications_enabled', v);
            },
            title: const Text('Notifications activées', style: TextStyle(color: Colors.black87)),
            activeColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock, color: AppConstants.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: [
              _ActionTile(icon: Icons.security, label: 'Sécurité', color: AppConstants.primaryColor, onTap: () => context.push(AppConstants.routeVictimSecurity)),
              _ActionTile(icon: Icons.description, label: 'CGU', color: AppConstants.secondaryColor, onTap: () {
                showDialog(context: context, builder: (c) => const AlertDialog(title: Text('CGU & Confidentialité'), content: Text('Les conditions d\'utilisation et la politique de confidentialité seront affichées ici.')));
              }),
              _ActionTile(icon: Icons.logout, label: 'Déconnexion', color: Colors.redAccent, onTap: () async { await SupabaseService.instance.signOut(); }),
              _ActionTile(icon: Icons.info_outline, label: 'À propos', color: Colors.blue, onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guinèmali v1.0'))); }),
            ],
          ),
        ],
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
                  color: AppConstants.primaryColor.withOpacity(0.1),
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
                    shadowColor: AppConstants.primaryColor.withOpacity(0.3),
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

  // _buildProfileStats supprimé

  // _buildStatCard supprimé

  // _buildQuickSettings supprimé

  /// Construit une carte de paramètre rapide
  // _buildQuickSettingCard supprimé

  /// Navigation vers les paramètres
  // _navigateToSettings supprimé

  /// Navigation vers les contacts
  // _navigateToContacts supprimé

  /// Navigation vers l'urgence
  // _navigateToEmergency supprimé

  /// Navigation vers l'aide
  // _navigateToHelp supprimé

  // _buildBadgesSection supprimé

  /// Construit un badge individuel
  // _buildBadge supprimé

  // _buildSecuritySection supprimé

  // _buildSecurityOption supprimé

  /// Partage le profil de l'utilisateur
  // partage désactivé pour l'instant

  /// Construit une option de partage
  // composants de partage retirés

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

  // Tuile d'action (grille)
  Widget _ActionTile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  

  // Suppression des tests d'enregistrement/diagnostic pour épurer l'écran
}

class _StaticInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mutedIfEmpty;
  const _StaticInfoRow({required this.icon, required this.label, required this.value, this.mutedIfEmpty = false});

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.trim().isEmpty || value == '—' || value == 'Non renseigné';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: mutedIfEmpty && isEmpty ? Colors.grey.shade500 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
