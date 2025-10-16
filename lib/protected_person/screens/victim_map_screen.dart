import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_constants.dart';

class VictimMapScreen extends StatefulWidget {
  const VictimMapScreen({super.key});

  @override
  State<VictimMapScreen> createState() => _VictimMapScreenState();
}

class _VictimMapScreenState extends State<VictimMapScreen> {
  LatLng? _current;
  final MapController _map = MapController();
  double? _accuracy;
  double? _speed; // m/s
  double? _heading; // degrés

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activez la localisation pour afficher la carte.')),
      );
      return;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _current = LatLng(pos.latitude, pos.longitude);
      _accuracy = pos.accuracy;
      _speed = pos.speed;
      _heading = pos.heading;
    });

    Geolocator.getPositionStream().listen((p) {
      setState(() {
        _current = LatLng(p.latitude, p.longitude);
        _accuracy = p.accuracy;
        _speed = p.speed;
        _heading = p.heading;
      });
      _map.move(_current!, _map.camera.zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final center = _current ?? const LatLng(9.6412, -13.5784); // Conakry par défaut
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte GPS en temps réel'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: ~InteractiveFlag.rotate, // pas de rotation
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.guinemali.app',
              ),
              if (_current != null) ...[
                if (_accuracy != null)
                  CircleLayer(circles: [
                    CircleMarker(
                      point: _current!,
                      color: AppConstants.primaryColor.withOpacity(0.15),
                      borderStrokeWidth: 2,
                      borderColor: AppConstants.secondaryColor,
                      radius: _accuracy!.clamp(10, 200),
                    ),
                  ]),
                MarkerLayer(markers: [
                  Marker(
                    width: 50,
                    height: 50,
                    point: _current!,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Transform.rotate(
                        angle: ((_heading ?? 0) * 3.1415926535) / 180.0,
                        child: const Icon(Icons.navigation, color: Color(0xFF945acb), size: 32),
                      ),
                    ),
                  ),
                ]),
              ],
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 80,
            child: _buildGpsInfoCard(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          if (_current != null) {
            _map.move(_current!, 16);
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildGpsInfoCard() {
    final acc = _accuracy ?? 0;
    String quality;
    Color qualityColor;
    if (acc <= 20) {
      quality = 'Excellente';
      qualityColor = AppConstants.successColor;
    } else if (acc <= 50) {
      quality = 'Bonne';
      qualityColor = AppConstants.warningColor;
    } else {
      quality = 'Faible';
      qualityColor = AppConstants.errorColor;
    }
    final speedKmh = ((_speed ?? 0) * 3.6).toStringAsFixed(1);
    final headingDeg = (_heading ?? 0).toStringAsFixed(0);
    return Card(
      color: Colors.white,
      shadowColor: Colors.black26,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(Icons.speed, '$speedKmh km/h', 'Vitesse', AppConstants.primaryColor),
                _buildInfoItem(Icons.explore, '$headingDeg°', 'Direction', AppConstants.secondaryColor),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: qualityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: qualityColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gps_fixed, size: 18, color: qualityColor),
                  const SizedBox(width: 8),
                  Text(
                    'Précision: ±${acc.toStringAsFixed(0)} m',
                    style: TextStyle(
                      color: qualityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: qualityColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      quality,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}


