import 'env.dart';

class Constants {
  static const String apiBaseUrl = Environment.apiBaseUrl;
  static const String appName = Environment.appName;
  static const String appVersion = Environment.appVersion;
  static const bool isDebug = Environment.isDebug;
  static const bool enableLogging = Environment.enableLogging;
  static const int apiTimeout = Environment.apiTimeout;
  static const int cacheExpiration = Environment.cacheExpiration;
}
