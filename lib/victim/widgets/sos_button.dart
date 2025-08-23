import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';

/// Bouton SOS principal avec animations et design époustouflant
class SOSButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final AnimationController pulseController;

  const SOSButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculer une taille responsive: ~70% de la largeur, bornée entre min et un maximum généreux
        final double maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : AppConstants.sosButtonMaxSize;
        final double computedSize = (maxWidth * 0.85)
            .clamp(240.0, 420.0);

        return GestureDetector(
          onTap: isLoading ? null : onPressed,
          child: AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              return Container(
                width: computedSize,
                height: computedSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFF4444),
                  Color(0xFFFF6666),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                // Ombre principale rouge
                BoxShadow(
                  color: const Color(0xFFFF0000).withValues(alpha: 0.4),
                  blurRadius: 25 + (15 * pulseController.value),
                  spreadRadius: 8 + (5 * pulseController.value),
                  offset: const Offset(0, 12),
                ),
                // Ombre secondaire violette
                BoxShadow(
                  color: const Color(0xFF945acb).withValues(alpha: 0.3),
                  blurRadius: 40 + (20 * pulseController.value),
                  spreadRadius: 12 + (8 * pulseController.value),
                  offset: const Offset(0, 20),
                ),
                // Ombre violette claire
                BoxShadow(
                  color: const Color(0xFFee82ee).withValues(alpha: 0.2),
                  blurRadius: 60 + (30 * pulseController.value),
                  spreadRadius: 20 + (15 * pulseController.value),
                  offset: const Offset(0, 30),
                ),
              ],
            ),
                child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF0000),
                    Color(0xFFDD0000),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
                child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 4,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icône d'urgence avec animation
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.emergency,
                            size: 45,
                            color: Colors.white,
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(
                              duration: const Duration(milliseconds: 2000),
                              color: Colors.white.withValues(alpha: 0.6),
                            )
                            .then()
                            .scale(
                              duration: const Duration(milliseconds: 1000),
                              begin: const Offset(1.0, 1.0),
                              end: const Offset(1.1, 1.1),
                            )
                            .then()
                            .scale(
                              duration: const Duration(milliseconds: 1000),
                              begin: const Offset(1.1, 1.1),
                              end: const Offset(1.0, 1.0),
                            ),
                        
                        const SizedBox(height: 12),
                        
                        // Texte SOS stylisé
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black38,
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(
                              duration: const Duration(seconds: 3),
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                      ],
                    ),
                ),
              );
            },
          ),
        )
        .animate()
        .scale(
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
        )
        .then()
        .shimmer(
          duration: const Duration(seconds: 3),
          color: const Color(0xFFee82ee).withValues(alpha: 0.2),
        );
      },
    );
  }
}
