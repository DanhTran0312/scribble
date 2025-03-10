import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user.dart';
import '../theme/app_theme.dart';

class PlayerListWidget extends StatefulWidget {
  final List<User> players;
  final String currentUserId;
  final bool showScore;
  final String? drawerUserId;
  final bool showAvatar;
  final bool compact;
  final bool animateOnNewPlayers;

  const PlayerListWidget({
    super.key,
    required this.players,
    required this.currentUserId,
    this.showScore = false,
    this.drawerUserId,
    this.showAvatar = true,
    this.compact = false,
    this.animateOnNewPlayers = true,
  });

  @override
  State<PlayerListWidget> createState() => _PlayerListWidgetState();
}

class _PlayerListWidgetState extends State<PlayerListWidget> {
  List<String> _previousPlayerIds = [];
  List<String> _newPlayerIds = [];

  @override
  void initState() {
    super.initState();
    _previousPlayerIds = widget.players.map((p) => p.id).toList();
  }

  @override
  void didUpdateWidget(covariant PlayerListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.animateOnNewPlayers) {
      // Check for new players
      final oldIds = oldWidget.players.map((p) => p.id).toList();
      final currentIds = widget.players.map((p) => p.id).toList();

      _newPlayerIds = currentIds.where((id) => !oldIds.contains(id)).toList();

      // Clear new player IDs after 2 seconds
      if (_newPlayerIds.isNotEmpty) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _newPlayerIds = [];
            });
          }
        });
      }

      _previousPlayerIds = currentIds;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort players: drawer first (if game is active), then by score or readiness
    final sortedPlayers = List<User>.from(widget.players);

    sortedPlayers.sort((a, b) {
      // Drawer first (if specified)
      if (widget.drawerUserId != null) {
        if (a.id == widget.drawerUserId) return -1;
        if (b.id == widget.drawerUserId) return 1;
      }

      // Host second
      if (a.isHost && !b.isHost) return -1;
      if (!a.isHost && b.isHost) return 1;

      // Then by score (if showing scores)
      if (widget.showScore) {
        return b.score.compareTo(a.score);
      }

      // Finally by readiness (if not showing scores)
      if (a.isReady != b.isReady) {
        return a.isReady ? -1 : 1;
      }

      // Default to name
      return a.username.compareTo(b.username);
    });

    // If compact mode, use a more space-efficient layout
    if (widget.compact) {
      return _buildCompactLayout(sortedPlayers);
    }

    return _buildStandardLayout(sortedPlayers);
  }

  Widget _buildStandardLayout(List<User> sortedPlayers) {
    return Column(
      children: [
        // Header with player count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              const Icon(Icons.people, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Players',
                style: GoogleFonts.fredoka(
                  color: AppTheme.primaryColor,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  '${sortedPlayers.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Empty state
        if (sortedPlayers.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No Players',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Waiting for players to join...',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),

        // Player list
        if (sortedPlayers.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: sortedPlayers.length,
              itemBuilder: (context, index) {
                final player = sortedPlayers[index];

                return _buildPlayerItem(
                  context,
                  player,
                  rank: widget.showScore ? index + 1 : null,
                  isNewPlayer: _newPlayerIds.contains(player.id),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCompactLayout(List<User> sortedPlayers) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: sortedPlayers.length + 1, // +1 for header
      itemBuilder: (context, index) {
        // Header
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.people,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Players (${sortedPlayers.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        // Player items
        final player = sortedPlayers[index - 1];
        return _buildCompactPlayerItem(
          context,
          player,
          isNewPlayer: _newPlayerIds.contains(player.id),
        );
      },
    );
  }

  Widget _buildPlayerItem(
    BuildContext context,
    User player, {
    int? rank,
    bool isNewPlayer = false,
  }) {
    final isCurrentUser = player.id == widget.currentUserId;
    final isDrawing = player.id == widget.drawerUserId;
    final isReady = player.isReady || player.isHost;

    // Animation for new players
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: isNewPlayer ? 0.0 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Transform.translate(
            offset: Offset(isNewPlayer ? (1.0 - value) * 50 : 0, 0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: _getPlayerItemBackgroundColor(
            isCurrentUser,
            isDrawing,
            isNewPlayer,
          ),
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Rank badge or status icon
            if (rank != null) ...[
              _buildRankBadge(rank),
              const SizedBox(width: 12),
            ],

            // Avatar
            if (widget.showAvatar) ...[
              _buildPlayerAvatar(player, isDrawing),
              const SizedBox(width: 16),
            ],

            // Username and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username row with badges
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.username,
                          style: TextStyle(
                            fontWeight:
                                isCurrentUser || isDrawing || player.isHost
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            fontSize: 16,
                            color: isDrawing ? AppTheme.secondaryColor : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      if (isCurrentUser)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Status indicators
                  Row(
                    children: [
                      // Role indicators
                      if (player.isHost)
                        _buildStatusTag(
                          label: 'Host',
                          iconData: Icons.star,
                          color: Colors.amber,
                        ),

                      if (isDrawing && widget.showScore)
                        _buildStatusTag(
                          label: 'Drawing',
                          iconData: Icons.brush,
                          color: AppTheme.secondaryColor,
                        ),

                      // Readiness indicator (in lobby) or Guessed indicator (in game)
                      if (!widget.showScore && !player.isHost)
                        _buildStatusTag(
                          label: isReady ? 'Ready' : 'Not Ready',
                          iconData:
                              isReady
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                          color: isReady ? Colors.green : Colors.grey,
                        ),

                      if (widget.showScore && !isDrawing && player.isReady)
                        _buildStatusTag(
                          label: 'Guessed!',
                          iconData: Icons.check_circle,
                          color: Colors.green,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Score or Ready indicator
            if (widget.showScore)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isDrawing
                          ? AppTheme.secondaryColor.withOpacity(0.1)
                          : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDrawing
                            ? AppTheme.secondaryColor.withOpacity(0.3)
                            : AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  player.score.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color:
                        isDrawing
                            ? AppTheme.secondaryColor
                            : AppTheme.primaryColor,
                  ),
                ),
              ),

            // Ready indicator (if not showing score)
            if (!widget.showScore && !player.isHost)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color:
                      player.isReady
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        player.isReady
                            ? Colors.green.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.5),
                  ),
                ),
                child: Icon(
                  player.isReady ? Icons.check : Icons.hourglass_empty,
                  color: player.isReady ? Colors.green : Colors.grey,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPlayerItem(
    BuildContext context,
    User player, {
    bool isNewPlayer = false,
  }) {
    final isCurrentUser = player.id == widget.currentUserId;
    final isDrawing = player.id == widget.drawerUserId;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: isNewPlayer ? 0.0 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(isNewPlayer ? (1.0 - value) * 30 : 0, 0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: _getPlayerItemBackgroundColor(
            isCurrentUser,
            isDrawing,
            isNewPlayer,
          ),
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Avatar with status indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: _getAvatarColor(player, isDrawing),
                  child: Text(
                    player.username.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),

                if (widget.showScore && player.isReady && !isDrawing)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 1,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 6,
                        color: Colors.white,
                      ),
                    ),
                  ),

                if (isDrawing)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 1,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.brush,
                        size: 6,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 8),

            // Username with badges
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      player.username,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isCurrentUser || isDrawing || player.isHost
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color: isDrawing ? AppTheme.secondaryColor : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  if (isCurrentUser)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      child: Text(
                        '(You)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Role icons
            if (player.isHost)
              const Padding(
                padding: EdgeInsets.only(right: 4.0),
                child: Icon(Icons.star, size: 14, color: Colors.amber),
              ),

            // Ready status
            if (!widget.showScore && !player.isHost)
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  player.isReady ? Icons.check_circle : Icons.circle_outlined,
                  size: 14,
                  color: player.isReady ? Colors.green : Colors.grey,
                ),
              ),

            // Score
            if (widget.showScore)
              Text(
                player.score.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDrawing ? AppTheme.secondaryColor : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    switch (rank) {
      case 1:
        badgeColor = Colors.amber;
        break;
      case 2:
        badgeColor = Colors.grey.shade400;
        break;
      case 3:
        badgeColor = Colors.brown.shade300;
        break;
      default:
        badgeColor = Colors.grey.shade700;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: badgeColor),
        boxShadow: rank <= 3 ? AppTheme.smallShadow : null,
      ),
      child: Center(
        child: Text(
          rank.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: badgeColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar(User player, bool isDrawing) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: _getAvatarColor(player, isDrawing),
          child: Text(
            player.username.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        if (isDrawing)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: AppTheme.smallShadow,
              ),
              child: const Icon(Icons.brush, size: 12, color: Colors.white),
            ),
          ),

        if (player.isHost)
          Positioned(
            right: isDrawing ? null : -2,
            left: isDrawing ? -2 : null,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: AppTheme.smallShadow,
              ),
              child: const Icon(Icons.star, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusTag({
    required String label,
    required IconData iconData,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(User player, bool isDrawing) {
    if (isDrawing) return AppTheme.secondaryColor;
    if (player.isHost) return Colors.amber;
    return AppTheme.primaryColor;
  }

  Color _getPlayerItemBackgroundColor(
    bool isCurrentUser,
    bool isDrawing,
    bool isNewPlayer,
  ) {
    if (isNewPlayer) return Colors.yellow.withOpacity(0.1);
    if (isCurrentUser) return AppTheme.primaryColor.withOpacity(0.05);
    if (isDrawing) return AppTheme.secondaryColor.withOpacity(0.05);
    return Colors.transparent;
  }
}
