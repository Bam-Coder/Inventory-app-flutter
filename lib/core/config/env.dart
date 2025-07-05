class Env {
  static Future<void> load() async {
    // Ici tu peux charger des configs dynamiques
    // Exemple : via dotenv ou fichiers locaux
    await Future.delayed(Duration(milliseconds: 100));
  }
}

class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5003',
  );
  
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Inventory Management',
  );
  
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
  
  static const bool isDebug = bool.fromEnvironment(
    'DEBUG',
    defaultValue: true,
  );
  
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );
  
  static const int apiTimeout = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30,
  );
  
  static const int cacheExpiration = int.fromEnvironment(
    'CACHE_EXPIRATION',
    defaultValue: 300, // 5 minutes
  );
}
