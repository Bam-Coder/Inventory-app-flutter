import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../../../core/services/cache_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();
  final CacheService _cache = CacheService();

  // État des données
  List<ProductModel> _products = [];
  List<ProductModel> _searchResults = [];
  List<ProductModel> _lowStockProducts = [];
  Map<String, dynamic> _productStats = {};

  // États de chargement
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLoadingLowStock = false;
  bool _isLoadingStats = false;

  // Gestion des erreurs
  String? _error;

  // Getters
  List<ProductModel> get products => _products;
  List<ProductModel> get searchResults => _searchResults;
  List<ProductModel> get lowStockProducts => _lowStockProducts;
  Map<String, dynamic> get productStats => _productStats;
  
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isLoadingLowStock => _isLoadingLowStock;
  bool get isLoadingStats => _isLoadingStats;
  String? get error => _error;

  // Clés de cache
  static const String _productsCacheKey = 'cache_products';
  static const String _statsCacheKey = 'cache_product_stats';

  /// Charge la liste des produits depuis l'API
  Future<void> loadProducts({bool forceRefresh = false}) async {
    // Protection contre les requêtes multiples
    if (_isLoading && !forceRefresh) {
      print('⚠️ Chargement des produits en cours, ignoré');
      return;
    }

    if (forceRefresh) {
      await _cache.removeCache(_productsCacheKey);
    }

    _setLoadingState(true);
    _clearError();

    try {
      _products = await _service.fetchProducts();
      _filterDeletedProducts();
      await _updateProductsCache();
      
      _logProductLoadSuccess();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoadingState(false);
    }
  }

  /// Ajoute un nouveau produit
  Future<void> addProduct(
    String name,
    String category,
    int quantity,
    double price, {
    String? description,
    int? reorderThreshold,
    String? unit,
    String? supplier,
    String? imagePath,
  }) async {
    _setLoadingState(true);
    _clearError();

    try {
      await _service.addProduct(
        name, category, quantity, price,
        description: description,
        reorderThreshold: reorderThreshold,
        unit: unit,
        supplier: supplier,
      );
      
      _addProductLocally(name, category, quantity, price,
        description: description,
        reorderThreshold: reorderThreshold,
        unit: unit,
        supplier: supplier,
        imagePath: imagePath,
      );
      
      // Mise à jour optimisée : pas de rechargement complet
      await _updateProductsCache();
      await _invalidateStatsCache();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoadingState(false);
    }
  }

  /// Met à jour un produit existant
  Future<void> updateProduct(
    String id,
    String name,
    String category,
    int quantity,
    double price, {
    String? description,
    int? reorderThreshold,
    String? unit,
    String? supplier,
    String? imagePath,
  }) async {
    _setLoadingState(true);
    _clearError();

    try {
      await _service.updateProduct(
        id, name, category, quantity, price,
        description: description,
        reorderThreshold: reorderThreshold,
        unit: unit,
        supplier: supplier,
      );
      
      _updateProductLocally(id, name, category, quantity, price,
        description: description,
        reorderThreshold: reorderThreshold,
        unit: unit,
        supplier: supplier,
        imagePath: imagePath,
      );
      
      // Mise à jour optimisée : pas de rechargement complet
      await _updateProductsCache();
      await _invalidateStatsCache();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoadingState(false);
    }
  }

  /// Supprime un produit (soft delete)
  Future<void> deleteProduct(String id) async {
    _setLoadingState(true);
    _clearError();

    try {
      await _service.deleteProduct(id);
      _removeProductLocally(id);
      
      // Mise à jour optimisée
      await _updateProductsCache();
      await _invalidateStatsCache();
    } catch (e) {
      _setError(e.toString());
      // En cas d'erreur, recharger depuis le serveur
      await loadProducts(forceRefresh: true);
    } finally {
      _setLoadingState(false);
    }
  }

  /// Recherche des produits
  Future<void> searchProducts(String query) async {
    // Éviter les requêtes multiples simultanées
    if (_isSearching) {
      print('⚠️ Recherche en cours, ignorée');
      return;
    }

    _setSearchingState(true);
    _clearError();

    try {
      _searchResults = await _service.searchProducts(query);
      _filterDeletedProductsFromSearch();
    } catch (e) {
      _setError(e.toString());
      _searchResults = [];
    } finally {
      _setSearchingState(false);
    }
  }

  /// Charge les produits en stock faible
  Future<void> fetchLowStockProducts() async {
    // Protection contre les requêtes multiples
    if (_isLoadingLowStock) {
      print('⚠️ Chargement stock faible en cours, ignoré');
      return;
    }

    _setLowStockLoadingState(true);
    _clearError();

    try {
      _lowStockProducts = await _service.fetchLowStockProducts();
      _filterDeletedProductsFromLowStock();
      
      if (_lowStockProducts.isEmpty && _products.isNotEmpty) {
        _calculateLowStockLocally();
      }
    } catch (e) {
      _setError(e.toString());
      _calculateLowStockLocally();
    } finally {
      _setLowStockLoadingState(false);
    }
  }

  /// Charge les statistiques des produits
  Future<void> fetchProductStats({bool forceRefresh = false}) async {
    // Protection contre les requêtes multiples
    if (_isLoadingStats && !forceRefresh) {
      print('⚠️ Chargement stats en cours, ignoré');
      return;
    }

    if (forceRefresh) {
      await _cache.removeCache(_statsCacheKey);
    }

    _setStatsLoadingState(true);
    _clearError();

    try {
      _productStats = await _service.fetchProductStats();
      await _cache.setData(_statsCacheKey, _productStats);
    } catch (e) {
      _setError(e.toString());
      _productStats = {};
    } finally {
      _setStatsLoadingState(false);
    }
  }

  // Méthodes utilitaires privées

  void _setLoadingState(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSearchingState(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void _setLowStockLoadingState(bool loading) {
    _isLoadingLowStock = loading;
    notifyListeners();
  }

  void _setStatsLoadingState(bool loading) {
    _isLoadingStats = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _setError(String error) {
    _error = error;
  }

  void _filterDeletedProducts() {
    final beforeCount = _products.length;
    _products = _products.where((product) => !product.isDeleted).toList();
    final afterCount = _products.length;
    
    if (beforeCount != afterCount) {
      print('🚫 ${beforeCount - afterCount} produits supprimés exclus');
    }
  }

  void _filterDeletedProductsFromSearch() {
    _searchResults = _searchResults.where((product) => !product.isDeleted).toList();
  }

  void _filterDeletedProductsFromLowStock() {
    _lowStockProducts = _lowStockProducts.where((product) => !product.isDeleted).toList();
  }

  void _calculateLowStockLocally() {
    _lowStockProducts = _products.where((product) => 
      product.quantity <= product.reorderThreshold && !product.isDeleted
    ).toList();
  }

  void _addProductLocally(String name, String category, int quantity, double price, {
    String? description,
    int? reorderThreshold,
    String? unit,
    String? supplier,
    String? imagePath,
  }) {
    final newProduct = ProductModel(
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
    );
    
    _products.insert(0, newProduct);
  }

  void _updateProductLocally(String id, String name, String category, int quantity, double price, {
    String? description,
    int? reorderThreshold,
    String? unit,
    String? supplier,
    String? imagePath,
  }) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final updatedProduct = _products[index].copyWith(
        name: name,
        category: category,
        quantity: quantity,
        price: price,
        description: description ?? _products[index].description,
        reorderThreshold: reorderThreshold ?? _products[index].reorderThreshold,
        unit: unit ?? _products[index].unit,
        supplier: supplier ?? _products[index].supplier,
        imagePath: imagePath ?? _products[index].imagePath,
        updatedAt: DateTime.now(),
      );
      _products[index] = updatedProduct;
    }
  }

  void _removeProductLocally(String id) {
    _products.removeWhere((product) => product.id == id);
  }

  Future<void> _updateProductsCache() async {
    await _cache.setData(_productsCacheKey, _products.map((p) => p.toJson()).toList());
  }

  Future<void> _invalidateStatsCache() async {
    await _cache.removeCache(_statsCacheKey);
  }

  void _logProductLoadSuccess() {
    print('✅ Produits chargés: ${_products.length} produits');
    if (_products.isNotEmpty) {
      print('📦 Premier produit: ${_products.first.name} (ID: ${_products.first.id})');
    }
  }

  // Méthodes publiques utilitaires

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await _cache.removeCache(_productsCacheKey);
    await _cache.removeCache(_statsCacheKey);
    await loadProducts(forceRefresh: true);
    await fetchProductStats(forceRefresh: true);
  }

  Future<void> forceRefreshProducts() async {
    print('🔄 Forçage du rechargement complet des produits...');
    
    await _cache.clearCache();
    _products.clear();
    _searchResults.clear();
    _lowStockProducts.clear();
    
    await loadProducts(forceRefresh: true);
    print('✅ Rechargement complet terminé');
  }

  Future<void> updateProductPrice(String id, double newPrice) async {
    _setLoadingState(true);
    _clearError();

    try {
      await _service.updateProductPrice(id, newPrice);
      
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        final updatedProduct = _products[index].copyWith(price: newPrice);
        _products[index] = updatedProduct;
      }
      
      await _updateProductsCache();
      await _invalidateStatsCache();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> hardDeleteProduct(String id) async {
    _setLoadingState(true);
    _clearError();

    try {
      await _service.hardDeleteProduct(id);
      _removeProductLocally(id);
      await _updateProductsCache();
      await _invalidateStatsCache();
      print('✅ Produit supprimé définitivement: $id');
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoadingState(false);
    }
  }
}


