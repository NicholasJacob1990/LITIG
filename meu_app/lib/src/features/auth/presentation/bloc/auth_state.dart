import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/auth/domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial, antes de qualquer verificação
class AuthInitial extends AuthState {}

/// Estado de carregamento, durante operações assíncronas
class AuthLoading extends AuthState {}

/// Estado de sucesso, geralmente para mensagens informativas
class AuthSuccess extends AuthState {
  final String message;

  const AuthSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado quando o usuário está autenticado
class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Estado quando o usuário não está autenticado
class Unauthenticated extends AuthState {}

/// Estado de erro, contendo a mensagem de erro
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthRegistrationSuccess extends AuthState {
  final String message;
  const AuthRegistrationSuccess(this.message);
} 