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
  });

  bool get isFull => players.length >= maxPlayers;
  bool get canStart => players.length >= 2 && status == RoomStatus.waiting;
  bool get isPlaying => status == RoomStatus.playing;
  bool get isFinished => status == RoomStatus.finished;
  int get currentRoundIndex =>
      rounds.isNotEmpty ? rounds.indexOf(currentRound!) : -1;

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'players': players.map((player) => player.toJson()).toList(),
      'host': host?.toJson(),
      'currentRound': currentRound?.toJson(),
      'rounds': rounds.map((round) => round.toJson()).toList(),
      'status': status.name,
      'maxPlayers': maxPlayers,
      'maxRounds': maxRounds,
      'drawingTimeSeconds': drawingTimeSeconds,
      'isPrivate': isPrivate,
      'password': password,
      'useAI': useAI,
    };
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      players: (json['players'] as List)
          .map((player) => User.fromJson(player))
          .toList(),
      host: json['host'] != null ? User.fromJson(json['host']) : null,
      currentRound: json['currentRound'] != null
          ? GameRound.fromJson(json['currentRound'])
          : null,
      rounds: (json['rounds'] as List)
          .map((round) => GameRound.fromJson(round))
          .toList(),
      status: RoomStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => RoomStatus.waiting,
      ),
      maxPlayers: json['maxPlayers'] ?? 8,
      maxRounds: json['maxRounds'] ?? 3,
      drawingTimeSeconds: json['drawingTimeSeconds'] ?? 80,
      isPrivate: json['isPrivate'] ?? false,
      password: json['password'],
      useAI: json['useAI'] ?? false,
    );
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
      ];
}
