import 'package:equatable/equatable.dart';

abstract class RoomEvent extends Equatable {
  const RoomEvent();

  @override
  List<Object?> get props => [];
}

class RoomCreateRequested extends RoomEvent {
  final String roomName;
  final int maxPlayers;
  final int maxRounds;
  final int drawingTimeSeconds;
  final bool isPrivate;
  final String? password;
  final bool useAI;

  const RoomCreateRequested({
    required this.roomName,
    this.maxPlayers = 8,
    this.maxRounds = 3,
    this.drawingTimeSeconds = 80,
    this.isPrivate = false,
    this.password,
    this.useAI = false,
  });

  @override
  List<Object?> get props => [
    roomName,
    maxPlayers,
    maxRounds,
    drawingTimeSeconds,
    isPrivate,
    password,
    useAI,
  ];
}

class RoomJoinRequested extends RoomEvent {
  final String roomId;
  final String? password;

  const RoomJoinRequested({required this.roomId, this.password});

  @override
  List<Object?> get props => [roomId, password];
}

class RoomLeaveRequested extends RoomEvent {
  final String roomId;

  const RoomLeaveRequested(this.roomId);

  @override
  List<Object> get props => [roomId];
}

class RoomUpdateSettings extends RoomEvent {
  final int? maxPlayers;
  final int? maxRounds;
  final int? drawingTimeSeconds;
  final bool? isPrivate;
  final String? password;
  final bool? useAI;

  const RoomUpdateSettings({
    this.maxPlayers,
    this.maxRounds,
    this.drawingTimeSeconds,
    this.isPrivate,
    this.password,
    this.useAI,
  });

  @override
  List<Object?> get props => [
    maxPlayers,
    maxRounds,
    drawingTimeSeconds,
    isPrivate,
    password,
    useAI,
  ];
}

class RoomToggleReady extends RoomEvent {
  final bool isReady;

  const RoomToggleReady(this.isReady);

  @override
  List<Object> get props => [isReady];
}

class RoomLoadAvailable extends RoomEvent {}
