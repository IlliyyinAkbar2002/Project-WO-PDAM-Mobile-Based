import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_intern_pdam/core/utils/debug_log.dart';

class AppConfig {
  // Use safe getters so the app won't crash if dotenv hasn't been loaded
  static String _getEnv(String key, String fallback) {
    try {
      // flutter_dotenv exposes a safe "isInitialized" flag
      if (dotenv.isInitialized) {
        return dotenv.env[key] ?? fallback;
      }
    } catch (_) {
      // ignore: avoiding crash when dotenv throws NotInitializedError
    }
    return fallback;
  }

  static final String environment = _getEnv('ENVIRONMENT', 'development');
  // Use default backend domain if not provided in .env
  static final String backendDomain = _getEnv(
    'BACKEND_DOMAIN',
    'http://192.168.1.2:8080',
    // 'http://172.30.4.100:8080',
  );
  static final String baseStorageUrl = _getEnv(
    'BACKEND_URL',
    '$backendDomain/storage/',
  );

  // Google Maps API Key - safe getter with fallback
  static String get googleMapsApiKey => _getEnv(
    'GOOGLE_MAPS_API',
    'AIzaSyBmtfPnRIbGAAXra-XJOMQJ1fekZzLAyk4', // fallback to local.properties value
  );

  static Map<String, dynamic> toMap() {
    return {'environment': environment};
  }

  static String toJson() {
    return jsonEncode(toMap());
  }

  static void logConfig() {
    DebugLog.info(message: "AppConfig: ${toJson()}");
  }
}
