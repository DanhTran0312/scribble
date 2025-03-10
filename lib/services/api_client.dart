import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

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
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      if (kDebugMode) {
        print(
          'ApiClient initialized with token: ${_authToken != null ? 'exists' : 'null'}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing ApiClient: $e');
      }
    }
  }

  // Set auth token
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      if (kDebugMode) {
        print('Auth token saved: ${token.substring(0, 10)}...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving auth token: $e');
      }
    }
  }

  // Clear auth token
  Future<void> clearAuthToken() async {
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      if (kDebugMode) {
        print('Auth token cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing auth token: $e');
      }
    }
  }

  // Get auth token
  String? get authToken => _authToken;

  // Check if authenticated
  bool get isAuthenticated => _authToken != null;

  // GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      if (kDebugMode) {
        print('GET ${ApiConstants.baseUrl}$endpoint');
      }

      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _buildHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in GET request: $e');
      }
      throw ApiException('Failed to perform GET request: $e');
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print('POST ${ApiConstants.baseUrl}$endpoint');
        if (data != null) print('Data: $data');
      }

      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _buildHeaders(),
        body: data != null ? jsonEncode(data) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in POST request: $e');
      }
      throw ApiException('Failed to perform POST request: $e');
    }
  }

  // PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print('PATCH ${ApiConstants.baseUrl}$endpoint');
        if (data != null) print('Data: $data');
      }

      final response = await _client.patch(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _buildHeaders(),
        body: data != null ? jsonEncode(data) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in PATCH request: $e');
      }
      throw ApiException('Failed to perform PATCH request: $e');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      if (kDebugMode) {
        print('DELETE ${ApiConstants.baseUrl}$endpoint');
      }

      final response = await _client.delete(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _buildHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in DELETE request: $e');
      }
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
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      String logBody = response.body;
      if (logBody.length > 1000) {
        logBody = '${logBody.substring(0, 1000)}... [truncated]';
      }
      print('Response body: $logBody');
    }

    // Handle empty responses
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {}; // Empty successful response
      } else {
        throw ApiException(
          'Empty response with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    }

    // Parse response body
    Map<String, dynamic> responseData;
    try {
      responseData = jsonDecode(response.body);
    } catch (e) {
      throw ApiException(
        'Failed to parse response: $e',
        statusCode: response.statusCode,
        data: response.body,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success
      return responseData;
    } else {
      // Error
      String message = 'Request failed with status: ${response.statusCode}';

      if (responseData.containsKey('detail')) {
        message = responseData['detail'];
      } else if (responseData.containsKey('message')) {
        message = responseData['message'];
      } else if (responseData.containsKey('error')) {
        message = responseData['error'];
      }

      throw ApiException(
        message,
        statusCode: response.statusCode,
        data: responseData,
      );
    }
  }

  // Clean up resources
  void dispose() {
    _client.close();
  }
}
