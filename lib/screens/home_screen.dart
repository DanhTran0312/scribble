import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scribble/bloc/auth_bloc.dart';
import 'package:scribble/bloc/auth_event.dart';
import 'package:scribble/bloc/auth_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Check if user is already logged in
    context.read<AuthBloc>().add(AuthCheckStatus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // User authenticated, show navigation options
          } else if (state is AuthFailure) {
            // Show error message
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AuthAuthenticated) {
            return _buildMainMenu(context, state);
          }

          return _buildLoginScreen(context);
        },
      ),
    );
  }

  Widget _buildLoginScreen(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo/title
                  Text(
                    'Doodle Guess',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Draw, Guess, and Have Fun!',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                  ),

                  const SizedBox(height: 48),

                  // Login form
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Enter a Username',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),

                          const SizedBox(height: 24),

                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.person),
                            ),
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                final username =
                                    _usernameController.text.trim();
                                if (username.isNotEmpty) {
                                  context.read<AuthBloc>().add(
                                    AuthLogin(username: username),
                                  );
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text('Start Playing'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMenu(BuildContext context, AuthAuthenticated state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Welcome message
                  Text(
                    'Welcome, ${state.user.username}!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Game options
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMenuButton(
                            context,
                            icon: Icons.add_circle,
                            text: 'Create Room',
                            onPressed: () {
                              context.push('/create-room');
                            },
                          ),

                          const SizedBox(height: 16),

                          _buildMenuButton(
                            context,
                            icon: Icons.login,
                            text: 'Join Room',
                            onPressed: () {
                              context.push('/join-room');
                            },
                          ),

                          const SizedBox(height: 16),

                          _buildMenuButton(
                            context,
                            icon: Icons.leaderboard,
                            text: 'Leaderboard',
                            onPressed: () {
                              context.push('/leaderboard');
                            },
                          ),

                          const SizedBox(height: 16),

                          _buildMenuButton(
                            context,
                            icon: Icons.settings,
                            text: 'Settings',
                            onPressed: () {
                              context.push('/settings');
                            },
                          ),

                          const SizedBox(height: 24),

                          // Logout button
                          TextButton.icon(
                            onPressed: () {
                              context.read<AuthBloc>().add(AuthLogout());
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(text, style: const TextStyle(fontSize: 16)),
        ),
        style: ElevatedButton.styleFrom(alignment: Alignment.centerLeft),
      ),
    );
  }
}
