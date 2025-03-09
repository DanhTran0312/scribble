import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiClient {
  final http.Client _client = http.Client();
  String? _authToken;

  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  // Initialize and load auth token
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // Set auth token
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear auth token
  Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get auth token
  String? get authToken => _authToken;

  // Check if authenticated
  bool get isAuthenticated => _authToken != null;

  // GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _buildHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to perform GET request: $e');
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _buildHeaders(),
        body: data != null ? jsonEncode(data) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to perform POST request: $e');
    }
  }

  // PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _buildHeaders(),
        body: data != null ? jsonEncode(data) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to perform PATCH request: $e');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _client.delete(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _buildHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to perform DELETE request: $e');
    }
  }

  // Build request headers
  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success
      if (response.body.isEmpty) {
        return {};
      }

      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw ApiException('Failed to parse response: $e');
      }
    } else {
      // Error
      String message = 'Request failed with status: ${response.statusCode}';

      try {
        final errorData = jsonDecode(response.body);
        if (errorData.containsKey('detail')) {
          message = errorData['detail'];
        }
      } catch (_) {
        // Couldn't parse error response
      }

      throw ApiException(message, statusCode: response.statusCode);
    }
  }
}
