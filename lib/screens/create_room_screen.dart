import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/room_bloc.dart';
import '../bloc/room_event.dart';
import '../bloc/room_state.dart';
import '../theme/app_theme.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  final _roomNameFocusNode = FocusNode();
  final _passwordController = TextEditingController();

  int _maxPlayers = 8;
  int _maxRounds = 3;
  int _drawingTime = 80;
  bool _isPrivate = false;
  bool _useAI = false;
  bool _isCreating = false;

  // For animated transitions
  bool _isAdvancedSettingsVisible = false;

  @override
  void dispose() {
    _roomNameController.dispose();
    _passwordController.dispose();
    _roomNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Room'), elevation: 0),
      body: BlocConsumer<RoomBloc, RoomState>(
        listener: (context, state) {
          if (state is RoomCreated) {
            // Join the room with the game bloc
            context.read<GameBloc>().add(GameJoined(state.room.id));

            // Navigate to game screen
            context.go('/game/${state.room.id}');
          } else if (state is RoomFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppTheme.errorColor,
              ),
            );
            setState(() {
              _isCreating = false;
            });
          }
        },
        builder: (context, state) {
          if (state is RoomLoading || _isCreating) {
            return _buildLoadingState();
          }

          return _buildCreateRoomForm();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Creating your room...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait a moment',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateRoomForm() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryColor.withOpacity(0.05), Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room creation card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header section
                        Row(
                          children: [
                            Icon(
                              Icons.meeting_room,
                              color: AppTheme.primaryColor,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Room Details',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Set up your drawing room',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Room name field
                        TextFormField(
                          controller: _roomNameController,
                          focusNode: _roomNameFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Room Name',
                            hintText: 'Enter a name for your room',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.edit),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a room name';
                            }
                            if (value.length < 3) {
                              return 'Room name must be at least 3 characters';
                            }
                            if (value.length > 20) {
                              return 'Room name must be less than 20 characters';
                            }
                            return null;
                          },
                          maxLength: 20,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () {
                            _roomNameFocusNode.unfocus();
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9 ]'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Basic settings
                        const Text(
                          'Basic Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Max players slider
                        _buildSliderSetting(
                          title: 'Maximum Players',
                          subtitle: 'How many players can join your room',
                          value: _maxPlayers.toDouble(),
                          min: 2,
                          max: 12,
                          divisions: 10,
                          valueLabel: _maxPlayers.toString(),
                          onChanged: (value) {
                            setState(() {
                              _maxPlayers = value.toInt();
                            });
                          },
                          leadingIcon: Icons.people,
                        ),

                        const SizedBox(height: 16),

                        // Switches for private and AI
                        _buildSwitchSetting(
                          title: 'Private Room',
                          subtitle: 'Require a password to join',
                          value: _isPrivate,
                          onChanged: (value) {
                            setState(() {
                              _isPrivate = value;
                            });
                          },
                          leadingIcon: Icons.lock,
                        ),

                        // Password field (conditional)
                        AnimatedCrossFade(
                          firstChild: Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Room Password',
                                hintText: 'Enter a password for your room',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.vpn_key),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (_isPrivate &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter a password for private room';
                                }
                                if (_isPrivate && value!.length < 4) {
                                  return 'Password must be at least 4 characters';
                                }
                                return null;
                              },
                              obscureText: true,
                              maxLength: 16,
                            ),
                          ),
                          secondChild: const SizedBox.shrink(),
                          crossFadeState:
                              _isPrivate
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                          duration: AppTheme.shortAnimationDuration,
                        ),

                        const SizedBox(height: 16),

                        _buildSwitchSetting(
                          title: 'AI Drawing Mode',
                          subtitle:
                              'Allow AI to generate drawings from word prompts',
                          value: _useAI,
                          onChanged: (value) {
                            setState(() {
                              _useAI = value;
                            });
                          },
                          leadingIcon: Icons.auto_fix_high,
                          color: AppTheme.accentColor,
                        ),

                        const SizedBox(height: 16),

                        // Advanced settings toggle
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isAdvancedSettingsVisible =
                                  !_isAdvancedSettingsVisible;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isAdvancedSettingsVisible
                                      ? 'Hide Advanced Settings'
                                      : 'Show Advanced Settings',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                Icon(
                                  _isAdvancedSettingsVisible
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Advanced settings (conditional)
                        AnimatedCrossFade(
                          firstChild: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),

                              const Text(
                                'Advanced Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Number of rounds slider
                              _buildSliderSetting(
                                title: 'Number of Rounds',
                                subtitle: 'How many rounds to play in total',
                                value: _maxRounds.toDouble(),
                                min: 1,
                                max: 10,
                                divisions: 9,
                                valueLabel: _maxRounds.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _maxRounds = value.toInt();
                                  });
                                },
                                leadingIcon: Icons.repeat,
                              ),

                              const SizedBox(height: 16),

                              // Drawing time slider
                              _buildSliderSetting(
                                title: 'Drawing Time',
                                subtitle: 'Seconds per drawing turn',
                                value: _drawingTime.toDouble(),
                                min: 30,
                                max: 180,
                                divisions: 15,
                                valueLabel: '${_drawingTime}s',
                                onChanged: (value) {
                                  setState(() {
                                    _drawingTime = value.toInt();
                                  });
                                },
                                leadingIcon: Icons.timer,
                              ),
                            ],
                          ),
                          secondChild: const SizedBox.shrink(),
                          crossFadeState:
                              _isAdvancedSettingsVisible
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                          duration: AppTheme.shortAnimationDuration,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Create room button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Create Room',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isCreating ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueLabel,
    required Function(double) onChanged,
    required IconData leadingIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(leadingIcon, color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                valueLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData leadingIcon,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(leadingIcon, color: color ?? Colors.grey.shade700, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color ?? AppTheme.primaryColor,
        ),
      ],
    );
  }

  void _createRoom() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCreating = true;
      });

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
