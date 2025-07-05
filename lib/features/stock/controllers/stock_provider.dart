// stock_provider.dart
import 'package:flutter/material.dart';
import '../../../core/services/cache_service.dart';
import '../models/stock_log_model.dart';
import '../services/stock_service.dart';
import '../../../core/utils/logger.dart';

class StockProvider extends ChangeNotifier {
  final StockService _service = StockService();
  final CacheService _cache = CacheService();

  List<StockLogModel> _stockLogs = [];
  bool _isLoading = false;
  String? _error;

  List<StockLogModel> _productLogs = [];
  bool _isLoadingProductLogs = false;

  bool _isAdjustingStock = false;
  bool get isAdjustingStock => _isAdjustingStock;

  List<StockLogModel> get stockLogs => _stockLogs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<StockLogModel> get productLogs => _productLogs;
  bool get isLoadingProductLogs => _isLoadingProductLogs;

  static const String _stockCacheKey = 'cache_stock_logs';

  Future<void> loadStockHistory({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _cache.getData(_stockCacheKey);
      if (cached != null) {
        try {
          _stockLogs = (cached as List<dynamic>)
              .map((e) => StockLogModel.fromJson(e as Map<String, dynamic>))
              .toList();
          notifyListeners();
        } catch (e) {
          AppLogger.warning('Erreur lors du chargement du cache: $e');
          // Continuer avec le chargement depuis l'API
        }
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stockLogs = await _service.fetchStockHistory();
      if (_stockLogs.isNotEmpty) {
        await _cache.setData(_stockCacheKey, _stockLogs.map((e) => e.toJson()).toList());
      }
    } catch (e) {
      _error = 'Erreur lors du chargement de l\'historique: ${e.toString()}';
      AppLogger.error('Erreur StockProvider', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addStockEntry(String productId, int quantity, String type, String? notes) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.addStockEntry(productId, quantity, type, notes);
      await loadStockHistory(forceRefresh: true);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addStockIn(String productId, int quantity, String? notes) async {
    await addStockEntry(productId, quantity, 'IN', notes);
  }

  Future<void> addStockOut(String productId, int quantity, String? notes) async {
    await addStockEntry(productId, quantity, 'OUT', notes);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchLogsForProduct(String productId) async {
    _isLoadingProductLogs = true;
    _error = null;
    notifyListeners();

    try {
      _productLogs = await _service.fetchLogsForProduct(productId);
    } catch (e) {
      _error = e.toString();
      _productLogs = [];
    } finally {
      _isLoadingProductLogs = false;
      notifyListeners();
    }
  }

  Future<void> adjustStock(String productId, int newQuantity, String? notes) async {
    _isAdjustingStock = true;
    _error = null;
    notifyListeners();
    try {
      await _service.adjustStock(productId, newQuantity, notes);
      await loadStockHistory(forceRefresh: true);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isAdjustingStock = false;
      notifyListeners();
    }
  }
}