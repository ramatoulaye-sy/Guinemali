import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

/// Écran de bienvenue de l'application Guinèmali
/// Premier écran affiché aux utilisateurs avec options de connexion/inscription
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Démarrer les animations
    _backgroundController.forward();
    _contentController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: true);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black, // fond neutre pour bandes éventuelles
          image: const DecorationImage(
            image: AssetImage('assets/images/femmeguinemali.jpg'),
            fit: BoxFit.contain, // afficher toute l'image sans recadrage
            alignment: Alignment.center,
            colorFilter: ColorFilter.mode(
              Color.fromRGBO(0, 0, 0, 0.20), // overlay léger
              BlendMode.darken,
            ),
          ),
        ),
        foregroundDecoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.08),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.20),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                // En-tête avec logo et nom de l'app
                _buildHeader(size, theme),
                
                const SizedBox(height: 24),
                
                // Message de bienvenue (personnalisé si connecté)
                _buildWelcomeMessage(theme, userName: auth.currentUser?.prenom),
                
                const SizedBox(height: 32),
                
                // Boutons d'action
                _buildActionButtons(context, theme),
                
                const SizedBox(height: 24),
                
                // Footer avec informations légales
                _buildFooter(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construit l'en-tête avec le logo et le nom de l'application
  Widget _buildHeader(Size size, ThemeData theme) {
    final double logoSize = (size.width * 0.3).clamp(80, 120);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
          // Logo animé de l'application
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                AppConstants.logoPath,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
              ),
            ),
          )
              .animate()
              .scale(
                duration: AppConstants.animationDurationSlow,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: AppConstants.animationDurationMedium),

          const SizedBox(height: AppConstants.paddingMedium),

          // Nom de l'application
          Text(
            AppConstants.appName,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .slideY(
                begin: 0.5,
                duration: AppConstants.animationDurationMedium,
                curve: Curves.easeOut,
              )
              .fadeIn(delay: AppConstants.animationDurationFast),



          // Slogan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppConstants.appSlogan,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
              .animate()
              .slideY(
                begin: 0.3,
                duration: AppConstants.animationDurationMedium,
                curve: Curves.easeOut,
              )
              .fadeIn(delay: const Duration(milliseconds: 1000)),
          ],
        ),
      ),
    );
  }

  /// Construit le message de bienvenue
  Widget _buildWelcomeMessage(ThemeData theme, {String? userName}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      child: Column(
        children: [
          Text(
            userName != null && userName.isNotEmpty
                ? 'Bienvenue, $userName'
                : 'Bienvenue sur Guinèmali',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .slideX(
                begin: -0.5,
                duration: AppConstants.animationDurationMedium,
                curve: Curves.easeOut,
              )
              .fadeIn(delay: const Duration(milliseconds: 800)),

          const SizedBox(height: AppConstants.paddingMedium),

          Text(
            'Une application de sécurité dédiée à la protection des femmes et jeunes filles en Guinée.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
              shadows: [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .slideX(
                begin: 0.5,
                duration: AppConstants.animationDurationMedium,
                curve: Curves.easeOut,
              )
              .fadeIn(delay: const Duration(milliseconds: 1000)),

          const SizedBox(height: AppConstants.paddingLarge),

          // Icônes des fonctionnalités principales - utiliser Wrap pour éviter l'overflow
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 16,
            children: [
              _buildFeatureIcon(
                Icons.emergency,
                'Alerte\nUrgence',
                theme,
                delay: 1200,
              ),
              _buildFeatureIcon(
                Icons.location_on,
                'Géolocalisation\nTemps réel',
                theme,
                delay: 1400,
              ),
              _buildFeatureIcon(
                Icons.people,
                'Réseau\nSolidaire',
                theme,
                delay: 1600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit une icône de fonctionnalité
  Widget _buildFeatureIcon(
    IconData icon,
    String label,
    ThemeData theme, {
    required int delay,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: AppConstants.iconSizeLarge,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    )
        .animate()
        .scale(
          begin: const Offset(0.5, 0.5),
          duration: AppConstants.animationDurationMedium,
          curve: Curves.elasticOut,
        )
        .fadeIn(delay: Duration(milliseconds: delay));
  }

  /// Construit les boutons d'action
  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bouton Se connecter
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => context.push(AppConstants.routeLogin),
              icon: const Icon(Icons.login),
              label: const Text(
                'Se connecter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
              .animate()
              .slideY(
                begin: 0.5,
                duration: AppConstants.animationDurationMedium,
                curve: Curves.easeOut,
              )
              .fadeIn(delay: const Duration(milliseconds: 1800)),

          const SizedBox(height: AppConstants.paddingMedium),

          // Bouton S'inscrire
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => context.push(AppConstants.routeRegister),
              icon: const Icon(Icons.person_add),
              label: const Text(
                'S\'inscrire',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
              .animate()
              .slideY(
                begin: 0.5,
                duration: AppConstants.animationDurationMedium,
                curve: Curves.easeOut,
              )
              .fadeIn(delay: const Duration(milliseconds: 2000)),

          const SizedBox(height: AppConstants.paddingLarge),

          // Texte d'aide
          TextButton(
            onPressed: () {
              _showHelpDialog(context);
            },
            child: Text(
              'Besoin d\'aide ?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppConstants.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 2200)),
        ],
      ),
    );
  }

  /// Construit le footer
  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
          Text(
            'Version ${AppConstants.appVersion}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              shadows: [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 1,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          // Utiliser Wrap pour éviter l'overflow
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppConstants.paddingSmall,
            children: [
              TextButton(
                onPressed: () => _showPrivacyPolicy(context),
                child: Text(
                  'Confidentialité',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
              Text(
                '•',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              TextButton(
                onPressed: () => _showTermsOfService(context),
                child: Text(
                  'Conditions',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 2400));
  }

  /// Affiche la boîte de dialogue d'aide
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide'),
        content: const Text(
          'Guinèmali est une application de sécurité pour les femmes et jeunes filles.\n\n'
          'Fonctionnalités principales :\n'
          '• Alerte d\'urgence rapide\n'
          '• Partage de localisation\n'
          '• Réseau de soutien communautaire\n'
          '• Enregistrement de preuves\n\n'
          'Pour commencer, créez un compte ou connectez-vous.',
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

  /// Affiche la politique de confidentialité
  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Politique de confidentialité'),
        content: const SingleChildScrollView(
          child: Text(
            'Guinèmali respecte votre vie privée et protège vos données personnelles.\n\n'
            'Nous collectons uniquement les informations nécessaires pour :\n'
            '• Assurer votre sécurité\n'
            '• Vous connecter au réseau de soutien\n'
            '• Améliorer nos services\n\n'
            'Vos données sont chiffrées et ne sont jamais partagées sans votre consentement.',
          ),
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

  /// Affiche les conditions d'utilisation
  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conditions d\'utilisation'),
        content: const SingleChildScrollView(
          child: Text(
            'En utilisant Guinèmali, vous acceptez :\n\n'
            '• D\'utiliser l\'application de manière responsable\n'
            '• De ne pas transmettre de fausses alertes\n'
            '• De respecter la communauté d\'utilisateurs\n'
            '• Les conditions de stockage et de traitement des données\n\n'
            'L\'utilisation abusive peut entraîner la suspension du compte.',
          ),
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
}
