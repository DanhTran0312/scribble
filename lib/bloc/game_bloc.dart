import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/game_round.dart';
import '../../models/message.dart';
import '../../models/room.dart';
import '../../models/user.dart';
import '../../services/room_service.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final RoomService roomService;
  StreamSubscription? _roomSubscription;
  StreamSubscription? _roundSubscription;
  StreamSubscription? _messageSubscription;

  GameBloc({required this.roomService}) : super(GameInitial()) {
    on<GameJoined>(_onGameJoined);
    on<GameLeft>(_onGameLeft);
    on<GameStarted>(_onGameStarted);
    on<GameEnded>(_onGameEnded);
    on<GameRoundStarted>(_onGameRoundStarted);
    on<GameRoundEnded>(_onGameRoundEnded);
    on<GameWordSelected>(_onGameWordSelected);
    on<GameGuessSubmitted>(_onGameGuessSubmitted);
    on<GameTimerTick>(_onGameTimerTick);
    on<GameMessagesReceived>(_onGameMessagesReceived);
    on<GameRoundUpdated>(_onGameRoundUpdated);
    on<GamePlayerJoined>(_onGamePlayerJoined);
    on<GamePlayerLeft>(_onGamePlayerLeft);
    on<GamePlayerReady>(_onGamePlayerReady);
    on<GamePlayerScoreUpdated>(_onGamePlayerScoreUpdated);
  }

  Future<void> _onGameJoined(
    GameJoined event,
    Emitter<GameState> emit,
  ) async {
    emit(GameLoading());

    try {
      final room = await roomService.joinRoom(event.roomId);

      // Subscribe to room updates
      _subscribeToRoomUpdates(room.id);

      emit(GameInLobby(room));
    } catch (error) {
      emit(GameFailure(error.toString()));
    }
  }

  Future<void> _onGameLeft(
    GameLeft event,
    Emitter<GameState> emit,
  ) async {
    // Cancel all subscriptions
    await _roomSubscription?.cancel();
    await _roundSubscription?.cancel();
    await _messageSubscription?.cancel();

    _roomSubscription = null;
    _roundSubscription = null;
    _messageSubscription = null;

    emit(GameInitial());
  }

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<GameState> emit,
  ) async {
    final currentState = state;
    if (currentState is GameInLobby) {
      emit(GameLoading());

      try {
        final updatedRoom = await roomService.startGame(currentState.room.id);
        _subscribeToRoundUpdates(updatedRoom.id);

        if (updatedRoom.currentRound != null) {
          emit(GamePlaying(
            room: updatedRoom,
            round: updatedRoom.currentRound!,
            isDrawingTurn: _isDrawingTurn(updatedRoom),
            remainingTimeInSeconds:
                updatedRoom.currentRound!.remainingTimeInSeconds,
          ));
        } else {
          emit(GameInLobby(updatedRoom));
        }
      } catch (error) {
        emit(GameFailure(error.toString()));
        emit(currentState); // Revert to previous state
      }
    }
  }

  Future<void> _onGameEnded(
    GameEnded event,
    Emitter<GameState> emit,
  ) async {
    final currentState = state;
    if (currentState is GamePlaying) {
      await _roundSubscription?.cancel();
      _roundSubscription = null;

      emit(GameFinished(
        room: currentState.room,
        rounds: currentState.room.rounds,
        winner: _determineWinner(currentState.room),
      ));
    }
  }

  Future<void> _onGameRoundStarted(
    GameRoundStarted event,
    Emitter<GameState> emit,
  ) async {
    final currentState = state;
    if (currentState is GamePlaying || currentState is GameInLobby) {
      Room room;

      if (currentState is GamePlaying) {
        room = currentState.room;
      } else {
        room = (currentState as GameInLobby).room;
      }

      _subscribeToRoundUpdates(room.id);

      emit(GamePlaying(
        room: room.copyWith(
          currentRound: event.round,
          rounds: [...room.rounds, event.round],
        ),
        round: event.round,
        isDrawingTurn: _isDrawingTurn(room, event.round),
        remainingTimeInSeconds: event.round.remainingTimeInSeconds,
      ));
    }
  }

  Future<void> _onGameRoundEnded(
    GameRoundEnded event,
    Emitter<GameState> emit,
  ) async {
    final currentState = state;
    if (currentState is GamePlaying) {
      final updatedRound = currentState.round.copyWith(
        status: RoundStatus.ended,
        endTime: DateTime.now(),
      );

      final updatedRoom = currentState.room.copyWith(
        rounds: currentState.room.rounds.map((round) {
          if (round.roundNumber == updatedRound.roundNumber) {
            return updatedRound;
          }
          return round;
        }).toList(),
      );

      emit(GameRoundFinished(
        room: updatedRoom,
        round: updatedRound,
        playerScores: updatedRound.playerScores,
      ));

      // If the game is not finished, a new round will start soon
      if (updatedRoom.rounds.length < updatedRoom.maxRounds) {
        await Future.delayed(const Duration(seconds: 10));

        // Check if we're still in the round finished state
        final currentState = state;
        if (currentState is GameRoundFinished) {
          emit(GameLoading());
        }
      } else {
        // End the game
        add(GameEnded());
      }
    }
  }

  Future<void> _onGameWordSelected(
    GameWordSelected event,
    Emitter<GameState> emit,
  ) async {
    final currentState = state;
    if (currentState is GamePlaying && currentState.isDrawingTurn) {
      try {
        await roomService.selectWord(
          currentState.room.id,
          currentState.round.roundNumber,
          event.word,
        );
      } catch (error) {
        emit(GameFailure(error.toString()));
        emit(currentState); // Revert to previous state
      }
    }
  }

  Future<void> _onGameGuessSubmitted(
    GameGuessSubmitted event,
    Emitter<GameState> emit,
  ) async {
    final currentState = state;
    if (currentState is GamePlaying && !currentState.isDrawingTurn) {
      try {
        await roomService.submitGuess(
          currentState.room.id,
          currentState.round.roundNumber,
          event.guess,
        );
      } catch (error) {
        emit(GameFailure(error.toString()));
      }
    }
  }

  void _onGameTimerTick(
    GameTimerTick event,
    Emitter<GameState> emit,
  ) {
    final currentState = state;
    if (currentState is GamePlaying) {
      emit(currentState.copyWith(
        remainingTimeInSeconds: event.remainingSeconds,
      ));

      if (event.remainingSeconds <= 0) {
        add(GameRoundEnded());
      }
    }
  }

  void _onGameMessagesReceived(
    GameMessagesReceived event,
    Emitter<GameState> emit,
  ) {
    final currentState = state;
    if (currentState is GamePlaying) {
      final updatedRound = currentState.round.copyWith(
        messages: event.messages,
      );

      emit(currentState.copyWith(
        round: updatedRound,
      ));
    }
  }

  void _onGameRoundUpdated(
    GameRoundUpdated event,
    Emitter<GameState> emit,
  ) {
    final currentState = state;
    if (currentState is GamePlaying) {
      emit(currentState.copyWith(
        round: event.round,
      ));
    }
  }

  void _onGamePlayerJoined(
    GamePlayerJoined event,
    Emitter<GameState> emit,
  ) {
    final currentState = state;
    if (currentState is GameInLobby) {
      final updatedPlayers = [...currentState.room.players, event.player];
      final updatedRoom = currentState.room.copyWith(
        players: updatedPlayers,
      );

      emit(GameInLobby(updatedRoom));
    } else if (currentState is GamePlaying) {
      final updatedPlayers = [...currentState.room.players, event.player];
      final updatedRoom = currentState.room.copyWith(
        players: updatedPlayers,
      );

      emit(currentState.copyWith(
        room: updatedRoom,
      ));
    }
  }

  void _onGamePlayerLeft(
    GamePlayerLeft event,
    Emitter<GameState> emit,
  ) {
    final currentState = state;
    if (currentState is GameInLobby) {
      final updatedPlayers = currentState.room.players
          .where((player) => player.id != event.playerId)
          .toList();

      final updatedRoom = currentState.room.copyWith(
        players: updatedPlayers,
      );

      emit(GameInLobby(updatedRoom));
    } else if (currentState is GamePlaying) {
      final updatedPlayers = currentState.room.players
          .where((player) => player.id != event.playerId)
          .toList();

      final updatedRoom = currentState.room.copyWith(
        players: updatedPlayers,
      );

      emit(currentState.copyWith(
        room: updatedRoom,
      ));
    }
  }

  void _onGamePlayerReady(
    GamePlayerReady event,
    Emitter<GameState> emit,
  ) {
    final currentState = state;
    if (currentState is GameInLobby) {
      final updatedPlayers = currentState.room.players.map((player) {
        if (player.id == event.playerId) {
          return player.copyWith(isReady: event.isReady);
        }
        return player;
      }).toList();

      final updatedRoom = currentState.room.copyWith(
        players: updatedPlayers,
      );

      emit(GameInLobby(updatedRoom));
    }
  }

  void _onGamePlayerScoreUpdated(
    GamePlayerScoreUpdated event,
    Emitter<GameState> emit,
  ) {
    final currentState = state;
    if (currentState is GamePlaying) {
      final updatedPlayers = currentState.room.players.map((player) {
        if (player.id == event.playerId) {
          return player.copyWith(score: event.score);
        }
        return player;
      }).toList();

      final updatedRoom = currentState.room.copyWith(
        players: updatedPlayers,
      );

      emit(currentState.copyWith(
        room: updatedRoom,
      ));
    }
  }

  bool _isDrawingTurn(Room room, [GameRound? round]) {
    final user = room.players.firstWhere(
      (player) => player.isDrawing,
      orElse: () => room.players.first,
    );

    final currentRound = round ?? room.currentRound;
    if (currentRound == null) return false;

    return user.id == currentRound.drawerUser.id;
  }

  User _determineWinner(Room room) {
    // Find player with highest score
    final sortedPlayers = List<User>.from(room.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return sortedPlayers.first;
  }

  void _subscribeToRoomUpdates(String roomId) {
    _roomSubscription?.cancel();
    _roomSubscription = roomService.getRoomUpdates(roomId).listen(
      (room) {
        // Handle player joining/leaving
        if (state is GameInLobby) {
          // ...
        }
      },
      onError: (error) {
        add(GameLeft());
      },
    );
  }

  void _subscribeToRoundUpdates(String roomId) {
    _roundSubscription?.cancel();
    _roundSubscription = roomService.getRoundUpdates(roomId).listen(
      (round) {
        add(GameRoundUpdated(round));
      },
      onError: (error) {
        // Handle error
      },
    );

    _messageSubscription?.cancel();
    _messageSubscription = roomService.getMessageUpdates(roomId).listen(
      (messages) {
        add(GameMessagesReceived(messages));
      },
      onError: (error) {
        // Handle error
      },
    );
  }

  @override
  Future<void> close() {
    _roomSubscription?.cancel();
    _roundSubscription?.cancel();
    _messageSubscription?.cancel();
    return super.close();
  }
}
