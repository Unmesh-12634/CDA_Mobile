class AppConfig {
  /// Primary Java Spring Boot Backend Host on Wi-Fi (Port 8000)
  static const String javaBackendHost = 'http://192.168.1.92:8000';

  static String activeHost = javaBackendHost;

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
