import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scribble/bloc/auth_bloc.dart';
import 'package:scribble/bloc/auth_state.dart';
import 'package:scribble/bloc/game_bloc.dart';
import 'package:scribble/bloc/game_event.dart';
import 'package:scribble/bloc/game_state.dart';
import 'package:scribble/widgets/chat_box.dart';
import 'package:scribble/widgets/player_list.dart';
import 'package:scribble/widgets/round_info.dart';
import 'package:scribble/widgets/timer_widget.dart';
import 'package:scribble/widgets/word_selection.dart';

import '../models/game_round.dart';
import '../widgets/drawing_canvas.dart';

class GameScreen extends StatefulWidget {
  final String roomId;

  const GameScreen({super.key, required this.roomId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();

    // Join the game
    context.read<GameBloc>().add(GameJoined(widget.roomId));
  }

  @override
  void dispose() {
    // Leave the game
    context.read<GameBloc>().add(GameLeft());

    // Cancel timer
    _gameTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doodle Guess'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Leave Game?'),
                    content: const Text(
                      'Are you sure you want to leave the game? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Leave Game'),
                      ),
                    ],
                  ),
            );
          },
        ),
      ),
      body: BlocConsumer<GameBloc, GameState>(
        listener: (context, state) {
          if (state is GamePlaying) {
            // Start timer
            _startGameTimer(state);
          }
        },
        builder: (context, state) {
          if (state is GameInitial || state is GameLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GameFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Game Error: ${state.error}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      context.go('/');
                    },
                    child: const Text('Return to Home'),
                  ),
                ],
              ),
            );
          }

          if (state is GameInLobby) {
            return _buildLobbyScreen(context, state);
          }

          if (state is GamePlaying) {
            return _buildGamePlayingScreen(context, state);
          }

          if (state is GameRoundFinished) {
            return _buildRoundFinishedScreen(context, state);
          }

          if (state is GameFinished) {
            return _buildGameFinishedScreen(context, state);
          }

          return const Center(child: Text('Unknown game state'));
        },
      ),
    );
  }

  Widget _buildLobbyScreen(BuildContext context, GameInLobby state) {
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isHost = currentUser?.id == state.room.host?.id;

    return Column(
      children: [
        // Room info
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room: ${state.room.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Host: ${state.room.host?.username ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Copy code button
              OutlinedButton.icon(
                onPressed: () {
                  // Copy room code to clipboard
                  // In a real app, this would use clipboard functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room code copied to clipboard'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: Text(
                  state.room.id.substring(0, 6).toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Room settings
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withOpacity(0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSettingItem(
                icon: Icons.people,
                label: 'Players',
                value: '${state.room.players.length}/${state.room.maxPlayers}',
              ),
              _buildSettingItem(
                icon: Icons.repeat,
                label: 'Rounds',
                value: state.room.maxRounds.toString(),
              ),
              _buildSettingItem(
                icon: Icons.timer,
                label: 'Time',
                value: '${state.room.drawingTimeSeconds}s',
              ),
              if (state.room.useAI)
                _buildSettingItem(
                  icon: Icons.auto_fix_high,
                  label: 'AI Mode',
                  value: 'On',
                ),
            ],
          ),
        ),

        // Player list
        Expanded(
          child: PlayerListWidget(
            players: state.room.players,
            currentUserId: currentUser?.id ?? '',
          ),
        ),

        // Ready button or start game button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              isHost
                  ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canStartGame(state) ? _startGame : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text(
                        'Start Game',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  )
                  : Row(
                    children: [
                      const Text(
                        'Ready to play?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          // Toggle ready status
                          final isCurrentlyReady =
                              state.room.players
                                  .firstWhere((p) => p.id == currentUser?.id)
                                  .isReady;

                          context.read<GameBloc>().add(
                            GamePlayerReady(
                              playerId: currentUser?.id ?? '',
                              isReady: !isCurrentlyReady,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isPlayerReady(state, currentUser?.id ?? '')
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                        ),
                        child: Text(
                          _isPlayerReady(state, currentUser?.id ?? '')
                              ? 'Ready!'
                              : 'Not Ready',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildGamePlayingScreen(BuildContext context, GamePlaying state) {
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;

    // Check if it's word selection phase
    if (state.round.status == RoundStatus.choosing && state.isDrawingTurn) {
      return WordSelectionWidget(
        wordChoices: state.round.wordChoices,
        onWordSelected: (word) {
          context.read<GameBloc>().add(GameWordSelected(word));
        },
      );
    }

    return Column(
      children: [
        // Game info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              // Round info
              RoundInfoWidget(
                currentRound: state.round.roundNumber,
                totalRounds: state.room.maxRounds,
                drawerName: state.round.drawerUser.username,
              ),

              const Spacer(),

              // Timer
              TimerWidget(
                remainingSeconds: state.remainingTimeInSeconds,
                totalSeconds: state.room.drawingTimeSeconds,
              ),
            ],
          ),
        ),

        // Word hint (if not the drawer)
        if (!state.isDrawingTurn && state.round.word.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Word: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _getWordHint(state.round.word),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  ' (${state.round.word.length} letters)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

        // Current word (if drawer)
        if (state.isDrawingTurn && state.round.word.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Your word: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  state.round.word,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

        // Main content - Drawing canvas and chat
        Expanded(
          child: Row(
            children: [
              // Drawing canvas
              Expanded(
                flex: 2,
                child: Center(
                  child: DrawingCanvas(
                    isDrawingTurn: state.isDrawingTurn,
                    isAiMode: state.room.useAI,
                    canvasWidth: MediaQuery.of(context).size.width * 0.6,
                    canvasHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                ),
              ),

              // Chat and player list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Player list
                      Expanded(
                        flex: 1,
                        child: PlayerListWidget(
                          players: state.room.players,
                          currentUserId: currentUser?.id ?? '',
                          showScore: true,
                          drawerUserId: state.round.drawerUser.id,
                        ),
                      ),

                      // Chat
                      Expanded(
                        flex: 2,
                        child: ChatBoxWidget(
                          messages: state.round.messages,
                          currentUserId: currentUser?.id ?? '',
                          isDrawingTurn: state.isDrawingTurn,
                          onSendMessage: (message) {
                            if (!state.isDrawingTurn) {
                              context.read<GameBloc>().add(
                                GameGuessSubmitted(message),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoundFinishedScreen(
    BuildContext context,
    GameRoundFinished state,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'Round ${state.round.roundNumber} Finished!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The word was: ${state.round.word}',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Round scores
          const Text(
            'Scores:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Score list
          SizedBox(
            width: 300,
            height: 200,
            child: ListView.builder(
              itemCount: state.room.players.length,
              itemBuilder: (context, index) {
                final player = state.room.players[index];
                final roundScore = state.playerScores[player.id] ?? 0;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      player.username.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(player.username),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (roundScore > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '+$roundScore',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '${player.score}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          const Text(
            'Next round starting soon...',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameFinishedScreen(BuildContext context, GameFinished state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
          const SizedBox(height: 16),
          const Text(
            'Game Finished!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '${state.winner.username} wins with ${state.winner.score} points!',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Final scores
          const Text(
            'Final Scores:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Score list
          SizedBox(
            width: 300,
            height: 200,
            child: ListView.builder(
              itemCount: state.room.players.length,
              itemBuilder: (context, index) {
                final player = state.room.players[index];
                final isWinner = player.id == state.winner.id;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isWinner
                            ? Colors.amber
                            : Theme.of(context).colorScheme.primary,
                    child:
                        isWinner
                            ? const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                            )
                            : Text(
                              player.username.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                  title: Text(
                    player.username,
                    style: TextStyle(
                      fontWeight:
                          isWinner ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    '${player.score}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isWinner ? Colors.amber : null,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              context.go('/');
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  bool _canStartGame(GameInLobby state) {
    // Check if there are at least 2 players
    if (state.room.players.length < 2) {
      return false;
    }

    // Check if all players are ready (except the host)
    for (final player in state.room.players) {
      if (player.id != state.room.host?.id && !player.isReady) {
        return false;
      }
    }

    return true;
  }

  bool _isPlayerReady(GameInLobby state, String playerId) {
    final player = state.room.players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => throw Exception('Player not found'),
    );

    return player.isReady;
  }

  void _startGame() {
    context.read<GameBloc>().add(GameStarted());
  }

  void _startGameTimer(GamePlaying state) {
    // Cancel existing timer
    _gameTimer?.cancel();

    // Don't start timer if the game is not in drawing phase
    if (state.round.status != RoundStatus.drawing) {
      return;
    }

    // Start new timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remainingSeconds = state.remainingTimeInSeconds - 1;

      if (remainingSeconds <= 0) {
        timer.cancel();
      }

      context.read<GameBloc>().add(GameTimerTick(remainingSeconds));
    });
  }

  String _getWordHint(String word) {
    // Replace some characters with underscores
    final characters = word.split('');
    final hintCharacters = List<String>.from(characters);

    // Keep first and last letter, and show a proportion of the others
    const percentToReveal = 0.3;
    final revealCount = (characters.length * percentToReveal).ceil();

    // Always show first letter
    for (var i = 1; i < characters.length - 1; i++) {
      if (characters[i] == ' ') {
        // Keep spaces
        hintCharacters[i] = ' ';
      } else if (i > revealCount) {
        // Replace with underscore
        hintCharacters[i] = '_';
      }
    }

    return hintCharacters.join('');
  }
}
