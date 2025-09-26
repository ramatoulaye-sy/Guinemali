import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:guinemali/core/services/storage_service.dart';

/// Accessibility helper: announces messages via TTS when enabled
class A11yService {
  A11yService._();

  static void announceIfEnabled(BuildContext context, String message) {
    final enabled = StorageService.instance.getBool('a11y_tts_hints', defaultValue: false);
    if (!enabled) return;
    final dir = Directionality.of(context);
    SemanticsService.announce(message, dir);
  }
}


