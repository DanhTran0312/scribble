import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scribble/bloc/game_bloc.dart';
import 'package:scribble/bloc/game_event.dart';
import 'package:scribble/bloc/room_bloc.dart';
import 'package:scribble/bloc/room_event.dart';
import 'package:scribble/bloc/room_state.dart';

import '../models/room.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _passwordController = TextEditingController();
  Room? _selectedRoom;
  bool _isShowingPasswordDialog = false;

  @override
  void initState() {
    super.initState();
    // Load available rooms
    context.read<RoomBloc>().add(RoomLoadAvailable());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Room'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<RoomBloc>().add(RoomLoadAvailable());
            },
          ),
        ],
      ),
      body: BlocConsumer<RoomBloc, RoomState>(
        listener: (context, state) {
          if (state is RoomJoined) {
            // Join the room with the game bloc
            context.read<GameBloc>().add(GameJoined(state.room.id));

            // Navigate to game screen
            context.go('/game/${state.room.id}');
          } else if (state is RoomFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        builder: (context, state) {
          if (state is RoomLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RoomsLoaded) {
            if (state.rooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.meeting_room_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No rooms available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try creating your own room or refresh',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<RoomBloc>().add(RoomLoadAvailable());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.go('/create-room');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Room'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text(
                        'Available Rooms',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${state.rooms.length} room${state.rooms.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: state.rooms.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemBuilder: (context, index) {
                      final room = state.rooms[index];
                      return _buildRoomCard(context, room);
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.go('/create-room');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Room'),
                    ),
                  ),
                ),
              ],
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load rooms',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<RoomBloc>().add(RoomLoadAvailable());
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, Room room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        onTap: () => _joinRoom(room),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (room.isPrivate)
                    const Icon(Icons.lock, color: Colors.grey),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Host: ${room.host?.username ?? 'Unknown'}',
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '${room.players.length}/${room.maxPlayers}',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.repeat,
                    label: '${room.maxRounds} rounds',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.timer,
                    label: '${room.drawingTimeSeconds}s',
                  ),

                  const Spacer(),

                  ElevatedButton(
                    onPressed: () => _joinRoom(room),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Join'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  void _joinRoom(Room room) {
    if (room.isPrivate) {
      _showPasswordDialog(room);
    } else {
      context.read<RoomBloc>().add(RoomJoinRequested(roomId: room.id));
    }
  }

  void _showPasswordDialog(Room room) {
    if (_isShowingPasswordDialog) return;

    setState(() {
      _isShowingPasswordDialog = true;
      _selectedRoom = room;
      _passwordController.clear();
    });

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Room Password'),
            content: TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _isShowingPasswordDialog = false;
                  });
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();

                  if (_selectedRoom != null) {
                    context.read<RoomBloc>().add(
                      RoomJoinRequested(
                        roomId: _selectedRoom!.id,
                        password: _passwordController.text,
                      ),
                    );
                  }

                  setState(() {
                    _isShowingPasswordDialog = false;
                  });
                },
                child: const Text('Join'),
              ),
            ],
          ),
    );
  }
}
