import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String avatarUrl;
  final int score;
  final bool isReady;
  final bool isDrawing;
  final bool isHost;

  const User({
    required this.id,
    required this.username,
    this.avatarUrl = '',
    this.score = 0,
    this.isReady = false,
    this.isDrawing = false,
    this.isHost = false,
  });

  User copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    int? score,
    bool? isReady,
    bool? isDrawing,
    bool? isHost,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      score: score ?? this.score,
      isReady: isReady ?? this.isReady,
      isDrawing: isDrawing ?? this.isDrawing,
      isHost: isHost ?? this.isHost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatarUrl': avatarUrl,
      'score': score,
      'isReady': isReady,
      'isDrawing': isDrawing,
      'isHost': isHost,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatarUrl'] ?? '',
      score: json['score'] ?? 0,
      isReady: json['isReady'] ?? false,
      isDrawing: json['isDrawing'] ?? false,
      isHost: json['isHost'] ?? false,
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
      ];
}
