import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// removed unused import
import 'package:url_launcher/url_launcher.dart';
import 'package:guinemali/core/services/a11y_service.dart';
import 'package:guinemali/core/services/storage_service.dart';

class VictimHelpScreen extends StatefulWidget {
  const VictimHelpScreen({super.key});

  @override
  State<VictimHelpScreen> createState() => _VictimHelpScreenState();
}

class _VictimHelpScreenState extends State<VictimHelpScreen> {
  int _selectedIndex = 0;

  String _t(String key) {
    final lang = StorageService.instance.getString('selected_language') ?? 'fr';
    const map = {
      'fr': {
        'help_title': 'Aide et Support',
        'more_help': 'Besoin d\'Aide Supplémentaire ?',
        'contact_us': 'Si vous avez des questions ou rencontrez des problèmes, n\'hésitez pas à nous contacter.',
        'email_support': 'Email Support',
        'write_us': 'Nous écrire',
        'phone': 'Téléphone',
        'call_us': 'Nous appeler',
        'faq': 'FAQ',
        'faq_sub': 'Questions fréquentes',
        'manual': 'Manuel Utilisateur',
        'manual_sub': 'Guide complet',
        'diagnose': 'Diagnostiquer les permissions',
        'test_notifications': 'Tester les notifications',
      },
      'sus': {
        'help_title': 'Xɔriɲɛn nɛ kɔrɔ',
        'more_help': 'I tan nɛɛ xɔriɲɛn?',
        'contact_us': 'I bɛ n tan nɛɛ xɔriɲɛn, i lu n fan yɔn.',
        'email_support': 'Email xɔriɲɛn',
        'write_us': 'N fan yɔn',
        'phone': 'Telefɔni',
        'call_us': 'N bɛ naxan',
        'faq': 'FAQ',
        'faq_sub': 'Kɔrɔ mɛnɛ',
        'manual': 'Fɛɛn kili',
        'manual_sub': 'Tariki kɛndɛ',
        'diagnose': 'Sɛbɛn sɛnni fɛnsɛn',
        'test_notifications': 'Ṣɛli sɛnni',
      },
      'ff': {
        'help_title': 'Ballal e Wallitorde',
        'more_help': 'Aɗa jogii ballal goɗɗo?',
        'contact_us': 'So aɗa jogii caɗeele, ena waawi nden tawi amen.',
        'email_support': 'Ballal e Imeel',
        'write_us': 'Winndu amen',
        'phone': 'Telefoon',
        'call_us': 'Noddii amen',
        'faq': 'FAQ',
        'faq_sub': 'Naamnaaji jaajol',
        'manual': 'Doggitannde Kuutorɗo',
        'manual_sub': 'Jaaɓnirgal timmunde',
        'diagnose': 'Ƴeewto jamirooje',
        'test_notifications': 'Ƴeewto tintinooje',
      },
      'mlq': {
        'help_title': 'Bana ni Sutura',
        'more_help': 'I ba fɔ bana kɔrɔ?',
        'contact_us': 'I ka sɔrɔ kɛlɛ, i bɛ fɔ i ɲɛ.',
        'email_support': 'Email Bana',
        'write_us': 'Na i ma',
        'phone': 'Tilifɔni',
        'call_us': 'Bɔ i ma',
        'faq': 'FAQ',
        'faq_sub': 'Demi kɛcɛn',
        'manual': 'Jatigi Kɔnɔ',
        'manual_sub': 'Gidɛ sugandilen',
        'diagnose': 'Wɛrɛwɛrɛ ɲɛɛnɛ',
        'test_notifications': 'Ɲɛɛnɛ kɔlɔsi',
      },
    };
    return (map[lang] ?? map['fr']!)[key] ?? map['fr']![key] ?? key;
  }

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec titre et bouton retour
            _buildHeader(context),
            
            // Contenu principal - grille mobile-first
            Expanded(
              child: _buildMobileContent(context),
            ),
            
