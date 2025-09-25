import 'package:flutter/material.dart';
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

  final List<Map<String, String>> _items = [
    {'id': 'a1', 'type': 'article', 'title': 'Connaître ses droits', 'region': 'Conakry', 'lang': 'fr'},
    {'id': 'v1', 'type': 'video', 'title': 'Se protéger au quotidien', 'region': 'Labe', 'lang': 'fr'},
    {'id': 'a2', 'type': 'article', 'title': 'Recours légaux disponibles', 'region': 'Kindia', 'lang': 'fr'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text('Ressources éducatives', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: _buildRegionPicker()),
                const SizedBox(width: 8),
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
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                  leading: CircleAvatar(
                    backgroundColor: it['type'] == 'video' ? AppConstants.secondaryColor.withOpacity(0.2) : AppConstants.primaryColor.withOpacity(0.2),
                    child: Icon(it['type'] == 'video' ? Icons.play_circle : Icons.article, color: it['type'] == 'video' ? AppConstants.secondaryColor : AppConstants.primaryColor),
                  ),
                  title: Text(it['title']!, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
                  subtitle: Text('${it['region']} • ${it['lang']}', style: const TextStyle(color: Colors.black54)),
                  trailing: IconButton(
                    icon: Icon(isFav ? Icons.bookmark : Icons.bookmark_border, color: isFav ? AppConstants.primaryColor : Colors.black38),
                    onPressed: () => setState(() {
                      if (isFav) {
                        _favorites.remove(it['id']);
                      } else {
                        _favorites.add(it['id']!);
                      }
                    }),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ouverture: ${it['title']}')));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionPicker() {
    return DropdownButtonFormField<String>(
      value: _region,
      items: AppConstants.guineanRegions
          .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: Colors.black87))))
          .toList(),
      onChanged: (v) => setState(() => _region = v ?? _region),
      decoration: InputDecoration(
        labelText: 'Région',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppConstants.primaryColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2)),
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
      items: langs
          .map((l) => DropdownMenuItem(value: l['code'], child: Text(l['name']!, style: const TextStyle(color: Colors.black87))))
          .toList(),
      onChanged: (v) => setState(() => _lang = v ?? _lang),
      decoration: InputDecoration(
        labelText: 'Langue',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppConstants.primaryColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  List<Map<String, String>> _filtered() {
    var list = _items.where((it) => it['region'] == _region && it['lang'] == _lang).toList();
    if (_onlyFavs) {
      list = list.where((it) => _favorites.contains(it['id'])).toList();
    }
    return list;
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
