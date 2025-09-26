import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:guinemali/core/services/storage_service.dart';

class LocationTrackingService {
  LocationTrackingService._();
  static final LocationTrackingService instance = LocationTrackingService._();

  StreamSubscription<Position>? _sub;
  bool get isRunning => _sub != null;

  Future<void> start({required String accuracy, required int intervalSec}) async {
    await _ensurePermissions();
    await stop();
    final desired = _mapAccuracy(accuracy);
    _sub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: desired,
        distanceFilter: 0,
      ),
    ).listen((pos) async {
      final lat = pos.latitude.toStringAsFixed(6);
      final lon = pos.longitude.toStringAsFixed(6);
      await StorageService.instance.saveString('gps_last_position', '$lat,$lon');
      await StorageService.instance.saveString('gps_last_sync', DateTime.now().toIso8601String());
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  LocationAccuracy _mapAccuracy(String code) {
    switch (code) {
      case 'high':
        return LocationAccuracy.best;
      case 'low':
        return LocationAccuracy.low;
      case 'balanced':
      default:
        return LocationAccuracy.medium;
    }
  }

  Future<void> _ensurePermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Services de localisation désactivés');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw Exception('Permission localisation refusée');
    }
  }
}
