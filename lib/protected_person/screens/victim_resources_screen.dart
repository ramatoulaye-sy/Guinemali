import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';

class VictimResourcesScreen extends StatefulWidget {
  const VictimResourcesScreen({super.key});

  @override
  State<VictimResourcesScreen> createState() => _VictimResourcesScreenState();
}

class _VictimResourcesScreenState extends State<VictimResourcesScreen> {
  String _region = 'Conakry';
  String _lang = AppConstants.defaultLanguage;
  bool _offlineOnly = false;
  bool _onlyFavs = false;
  final Set<String> _favorites = <String>{};

  final List<Map<String, dynamic>> _items = [
    {
      'id': 'guide_securite_quotidien',
      'type': 'article',
      'title': 'Guide de sécurité au quotidien',
      'description': 'Conseils pratiques pour se protéger dans la vie de tous les jours',
      'region': 'Toutes',
      'lang': 'fr',
      'content': 'assets/resources/guide_securite_quotidien.pdf',
      'tags': ['sécurité', 'prévention', 'quotidien'],
      'offline': true,
      'author': 'Ministère de la Promotion Féminine',
      'rating': 4.5,
      'views': 1250,
      'downloads': 890,
    },
    {
      'id': 'droits_femmes_guinee',
      'type': 'article',
      'title': 'Droits des femmes en Guinée',
      'description': 'Connaître vos droits légaux et les recours disponibles',
      'region': 'Toutes',
      'lang': 'fr',
      'content': 'assets/resources/droits_femmes_guinee.pdf',
      'tags': ['droits', 'légal', 'recours'],
      'offline': true,
      'author': 'UN Women Guinée',
      'rating': 4.8,
      'views': 2100,
      'downloads': 1450,
    },
    {
      'id': 'auto_defense_basique',
      'type': 'video',
      'title': 'Techniques d\'auto-défense de base',
      'description': 'Apprendre les gestes essentiels pour se protéger',
      'region': 'Toutes',
      'lang': 'fr',
      'content': 'assets/resources/videos/auto_defense_basique.mp4',
      'duration': '15:30',
      'tags': ['auto-défense', 'protection', 'techniques'],
      'offline': true,
      'author': 'Centre de Formation Sécurité',
      'rating': 4.7,
      'views': 3200,
      'downloads': 2100,
    },
    {
      'id': 'prevention_violence_conjugale',
      'type': 'article',
      'title': 'Prévention de la violence conjugale',
      'description': 'Reconnaître les signes et savoir réagir',
      'region': 'Toutes',
      'lang': 'fr',
      'content': 'assets/resources/prevention_violence_conjugale.pdf',
      'tags': ['violence', 'prévention', 'conjugale'],
      'offline': true,
      'author': 'Association Protection Femmes',
      'rating': 4.6,
      'views': 1800,
      'downloads': 1200,
    },
    {
      'id': 'premiers_secours_psychologiques',
      'type': 'article',
      'title': 'Premiers secours psychologiques',
      'description': 'Comment gérer le stress et l\'anxiété après un incident',
      'region': 'Toutes',
      'lang': 'fr',
      'content': 'assets/resources/premiers_secours_psycho.pdf',
      'tags': ['psychologie', 'stress', 'soutien'],
      'offline': true,
      'author': 'OMS Guinée',
      'rating': 4.4,
      'views': 950,
      'downloads': 680,
    },
    {
      'id': 'quiz_connaissance_droits',
      'type': 'quiz',
      'title': 'Quiz : Connaissez-vous vos droits ?',
      'description': 'Testez vos connaissances sur les droits des femmes',
      'region': 'Toutes',
      'lang': 'fr',
      'questions': 10,
      'tags': ['quiz', 'droits', 'test'],
      'offline': true,
      'author': 'Plateforme Guinèmali',
      'rating': 4.3,
      'views': 1500,
      'downloads': 0,
    },
    {
      'id': 'checklist_securite_personnelle',
      'type': 'checklist',
      'title': 'Checklist de sécurité personnelle',
      'description': 'Vérifiez vos habitudes de sécurité quotidiennes',
      'region': 'Toutes',
      'lang': 'fr',
      'items': 15,
      'tags': ['checklist', 'sécurité', 'habitudes'],
      'offline': true,
      'author': 'Centre de Formation Sécurité',
      'rating': 4.2,
      'views': 1100,
      'downloads': 750,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF945acb), // 🔥 COULEUR PRIMAIRE
              Color(0xFFee82ee), // 🔥 COULEUR SECONDAIRE
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent, // 🔥 FOND TRANSPARENT POUR VOIR LE DÉGRADÉ
          appBar: AppBar(
            backgroundColor: Colors.transparent, // 🔥 APP BAR TRANSPARENTE
            elevation: 0,
            title: const Text('Ressources éducatives', style: TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16), // 🔥 PADDING PLUS GRAND
            child: Row(
              children: [
                Expanded(child: _buildRegionPicker()),
                const SizedBox(width: 16), // 🔥 ESPACEMENT PLUS GRAND
                Expanded(child: _buildLangPicker()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _TogglePill(label: 'Hors-ligne', selected: _offlineOnly, onTap: () => setState(() => _offlineOnly = !_offlineOnly)),
                const SizedBox(width: 8),
                _TogglePill(label: 'Favoris', selected: _onlyFavs, onTap: () => setState(() => _onlyFavs = !_onlyFavs), color: AppConstants.secondaryColor),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _filtered().length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final it = _filtered()[i];
                final isFav = _favorites.contains(it['id']);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 3,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openResource(it),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header avec type et actions
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: _getTypeColor(it['type']).withOpacity(0.2),
                                child: Icon(
                                  _getTypeIcon(it['type']),
                                  color: _getTypeColor(it['type']),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      it['title']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      it['description']!,
                                      style: const TextStyle(
                                        color: Colors.black87, // 🔥 CHANGÉ: noir au lieu de gris
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Actions
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isFav ? Icons.bookmark : Icons.bookmark_border,
                                      color: isFav ? AppConstants.primaryColor : Colors.black54,
                                    ),
                                    onPressed: () => setState(() {
                                      if (isFav) {
                                        _favorites.remove(it['id']);
                                      } else {
                                        _favorites.add(it['id']!);
                                      }
                                    }),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.download, color: Colors.black54),
                                    onPressed: () => _downloadResource(it),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Informations supplémentaires - CORRIGÉ POUR ÉVITER OVERFLOW
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // Auteur
                                Icon(Icons.person, size: 14, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text(
                                  it['author']!,
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                                const SizedBox(width: 16),
                                // Rating
                                Icon(Icons.star, size: 14, color: Colors.amber[600]),
                                const SizedBox(width: 4),
                                Text(
                                  it['rating']!.toString(),
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                                const SizedBox(width: 16),
                                // Vues
                                Icon(Icons.visibility, size: 14, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text(
                                  '${it['views']}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                                if (it['duration'] != null) ...[
                                  const SizedBox(width: 16),
                                  Icon(Icons.access_time, size: 14, color: Colors.black54),
                                  const SizedBox(width: 4),
                                  Text(
                                    it['duration']!,
                                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tags améliorés
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: (it['tags'] as List<String>).map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildRegionPicker() {
    return DropdownButtonFormField<String>(
      value: _region,
      dropdownColor: Colors.white, // 🔥 FOND BLANC POUR LE DROPDOWN
      items: AppConstants.guineanRegions
          .map((r) => DropdownMenuItem(
            value: r, 
            child: Text(r, style: const TextStyle(color: Colors.black87, fontSize: 14)),
          ))
          .toList(),
      onChanged: (v) => setState(() => _region = v ?? _region),
      decoration: InputDecoration(
        labelText: 'Région',
        labelStyle: TextStyle(
          color: Colors.grey[800], // 🔥 GRIS FONCÉ POUR MEILLEURE VISIBILITÉ
          fontWeight: FontWeight.w700,
          fontSize: 16, // 🔥 TAILLE PLUS GRANDE
        ), // 🔥 GRIS FONCÉ SANS OMBRE
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: AppConstants.primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildLangPicker() {
    final langs = const [
      {'code': 'fr', 'name': 'Français'},
      {'code': 'en', 'name': 'English'},
      {'code': 'ff', 'name': 'Pular'},
    ];
    return DropdownButtonFormField<String>(
      value: _lang,
      dropdownColor: Colors.white, // 🔥 FOND BLANC POUR LE DROPDOWN
      items: langs
          .map((l) => DropdownMenuItem(
            value: l['code'], 
            child: Text(l['name']!, style: const TextStyle(color: Colors.black87, fontSize: 14)),
          ))
          .toList(),
      onChanged: (v) => setState(() => _lang = v ?? _lang),
      decoration: InputDecoration(
        labelText: 'Langue',
        labelStyle: TextStyle(
          color: Colors.grey[800], // 🔥 GRIS FONCÉ POUR MEILLEURE VISIBILITÉ
          fontWeight: FontWeight.w700,
          fontSize: 16, // 🔥 TAILLE PLUS GRANDE
        ), // 🔥 GRIS FONCÉ SANS OMBRE
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: AppConstants.primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  List<Map<String, dynamic>> _filtered() {
    var list = _items.where((it) => 
      (it['region'] == _region || it['region'] == 'Toutes') && 
      it['lang'] == _lang
    ).toList();
    
    if (_offlineOnly) {
      list = list.where((it) => it['offline'] == true).toList();
    }
    
    if (_onlyFavs) {
      list = list.where((it) => _favorites.contains(it['id'])).toList();
    }
    
    return list;
  }

  // Helper methods pour les types de ressources
  Color _getTypeColor(String type) {
    switch (type) {
      case 'video':
        return AppConstants.secondaryColor;
      case 'article':
        return AppConstants.primaryColor;
      case 'quiz':
        return Colors.orange;
      case 'checklist':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle;
      case 'article':
        return Icons.article;
      case 'quiz':
        return Icons.quiz;
      case 'checklist':
        return Icons.checklist;
      default:
        return Icons.description;
    }
  }

  // Ouvrir une ressource
  void _openResource(Map<String, dynamic> resource) {
    final type = resource['type'] as String;
    final title = resource['title'] as String;
    
    switch (type) {
      case 'article':
        _showPdfViewer(resource);
        break;
      case 'video':
        _showVideoPlayer(resource);
        break;
      case 'quiz':
        _startQuiz(resource);
        break;
      case 'checklist':
        _showChecklist(resource);
        break;
      default:
        _showSnackBar('Ouverture: $title');
    }
  }

  // Télécharger une ressource
  void _downloadResource(Map<String, dynamic> resource) async {
    try {
      final title = resource['title'] as String;
      final type = resource['type'] as String;
      
      if (type == 'quiz' || type == 'checklist') {
        _showSnackBar('Cette ressource est déjà disponible hors-ligne');
        return;
      }
      
      // Simuler le téléchargement
      _showSnackBar('Téléchargement de "$title" en cours...');
      
      // Simuler le temps de téléchargement
      await Future.delayed(const Duration(seconds: 2));
      
      _showSnackBar('✅ "$title" téléchargé avec succès !');
      
      // Incrémenter le compteur de téléchargements (simulation)
      setState(() {
        final index = _items.indexWhere((item) => item['id'] == resource['id']);
        if (index != -1) {
          _items[index]['downloads'] = (_items[index]['downloads'] as int) + 1;
        }
      });
      
    } catch (e) {
      _showSnackBar('❌ Erreur lors du téléchargement: $e');
    }
  }

  // Afficher un PDF (simulation)
  void _showPdfViewer(Map<String, dynamic> resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resource['title'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Contenu PDF: ${resource['description']}'),
            const SizedBox(height: 16),
            const Text('📱 Mode démo - Le PDF s\'ouvrirait ici'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadResource(resource);
            },
            child: const Text('Télécharger'),
          ),
        ],
      ),
    );
  }

  // Afficher un lecteur vidéo (simulation)
  void _showVideoPlayer(Map<String, dynamic> resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resource['title'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text('Durée: ${resource['duration']}'),
            const SizedBox(height: 16),
            const Text('📱 Mode démo - La vidéo se lancerait ici'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadResource(resource);
            },
            child: const Text('Télécharger'),
          ),
        ],
      ),
    );
  }

  // Démarrer un quiz (simulation)
  void _startQuiz(Map<String, dynamic> resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resource['title'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.quiz, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text('${resource['questions']} questions'),
            const SizedBox(height: 16),
            const Text('📱 Mode démo - Le quiz s\'ouvrirait ici'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('🎯 Quiz démarré !');
            },
            child: const Text('Commencer'),
          ),
        ],
      ),
    );
  }

  // Afficher une checklist (simulation)
  void _showChecklist(Map<String, dynamic> resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resource['title'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.checklist, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text('${resource['items']} éléments à vérifier'),
            const SizedBox(height: 16),
            const Text('📱 Mode démo - La checklist s\'ouvrirait ici'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('✅ Checklist ouverte !');
            },
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );
  }

  // Afficher un message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('❌') ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _TogglePill({Key? key, required this.label, required this.selected, required this.onTap, this.color = AppConstants.primaryColor}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color, width: 1.2),
          boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0,2))] : null,
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
