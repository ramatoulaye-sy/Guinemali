import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/services/alert_service.dart';
import '../../core/services/evidence_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart';

class VictimHistoryScreen extends StatefulWidget {
  const VictimHistoryScreen({super.key});

  @override
  State<VictimHistoryScreen> createState() => _VictimHistoryScreenState();
}

class _VictimHistoryScreenState extends State<VictimHistoryScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = false;
  String _selectedFilter = 'all'; // all, active, cancelled

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final history = await AlertService.instance.getAlertHistory();
      if (mounted) {
        setState(() {
          _alerts = history;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _alerts.where((a) {
      if (_selectedFilter == 'all') return true;
      return (a['status'] ?? a['statut'] ?? 'active') ==
          (_selectedFilter == 'active' ? 'active' : 'cancelled');
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Historique des Alertes', style: TextStyle(color: Colors.white)),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAlerts),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Vider l\'historique',
            onPressed: () async {
              await AlertService.instance.clearAlertHistory();
              await _loadAlerts();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('all', 'Toutes'),
                      _buildFilterChip('active', 'Actives'),
                      _buildFilterChip('cancelled', 'Annulées'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Aucune alerte', style: TextStyle(color: Colors.black54)))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final a = filtered[index];
                            final status = (a['status'] ?? a['statut'] ?? 'active') as String;
                            final dateStr = a['timestamp'] ?? a['time'] ?? DateTime.now().toIso8601String();
                            final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                            final fmt = DateFormat('dd/MM/yyyy HH:mm');
                            final lat = a['latitude'];
                            final lon = a['longitude'];
                            final id = a['id'] ?? '';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: status == 'active' ? AppConstants.secondaryColor : Colors.grey.shade300,
                                child: Icon(Icons.emergency, color: status == 'active' ? Colors.white : Colors.black54),
                              ),
                              title: Text('Alerte ${id.toString().substring(0, 6)} • ${fmt.format(date)}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
                              subtitle: Text(lat != null && lon != null ? '📍 $lat, $lon' : 'Sans position', style: const TextStyle(color: Colors.black54)),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: AppConstants.primaryColor),
                                onSelected: (v) async {
                                  if (v == 'open') {
                                    // Sauvegarder l'ID de l'alerte pour redirection
                                    await StorageService.instance.saveString(AppConstants.keyCurrentAlertId, id);
                                    await StorageService.instance.saveString('current_alert_should_open', '1');
                                    if (!mounted) return;
                                    context.push(AppConstants.routeVictimActiveAlert);
                                  } else if (v == 'evidences') {
                                    // Naviguer vers l'écran des preuves de cette alerte
                                    if (!mounted) return;
                                    await _showEvidencesForAlert(id);
                                  } else if (v == 'report') {
                                    final report = await AlertService.instance.generateAlertReport(id);
                                    if (!mounted) return;
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        backgroundColor: AppConstants.primaryColor,
                                        title: const Row(
                                          children: [
                                            Icon(Icons.description, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text('Rapport détaillé', style: TextStyle(color: Colors.white)),
                                          ],
                                        ),
                                        content: SingleChildScrollView(
                                          child: Text(report.toString(), style: const TextStyle(color: Colors.white)),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Fermer', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (v == 'pdf') {
                                    await _exportPdfForAlert(a);
                                  } else if (v == 'share') {
                                    await _shareAlert(a);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'open',
                                    child: Row(
                                      children: [
                                        Icon(Icons.open_in_new, size: 20, color: AppConstants.primaryColor),
                                        SizedBox(width: 8),
                                        Text('Ouvrir l\'alerte'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'evidences',
                                    child: Row(
                                      children: [
                                        Icon(Icons.video_library, size: 20, color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text('Voir les preuves'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'report',
                                    child: Row(
                                      children: [
                                        Icon(Icons.description, size: 20, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Rapport détaillé'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'pdf',
                                    child: Row(
                                      children: [
                                        Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Exporter PDF Gendarmerie'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'share',
                                    child: Row(
                                      children: [
                                        Icon(Icons.share, size: 20, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('Partager'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _exportPdfForAlert(Map<String, dynamic> alert) async {
    final doc = pw.Document();
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final id = (alert['id'] ?? '').toString();
    final dateStr = alert['timestamp'] ?? alert['time'] ?? DateTime.now().toIso8601String();
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final lat = alert['latitude'];
    final lon = alert['longitude'];
    final status = (alert['status'] ?? alert['statut'] ?? 'active').toString();
    final mapsUrl = (lat != null && lon != null)
        ? 'https://www.google.com/maps?q=$lat,$lon'
        : 'Position indisponible';

    final barcode = Barcode.qrCode();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Guinémali – Rapport d\'Alerte',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('ID: ${id.isEmpty ? 'N/A' : id}'),
                pw.Text('Date: ${fmt.format(date)}'),
                pw.Text('Statut: ${status.toUpperCase()}'),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Text('Position', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text(lat != null && lon != null ? 'Lat: $lat, Lon: $lon' : 'Position non disponible'),
                pw.SizedBox(height: 6),
                pw.Text('Lien Google Maps:'),
                pw.UrlLink(
                  destination: lat != null && lon != null ? mapsUrl : '',
                  child: pw.Text(mapsUrl, style: const pw.TextStyle(color: PdfColors.blue)),
                ),
                pw.SizedBox(height: 16),
                if (lat != null && lon != null)
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Text('QR vers la position'),
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Container(
                        width: 120,
                        height: 120,
                        child: pw.BarcodeWidget(
                          barcode: barcode,
                          data: mapsUrl,
                        ),
                      ),
                    ],
                  ),
                pw.SizedBox(height: 20),
                pw.Text('Résumé des preuves',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Bullet(text: 'Preuves locales liées à cette alerte (voir écran Preuves).'),
                pw.Bullet(text: 'Audio/vidéo chiffrés et stockés localement.'),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text('Document généré automatiquement – Guinémali'),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : AppConstants.primaryColor, fontWeight: FontWeight.w700)),
      selected: selected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppConstants.primaryColor,
      backgroundColor: Colors.white,
      shape: StadiumBorder(side: BorderSide(color: AppConstants.primaryColor)),
    );
  }

  /// Affiche les preuves associées à une alerte
  Future<void> _showEvidencesForAlert(String alertId) async {
    try {
      // Charger les preuves depuis le service
      final evidences = await EvidenceService.instance.getEvidencesForAlert(alertId);
      
      if (!mounted) return;
      
      if (evidences.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune preuve enregistrée pour cette alerte'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.video_library, color: AppConstants.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Preuves de l\'alerte',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              ...evidences.map((evidence) {
                final type = evidence['type'] ?? 'unknown';
                IconData icon = Icons.insert_drive_file;
                Color color = Colors.grey;
                
                if (type == 'audio') {
                  icon = Icons.audiotrack;
                  color = AppConstants.primaryColor;
                } else if (type == 'video') {
                  icon = Icons.videocam;
                  color = AppConstants.secondaryColor;
                } else if (type == 'photo') {
                  icon = Icons.camera_alt;
                  color = Colors.orange;
                }
                
                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(type.toUpperCase()),
                  subtitle: Text(evidence['file_path'] ?? 'Fichier'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Naviguer vers l'écran des preuves
                    context.push(AppConstants.routeVictimEvidence);
                  },
                );
              }).toList(),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Partage les détails d'une alerte
  Future<void> _shareAlert(Map<String, dynamic> alert) async {
    try {
      final id = (alert['id'] ?? '').toString();
      final dateStr = alert['timestamp'] ?? alert['time'] ?? DateTime.now().toIso8601String();
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
      final fmt = DateFormat('dd/MM/yyyy HH:mm');
      final lat = alert['latitude'];
      final lon = alert['longitude'];
      final status = (alert['status'] ?? alert['statut'] ?? 'active').toString();
      
      final shareText = '''
🚨 ALERTE GUINEMALI

ID: ${id.substring(0, 8)}
Date: ${fmt.format(date)}
Statut: ${status.toUpperCase()}

📍 Position:
${lat != null && lon != null ? 'Latitude: $lat\nLongitude: $lon\n\nGoogle Maps: https://www.google.com/maps?q=$lat,$lon' : 'Position non disponible'}

---
Rapport généré par Guinemali
Application de protection des victimes
''';

      // Copier dans le presse-papiers
      await Clipboard.setData(ClipboardData(text: shareText));
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Détails de l\'alerte copiés dans le presse-papiers'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
