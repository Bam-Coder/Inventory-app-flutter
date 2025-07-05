import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const Duration defaultExpiry = Duration(minutes: 5);

  Future<void> setData(String key, dynamic data, {Duration? expiry}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'expiry': (expiry ?? defaultExpiry).inMilliseconds,
    };
    await prefs.setString(key, jsonEncode(cacheData));
  }

  Future<dynamic> getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);

    if (cached != null) {
      try {
        final cacheData = jsonDecode(cached);
        final timestamp = DateTime.parse(cacheData['timestamp']);
        final expiry = Duration(milliseconds: cacheData['expiry']);

        if (DateTime.now().difference(timestamp) < expiry) {
          return cacheData['data'];
        } else {
          await prefs.remove(key);
        }
      } catch (e) {
        await prefs.remove(key);
      }
    }
    return null;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> removeCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
} 