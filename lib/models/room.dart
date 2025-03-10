import 'package:equatable/equatable.dart';

import 'game_round.dart';
import 'user.dart';

enum RoomStatus { waiting, playing, finished }

class Room extends Equatable {
  final String id;
  final String name;
  final List<User> players;
  final User? host;
  final GameRound? currentRound;
  final List<GameRound> rounds;
  final RoomStatus status;
  final int maxPlayers;
  final int maxRounds;
  final int drawingTimeSeconds;
  final bool isPrivate;
  final String? password;
  final bool useAI;
  final DateTime? createdAt; // Added creation timestamp

  const Room({
    required this.id,
    required this.name,
    this.players = const [],
    this.host,
    this.currentRound,
    this.rounds = const [],
    this.status = RoomStatus.waiting,
    this.maxPlayers = 8,
    this.maxRounds = 3,
    this.drawingTimeSeconds = 80,
    this.isPrivate = false,
    this.password,
    this.useAI = false,
    this.createdAt,
  });

  bool get isFull => players.length >= maxPlayers;
  bool get canStart => players.length >= 2 && status == RoomStatus.waiting;
  bool get isPlaying => status == RoomStatus.playing;
  bool get isFinished => status == RoomStatus.finished;
  int get currentRoundIndex =>
      rounds.isNotEmpty ? rounds.indexOf(currentRound!) : -1;

  // Helper method to get active (not full, not started) rooms
  bool get isActive => !isFull && status == RoomStatus.waiting;

  Room copyWith({
    String? id,
    String? name,
    List<User>? players,
    User? host,
    GameRound? currentRound,
    List<GameRound>? rounds,
    RoomStatus? status,
    int? maxPlayers,
    int? maxRounds,
    int? drawingTimeSeconds,
    bool? isPrivate,
    String? password,
    bool? useAI,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      players: players ?? this.players,
      host: host ?? this.host,
      currentRound: currentRound ?? this.currentRound,
      rounds: rounds ?? this.rounds,
      status: status ?? this.status,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      maxRounds: maxRounds ?? this.maxRounds,
      drawingTimeSeconds: drawingTimeSeconds ?? this.drawingTimeSeconds,
      isPrivate: isPrivate ?? this.isPrivate,
      password: password ?? this.password,
      useAI: useAI ?? this.useAI,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'players': players.map((player) => player.toJson()).toList(),
      'host': host?.toJson(),
      'current_round': currentRound?.toJson(), // Snake case for backend
      'rounds': rounds.map((round) => round.toJson()).toList(),
      'status': status.name,
      'max_players': maxPlayers, // Snake case for backend
      'max_rounds': maxRounds, // Snake case for backend
      'drawing_time_seconds': drawingTimeSeconds, // Snake case for backend
      'is_private': isPrivate, // Snake case for backend
      'password': password,
      'use_ai': useAI, // Snake case for backend
      'created_at': createdAt?.toIso8601String(), // Snake case for backend
    };
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      players:
          (json['players'] as List?)
              ?.map((player) => User.fromJson(player))
              .toList() ??
          [],
      host: json['host'] != null ? User.fromJson(json['host']) : null,
      currentRound:
          json['current_round'] != null || json['currentRound'] != null
              ? GameRound.fromJson(
                json['current_round'] ?? json['currentRound'],
              )
              : null,
      rounds:
          (json['rounds'] as List?)
              ?.map((round) => GameRound.fromJson(round))
              .toList() ??
          [],
      status: _parseRoomStatus(json['status']),
      maxPlayers: json['max_players'] ?? json['maxPlayers'] ?? 8,
      maxRounds: json['max_rounds'] ?? json['maxRounds'] ?? 3,
      drawingTimeSeconds:
          json['drawing_time_seconds'] ?? json['drawingTimeSeconds'] ?? 80,
      isPrivate: json['is_private'] ?? json['isPrivate'] ?? false,
      password: json['password'],
      useAI: json['use_ai'] ?? json['useAI'] ?? false,
      createdAt:
          json['created_at'] != null || json['createdAt'] != null
              ? DateTime.parse(json['created_at'] ?? json['createdAt'])
              : null,
    );
  }

  static RoomStatus _parseRoomStatus(String? status) {
    if (status == null) return RoomStatus.waiting;

    switch (status.toLowerCase()) {
      case 'waiting':
        return RoomStatus.waiting;
      case 'playing':
        return RoomStatus.playing;
      case 'finished':
        return RoomStatus.finished;
      default:
        return RoomStatus.waiting;
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    players,
    host,
    currentRound,
    rounds,
    status,
    maxPlayers,
    maxRounds,
    drawingTimeSeconds,
    isPrivate,
    password,
    useAI,
    createdAt,
  ];
}

// Room info for the room list (lightweight version)
class RoomInfo extends Equatable {
  final String id;
  final String name;
  final String hostName;
  final int playerCount;
  final int maxPlayers;
  final RoomStatus status;
  final bool isPrivate;
  final bool useAI;

  const RoomInfo({
    required this.id,
    required this.name,
    required this.hostName,
    required this.playerCount,
    required this.maxPlayers,
    required this.status,
    required this.isPrivate,
    required this.useAI,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      hostName: json['host_name'] ?? json['hostName'] ?? 'Unknown',
      playerCount: json['player_count'] ?? json['playerCount'] ?? 0,
      maxPlayers: json['max_players'] ?? json['maxPlayers'] ?? 8,
      status: Room._parseRoomStatus(json['status']),
      isPrivate: json['is_private'] ?? json['isPrivate'] ?? false,
      useAI: json['use_ai'] ?? json['useAI'] ?? false,
    );
  }

  bool get isFull => playerCount >= maxPlayers;
  bool get canJoin => status == RoomStatus.waiting && !isFull;

  @override
  List<Object?> get props => [
    id,
    name,
    hostName,
    playerCount,
    maxPlayers,
    status,
    isPrivate,
    useAI,
  ];
}
