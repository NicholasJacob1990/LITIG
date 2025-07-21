import 'package:equatable/equatable.dart';

/// Classe abstrata base para todas as falhas do sistema
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Falha de servidor/API
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Falha de cache local
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Falha de conexão de rede
class ConnectionFailure extends Failure {
  const ConnectionFailure({required super.message, super.code});
}

/// Falha de validação de dados
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

/// Falha de autenticação
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message, super.code});
}

/// Falha de autorização
class AuthorizationFailure extends Failure {
  const AuthorizationFailure({required super.message, super.code});
}

/// Falha de timeout
class TimeoutFailure extends Failure {
  const TimeoutFailure({required super.message, super.code});
}

/// Falha genérica do sistema
class GenericFailure extends Failure {
  const GenericFailure({required super.message, super.code});
}

/// Falha inesperada do sistema
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code});
}

/// Falha de não encontrado
class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.code});
}

/// Falha de dados inválidos
class InvalidDataFailure extends Failure {
  const InvalidDataFailure({required super.message, super.code});
}

/// Falha de permissão
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

/// Falha de formato de dados
class FormatFailure extends Failure {
  const FormatFailure({required super.message, super.code});
}

/// Falha de limite excedido
class LimitExceededFailure extends Failure {
  const LimitExceededFailure({required super.message, super.code});
}

/// Falha de recurso indisponível
class UnavailableFailure extends Failure {
  const UnavailableFailure({required super.message, super.code});
}

/// Falha de videochamada
class VideoCallFailure extends Failure {
  const VideoCallFailure({required super.message, super.code});
}

/// Falha de rede
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// Falha de autenticação
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}