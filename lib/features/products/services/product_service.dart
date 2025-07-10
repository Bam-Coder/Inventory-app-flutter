import '../../../core/services/api_service.dart';
import '../models/product_model.dart';

class ProductService {
  final ApiService _api = ApiService();

  /// Récupère tous les produits
  Future<List<ProductModel>> fetchProducts() async {
    try {
      final data = await _api.get('/products');
      final List<dynamic> list = data['data'] as List<dynamic>;
      final products = list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      
      return _filterDeletedProducts(products);
    } catch (e) {
      rethrow;
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
  }) async {
    try {
      final productData = _buildProductData(
        name: name,
        category: category,
        quantity: quantity,
        price: price,
        description: description,
        reorderThreshold: reorderThreshold,
        unit: unit,
        supplier: supplier,
      );
      
      await _api.post('/products', productData);
    } catch (e) {
      rethrow;
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
  }) async {
    try {
      final productData = _buildProductData(
        name: name,
        category: category,
        quantity: quantity,
        price: price,
        description: description,
        reorderThreshold: reorderThreshold,
        unit: unit,
        supplier: supplier,
      );
      
      await _api.put('/products/$id', productData);
    } catch (e) {
      rethrow;
    }
  }

  /// Supprime un produit (soft delete)
  Future<void> deleteProduct(String id) async {
    try {
      await _api.delete('/products/$id');
    } catch (e) {
      rethrow;
    }
  }

  /// Recherche des produits
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final data = await _api.get('/products/search?q=$query');
      final List<dynamic> list = data['data'] as List<dynamic>;
      final products = list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      
      return _filterDeletedProducts(products);
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère les produits en stock faible
  Future<List<ProductModel>> fetchLowStockProducts() async {
    try {
      final data = await _api.get('/products/low-stock');
      final List<dynamic> list = data['data'] as List<dynamic>;
      final products = list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      
      return _filterDeletedProducts(products);
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère les statistiques des produits
  Future<Map<String, dynamic>> fetchProductStats() async {
    try {
      final data = await _api.get('/products/stats');
      return data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Met à jour le prix d'un produit
  Future<void> updateProductPrice(String id, double newPrice) async {
    try {
      final productData = {'price': newPrice};
      await _api.put('/products/$id', productData);
    } catch (e) {
      rethrow;
    }
  }

  /// Supprime définitivement un produit
  Future<void> hardDeleteProduct(String id) async {
    try {
      await _api.delete('/products/$id/hard-delete');
    } catch (e) {
      rethrow;
    }
  }

  /// Teste la connexion à l'API
  Future<bool> testConnection() async {
    try {
      await _api.get('/products');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Méthodes utilitaires privées

  Map<String, dynamic> _buildProductData({
    required String name,
    required String category,
    required int quantity,
    required double price,
    String? description,
    int? reorderThreshold,
    String? unit,
    String? supplier,
  }) {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'price': price,
      'unit': unit ?? 'pièce',
      'reorderThreshold': reorderThreshold ?? 5,
      'description': description ?? '',
      'supplier': supplier ?? '',
    };
  }

  List<ProductModel> _filterDeletedProducts(List<ProductModel> products) {
    return products.where((product) => !product.isDeleted).toList();
  }
}
