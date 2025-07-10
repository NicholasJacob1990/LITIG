import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthenticatedState extends AuthState {
  final dynamic user;
  final String userRole;

  const AuthenticatedState({
    required this.user,
    required this.userRole,
  });

  @override
  List<Object?> get props => [user, userRole];
}

class UnauthenticatedState extends AuthState {
  const UnauthenticatedState();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
} 