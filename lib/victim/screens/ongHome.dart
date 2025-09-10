import 'package:flutter/material.dart';

class OngHome extends StatelessWidget {
  const OngHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace ONG'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.business_center,
                size: 80,
                color: Color(0xFF2196F3),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bienvenue dans l’espace ONG',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Accédez aux outils et ressources dédiés aux organisations partenaires pour soutenir les victimes.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Retour à la page précédente
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
