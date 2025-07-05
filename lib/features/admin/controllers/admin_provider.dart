import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _auditLogs = [];
  Map<String, dynamic> _globalStats = {};
  
  bool _isLoadingUsers = false;
  bool _isLoadingAudit = false;
  bool _isLoadingStats = false;
  String? _error;

  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get auditLogs => _auditLogs;
  Map<String, dynamic> get globalStats => _globalStats;
  
  bool get isLoadingUsers => _isLoadingUsers;
  bool get isLoadingAudit => _isLoadingAudit;
  bool get isLoadingStats => _isLoadingStats;
  String? get error => _error;

  Future<void> fetchUsers() async {
    _isLoadingUsers = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _adminService.fetchUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> fetchAuditLogs() async {
    _isLoadingAudit = true;
    _error = null;
    notifyListeners();

    try {
      _auditLogs = await _adminService.fetchAuditLogs();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingAudit = false;
      notifyListeners();
    }
  }

  Future<void> fetchGlobalStats() async {
    _isLoadingStats = true;
    _error = null;
    notifyListeners();

    try {
      _globalStats = await _adminService.fetchGlobalStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _adminService.deleteUser(userId);
      // Recharger la liste des utilisateurs
      await fetchUsers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 