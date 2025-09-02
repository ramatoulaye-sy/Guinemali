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
    });

    Geolocator.getPositionStream().listen((p) {
      setState(() {
        _current = LatLng(p.latitude, p.longitude);
      });
      _map.move(_current!, _map.camera.zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final center = _current ?? const LatLng(9.6412, -13.5784); // Conakry par défaut
    return Scaffold(
      appBar: AppBar(title: const Text('Géolocalisation (temps réel)')),
      body: FlutterMap(
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
          if (_current != null)
            MarkerLayer(markers: [
              Marker(
                width: 40,
                height: 40,
                point: _current!,
                child: const Icon(Icons.my_location, color: Colors.red, size: 32),
              ),
            ]),
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
}


