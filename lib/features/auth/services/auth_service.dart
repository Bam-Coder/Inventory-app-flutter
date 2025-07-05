import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/constants.dart';
import '../../../core/utils/logger.dart';

class AuthService {
  final String baseUrl = Constants.apiBaseUrl;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Réponse vide du serveur');
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = data['data'] as Map<String, dynamic>;
        return userData;
      } else {
        _handleErrorResponse(response);
        throw Exception('Erreur inattendue');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Format de réponse invalide');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(String name, String businessName, String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/auth/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "businessName": businessName,
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 201) {
        if (response.body.isEmpty) {
          throw Exception('Réponse vide du serveur');
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = data['data'] as Map<String, dynamic>;
        return userData;
      } else {
        // Afficher le message d'erreur du backend s'il existe
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final message = errorData['message'] ?? 'Erreur inconnue';
          throw Exception(message);
        } catch (e) {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Format de réponse invalide');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final url = Uri.parse('$baseUrl/auth/profile');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>;
      } else {
        _handleErrorResponse(response);
        throw Exception('Erreur inattendue');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Format de réponse invalide');
      }
      rethrow;
    }
  }

  Future<void> updateProfile(String token, String name, String email) async {
    try {
      final url = Uri.parse('$baseUrl/auth/profile');
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
        }),
      );
      
      if (response.statusCode != 200) {
        _handleErrorResponse(response);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Format de réponse invalide');
      }
      rethrow;
    }
  }

  Future<void> changePassword(String token, String oldPassword, String newPassword) async {
    try {
      final url = Uri.parse('$baseUrl/auth/password');
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      
      if (response.statusCode != 200) {
        _handleErrorResponse(response);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Format de réponse invalide');
      }
      rethrow;
    }
  }

  void _handleErrorResponse(http.Response response) {
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      final message = errorData['message'] ?? 'Erreur inconnue';
      AppLogger.error('Erreur API: ${response.statusCode} - $message');
      throw Exception(message);
    } catch (e) {
      if (e is FormatException) {
        final errorMsg = 'Erreur serveur: ${response.statusCode}';
        AppLogger.error('Erreur de format: $errorMsg');
        throw Exception(errorMsg);
      }
      rethrow;
    }
  }
}
