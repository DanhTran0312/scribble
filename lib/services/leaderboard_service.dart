import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../utils/api_constants.dart';
import 'api_client.dart';

class LeaderboardResult {
  final bool success;
  final List<User>? users;
  final String? error;
  final String timeFilter;

  LeaderboardResult({
    required this.success,
    this.users,
    this.error,
    this.timeFilter = 'all_time',
  });
}

class LeaderboardService {
  final ApiClient _apiClient = ApiClient();

  // Singleton pattern
  static final LeaderboardService _instance = LeaderboardService._internal();

  factory LeaderboardService() {
    return _instance;
  }

  LeaderboardService._internal();

  // Get leaderboard
  Future<LeaderboardResult> getLeaderboard({
    String timeFilter = 'all_time',
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'time_filter': timeFilter,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      // Build query string
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      final response = await _apiClient.get(
        '${ApiConstants.leaderboard}?$queryString',
      );

      // Extract leaderboard data from response
      List<dynamic> usersData = [];
      if (response.containsKey('items')) {
        usersData = response['items'] as List<dynamic>;
      } else if (response.containsKey('data')) {
        usersData = response['data'] as List<dynamic>;
      } else if (response.containsKey('users')) {
        usersData = response['users'] as List<dynamic>;
      } else {
        // If response has no recognized wrapper, assume it's a direct list
        // usersData = response is List ? response : [response];
      }

      final users =
          usersData
              .map(
                (userData) => User.fromJson(userData as Map<String, dynamic>),
              )
              .toList();

      return LeaderboardResult(
        success: true,
        users: users,
        timeFilter: timeFilter,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting leaderboard: $e');
      }
      return LeaderboardResult(
        success: false,
        error: e.toString(),
        timeFilter: timeFilter,
      );
    }
  }

  // Get player rank
  Future<int> getPlayerRank(
    String userId, {
    String timeFilter = 'all_time',
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.leaderboard}/rank/$userId?time_filter=$timeFilter',
      );

      if (response.containsKey('rank')) {
        return response['rank'] as int;
      }

      return 0; // Default rank if not found
    } catch (e) {
      if (kDebugMode) {
        print('Error getting player rank: $e');
      }
      return 0; // Default rank on error
    }
  }

  // Get my stats
  Future<User?> getMyStats() async {
    try {
      final response = await _apiClient.get('${ApiConstants.leaderboard}/me');

      return User.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user stats: $e');
      }
      return null;
    }
  }
}
