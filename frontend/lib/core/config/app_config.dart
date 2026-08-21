import 'package:flutter/foundation.dart';

class AppConfig {
  /// USB Reverse Port Forwarding & Localhost (Port 8000 for Python AI Engine, 8080 for Backend)
  static const String usbLocalhost8000 = 'http://127.0.0.1:8000';
  static const String usbLocalhost8005 = 'http://127.0.0.1:8005';
  static const String usbLocalhost8080 = 'http://127.0.0.1:8080';

  /// Primary Wi-Fi IP address of host computer
  static const String defaultWifiHostPort8000 = 'http://192.168.1.129:8000';
  static const String defaultWifiHostPort8080 = 'http://192.168.1.129:8080';
  static const String hotspotHostPort8000 = 'http://192.168.137.1:8000';
  static const String hotspotHostPort8080 = 'http://192.168.137.1:8080';
  static const String emulatorHostPort8000 = 'http://10.0.2.2:8000';
  static const String emulatorHostPort8080 = 'http://10.0.2.2:8080';

  static const List<String> candidateHosts = [
    usbLocalhost8080,
    usbLocalhost8000,
    usbLocalhost8005,
    defaultWifiHostPort8000,
    defaultWifiHostPort8080,
    hotspotHostPort8000,
    hotspotHostPort8080,
    emulatorHostPort8000,
    emulatorHostPort8080,
  ];

  static String activeHost = usbLocalhost8080;


  static void setActiveHost(String newHost) {
    var cleaned = newHost.trim();
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    activeHost = cleaned;
    debugPrint('🌐 AppConfig activeHost set to: $activeHost');
  }

  /// Environment-aware API Base URL
  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl.endsWith('/') ? '${envUrl}api/v1' : '$envUrl/api/v1';
    }
    return activeHost.endsWith('/') ? '${activeHost}api/v1' : '$activeHost/api/v1';
  }

  /// Direct Root Host URL for ping & health checks
  static String get rootHost {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;
    return activeHost;
  }
}
