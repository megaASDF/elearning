import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInstructor => _user?.isInstructor ?? false;
  bool get isStudent => _user?.isStudent ?? false;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiService = ApiService();
      final response = await apiService.login(username, password);
      final token = response['token'];
      final userData = response['user'];

      _user = UserModel.fromJson(userData);
      apiService.setToken(token);

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user', userData.toString());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    final apiService = ApiService();
    apiService.setToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');

    notifyListeners();
  }

  Future<void> loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userStr = prefs.getString('user');

    if (token != null && userStr != null) {
      final apiService = ApiService();
      apiService.setToken(token);
      // Parse user data and set _user
      notifyListeners();
    }
  }
}