import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scribble/bloc/auth_bloc.dart';
import 'package:scribble/bloc/drawing_bloc.dart';
import 'package:scribble/bloc/game_bloc.dart';
import 'package:scribble/bloc/room_bloc.dart';

import 'app.dart';
import 'services/ai_drawing_service.dart';
import 'services/auth_service.dart';
import 'services/line_tracing_service.dart';
import 'services/room_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  final authService = AuthService();
  final roomService = RoomService();
  final aiDrawingService = AiDrawingService();
  final lineTracingService = LineTracingService();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authService: authService),
        ),
        BlocProvider<RoomBloc>(
          create: (_) => RoomBloc(roomService: roomService),
        ),
        BlocProvider<GameBloc>(
          create: (_) => GameBloc(roomService: roomService),
        ),
        BlocProvider<DrawingBloc>(
          create:
              (_) => DrawingBloc(
                aiDrawingService: aiDrawingService,
                lineTracingService: lineTracingService,
              ),
        ),
      ],
      child: const DoodleGuessApp(),
    ),
  );
}
