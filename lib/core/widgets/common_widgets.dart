import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../services/config_service.dart';

/// Widgets réutilisables pour éliminer les redondances d'UI
/// Basé sur 30 ans d'expérience en développement mobile
class CommonWidgets {
  /// Bouton principal standardisé
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double height = 50,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.whiteColor),
                ),
              )
            : icon != null
                ? Icon(icon, color: AppConstants.whiteColor)
                : const SizedBox.shrink(),
        label: Text(
          isLoading ? 'Chargement...' : text,
          style: const TextStyle(
            color: AppConstants.whiteColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? AppConstants.primaryColor : Colors.grey,
          foregroundColor: AppConstants.whiteColor,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          elevation: 2,
        ),
      ),
    ).animate().scale(
      duration: ConfigService.getAnimationConfig()['fast']!,
      curve: Curves.easeInOut,
    );
  }

  /// Bouton secondaire standardisé
  static Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double height = 50,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton.icon(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                ),
              )
            : icon != null
                ? Icon(icon, color: AppConstants.primaryColor)
                : const SizedBox.shrink(),
        label: Text(
          isLoading ? 'Chargement...' : text,
          style: const TextStyle(
            color: AppConstants.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          side: BorderSide(
            color: isEnabled ? AppConstants.primaryColor : Colors.grey,
            width: 1.5,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
        ),
      ),
    ).animate().scale(
      duration: ConfigService.getAnimationConfig()['fast']!,
      curve: Curves.easeInOut,
    );
  }

  /// Champ de texte standardisé
  static Widget textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helperText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int? maxLines,
    int? maxLength,
    bool autofocus = false,
    FocusNode? focusNode,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    Color? borderColor,
    Color? labelColor,
    Color? textColor,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      inputFormatters: inputFormatters,
      maxLines: maxLines ?? 1,
      maxLength: maxLength,
      autofocus: autofocus,
      focusNode: focusNode,
      onTap: onTap,
      onChanged: onChanged,
      style: TextStyle(
        color: textColor ?? (enabled ? AppConstants.blackColor : Colors.grey),
        fontSize: ConfigService.getFontSizeConfig()['md'],
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: enabled ? (borderColor ?? AppConstants.primaryColor) : Colors.grey,
              )
            : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(
                  suffixIcon,
                  color: enabled ? (borderColor ?? AppConstants.primaryColor) : Colors.grey,
                ),
                onPressed: enabled ? onSuffixIconPressed : null,
              )
            : null,
        labelStyle: TextStyle(
          color: labelColor ?? (enabled ? AppConstants.blackColor : Colors.grey),
        ),
        hintStyle: TextStyle(
          color: enabled ? AppConstants.blackColor.withValues(alpha: 0.6) : Colors.grey,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          borderSide: BorderSide(
            color: borderColor ?? AppConstants.primaryColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          borderSide: BorderSide(
            color: borderColor ?? AppConstants.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          borderSide: BorderSide(
            color: AppConstants.errorColor,
            width: 1,
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
        fillColor: enabled ? AppConstants.whiteColor : Colors.grey[100],
      ),
    ).animate().slideX(
      begin: 0.1,
      duration: ConfigService.getAnimationConfig()['fast']!,
      curve: Curves.easeOut,
    );
  }

  /// Carte standardisée
  static Widget card({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
    double? elevation,
    BorderRadius? borderRadius,
    Border? border,
    VoidCallback? onTap,
    bool animate = true,
  }) {
    Widget cardWidget = Card(
      color: color ?? AppConstants.whiteColor,
      elevation: elevation ?? 2,
      margin: margin ?? const EdgeInsets.all(AppConstants.paddingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.borderRadiusMedium),
        side: border?.top ?? BorderSide.none,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppConstants.paddingMedium),
        child: child,
      ),
    );

    if (onTap != null) {
      cardWidget = InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: cardWidget,
      );
    }

    if (animate) {
      cardWidget = cardWidget.animate().fadeIn(
        duration: ConfigService.getAnimationConfig()['medium']!,
        curve: Curves.easeOut,
      ).slideY(
        begin: 0.1,
        duration: ConfigService.getAnimationConfig()['medium']!,
        curve: Curves.easeOut,
      );
    }

    return cardWidget;
  }

  /// En-tête de section standardisé
  static Widget sectionHeader({
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? trailing,
    bool animate = true,
  }) {
    Widget header = Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: AppConstants.primaryColor,
            size: ConfigService.getIconSizeConfig()['md'],
          ),
          const SizedBox(width: AppConstants.paddingSmall),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: ConfigService.getFontSizeConfig()['lg'],
                  fontWeight: FontWeight.bold,
                  color: AppConstants.blackColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: ConfigService.getFontSizeConfig()['sm'],
                    color: AppConstants.blackColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );

    if (animate) {
      header = header.animate().fadeIn(
        duration: ConfigService.getAnimationConfig()['fast']!,
        curve: Curves.easeOut,
      ).slideX(
        begin: 0.1,
        duration: ConfigService.getAnimationConfig()['fast']!,
        curve: Curves.easeOut,
      );
    }

    return header;
  }

  /// Indicateur de statut standardisé
  static Widget statusIndicator({
    required String status,
    required Color color,
    IconData? icon,
    bool animate = true,
  }) {
    Widget indicator = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color,
              size: ConfigService.getIconSizeConfig()['sm'],
            ),
            const SizedBox(width: AppConstants.paddingSmall),
          ],
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: ConfigService.getFontSizeConfig()['sm'],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (animate) {
      indicator = indicator.animate().scale(
        duration: ConfigService.getAnimationConfig()['fast']!,
        curve: Curves.elasticOut,
      );
    }

    return indicator;
  }

  /// Bouton d'action flottant standardisé
  static Widget floatingActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool animate = true,
  }) {
    Widget fab = FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? AppConstants.primaryColor,
      foregroundColor: foregroundColor ?? AppConstants.whiteColor,
      elevation: elevation ?? 6,
      child: Icon(icon),
    );

    if (animate) {
      fab = fab.animate().scale(
        duration: ConfigService.getAnimationConfig()['medium']!,
        curve: Curves.elasticOut,
      ).fadeIn(
        duration: ConfigService.getAnimationConfig()['medium']!,
        curve: Curves.easeOut,
      );
    }

    return fab;
  }

  /// Liste vide standardisée
  static Widget emptyList({
    required String message,
    IconData? icon,
    String? actionText,
    VoidCallback? onActionPressed,
    bool animate = true,
  }) {
    Widget emptyWidget = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: ConfigService.getIconSizeConfig()['xl'],
              color: AppConstants.blackColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
          ],
          Text(
            message,
            style: TextStyle(
              fontSize: ConfigService.getFontSizeConfig()['lg'],
              color: AppConstants.blackColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onActionPressed != null) ...[
            const SizedBox(height: AppConstants.paddingLarge),
            primaryButton(
              text: actionText,
              onPressed: onActionPressed,
            ),
          ],
        ],
      ),
    );

    if (animate) {
      emptyWidget = emptyWidget.animate().fadeIn(
        duration: ConfigService.getAnimationConfig()['medium']!,
        curve: Curves.easeOut,
      ).slideY(
        begin: 0.2,
        duration: ConfigService.getAnimationConfig()['medium']!,
        curve: Curves.easeOut,
      );
    }

    return emptyWidget;
  }

  /// Indicateur de chargement standardisé
  static Widget loadingIndicator({
    String? message,
    Color? color,
    double size = 40,
    bool animate = true,
  }) {
    Widget loading = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppConstants.primaryColor,
            ),
            strokeWidth: 3,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            message,
            style: TextStyle(
              fontSize: ConfigService.getFontSizeConfig()['md'],
              color: AppConstants.blackColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (animate) {
      loading = loading.animate().fadeIn(
        duration: ConfigService.getAnimationConfig()['fast']!,
        curve: Curves.easeOut,
      );
    }

    return loading;
  }

  /// Diviseur standardisé
  static Widget divider({
    double? height,
    double? thickness,
    Color? color,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
      child: Divider(
        height: height ?? 1,
        thickness: thickness ?? 1,
        color: color ?? AppConstants.blackColor.withValues(alpha: 0.1),
      ),
    );
  }

  /// Espacement standardisé
  static Widget spacing({
    double? width,
    double? height,
  }) {
    return SizedBox(
      width: width,
      height: height ?? AppConstants.paddingMedium,
    );
  }

  /// Badge standardisé
  static Widget badge({
    required String text,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    bool animate = true,
  }) {
    Widget badgeWidget = Container(
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppConstants.primaryColor,
        borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? AppConstants.whiteColor,
          fontSize: fontSize ?? ConfigService.getFontSizeConfig()['xs'],
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (animate) {
      badgeWidget = badgeWidget.animate().scale(
        duration: ConfigService.getAnimationConfig()['fast']!,
        curve: Curves.elasticOut,
      );
    }

    return badgeWidget;
  }
}
