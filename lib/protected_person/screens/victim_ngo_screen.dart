import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';

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

  final List<Map<String, String>> _ngos = [
    {'id': 'ngo1', 'name': 'ONG Espoir', 'region': 'Conakry', 'lang': 'fr', 'domain': 'Juridique', 'phone': '+224620000000', 'whatsapp': '+224620000000', 'email': 'contact@espoir.org'},
    {'id': 'ngo2', 'name': 'ONG Aide', 'region': 'Labe', 'lang': 'fr', 'domain': 'Psychologique', 'phone': '+224621111111', 'whatsapp': '+224621111111', 'email': 'support@aide.org'},
  ];

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
                Expanded(child: _buildDropdown('Langue', _lang, const ['fr','en','ff'], (v) => setState(() => _lang = v))),
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
            child: ListView.separated(
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

  List<Map<String, String>> _filtered() {
    var l = _ngos.where((n) => n['region'] == _region && n['lang'] == _lang).toList();
    if (_domain != 'Tous') l = l.where((n) => n['domain'] == _domain).toList();
    // _openNow est un placeholder: toutes les ONG listées sont considérées 24/24 dans cette V1
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
  final Map<String, String> ngo;
  const _NGOTile({Key? key, required this.ngo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                Text(ngo['name']!, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(height: 2),
                Text('${ngo['region']} • ${ngo['lang']} • ${ngo['domain']}', style: const TextStyle(color: Colors.black54)),
              ]),
            ),
            Wrap(spacing: 6, children: [
              _ActionIcon(icon: Icons.call, onTap: () => _launch('tel:${ngo['phone']}')),
              _ActionIcon(icon: Icons.sms, onTap: () => _launch('sms:${ngo['phone']}')),
              _ActionIcon(icon: Icons.chat, onTap: () => _launch('https://wa.me/${ngo['whatsapp']?.replaceAll('+', '')}')),
              _ActionIcon(icon: Icons.email, onTap: () => _launch('mailto:${ngo['email']}')),
            ]),
          ],
        ),
      ),
    );
  }

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
