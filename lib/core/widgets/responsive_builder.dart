import 'package:flutter/material.dart';
import '../constants/responsive_breakpoints.dart';

/// Widget pour gérer le responsive design
/// Adapte l'interface selon la taille de l'écran
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? watch;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.watch,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // Watch (très petit écran)
        if (width < ResponsiveBreakpoints.mobile && watch != null) {
          return watch!;
        }
        
        // Desktop
        if (width >= ResponsiveBreakpoints.desktop && desktop != null) {
          return desktop!;
        }
        
        // Tablet
        if (width >= ResponsiveBreakpoints.tablet && tablet != null) {
          return tablet!;
        }
        
        // Mobile (par défaut)
        return mobile;
      },
    );
  }
}

/// Extension pour accéder facilement aux breakpoints
extension ResponsiveExtension on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < ResponsiveBreakpoints.tablet;
  bool get isTablet => MediaQuery.of(this).size.width >= ResponsiveBreakpoints.tablet && 
                       MediaQuery.of(this).size.width < ResponsiveBreakpoints.desktop;
  bool get isDesktop => MediaQuery.of(this).size.width >= ResponsiveBreakpoints.desktop;
  bool get isWatch => MediaQuery.of(this).size.width < ResponsiveBreakpoints.mobile;
  
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Retourne la taille de police adaptée à l'écran
  double getResponsiveFontSize({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
  
  /// Retourne le padding adapté à l'écran
  EdgeInsets getResponsivePadding({
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}
