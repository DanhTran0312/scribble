import 'package:equatable/equatable.dart';
import '../../models/game_round.dart';
import '../../models/room.dart';
import '../../models/user.dart';

abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class GameInLobby extends GameState {
  final Room room;

  const GameInLobby(this.room);

  @override
  List<Object> get props => [room];
}

class GamePlaying extends GameState {
  final Room room;
  final GameRound round;
  final bool isDrawingTurn;
  final int remainingTimeInSeconds;

  const GamePlaying({
    required this.room,
    required this.round,
    required this.isDrawingTurn,
    this.remainingTimeInSeconds = 0,
  });

  GamePlaying copyWith({
    Room? room,
    GameRound? round,
    bool? isDrawingTurn,
    int? remainingTimeInSeconds,
  }) {
    return GamePlaying(
      room: room ?? this.room,
      round: round ?? this.round,
      isDrawingTurn: isDrawingTurn ?? this.isDrawingTurn,
      remainingTimeInSeconds:
          remainingTimeInSeconds ?? this.remainingTimeInSeconds,
    );
  }

  @override
  List<Object> get props => [
        room,
        round,
        isDrawingTurn,
        remainingTimeInSeconds,
      ];
}

class GameRoundFinished extends GameState {
  final Room room;
  final GameRound round;
  final Map<String, int> playerScores;

  const GameRoundFinished({
    required this.room,
    required this.round,
    required this.playerScores,
  });

  @override
  List<Object> get props => [room, round, playerScores];
}

class GameFinished extends GameState {
  final Room room;
  final List<GameRound> rounds;
  final User winner;

  const GameFinished({
    required this.room,
    required this.rounds,
    required this.winner,
  });

  @override
  List<Object> get props => [room, rounds, winner];
}

class GameFailure extends GameState {
  final String error;

  const GameFailure(this.error);

  @override
  List<Object> get props => [error];
}
