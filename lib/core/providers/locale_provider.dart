import 'package:flutter/material.dart';
import 'package:guinemali/core/services/storage_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _keyAppLocale = 'app_locale';

  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> initialize() async {
    try {
      final saved = StorageService.instance.getString(_keyAppLocale);
      if (saved != null && saved.isNotEmpty) {
        final parts = saved.split('-');
        if (parts.length == 2) {
          _locale = Locale(parts[0], parts[1]);
        } else if (parts.isNotEmpty) {
          _locale = Locale(parts[0]);
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    if (locale == null) {
      await StorageService.instance.remove(_keyAppLocale);
    } else {
      final value = locale.countryCode != null && locale.countryCode!.isNotEmpty
          ? '${locale.languageCode}-${locale.countryCode}'
          : locale.languageCode;
      await StorageService.instance.saveString(_keyAppLocale, value);
    }
    notifyListeners();
  }
}
