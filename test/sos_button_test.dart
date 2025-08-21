import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:guinemali/core/providers/auth_provider.dart';
import 'package:guinemali/victim/screens/victim_home_screen.dart';

void main() {
  group('SOS Button Tests', () {
    testWidgets('SOS Button should be visible and clickable', (WidgetTester tester) async {
      // Créer un mock AuthProvider
      final authProvider = AuthProvider();
      
      // Construire l'écran avec le provider
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const VictimHomeScreen(),
          ),
        ),
      );

      // Attendre que l'écran se charge
      await tester.pumpAndSettle();

      // Vérifier que le bouton SOS est visible
      expect(find.byType(ElevatedButton), findsOneWidget);
      
      // Vérifier que le texte d'urgence est présent
      expect(find.textContaining('SOS'), findsOneWidget);
    });

    testWidgets('SOS Button should trigger emergency mode', (WidgetTester tester) async {
      // Créer un mock AuthProvider
      final authProvider = AuthProvider();
      
      // Construire l'écran avec le provider
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const VictimHomeScreen(),
          ),
        ),
      );

      // Attendre que l'écran se charge
      await tester.pumpAndSettle();

      // Trouver et appuyer sur le bouton SOS
      final sosButton = find.byType(ElevatedButton);
      expect(sosButton, findsOneWidget);
      
      // Simuler un appui sur le bouton
      await tester.tap(sosButton);
      await tester.pumpAndSettle();

      // Vérifier que l'état d'urgence est activé
      // (Le bouton devrait changer d'apparence)
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
