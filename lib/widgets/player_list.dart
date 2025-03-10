import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/app_theme.dart';

class PlayerListWidget extends StatelessWidget {
  final List<User> players;
  final String currentUserId;
  final bool showScore;
  final String? drawerUserId;
  final bool showAvatar;
  final bool compact;

  const PlayerListWidget({
    super.key,
    required this.players,
    required this.currentUserId,
    this.showScore = false,
    this.drawerUserId,
    this.showAvatar = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sort players: drawer first (if game is active), then by score or readiness
    final sortedPlayers = List<User>.from(players);

    sortedPlayers.sort((a, b) {
      // Drawer first (if specified)
      if (drawerUserId != null) {
        if (a.id == drawerUserId) return -1;
        if (b.id == drawerUserId) return 1;
      }

      // Host second
      if (a.isHost && !b.isHost) return -1;
      if (!a.isHost && b.isHost) return 1;

      // Then by score (if showing scores)
      if (showScore) {
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
    if (compact) {
      return ListView.builder(
        itemCount: sortedPlayers.length,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemBuilder:
            (context, index) =>
                _buildCompactPlayerItem(context, sortedPlayers[index]),
      );
    }

    return ListView.builder(
      itemCount: sortedPlayers.length,
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemBuilder:
          (context, index) => _buildPlayerItem(context, sortedPlayers[index]),
    );
  }

  Widget _buildPlayerItem(BuildContext context, User player) {
    final isCurrentUser = player.id == currentUserId;
    final isDrawing = player.id == drawerUserId;
    final isCorrectlyGuessed =
        player
            .isReady; // In game mode, "isReady" flag can be used for "has guessed correctly"

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color:
            isCurrentUser
                ? AppTheme.primaryColor.withOpacity(0.1)
                : isDrawing
                ? AppTheme.secondaryColor.withOpacity(0.05)
                : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Avatar or drawing indicator
          if (showAvatar)
            CircleAvatar(
              radius: 20,
              backgroundColor: _getAvatarColor(player, isDrawing),
              child: _getAvatarContent(player, isDrawing),
            ),

          const SizedBox(width: 16),

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
                          color: isDrawing ? AppTheme.secondaryColor : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    if (isCurrentUser)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          '(You)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
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

                    if (isDrawing && showScore)
                      _buildStatusTag(
                        label: 'Drawing',
                        iconData: Icons.brush,
                        color: AppTheme.secondaryColor,
                      ),

                    // Readiness indicator (in lobby) or Guessed indicator (in game)
                    if (!showScore && !player.isHost)
                      _buildStatusTag(
                        label: player.isReady ? 'Ready' : 'Not Ready',
                        iconData:
                            player.isReady
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                        color: player.isReady ? Colors.green : Colors.grey,
                      ),

                    if (showScore && !isDrawing && player.isReady)
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
          if (showScore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isDrawing
                        ? AppTheme.secondaryColor.withOpacity(0.1)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDrawing
                          ? AppTheme.secondaryColor.withOpacity(0.5)
                          : Colors.grey.shade300,
                ),
              ),
              child: Text(
                player.score.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDrawing ? AppTheme.secondaryColor : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactPlayerItem(BuildContext context, User player) {
    final isCurrentUser = player.id == currentUserId;
    final isDrawing = player.id == drawerUserId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color:
            isCurrentUser
                ? AppTheme.primaryColor.withOpacity(0.1)
                : isDrawing
                ? AppTheme.secondaryColor.withOpacity(0.05)
                : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Small avatar with status indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _getAvatarColor(player, isDrawing),
                child: _getAvatarContent(player, isDrawing, small: true),
              ),

              if (showScore && player.isReady && !isDrawing)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 8),

          // Username
          Expanded(
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

          // Role indicators
          if (player.isHost)
            const Icon(Icons.star, size: 14, color: Colors.amber),

          const SizedBox(width: 4),

          if (isDrawing && showScore)
            const Icon(Icons.brush, size: 14, color: AppTheme.secondaryColor),

          if (!showScore && !player.isHost) ...[
            const SizedBox(width: 4),
            Icon(
              player.isReady ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: player.isReady ? Colors.green : Colors.grey,
            ),
          ],

          // Score
          if (showScore) ...[
            const SizedBox(width: 8),
            Text(
              player.score.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDrawing ? AppTheme.secondaryColor : null,
              ),
            ),
          ],
        ],
      ),
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

  // Helper methods
  Color _getAvatarColor(User player, bool isDrawing) {
    if (isDrawing) return AppTheme.secondaryColor;
    if (player.isHost) return Colors.amber;
    return AppTheme.primaryColor;
  }

  Widget _getAvatarContent(User player, bool isDrawing, {bool small = false}) {
    if (isDrawing) {
      return Icon(Icons.brush, color: Colors.white, size: small ? 10 : 16);
    }

    if (player.isHost && !small) {
      return Stack(
        children: [
          Text(
            player.username.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: small ? 10 : 14,
            ),
          ),
          const Positioned(
            right: -4,
            top: -4,
            child: Icon(Icons.star, color: Colors.white, size: 12),
          ),
        ],
      );
    }

    return Text(
      player.username.substring(0, 1).toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: small ? 10 : 14,
      ),
    );
  }
}
