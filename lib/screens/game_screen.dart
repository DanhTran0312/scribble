import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';
import '../models/game_round.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_drawing_controls.dart';
import '../widgets/chat_box.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/player_list.dart';
import '../widgets/round_info.dart';
import '../widgets/timer_widget.dart';
import '../widgets/word_selection.dart';

class GameScreen extends StatefulWidget {
  final String roomId;

  const GameScreen({super.key, required this.roomId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  Timer? _gameTimer;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // UI state
  bool _showPlayerList = true;
  bool _showChat = true;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Join the game
    context.read<GameBloc>().add(GameJoined(widget.roomId));
  }

  @override
  void dispose() {
    // Leave the game
    context.read<GameBloc>().add(GameLeft());

    // Cancel timer
    _gameTimer?.cancel();

    // Dispose animation
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<GameBloc, GameState>(
          builder: (context, state) {
            if (state is GameInLobby) {
              return Text('Lobby: ${state.room.name}');
            } else if (state is GamePlaying) {
              return Text('Playing: ${state.room.name}');
            }
            return const Text('Doodle Guess');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showGameHelp();
            },
            tooltip: 'Game Rules',
          ),
        ],
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _showLeaveGameDialog();
                },
                tooltip: 'Leave Game',
              ),
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
            return _buildLoadingState();
          }

          if (state is GameFailure) {
            return _buildErrorState(state);
          }

          if (state is GameInLobby) {
            return _buildLobbyState(state);
          }

          if (state is GamePlaying) {
            return _buildGamePlayingState(state);
          }

          if (state is GameRoundFinished) {
            return _buildRoundFinishedState(state);
          }

          if (state is GameFinished) {
            return _buildGameFinishedState(state);
          }

          return const Center(child: Text('Unknown game state'));
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
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Joining Game...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connecting to room: ${widget.roomId}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(GameFailure state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorColor.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Game Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.error,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/');
              },
              icon: const Icon(Icons.home),
              label: const Text('Return to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
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

  Widget _buildLobbyState(GameInLobby state) {
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isHost = currentUser?.id == state.room.host?.id;
    final readyPlayers =
        state.room.players.where((p) => p.isReady || p.isHost).length;
    final totalPlayers = state.room.players.length;
    final canStart = readyPlayers == totalPlayers && totalPlayers >= 2;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryColor.withOpacity(0.05), Colors.white],
        ),
      ),
      child: Column(
        children: [
          // Room info card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Room info header
                    Row(
                      children: [
                        Icon(
                          Icons.meeting_room,
                          size: 24,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.room.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Host: ${state.room.host?.username ?? 'Unknown'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Room status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.hourglass_empty,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Waiting',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Game settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSettingColumn(
                          icon: Icons.people,
                          label: 'Players',
                          value:
                              '${state.room.players.length}/${state.room.maxPlayers}',
                        ),
                        _buildSettingColumn(
                          icon: Icons.repeat,
                          label: 'Rounds',
                          value: state.room.maxRounds.toString(),
                        ),
                        _buildSettingColumn(
                          icon: Icons.timer,
                          label: 'Time per Round',
                          value: '${state.room.drawingTimeSeconds}s',
                        ),
                        if (state.room.useAI)
                          _buildSettingColumn(
                            icon: Icons.auto_fix_high,
                            label: 'AI Drawing',
                            value: 'Enabled',
                            highlight: true,
                          ),
                        if (state.room.isPrivate)
                          _buildSettingColumn(
                            icon: Icons.lock,
                            label: 'Private Room',
                            value: 'Yes',
                          ),
                      ],
                    ),

                    // Room code for sharing
                    if (isHost) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Room Code:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      widget.roomId,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'monospace',
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.content_copy,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        // Copy to clipboard functionality
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Room code copied to clipboard!',
                                            ),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      tooltip: 'Copy Room Code',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Share functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Share feature coming soon!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Player list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.people),
                          const SizedBox(width: 8),
                          const Text(
                            'Players',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$readyPlayers/$totalPlayers Ready',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: canStart ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: PlayerListWidget(
                        players: state.room.players,
                        currentUserId: currentUser?.id ?? '',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Ready button or start game button
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child:
                isHost
                    ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canStart ? _startGame : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: const Text(
                          'Start Game',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    : Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Waiting for the host to start the game...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Toggle ready status
                                final isCurrentlyReady =
                                    state.room.players
                                        .firstWhere(
                                          (p) => p.id == currentUser?.id,
                                        )
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
                                    _getReadyStatus(
                                          state,
                                          currentUser?.id ?? '',
                                        )
                                        ? Colors.green
                                        : AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                              ),
                              child: Text(
                                _getReadyStatus(state, currentUser?.id ?? '')
                                    ? 'Ready!'
                                    : 'Not Ready',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamePlayingState(GamePlaying state) {
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

    // Check if user wants to use AI drawing tool
    if (state.isDrawingTurn &&
        state.round.status == RoundStatus.drawing &&
        state.room.useAI) {
      // Show AI drawing button
      final aiDrawButton = Positioned(
        top: 16,
        right: 16,
        child: FloatingActionButton(
          heroTag: 'ai_draw_button',
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AiDrawingControls(currentWord: state.round.word),
                  ),
            );
          },
          backgroundColor: AppTheme.accentColor,
          foregroundColor: Colors.black,
          elevation: 4,
          tooltip: 'Use AI Drawing',
          child: const Icon(Icons.auto_fix_high),
        ),
      );
    }

    return FadeTransition(
      opacity: _slideAnimation,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Game info bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: AppTheme.smallShadow,
                ),
                child: Row(
                  children: [
                    // Round info
                    Expanded(
                      child: RoundInfoWidget(
                        currentRound: state.round.roundNumber,
                        totalRounds: state.room.maxRounds,
                        drawerName: state.round.drawerUser.username,
                      ),
                    ),

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
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Word: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getWordHint(state.round.word),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        ' (${state.round.word.length} letters)',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

              // Current word (if drawer)
              if (state.isDrawingTurn && state.round.word.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.brush, color: AppTheme.secondaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Draw: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        state.round.word,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

              // Main content - Drawing canvas and sidebar
              Expanded(
                child: Row(
                  children: [
                    // Drawing canvas area
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          Center(
                            child: DrawingCanvas(
                              isDrawingTurn: state.isDrawingTurn,
                              isAiMode: state.room.useAI,
                              canvasWidth:
                                  MediaQuery.of(context).size.width * 0.65,
                              canvasHeight:
                                  MediaQuery.of(context).size.height * 0.5,
                            ),
                          ),

                          // Floating AI button (if applicable)
                          if (state.isDrawingTurn &&
                              state.round.status == RoundStatus.drawing &&
                              state.room.useAI)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: FloatingActionButton(
                                heroTag: 'ai_draw_button',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: AiDrawingControls(
                                            currentWord: state.round.word,
                                          ),
                                        ),
                                  );
                                },
                                backgroundColor: AppTheme.accentColor,
                                foregroundColor: Colors.black,
                                elevation: 4,
                                tooltip: 'Use AI Drawing',
                                child: const Icon(Icons.auto_fix_high),
                              ),
                            ),

                          // Toggle sidebar buttons
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FloatingActionButton.small(
                                  heroTag: 'toggle_players',
                                  onPressed: () {
                                    setState(() {
                                      _showPlayerList = !_showPlayerList;
                                    });
                                  },
                                  backgroundColor:
                                      _showPlayerList
                                          ? AppTheme.primaryColor
                                          : Colors.grey.shade300,
                                  foregroundColor:
                                      _showPlayerList
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                  tooltip:
                                      _showPlayerList
                                          ? 'Hide Players'
                                          : 'Show Players',
                                  child: const Icon(Icons.people),
                                ),
                                const SizedBox(height: 8),
                                FloatingActionButton.small(
                                  heroTag: 'toggle_chat',
                                  onPressed: () {
                                    setState(() {
                                      _showChat = !_showChat;
                                    });
                                  },
                                  backgroundColor:
                                      _showChat
                                          ? AppTheme.primaryColor
                                          : Colors.grey.shade300,
                                  foregroundColor:
                                      _showChat
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                  tooltip:
                                      _showChat ? 'Hide Chat' : 'Show Chat',
                                  child: const Icon(Icons.chat),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sidebar with player list and chat
                    if (_showPlayerList || _showChat)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Player list
                              if (_showPlayerList)
                                Expanded(
                                  flex: 1,
                                  child: PlayerListWidget(
                                    players: state.room.players,
                                    currentUserId: currentUser?.id ?? '',
                                    showScore: true,
                                    drawerUserId: state.round.drawerUser.id,
                                  ),
                                ),

                              // Divider between player list and chat
                              if (_showPlayerList && _showChat)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),

                              // Chat
                              if (_showChat)
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
          ),
        ),
      ),
    );
  }

  Widget _buildRoundFinishedState(GameRoundFinished state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryColor.withOpacity(0.1), Colors.white],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trophy icon
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          size: 64,
                          color: Colors.amber,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Round finished text
                      Text(
                        'Round ${state.round.roundNumber} Finished!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Word reveal
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'The word was: ',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            TextSpan(
                              text: state.round.word,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Scores section
                      const Text(
                        'Scores This Round',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Score list
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: state.room.players.length,
                            itemBuilder: (context, index) {
                              final player = state.room.players[index];
                              final roundScore =
                                  state.playerScores[player.id] ?? 0;

                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                      width:
                                          index < state.room.players.length - 1
                                              ? 1
                                              : 0,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        player.id == state.round.drawerUser.id
                                            ? AppTheme.secondaryColor
                                            : AppTheme.primaryColor,
                                    child:
                                        player.id == state.round.drawerUser.id
                                            ? const Icon(
                                              Icons.brush,
                                              color: Colors.white,
                                              size: 18,
                                            )
                                            : Text(
                                              player.username
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                  ),
                                  title: Text(
                                    player.username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          player.id == state.round.drawerUser.id
                                              ? AppTheme.secondaryColor
                                              : null,
                                    ),
                                  ),
                                  subtitle:
                                      player.id == state.round.drawerUser.id
                                          ? const Text('Artist')
                                          : null,
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
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.add,
                                                size: 14,
                                                color: Colors.green,
                                              ),
                                              Text(
                                                roundScore.toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      Text(
                                        player.score.toString(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Next round indicator
                      if (state.round.roundNumber < state.room.maxRounds)
                        const Column(
                          children: [
                            Text(
                              'Next round starting soon...',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ],
                        )
                      else
                        const Column(
                          children: [
                            Text(
                              'Game ending soon...',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameFinishedState(GameFinished state) {
    // Find top 3 players
    final sortedPlayers = List<User>.from(state.room.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    final winner = sortedPlayers.first;
    final hasSecond = sortedPlayers.length > 1;
    final hasThird = sortedPlayers.length > 2;

    final second = hasSecond ? sortedPlayers[1] : null;
    final third = hasThird ? sortedPlayers[2] : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryColor.withOpacity(0.2), Colors.white],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Game finished banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Game Finished!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.room.name} • ${state.room.maxRounds} Rounds',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Winner announcement
                      Text(
                        '🏆 ${winner.username} wins! 🏆',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),

                      Text(
                        'with ${winner.score} points',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Podium visualization
                      SizedBox(
                        height: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (hasSecond)
                              _buildPodiumPosition(
                                context,
                                player: second!,
                                position: 2,
                                height: 80,
                              ),

                            _buildPodiumPosition(
                              context,
                              player: winner,
                              position: 1,
                              height: 120,
                            ),

                            if (hasThird)
                              _buildPodiumPosition(
                                context,
                                player: third!,
                                position: 3,
                                height: 60,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Final scores header
                      const Row(
                        children: [
                          Icon(Icons.leaderboard),
                          SizedBox(width: 8),
                          Text(
                            'Final Scores',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Score list
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: sortedPlayers.length,
                          itemBuilder: (context, index) {
                            final player = sortedPlayers[index];
                            final position = index + 1;

                            Color positionColor;
                            if (position == 1)
                              positionColor = Colors.amber;
                            else if (position == 2)
                              positionColor = Colors.grey.shade400;
                            else if (position == 3)
                              positionColor = Colors.brown.shade300;
                            else
                              positionColor = Colors.grey.shade700;

                            return Container(
                              decoration: BoxDecoration(
                                color:
                                    position == 1
                                        ? Colors.amber.withOpacity(0.1)
                                        : null,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width:
                                        index < sortedPlayers.length - 1
                                            ? 1
                                            : 0,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color:
                                        position <= 3
                                            ? positionColor.withOpacity(0.1)
                                            : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: positionColor),
                                  ),
                                  child: Center(
                                    child: Text(
                                      position.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: positionColor,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  player.username,
                                  style: TextStyle(
                                    fontWeight:
                                        position <= 3 ? FontWeight.bold : null,
                                  ),
                                ),
                                trailing: Text(
                                  player.score.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: position == 1 ? Colors.amber : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Back to home button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.go('/');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Back to Home',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Play again button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // Go to join room screen
                            context.go('/join-room');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Play Again',
                            style: TextStyle(
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingColumn({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: highlight ? AppTheme.accentColor : Colors.grey.shade700,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: highlight ? AppTheme.accentColor : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumPosition(
    BuildContext context, {
    required User player,
    required int position,
    required double height,
  }) {
    // Medal emoji based on position
    String medal;
    Color color;
    double avatarSize;

    if (position == 1) {
      medal = '🥇';
      color = Colors.amber;
      avatarSize = 60;
    } else if (position == 2) {
      medal = '🥈';
      color = Colors.grey.shade400;
      avatarSize = 50;
    } else {
      medal = '🥉';
      color = Colors.brown.shade300;
      avatarSize = 40;
    }

    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Medal emoji
          Text(medal, style: const TextStyle(fontSize: 24)),

          // Player avatar
          CircleAvatar(
            radius: avatarSize / 2,
            backgroundColor: color,
            child: Text(
              player.username.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: position == 1 ? 32 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Player name
          Text(
            player.username,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: position == 1 ? 16 : 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Player score
          Text(
            '${player.score} pts',
            style: TextStyle(
              fontSize: position == 1 ? 14 : 12,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 4),

          // Podium block
          Container(
            width: position == 1 ? 80 : 60,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              boxShadow: AppTheme.smallShadow,
            ),
            child: Center(
              child: Text(
                position.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _getReadyStatus(GameInLobby state, String userId) {
    final player = state.room.players.firstWhere(
      (p) => p.id == userId,
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

  void _showLeaveGameDialog() {
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
                  foregroundColor: Colors.white,
                ),
                child: const Text('Leave Game'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
  }

  void _showGameHelp() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Game Rules'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRuleItem(
                    icon: Icons.brush,
                    title: 'Drawing Phase',
                    description:
                        'Each round, one player draws a word while others guess.',
                  ),
                  const SizedBox(height: 16),
                  _buildRuleItem(
                    icon: Icons.chat,
                    title: 'Guessing',
                    description:
                        'Type your guesses in the chat. Be the first to guess correctly for more points!',
                  ),
                  const SizedBox(height: 16),
                  _buildRuleItem(
                    icon: Icons.timer,
                    title: 'Time Limit',
                    description:
                        'Each drawing phase has a time limit. Faster guesses earn more points!',
                  ),
                  const SizedBox(height: 16),
                  _buildRuleItem(
                    icon: Icons.emoji_events,
                    title: 'Scoring',
                    description:
                        'First player to guess gets more points. Drawing player earns points for each correct guess.',
                  ),
                  const SizedBox(height: 16),
                  _buildRuleItem(
                    icon: Icons.repeat,
                    title: 'Rounds',
                    description:
                        'Players take turns drawing. After all rounds, the player with the most points wins!',
                  ),
                  if (context.read<GameBloc>().state is GamePlaying &&
                      (context.read<GameBloc>().state as GamePlaying)
                          .room
                          .useAI) ...[
                    const SizedBox(height: 16),
                    _buildRuleItem(
                      icon: Icons.auto_fix_high,
                      title: 'AI Mode',
                      description:
                          'Drawing players can use AI to help draw complex concepts.',
                      color: AppTheme.accentColor,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Got it!'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required String title,
    required String description,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color ?? AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
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
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
