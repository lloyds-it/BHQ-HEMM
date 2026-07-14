import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _token;
  String? get token => _token;

  // HTTP client with timeout for performance
  final http.Client _httpClient = http.Client();
  static const Duration _timeout = Duration(seconds: 15);

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> init() async {
    try {
      _token = await _secureStorage.read(key: 'jwt_token');
    } catch (e) {
      // If decryption fails, clear all stored data to recover from keystore corruption
      try {
        await _secureStorage.deleteAll();
      } catch (_) {}
      _token = null;
    }
  }

  Future<void> saveToken(String token) async {
    _token = token;
    await _secureStorage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _secureStorage.delete(key: 'jwt_token');
  }

  Map<String, String> _getHeaders({bool includeContentType = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
    };
    if (includeContentType) headers['Content-Type'] = 'application/json';
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  Future<http.Response> get(String path) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final response = await _httpClient
        .get(uri, headers: _getHeaders())
        .timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> post(String path, dynamic body) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final response = await _httpClient
        .post(uri, headers: _getHeaders(), body: jsonEncode(body))
        .timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> put(String path, dynamic body) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final response = await _httpClient
        .put(uri, headers: _getHeaders(), body: jsonEncode(body))
        .timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> delete(String path) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final response = await _httpClient
        .delete(uri, headers: _getHeaders())
        .timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }

  /// Returns the full download URL with auth token as query param for browser download
  String getReportUrl(String reportType, Map<String, String> queryParameters) {
    final params = Map<String, String>.from(queryParameters);
    if (_token != null) params['token'] = _token!;
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/Report/$reportType')
        .replace(queryParameters: params);
    return uri.toString();
  }

  /// Fetches report data as a JSON list for inline preview
  Future<dynamic> getReportData(String reportType, Map<String, String> queryParameters) async {
    final params = Map<String, String>.from(queryParameters);
    params['format'] = 'json'; // explicitly request JSON
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/Report/$reportType')
        .replace(queryParameters: params);
    final response = await _httpClient
        .get(uri, headers: _getHeaders())
        .timeout(_timeout);
    _checkUnauthorized(response);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load report: ${response.statusCode}');
  }

  void _checkUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      clearToken();
    }
  }
}
