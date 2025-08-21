import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guinemali/victim/widgets/sos_button.dart';
import 'package:guinemali/core/constants/app_constants.dart';

void main() {
  group('SOS Button Simple Tests', () {
    testWidgets('SOS Button should render without overflow', (WidgetTester tester) async {
      // Créer un mock AnimationController
      final pulseController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: tester,
      );
      
      // Construire juste le bouton SOS
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SOSButton(
                onPressed: () {},
                isLoading: false,
                pulseController: pulseController,
              ),
            ),
          ),
        ),
      );

      // Attendre que l'écran se charge
      await tester.pump();

      // Vérifier que le bouton SOS est visible
      expect(find.byType(ElevatedButton), findsOneWidget);
      
      // Vérifier que le texte SOS est présent
      expect(find.text('SOS'), findsOneWidget);
      
      // Vérifier qu'il n'y a pas d'erreurs de layout
      expect(tester.takeException(), isNull);
    });

    testWidgets('SOS Button should handle tap', (WidgetTester tester) async {
      bool buttonTapped = false;
      
      // Créer un mock AnimationController
      final pulseController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: tester,
      );
      
      // Construire juste le bouton SOS
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SOSButton(
                onPressed: () {
                  buttonTapped = true;
                },
                isLoading: false,
                pulseController: pulseController,
              ),
            ),
          ),
        ),
      );

      // Attendre que l'écran se charge
      await tester.pump();

      // Trouver et appuyer sur le bouton SOS
      final sosButton = find.byType(ElevatedButton);
      expect(sosButton, findsOneWidget);
      
      // Simuler un appui sur le bouton
      await tester.tap(sosButton);
      await tester.pump();

      // Vérifier que le callback a été appelé
      expect(buttonTapped, isTrue);
    });
  });
}
