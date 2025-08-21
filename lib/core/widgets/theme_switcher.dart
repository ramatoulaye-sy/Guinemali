import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_constants.dart';

/// Widget pour changer de thème
class ThemeSwitcher extends StatelessWidget {
  final bool showLabel;
  final double size;

  const ThemeSwitcher({
    super.key,
    this.showLabel = true,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                themeProvider.toggleTheme();
              },
              icon: Icon(
                themeProvider.isDarkMode == true
                    ? Icons.light_mode 
                    : Icons.dark_mode,
                size: size,
                color: themeProvider.isDarkMode == true
                    ? Colors.amber 
                    : Colors.indigo,
              ),
              tooltip: themeProvider.isDarkMode == true
                  ? 'Passer au mode clair' 
                  : 'Passer au mode sombre',
            ),
            if (showLabel) ...[
              const SizedBox(height: 4),
                                      Text(
                          themeProvider.isDarkMode == true ? 'Clair' : 'Sombre',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Widget pour choisir un thème personnalisé
class CustomThemeSelector extends StatelessWidget {
  final List<CustomTheme> themes;
  final CustomTheme? selectedTheme;
  final ValueChanged<CustomTheme>? onThemeChanged;

  const CustomThemeSelector({
    super.key,
    required this.themes,
    this.selectedTheme,
    this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thème personnalisé',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: themes.map((theme) {
            final isSelected = selectedTheme?.id == theme.id;
            return GestureDetector(
              onTap: () => onThemeChanged?.call(theme),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? AppConstants.primaryColor 
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Classe pour représenter un thème personnalisé
class CustomTheme {
  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;

  const CustomTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
  });

  /// Thèmes prédéfinis
  static const List<CustomTheme> predefinedThemes = [
    CustomTheme(
      id: 'default',
      name: 'Par défaut',
      primaryColor: Color(0xFF945acb),
      secondaryColor: Color(0xFFee82ee),
      accentColor: Color(0xFFFF6B6B),
      backgroundColor: Color(0xFFF8F9FA),
      surfaceColor: Colors.white,
      textColor: Color(0xFF2C3E50),
    ),
    CustomTheme(
      id: 'ocean',
      name: 'Océan',
      primaryColor: Color(0xFF1E3A8A),
      secondaryColor: Color(0xFF3B82F6),
      accentColor: Color(0xFF06B6D4),
      backgroundColor: Color(0xFFF0F9FF),
      surfaceColor: Colors.white,
      textColor: Color(0xFF1E293B),
    ),
    CustomTheme(
      id: 'forest',
      name: 'Forêt',
      primaryColor: Color(0xFF059669),
      secondaryColor: Color(0xFF10B981),
      accentColor: Color(0xFF84CC16),
      backgroundColor: Color(0xFFF0FDF4),
      surfaceColor: Colors.white,
      textColor: Color(0xFF064E3B),
    ),
    CustomTheme(
      id: 'sunset',
      name: 'Coucher de soleil',
      primaryColor: Color(0xFFDC2626),
      secondaryColor: Color(0xFFF59E0B),
      accentColor: Color(0xFFEC4899),
      backgroundColor: Color(0xFFFFF7ED),
      surfaceColor: Colors.white,
      textColor: Color(0xFF7C2D12),
    ),
    CustomTheme(
      id: 'midnight',
      name: 'Minuit',
      primaryColor: Color(0xFF1F2937),
      secondaryColor: Color(0xFF374151),
      accentColor: Color(0xFF8B5CF6),
      backgroundColor: Color(0xFF111827),
      surfaceColor: Color(0xFF1F2937),
      textColor: Color(0xFFF9FAFB),
    ),
  ];
}

/// Widget pour prévisualiser un thème
class ThemePreview extends StatelessWidget {
  final CustomTheme theme;
  final VoidCallback? onTap;

  const ThemePreview({
    super.key,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              theme.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildColorPreview('Primaire', theme.primaryColor),
                const SizedBox(width: 8),
                _buildColorPreview('Secondaire', theme.secondaryColor),
                const SizedBox(width: 8),
                _buildColorPreview('Accent', theme.accentColor),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Bouton d\'exemple',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPreview(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
