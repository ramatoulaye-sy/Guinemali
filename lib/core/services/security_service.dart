import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AppLockMethod { none, biometrics, pin }

class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  static const MethodChannel _platform = MethodChannel('app.stealth');

  static const String _keyLockMethod = 'app_lock_method';
  static const String _keyPin = 'app_lock_pin';

  Future<AppLockMethod> getLockMethod() async {
    final v = await _secure.read(key: _keyLockMethod);
    switch (v) {
      case 'biometrics':
        return AppLockMethod.biometrics;
      case 'pin':
        return AppLockMethod.pin;
      default:
        return AppLockMethod.none;
    }
  }

  Future<void> setLockMethod(AppLockMethod method) async {
    await _secure.write(key: _keyLockMethod, value: method.name);
  }

  Future<void> savePin(String pin) async {
    await _secure.write(key: _keyPin, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    final saved = await _secure.read(key: _keyPin);
    return saved != null && saved == pin;
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({String reason = 'Déverrouiller Guinèmali'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Tente d'activer/désactiver le mode furtif au niveau système (Android uniquement)
  /// - Masquage icône lanceur / atténuation notifications selon impl native
  /// Retourne true si une implémentation native a confirmé l'action
  Future<bool> setStealthModeSystem(bool enabled) async {
    try {
      final result = await _platform.invokeMethod<bool>('setStealth', {
        'enabled': enabled,
      });
      return result == true;
    } catch (_) {
      return false;
    }
  }
}


