class AppConfig {
  /// Base Production Render URL for FastAPI Backend
  static const String defaultProductionHost = 'https://cda-ai-interview-engine.onrender.com';

  /// Environment-aware API Base URL
  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl.endsWith('/') ? '${envUrl}api/v1' : '$envUrl/api/v1';
    }
    return '$defaultProductionHost/api/v1';
  }

  /// Direct Root Host URL for ping & health checks
  static String get rootHost {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;
    return defaultProductionHost;
  }
}
