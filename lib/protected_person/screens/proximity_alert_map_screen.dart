import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/geolocation_service.dart';

/// Écran de carte affichant une alerte de proximité
class ProximityAlertMapScreen extends StatefulWidget {
  final String alertId;
  final double alertLatitude;
  final double alertLongitude;
  final String? victimName;

  const ProximityAlertMapScreen({
    super.key,
    required this.alertId,
    required this.alertLatitude,
    required this.alertLongitude,
    this.victimName,
  });

  @override
  State<ProximityAlertMapScreen> createState() => _ProximityAlertMapScreenState();
}

class _ProximityAlertMapScreenState extends State<ProximityAlertMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _myPosition;
  bool _isLoadingPosition = true;
  double? _distanceToAlert;

  @override
  void initState() {
    super.initState();
    _loadMyPosition();
  }

  Future<void> _loadMyPosition() async {
    try {
      final hasPermission = await GeolocationService.instance.checkPermissions();
      if (!hasPermission) {
        setState(() => _isLoadingPosition = false);
        return;
      }

      final position = await GeolocationService.instance.getCurrentPosition();
      setState(() {
        _myPosition = LatLng(position.latitude, position.longitude);
        _distanceToAlert = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          widget.alertLatitude,
          widget.alertLongitude,
        ) / 1000; // Convertir en km
        _isLoadingPosition = false;
      });

      // Centrer la carte entre ma position et l'alerte
      _mapController.move(
        LatLng(
          (position.latitude + widget.alertLatitude) / 2,
          (position.longitude + widget.alertLongitude) / 2,
        ),
        13,
      );
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur récupération position: $e');
      }
      setState(() => _isLoadingPosition = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerte à proximité'),
        backgroundColor: AppConstants.errorColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Carte
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.alertLatitude, widget.alertLongitude),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.guinemali.mobile',
              ),
              // Cercle de danger autour de l'alerte
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(widget.alertLatitude, widget.alertLongitude),
                    color: AppConstants.errorColor.withOpacity(0.2),
                    borderStrokeWidth: 3,
                    borderColor: AppConstants.errorColor,
                    radius: 100, // 100 mètres
                  ),
                ],
              ),
              // Marqueurs
              MarkerLayer(
                markers: [
                  // Marqueur de l'alerte
                  Marker(
                    width: 60,
                    height: 60,
                    point: LatLng(widget.alertLatitude, widget.alertLongitude),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppConstants.errorColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.warning,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConstants.errorColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Marqueur de ma position (si disponible)
                  if (_myPosition != null)
                    Marker(
                      width: 50,
                      height: 50,
                      point: _myPosition!,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Info card en haut
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildInfoCard(),
          ),
          // Actions en bas
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildActionsCard(),
          ),
          // Loading overlay
          if (_isLoadingPosition)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          if (_myPosition != null) {
            _mapController.move(_myPosition!, 15);
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildInfoCard() {
    final victimName = widget.victimName ?? 'Une personne';
    
    return Card(
      color: AppConstants.errorColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ALERTE URGENCE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$victimName a besoin d\'aide',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_distanceToAlert != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'À ${_distanceToAlert!.toStringAsFixed(1)} km de vous',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: _openDirections,
              icon: const Icon(Icons.directions),
              label: const Text('Obtenir l\'itinéraire'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _callEmergency,
                    icon: const Icon(Icons.phone),
                    label: const Text('Appeler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Fermer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDirections() {
    // Ouvrir Google Maps ou l'app de navigation par défaut
    // TODO: Implémenter avec url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture de l\'itinéraire dans Google Maps...'),
        backgroundColor: AppConstants.primaryColor,
      ),
    );
  }

  void _callEmergency() {
    // TODO: Implémenter l'appel vers le numéro d'urgence de la victime
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'appel en développement'),
        backgroundColor: AppConstants.warningColor,
      ),
    );
  }
}
