import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/room_bloc.dart';
import '../bloc/room_event.dart';
import '../bloc/room_state.dart';
import '../models/room.dart';
import '../theme/app_theme.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _passwordController = TextEditingController();
  Room? _selectedRoom;
  bool _isShowingPasswordDialog = false;
  String _searchQuery = '';
  String _selectedFilterStatus = 'All';
  bool _showFilters = false;

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
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RoomLoading) {
            return _buildLoadingState();
          }

          if (state is RoomsLoaded) {
            // Apply search filter
            var filteredRooms = state.rooms;
            if (_searchQuery.isNotEmpty) {
              filteredRooms =
                  filteredRooms
                      .where(
                        (room) =>
                            room.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            (room.host?.username.toLowerCase() ?? '').contains(
                              _searchQuery.toLowerCase(),
                            ),
                      )
                      .toList();
            }

            // Apply status filter
            if (_selectedFilterStatus != 'All') {
              if (_selectedFilterStatus == 'Waiting') {
                filteredRooms =
                    filteredRooms
                        .where((room) => room.status == RoomStatus.waiting)
                        .toList();
              } else if (_selectedFilterStatus == 'Available') {
                filteredRooms =
                    filteredRooms.where((room) => !room.isFull).toList();
              } else if (_selectedFilterStatus == 'Public') {
                filteredRooms =
                    filteredRooms.where((room) => !room.isPrivate).toList();
              }
            }

            if (filteredRooms.isEmpty) {
              return _buildEmptyState(state.rooms.isEmpty);
            }

            return _buildRoomList(filteredRooms);
          }

          return _buildErrorState();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/create-room');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Room'),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Rooms...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool noRooms) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noRooms ? Icons.meeting_room_outlined : Icons.search_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              noRooms ? 'No Rooms Available' : 'No Matching Rooms',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              noRooms
                  ? 'Be the first to create a room and invite friends to play!'
                  : 'Try different search terms or filters',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                if (noRooms) {
                  context.go('/create-room');
                } else {
                  setState(() {
                    _searchQuery = '';
                    _selectedFilterStatus = 'All';
                  });
                  context.read<RoomBloc>().add(RoomLoadAvailable());
                }
              },
              icon: Icon(noRooms ? Icons.add : Icons.refresh),
              label: Text(noRooms ? 'Create Room' : 'Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    noRooms ? AppTheme.secondaryColor : AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.errorColor.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to Load Rooms',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.read<RoomBloc>().add(RoomLoadAvailable());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList(List<Room> rooms) {
    return Column(
      children: [
        // Search bar and filters
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Column(
            children: [
              // Search bar
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search rooms or hosts...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              // Filters
              if (_showFilters)
                AnimatedContainer(
                  duration: AppTheme.shortAnimationDuration,
                  margin: const EdgeInsets.only(top: 16),
                  height: _showFilters ? null : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            _buildFilterChip('Waiting'),
                            _buildFilterChip('Available'),
                            _buildFilterChip('Public'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Room count
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Row(
            children: [
              Text(
                '${rooms.length} room${rooms.length == 1 ? '' : 's'} available',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              Text(
                'Tap a room to join',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Room list
        Expanded(
          child: ListView.builder(
            itemCount: rooms.length,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _buildRoomCard(context, room);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilterStatus == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterStatus = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, Room room) {
    final isWaiting = room.status == RoomStatus.waiting;
    final isFull = room.players.length >= room.maxPlayers;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: isFull ? null : () => _joinRoom(room),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room header with status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  _buildStatusBadge(room),
                ],
              ),

              const SizedBox(height: 8),

              // Host info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Host: ${room.host?.username ?? 'Unknown'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  if (room.isPrivate)
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Private',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Room details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailColumn(
                    icon: Icons.people,
                    title: 'Players',
                    value: '${room.players.length}/${room.maxPlayers}',
                    warning: isFull,
                  ),
                  _buildDetailColumn(
                    icon: Icons.repeat,
                    title: 'Rounds',
                    value: '${room.maxRounds}',
                  ),
                  _buildDetailColumn(
                    icon: Icons.timer,
                    title: 'Time',
                    value: '${room.drawingTimeSeconds}s',
                  ),
                  if (room.useAI)
                    _buildDetailColumn(
                      icon: Icons.auto_fix_high,
                      title: 'AI',
                      value: 'Enabled',
                      highlight: true,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Join button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isFull ? null : () => _joinRoom(room),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isWaiting
                            ? AppTheme.primaryColor
                            : Colors.grey.shade400,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isFull
                        ? 'Room Full'
                        : isWaiting
                        ? 'Join Room'
                        : 'Game In Progress',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Room room) {
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    switch (room.status) {
      case RoomStatus.waiting:
        badgeColor = Colors.green;
        statusText = 'Waiting';
        statusIcon = Icons.hourglass_empty;
        break;
      case RoomStatus.playing:
        badgeColor = Colors.blue;
        statusText = 'Playing';
        statusIcon = Icons.sports_esports;
        break;
      case RoomStatus.finished:
        badgeColor = Colors.grey;
        statusText = 'Finished';
        statusIcon = Icons.done_all;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn({
    required IconData icon,
    required String title,
    required String value,
    bool warning = false,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color:
              warning
                  ? AppTheme.errorColor
                  : highlight
                  ? AppTheme.accentColor
                  : Colors.grey.shade600,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color:
                warning
                    ? AppTheme.errorColor
                    : highlight
                    ? AppTheme.accentColor
                    : Colors.black,
          ),
        ),
      ],
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
            title: Text('Enter Password for "${room.name}"'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This is a private room created by ${room.host?.username ?? "Unknown"}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                  autofocus: true,
                  onSubmitted: (_) {
                    Navigator.of(context).pop();
                    _submitPassword();
                  },
                ),
              ],
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
                  _submitPassword();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Join Room'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
  }

  void _submitPassword() {
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
  }
}
