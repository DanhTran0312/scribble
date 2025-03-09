import 'package:equatable/equatable.dart';
import '../../models/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLogin extends AuthEvent {
  final String username;
  final String? avatarUrl;

  const AuthLogin({required this.username, this.avatarUrl});

  @override
  List<Object?> get props => [username, avatarUrl];
}

class AuthLogout extends AuthEvent {}

class AuthCheckStatus extends AuthEvent {}

class AuthUpdateUser extends AuthEvent {
  final User user;

  const AuthUpdateUser(this.user);

  @override
  List<Object> get props => [user];
}
