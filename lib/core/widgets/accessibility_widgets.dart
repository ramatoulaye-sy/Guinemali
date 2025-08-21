import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget pour améliorer l'accessibilité des boutons
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? label;
  final String? hint;
  final bool isSemanticButton;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.label,
    this.hint,
    this.isSemanticButton = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = onPressed != null
        ? InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: child,
          )
        : child;

    if (isSemanticButton) {
      button = Semantics(
        button: true,
        label: label,
        hint: hint,
        child: button,
      );
    }

    return button;
  }
}

/// Widget pour les cartes accessibles
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;

  const AccessibleCard({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.onTap,
    this.padding,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: decoration ??
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
      child: child,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return Semantics(
      label: label,
      hint: hint,
      child: card,
    );
  }
}

/// Widget pour les listes accessibles
class AccessibleListView extends StatelessWidget {
  final List<Widget> children;
  final String? label;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  const AccessibleListView({
    super.key,
    required this.children,
    this.label,
    this.controller,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: ListView(
        controller: controller,
        padding: padding,
        children: children,
      ),
    );
  }
}

/// Widget pour les champs de texte accessibles
class AccessibleTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const AccessibleTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          errorText: errorText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onTap: onTap,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}

/// Widget pour les images accessibles
class AccessibleImage extends StatelessWidget {
  final String imagePath;
  final String altText;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;

  const AccessibleImage({
    super.key,
    required this.imagePath,
    required this.altText,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: borderRadius,
          ),
          child: Icon(
            Icons.image_not_supported,
            color: Colors.grey[600],
            size: 32,
          ),
        );
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return Semantics(
      label: altText,
      image: true,
      child: image,
    );
  }
}

/// Widget pour les icônes accessibles
class AccessibleIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? size;
  final Color? color;
  final VoidCallback? onTap;

  const AccessibleIcon({
    super.key,
    required this.icon,
    required this.label,
    this.size,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(
      icon,
      size: size,
      color: color,
    );

    if (onTap != null) {
      iconWidget = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: iconWidget,
        ),
      );
    }

    return Semantics(
      label: label,
      button: onTap != null,
      child: iconWidget,
    );
  }
}

/// Mixin pour ajouter des fonctionnalités d'accessibilité
mixin AccessibilityMixin<T extends StatefulWidget> on State<T> {
  /// Définit le focus sur un widget
  void setFocus(FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }

  /// Vérifie si l'accessibilité est activée
  bool get isAccessibilityEnabled {
    return MediaQuery.of(context).accessibleNavigation;
  }
}
