import 'package:equatable/equatable.dart';

import '../../models/room.dart';

abstract class RoomState extends Equatable {
  const RoomState();

  @override
  List<Object?> get props => [];
}

class RoomInitial extends RoomState {}

class RoomLoading extends RoomState {}

class RoomCreated extends RoomState {
  final Room room;

  const RoomCreated(this.room);

  @override
  List<Object> get props => [room];
}

class RoomJoined extends RoomState {
  final Room room;

  const RoomJoined(this.room);

  @override
  List<Object> get props => [room];
}

class RoomLeft extends RoomState {}

class RoomsLoaded extends RoomState {
  final List<Room> rooms;

  const RoomsLoaded(this.rooms);

  @override
  List<Object> get props => [rooms];
}

class RoomFailure extends RoomState {
  final String error;

  const RoomFailure(this.error);

  @override
  List<Object> get props => [error];
}
