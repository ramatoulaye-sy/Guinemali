import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/alert_service.dart';
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
                                onSelected: (v) async {
                                  if (v == 'open') {
                                    context.push(AppConstants.routeVictimActiveAlert);
                                  } else if (v == 'evidences') {
                                    // Optionnel: futur écran détails
                                  } else if (v == 'report') {
                                    final report = await AlertService.instance.generateAlertReport(id);
                                    if (!mounted) return;
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Rapport'),
                                        content: Text(report.toString()),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Fermer'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (v == 'pdf') {
                                    await _exportPdfForAlert(a);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'open', child: Text('Ouvrir')),
                                  PopupMenuItem(value: 'report', child: Text('Rapport brut')),
                                  PopupMenuItem(value: 'pdf', child: Text('Exporter PDF')),
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
}
