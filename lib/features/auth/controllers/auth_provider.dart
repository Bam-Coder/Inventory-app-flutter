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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _authService.login(email, password);

      _token = data['token'];
      _user = UserModel.fromJson(data);

      await _storageService.saveToken(_token!);
      await _storageService.saveUserData(data);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String businessName, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _authService.register(name, businessName, email, password);

      _token = data['token'];
      _user = UserModel.fromJson(data);

      await _storageService.saveToken(_token!);
      await _storageService.saveUserData(data);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storageService.deleteToken();
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final savedToken = await _storageService.getToken();
    final userData = await _storageService.getUserData();
    if (savedToken != null && userData != null) {
      _token = savedToken;
      _user = UserModel.fromJson(userData);
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await _storageService.getToken();
      final data = await _authService.getProfile(token!);
      _user = UserModel.fromJson(data);
      await _storageService.saveUserData(data);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String name, String email) async {
    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await _storageService.getToken();
      await _authService.updateProfile(token!, name, email);
      await fetchProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }
      await _authService.changePassword(token, oldPassword, newPassword);
      // Recharger le profil après le changement de mot de passe
      await fetchProfile();
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('Erreur lors du changement de mot de passe', e);
      rethrow; // Propager l'erreur pour l'afficher dans l'UI
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> testAuth() async {
    try {
      final token = await _storageService.getToken();
      
      if (token == null) {
        return false;
      }
      
      await _authService.getProfile(token);
      return true;
    } catch (e) {
      return false;
    }
  }
}
