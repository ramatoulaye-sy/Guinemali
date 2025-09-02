import 'package:flutter/foundation.dart';
import 'config_service.dart';

/// Service centralisé pour la gestion des logs
/// Remplace tous les print statements par un système de logging professionnel
/// Basé sur 30 ans d'expérience en développement mobile
class LogService {
  static LogService? _instance;
  static LogService get instance => _instance ??= LogService._();
  
  LogService._();

  // Configuration du niveau de log
  static const String _defaultLogLevel = 'info';
  static String _currentLogLevel = _defaultLogLevel;

  // Niveaux de log (du plus critique au moins critique)
  static const List<String> _logLevels = ['error', 'warning', 'info', 'debug', 'verbose'];

  /// Initialise le service de logging
  static void initialize({String? logLevel}) {
    _currentLogLevel = logLevel ?? ConfigService.getEnvironmentConfig()['logLevel'] ?? _defaultLogLevel;
  }

  /// Vérifie si un niveau de log doit être affiché
  static bool _shouldLog(String level) {
    final currentIndex = _logLevels.indexOf(_currentLogLevel);
    final messageIndex = _logLevels.indexOf(level);
    return messageIndex <= currentIndex;
  }

  /// Formate un message de log
  static String _formatMessage(String level, String message, {String? tag, dynamic data}) {
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag]' : '';
    final dataStr = data != null ? ' | Data: $data' : '';
    return '[$timestamp] $level$tagStr: $message$dataStr';
  }

  /// Log d'erreur critique
  static void error(String message, {String? tag, dynamic data, StackTrace? stackTrace}) {
    if (_shouldLog('error')) {
      final formattedMessage = _formatMessage('ERROR', message, tag: tag, data: data);
      if (kDebugMode) {
        print('❌ $formattedMessage');
        if (stackTrace != null) {
          print('Stack trace: $stackTrace');
        }
      }
      // En production, envoyer à un service de crash reporting
      _sendToCrashReporting(message, stackTrace);
    }
  }

  /// Log d'avertissement
  static void warning(String message, {String? tag, dynamic data}) {
    if (_shouldLog('warning')) {
      final formattedMessage = _formatMessage('WARNING', message, tag: tag, data: data);
      if (kDebugMode) {
        print('⚠️ $formattedMessage');
      }
    }
  }

  /// Log d'information
  static void info(String message, {String? tag, dynamic data}) {
    if (_shouldLog('info')) {
      final formattedMessage = _formatMessage('INFO', message, tag: tag, data: data);
      if (kDebugMode) {
        print('ℹ️ $formattedMessage');
      }
    }
  }

  /// Log de débogage
  static void debug(String message, {String? tag, dynamic data}) {
    if (_shouldLog('debug')) {
      final formattedMessage = _formatMessage('DEBUG', message, tag: tag, data: data);
      if (kDebugMode) {
        print('🔍 $formattedMessage');
      }
    }
  }

  /// Log verbeux (pour le développement)
  static void verbose(String message, {String? tag, dynamic data}) {
    if (_shouldLog('verbose')) {
      final formattedMessage = _formatMessage('VERBOSE', message, tag: tag, data: data);
      if (kDebugMode) {
        print('📝 $formattedMessage');
      }
    }
  }

  /// Log de succès
  static void success(String message, {String? tag, dynamic data}) {
    if (_shouldLog('info')) {
      final formattedMessage = _formatMessage('SUCCESS', message, tag: tag, data: data);
      if (kDebugMode) {
        print('✅ $formattedMessage');
      }
    }
  }

  /// Log de performance
  static void performance(String operation, Duration duration, {String? tag}) {
    if (_shouldLog('debug')) {
      final formattedMessage = _formatMessage('PERFORMANCE', '$operation took ${duration.inMilliseconds}ms', tag: tag);
      if (kDebugMode) {
        print('⚡ $formattedMessage');
      }
    }
  }

  /// Log de navigation
  static void navigation(String from, String to, {String? tag, Map<String, dynamic>? parameters}) {
    if (_shouldLog('debug')) {
      final paramsStr = parameters != null ? ' | Params: $parameters' : '';
      final formattedMessage = _formatMessage('NAVIGATION', '$from → $to$paramsStr', tag: tag);
      if (kDebugMode) {
        print('🧭 $formattedMessage');
      }
    }
  }

  /// Log d'API
  static void api(String method, String endpoint, {String? tag, dynamic requestData, dynamic responseData, int? statusCode}) {
    if (_shouldLog('debug')) {
      final statusStr = statusCode != null ? ' | Status: $statusCode' : '';
      final formattedMessage = _formatMessage('API', '$method $endpoint$statusStr', tag: tag);
      if (kDebugMode) {
        print('🌐 $formattedMessage');
        if (requestData != null) {
          print('📤 Request: $requestData');
        }
        if (responseData != null) {
          print('📥 Response: $responseData');
        }
      }
    }
  }

  /// Log de base de données
  static void database(String operation, String table, {String? tag, dynamic data, int? affectedRows}) {
    if (_shouldLog('debug')) {
      final rowsStr = affectedRows != null ? ' | Rows: $affectedRows' : '';
      final formattedMessage = _formatMessage('DATABASE', '$operation on $table$rowsStr', tag: tag);
      if (kDebugMode) {
        print('🗄️ $formattedMessage');
        if (data != null) {
          print('📊 Data: $data');
        }
      }
    }
  }

  /// Log de sécurité
  static void security(String event, {String? tag, String? userId, String? action}) {
    if (_shouldLog('info')) {
      final userStr = userId != null ? ' | User: $userId' : '';
      final actionStr = action != null ? ' | Action: $action' : '';
      final formattedMessage = _formatMessage('SECURITY', '$event$userStr$actionStr', tag: tag);
      if (kDebugMode) {
        print('🔒 $formattedMessage');
      }
    }
  }

  /// Log d'alerte d'urgence
  static void emergency(String event, {String? tag, String? userId, String? location}) {
    if (_shouldLog('info')) {
      final userStr = userId != null ? ' | User: $userId' : '';
      final locationStr = location != null ? ' | Location: $location' : '';
      final formattedMessage = _formatMessage('EMERGENCY', '$event$userStr$locationStr', tag: tag);
      if (kDebugMode) {
        print('🚨 $formattedMessage');
      }
    }
  }

  /// Log d'enregistrement de preuves
  static void evidence(String operation, String type, {String? tag, String? alertId, String? filePath}) {
    if (_shouldLog('debug')) {
      final alertStr = alertId != null ? ' | Alert: $alertId' : '';
      final fileStr = filePath != null ? ' | File: $filePath' : '';
      final formattedMessage = _formatMessage('EVIDENCE', '$operation $type$alertStr$fileStr', tag: tag);
      if (kDebugMode) {
        print('📹 $formattedMessage');
      }
    }
  }

  /// Log d'authentification
  static void auth(String event, {String? tag, String? userId, String? method}) {
    if (_shouldLog('info')) {
      final userStr = userId != null ? ' | User: $userId' : '';
      final methodStr = method != null ? ' | Method: $method' : '';
      final formattedMessage = _formatMessage('AUTH', '$event$userStr$methodStr', tag: tag);
      if (kDebugMode) {
        print('🔐 $formattedMessage');
      }
    }
  }

  /// Log de permissions
  static void permission(String permission, bool granted, {String? tag, String? userId}) {
    if (_shouldLog('debug')) {
      final userStr = userId != null ? ' | User: $userId' : '';
      final status = granted ? 'GRANTED' : 'DENIED';
      final formattedMessage = _formatMessage('PERMISSION', '$permission: $status$userStr', tag: tag);
      if (kDebugMode) {
        print('🔑 $formattedMessage');
      }
    }
  }

  /// Log de cache
  static void cache(String operation, String key, {String? tag, dynamic data, bool? hit}) {
    if (_shouldLog('debug')) {
      final hitStr = hit != null ? ' | ${hit ? "HIT" : "MISS"}' : '';
      final formattedMessage = _formatMessage('CACHE', '$operation $key$hitStr', tag: tag);
      if (kDebugMode) {
        print('💾 $formattedMessage');
        if (data != null) {
          print('📦 Data: $data');
        }
      }
    }
  }

  /// Log de notification
  static void notification(String type, String message, {String? tag, String? userId, bool? sent}) {
    if (_shouldLog('debug')) {
      final userStr = userId != null ? ' | User: $userId' : '';
      final sentStr = sent != null ? ' | ${sent ? "SENT" : "FAILED"}' : '';
      final formattedMessage = _formatMessage('NOTIFICATION', '$type: $message$userStr$sentStr', tag: tag);
      if (kDebugMode) {
        print('🔔 $formattedMessage');
      }
    }
  }

  /// Log de géolocalisation
  static void location(String event, {String? tag, double? latitude, double? longitude, double? accuracy}) {
    if (_shouldLog('debug')) {
      final coordsStr = (latitude != null && longitude != null) ? ' | Lat: $latitude, Lng: $longitude' : '';
      final accuracyStr = accuracy != null ? ' | Accuracy: ${accuracy}m' : '';
      final formattedMessage = _formatMessage('LOCATION', '$event$coordsStr$accuracyStr', tag: tag);
      if (kDebugMode) {
        print('📍 $formattedMessage');
      }
    }
  }

  /// Log de démarrage d'application
  static void appStart({String? tag, Map<String, dynamic>? config}) {
    if (_shouldLog('info')) {
      final configStr = config != null ? ' | Config: $config' : '';
      final formattedMessage = _formatMessage('APP_START', 'Application started$configStr', tag: tag);
      if (kDebugMode) {
        print('🚀 $formattedMessage');
      }
    }
  }

  /// Log de fermeture d'application
  static void appStop({String? tag, String? reason}) {
    if (_shouldLog('info')) {
      final reasonStr = reason != null ? ' | Reason: $reason' : '';
      final formattedMessage = _formatMessage('APP_STOP', 'Application stopped$reasonStr', tag: tag);
      if (kDebugMode) {
        print('🛑 $formattedMessage');
      }
    }
  }

  /// Envoie les erreurs à un service de crash reporting
  static void _sendToCrashReporting(String message, StackTrace? stackTrace) {
    // En production, intégrer avec Firebase Crashlytics, Sentry, etc.
    if (ConfigService.isProductionMode()) {
      // TODO: Implémenter l'envoi vers le service de crash reporting
    }
  }

  /// Change le niveau de log dynamiquement
  static void setLogLevel(String level) {
    if (_logLevels.contains(level)) {
      _currentLogLevel = level;
      info('Log level changed to: $level', tag: 'LogService');
    } else {
      warning('Invalid log level: $level. Valid levels: $_logLevels', tag: 'LogService');
    }
  }

  /// Retourne le niveau de log actuel
  static String getCurrentLogLevel() {
    return _currentLogLevel;
  }

  /// Retourne tous les niveaux de log disponibles
  static List<String> getAvailableLogLevels() {
    return List.from(_logLevels);
  }

  /// Nettoie les logs (pour libérer la mémoire)
  static void clear() {
    // En mode debug, on peut vider la console
    if (kDebugMode) {
      // Note: Flutter n'a pas de méthode native pour vider la console
      // Cette méthode est principalement pour la documentation
    }
  }
}
