// stock_service.dart
import '../../../core/services/api_service.dart';
import '../models/stock_log_model.dart';
import '../../../core/utils/logger.dart';

class StockService {
  final ApiService _api = ApiService();

  Future<List<StockLogModel>> fetchStockHistory() async {
    try {
      final response = await _api.get('/stock/logs');
      List<dynamic> stockLogsList = [];
      
      if (response['data'] is List) {
        stockLogsList = response['data'] as List<dynamic>;
      } else {
        for (var value in response.values) {
          if (value is List) {
            stockLogsList = value;
            break;
          }
        }
      }
          
      return stockLogsList
          .whereType<Map<String, dynamic>>()
          .map((item) => StockLogModel.fromJson(item))
          .toList();
    } catch (e) {
      AppLogger.error('Erreur lors du chargement de l\'historique des stocks', e);
      return [];
    }
  }

  Future<void> addStockIn(String productId, int quantity, String? notes) async {
    await _api.post('/stock/in', {
      'productId': productId,
      'quantity': quantity,
      'note': notes,
    });
  }

  Future<void> addStockOut(String productId, int quantity, String? notes) async {
    await _api.post('/stock/out', {
      'productId': productId,
      'quantity': quantity,
      'note': notes,
    });
  }

  Future<void> addStockEntry(String productId, int quantity, String type, String? notes) async {
    if (type.toUpperCase() == 'IN') {
      await addStockIn(productId, quantity, notes);
    } else if (type.toUpperCase() == 'OUT') {
      await addStockOut(productId, quantity, notes);
    } else {
      throw Exception('Type de mouvement invalide: $type');
    }
  }

  Future<List<StockLogModel>> fetchLogsForProduct(String productId) async {
    try {
      final response = await _api.get('/stock/logs/$productId');
      List<dynamic> stockLogsList = [];
      
      if (response['data'] is List) {
        stockLogsList = response['data'] as List<dynamic>;
      } else {
        for (var value in response.values) {
          if (value is List) {
            stockLogsList = value;
            break;
          }
        }
      }
          
      return stockLogsList
          .whereType<Map<String, dynamic>>()
          .map((item) => StockLogModel.fromJson(item))
          .toList();
    } catch (e) {
      AppLogger.error('Erreur lors du chargement des logs pour le produit $productId', e);
      return [];
    }
  }

  Future<void> adjustStock(String productId, int newQuantity, String? notes) async {
    await _api.post('/stock/adjust', {
      'productId': productId,
      'newQuantity': newQuantity,
      'note': notes,
    });
  }
}