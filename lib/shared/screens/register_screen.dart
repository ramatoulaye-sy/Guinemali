import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:guinemali/core/models/auth_models.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/user_model.dart';

import '../../core/services/supabase_service.dart';
import '../../core/providers/auth_provider.dart'; // Added import for AuthProvider

/// Écran d'inscription pour l'application Guinèmali
/// Permet aux nouveaux utilisateurs de créer un compte
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _pseudoController = TextEditingController(); // Nouveau contrôleur pour le pseudo
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _phoneController = TextEditingController();
  
  late TabController _tabController;
  
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _acceptTerms = false;
  bool _pseudoValidated = false; // Nouveau: indique si le pseudo a été validé
  bool _isCheckingPseudo = false; // Nouveau: indique si on vérifie le pseudo
  String? _errorMessage;

  UserType _selectedUserType = UserType.victime;
  String _selectedLanguage = AppConstants.defaultLanguage;
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _prenomController.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppConstants.primaryColor,
          tabs: const [
            Tab(text: 'Type de compte', icon: Icon(Icons.person_outline)),
            Tab(text: 'Informations', icon: Icon(Icons.info_outline)),
            Tab(text: 'Finalisation', icon: Icon(Icons.check_circle_outline)),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildUserTypeTab(theme),
            _buildInformationTab(theme),
            _buildFinalizationTab(theme),
          ],
        ),
      ),
    );
  }

  /// Construit l'onglet de sélection du type d'utilisateur
  Widget _buildUserTypeTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo et slogan
                  _buildLogoHeader(theme),

                  const SizedBox(height: AppConstants.paddingMedium),

                  // En-tête
                  _buildStepHeader(
                    'Choisissez votre type de compte',
                    'Sélectionnez le type qui correspond le mieux à votre profil',
                    theme,
                  ),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // Options de type d'utilisateur
                  ...UserType.values.map((type) => _buildUserTypeCard(type, theme)),

                  const SizedBox(height: AppConstants.paddingLarge),
                ],
              ),
            ),
          ),

          // Bouton suivant épinglé en bas
          SafeArea(
            top: false,
            child: _buildNextButton(() {
              _tabController.animateTo(1);
            }),
          ),
        ],
      ),
    );
  }

  /// Construit l'onglet des informations personnelles
  Widget _buildInformationTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // En-tête
            _buildStepHeader(
              'Vos informations',
              'Remplissez vos informations personnelles',
              theme,
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Message d'erreur
            if (_errorMessage != null) _buildErrorMessage(),

            // Formulaire
            _buildInformationForm(theme),

            const SizedBox(height: AppConstants.paddingLarge),

            // Boutons navigation
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _tabController.animateTo(0),
                    child: const Text(
                      'Précédent',
                      style: TextStyle(color: AppConstants.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: _buildNextButton(() {
                    if (_formKey.currentState!.validate()) {
                      _tabController.animateTo(2);
                    }
                  }, enabled: _pseudoValidated), // Désactiver si pseudo non validé
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit l'onglet de finalisation
  Widget _buildFinalizationTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          // En-tête
          _buildStepHeader(
            'Finalisation',
            'Vérifiez vos informations et acceptez les conditions',
            theme,
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Résumé des informations
          _buildSummaryCard(theme),

          const SizedBox(height: AppConstants.paddingLarge),

          // Conditions d'utilisation
          _buildTermsSection(theme),

          const SizedBox(height: AppConstants.paddingLarge),

          // Boutons navigation
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text(
                    'Précédent',
                    style: TextStyle(color: AppConstants.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildRegisterButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit l'en-tête avec le logo et le slogan
  Widget _buildLogoHeader(ThemeData theme) {
    return Column(
      children: [
        // Logo
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              AppConstants.logoPath,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
        )
            .animate()
            .scale(
              duration: AppConstants.animationDurationMedium,
              curve: Curves.elasticOut,
            )
            .fadeIn(),

        const SizedBox(height: AppConstants.paddingSmall),

        // Nom de l'application
        Text(
          AppConstants.appName,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppConstants.primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .slideY(begin: 0.3)
            .fadeIn(delay: AppConstants.animationDurationFast),

        const SizedBox(height: AppConstants.paddingSmall),

        // Slogan
        Text(
          AppConstants.appSlogan,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppConstants.primaryColor.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )
            .animate()
            .slideY(begin: 0.3)
            .fadeIn(delay: const Duration(milliseconds: 200)),
      ],
    );
  }

  /// Construit l'en-tête d'une étape
  Widget _buildStepHeader(String title, String subtitle, ThemeData theme) {
    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppConstants.blackColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .slideY(begin: 0.3)
            .fadeIn(),

        const SizedBox(height: AppConstants.paddingSmall),

        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppConstants.blackColor,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .slideY(begin: 0.3)
            .fadeIn(delay: AppConstants.animationDurationFast),
      ],
    );
  }

  /// Construit une carte de type d'utilisateur
  Widget _buildUserTypeCard(UserType type, ThemeData theme) {
    final isSelected = _selectedUserType == type;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: isSelected ? AppConstants.primaryColor.withValues(alpha: 0.1) : AppConstants.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          side: BorderSide(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedUserType = type;
            });
          },
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Row(
              children: [
                // Icône
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected 
                        ? AppConstants.primaryColor 
                        : AppConstants.primaryColor.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    _getUserTypeIcon(type),
                    color: isSelected 
                        ? AppConstants.whiteColor 
                        : AppConstants.primaryColor,
                    size: AppConstants.iconSizeLarge,
                  ),
                ),

                const SizedBox(width: AppConstants.paddingMedium),

                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppConstants.primaryColor : AppConstants.blackColor,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      Text(
                        type.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppConstants.blackColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Indicateur de sélection
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppConstants.primaryColor,
                    size: AppConstants.iconSizeLarge,
                  ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .slideX(begin: 0.3)
        .fadeIn(delay: Duration(milliseconds: 100 * type.index))
        .animate();
  }

  /// Construit le formulaire d'informations
  Widget _buildInformationForm(ThemeData theme) {
    return Column(
      children: [
        // Pseudo - CHAMP PRINCIPAL À VALIDER EN PREMIER
        TextFormField(
          controller: _pseudoController,
          enabled: !_isCheckingPseudo, // Désactiver pendant la vérification
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
              color: _pseudoValidated ? AppConstants.successColor : AppConstants.blackColor,
            ),
            hintStyle: TextStyle(color: AppConstants.blackColor.withValues(alpha: 0.6)),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: _pseudoValidated ? AppConstants.successColor : AppConstants.primaryColor,
                width: _pseudoValidated ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _pseudoValidated ? AppConstants.successColor : AppConstants.primaryColor,
                width: 2,
              ),
            ),
          ),
          style: TextStyle(
            color: _pseudoValidated ? AppConstants.successColor : AppConstants.blackColor,
          ),
          textInputAction: TextInputAction.done,
          validator: _validatePseudo,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          ],
          onChanged: (value) {
            // Réinitialiser la validation si l'utilisateur modifie le pseudo
            if (_pseudoValidated && value != _pseudoController.text) {
              setState(() {
                _pseudoValidated = false;
              });
            }
          },
        )
            .animate()
            .slideX(begin: -0.3)
            .fadeIn(),

        const SizedBox(height: AppConstants.paddingMedium),

        // Indicateur de statut du pseudo
        if (!_pseudoValidated)
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppConstants.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              border: Border.all(color: AppConstants.warningColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppConstants.warningColor, size: 20),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: Text(
                    'Veuillez d\'abord valider votre pseudo pour continuer',
                    style: TextStyle(
                      color: AppConstants.warningColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )
            .animate()
            .slideX(begin: 0.3)
            .fadeIn(),

        const SizedBox(height: AppConstants.paddingMedium),

        // Prénom - GRISÉ JUSQU'À VALIDATION DU PSEUDO
        TextFormField(
          controller: _prenomController,
          enabled: _pseudoValidated, // Activer seulement après validation du pseudo
          decoration: InputDecoration(
            labelText: 'Prénom *',
            hintText: 'Entrez votre prénom',
            prefixIcon: Icon(
              Icons.person_outline, 
              color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
            ),
            labelStyle: TextStyle(
              color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
            ),
            hintStyle: TextStyle(
              color: _pseudoValidated ? AppConstants.blackColor.withValues(alpha: 0.6) : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
              ),
            ),
          ),
          style: TextStyle(
            color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
          ),
          textInputAction: TextInputAction.next,
          validator: _pseudoValidated ? _validatePrenom : null,
        )
            .animate()
            .slideX(begin: 0.3)
            .fadeIn(),

        const SizedBox(height: AppConstants.paddingMedium),

        // Code PIN - GRISÉ JUSQU'À VALIDATION DU PSEUDO
        TextFormField(
          controller: _pinController,
          enabled: _pseudoValidated,
          decoration: InputDecoration(
            labelText: 'Code PIN *',
            hintText: 'Créez votre code PIN sécurisé',
            prefixIcon: Icon(
              Icons.lock_outline, 
              color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePin ? Icons.visibility : Icons.visibility_off,
                color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
              ),
              onPressed: _pseudoValidated ? () => setState(() => _obscurePin = !_obscurePin) : null,
            ),
            labelStyle: TextStyle(
              color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
            ),
            hintStyle: TextStyle(
              color: _pseudoValidated ? AppConstants.blackColor.withValues(alpha: 0.6) : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
              ),
            ),
          ),
          style: TextStyle(
            color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
          ),
          obscureText: _obscurePin,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(AppConstants.pinMaxLength),
          ],
          validator: _pseudoValidated ? _validatePin : null,
        )
            .animate()
            .slideX(begin: -0.3)
            .fadeIn(delay: AppConstants.animationDurationFast),

        const SizedBox(height: AppConstants.paddingMedium),

        // Confirmation PIN - GRISÉ JUSQU'À VALIDATION DU PSEUDO
        TextFormField(
          controller: _confirmPinController,
          enabled: _pseudoValidated,
          decoration: InputDecoration(
            labelText: 'Confirmer le PIN *',
            hintText: 'Répétez votre code PIN',
            prefixIcon: Icon(
              Icons.lock_outline, 
              color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPin ? Icons.visibility : Icons.visibility_off,
                color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
              ),
              onPressed: _pseudoValidated ? () => setState(() => _obscureConfirmPin = !_obscureConfirmPin) : null,
            ),
            labelStyle: TextStyle(
              color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
            ),
            hintStyle: TextStyle(
              color: _pseudoValidated ? AppConstants.blackColor.withValues(alpha: 0.6) : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
              ),
            ),
          ),
          style: TextStyle(
            color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
          ),
          obscureText: _obscureConfirmPin,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(AppConstants.pinMaxLength),
          ],
          validator: _pseudoValidated ? _validateConfirmPin : null,
        )
            .animate()
            .slideX(begin: 0.3)
            .fadeIn(delay: const Duration(milliseconds: 200)),

        const SizedBox(height: AppConstants.paddingMedium),

        // Numéro de téléphone - GRISÉ JUSQU'À VALIDATION DU PSEUDO
        TextFormField(
          controller: _phoneController,
          enabled: _pseudoValidated,
          decoration: InputDecoration(
            labelText: 'Numéro de téléphone',
            hintText: '+224 XXX XX XX XX (optionnel)',
            prefixIcon: Icon(
              Icons.phone, 
              color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
            ),
            labelStyle: TextStyle(
              color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
            ),
            hintStyle: TextStyle(
              color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
              ),
            ),
          ),
          style: TextStyle(
            color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: _pseudoValidated ? _validatePhone : null,
        )
            .animate()
            .slideX(begin: 0.3)
            .fadeIn(delay: const Duration(milliseconds: 300)),

        const SizedBox(height: AppConstants.paddingMedium),

        // Région - GRISÉ JUSQU'À VALIDATION DU PSEUDO
        DropdownButtonFormField<String>(
          value: _selectedRegion,
          decoration: InputDecoration(
            labelText: 'Région',
            prefixIcon: Icon(
              Icons.location_on, 
              color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
            ),
            labelStyle: TextStyle(
              color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
              ),
            ),
          ),
          style: TextStyle(
            color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
          ),
          dropdownColor: AppConstants.whiteColor,
          items: AppConstants.guineanRegions.map((region) {
            return DropdownMenuItem<String>(
              value: region,
              child: Text(
                region,
                style: TextStyle(
                  color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
                ),
              ),
            );
          }).toList(),
          onChanged: _pseudoValidated ? (value) => setState(() => _selectedRegion = value) : null,
        )
            .animate()
            .slideX(begin: -0.3)
            .fadeIn(delay: const Duration(milliseconds: 400)),

        const SizedBox(height: AppConstants.paddingMedium),

        // Langue - GRISÉ JUSQU'À VALIDATION DU PSEUDO
        DropdownButtonFormField<String>(
          value: _selectedLanguage,
          decoration: InputDecoration(
            labelText: 'Langue préférée',
            prefixIcon: Icon(
              Icons.language, 
              color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
            ),
            labelStyle: TextStyle(
              color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: _pseudoValidated ? AppConstants.primaryColor : Colors.grey,
              ),
            ),
          ),
          style: TextStyle(
            color: _pseudoValidated ? AppConstants.blackColor : Colors.grey,
          ),
          dropdownColor: AppConstants.whiteColor,
          items: const [
            DropdownMenuItem(
              value: 'fr',
              child: Text('Français', style: TextStyle(color: AppConstants.blackColor)),
            ),
            DropdownMenuItem(
              value: 'en',
              child: Text('English', style: TextStyle(color: AppConstants.blackColor)),
            ),
            DropdownMenuItem(
              value: 'ff',
              child: Text('Fulani', style: TextStyle(color: AppConstants.blackColor)),
            ),
          ],
          onChanged: _pseudoValidated ? (value) => setState(() => _selectedLanguage = value!) : null,
        )
            .animate()
            .slideX(begin: 0.3)
            .fadeIn(delay: const Duration(milliseconds: 500)),
      ],
    );
  }

  /// Construit le message d'erreur
  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppConstants.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppConstants.errorColor),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideX(begin: 0.3)
        .fadeIn();
  }

  /// Construit la carte de résumé
  Widget _buildSummaryCard(ThemeData theme) {
    return Card(
      color: AppConstants.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé de votre compte',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppConstants.blackColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildSummaryRow('Type de compte', _selectedUserType.displayName),
            _buildSummaryRow('Pseudo', _pseudoController.text),
            _buildSummaryRow('Prénom', _prenomController.text),
            if (_phoneController.text.isNotEmpty)
              _buildSummaryRow('Téléphone', _phoneController.text),
            if (_selectedRegion != null)
              _buildSummaryRow('Région', _selectedRegion!),
            _buildSummaryRow('Langue', _getLanguageName(_selectedLanguage)),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.3)
        .fadeIn();
  }

  /// Construit une ligne du résumé
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppConstants.blackColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppConstants.blackColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la section des conditions d'utilisation
  Widget _buildTermsSection(ThemeData theme) {
    return Card(
      color: AppConstants.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          children: [
            CheckboxListTile(
              value: _acceptTerms,
              onChanged: (value) {
                // Conditions changées: $value
                setState(() => _acceptTerms = value!);
              },
              title: const Text(
                'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                style: TextStyle(color: AppConstants.blackColor),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppConstants.primaryColor,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            
            // Indicateur visuel de l'état des conditions
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              decoration: BoxDecoration(
                color: _acceptTerms ? AppConstants.successColor.withValues(alpha: 0.1) : AppConstants.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                border: Border.all(
                  color: _acceptTerms ? AppConstants.successColor : AppConstants.warningColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _acceptTerms ? Icons.check_circle : Icons.warning,
                    color: _acceptTerms ? AppConstants.successColor : AppConstants.warningColor,
                    size: 16,
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Text(
                    _acceptTerms ? 'Conditions acceptées' : 'Conditions non acceptées',
                    style: TextStyle(
                      color: _acceptTerms ? AppConstants.successColor : AppConstants.warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingSmall),
            
            // Boutons des conditions avec Wrap pour éviter l'overflow
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppConstants.paddingMedium,
              runSpacing: AppConstants.paddingSmall,
              children: [
                TextButton(
                  onPressed: () => _showTermsDialog(),
                  child: const Text(
                    'Lire les conditions',
                    style: TextStyle(color: AppConstants.blackColor),
                  ),
                ),
                TextButton(
                  onPressed: () => _showPrivacyDialog(),
                  child: const Text(
                    'Politique de confidentialité',
                    style: TextStyle(color: AppConstants.blackColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.3)
        .fadeIn(delay: AppConstants.animationDurationFast);
  }

  /// Construit le bouton suivant
  Widget _buildNextButton(VoidCallback onPressed, {bool enabled = true}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.arrow_forward, color: AppConstants.whiteColor),
        label: const Text('Suivant', style: TextStyle(color: AppConstants.whiteColor)),
      ),
    );
  }

  /// Construit le bouton d'inscription
  Widget _buildRegisterButton() {
    final bool canRegister = !_isLoading && _acceptTerms;
    
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: canRegister ? () {
                  // Bouton d'inscription cliqué
    // État: isLoading=$_isLoading, acceptTerms=$_acceptTerms
              _handleRegister();
            } : null,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.whiteColor),
                    ),
                  )
                : const Icon(Icons.person_add, color: AppConstants.whiteColor),
            label: Text(
              _isLoading ? 'Inscription...' : 'S\'inscrire',
              style: const TextStyle(color: AppConstants.whiteColor),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: canRegister ? AppConstants.primaryColor : Colors.grey,
              foregroundColor: AppConstants.whiteColor,
            ),
          ),
        ),
      ],
    );
  }



  /// Retourne l'icône pour un type d'utilisateur
  IconData _getUserTypeIcon(UserType type) {
    switch (type) {
      case UserType.victime:
        return Icons.shield;
      case UserType.aidant:
        return Icons.people_alt;
      case UserType.ong:
        return Icons.business;
      case UserType.admin:
        return Icons.admin_panel_settings;
    }
  }

  /// Retourne le nom de la langue
  String _getLanguageName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'ff':
        return 'Fulani';
      default:
        return code;
    }
  }

  /// Validation du prénom
  String? _validatePrenom(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le prénom est requis';
    }
    if (value.length < 2) {
      return 'Le prénom doit contenir au moins 2 caractères';
    }
    if (!RegExp(AppConstants.prenomPattern).hasMatch(value)) {
      return 'Prénom invalide (lettres et espaces uniquement)';
    }
    return null;
  }

  /// Validation du PIN
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

  /// Validation de la confirmation du PIN
  String? _validateConfirmPin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre PIN';
    }
    if (value != _pinController.text) {
      return 'Les codes PIN ne correspondent pas';
    }
    return null;
  }

  /// Validation du téléphone
  String? _validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!RegExp(AppConstants.phoneNumberPattern).hasMatch(value)) {
        return 'Format de numéro invalide';
      }
    }
    return null;
  }

  /// Validation du pseudo
  String? _validatePseudo(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le pseudo est requis';
    }
    if (value.length < 3) {
      return 'Le pseudo doit contenir au moins 3 caractères';
    }
    if (value.length > 20) {
      return 'Le pseudo ne peut pas dépasser 20 caractères';
    }
    // Vérifier qu'il n'y a pas d'espaces ni de caractères spéciaux
    if (value.contains(' ') || !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return 'Le pseudo ne doit contenir que des lettres et chiffres';
    }
    return null;
  }

  /// Vérifie la disponibilité du pseudo via Supabase
  Future<void> _checkPseudoAvailability() async {
    final pseudo = _pseudoController.text.trim();
    
    if (pseudo.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez saisir un pseudo';
      });
      return;
    }

    // Validation locale d'abord
    final validationError = _validatePseudo(pseudo);
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
        _pseudoValidated = false;
      });
      return;
    }

    setState(() {
      _isCheckingPseudo = true;
      _errorMessage = null;
    });

    try {
      // Utiliser l'AuthProvider au lieu du service direct
      final result = await context.read<AuthProvider>().checkPseudoAvailability(pseudo);

      if (result['status'] == 'success') {
        if (result['available'] == true) {
          setState(() {
            _pseudoValidated = true;
            _errorMessage = null;
          });
          
          // Afficher un message de succès
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${result['message']}'),
                backgroundColor: AppConstants.successColor,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Pseudo non disponible, afficher les suggestions
          final suggestions = List<String>.from(result['suggestions'] ?? []);
          _showPseudoSuggestions(suggestions);
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de la vérification: ${result['message']}';
          _pseudoValidated = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion: $e';
        _pseudoValidated = false;
      });
    } finally {
      setState(() {
        _isCheckingPseudo = false;
      });
    }
  }

  /// Affiche les suggestions de pseudo
  void _showPseudoSuggestions(List<String> suggestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Pseudo déjà utilisé',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ce pseudo est déjà utilisé. Voici quelques suggestions :',
              style: TextStyle(color: AppConstants.blackColor),
            ),
            const SizedBox(height: 16),
            ...suggestions.map((suggestion) => ListTile(
              title: Text(suggestion),
              trailing: TextButton(
                onPressed: () {
                  _pseudoController.text = suggestion;
                  Navigator.of(context).pop();
                  _checkPseudoAvailability(); // Vérifier la suggestion
                },
                child: const Text('Utiliser'),
              ),
            )),
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

  /// Gère l'inscription
  Future<void> _handleRegister() async {
    // === DÉBUT DE L'INSCRIPTION ===
    // État du bouton: isLoading=$_isLoading, acceptTerms=$_acceptTerms
    
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      
    });

    try {
          // Début de l'inscription...
    // Données saisies:
    //   - Prénom: "${_prenomController.text.trim()}"
    //   - PIN: "${_pinController.text.trim()}"
    //   - Confirmation PIN: "${_confirmPinController.text.trim()}"
    //   - Téléphone: "${_phoneController.text.trim()}"
    //   - Région: "$_selectedRegion"
    //   - Langue: "$_selectedLanguage"
    //   - Type utilisateur: ${_selectedUserType.displayName}
      
      // Test de connexion Supabase
      
      // Test de connexion Supabase...
      try {
        await SupabaseService.ensureInitialized();
        final supabase = SupabaseService.instance;
        // Instance Supabase récupérée
        
        // Test simple de connexion (via le service pour garantir l'init)
        final response = await supabase.select(
          'utilisateurs',
          columns: 'count',
          limit: 1,
        );
        // Connexion Supabase réussie: $response
      } catch (e) {
        // Erreur de connexion Supabase: $e
        throw Exception('Impossible de se connecter à la base de données: $e');
      }
      
      
      
      // Service d'authentification récupéré
      
      // Vérifier si le pseudo est disponible (déjà fait dans l'étape précédente)
      if (!_pseudoValidated) {
        throw Exception('Le pseudo doit être validé avant de continuer');
      }
      // Pseudo validé: ${_pseudoController.text.trim()}

      
             final registrationData = RegistrationData(
                   prenom: _prenomController.text.trim(),
                   pseudo: _pseudoController.text.trim(), // Utiliser le pseudo saisi par l'utilisateur
         pin: _pinController.text.trim(),
         numTel: _phoneController.text.trim().isEmpty ? '' : _phoneController.text.trim(),
         langue: _selectedLanguage,
         region: _selectedRegion,
         typeUtilisateur: _selectedUserType,
       );
      
      // Données d'inscription préparées: ${registrationData.toJson()}

      
      // Appel du service d'inscription...
      try {
        // Utiliser l'AuthProvider au lieu du service direct
        final success = await context.read<AuthProvider>().register(
          prenom: _prenomController.text.trim(),
          pseudo: _pseudoController.text.trim(), // Passer le pseudo saisi
          pin: _pinController.text.trim(),
          numTel: _phoneController.text.trim().isEmpty ? '' : _phoneController.text.trim(),
          userType: _selectedUserType.value,
          langue: _selectedLanguage,
          region: _selectedRegion,
        );
        
        if (success) {
          // Récupérer l'utilisateur depuis l'AuthProvider
          final user = context.read<AuthProvider>().currentUser;
          if (user != null) {
                // Inscription réussie: ${user.prenom}
    // Type utilisateur: ${user.typeUtilisateur.value}
    // Route de redirection: ${_getRouteForUserType(user.typeUtilisateur)}
             
            if (mounted) {
              // Afficher un message de succès
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bienvenue ${user.prenom} !'),
                  backgroundColor: AppConstants.successColor,
                  duration: const Duration(seconds: 2),
                ),
              );

              // Redirection vers l'écran approprié...
              // Attendre un peu pour que le SnackBar soit visible
              await Future.delayed(const Duration(seconds: 2));
              
              // Rediriger vers l'écran approprié
              _redirectToUserScreen(user.typeUtilisateur);
            }
          } else {
            throw Exception('Utilisateur non récupéré après inscription');
          }
        } else {
          throw Exception('Échec de l\'inscription');
        }
      } catch (e) {
        // Erreur lors de l'inscription via AuthProvider: $e
        throw Exception('Erreur lors de l\'inscription: $e');
      }
      
    } catch (e, stackTrace) {
          // === ERREUR LORS DE L'INSCRIPTION ===
    // Erreur: $e
    // Stack trace: $stackTrace
      
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;

        });

        HapticFeedback.mediumImpact();
        
        // Afficher l'erreur dans un SnackBar pour être sûr qu'elle soit visible
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${_errorMessage}'),
            backgroundColor: AppConstants.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      // === FIN DE L'INSCRIPTION ===
      if (mounted) {
        setState(() {
          _isLoading = false;

        });
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

  /// Obtient la route pour un type d'utilisateur (pour debug)
  String _getRouteForUserType(UserType userType) {
    switch (userType) {
      case UserType.victime:
        return AppConstants.routeVictimDashboard;
      case UserType.aidant:
        return AppConstants.routeHelperHome;
      case UserType.ong:
        return AppConstants.routeONGHome;
      case UserType.admin:
        return AppConstants.routeAdminHome;
    }
  }

  /// Affiche les conditions d'utilisation
  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Conditions d\'utilisation',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'En utilisant Guinèmali, vous vous engagez à :\n\n'
            '• Utiliser l\'application de manière responsable\n'
            '• Ne pas transmettre de fausses alertes\n'
            '• Respecter la communauté d\'utilisateurs\n'
            '• Protéger vos identifiants de connexion\n\n'
            'L\'utilisation abusive peut entraîner la suspension du compte.',
            style: TextStyle(color: AppConstants.blackColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Fermer',
              style: TextStyle(color: AppConstants.blackColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche la politique de confidentialité
  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Politique de confidentialité',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Guinèmali protège vos données personnelles :\n\n'
            '• Vos données sont chiffrées\n'
            '• Nous ne partageons pas vos informations\n'
            '• Les alertes sont traitées de manière confidentielle\n'
            '• Vous pouvez supprimer votre compte à tout moment\n\n'
            'Vos données ne sont utilisées que pour assurer votre sécurité.',
            style: TextStyle(color: AppConstants.blackColor),
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