            // Zone SOS en bas
            _buildSOSZone(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton retour
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withOpacity(0.25)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Titre et sous-titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('help_title'),
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF945acb),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trouvez rapidement l\'aide dont vous avez besoin',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Grille des sections d'aide
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _helpSections.length,
            itemBuilder: (context, index) {
              return _buildAnimatedCard(context, index);
            },
          ),
          const SizedBox(height: 20),
          
          // Zone de support supplémentaire
          _buildSupportSection(context),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(BuildContext context, int index) {
    final section = _helpSections[index];
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                A11yService.announceIfEnabled(context, 'Section: ${section['title']}');
                _showSectionDetails(context, section);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? colorScheme.primary
                        : Colors.grey.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icône avec effet de halo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ] : null,
                      ),
                      child: Icon(
                        section['icon'],
                        size: 32,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Titre
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        section['title'],
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF945acb),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('more_help'),
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _t('contact_us'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          _buildSupportButtons(context),
        ],
      ),
    );
  }

  Widget _buildSupportButtons(BuildContext context) {
    return Column(
      children: [
        _buildSupportButton(
          context,
          icon: Icons.email,
          title: _t('email_support'),
          subtitle: _t('write_us'),
          onTap: () => _launchEmail(context),
        ),
        const SizedBox(height: 12),
        _buildSupportButton(
          context,
          icon: Icons.phone,
          title: _t('phone'),
          subtitle: _t('call_us'),
          onTap: () => _launchPhone(context),
        ),
        const SizedBox(height: 12),
        _buildSupportButton(
          context,
          icon: Icons.help_outline,
          title: _t('faq'),
          subtitle: _t('faq_sub'),
          onTap: () => _launchFAQ(context),
        ),
        const SizedBox(height: 12),
        _buildSupportButton(
          context,
          icon: Icons.book,
          title: _t('manual'),
          subtitle: _t('manual_sub'),
          onTap: () => _launchManual(context),
        ),
      ],
    );
  }

  Widget _buildSupportButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF945acb),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSZone(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.warning,
              color: Colors.red[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Déclencher une Alerte SOS',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'En cas d\'urgence immédiate',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // TODO: Implémenter la logique SOS
              A11yService.announceIfEnabled(context, 'Alerte SOS déclenchée');
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emergency,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSectionDetails(BuildContext context, Map<String, dynamic> section) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSectionModal(context, section),
    );
  }

  Widget _buildSectionModal(BuildContext context, Map<String, dynamic> section) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF945acb).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    section['icon'],
                    color: const Color(0xFF945acb),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    section['title'],
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: (section['content'] as List).map<Widget>((item) {
                  return _buildHelpItem(item);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes de lancement des liens externes
  Future<void> _launchEmail(BuildContext context) async {
    const email = 'support@guinemali.com';
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        A11yService.announceIfEnabled(context, 'Email ouvert');
      } else {
        await Clipboard.setData(const ClipboardData(text: email));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email copié: $email')),
          );
          A11yService.announceIfEnabled(context, 'Email copié dans le presse-papiers');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    const phone = '+224 123 456 789';
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        A11yService.announceIfEnabled(context, 'Appel téléphonique lancé');
      } else {
        await Clipboard.setData(const ClipboardData(text: phone));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Numéro copié: $phone')),
          );
          A11yService.announceIfEnabled(context, 'Numéro copié dans le presse-papiers');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _launchFAQ(BuildContext context) async {
    final url = _getLocalizedUrl('faq_url');
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        A11yService.announceIfEnabled(context, 'FAQ ouverte');
      } else {
        await Clipboard.setData(ClipboardData(text: url));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lien FAQ copié: $url')),
          );
          A11yService.announceIfEnabled(context, 'Lien FAQ copié dans le presse-papiers');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _launchManual(BuildContext context) async {
    final url = _getLocalizedUrl('manual_url');
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        A11yService.announceIfEnabled(context, 'Manuel ouvert');
      } else {
        await Clipboard.setData(ClipboardData(text: url));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lien Manuel copié: $url')),
          );
          A11yService.announceIfEnabled(context, 'Lien Manuel copié dans le presse-papiers');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  String _getLocalizedUrl(String key) {
    final lang = StorageService.instance.getString('selected_language') ?? 'fr';
    const urls = {
      'fr': {
        'faq_url': 'https://guinemali.com/faq',
        'manual_url': 'https://guinemali.com/manual',
      },
      'sus': {
        'faq_url': 'https://guinemali.com/sus/faq',
        'manual_url': 'https://guinemali.com/sus/manual',
      },
      'ff': {
        'faq_url': 'https://guinemali.com/ff/faq',
        'manual_url': 'https://guinemali.com/ff/manual',
      },
      'mlq': {
        'faq_url': 'https://guinemali.com/mlq/faq',
        'manual_url': 'https://guinemali.com/mlq/manual',
      },
    };
    
    return urls[lang]?[key] ?? urls['fr']![key]!;
  }

  // Ancienne sidebar supprimée (non utilisée avec le design mobile-first)

  // Ancien contenu (layout desktop) supprimé (non utilisé)

  Widget _buildHelpItem(Map<String, dynamic> item) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['title'],
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item['description'],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 14),
          if (item['steps'] != null) ...[
            Text(
              'Étapes à suivre :',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...item['steps'].map<Widget>((step) => _buildStepItem(step)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem(String step) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary,
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
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Supprimé: ancienne version _buildSupportSectionOld non utilisée
  /*Widget _buildSupportSectionOld() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('more_help'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _t('contact_us'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            
            // Boutons de support
            Row(
              children: [
                Expanded(
                  child: _buildSupportButton(
                    icon: Icons.email,
                    title: _t('email_support'),
                    subtitle: _t('write_us'),
                    color: Colors.blue,
                    onTap: () async {
                      final uri = Uri.parse('mailto:support@guinemali.org?subject=Support%20Guinemali');
                      A11yService.announceIfEnabled(context, 'Ouverture de l\'email de support');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client email ouvert')));
                        A11yService.announceIfEnabled(context, 'Client email ouvert');
                      } else {
                        await Clipboard.setData(const ClipboardData(text: 'support@guinemali.org'));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse email copiée')));
                        A11yService.announceIfEnabled(context, 'Adresse email copiée');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSupportButton(
                    icon: Icons.phone,
                    title: _t('phone'),
                    subtitle: _t('call_us'),
                    color: Colors.green,
                    onTap: () async {
                      final phone = '+224000000000';
                      final uri = Uri.parse('tel:$phone');
                      A11yService.announceIfEnabled(context, 'Ouverture de l\'appel');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application téléphone ouverte')));
                        A11yService.announceIfEnabled(context, 'Application téléphone ouverte');
                      } else {
                        await Clipboard.setData(ClipboardData(text: phone));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro copié')));
                        A11yService.announceIfEnabled(context, 'Numéro copié');
                      }
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
                    title: _t('faq'),
                    subtitle: _t('faq_sub'),
                    color: Colors.orange,
                    onTap: () async {
                      final uri = _getLocalizedUri('faq');
                      A11yService.announceIfEnabled(context, 'Ouverture de la FAQ');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FAQ ouverte')));
                        A11yService.announceIfEnabled(context, 'FAQ ouverte');
                      } else {
                        await Clipboard.setData(ClipboardData(text: uri.toString()));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lien FAQ copié')));
                        A11yService.announceIfEnabled(context, 'Lien FAQ copié');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSupportButton(
                    icon: Icons.book,
                    title: _t('manual'),
                    subtitle: _t('manual_sub'),
                    color: Colors.purple,
                    onTap: () async {
                      final uri = _getLocalizedUri('manual');
                      A11yService.announceIfEnabled(context, 'Ouverture du manuel utilisateur');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manuel ouvert')));
                        A11yService.announceIfEnabled(context, 'Manuel ouvert');
                      } else {
                        await Clipboard.setData(ClipboardData(text: uri.toString()));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lien manuel copié')));
                        A11yService.announceIfEnabled(context, 'Lien manuel copié');
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Outils techniques
            Row(
              children: [
                Expanded(
                  child: _buildSupportButton(
                    icon: Icons.privacy_tip,
                    title: _t('diagnose'),
                    subtitle: 'GPS, SMS, stockage',
                    color: colorScheme.primary,
                    onTap: () async {
                      A11yService.announceIfEnabled(context, 'Diagnostic des permissions');
                      // Ouvre la page permissions existante
                      if (!mounted) return;
                      context.go(AppConstants.routePermissions);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSupportButton(
                    icon: Icons.notifications_active,
                    title: _t('test_notifications'),
                    subtitle: 'Push/SMS (simulation)',
                    color: colorScheme.secondary,
                    onTap: () async {
                      // Test simple: lire préférence et annoncer
                      final mode = StorageService.instance.getString('notification_type') ?? 'push';
                      final label = mode == 'both' ? 'Push + SMS' : (mode == 'sms' ? 'SMS' : 'Push');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Test notifications: $label')),
                      );
                      A11yService.announceIfEnabled(context, 'Test notifications: $label');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }*/

  // Supprimé: ancienne version _buildSupportButtonOld non utilisée
  /*Widget _buildSupportButtonOld({
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
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }*/
}