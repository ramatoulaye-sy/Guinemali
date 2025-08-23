import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/geolocation_service.dart';
import '../../core/widgets/accessibility_widgets.dart';
import '../../core/models/user_model.dart';
import '../widgets/quick_actions_modal.dart';
import '../widgets/menu_modal.dart';

/// Écran d'accueil principal avec dashboard complet
class VictimDashboardScreen extends StatefulWidget {
  const VictimDashboardScreen({super.key});

  @override
  State<VictimDashboardScreen> createState() => _VictimDashboardScreenState();
}

class _VictimDashboardScreenState extends State<VictimDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;


  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissions();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Plus rapide pour un effet plus visible
      vsync: this,
    )..repeat(reverse: true); // Alterner entre grand et petit pour un effet pulsant

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  Future<void> _checkPermissions() async {
    // Vérifier les permissions GPS et audio
    await GeolocationService.instance.checkPermissions();
    // TODO: Implémenter checkPermissions pour AudioRecordingService
    // await AudioRecordingService.instance.checkPermissions();
    
    // Démarrer l'animation du bouton Actions Rapides
    Future.delayed(const Duration(milliseconds: 500), () {
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec logo, nom utilisateur et icônes de statut
            _buildHeader(user),
            
            // Contenu principal centré
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bouton SOS principal
                  _buildSOSButton(),
                  
                  const SizedBox(height: 32),
                  
                  // Bouton Actions Rapides
                  _buildQuickActionsButton(),
                ],
              ),
            ),
            
            // Footer avec navigation
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// Construit le header avec logo, nom utilisateur et icônes de statut
  Widget _buildHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF945ACB), // Couleur primaire
            Color(0xFFEE82EE), // Couleur secondaire
            Colors.white,       // Blanc
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Première ligne : Logo Guinemali - Nom utilisateur - Icône profil
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo Guinémali à gauche (avec votre vraie image)
              Column(
                children: [
                  // Logo Guinémali (votre image)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                                 // Nom Guinémali centré sous le logo
               const Text(
                 'Guinémali',
                 style: TextStyle(
                   fontSize: 14,
                   fontWeight: FontWeight.bold,
                   color: Colors.white,
                   shadows: [
                     Shadow(
                       offset: Offset(1, 1),
                       blurRadius: 2,
                       color: Colors.black26,
                     ),
                   ],
                 ),
                 textAlign: TextAlign.center,
               ),
                ],
              ),
              
                             // Nom de l'utilisateur au centre (plus grand et stylisé)
               Expanded(
                 child: Text(
                   user?.prenom ?? 'Utilisateur Test',
                   style: const TextStyle(
                     fontSize: 24,
                     fontWeight: FontWeight.bold,
                     color: Colors.white,
                     fontFamily: 'Roboto',
                     shadows: [
                       Shadow(
                         offset: Offset(1, 1),
                         blurRadius: 3,
                         color: Colors.black38,
                       ),
                     ],
                   ),
                   textAlign: TextAlign.center,
                 ),
               ),
              
              // Icône de profil à droite (violet comme dans votre thème)
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
          
                     const SizedBox(height: 4), // Espace très réduit entre le nom et le slogan
           
           // Slogan centré
           Text(
             'Votre Sécurité, notre priorité',
             style: const TextStyle(
               fontSize: 16,
               color: Colors.white,
               fontStyle: FontStyle.italic,
               fontWeight: FontWeight.w600,
               shadows: [
                 Shadow(
                   offset: Offset(1, 1),
                   blurRadius: 2,
                   color: Colors.black26,
                 ),
               ],
             ),
             textAlign: TextAlign.center,
           ),
          
                     const SizedBox(height: 16), // Réduit l'espace entre le slogan et les icônes
           
           // Icônes de statut (WiFi, GPS, Micro) - plus espacées
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Statut WiFi (en ligne)
              _buildStatusIcon(
                icon: Icons.wifi,
                isActive: true,
                label: 'En ligne',
                color: AppTheme.successColor,
              ),
              
              // Statut GPS
              _buildStatusIcon(
                icon: Icons.location_on,
                isActive: GeolocationService.instance.isTracking.value,
                label: 'GPS',
                color: AppTheme.primaryColor,
              ),
              
              // Statut micro
              _buildStatusIcon(
                icon: Icons.mic,
                isActive: false, // TODO: Implémenter le statut du micro
                label: 'Micro',
                color: AppTheme.secondaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit une icône de statut
  Widget _buildStatusIcon({
    required IconData icon,
    required bool isActive,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color : Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construit le bouton SOS principal
  Widget _buildSOSButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Column(
          children: [
            // Grand cercle rouge principal avec lueur pulsante exacte (comme dans l'image)
            GestureDetector(
              onTap: () => _triggerEmergency(),
              child: Container(
                width: 280, // Ajusté pour éviter que l'ombre touche le header
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF0000), // Rouge vif exact #FF0000
                  boxShadow: [
                    // Lueur rouge pulsante et diffuse (transition rouge → rose → blanc)
                    BoxShadow(
                      color: const Color(0xFFFF0000).withValues(alpha: 0.6),
                      blurRadius: 40 + (30 * _pulseController.value),
                      spreadRadius: 15 + (10 * _pulseController.value),
                    ),
                    // Lueur rose intermédiaire pour la transition
                    BoxShadow(
                      color: const Color(0xFFEE82EE).withValues(alpha: 0.4), // Couleur secondaire
                      blurRadius: 80,
                      spreadRadius: 30,
                    ),
                    // Lueur externe blanche très douce et étendue
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 120,
                      spreadRadius: 50,
                    ),
                    // Lueur supplémentaire pour l'effet radial complet
                    BoxShadow(
                      color: const Color(0xFFFF0000).withValues(alpha: 0.2),
                      blurRadius: 160,
                      spreadRadius: 70,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.star_border, // Astérisque blanche exacte (plus proche de l'image)
                    size: 85, // Ajusté pour correspondre exactement à l'image
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 18), // Espacement optimisé pour éviter le header
            
            // Bouton "SOS" blanc avec contours et ombres exacts (comme dans l'image)
            Container(
              width: 130, // Ajusté pour correspondre exactement à l'image
              height: 42, // Ajusté pour correspondre exactement à l'image
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25), // Coins très arrondis comme dans l'image
                boxShadow: [
                  // Ombre subtile et douce (comme dans l'image)
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                  // Ombre supplémentaire pour la profondeur 3D
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: 19, // Ajusté pour correspondre exactement à l'image
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.2, // Espacement des lettres pour plus de lisibilité
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Déclenche l'urgence
  void _triggerEmergency() {
    // TODO: Implémenter le déclenchement d'urgence
    print('🚨 URGENCE DÉCLENCHÉE !');
  }

  /// Construit le bouton Actions Rapides
  Widget _buildQuickActionsButton() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeController.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _fadeController.value)),
            child: ElevatedButton.icon(
              onPressed: () => _showQuickActionsModal(),
              icon: const Icon(Icons.flash_on),
              label: const Text('Actions Rapides'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 4,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construit le footer avec navigation
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFooterButton(
            icon: Icons.home,
            label: 'Accueil',
            onTap: () => _navigateToHome(),
          ),
          _buildFooterButton(
            icon: Icons.contacts,
            label: 'Contact',
            onTap: () => _navigateToContacts(),
          ),
          _buildFooterButton(
            icon: Icons.forum,
            label: 'Forum',
            onTap: () => _navigateToForum(),
          ),
          _buildFooterButton(
            icon: Icons.menu,
            label: 'Menu',
            onTap: () => _showMenuModal(),
          ),
        ],
      ),
    );
  }

  /// Construit un bouton du footer
  Widget _buildFooterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche la fenêtre modale des actions rapides
  void _showQuickActionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickActionsModal(),
    );
  }

  /// Affiche la fenêtre modale du menu
  void _showMenuModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MenuModal(),
    );
  }

  /// Navigue vers les contacts
  void _navigateToContacts() {
    // TODO: Implémenter la navigation vers les contacts
    print('👥 Navigation vers les contacts');
  }

  /// Navigue vers le forum
  void _navigateToForum() {
    // TODO: Implémenter la navigation vers le forum
    print('💬 Navigation vers le forum');
  }

  /// Navigue vers le profil
  void _navigateToProfile() {
    // TODO: Implémenter la navigation vers le profil
    print('👤 Navigation vers le profil');
  }

  /// Navigue vers l'accueil
  void _navigateToHome() {
    // TODO: Implémenter la navigation vers l'accueil
    print('🏠 Navigation vers l\'accueil');
  }



}
