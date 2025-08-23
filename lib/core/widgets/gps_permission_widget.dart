import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:guinemali/core/constants/app_constants.dart';

/// Widget pour gérer les permissions GPS avec guidance utilisateur améliorée
class GpsPermissionWidget extends StatefulWidget {
  final VoidCallback? onPermissionGranted;
  final bool showAsCard;
  final String? customMessage;

  const GpsPermissionWidget({
    super.key,
    this.onPermissionGranted,
    this.showAsCard = true,
    this.customMessage,
  });

  @override
  State<GpsPermissionWidget> createState() => _GpsPermissionWidgetState();
}

class _GpsPermissionWidgetState extends State<GpsPermissionWidget> {
  LocationPermission? _currentPermission;
  bool _isChecking = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermission();
  }

  Future<void> _checkCurrentPermission() async {
    setState(() => _isChecking = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (mounted) {
        setState(() {
          _currentPermission = permission;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (mounted) {
        setState(() {
          _currentPermission = permission;
          _isRequesting = false;
        });
        
        if (permission == LocationPermission.whileInUse || 
            permission == LocationPermission.always) {
          widget.onPermissionGranted?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  Future<void> _openAppSettings() async {
    try {
      HapticFeedback.mediumImpact();
      await openAppSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir les réglages: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _openLocationSettings() async {
    try {
      HapticFeedback.mediumImpact();
      await Geolocator.openLocationSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir les réglages de localisation: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildPermissionContent() {
    if (_isChecking) {
      return const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Vérification des permissions...'),
        ],
      );
    }

    switch (_currentPermission) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return Row(
          children: [
            Icon(Icons.location_on, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'GPS activé - Localisation disponible',
                style: TextStyle(color: Colors.green.shade700),
              ),
            ),
          ],
        );

      case LocationPermission.denied:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_off, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Permission GPS refusée',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'La localisation est nécessaire pour votre sécurité. Veuillez autoriser l\'accès.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRequesting ? null : _requestPermission,
                icon: _isRequesting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.location_on, size: 16),
                label: Text(_isRequesting ? 'Demande...' : 'Autoriser GPS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                ),
              ),
            ),
          ],
        );

      case LocationPermission.deniedForever:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_off, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Permission GPS refusée définitivement',
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.customMessage ?? 
              'La localisation est bloquée. Vous devez l\'activer manuellement dans les réglages.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openAppSettings,
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Réglages App'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openLocationSettings,
                    icon: const Icon(Icons.location_on, size: 16),
                    label: const Text('GPS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '💡 Conseil: Activez d\'abord la localisation dans les réglages système, puis revenez dans l\'app',
              style: TextStyle(
                fontSize: 11, 
                color: Colors.blue.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );

      default:
        return const Text('État des permissions inconnu');
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildPermissionContent();
    
    if (widget.showAsCard) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gps_fixed, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Statut GPS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              content,
            ],
          ),
        ),
      );
    }
    
    return content;
  }
}
