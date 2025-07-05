import '../../../core/services/api_service.dart';
import '../models/product_model.dart';

class ProductService {
  final ApiService _api = ApiService();

  Future<List<ProductModel>> fetchProducts() async {
    try {
      final data = await _api.get('/products');
      final List<dynamic> list = data['data'] as List<dynamic>;
      return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addProduct(String name, String category, int quantity, double price, {
    String? description,
    int? reorderThreshold,
    String? unit,
    String? supplier,
  }) async {
    try {
      final productData = {
        'name': name,
        'category': category,
        'quantity': quantity,
        'price': price,
        'unit': unit ?? 'pièce',
        'reorderThreshold': reorderThreshold ?? 5,
        'description': description ?? '',
        'supplier': supplier ?? '',
      };
      
      // Debug: afficher les données envoyées
      print('Données envoyées au backend: $productData');
      
      await _api.post('/products', productData);
    } catch (e) {
      print('Erreur lors de l\'ajout du produit: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(String id, String name, String category, int quantity, double price) async {
    try {
      final productData = {
        'name': name,
        'category': category,
        'quantity': quantity,
        'price': price,
        'unit': 'pièce',
        'description': '',
      };
      
      // Debug: afficher les données envoyées
      print('🔄 Mise à jour du produit $id');
      print('📦 Données envoyées: $productData');
      
      final response = await _api.put('/products/$id', productData);
      
      // Debug: afficher la réponse
      print('✅ Réponse du serveur: $response');
      
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du produit: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _api.delete('/products/$id');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final data = await _api.get('/products/search?q=$query');
      final List<dynamic> list = data['data'] as List<dynamic>;
      return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> fetchLowStockProducts() async {
    try {
      final data = await _api.get('/products/low-stock');
      final List<dynamic> list = data['data'] as List<dynamic>;
      return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchProductStats() async {
    try {
      final data = await _api.get('/products/stats');
      return data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> testConnection() async {
    try {
      await _api.get('/products');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateProductPrice(String id, double newPrice) async {
    try {
      final productData = {
        'price': newPrice,
      };
      
      print('💰 Mise à jour du prix du produit $id: $newPrice FCFA');
      
      final response = await _api.put('/products/$id', productData);
      
      print('✅ Prix mis à jour avec succès: $response');
      
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du prix: $e');
      rethrow;
    }
  }
}
