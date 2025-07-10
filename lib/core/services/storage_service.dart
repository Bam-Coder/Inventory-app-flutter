import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userDataKey = 'user_data';

  /// Sauvegarde le token d'authentification
  Future<void> saveToken(String token, {String? refreshToken, DateTime? expiry}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      
      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
      }
      
      if (expiry != null) {
        await prefs.setString(_tokenExpiryKey, expiry.toIso8601String());
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du token: $e');
    }
  }

  /// Récupère le token d'authentification
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final expiry = prefs.getString(_tokenExpiryKey);

      if (token != null && expiry != null) {
        try {
          final expiryDate = DateTime.parse(expiry);
          if (DateTime.now().isAfter(expiryDate)) {
            await deleteToken();
            return null;
          }
        } catch (e) {
          // Date d'expiration invalide, supprimer le token
          await deleteToken();
          return null;
        }
      }
      return token;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du token: $e');
    }
  }

  /// Récupère le refresh token
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du refresh token: $e');
    }
  }

  /// Sauvegarde les données utilisateur
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(userData));
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde des données utilisateur: $e');
    }
  }

  /// Récupère les données utilisateur
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userDataKey);
      if (userData != null) {
        try {
          return jsonDecode(userData) as Map<String, dynamic>;
        } catch (e) {
          // Données corrompues, les supprimer
          await prefs.remove(_userDataKey);
          return null;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des données utilisateur: $e');
    }
  }

  /// Supprime le token d'authentification
  Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_tokenExpiryKey);
      await prefs.remove(_userDataKey);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du token: $e');
    }
  }

  /// Efface toutes les données stockées
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Erreur lors de l\'effacement des données: $e');
    }
  }

  /// Vérifie si un token existe
  Future<bool> hasToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_tokenKey);
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si le token est expiré
  Future<bool> isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiry = prefs.getString(_tokenExpiryKey);
      
      if (expiry != null) {
        final expiryDate = DateTime.parse(expiry);
        return DateTime.now().isAfter(expiryDate);
      }
      return false;
    } catch (e) {
      return true;
    }
  }
}

