import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../../../core/services/cache_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();
  final CacheService _cache = CacheService();

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> _searchResults = [];
  bool _isSearching = false;

  List<ProductModel> _lowStockProducts = [];
  bool _isLoadingLowStock = false;

  Map<String, dynamic> _productStats = {};
  bool _isLoadingStats = false;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProductModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  List<ProductModel> get lowStockProducts => _lowStockProducts;
  bool get isLoadingLowStock => _isLoadingLowStock;
  Map<String, dynamic> get productStats => _productStats;
  bool get isLoadingStats => _isLoadingStats;

  static const String _productsCacheKey = 'cache_products';
  static const String _statsCacheKey = 'cache_product_stats';

  Future<void> loadProducts({bool forceRefresh = false}) async {
    print('🔄 Chargement des produits...');
    
    // Toujours forcer le rechargement pour éviter les problèmes de cache
    if (forceRefresh) {
      await _cache.removeCache(_productsCacheKey);
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _service.fetchProducts();
      print('✅ Produits chargés: ${_products.length} produits');
      
      // Debug: afficher les premiers produits
      if (_products.isNotEmpty) {
        print('📦 Premier produit: ${_products.first.name}');
      }
      
      // Mettre à jour le cache avec les nouvelles données
      await _cache.setData(_productsCacheKey, _products.map((p) => p.toJson()).toList());
    } catch (e) {
      _error = e.toString();
      print('❌ Erreur lors du chargement des produits: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(
      String name, String category, int quantity, double price, {
      String? description,
      int? reorderThreshold,
      String? unit,
      String? supplier,
      String? imagePath,
    }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.addProduct(name, category, quantity, price,
        description: description,
        reorderThreshold: reorderThreshold,
        unit: unit,
        supplier: supplier,
      );
      
      // Ajout local du produit avec TOUS les champs
      _products.insert(0, ProductModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description ?? '',
        quantity: quantity,
        price: price,
        reorderThreshold: reorderThreshold ?? 5,
        unit: unit ?? 'pièce',
        category: category,
        supplier: supplier ?? '',
        addedBy: '',
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imagePath: imagePath,
      ));
      
      await _cache.removeCache(_productsCacheKey);
      await _cache.removeCache(_statsCacheKey);
      await loadProducts(forceRefresh: true);
      await fetchProductStats(forceRefresh: true);
    } catch (e) {
      _error = e.toString();
      print('❌ Erreur lors de l\'ajout du produit: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct(String id, String name, String category, int quantity, double price) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateProduct(id, name, category, quantity, price);
      await _cache.removeCache(_productsCacheKey);
      await _cache.removeCache(_statsCacheKey);
      await loadProducts(forceRefresh: true);
      await fetchProductStats(forceRefresh: true);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteProduct(id);
      await _cache.removeCache(_productsCacheKey);
      await _cache.removeCache(_statsCacheKey);
      await loadProducts(forceRefresh: true);
      await fetchProductStats(forceRefresh: true);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> searchProducts(String query) async {
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _service.searchProducts(query);
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  Future<void> fetchLowStockProducts() async {
    _isLoadingLowStock = true;
    _error = null;
    notifyListeners();

    try {
      _lowStockProducts = await _service.fetchLowStockProducts();
    } catch (e) {
      _error = e.toString();
      _lowStockProducts = [];
    } finally {
      _isLoadingLowStock = false;
      notifyListeners();
    }
  }

  Future<void> fetchProductStats({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await _cache.removeCache(_statsCacheKey);
    }

    _isLoadingStats = true;
    _error = null;
    notifyListeners();

    try {
      _productStats = await _service.fetchProductStats();
      await _cache.setData(_statsCacheKey, _productStats);
    } catch (e) {
      _error = e.toString();
      _productStats = {};
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  // Méthode pour forcer le rechargement complet
  Future<void> refreshAll() async {
    await _cache.removeCache(_productsCacheKey);
    await _cache.removeCache(_statsCacheKey);
    await loadProducts(forceRefresh: true);
    await fetchProductStats(forceRefresh: true);
  }

  Future<void> updateProductPrice(String id, double newPrice) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateProductPrice(id, newPrice);
      
      // Mettre à jour localement le produit
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        final updatedProduct = _products[index].copyWith(price: newPrice);
        _products[index] = updatedProduct;
      }
      
      await _cache.removeCache(_productsCacheKey);
      await _cache.removeCache(_statsCacheKey);
      
    } catch (e) {
      _error = e.toString();
      print('❌ Erreur dans ProductProvider.updateProductPrice: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
