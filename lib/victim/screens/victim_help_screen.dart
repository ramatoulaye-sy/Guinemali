import 'package:flutter/material.dart';
import 'package:guinemali/core/constants/app_constants.dart';

class VictimHelpScreen extends StatefulWidget {
  const VictimHelpScreen({super.key});

  @override
  State<VictimHelpScreen> createState() => _VictimHelpScreenState();
}

class _VictimHelpScreenState extends State<VictimHelpScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _helpSections = [
    {
      'title': 'Comment Utiliser l\'App',
      'icon': Icons.help_outline,
      'content': [
        {
          'title': 'Déclencher une Alerte SOS',
          'description': 'Appuyez sur le bouton SOS rouge sur l\'écran d\'accueil pour déclencher une alerte d\'urgence immédiatement.',
          'steps': [
            'Localisez le bouton SOS rouge sur l\'écran d\'accueil',
            'Appuyez fermement sur le bouton',
            'Confirmez l\'alerte dans la popup qui apparaît',
            'L\'application enverra automatiquement votre position et contactera vos contacts d\'urgence'
          ]
        },
        {
          'title': 'Gérer vos Contacts d\'Urgence',
          'description': 'Ajoutez jusqu\'à 3 contacts de confiance qui seront automatiquement contactés en cas d\'urgence.',
          'steps': [
            'Allez dans "Mes Contacts" depuis l\'écran d\'accueil',
            'Appuyez sur "Ajouter un Contact"',
            'Remplissez le nom et le numéro de téléphone',
            'Sauvegardez le contact'
          ]
        },
        {
          'title': 'Enregistrer des Preuves',
          'description': 'Capturez des photos, vidéos, enregistrements audio et notes pour documenter votre situation.',
          'steps': [
            'Accédez à "Enregistrement des Preuves" depuis l\'écran d\'accueil',
            'Choisissez le type de preuve (photo, vidéo, audio, note)',
            'Suivez les instructions à l\'écran',
            'Vos preuves seront automatiquement sauvegardées et synchronisées'
          ]
        }
      ]
    },
    {
      'title': 'Fonctionnalités de Sécurité',
      'icon': Icons.security,
      'content': [
        {
          'title': 'Suivi GPS en Arrière-plan',
          'description': 'L\'application suit automatiquement votre position pendant une alerte active pour assurer votre sécurité.',
          'steps': [
            'Le suivi GPS démarre automatiquement lors d\'une alerte',
            'Votre position est enregistrée toutes les 30 secondes',
            'Les données sont sauvegardées localement et synchronisées',
            'Le suivi s\'arrête automatiquement à la résolution de l\'alerte'
          ]
        },
        {
          'title': 'Enregistrement Audio Continu',
          'description': 'L\'application enregistre automatiquement l\'audio ambiant pendant une alerte pour capturer des preuves importantes.',
          'steps': [
            'L\'enregistrement démarre automatiquement avec l\'alerte',
            'L\'audio est capturé même si l\'écran est éteint',
            'Les fichiers sont sauvegardés localement',
            'La synchronisation vers le serveur se fait automatiquement'
          ]
        },
        {
          'title': 'Synchronisation Hors-ligne',
          'description': 'L\'application fonctionne même sans connexion internet et synchronise les données dès que la connexion est rétablie.',
          'steps': [
            'Toutes les données sont sauvegardées localement',
            'La synchronisation se fait automatiquement en arrière-plan',
            'Les tentatives échouées sont retentées avec un délai progressif',
            'Aucune donnée n\'est perdue même en cas de problème réseau'
          ]
        }
      ]
    },
    {
      'title': 'Plan d\'Urgence',
      'icon': Icons.emergency,
      'content': [
        {
          'title': 'Créer votre Plan d\'Urgence',
          'description': 'Personnalisez vos actions et lieux de sécurité en cas d\'urgence.',
          'steps': [
            'Allez dans "Plan d\'Urgence" depuis le menu',
            'Appuyez sur l\'icône d\'édition',
            'Remplissez les différentes sections',
            'Sauvegardez votre plan personnalisé'
          ]
        },
        {
          'title': 'Instructions d\'Urgence',
          'description': 'Définissez les actions à effectuer immédiatement en cas de danger.',
          'steps': [
            'Décrivez vos actions prioritaires',
            'Incluez les numéros d\'urgence importants',
            'Précisez l\'ordre des actions à effectuer',
            'Gardez les instructions claires et simples'
          ]
        },
        {
          'title': 'Lieux de Sécurité',
          'description': 'Identifiez les endroits où vous pouvez vous réfugier en cas de danger.',
          'steps': [
            'Listez les pièces sécurisées de votre domicile',
            'Identifiez les lieux publics sûrs à proximité',
            'Précisez les adresses et moyens d\'accès',
            'Vérifiez que ces lieux sont accessibles 24h/24'
          ]
        }
      ]
    },
    {
      'title': 'Paramètres et Configuration',
      'icon': Icons.settings,
      'content': [
        {
          'title': 'Configurer les Notifications',
          'description': 'Personnalisez vos préférences de notifications pour rester informé.',
          'steps': [
            'Accédez aux "Paramètres" depuis le menu',
            'Configurez les notifications push, SMS et email',
            'Activez ou désactivez les sons et vibrations',
            'Testez vos paramètres pour vérifier qu\'ils fonctionnent'
          ]
        },
        {
          'title': 'Gérer la Confidentialité',
          'description': 'Contrôlez le partage de vos données et votre localisation.',
          'steps': [
            'Activez ou désactivez le partage de localisation',
            'Configurez la synchronisation automatique',
            'Vérifiez les permissions de l\'application',
            'Consultez la politique de confidentialité'
          ]
        },
        {
          'title': 'Personnaliser l\'Interface',
          'description': 'Adaptez l\'apparence de l\'application à vos préférences.',
          'steps': [
            'Choisissez entre le mode clair et sombre',
            'Ajustez la taille du texte si nécessaire',
            'Configurez la langue de l\'interface',
            'Personnalisez les couleurs d\'accent si disponible'
          ]
        }
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide et Support'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Navigation latérale
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: _buildSidebar(),
          ),
          // Contenu principal
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _helpSections.length,
      itemBuilder: (context, index) {
        final section = _helpSections[index];
        final isSelected = _selectedIndex == index;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.red.shade600 : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: Icon(
              section['icon'],
              color: isSelected ? Colors.red.shade600 : Colors.grey.shade600,
            ),
            title: Text(
              section['title'],
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.red.shade600 : Colors.black87,
              ),
            ),
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_selectedIndex >= _helpSections.length) return const SizedBox.shrink();
    
    final section = _helpSections[_selectedIndex];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la section
          Row(
            children: [
              Icon(
                section['icon'],
                size: 32,
                color: Colors.red.shade600,
              ),
              const SizedBox(width: 16),
              Text(
                section['title'],
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Contenu de la section
          ...section['content'].map<Widget>((item) => _buildHelpItem(item)).toList(),
          
          const SizedBox(height: 32),
          
          // Section de support
          _buildSupportSection(),
        ],
      ),
    );
  }

  Widget _buildHelpItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['title'],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item['description'],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            
            // Étapes
            if (item['steps'] != null) ...[
              Text(
                'Étapes à suivre :',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...item['steps'].map<Widget>((step) => _buildStepItem(step)).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Besoin d\'Aide Supplémentaire ?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Si vous avez des questions ou rencontrez des problèmes, n\'hésitez pas à nous contacter.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            
            // Boutons de support
            Row(
              children: [
                Expanded(
                  child: _buildSupportButton(
                    icon: Icons.email,
                    title: 'Email Support',
                    subtitle: 'Nous écrire',
                    color: Colors.blue,
                    onTap: () {
                      // TODO: Ouvrir l'email de support
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ouverture de l\'email de support à implémenter')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSupportButton(
                    icon: Icons.phone,
                    title: 'Téléphone',
                    subtitle: 'Nous appeler',
                    color: Colors.green,
                    onTap: () {
                      // TODO: Appeler le support
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appel du support à implémenter')),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // FAQ et ressources
            Row(
              children: [
                Expanded(
                  child: _buildSupportButton(
                    icon: Icons.question_answer,
                    title: 'FAQ',
                    subtitle: 'Questions fréquentes',
                    color: Colors.orange,
                    onTap: () {
                      // TODO: Ouvrir la FAQ
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ouverture de la FAQ à implémenter')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSupportButton(
                    icon: Icons.book,
                    title: 'Manuel Utilisateur',
                    subtitle: 'Guide complet',
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Ouvrir le manuel
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ouverture du manuel à implémenter')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
