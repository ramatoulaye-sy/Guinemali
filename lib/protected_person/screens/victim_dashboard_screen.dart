import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/geolocation_service.dart';
import '../../core/services/alert_service.dart';
import '../../core/services/evidence_service.dart';
import '../../core/services/emergency_contact_service.dart';
import '../../core/services/storage_service.dart';
import 'dart:async';
import 'dart:convert';
import '../../core/models/user_model.dart';
import '../widgets/menu_modal.dart';
import '../../shared/screens/app_lock_screen.dart';
import '../../core/services/security_service.dart';
import '../../core/services/local_push_service.dart';

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
  
  // Variables d'état pour les services
  bool _isOnline = true;
  bool _isGpsActive = false;
  bool _isMicrophoneActive = false;
  bool _isRecording = false;
  
  // Variable pour suivre la page active dans le footer
  int _currentFooterIndex = 0; // 0 = Accueil, 1 = Contact, 2 = Forum, 3 = Menu
  
  // Timer pour mettre à jour les statuts
  Timer? _statusTimer;


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
    _statusTimer?.cancel();
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
    
    // Démarrer la vérification des statuts en temps réel
    _startStatusMonitoring();
  }
  
  Widget _buildDialogAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFee82ee).withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
          border: Border.all(color: const Color(0xFFee82ee).withOpacity(0.35)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 6),
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text(' ', style: TextStyle(fontSize: 0)),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Démarre la surveillance des statuts en temps réel
  void _startStatusMonitoring() {
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateServiceStatus();
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLock();
  }

  Future<void> _maybeLock() async {
    final method = await SecurityService.instance.getLockMethod();
    if (method == AppLockMethod.none) return;
    if (!mounted) return;
    final unlocked = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AppLockScreen(),
    );
    if (unlocked != true && mounted) {
      Navigator.of(context).pop();
    }
  }
  
  /// Met à jour le statut des services
  Future<void> _updateServiceStatus() async {
    if (!mounted) return;
    
    try {
      // Vérifier le statut GPS
      final gpsEnabled = await Geolocator.isLocationServiceEnabled();
      final gpsPermission = await Geolocator.checkPermission();
      final isGpsActive = gpsEnabled && gpsPermission == LocationPermission.whileInUse;
      
      // Vérifier le statut du micro (simulation pour l'instant)
      final isMicroActive = _isRecording || await _checkMicrophoneStatus();
      
      // Vérifier la connectivité réseau
      final isOnline = await _checkNetworkStatus();
      
      setState(() {
        _isGpsActive = isGpsActive;
        _isMicrophoneActive = isMicroActive;
        _isOnline = isOnline;
      });
    } catch (e) {
      print('❌ Erreur lors de la vérification des statuts: $e');
    }
  }
  
  /// Vérifie le statut du microphone
  Future<bool> _checkMicrophoneStatus() async {
    // TODO: Implémenter la vraie vérification du statut du micro
    // Pour l'instant, on simule
    return _isRecording;
  }
  
  /// Vérifie le statut de la connectivité réseau
  Future<bool> _checkNetworkStatus() async {
    // TODO: Implémenter la vraie vérification de la connectivité
    // Pour l'instant, on simule
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec logo, nom utilisateur et icônes de statut
            _buildHeader(user),
            
            // Contenu principal scrollable pour éviter les overflows (clavier/dialogues)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFooter(),
    );
  }

  /// Construit le header avec logo, nom utilisateur et icônes de statut
  Widget _buildHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withOpacity(0.85),
            AppConstants.secondaryColor.withOpacity(0.8),
          ],
          stops: const [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo Guinémali à gauche - POSITION INITIALE
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 24,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Guinémali',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Icône profil + Nom utilisateur et slogan au centre - NOUVEAU LAYOUT
          Expanded(
            child: Row(
              children: [
                // Icône profil DEVANT le nom utilisateur - CLIQUABLE
                GestureDetector(
                  onTap: () {
                    print('👤 Clic sur le bouton profil détecté');
                    _showProfileOptions(user);
                  },
                  child: Container(
                    width: 40, // Légèrement agrandi pour être plus cliquable
                    height: 40, // Légèrement agrandi pour être plus cliquable
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5, // Bordure plus visible
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Builder(builder: (context) {
                        final cached = StorageService.instance.getString('profile_photo_url');
                        final effectiveUrl = (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                            ? user.photoUrl!
                            : (cached ?? '');
                        if (effectiveUrl.isNotEmpty) {
                          return Image.network(
                            effectiveUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_outline, color: Colors.white, size: 20),
                          );
                        }
                        return const Icon(Icons.person_outline, color: Colors.white, size: 20);
                      }),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12), // Espacement entre profil et texte
                
                // Nom utilisateur et slogan - CENTRÉ DE FAÇON ESTHÉTIQUE
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.prenom ?? 'Utilisateur',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Votre Sécurité, notre priorité',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Icônes de statut À DROITE - ÉLÉGANTES ET CLIQUABLES
          InkWell(
            onTap: () {
              print('🎯 Clic détecté sur WiFi');
              _showNetworkStatus();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 28, // Plus petit et élégant
              height: 28, // Plus petit et élégant
              margin: const EdgeInsets.all(6), // Zone de clic étendue
              decoration: BoxDecoration(
                color: _isOnline 
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20), // Plus arrondi
                border: Border.all(
                  color: _isOnline 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.15),
                  width: 0.8, // Plus fin
                ),
                boxShadow: _isOnline ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
              child: Icon(
                Icons.wifi,
                size: 14, // Plus petit et discret
                color: _isOnline 
                    ? Colors.blue
                    : Colors.white.withOpacity(0.6),
              ),
            ),
          ),
          
          InkWell(
            onTap: () {
              print('🎯 Clic détecté sur GPS');
              _showGpsStatus();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 28, // Plus petit et élégant
              height: 28, // Plus petit et élégant
              margin: const EdgeInsets.all(6), // Zone de clic étendue
              decoration: BoxDecoration(
                color: _isGpsActive 
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20), // Plus arrondi
                border: Border.all(
                  color: _isGpsActive 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.15),
                  width: 0.8, // Plus fin
                ),
                boxShadow: _isGpsActive ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
              child: Icon(
                Icons.gps_fixed,
                size: 14, // Plus petit et discret
                color: _isGpsActive 
                    ? Colors.green
                    : Colors.white.withOpacity(0.6),
              ),
            ),
          ),
          
          InkWell(
            onTap: () {
              print('🎯 Clic détecté sur Micro');
              _showMicrophoneStatus();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 28, // Plus petit et élégant
              height: 28, // Plus petit et élégant
              margin: const EdgeInsets.all(6), // Zone de clic étendue
              decoration: BoxDecoration(
                color: _isMicrophoneActive 
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20), // Plus arrondi
                border: Border.all(
                  color: _isMicrophoneActive 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.15),
                  width: 0.8, // Plus fin
                ),
                boxShadow: _isMicrophoneActive ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
              child: Icon(
                Icons.mic,
                size: 14, // Plus petit et discret
                color: _isMicrophoneActive 
                    ? Colors.orange
                    : Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une icône de statut (version normale)
  Widget _buildStatusIcon({
    required IconData icon,
    required bool isActive,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withOpacity(0.25)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
                ? Colors.white.withOpacity(0.5)
                : Colors.white.withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: onTap != null ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ] : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive 
              ? color
              : Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  /// Construit une petite icône de statut pour le header (en haut à droite)
  Widget _buildSmallStatusIcon({
    required IconData icon,
    required bool isActive,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        print('🎯 Clic détecté sur icône: $icon');
        if (onTap != null) {
          onTap();
        }
      },
      child: Container(
        width: 32, // Agrandi pour être cliquable
        height: 32, // Agrandi pour être cliquable
        padding: const EdgeInsets.all(4), // Padding pour zone de clic plus grande
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8), // Plus arrondi
          border: Border.all(
            color: isActive 
                ? Colors.white.withOpacity(0.4)
                : Colors.white.withOpacity(0.2),
            width: 1, // Légèrement plus épais
          ),
        ),
        child: Icon(
          icon,
          size: 16, // Légèrement plus grand pour être visible
          color: isActive 
              ? color
              : Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }
  
  /// Affiche le statut de la connectivité réseau
  void _showNetworkStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off,
              color: _isOnline ? Colors.blue : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              _isOnline ? 'WiFi Connecté' : 'WiFi Déconnecté',
              style: TextStyle(
                color: _isOnline ? Colors.blue : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isOnline 
                  ? 'Votre appareil est connecté au réseau WiFi.'
                  : 'Votre appareil n\'est pas connecté au réseau WiFi.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.blue.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isOnline ? Colors.blue.shade200 : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isOnline ? Icons.check_circle : Icons.error,
                    color: _isOnline ? Colors.blue : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isOnline 
                          ? 'Connectivité WiFi stable'
                          : 'Vérifiez votre connexion WiFi',
                      style: TextStyle(
                        color: _isOnline ? Colors.blue.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
  
  /// Affiche le statut GPS
  void _showGpsStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              _isGpsActive ? Icons.gps_fixed : Icons.gps_off,
              color: _isGpsActive ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              _isGpsActive ? 'GPS Actif' : 'GPS Inactif',
              style: TextStyle(
                color: _isGpsActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isGpsActive 
                  ? 'Le suivi GPS est actif et fonctionne correctement.'
                  : 'Le suivi GPS n\'est pas actif. Vérifiez les permissions de localisation.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isGpsActive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isGpsActive ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isGpsActive ? Icons.check_circle : Icons.error,
                    color: _isGpsActive ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isGpsActive 
                          ? 'Position GPS en cours de suivi'
                          : 'Permissions GPS requises',
                      style: TextStyle(
                        color: _isGpsActive ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          if (!_isGpsActive)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestGpsPermission();
              },
              child: const Text('Activer GPS'),
            ),
        ],
      ),
    );
  }
  
  /// Affiche le statut du microphone
  void _showMicrophoneStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              _isMicrophoneActive ? Icons.mic : Icons.mic_off,
              color: _isMicrophoneActive ? Colors.orange : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              _isMicrophoneActive ? 'Micro Actif' : 'Micro Inactif',
              style: TextStyle(
                color: _isMicrophoneActive ? Colors.orange : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isMicrophoneActive 
                  ? 'Le microphone est prêt pour l\'enregistrement audio.'
                  : 'L\'accès au microphone n\'est pas disponible.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isMicrophoneActive ? Colors.orange.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isMicrophoneActive ? Colors.orange.shade200 : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isMicrophoneActive ? Icons.check_circle : Icons.error,
                    color: _isMicrophoneActive ? Colors.orange : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isMicrophoneActive 
                          ? 'Microphone prêt pour l\'enregistrement'
                          : 'Permissions microphone requises',
                      style: TextStyle(
                        color: _isMicrophoneActive ? Colors.orange.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          if (!_isMicrophoneActive)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestMicrophonePermission();
              },
              child: const Text('Activer Micro'),
            ),
        ],
      ),
    );
  }
  
  /// Demande la permission GPS
  Future<void> _requestGpsPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        setState(() {
          _isGpsActive = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Permission GPS accordée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la demande de permission GPS: $e');
    }
  }
  
  /// Demande la permission microphone
  Future<void> _requestMicrophonePermission() async {
    try {
      // TODO: Implémenter la vraie demande de permission microphone
      // Pour l'instant, on simule
      setState(() {
        _isMicrophoneActive = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Permission microphone accordée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Erreur lors de la demande de permission microphone: $e');
    }
  }
  
  /// Affiche les options du profil utilisateur
  void _showProfileOptions(UserModel? user) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Profil',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFee82ee), Color(0xFF945acb)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: SingleChildScrollView(
                  child: Column(
          mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF945acb),
                            backgroundImage: (user?.photoUrl != null && (user!.photoUrl!.isNotEmpty)) ? NetworkImage(user.photoUrl!) : null,
                            child: (user?.photoUrl == null || user!.photoUrl!.isEmpty) ? const Icon(Icons.person, color: Colors.white, size: 16) : null,
                      ),
                      const SizedBox(width: 8),
                          const Text('Profil Utilisateur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18, shadows: [Shadow(color: Colors.black45, blurRadius: 6)])),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))]),
                        child: Row(children: [
                          Stack(alignment: Alignment.center, children: [Container(width: 58, height: 58, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFee82ee).withOpacity(0.5), blurRadius: 16, spreadRadius: 2)])), CircleAvatar(radius: 24, backgroundColor: const Color(0xFF945acb), backgroundImage: (user?.photoUrl != null && (user!.photoUrl!.isNotEmpty)) ? NetworkImage(user.photoUrl!) : null, child: (user?.photoUrl == null || user!.photoUrl!.isEmpty) ? const Icon(Icons.person, color: Colors.white) : null)]),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${user?.prenom ?? 'Prénom'} (${user?.pseudo ?? 'Pseudo'})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)), const SizedBox(height: 6), InkWell(onTap: () => _composePhone(user?.numTel), child: Row(children: const [Icon(Icons.phone, size: 16, color: Colors.grey), SizedBox(width: 6),])) , Text(user?.numTel ?? 'Non spécifié', style: const TextStyle(color: Colors.black87, decoration: TextDecoration.underline))])),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 2.8, children: [
                        _buildDialogAction(icon: Icons.edit, label: 'Modifier le profil', onTap: () { Navigator.of(context).pop(); _navigateToEditProfile(); }),
                        _buildDialogAction(icon: Icons.settings, label: 'Paramètres', onTap: () { Navigator.of(context).pop(); _navigateToSettings(); }),
                        _buildDialogAction(icon: Icons.security, label: 'Sécurité', onTap: () { Navigator.of(context).pop(); _navigateToSecurity(); }),
                        _buildDialogAction(icon: Icons.help_outline, label: 'Aide', onTap: () { Navigator.of(context).pop(); _navigateToHelp(); }),
                      ]),
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.center, child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF945acb), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), elevation: 6, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)), child: const Text('Fermer'))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Opacity(opacity: anim1.value, child: Transform.scale(scale: 0.98 + 0.02 * anim1.value, child: child));
      },
    );
  }
  
  void _composePhone(String? phone) {
    if (phone == null || phone.isEmpty) return;
    // Placeholder: ici on pourrait utiliser url_launcher
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Composer: $phone')));
  }

  // _buildProfileOption supprimé (non utilisé)
  
  /// Navigation vers l'édition du profil
  void _navigateToEditProfile() {
    try {
      context.push(AppConstants.routeVictimProfile);
    } catch (e) {
      print('❌ Erreur navigation profil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur lors de la navigation vers le profil'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Navigation vers les paramètres
  void _navigateToSettings() {
    try {
      context.push(AppConstants.routeVictimSettings);
    } catch (e) {
      print('❌ Erreur navigation paramètres: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur lors de la navigation vers les paramètres'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Navigation vers la sécurité
  void _navigateToSecurity() {
    try {
      // Pour l'instant, rediriger vers les paramètres (section sécurité)
      context.push(AppConstants.routeVictimSettings);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Redirection vers les paramètres (section sécurité)'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('❌ Erreur navigation sécurité: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur lors de la navigation vers la sécurité'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Navigation vers l'aide
  void _navigateToHelp() {
    try {
      context.push(AppConstants.routeVictimHelp);
    } catch (e) {
      print('❌ Erreur navigation aide: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur lors de la navigation vers l\'aide'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Construit le bouton SOS principal avec design expert et harmonie parfaite
  Widget _buildSOSButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Column(
          children: [
            const SizedBox(height: 24), // Espacement harmonieux
            
            // Bouton SOS avec design professionnel et ombres sophistiquées
            GestureDetector(
              onTap: () => _triggerEmergency(),
              child: Container(
                width: 280, // Taille fixe comme avant
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Dégradé radial sophistiqué pour la profondeur
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      const Color.fromARGB(255, 238, 5, 5), // Rouge plus clair et doux au centre
                      const Color.fromARGB(255, 239, 97, 97), // Rouge moyen vers l'extérieur
                    ],
                  ),
                  // Bordure subtile avec couleur primaire
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    width: 3,
                  ),
                  // Ombres expertes pour la profondeur et l'urgence
                  boxShadow: [
                    // Ombre interne pour la profondeur
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, 8),
                    ),
                    // Lueur rouge pulsante (effet d'urgence)
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.4),
                      blurRadius: 40 + (20 * _pulseController.value),
                      spreadRadius: 8 + (4 * _pulseController.value),
                    ),
                    // Halo violet subtil (couleur primaire)
                    BoxShadow(
                      color: AppConstants.primaryColor.withOpacity(0.15),
                      blurRadius: 80 + (30 * _pulseController.value),
                      spreadRadius: 20 + (10 * _pulseController.value),
                    ),
                    // Lueur blanche externe pour l'éclat
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 100 + (40 * _pulseController.value),
                      spreadRadius: 30 + (15 * _pulseController.value),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icône d'urgence avec animation subtile
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (0.05 * _pulseController.value),
                            child: const Icon(
                              Icons.emergency,
                              size: 80,
                        color: Colors.white,
                      ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Texte SOS avec typographie expert
                      const Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3.0,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 4,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Indicateur d'urgence subtil
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                    ],
              ),
            ),
              ),
            ),
            
            // Le bouton SOS principal est suffisant - suppression du bouton redondant
          ],
        );
      },
    );
  }

  /// Déclenche l'urgence avec confirmation et fonctionnalités avancées
  Future<void> _triggerEmergency() async {
    print('🚨🚨🚨 DASHBOARD SOS DÉCLENCHÉ - _triggerEmergency() COMMENCÉ 🚨🚨🚨');
    print('🚨 DÉBUT _triggerEmergency');
    
    // 1. Demander confirmation pour éviter les clics accidentels
    final confirmed = await _showEmergencyConfirmation();
    if (!confirmed) {
      print('❌ Confirmation annulée par l\'utilisateur');
      return;
    }
    
    print('✅ Confirmation validée par l\'utilisateur');

    try {
      print('🔍 Étape 1: Rafraîchissement de l\'utilisateur...');
      
      // 2. Rafraîchir l'utilisateur et vérifier la session
      try {
        await context.read<AuthProvider>().refreshUser();
        print('✅ Utilisateur rafraîchi');
      } catch (_) {
        print('⚠️ Erreur rafraîchissement utilisateur (ignorée)');
      }
      final currentUser = context.read<AuthProvider>().currentUser;
      print('🔍 Utilisateur actuel: ${currentUser?.id}');
      if (currentUser == null) {
        print('❌ Utilisateur non connecté, arrêt de la procédure');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Utilisateur non connecté. Veuillez vous reconnecter.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      print('✅ Utilisateur connecté: ${currentUser.id}');

      print('🔍 Étape 2: Création de l\'alerte AVANT navigation...');
      
      // 3. Créer l'alerte d'urgence D'ABORD (pour que l'écran la trouve)
      print('🚨 Création de l\'alerte d\'urgence...');
      
      // Obtenir la position actuelle
      final position = await GeolocationService.instance.getCurrentPosition();
      print('✅ Position récupérée: ${position.latitude}, ${position.longitude}');
      
      // Créer l'alerte d'urgence
      final alertId = await AlertService.instance.createEmergencyAlert(
        latitude: position.latitude,
        longitude: position.longitude,
        type: 'urgence',
        dangerLevel: 5,
        description: 'Alerte SOS déclenchée depuis le dashboard',
      );
      
      print('✅ Alerte créée avec succès: $alertId');

      print('🔍 Étape 3: Navigation APRÈS création de l\'alerte...');
      
      // 4. Navigation APRÈS la création de l'alerte (pour que l'écran la trouve)
      print('🧭 Navigation vers l\'écran d\'alerte active...');
      print('🧭 Contexte monté: $mounted');
      if (!mounted) {
        print('❌ Contexte non monté, mais alerte créée avec succès');
        return;
      }
      
      // Navigation avec GoRouter
      context.go(AppConstants.routeVictimActiveAlert);
      print('✅ Navigation lancée avec GoRouter');

      print('🎉 FIN _triggerEmergency - Navigation lancée');
      
    } catch (e) {
      print('❌ Erreur lors du déclenchement de l\'urgence: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du déclenchement: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Affiche la confirmation d'urgence
  Future<bool> _showEmergencyConfirmation() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red.shade700, size: 32),
            const SizedBox(width: 12),
            const Text(
              '🚨 ALERTE D\'URGENCE',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question principale avec design professionnel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red[700],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Êtes-vous en danger ?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Actions qui seront déclenchées avec design moderne
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actions automatiques :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Liste des actions avec icônes et textes visibles
                    _buildActionItem(
                      Icons.location_on,
                      'Votre position GPS sera partagée',
                      Colors.blue[700]!,
                    ),
                    const SizedBox(height: 8),
                    _buildActionItem(
                      Icons.mic,
                      'Un enregistrement audio/vidéo discret sera lancé',
                      Colors.orange[700]!,
                    ),
                    const SizedBox(height: 8),
                    _buildActionItem(
                      Icons.phone,
                      'Vos contacts d\'urgence seront alertés',
                      Colors.green[700]!,
                    ),
                    const SizedBox(height: 8),
                    _buildActionItem(
                      Icons.people,
                      'La communauté locale sera notifiée',
                      Colors.purple[700]!,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Avertissement important avec design d'urgence
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ne confirmez que si vous êtes réellement en danger !',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Bouton Annuler avec design professionnel
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          // Bouton de confirmation avec design d'urgence (sans Expanded pour éviter ParentDataWidget)
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.emergency, color: Colors.white, size: 20),
            label: const Text('CONFIRMER L\'URGENCE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Démarre l'enregistrement discret automatique
  Future<void> _startDiscreteRecording(String alertId) async {
    try {
      // Démarrer l'enregistrement audio discret
      await EvidenceService.instance.startAudioRecording(alertId);
      
      // Démarrer l'enregistrement vidéo discret (si disponible)
      try {
        await EvidenceService.instance.startVideoRecording(alertId);
      } catch (e) {
        print('⚠️ Enregistrement vidéo non disponible: $e');
      }

      // Enregistrer l'événement dans le service local
      await _logDiscreteRecordingEvent(alertId);

      print('🎤 Enregistrement discret démarré pour l\'alerte: $alertId');
      // Notification enregistr.
      LocalPushService.instance.showPersistent(
        id: 1002,
        title: 'Enregistrement en cours',
        body: 'Preuve audio/vidéo en cours...',
      );
    } catch (e) {
      print('❌ Erreur lors du démarrage de l\'enregistrement: $e');
    }
  }

  /// Enregistre l'événement d'enregistrement discret
  Future<void> _logDiscreteRecordingEvent(String alertId) async {
    try {
      final event = {
        'alertId': alertId,
        'type': 'discrete_recording_started',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'active',
      };
      
      await StorageService.instance.saveString('discrete_recording_$alertId', jsonEncode(event));
    } catch (e) {
      print('❌ Erreur lors de l\'enregistrement de l\'événement: $e');
    }
  }

  /// Envoie l'alerte à la communauté locale
  Future<void> _sendCommunityAlert(double latitude, double longitude, String alertId) async {
    try {
      // TODO: Implémenter l'envoi à la communauté locale
      // Pour l'instant, on simule l'envoi
      print('🌍 Envoi de l\'alerte à la communauté locale...');
      print('📍 Position: $latitude, $longitude');
      print('🔗 Lien vers l\'enregistrement: /evidence/$alertId');
      
      // Simuler un délai d'envoi
      await Future.delayed(const Duration(seconds: 1));
      
      print('✅ Alerte envoyée à la communauté locale');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi à la communauté: $e');
    }
  }

  /// Notifie les contacts d'urgence (version locale)
  Future<void> _notifyEmergencyContactsLocal(String alertId, dynamic position) async {
    try {
      print('📞 Notification des contacts d\'urgence...');
      
      // Récupérer le message personnalisé
      final customMessage = StorageService.instance.getString('custom_sos_message');
      print('📖 Lecture: custom_sos_message = "$customMessage"');
      
      // Utiliser EmergencyContactService pour envoyer les SMS
      await EmergencyContactService.instance.callAllContactsWithFallback(
        customMessage: customMessage,
      );
      
      print('✅ Contacts d\'urgence notifiés localement');
    } catch (e) {
      print('❌ Erreur lors de la notification des contacts: $e');
    }
  }

  /// Démarre le suivi GPS continu
  Future<void> _startContinuousGPSTracking(String alertId, dynamic position) async {
    try {
      print('📍 Démarrage du suivi GPS continu...');
      
      // Simuler le suivi GPS continu
      Timer.periodic(const Duration(seconds: 10), (timer) {
        print('📍 Suivi GPS actif - Alerte: $alertId');
        // TODO: Implémenter la vraie logique de suivi GPS
      });
      
      print('✅ Suivi GPS continu démarré');
    } catch (e) {
      print('❌ Erreur lors du démarrage du suivi GPS: $e');
    }
  }

  /// Construit un élément d'action avec icône et texte
  Widget _buildActionItem(IconData icon, String text, Color color) {
    return Row(
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
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  /// Affiche le succès avec option d'annulation
  void _showEmergencySuccessWithCancel(String alertId) {
    // Afficher le message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🚨 ALERTE CRÉÉE ! ID: ${alertId.substring(0, 8)}...\n'
                'Vous avez 3 secondes pour annuler avec le code secret',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'ANNULER',
          textColor: Colors.white,
          backgroundColor: Colors.red,
          onPressed: () => _showCancelEmergencyDialog(alertId),
        ),
      ),
    );

    // Démarrer le compte à rebours pour l'annulation
    _startCancelCountdown(alertId);
  }

  /// Démarre le compte à rebours pour l'annulation
  void _startCancelCountdown(String alertId) {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Le compte à rebours est terminé - l'utilisateur est déjà sur l'écran d'alerte
        print('⏰ Compte à rebours d\'annulation terminé pour l\'alerte: $alertId');
      }
    });
  }

  /// Affiche le dialogue d'annulation d'urgence
  Future<void> _showCancelEmergencyDialog(String alertId) async {
    final codeController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.orange.shade50,
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            const Text(
              '🔐 Annuler l\'Alerte',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez votre code secret pour annuler l\'alerte d\'urgence :',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Code Secret',
                hintText: 'Ex: 1234',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Attention : L\'annulation arrêtera l\'enregistrement et les alertes',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer l\'Alerte'),
          ),
          ElevatedButton(
            onPressed: () {
              final enteredCode = codeController.text.trim();
              if (enteredCode == '1234') { // Code secret par défaut
                Navigator.of(context).pop(true);
              } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
                    content: Text('❌ Code secret incorrect !'),
          backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('ANNULER L\'ALERTE'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _cancelEmergency(alertId);
    }
  }

  /// Annule l'alerte d'urgence
  Future<void> _cancelEmergency(String alertId) async {
    try {
      // Arrêter l'enregistrement
      try {
        await EvidenceService.instance.stopAudioRecording();
        await EvidenceService.instance.stopVideoRecording();
    } catch (e) {
        print('⚠️ Erreur lors de l\'arrêt de l\'enregistrement: $e');
      }

      // Marquer l'alerte comme annulée
      await AlertService.instance.cancelEmergencyAlert(alertId);

      // Retirer notifications persistantes
      await LocalPushService.instance.cancel(1001);
      await LocalPushService.instance.cancel(1002);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Alerte d\'urgence annulée avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      print('✅ Alerte d\'urgence annulée: $alertId');
    } catch (e) {
      print('❌ Erreur lors de l\'annulation: $e');
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de l\'annulation: $e'),
          backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
        ),
      );
      }
    }
  }

  /// Construit le bouton Actions Rapides
  Widget _buildQuickActionsButton() {
    // Rendre les boutons toujours visibles (suppression Opacity/Transform)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
                ElevatedButton.icon(
                  onPressed: () => _navigateToQuickActions(),
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
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _navigateToRealtimeMap(),
          icon: const Icon(Icons.map_outlined),
          label: const Text('Carte GPS en temps réel'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFee82ee),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 4,
          ),
        ),
      ],
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
      child: SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
            Expanded(
              child: _buildFooterButton(
            icon: Icons.home,
            label: 'Accueil',
                index: 0,
            onTap: () => _navigateToHome(),
          ),
            ),
            Expanded(
              child: _buildFooterButton(
            icon: Icons.contacts,
            label: 'Contact',
                index: 1,
            onTap: () => _navigateToContacts(),
          ),
            ),
            Expanded(
              child: _buildFooterButton(
            icon: Icons.forum,
            label: 'Forum',
                index: 2,
            onTap: () => _navigateToForum(),
          ),
            ),
            Expanded(
              child: _buildFooterButton(
                icon: Icons.menu_book,
                label: 'Ressources',
                index: 4,
                onTap: () => _navigateToResources(),
              ),
            ),
            Expanded(
              child: _buildFooterButton(
            icon: Icons.menu,
            label: 'Menu',
                index: 3,
            onTap: () => _showMenuModal(),
              ),
          ),
        ],
        ),
      ),
    );
  }

  /// Construit un bouton du footer avec indicateur de page active
  Widget _buildFooterButton({
    required IconData icon,
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    final isSelected = _currentFooterIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFooterIndex = index;
        });
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
              color: isSelected 
                  ? AppTheme.primaryColor 
                  : Colors.grey.shade600,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
                color: isSelected 
                    ? AppTheme.primaryColor 
                    : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Navigue vers la page des actions rapides
  void _navigateToQuickActions() {
    try {
      context.push(AppConstants.routeVictimQuickActions);
      print('⚡ Navigation vers les actions rapides');
    } catch (e) {
      print('❌ Erreur navigation actions rapides: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur navigation: $e')),
      );
    }
  }

  /// Navigation vers la carte GPS temps réel
  void _navigateToRealtimeMap() {
    try {
      // Utilise la route définie dans AppRouter (victim_live_map)
      context.push(AppConstants.routeVictimLiveMap);
    } catch (e) {
      print('❌ Erreur navigation carte: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur navigation: $e')),
      );
    }
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
    try {
      context.push(AppConstants.routeVictimContacts);
      print('👥 Navigation vers les contacts');
    } catch (e) {
      print('❌ Erreur navigation contacts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur navigation: $e')),
      );
    }
  }

  /// Navigue vers le forum
  void _navigateToForum() {
    try {
      context.push(AppConstants.routeVictimForum);
      print('💬 Navigation vers le forum');
    } catch (e) {
      print('❌ Erreur navigation forum: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur navigation: $e')),
      );
    }
  }

  void _navigateToResources() {
    try {
      context.push(AppConstants.routeVictimResources);
      print('📚 Navigation vers ressources éducatives');
    } catch (e) {
      print('❌ Erreur navigation ressources: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur navigation: $e')),
      );
    }
  }



  /// Navigue vers l'accueil (reste sur la page actuelle)
  void _navigateToHome() {
    // On est déjà sur l'accueil, juste mettre à jour l'index
    setState(() {
      _currentFooterIndex = 0;
    });
    print('🏠 Reste sur l\'accueil (dashboard)');
  }



}
