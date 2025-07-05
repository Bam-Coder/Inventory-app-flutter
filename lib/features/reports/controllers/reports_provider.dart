import 'package:flutter/material.dart';
import '../../products/models/product_model.dart';
import '../../../core/services/storage_service.dart';

class ReportsProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  int totalProducts = 0;
  int totalItems = 0;
  int lowStock = 0;
  int categories = 0;
  Map<String, int> categoryDistribution = {};
  bool isLoading = false;
  String? errorMessage;
  List<ProductModel> lowStockProducts = [];

  Future<void> fetchReports() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Token manquant');
      // Appelle l'endpoint stats
      // final stats = await _productService.getStats(token);
      // totalProducts = stats['totalProducts'];
      // totalItems = stats['totalItems'];
      // lowStock = stats['lowStock'];
      // categories = stats['categories'];
      // categoryDistribution = stats['categoryDistribution'];
      // lowStockProducts = await _productService.getLowStockProducts(token);
      // (À adapter selon la réponse réelle de l'API)
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
} 