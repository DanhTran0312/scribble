import 'package:equatable/equatable.dart';
import '../../models/game_round.dart';
import '../../models/message.dart';
import '../../models/user.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class GameJoined extends GameEvent {
  final String roomId;

  const GameJoined(this.roomId);

  @override
  List<Object> get props => [roomId];
}

class GameLeft extends GameEvent {}

class GameStarted extends GameEvent {}

class GameEnded extends GameEvent {}

class GameRoundStarted extends GameEvent {
  final GameRound round;

  const GameRoundStarted(this.round);

  @override
  List<Object> get props => [round];
}

class GameRoundEnded extends GameEvent {}

class GameWordSelected extends GameEvent {
  final String word;

  const GameWordSelected(this.word);

  @override
  List<Object> get props => [word];
}

class GameGuessSubmitted extends GameEvent {
  final String guess;

  const GameGuessSubmitted(this.guess);

  @override
  List<Object> get props => [guess];
}

class GameTimerTick extends GameEvent {
  final int remainingSeconds;

  const GameTimerTick(this.remainingSeconds);

  @override
  List<Object> get props => [remainingSeconds];
}

class GameMessagesReceived extends GameEvent {
  final List<Message> messages;

  const GameMessagesReceived(this.messages);

  @override
  List<Object> get props => [messages];
}

class GameRoundUpdated extends GameEvent {
  final GameRound round;

  const GameRoundUpdated(this.round);

  @override
  List<Object> get props => [round];
}

class GamePlayerJoined extends GameEvent {
  final User player;

  const GamePlayerJoined(this.player);

  @override
  List<Object> get props => [player];
}

class GamePlayerLeft extends GameEvent {
  final String playerId;

  const GamePlayerLeft(this.playerId);

  @override
  List<Object> get props => [playerId];
}

class GamePlayerReady extends GameEvent {
  final String playerId;
  final bool isReady;

  const GamePlayerReady({
    required this.playerId,
    required this.isReady,
  });

  @override
  List<Object> get props => [playerId, isReady];
}

class GamePlayerScoreUpdated extends GameEvent {
  final String playerId;
  final int score;

  const GamePlayerScoreUpdated({
    required this.playerId,
    required this.score,
  });

  @override
  List<Object> get props => [playerId, score];
}
