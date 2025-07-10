import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/logger.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoadingProfile = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;
  bool get isLoadingProfile => _isLoadingProfile;

  Future<bool> login(String email, String password) async {
    return _performAuthOperation(() async {
      final data = await _authService.login(email, password);
      await _handleAuthSuccess(data);
    });
  }

  Future<bool> register(String name, String businessName, String email, String password) async {
    return _performAuthOperation(() async {
      final data = await _authService.register(name, businessName, email, password);
      await _handleAuthSuccess(data);
    });
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storageService.deleteToken();
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    try {
      final savedToken = await _storageService.getToken();
      final userData = await _storageService.getUserData();
      
      if (savedToken != null && userData != null) {
        _token = savedToken;
        _user = UserModel.fromJson(userData);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Erreur lors de la connexion automatique', e);
      await logout();
    }
  }

  Future<void> fetchProfile() async {
    await _performProfileOperation(() async {
      final token = await _getValidToken();
      final data = await _authService.getProfile(token);
      _user = UserModel.fromJson(data);
      await _storageService.saveUserData(data);
    });
  }

  Future<void> updateProfile(String name, String email) async {
    await _performProfileOperation(() async {
      final token = await _getValidToken();
      await _authService.updateProfile(token, name, email);
      await fetchProfile();
    });
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _performProfileOperation(() async {
      final token = await _getValidToken();
      await _authService.changePassword(token, oldPassword, newPassword);
      await fetchProfile();
    });
  }

  Future<bool> testAuth() async {
    try {
      final token = await _getValidToken();
      
      await _authService.getProfile(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _performAuthOperation(Future<void> Function() operation) async {
    _setLoadingState(true);
    _clearError();

    try {
      await operation();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _performProfileOperation(Future<void> Function() operation) async {
    _setProfileLoadingState(true);
    _clearError();

    try {
      await operation();
    } catch (e) {
      _setError(e.toString());
      AppLogger.error('Erreur lors de l\'opération sur le profil', e);
      rethrow;
    } finally {
      _setProfileLoadingState(false);
    }
  }

  Future<void> _handleAuthSuccess(Map<String, dynamic> data) async {
    _token = data['token'];
    _user = UserModel.fromJson(data);

    await _storageService.saveToken(_token!);
    await _storageService.saveUserData(data);
  }

  Future<String> _getValidToken() async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }
    return token;
  }

  void _setLoadingState(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setProfileLoadingState(bool loading) {
    _isLoadingProfile = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setError(String error) {
    _errorMessage = error;
  }
}
