import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/room.dart';
import '../../services/room_service.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final RoomService roomService;

  RoomBloc({required this.roomService}) : super(RoomInitial()) {
    on<RoomCreateRequested>(_onRoomCreateRequested);
    on<RoomJoinRequested>(_onRoomJoinRequested);
    on<RoomLeaveRequested>(_onRoomLeaveRequested);
    on<RoomUpdateSettings>(_onRoomUpdateSettings);
    on<RoomToggleReady>(_onRoomToggleReady);
    on<RoomLoadAvailable>(_onRoomLoadAvailable);
  }

  Future<void> _onRoomCreateRequested(
    RoomCreateRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(RoomLoading());

    try {
      final room = await roomService.createRoom(
        name: event.roomName,
        maxPlayers: event.maxPlayers,
        maxRounds: event.maxRounds,
        drawingTimeSeconds: event.drawingTimeSeconds,
        isPrivate: event.isPrivate,
        password: event.password,
        useAI: event.useAI,
      );

      emit(RoomCreated(room));
    } catch (error) {
      emit(RoomFailure(error.toString()));
    }
  }

  Future<void> _onRoomJoinRequested(
    RoomJoinRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(RoomLoading());

    try {
      final room = await roomService.joinRoom(
        event.roomId,
        password: event.password,
      );

      emit(RoomJoined(room));
    } catch (error) {
      emit(RoomFailure(error.toString()));
    }
  }

  Future<void> _onRoomLeaveRequested(
    RoomLeaveRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(RoomLoading());

    try {
      await roomService.leaveRoom(event.roomId);
      emit(RoomLeft());
    } catch (error) {
      emit(RoomFailure(error.toString()));
    }
  }

  Future<void> _onRoomUpdateSettings(
    RoomUpdateSettings event,
    Emitter<RoomState> emit,
  ) async {
    final currentState = state;
    if (currentState is RoomCreated || currentState is RoomJoined) {
      Room currentRoom;

      if (currentState is RoomCreated) {
        currentRoom = currentState.room;
      } else {
        currentRoom = (currentState as RoomJoined).room;
      }

      emit(RoomLoading());

      try {
        final updatedRoom = await roomService.updateRoomSettings(
          roomId: currentRoom.id,
          maxPlayers: event.maxPlayers,
          maxRounds: event.maxRounds,
          drawingTimeSeconds: event.drawingTimeSeconds,
          isPrivate: event.isPrivate,
          password: event.password,
          useAI: event.useAI,
        );

        if (currentState is RoomCreated) {
          emit(RoomCreated(updatedRoom));
        } else {
          emit(RoomJoined(updatedRoom));
        }
      } catch (error) {
        emit(RoomFailure(error.toString()));

        // Revert to previous state
        if (currentState is RoomCreated) {
          emit(RoomCreated(currentRoom));
        } else {
          emit(RoomJoined(currentRoom));
        }
      }
    }
  }

  Future<void> _onRoomToggleReady(
    RoomToggleReady event,
    Emitter<RoomState> emit,
  ) async {
    final currentState = state;
    if (currentState is RoomJoined) {
      final currentRoom = currentState.room;

      try {
        await roomService.toggleReady(
          roomId: currentRoom.id,
          isReady: event.isReady,
        );
      } catch (error) {
        emit(RoomFailure(error.toString()));
      }
    }
  }

  Future<void> _onRoomLoadAvailable(
    RoomLoadAvailable event,
    Emitter<RoomState> emit,
  ) async {
    emit(RoomLoading());

    try {
      final rooms = await roomService.getAvailableRooms();
      emit(RoomsLoaded(rooms));
    } catch (error) {
      emit(RoomFailure(error.toString()));
    }
  }
}
