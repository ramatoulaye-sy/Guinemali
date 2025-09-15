import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

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
      appBar: AppBar(title: const Text('Géolocalisation (temps réel)')),
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
                      color: Colors.blue.withOpacity(0.15),
                      borderStrokeWidth: 1,
                      borderColor: Colors.blueAccent,
                      radius: _accuracy!.clamp(10, 200),
                    ),
                  ]),
                MarkerLayer(markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: _current!,
                    child: Transform.rotate(
                      angle: ((_heading ?? 0) * 3.1415926535) / 180.0,
                      child: const Icon(Icons.navigation, color: Colors.red, size: 32),
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
        onPressed: () {
          if (_current != null) {
            _map.move(_current!, 16);
          }
        },
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  Widget _buildGpsInfoCard() {
    final acc = _accuracy ?? 0;
    String quality;
    if (acc <= 20) {
      quality = 'Bonne';
    } else if (acc <= 50) {
      quality = 'Moyenne';
    } else {
      quality = 'Faible';
    }
    final speedKmh = ((_speed ?? 0) * 3.6).toStringAsFixed(1);
    final headingDeg = (_heading ?? 0).toStringAsFixed(0);
    return Card(
      color: Colors.white,
      shadowColor: Colors.black26,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              const Icon(Icons.speed, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Text('$speedKmh km/h'),
            ]),
            Row(children: [
              const Icon(Icons.explore, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Text('$headingDeg°'),
            ]),
            Row(children: [
              const Icon(Icons.gps_fixed, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Text('±${acc.toStringAsFixed(0)} m • $quality'),
            ]),
          ],
        ),
      ),
    );
  }
}


