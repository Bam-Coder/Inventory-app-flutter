// api_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = Constants.apiBaseUrl;
  final StorageService _storage = StorageService();

  static const Duration timeout = Duration(seconds: 30);
  static const Duration rateLimitDelay = Duration(seconds: 2);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    int retryCount = 0,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers).timeout(timeout);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: jsonEncode(data),
          ).timeout(timeout);
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: jsonEncode(data),
          ).timeout(timeout);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers).timeout(timeout);
          break;
        default:
          throw Exception('Méthode HTTP non supportée: $method');
      }

      return _handleResponse(response, method, endpoint, data, retryCount);
    } on SocketException {
      throw Exception('Erreur de connexion réseau');
    } on TimeoutException {
      throw Exception('Délai d\'attente dépassé');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    return _makeRequest('GET', endpoint);
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    return _makeRequest('POST', endpoint, data: data);
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    return _makeRequest('PUT', endpoint, data: data);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    return _makeRequest('DELETE', endpoint);
  }

  Map<String, dynamic> _handleResponse(
    http.Response response,
    String method,
    String endpoint,
    Map<String, dynamic>? data,
    int retryCount,
  ) {
    // Vérifier d'abord si c'est une réponse d'erreur
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleErrorResponse(response, method, endpoint, data, retryCount);
    }

    // Si on arrive ici, c'est une réponse de succès
    if (response.body.isEmpty) {
      return {'success': true};
    }
    
    // Gestion spéciale pour les fichiers CSV
    if (_isCsvResponse(response)) {
      return {'data': response.body};
    }
    
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      // Si le JSON est invalide, retourner le body comme texte
      return {'data': response.body};
    }
  }

  bool _isCsvResponse(http.Response response) {
    return response.headers['content-type']?.contains('text/csv') == true ||
           response.body.trimLeft().startsWith('"name","description"');
  }

  void _handleErrorResponse(
    http.Response response,
    String method,
    String endpoint,
    Map<String, dynamic>? data,
    int retryCount,
  ) {
    final statusCode = response.statusCode;
    
    switch (statusCode) {
      case 401:
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      case 403:
        throw Exception('Accès refusé');
      case 404:
        throw Exception('Ressource non trouvée');
      case 429:
        _handleRateLimitError(method, endpoint, data, retryCount);
        break;
      case >= 500:
        throw Exception('Erreur serveur. Veuillez réessayer plus tard.');
      default:
        _throwParsedError(response);
    }
  }

  void _handleRateLimitError(
    String method,
    String endpoint,
    Map<String, dynamic>? data,
    int retryCount,
  ) async {
    if (retryCount < 3) {
      print('⚠️ Rate limit atteint, nouvelle tentative dans ${rateLimitDelay.inSeconds} secondes...');
      await Future.delayed(rateLimitDelay);
      await _makeRequest(method, endpoint, data: data, retryCount: retryCount + 1);
    } else {
      throw Exception('Trop de requêtes. Veuillez patienter quelques minutes avant de réessayer.');
    }
  }

  void _throwParsedError(http.Response response) {
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(errorData['message'] ?? 'Erreur inconnue');
    } catch (e) {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }
}
// api_service.dart