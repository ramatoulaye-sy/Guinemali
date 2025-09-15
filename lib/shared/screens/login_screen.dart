import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:guinemali/core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_model.dart';

/// Écran de connexion pour l'application Guinèmali
/// Permet aux utilisateurs existants de se connecter avec prénom et PIN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pseudoController = TextEditingController();
  final _pinController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePin = true;
  String? _errorMessage;

  @override
  void dispose() {
    _pseudoController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                SizedBox(height: size.height * 0.03),
                
                // En-tête avec icône
                _buildHeader(theme),
                
                SizedBox(height: size.height * 0.03),
                
                // Formulaire de connexion
                _buildLoginForm(theme),
                
                const SizedBox(height: AppConstants.paddingMedium),
                
                // Bouton de connexion
                _buildLoginButton(),
                
                const SizedBox(height: AppConstants.paddingMedium),
                
                // Liens utiles
                _buildHelpLinks(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construit l'en-tête avec l'icône de connexion
  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
                            color: AppConstants.primaryColor.withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.login,
            size: 40,
            color: AppConstants.primaryColor,
          ),
        )
            .animate()
            .scale(
              duration: AppConstants.animationDurationMedium,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: AppConstants.animationDurationMedium),

        const SizedBox(height: AppConstants.paddingMedium),

        Text(
          'Connexion',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppConstants.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .slideY(
              begin: 0.3,
              duration: AppConstants.animationDurationMedium,
            )
            .fadeIn(delay: const Duration(milliseconds: 200)),

        const SizedBox(height: AppConstants.paddingSmall),

        Text(
          'Connectez-vous avec votre pseudo et votre code PIN',
          style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppConstants.primaryColor.withOpacity(0.7),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )
            .animate()
            .slideY(
              begin: 0.3,
              duration: AppConstants.animationDurationMedium,
            )
            .fadeIn(delay: const Duration(milliseconds: 400)),
      ],
    )
        .animate()
        .slideY(
          begin: 0.3,
          duration: AppConstants.animationDurationMedium,
        )
        .fadeIn(delay: const Duration(milliseconds: 200));
  }

  /// Construit le formulaire de connexion
  Widget _buildLoginForm(ThemeData theme) {
    return Card(
      elevation: 8,
      shadowColor: AppConstants.primaryColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Message d'erreur
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppConstants.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    border: Border.all(
                      color: AppConstants.errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppConstants.errorColor,
                        size: AppConstants.iconSizeSmall,
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppConstants.errorColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .slideX(begin: 0.3)
                    .fadeIn(),

                    // Champ pseudo
      TextFormField(
        controller: _pseudoController,
        decoration: InputDecoration(
          labelText: 'Pseudo',
          hintText: 'Entrez votre pseudo',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: _pseudoController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _pseudoController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                textInputAction: TextInputAction.next,
                autocorrect: false,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                validator: (v) => _validatePseudo(v?.trim().toLowerCase()),
                onChanged: (value) => setState(() {}),
              )
                  .animate()
                  .slideX(
                    begin: -0.3,
                    duration: AppConstants.animationDurationMedium,
                  )
                  .fadeIn(delay: const Duration(milliseconds: 400)),

              const SizedBox(height: AppConstants.paddingLarge),

              // Champ PIN
              TextFormField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'Code PIN',
                  hintText: 'Entrez votre code PIN',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePin ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePin = !_obscurePin;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(AppConstants.pinMaxLength),
                ],
                validator: _validatePin,
                onFieldSubmitted: (_) => _handleLogin(),
              )
                  .animate()
                  .slideX(
                    begin: 0.3,
                    duration: AppConstants.animationDurationMedium,
                  )
                  .fadeIn(delay: const Duration(milliseconds: 500)),

              const SizedBox(height: AppConstants.paddingMedium),

              // Aide PIN
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: AppConstants.iconSizeSmall,
                    color: AppConstants.primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Text(
                      'Votre code PIN contient ${AppConstants.pinMinLength} à ${AppConstants.pinMaxLength} chiffres',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppConstants.primaryColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 600)),
            ],
          ),
        ),
      ),
    )
        .animate()
        .slideY(
          begin: 0.3,
          duration: AppConstants.animationDurationMedium,
        )
        .fadeIn(delay: const Duration(milliseconds: 200));
  }

  /// Construit le bouton de connexion
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleLogin,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppConstants.whiteColor,
                  ),
                ),
              )
            : const Icon(Icons.login),
        label: Text(
          _isLoading ? 'Connexion...' : 'Se connecter',
          style: const TextStyle(
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
        )
        .fadeIn(delay: const Duration(milliseconds: 700));
  }

  /// Construit les liens d'aide
  Widget _buildHelpLinks(ThemeData theme) {
    return Column(
      children: [
        TextButton(
          onPressed: () => _showForgotPinDialog(),
          child: Text(
            'PIN oublié ?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppConstants.primaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),

        const SizedBox(height: AppConstants.paddingSmall),

        // Utiliser Wrap pour éviter l'overflow
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppConstants.paddingSmall,
          children: [
            Text(
              'Pas encore de compte ? ',
              style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppConstants.primaryColor.withOpacity(0.7),
              ),
            ),
            TextButton(
              onPressed: () => context.pushReplacement(AppConstants.routeRegister),
              child: const Text(
                'S\'inscrire',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 800));
  }

  /// Valide le pseudo
  String? _validatePseudo(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le pseudo est requis';
    }
    if (value.length < 2) {
      return 'Le pseudo doit contenir au moins 2 caractères';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Pseudo invalide (lettres, chiffres et _ uniquement)';
    }
    return null;
  }

  /// Valide le PIN
  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le code PIN est requis';
    }
    if (value.length < AppConstants.pinMinLength) {
      return 'Le PIN doit contenir au moins ${AppConstants.pinMinLength} chiffres';
    }
    if (!RegExp(AppConstants.pinPattern).hasMatch(value)) {
      return 'Le PIN ne doit contenir que des chiffres';
    }
    return null;
  }

  /// Gère la connexion
  Future<void> _handleLogin() async {
    // Effacer les erreurs précédentes
    setState(() {
      _errorMessage = null;
    });

    // Valider le formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Utiliser l'AuthProvider au lieu du service direct
      final success = await context.read<AuthProvider>().login(
        pseudo: _pseudoController.text.trim().toLowerCase(),
        pin: _pinController.text.trim(),
      );
      
      if (success) {
        // Récupérer l'utilisateur depuis l'AuthProvider
        final user = context.read<AuthProvider>().currentUser;
        if (user != null && mounted) {
          // Rediriger vers l'écran approprié selon le type d'utilisateur
          _redirectToUserScreen(user.typeUtilisateur);
        }
      } else {
        throw Exception('Échec de la connexion');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });

        // Faire vibrer en cas d'erreur
        HapticFeedback.mediumImpact();
      }
    }
  }

  /// Redirige vers l'écran approprié selon le type d'utilisateur
  void _redirectToUserScreen(UserType userType) {
    // Attendre un peu pour que l'état d'authentification soit mis à jour
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        switch (userType) {
          case UserType.victime:
            context.go(AppConstants.routeVictimDashboard);
            break;
          case UserType.aidant:
            context.go(AppConstants.routeHelperHome);
            break;
          case UserType.ong:
            context.go(AppConstants.routeONGHome);
            break;
          case UserType.admin:
            context.go(AppConstants.routeAdminHome);
            break;
        }
      }
    });
  }

  /// Affiche la boîte de dialogue pour PIN oublié
  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PIN oublié'),
        content: const Text(
          'Pour récupérer votre PIN, contactez le support technique de Guinèmali.\n\n'
          'Par sécurité, votre PIN ne peut pas être récupéré automatiquement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Ouvrir le contact support
              _contactSupport();
            },
            child: const Text('Contacter le support'),
          ),
        ],
      ),
    );
  }

  /// Ouvre le contact support
  void _contactSupport() {
    // TODO: Implémenter le contact support
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Contact support à implémenter'),
        backgroundColor: AppConstants.infoColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
