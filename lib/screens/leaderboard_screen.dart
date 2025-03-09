import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scribble/bloc/auth_bloc.dart';
import 'package:scribble/bloc/auth_state.dart';

class LeaderboardItem {
  final String id;
  final String username;
  final String avatarUrl;
  final int totalScore;
  final int gamesPlayed;
  final int gamesWon;

  LeaderboardItem({
    required this.id,
    required this.username,
    this.avatarUrl = '',
    required this.totalScore,
    required this.gamesPlayed,
    required this.gamesWon,
  });
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _timeFilter = 'all_time'; // 'today', 'week', 'month', 'all_time'

  // Placeholder data for the leaderboard
  final List<LeaderboardItem> _leaderboardItems = [
    LeaderboardItem(
      id: '1',
      username: 'DrawMaster',
      totalScore: 9852,
      gamesPlayed: 42,
      gamesWon: 28,
    ),
    LeaderboardItem(
      id: '2',
      username: 'ArtGenius',
      totalScore: 8721,
      gamesPlayed: 39,
      gamesWon: 23,
    ),
    LeaderboardItem(
      id: '3',
      username: 'SketchKing',
      totalScore: 7645,
      gamesPlayed: 35,
      gamesWon: 19,
    ),
    LeaderboardItem(
      id: '4',
      username: 'PicassoPro',
      totalScore: 6932,
      gamesPlayed: 31,
      gamesWon: 17,
    ),
    LeaderboardItem(
      id: '5',
      username: 'DoodleQueen',
      totalScore: 5874,
      gamesPlayed: 27,
      gamesWon: 14,
    ),
    LeaderboardItem(
      id: '6',
      username: 'ArtistX',
      totalScore: 4983,
      gamesPlayed: 25,
      gamesWon: 12,
    ),
    LeaderboardItem(
      id: '7',
      username: 'PenMaster',
      totalScore: 4210,
      gamesPlayed: 22,
      gamesWon: 10,
    ),
    LeaderboardItem(
      id: '8',
      username: 'BrushNinja',
      totalScore: 3752,
      gamesPlayed: 19,
      gamesWon: 8,
    ),
    LeaderboardItem(
      id: '9',
      username: 'CreativeGeek',
      totalScore: 3125,
      gamesPlayed: 17,
      gamesWon: 7,
    ),
    LeaderboardItem(
      id: '10',
      username: 'SketchWizard',
      totalScore: 2843,
      gamesPlayed: 15,
      gamesWon: 6,
    ),
  ];

  int _getPlayerRank() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      // In a real app, this would query the server
      return 42; // Placeholder rank
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Simulate loading
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Top Players'), Tab(text: 'Friends')],
        ),
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : TabBarView(
                controller: _tabController,
                children: [_buildTopPlayersTab(), _buildFriendsTab()],
              ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading leaderboard...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPlayersTab() {
    return Column(
      children: [
        // Time filter
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterChip('Today', 'today'),
              _buildFilterChip('This Week', 'week'),
              _buildFilterChip('This Month', 'month'),
              _buildFilterChip('All Time', 'all_time'),
            ],
          ),
        ),

        // Top 3 players podium
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              _buildPodiumItem(
                _leaderboardItems[1],
                2,
                Colors.grey.shade300,
                80,
              ),

              // 1st place
              _buildPodiumItem(_leaderboardItems[0], 1, Colors.amber, 100),

              // 3rd place
              _buildPodiumItem(
                _leaderboardItems[2],
                3,
                Colors.brown.shade300,
                60,
              ),
            ],
          ),
        ),

        // Player's rank
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              final playerRank = _getPlayerRank();

              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Rank',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '#$playerRank',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Scroll to player's position (placeholder)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Feature coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),

        // Leaderboard list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _leaderboardItems.length,
            itemBuilder: (context, index) {
              final player = _leaderboardItems[index];
              final rank = index + 1;

              // Skip the top 3 players (they're shown in the podium)
              if (rank <= 3) {
                return const SizedBox.shrink();
              }

              return _buildLeaderboardItem(player, rank);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Friends Leaderboard',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add friends to see how you compare!',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Add friends (placeholder)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Friend system coming soon!')),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add Friends'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _timeFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _timeFilter = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumItem(
    LeaderboardItem player,
    int rank,
    Color color,
    double height,
  ) {
    return Column(
      children: [
        // Crown for 1st place
        if (rank == 1)
          const Icon(Icons.emoji_events, color: Colors.amber, size: 32),

        // Player avatar
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 40 : 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                player.username.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: rank == 1 ? 24 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Player name
        Text(
          player.username,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: rank == 1 ? 16 : 14,
          ),
        ),

        // Player score
        Text(
          '${player.totalScore} pts',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 8),

        // Podium
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(LeaderboardItem player, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Rank
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Player avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                player.username.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${player.gamesWon} wins / ${player.gamesPlayed} games',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${player.totalScore}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
