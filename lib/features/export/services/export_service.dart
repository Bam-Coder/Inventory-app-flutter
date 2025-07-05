import '../../../core/services/api_service.dart';

class ExportService {
  final ApiService _api = ApiService();

  Future<String> exportProducts() async {
    try {
      final response = await _api.get('/export/products');
      return response['downloadUrl'] as String;
    } catch (e) {
      throw Exception('Erreur lors de l\'export des produits: $e');
    }
  }

  Future<String> exportStockHistory() async {
    try {
      final response = await _api.get('/export/logs');
      return response['downloadUrl'] as String;
    } catch (e) {
      throw Exception('Erreur lors de l\'export de l\'historique de stock: $e');
    }
  }

  Future<String> exportLowStock() async {
    try {
      final response = await _api.get('/export/low-stock');
      return response['downloadUrl'] as String;
    } catch (e) {
      throw Exception('Erreur lors de l\'export des produits en stock faible: $e');
    }
  }

  Future<String> exportStats() async {
    try {
      final response = await _api.get('/export/stats');
      return response['downloadUrl'] as String;
    } catch (e) {
      throw Exception('Erreur lors de l\'export des statistiques: $e');
    }
  }

  Future<String> exportAuditLogs() async {
    try {
      final response = await _api.get('/admin/audit/logs');
      // Pour l'export des logs d'audit, on utilise l'endpoint admin
      return response['downloadUrl'] as String;
    } catch (e) {
      throw Exception('Erreur lors de l\'export des logs d\'audit: $e');
    }
  }
} 