import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../utils/api_constants.dart';
import 'api_client.dart';

class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  AuthResult({required this.success, this.user, this.error});
}

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final StreamController<User?> _userController =
      StreamController<User?>.broadcast();
  User? _currentUser;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Initialize and check if user is already logged in
  Future<void> init() async {
    await _apiClient.init();

    if (_apiClient.isAuthenticated) {
      try {
        await getCurrentUser();
      } catch (e) {
        if (kDebugMode) {
          print('Error getting current user: $e');
        }

        // Token might be invalid, clear it
        await logout();
      }
    }
  }

  // Login with username
  Future<AuthResult> login({
    required String username,
    String? avatarUrl,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {'username': username, 'avatar_url': avatarUrl},
      );

      // Save auth token
      if (response.containsKey('access_token')) {
        await _apiClient.setAuthToken(response['access_token']);

        // Get user info
        final userResponse = await getCurrentUser();

        if (userResponse != null) {
          return AuthResult(success: true, user: userResponse);
        } else {
          return AuthResult(
            success: false,
            error: 'Failed to get user details',
          );
        }
      } else {
        return AuthResult(success: false, error: 'No access token in response');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging in: $e');
      }
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      await _apiClient.clearAuthToken();
      _currentUser = null;
      _userController.add(null);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error logging out: $e');
      }
      return false;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    if (!_apiClient.isAuthenticated) {
      _currentUser = null;
      _userController.add(null);
      return null;
    }

    try {
      final userData = await _apiClient.get(ApiConstants.currentUser);
      _currentUser = User.fromJson(userData);
      _userController.add(_currentUser);
      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current user: $e');
      }

      // If unauthorized, clear token
      if (e is ApiException && (e.statusCode == 401 || e.statusCode == 403)) {
        await logout();
      }
      rethrow;
    }
  }

  // Update user profile
  Future<User?> updateUserProfile({String? username, String? avatarUrl}) async {
    if (!_apiClient.isAuthenticated || _currentUser == null) {
      return null;
    }

    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      final response = await _apiClient.patch('/api/users/me', data: data);

      _currentUser = User.fromJson(response);
      _userController.add(_currentUser);
      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      rethrow;
    }
  }

  // Stream of user changes
  Stream<User?> get userChanges => _userController.stream;

  // Current user getter
  User? get currentUser => _currentUser;

  // Check if logged in
  bool get isLoggedIn => _currentUser != null;

  // Cleanup
  void dispose() {
    _userController.close();
  }
}
