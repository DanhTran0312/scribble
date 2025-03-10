import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String avatarUrl;
  final int score;
  final bool isReady;
  final bool isDrawing;
  final bool isHost;
  final int totalScore; // Added for leaderboard integration
  final int gamesPlayed; // Added for stats
  final int gamesWon; // Added for stats

  const User({
    required this.id,
    required this.username,
    this.avatarUrl = '',
    this.score = 0,
    this.isReady = false,
    this.isDrawing = false,
    this.isHost = false,
    this.totalScore = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
  });

  User copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    int? score,
    bool? isReady,
    bool? isDrawing,
    bool? isHost,
    int? totalScore,
    int? gamesPlayed,
    int? gamesWon,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      score: score ?? this.score,
      isReady: isReady ?? this.isReady,
      isDrawing: isDrawing ?? this.isDrawing,
      isHost: isHost ?? this.isHost,
      totalScore: totalScore ?? this.totalScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl, // Snake case for backend compatibility
      'score': score,
      'is_ready': isReady, // Snake case for backend compatibility
      'is_drawing': isDrawing, // Snake case for backend compatibility
      'is_host': isHost, // Snake case for backend compatibility
      'total_score': totalScore, // Snake case for backend compatibility
      'games_played': gamesPlayed, // Snake case for backend compatibility
      'games_won': gamesWon, // Snake case for backend compatibility
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      avatarUrl:
          json['avatar_url'] ?? json['avatarUrl'] ?? '', // Support both cases
      score: json['score'] ?? 0,
      isReady:
          json['is_ready'] ?? json['isReady'] ?? false, // Support both cases
      isDrawing:
          json['is_drawing'] ??
          json['isDrawing'] ??
          false, // Support both cases
      isHost: json['is_host'] ?? json['isHost'] ?? false, // Support both cases
      totalScore:
          json['total_score'] ?? json['totalScore'] ?? 0, // Support both cases
      gamesPlayed:
          json['games_played'] ??
          json['gamesPlayed'] ??
          0, // Support both cases
      gamesWon:
          json['games_won'] ?? json['gamesWon'] ?? 0, // Support both cases
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    avatarUrl,
    score,
    isReady,
    isDrawing,
    isHost,
    totalScore,
    gamesPlayed,
    gamesWon,
  ];
}
