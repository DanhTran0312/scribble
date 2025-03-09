import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scribble/bloc/auth_bloc.dart';
import 'package:scribble/bloc/auth_state.dart';
import 'screens/home_screen.dart';
import 'screens/create_room_screen.dart';
import 'screens/join_room_screen.dart';
import 'screens/game_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

class DoodleGuessApp extends StatefulWidget {
  const DoodleGuessApp({Key? key}) : super(key: key);

  @override
  State<DoodleGuessApp> createState() => _DoodleGuessAppState();
}

class _DoodleGuessAppState extends State<DoodleGuessApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/create-room',
          builder: (context, state) => const CreateRoomScreen(),
        ),
        GoRoute(
          path: '/join-room',
          builder: (context, state) => const JoinRoomScreen(),
        ),
        GoRoute(
          path: '/game/:roomId',
          builder: (context, state) {
            final roomId = state.pathParameters['roomId']!;
            return GameScreen(roomId: roomId);
          },
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final loggedIn = authState is AuthAuthenticated;

        // If user is not logged in and not on home page, redirect to home
        final isGoingToLogin = state.path == '/';
        if (!loggedIn && !isGoingToLogin) {
          return '/';
        }

        // Allow access to all other routes
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Doodle Guess',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
