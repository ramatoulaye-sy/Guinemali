import 'package:flutter/material.dart';

/// Breakpoints pour le responsive design
class ResponsiveBreakpoints {
  // Mobile (téléphones)
  static const double mobile = 600;
  
  // Tablet (tablettes)
  static const double tablet = 900;
  
  // Desktop (ordinateurs)
  static const double desktop = 1200;
  
  // Large Desktop (grands écrans)
  static const double largeDesktop = 1600;
}

/// Classes de padding responsives
class ResponsivePadding {
  // Mobile
  static const EdgeInsets small = EdgeInsets.all(8.0);
  static const EdgeInsets medium = EdgeInsets.all(16.0);
  static const EdgeInsets large = EdgeInsets.all(24.0);
  static const EdgeInsets extraLarge = EdgeInsets.all(32.0);
  
  // Tablet
  static const EdgeInsets tabletSmall = EdgeInsets.all(12.0);
  static const EdgeInsets tabletMedium = EdgeInsets.all(20.0);
  static const EdgeInsets tabletLarge = EdgeInsets.all(28.0);
  static const EdgeInsets tabletExtraLarge = EdgeInsets.all(36.0);
  
  // Desktop
  static const EdgeInsets desktopSmall = EdgeInsets.all(16.0);
  static const EdgeInsets desktopMedium = EdgeInsets.all(24.0);
  static const EdgeInsets desktopLarge = EdgeInsets.all(32.0);
  static const EdgeInsets desktopExtraLarge = EdgeInsets.all(40.0);
}
