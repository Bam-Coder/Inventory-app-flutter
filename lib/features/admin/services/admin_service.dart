import '../../../core/services/api_service.dart';

class AdminService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final data = await _api.get('/admin/users');
    final List<dynamic> list = data['data'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchGlobalStats() async {
    final data = await _api.get('/admin/stats/global');
    return data['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchAuditLogs() async {
    final data = await _api.get('/admin/audit/logs');
    final List<dynamic> list = data['data'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  // Soft delete (marquer comme supprimé)
  Future<void> softDeleteUser(String userId) async {
    await _api.delete('/admin/users/$userId');
  }

  // Hard delete (suppression définitive)
  Future<void> hardDeleteUser(String userId) async {
    await _api.delete('/admin/delete/users/$userId');
  }

  // Méthode pour compatibilité
  Future<void> deleteUser(String userId) async {
    await softDeleteUser(userId);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    await _api.put('/admin/users/$userId', userData);
  }

  Future<Map<String, dynamic>> getUserById(String userId) async {
    final data = await _api.get('/admin/users/$userId');
    return data['data'] as Map<String, dynamic>;
  }

  // Gestion des produits
  Future<void> softDeleteProduct(String productId) async {
    await _api.delete('/admin/products/$productId');
  }

  Future<void> hardDeleteProduct(String productId) async {
    await _api.delete('/admin/delete/product/$productId');
  }
} 