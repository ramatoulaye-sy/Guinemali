import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/supabase_service.dart';

class VictimNGOScreen extends StatefulWidget {
  const VictimNGOScreen({super.key});

  @override
  State<VictimNGOScreen> createState() => _VictimNGOScreenState();
}

class _VictimNGOScreenState extends State<VictimNGOScreen> {
  String _region = 'Conakry';
  String _lang = 'fr';
  String _domain = 'Tous';
  bool _openNow = true; // 24/24 par défaut
  
  List<Map<String, dynamic>> _ngos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNGOs();
  }

  Future<void> _loadNGOs() async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.ensureInitialized();
      
      // Essayer différentes variantes de noms de colonnes
      final rows = await SupabaseService.instance.select(
        'ong',
        columns: 'id, name, nom_organisation, region, langues, langue, domaine, domaine_intervention, telephone, tel, whatsapp, email, ouvert_24_7, disponible_24_7',
      ).catchError((e) async {
        // Si ça échoue, essayer avec toutes les colonnes
        print('⚠️ Erreur colonnes spécifiques, tentative SELECT *');
        return await SupabaseService.instance.select('ong');
      });
      
      if (mounted) {
        setState(() {
          _ngos = (rows as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
        
        if (_ngos.isNotEmpty) {
          // Afficher les colonnes disponibles pour debug
          print('✅ ONG chargées: ${_ngos.length}');
          print('📋 Colonnes disponibles: ${_ngos.first.keys.toList()}');
        }
      }
    } catch (e) {
      print('❌ Erreur chargement ONG: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement des ONG: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text('ONG 24/24', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: _buildDropdown('Région', _region, AppConstants.guineanRegions, (v) => setState(() => _region = v))),
                const SizedBox(width: 8),
                Expanded(child: _buildDropdown('Langue', _lang, const ['fr','en'], (v) => setState(() => _lang = v))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _Pill(label: '24/24', selected: _openNow, onTap: () => setState(() => _openNow = !_openNow)),
                const SizedBox(width: 8),
                _Pill(label: _domain, selected: _domain != 'Tous', onTap: _pickDomain),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                : _filtered().isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('Aucune ONG trouvée', style: TextStyle(color: Colors.black54, fontSize: 18)),
                            const SizedBox(height: 8),
                            const Text('Essayez de changer les filtres', style: TextStyle(color: Colors.black38)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered().length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final ngo = _filtered()[i];
                          return _NGOTile(ngo: ngo);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filtered() {
    var l = _ngos.where((n) {
      // Filtrer par région
      if (n['region'] != _region) return false;
      
      // Filtrer par langue (essayer plusieurs variantes de colonnes)
      final langues = n['langues_supportees'] ?? n['langues'] ?? n['langue'];
      bool langMatch = false;
      if (langues is List) {
        langMatch = langues.contains(_lang);
      } else if (langues is String) {
        langMatch = langues.contains(_lang);
      }
      // Si pas de langue spécifiée, accepter par défaut
      if (langues == null) langMatch = true;
      if (!langMatch) return false;
      
      return true;
    }).toList();
    
    // Filtrer par domaine
    if (_domain != 'Tous') {
      l = l.where((n) {
        final domaine = n['domaine_intervention'] ?? n['domaine'];
        return domaine == _domain;
      }).toList();
    }
    
    // Filtrer par disponibilité 24/7
    if (_openNow) {
      l = l.where((n) {
        final ouvert = n['ouvert_24_7'] ?? n['disponible_24_7'];
        return ouvert == true || ouvert == 1 || ouvert == '1';
      }).toList();
    }
    
    return l;
  }

  void _pickDomain() async {
    final domains = ['Tous','Juridique','Psychologique','Santé','Hébergement'];
    final d = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Domaine'),
        children: domains.map((e) => SimpleDialogOption(onPressed: () => Navigator.of(ctx).pop(e), child: Text(e))).toList(),
      ),
    );
    if (d != null) setState(() => _domain = d);
  }

  Widget _buildDropdown(String label, String value, List<String> values, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: values.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(color: Colors.black87)))).toList(),
      onChanged: (v) => onChanged(v ?? value),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppConstants.primaryColor)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppConstants.primaryColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _NGOTile extends StatelessWidget {
  final Map<String, dynamic> ngo;
  const _NGOTile({Key? key, required this.ngo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Gérer plusieurs variantes de noms de colonnes
    final String nom = ngo['nom'] ?? ngo['name'] ?? ngo['nom_organisation'] ?? 'ONG';
    final String region = ngo['region'] ?? '';
    final String domaine = ngo['domaine_intervention'] ?? ngo['domaine'] ?? '';
    final String telephone = ngo['telephone'] ?? ngo['tel'] ?? '';
    final String whatsapp = ngo['whatsapp'] ?? telephone;
    final String email = ngo['email'] ?? '';
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: AppConstants.secondaryColor.withOpacity(0.15), child: const Icon(Icons.handshake, color: AppConstants.secondaryColor)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nom, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(height: 2),
                Text('$region • $domaine', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ]),
            ),
            Wrap(spacing: 6, children: [
              if (telephone.isNotEmpty) _ActionIcon(icon: Icons.call, onTap: () => _launch('tel:$telephone')),
              if (telephone.isNotEmpty) _ActionIcon(icon: Icons.sms, onTap: () => _launch('sms:$telephone')),
              if (whatsapp.isNotEmpty) _ActionIcon(icon: Icons.chat, onTap: () => _launch('https://wa.me/${whatsapp.replaceAll('+', '').replaceAll(' ', '')}')),
              if (email.isNotEmpty) _ActionIcon(icon: Icons.email, onTap: () => _launch('mailto:$email')),
            ]),
          ],
        ),
      ),
    );
  }

  static Future<void> _launch(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('❌ Impossible de lancer: $url');
      }
    } catch (e) {
      print('❌ Erreur lancement URL: $e');
    }
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIcon({Key? key, required this.icon, required this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: AppConstants.primaryColor.withOpacity(0.08), shape: BoxShape.circle, border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2))),
        child: Icon(icon, size: 18, color: AppConstants.primaryColor),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({Key? key, required this.label, required this.selected, required this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppConstants.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppConstants.primaryColor, width: 1.2),
          boxShadow: selected ? [BoxShadow(color: AppConstants.primaryColor.withOpacity(0.25), blurRadius: 8, offset: const Offset(0,2))] : null,
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppConstants.primaryColor, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
