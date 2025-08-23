import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget pour la navigation par gestes
class GestureNavigation extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final double swipeThreshold;

  const GestureNavigation({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onDoubleTap,
    this.onLongPress,
    this.swipeThreshold = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (details) {
        final dx = details.velocity.pixelsPerSecond.dx;
        final dy = details.velocity.pixelsPerSecond.dy;
        
        if (dx.abs() > dy.abs()) {
          // Mouvement horizontal
          if (dx > swipeThreshold && onSwipeRight != null) {
            HapticFeedback.lightImpact();
            onSwipeRight!();
          } else if (dx < -swipeThreshold && onSwipeLeft != null) {
            HapticFeedback.lightImpact();
            onSwipeLeft!();
          }
        } else {
          // Mouvement vertical
          if (dy > swipeThreshold && onSwipeDown != null) {
            HapticFeedback.lightImpact();
            onSwipeDown!();
          } else if (dy < -swipeThreshold && onSwipeUp != null) {
            HapticFeedback.lightImpact();
            onSwipeUp!();
          }
        }
      },
      onDoubleTap: onDoubleTap != null ? () {
        HapticFeedback.mediumImpact();
        onDoubleTap!();
      } : null,
      onLongPress: onLongPress != null ? () {
        HapticFeedback.heavyImpact();
        onLongPress!();
      } : null,
      child: child,
    );
  }
}

/// Widget pour la navigation par swipe horizontal
class HorizontalSwipeNavigation extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final double swipeThreshold;

  const HorizontalSwipeNavigation({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.swipeThreshold = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (details) {
        final dx = details.velocity.pixelsPerSecond.dx;
        
        if (dx > swipeThreshold && onSwipeRight != null) {
          HapticFeedback.lightImpact();
          onSwipeRight!();
        } else if (dx < -swipeThreshold && onSwipeLeft != null) {
          HapticFeedback.lightImpact();
          onSwipeLeft!();
        }
      },
      child: child,
    );
  }
}

/// Widget pour la navigation par swipe vertical
class VerticalSwipeNavigation extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final double swipeThreshold;

  const VerticalSwipeNavigation({
    super.key,
    required this.child,
    this.onSwipeUp,
    this.onSwipeDown,
    this.swipeThreshold = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (details) {
        final dy = details.velocity.pixelsPerSecond.dy;
        
        if (dy > swipeThreshold && onSwipeDown != null) {
          HapticFeedback.lightImpact();
          onSwipeDown!();
        } else if (dy < -swipeThreshold && onSwipeUp != null) {
          HapticFeedback.lightImpact();
          onSwipeUp!();
        }
      },
      child: child,
    );
  }
}

/// Widget pour la navigation par tap avec feedback haptique
class HapticTapWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HapticFeedbackType hapticType;
  final bool enabled;

  const HapticTapWidget({
    super.key,
    required this.child,
    this.onTap,
    this.hapticType = HapticFeedbackType.lightImpact,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || onTap == null) {
      return child;
    }

    return GestureDetector(
      onTap: () {
        _triggerHaptic();
        onTap!();
      },
      child: child,
    );
  }

  void _triggerHaptic() {
    switch (hapticType) {
      case HapticFeedbackType.lightImpact:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.mediumImpact:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavyImpact:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selectionClick:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }
}

/// Types de feedback haptique
enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  vibrate,
}

/// Widget pour la navigation par pinch
class PinchNavigation extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPinchIn;
  final VoidCallback? onPinchOut;
  final double pinchThreshold;

  const PinchNavigation({
    super.key,
    required this.child,
    this.onPinchIn,
    this.onPinchOut,
    this.pinchThreshold = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleEnd: (details) {
        // Utiliser la vélocité du scale pour détecter le pinch
        final velocity = details.velocity.pixelsPerSecond.dx.abs() + 
                        details.velocity.pixelsPerSecond.dy.abs();
        
        if (velocity > 1000) { // Seuil de vélocité pour détecter le pinch
          if (onPinchIn != null) {
            HapticFeedback.lightImpact();
            onPinchIn!();
          }
        } else if (onPinchOut != null) {
          HapticFeedback.lightImpact();
          onPinchOut!();
        }
      },
      child: child,
    );
  }
}
