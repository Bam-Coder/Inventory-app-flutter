import 'package:flutter/material.dart';
import '../../stock/models/stock_log_model.dart';
import '../../../core/services/storage_service.dart';

class DashboardProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  int totalProducts = 0;
  int totalItems = 0;
  int lowStock = 0;
  List<StockLogModel> recentActivity = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Token manquant');
      // Appelle les endpoints stats, low-stock, etc.
      // Exemples :
      // final stats = await _productService.getStats(token);
      // totalProducts = stats['totalProducts'];
      // totalItems = stats['totalItems'];
      // lowStock = stats['lowStock'];
      // recentActivity = await _stockService.getRecentLogs(token);
      // (À adapter selon les endpoints exacts)
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
} 