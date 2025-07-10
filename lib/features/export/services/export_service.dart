import '../../../core/services/api_service.dart';

class ExportService {
  final ApiService _api = ApiService();

  Future<String> exportProducts() async {
    try {
      print('🔄 Export des produits en cours...');
      final response = await _api.get('/export/products');
      print('✅ Réponse export produits reçue: $response');
      
      return _processResponse(response);
      
    } catch (e) {
      print('❌ Erreur export produits: $e');
      throw Exception('Erreur lors de l\'export des produits: $e');
    }
  }

  Future<String> exportStockHistory() async {
    try {
      print('🔄 Export de l\'historique des stocks en cours...');
      final response = await _api.get('/export/stock-logs');
      print('✅ Réponse export historique reçue: $response');
      
      return _processResponse(response);
      
    } catch (e) {
      print('❌ Erreur export historique: $e');
      throw Exception('Erreur lors de l\'export de l\'historique de stock: $e');
    }
  }

  Future<String> exportLowStock() async {
    try {
      print('🔄 Export des produits en stock faible en cours...');
      final response = await _api.get('/export/low-stock');
      print('✅ Réponse export stock faible reçue: $response');
      
      return _processResponse(response);
      
    } catch (e) {
      print('❌ Erreur export stock faible: $e');
      throw Exception('Erreur lors de l\'export des produits en stock faible: $e');
    }
  }

  Future<String> exportStats() async {
    try {
      print('🔄 Export des statistiques en cours...');
      final response = await _api.get('/export/stats');
      print('✅ Réponse export stats reçue: $response');
      
      return _processResponse(response);
      
    } catch (e) {
      print('❌ Erreur export stats: $e');
      throw Exception('Erreur lors de l\'export des statistiques: $e');
    }
  }

  Future<String> exportAuditLogs() async {
    try {
      print('🔄 Export des logs d\'audit en cours...');
      final response = await _api.get('/admin/audit/logs');
      print('✅ Réponse export audit reçue: $response');
      
      return _processResponse(response);
      
    } catch (e) {
      print('❌ Erreur export audit: $e');
      throw Exception('Erreur lors de l\'export des logs d\'audit: $e');
    }
  }

  String _processResponse(dynamic response) {
    print('🔍 Traitement de la réponse de type: ${response.runtimeType}');
    
    // Si c'est un Map
    if (response is Map<String, dynamic>) {
      // Chercher downloadUrl
      if (response.containsKey('downloadUrl') && response['downloadUrl'] != null) {
        return response['downloadUrl'].toString();
      }
      
      // Chercher data
      if (response.containsKey('data') && response['data'] != null) {
        final data = response['data'];
        if (data is String) {
          return 'data:text/csv;charset=utf-8,${Uri.encodeComponent(data)}';
        }
      }
      
      // Chercher csv
      if (response.containsKey('csv') && response['csv'] != null) {
        return 'data:text/csv;charset=utf-8,${Uri.encodeComponent(response['csv'].toString())}';
      }
      
      // Si on a une clé qui contient du CSV
      for (var entry in response.entries) {
        if (entry.value is String && entry.value.toString().contains(',')) {
          return 'data:text/csv;charset=utf-8,${Uri.encodeComponent(entry.value.toString())}';
        }
      }
    }
    
    // Si c'est une String
    if (response is String) {
      if (response.startsWith('http')) {
        return response;
      }
      if (response.contains(',')) {
        return 'data:text/csv;charset=utf-8,${Uri.encodeComponent(response)}';
      }
    }
    
    // Si on arrive ici, on ne sait pas traiter
    print('❌ Format de réponse non reconnu: $response');
    throw Exception('Format de réponse non supporté: ${response.runtimeType}');
  }

  Future<bool> testExportEndpoints() async {
    try {
      await _api.get('/export/products');
      return true;
    } catch (e) {
      print('❌ Test des endpoints d\'export échoué: $e');
      return false;
    }
  }
} 