import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guinemali/core/services/supabase_service.dart';
import 'package:guinemali/core/providers/auth_provider.dart';
import 'package:guinemali/core/constants/app_constants.dart';
import 'package:guinemali/victim/widgets/alert_history_list.dart';

class VictimHistoryScreen extends StatefulWidget {
  const VictimHistoryScreen({super.key});

  @override
  State<VictimHistoryScreen> createState() => _VictimHistoryScreenState();
}

class _VictimHistoryScreenState extends State<VictimHistoryScreen> {
  List<AlertItem> _alerts = [];
  bool _isLoading = false;
  String _selectedFilter = 'all'; // all, active, resolved, cancelled

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;
      
      if (userId != null) {
        final response = await SupabaseService.instance.select(
          'alertes',
          columns: 'id, type_alerte, niveau_danger, description, statut, timestamp, latitude, longitude',
          filters: {'utilisateur_id': userId},
          orderBy: 'timestamp',
          ascending: false,
        );
        
        if (mounted) {
          setState(() {
            _alerts = List<Map<String, dynamic>>.from(response).map((m) => AlertItem(
              id: m['id'] ?? '',
              type: m['type_alerte'] ?? 'Alerte',
              status: m['statut'] ?? 'active',
              dangerLevel: m['niveau_danger'] ?? 'moyen',
              timestamp: m['timestamp'] ?? DateTime.now().toIso8601String(),
              latitude: (m['latitude'] as num?)?.toDouble(),
              longitude: (m['longitude'] as num?)?.toDouble(),
              description: m['description'],
            )).toList();
          });
        }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Alertes'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: AlertHistoryList(
                items: _alerts,
                filter: _selectedFilter,
                onFilterChanged: (f) => setState(() => _selectedFilter = f),
                onTapItem: (item) {
                  // TODO: ouvrir le détail de l'alerte
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Alerte ${item.id}')), 
                  );
                },
              ),
            ),
    );
  }
}
