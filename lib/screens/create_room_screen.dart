import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scribble/bloc/game_bloc.dart';
import 'package:scribble/bloc/game_event.dart';
import 'package:scribble/bloc/room_bloc.dart';
import 'package:scribble/bloc/room_event.dart';
import 'package:scribble/bloc/room_state.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();

  int _maxPlayers = 8;
  int _maxRounds = 3;
  int _drawingTime = 80;
  bool _isPrivate = false;
  final _passwordController = TextEditingController();
  bool _useAI = false;

  @override
  void dispose() {
    _roomNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Room')),
      body: BlocConsumer<RoomBloc, RoomState>(
        listener: (context, state) {
          if (state is RoomCreated) {
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

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room name
                    TextFormField(
                      controller: _roomNameController,
                      decoration: InputDecoration(
                        labelText: 'Room Name',
                        hintText: 'Enter a name for your room',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.meeting_room),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a room name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Max players slider
                    const Text(
                      'Maximum Players',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _maxPlayers.toDouble(),
                            min: 2,
                            max: 12,
                            divisions: 10,
                            label: _maxPlayers.toString(),
                            onChanged: (value) {
                              setState(() {
                                _maxPlayers = value.toInt();
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _maxPlayers.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Max rounds slider
                    const Text(
                      'Number of Rounds',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _maxRounds.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: _maxRounds.toString(),
                            onChanged: (value) {
                              setState(() {
                                _maxRounds = value.toInt();
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _maxRounds.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Drawing time slider
                    const Text(
                      'Drawing Time (seconds)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _drawingTime.toDouble(),
                            min: 30,
                            max: 180,
                            divisions: 15,
                            label: _drawingTime.toString(),
                            onChanged: (value) {
                              setState(() {
                                _drawingTime = value.toInt();
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _drawingTime.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Private room switch
                    SwitchListTile(
                      title: const Text(
                        'Private Room',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Only players with the password can join',
                      ),
                      value: _isPrivate,
                      onChanged: (value) {
                        setState(() {
                          _isPrivate = value;
                        });
                      },
                    ),

                    if (_isPrivate) ...[
                      const SizedBox(height: 16),

                      // Room password
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Room Password',
                          hintText: 'Enter a password for your room',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        validator: (value) {
                          if (_isPrivate && (value == null || value.isEmpty)) {
                            return 'Please enter a password for private room';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Use AI switch
                    SwitchListTile(
                      title: const Text(
                        'Enable AI Drawing Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'AI can generate and draw images from words',
                      ),
                      value: _useAI,
                      onChanged: (value) {
                        setState(() {
                          _useAI = value;
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    // Create room button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createRoom,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'Create Room',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _createRoom() {
    if (_formKey.currentState!.validate()) {
      context.read<RoomBloc>().add(
        RoomCreateRequested(
          roomName: _roomNameController.text.trim(),
          maxPlayers: _maxPlayers,
          maxRounds: _maxRounds,
          drawingTimeSeconds: _drawingTime,
          isPrivate: _isPrivate,
          password: _isPrivate ? _passwordController.text : null,
          useAI: _useAI,
        ),
      );
    }
  }
}
