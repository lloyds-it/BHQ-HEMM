import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _username;
  String? get username => _username;

  String? _role;
  String? get role => _role;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> tryAutoLogin() async {
    await _apiClient.init();
    if (_apiClient.token != null) {
      _username = await _secureStorage.read(key: 'username');
      _role = await _secureStorage.read(key: 'role');
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password, bool rememberMe) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/login', {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        _username = data['username'] as String;
        _role = data['role'] as String;
        _isAuthenticated = true;

        if (rememberMe) {
          await _apiClient.saveToken(token);
          await _secureStorage.write(key: 'username', value: _username!);
          await _secureStorage.write(key: 'role', value: _role!);
        } else {
          // Keep it in session memory only so it clears on close,
          // but for now, we'll save it to prefs so refresh works.
          // The issue is if we save token to prefs, we MUST save role.
          await _apiClient.saveToken(token);
          await _secureStorage.write(key: 'username', value: _username!);
          await _secureStorage.write(key: 'role', value: _role!);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
    await _secureStorage.delete(key: 'username');
    await _secureStorage.delete(key: 'role');
    _username = null;
    _role = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
