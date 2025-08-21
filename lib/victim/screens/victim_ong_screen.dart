import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/user_model.dart';
import '../../core/services/supabase_service.dart';
import '../widgets/ong_card.dart';

/// Écran d'affichage des ONG et de leurs contacts
class VictimOngScreen extends StatefulWidget {
  const VictimOngScreen({super.key});

  @override
  State<VictimOngScreen> createState() => _VictimOngScreenState();
}

class _VictimOngScreenState extends State<VictimOngScreen> {
  List<UserModel> _ongs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadONGs();
  }

  Future<void> _loadONGs() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await SupabaseService.instance.select(
        'utilisateurs',
        filters: {'type_utilisateur': 'ong'},
        orderBy: 'prenom',
      );

      final ongs = (response.data as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
      
      setState(() {
        _ongs = ongs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  List<UserModel> get _filteredONGs {
    if (_searchQuery.isEmpty) return _ongs;
    
    return _ongs.where((ong) =>
        ong.prenom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (ong.region?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('ONG Partenaires'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.whiteColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppConstants.whiteColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Rechercher une ONG ou région...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(AppConstants.paddingMedium),
              ),
            ),
          ),
          
          // Statistiques
          if (!_isLoading) _buildStatsCard(),
          
          // Liste des ONG
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  )
                : _filteredONGs.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadONGs,
                        color: AppConstants.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                          ),
                          itemCount: _filteredONGs.length,
                          itemBuilder: (context, index) {
                            final ong = _filteredONGs[index];
                            return ONGCard(
                              ong: ong,
                                                    onCall: () => _makeCall(ong.numTel ?? ''),
                      onMessage: () => _sendMessage(ong.numTel ?? ''),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor.withOpacity(0.1),
            AppConstants.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            '${_ongs.length}',
            'ONG Disponibles',
            Icons.business,
          ),
          _buildStatItem(
            '24/7',
            'Assistance',
            Icons.access_time,
          ),
          _buildStatItem(
            '🇬🇳',
            'Guinée',
            Icons.location_on,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppConstants.primaryColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          Text(
            _searchQuery.isEmpty 
                ? 'Aucune ONG disponible'
                : 'Aucune ONG trouvée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Text(
            _searchQuery.isEmpty
                ? 'Les ONG partenaires apparaîtront ici'
                : 'Essayez avec d\'autres mots-clés',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: AppConstants.spacingLarge),
            ElevatedButton(
              onPressed: _loadONGs,
              child: const Text('Actualiser'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de passer l\'appel'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage(String phoneNumber) async {
    final uri = Uri.parse('sms:$phoneNumber?body=Bonjour, j\'ai besoin d\'aide via Guinèmali');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'envoyer le message'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }
}
