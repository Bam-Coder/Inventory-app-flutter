import 'package:flutter/material.dart';
import '../models/stock_log_model.dart';
import '../services/stock_service.dart';
import '../../../core/services/storage_service.dart';

class StockLogProvider extends ChangeNotifier {
  final StockService _stockService = StockService();
  final StorageService _storageService = StorageService();

  List<StockLogModel> logs = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchLogs(String productId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Token manquant');
      logs = await _stockService.fetchLogsForProduct(productId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
} 