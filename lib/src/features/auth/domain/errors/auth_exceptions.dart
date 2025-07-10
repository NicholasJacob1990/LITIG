abstract class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException() : super('Credenciais inválidas');
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException() : super('E-mail já está em uso');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException() : super('Senha muito fraca');
}

class ServerException extends AuthException {
  const ServerException(String message) : super(message);
}

class NetworkException extends AuthException {
  const NetworkException() : super('Erro de conexão com a internet');
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException() : super('Usuário não encontrado');
}

class EmailNotVerifiedException extends AuthException {
  const EmailNotVerifiedException() : super('E-mail não verificado');
} 