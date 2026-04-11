import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:project_mobile_pdam/core/utils/debug_log.dart';

class AppConfig {
  static bool _initialized = false;

  static late final String environment;
  static late final String backendDomain;
  static late final String baseStorageUrl;
  static late final String googleMapsApiKey;

  static Future<void> init() async {
    if (_initialized) return;

    await dotenv.load(fileName: ".env");

    environment = dotenv.env['ENVIRONMENT'] ?? 'development';
    backendDomain = dotenv.env['BACKEND_DOMAIN'] ?? '';
    baseStorageUrl = dotenv.env['BACKEND_URL'] ?? '$backendDomain/storage/';
    googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API'] ?? '';

    _initialized = true;

    DebugLog.info(message: "AppConfig initialized: ${toJson()}");
    DebugLog.info(message: "BACKEND_DOMAIN: $backendDomain");
  }

  static Map<String, dynamic> toMap() {
    return {
      'environment': environment,
      'backendDomain': backendDomain,
      'googleMapsApiKey': googleMapsApiKey.isNotEmpty ? '***' : 'NOT SET',
    };
  }

  static String toJson() {
    return jsonEncode(toMap());
  }

  static void logConfig() {
    DebugLog.info(message: "AppConfig: ${toJson()}");
  }
}
