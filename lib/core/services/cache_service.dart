import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const Duration defaultExpiry = Duration(minutes: 5);
  static const Duration longExpiry = Duration(minutes: 30);

  /// Sauvegarde des données dans le cache
  Future<void> setData(String key, dynamic data, {Duration? expiry}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'expiry': (expiry ?? defaultExpiry).inMilliseconds,
      };
      await prefs.setString(key, jsonEncode(cacheData));
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde en cache: $e');
    }
  }

  /// Récupère des données du cache
  Future<dynamic> getData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);

      if (cached != null) {
        try {
          final cacheData = jsonDecode(cached) as Map<String, dynamic>;
          final timestamp = DateTime.parse(cacheData['timestamp'] as String);
          final expiry = Duration(milliseconds: cacheData['expiry'] as int);

          if (DateTime.now().difference(timestamp) < expiry) {
            return cacheData['data'];
          } else {
            await prefs.remove(key);
          }
        } catch (e) {
          // Cache corrompu, le supprimer
          await prefs.remove(key);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du cache: $e');
    }
  }

  /// Efface tout le cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'effacement du cache: $e');
    }
  }

  /// Supprime une clé spécifique du cache
  Future<void> removeCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du cache: $e');
    }
  }

  /// Vérifie si une clé existe dans le cache
  Future<bool> hasData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  /// Récupère la taille du cache
  Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      return keys.where((key) => key.startsWith('cache_')).length;
    } catch (e) {
      return 0;
    }
  }

  /// Nettoie le cache expiré
  Future<void> cleanExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          final cached = prefs.getString(key);
          if (cached != null) {
            try {
              final cacheData = jsonDecode(cached) as Map<String, dynamic>;
              final timestamp = DateTime.parse(cacheData['timestamp'] as String);
              final expiry = Duration(milliseconds: cacheData['expiry'] as int);

              if (DateTime.now().difference(timestamp) >= expiry) {
                await prefs.remove(key);
              }
            } catch (e) {
              // Cache corrompu, le supprimer
              await prefs.remove(key);
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Erreur lors du nettoyage du cache: $e');
    }
  }
} 