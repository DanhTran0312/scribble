import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc({required this.authService}) : super(AuthInitial()) {
    on<AuthLogin>(_onLogin);
    on<AuthLogout>(_onLogout);
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthUpdateUser>(_onUpdateUser);
  }

  Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final user = await authService.login(
        username: event.username,
        avatarUrl: event.avatarUrl,
      );

      emit(AuthAuthenticated(user));
    } catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      await authService.logout();
      emit(AuthUnauthenticated());
    } catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await authService.getCurrentUser();

      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  Future<void> _onUpdateUser(
    AuthUpdateUser event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      emit(AuthLoading());

      try {
        final updatedUser = await authService.updateUser(event.user);
        emit(AuthAuthenticated(updatedUser));
      } catch (error) {
        emit(AuthFailure(error.toString()));
        // Revert to previous state if update fails
        emit(currentState);
      }
    }
  }
}
