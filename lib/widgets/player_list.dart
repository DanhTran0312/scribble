import 'package:flutter/material.dart';

import '../models/user.dart';

class PlayerListWidget extends StatelessWidget {
  final List<User> players;
  final String currentUserId;
  final bool showScore;
  final String? drawerUserId;

  const PlayerListWidget({
    super.key,
    required this.players,
    required this.currentUserId,
    this.showScore = false,
    this.drawerUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Sort players: drawer first (if game is active), then by score
    final sortedPlayers = List<User>.from(players);

    sortedPlayers.sort((a, b) {
      // Drawer first (if specified)
      if (drawerUserId != null) {
        if (a.id == drawerUserId) return -1;
        if (b.id == drawerUserId) return 1;
      }

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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Players',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${players.length} player${players.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Player list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: sortedPlayers.length,
              itemBuilder: (context, index) {
                final player = sortedPlayers[index];
                return _buildPlayerItem(context, player);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerItem(BuildContext context, User player) {
    final isCurrentUser = player.id == currentUserId;
    final isDrawing = player.id == drawerUserId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color:
            isCurrentUser
                ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.1)
                : isDrawing
                ? Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withOpacity(0.1)
                : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor:
                isDrawing
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.primary,
            child: Text(
              player.username.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Username and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.username,
                      style: TextStyle(
                        fontWeight:
                            isCurrentUser || isDrawing
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (isCurrentUser)
                      Text(
                        '(You)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (player.isHost)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Host',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!showScore && !player.isHost)
                  Row(
                    children: [
                      Icon(
                        player.isReady
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 14,
                        color: player.isReady ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        player.isReady ? 'Ready' : 'Not ready',
                        style: TextStyle(
                          fontSize: 12,
                          color: player.isReady ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                if (isDrawing && showScore)
                  Row(
                    children: [
                      const Icon(Icons.brush, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Drawing',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Score
          if (showScore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                player.score.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
