import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/user_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/providers/auth_provider.dart';

/// Écran d'inscription pour l'application Guinèmali
/// Permet aux nouveaux utilisateurs de créer un compte en tant que personne à protéger
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _pseudoController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _acceptTerms = false;
  bool _pseudoValidated = false;
  bool _isCheckingPseudo = false;
  String? _errorMessage;

  // Type utilisateur fixé à "victime" (personne à protéger)
  UserType _selectedUserType = UserType.victime;
  String _selectedLanguage = AppConstants.defaultLanguage;
  String? _selectedRegion;

  @override
  void dispose() {
    _prenomController.dispose();
    _pseudoController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
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
        child: _buildRegistrationForm(theme),
      ),
    );
  }

  /// Construit le formulaire d'inscription unifié
  Widget _buildRegistrationForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Form(
        key: _formKey,
      child: Column(
                children: [
                  // Logo et slogan
                  _buildLogoHeader(theme),

                  const SizedBox(height: AppConstants.paddingLarge),

            // En-tête
            _buildStepHeader(
              'Créer votre compte',
              'Remplissez vos informations pour vous inscrire en tant que personne à protéger',
              theme,
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Message d'erreur
            if (_errorMessage != null) _buildErrorMessage(),

            const SizedBox(height: AppConstants.paddingMedium),

            // Formulaire
            _buildInformationForm(theme),

            const SizedBox(height: AppConstants.paddingLarge),

            // Conditions d'utilisation
            _buildTermsAndConditions(theme),

            const SizedBox(height: AppConstants.paddingLarge),

            // Bouton d'inscription
            _buildRegisterButton(theme),

            const SizedBox(height: AppConstants.paddingLarge),

            // Lien vers la connexion
            _buildLoginLink(theme),
          ],
        ),
      ),
    );
  }

  /// Construit les conditions d'utilisation
  Widget _buildTermsAndConditions(ThemeData theme) {
    return Row(
              children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
          activeColor: AppConstants.primaryColor,
          checkColor: Colors.white,
          fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return AppConstants.primaryColor;
            }
            return AppConstants.primaryColor.withOpacity(0.3);
          }),
          side: BorderSide(
            color: AppConstants.primaryColor,
            width: 2,
          ),
        ),
                Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppConstants.primaryColor,
                ),
                children: [
                  const TextSpan(text: 'J\'accepte les '),
                  TextSpan(
                    text: 'conditions d\'utilisation',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' et la '),
                  TextSpan(
                    text: 'politique de confidentialité',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
            ),
          ],
        ),
      ),
          ),
        ),
      ],
    );
  }

  /// Construit le bouton d'inscription
  Widget _buildRegisterButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Créer mon compte',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// Construit le lien vers la connexion
  Widget _buildLoginLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
            children: [
        Text(
          'Déjà un compte ? ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppConstants.primaryColor,
          ),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: Text(
            'Se connecter',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  /// Construit l'en-tête avec le logo et le slogan
  Widget _buildLogoHeader(ThemeData theme) {
    return Column(
      children: [
        // Logo Guinemali officiel
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              AppConstants.logoPath,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si l'image ne charge pas
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryColor,
                        AppConstants.secondaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 60,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),

        // Nom de l'application (déjà inclus dans le logo)
        Text(
          AppConstants.appName,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),

        // Slogan
        Text(
          AppConstants.appSlogan,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppConstants.primaryColor.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
        )
            .animate()
        .fadeIn(delay: AppConstants.animationDurationFast)
        .slideY(begin: -0.3, end: 0);
  }

  /// Construit l'en-tête de l'étape
  Widget _buildStepHeader(String title, String subtitle, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppConstants.primaryColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// Construit le message d'erreur
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppConstants.errorColor.withOpacity(0.3)),
      ),
            child: Row(
              children: [
          Icon(
            Icons.error_outline,
            color: AppConstants.errorColor,
            size: AppConstants.iconSizeMedium,
          ),
          const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: AppConstants.errorColor,
                fontSize: AppConstants.fontSizeMedium,
              ),
                        ),
                      ),
                    ],
                  ),
    );
  }

  /// Construit le formulaire d'informations
  Widget _buildInformationForm(ThemeData theme) {
    return Column(
      children: [
        // Pseudo - CHAMP PRINCIPAL À VALIDER EN PREMIER
        TextFormField(
          controller: _pseudoController,
          enabled: !_isCheckingPseudo,
          decoration: InputDecoration(
            labelText: 'Pseudo *',
            hintText: 'Entrez votre pseudo unique',
            helperText: '3-20 caractères, lettres et chiffres uniquement',
            prefixIcon: Icon(Icons.alternate_email, color: AppConstants.primaryColor),
            suffixIcon: _pseudoValidated 
              ? Icon(Icons.check_circle, color: AppConstants.successColor)
              : IconButton(
                  icon: _isCheckingPseudo 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.search, color: AppConstants.primaryColor),
                  onPressed: _isCheckingPseudo ? null : _checkPseudoAvailability,
                  tooltip: 'Vérifier la disponibilité',
                ),
            labelStyle: TextStyle(
              color: _pseudoValidated ? AppConstants.successColor : AppConstants.primaryColor,
            ),
            hintStyle: TextStyle(color: AppConstants.primaryColor.withOpacity(0.6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(
                color: _pseudoValidated ? AppConstants.successColor : AppConstants.primaryColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(
                color: _pseudoValidated ? AppConstants.successColor : AppConstants.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(
                color: AppConstants.errorColor,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(
                color: AppConstants.errorColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: TextStyle(
            color: _pseudoValidated ? AppConstants.successColor : AppConstants.primaryColor,
          ),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
          ],
          validator: (v) => _validatePseudo(v?.trim().toLowerCase()),
          onChanged: (value) {
            if (_pseudoValidated && value != _pseudoController.text) {
              setState(() {
                _pseudoValidated = false;
              });
            }
          },
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Prénom
        TextFormField(
                          controller: _prenomController,
          decoration: InputDecoration(
            labelText: 'Prénom *',
            hintText: 'Entrez votre prénom',
            prefixIcon: Icon(Icons.person, color: AppConstants.primaryColor),
            labelStyle: TextStyle(color: AppConstants.primaryColor),
            hintStyle: TextStyle(color: AppConstants.primaryColor.withOpacity(0.6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(
                color: AppConstants.primaryColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(color: AppConstants.errorColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(color: AppConstants.errorColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: TextStyle(color: AppConstants.primaryColor),
          textInputAction: TextInputAction.next,
          validator: _validatePrenom,
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Numéro de téléphone (optionnel)
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _createFieldDecoration(
            labelText: 'Numéro de téléphone (optionnel)',
            hintText: '+224 123 45 67 89',
            prefixIcon: Icons.phone,
          ),
          style: TextStyle(color: AppConstants.primaryColor),
          textInputAction: TextInputAction.next,
          validator: _validatePhone,
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        // PIN
        TextFormField(
          controller: _pinController,
          obscureText: _obscurePin,
          decoration: _createFieldDecoration(
            labelText: 'Code PIN *',
            hintText: '4-6 chiffres',
            prefixIcon: Icons.lock,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePin ? Icons.visibility : Icons.visibility_off,
                color: AppConstants.primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _obscurePin = !_obscurePin;
                });
              },
            ),
          ),
          style: TextStyle(color: AppConstants.primaryColor),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6), // Limiter à 6 chiffres maximum
          ],
          validator: _validatePin,
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Confirmation PIN
        TextFormField(
          controller: _confirmPinController,
          obscureText: _obscureConfirmPin,
          decoration: _createFieldDecoration(
            labelText: 'Confirmer le code PIN *',
            hintText: 'Répétez votre code PIN',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPin ? Icons.visibility : Icons.visibility_off,
                color: AppConstants.primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPin = !_obscureConfirmPin;
                });
              },
            ),
          ),
          style: TextStyle(color: AppConstants.primaryColor),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6), // Limiter à 6 chiffres maximum
          ],
          validator: _validateConfirmPin,
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Langue
        DropdownButtonFormField<String>(
          value: _selectedLanguage,
          decoration: _createFieldDecoration(
            labelText: 'Langue',
            prefixIcon: Icons.language,
          ),
          dropdownColor: Colors.white,
          style: TextStyle(
            color: AppConstants.primaryColor,
            fontSize: AppConstants.fontSizeMedium,
          ),
          items: const [
            DropdownMenuItem(
              value: 'fr',
              child: Text(
                'Français',
                style: TextStyle(color: AppConstants.primaryColor),
            ),
            ),
            DropdownMenuItem(
              value: 'en',
            child: Text(
                'English',
                style: TextStyle(color: AppConstants.primaryColor),
            ),
          ),
        ],
          onChanged: (value) {
            setState(() {
              _selectedLanguage = value!;
            });
          },
        ),

            const SizedBox(height: AppConstants.paddingMedium),

        // Région (optionnel)
        DropdownButtonFormField<String?>(
          value: _selectedRegion,
          decoration: _createFieldDecoration(
            labelText: 'Région (optionnel)',
            prefixIcon: Icons.location_on,
          ),
          dropdownColor: Colors.white,
          style: TextStyle(
            color: AppConstants.primaryColor,
            fontSize: AppConstants.fontSizeMedium,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
            child: Text(
                'Non spécifié',
                style: TextStyle(color: AppConstants.primaryColor),
              ),
            ),
            ...AppConstants.guineanRegions.map((region) => 
              DropdownMenuItem(
                value: region,
            child: Text(
                  region,
                  style: TextStyle(color: AppConstants.primaryColor),
                ),
              )
            ),
          ],
              onChanged: (value) {
            setState(() {
              _selectedRegion = value;
            });
          },
        ),
      ],
    );
  }

  /// Gère l'inscription de l'utilisateur
  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les conditions d\'utilisation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

      setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Appel du service d'inscription
      final success = await context.read<AuthProvider>().register(
        prenom: _prenomController.text.trim(),
        pseudo: _pseudoController.text.trim().toLowerCase(),
        pin: _pinController.text.trim(),
        numTel: _phoneController.text.trim().isEmpty ? '' : _phoneController.text.trim(),
        userType: _selectedUserType.value, // Toujours "victime"
        langue: _selectedLanguage,
        region: _selectedRegion,
      );
      
      if (success) {
        // Récupérer l'utilisateur depuis l'AuthProvider
        final user = context.read<AuthProvider>().currentUser;
        if (user != null && mounted) {
          // Afficher un message de succès
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
              content: Text('Bienvenue ${user.prenom} !'),
                backgroundColor: AppConstants.successColor,
              duration: const Duration(seconds: 2),
              ),
            );

          // Redirection immédiate vers le dashboard sans délai
          if (mounted) {
            // Utiliser pushReplacement pour éviter le retour à l'écran d'inscription
            context.pushReplacement(AppConstants.routeVictimDashboard);
          }
        }
      } else {
        if (mounted) {
        setState(() {
            _errorMessage = 'Erreur lors de l\'inscription. Veuillez réessayer.';
        });
        }
      }
    } catch (e) {
      if (mounted) {
      setState(() {
          _errorMessage = 'Erreur: ${e.toString()}';
      });
      }
    } finally {
      if (mounted) {
      setState(() {
          _isLoading = false;
      });
    }
  }
  }

  /// Vérifie la disponibilité du pseudo
  Future<void> _checkPseudoAvailability() async {
    final pseudo = _pseudoController.text.trim().toLowerCase();
    if (pseudo.isEmpty) return;
    
    setState(() {
      _isCheckingPseudo = true;
    });

    try {
      // Vérifier la disponibilité du pseudo via une requête directe
      final response = await SupabaseService.instance.select(
          'utilisateurs',
        filters: {'pseudo': pseudo},
      );
      
      // Debug: afficher le pseudo recherché et les résultats
      if (AppConstants.enableLogging) {
        print('🔍 Vérification pseudo: "$pseudo"');
        print('📋 Résultats de la requête: ${response.length} utilisateurs trouvés');
        if (response.isNotEmpty) {
          print('👤 Pseudo existant trouvé: ${response.first['pseudo']}');
        }
      }
      
      final isAvailable = response.isEmpty;
      setState(() {
        _pseudoValidated = isAvailable;
        if (!isAvailable) {
          _errorMessage = 'Ce pseudo est déjà utilisé';
          } else {
          _errorMessage = null; // Clear previous error message
        }
      });
      
      if (AppConstants.enableLogging) {
        print('✅ Pseudo "$pseudo" ${isAvailable ? "disponible" : "non disponible"}');
        }
      } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur vérification pseudo: $e');
      }
        setState(() {
        _pseudoValidated = false;
        _errorMessage = 'Erreur lors de la vérification du pseudo';
      });
    } finally {
        setState(() {
        _isCheckingPseudo = false;
        });
      }
    }

  /// Valide le pseudo
  String? _validatePseudo(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le pseudo est requis';
    }
    if (value.length < 3 || value.length > 20) {
      return 'Le pseudo doit contenir entre 3 et 20 caractères';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Le pseudo ne peut contenir que des lettres, chiffres et _';
    }
    if (!_pseudoValidated && value.isNotEmpty) {
      return 'Veuillez vérifier la disponibilité du pseudo';
    }
    return null;
  }

  /// Valide le prénom
  String? _validatePrenom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prénom est requis';
    }
    if (value.trim().length < 2) {
      return 'Le prénom doit contenir au moins 2 caractères';
    }
    return null;
  }

  /// Valide le numéro de téléphone
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optionnel
    }
    if (!RegExp(r'^[0-9+\-\s\(\)]{8,15}$').hasMatch(value.trim())) {
      return 'Format de numéro invalide';
    }
    return null;
  }

  /// Valide le PIN
  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le code PIN est requis';
    }
    if (value.length < 4 || value.length > 6) {
      return 'Le code PIN doit contenir entre 4 et 6 chiffres';
    }
    return null;
  }

  /// Valide la confirmation du PIN
  String? _validateConfirmPin(String? value) {
    if (value == null || value.isEmpty) {
      return 'La confirmation du PIN est requise';
    }
    if (value != _pinController.text) {
      return 'Les codes PIN ne correspondent pas';
    }
    return null;
  }

  /// Crée une décoration de champ avec les couleurs Guinemali
  InputDecoration _createFieldDecoration({
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: Icon(prefixIcon, color: AppConstants.primaryColor),
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(color: AppConstants.primaryColor),
      hintStyle: TextStyle(color: AppConstants.primaryColor.withOpacity(0.6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        borderSide: BorderSide(
          color: AppConstants.primaryColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        borderSide: BorderSide(color: AppConstants.errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        borderSide: BorderSide(color: AppConstants.errorColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
