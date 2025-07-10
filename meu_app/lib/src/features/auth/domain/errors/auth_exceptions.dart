// Classe base para exceções de autenticação
abstract class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  
  @override
  String toString() => message;
}

// Exceção para credenciais inválidas
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException([super.message = 'Credenciais inválidas']);
}

// Exceção para email já em uso
class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException([super.message = 'Email já está em uso']);
}

// Exceção para senha fraca
class WeakPasswordException extends AuthException {
  const WeakPasswordException([super.message = 'Senha muito fraca']);
}

// Exceção para erros de servidor
class ServerException extends AuthException {
  const ServerException([super.message = 'Erro interno do servidor']);
}

// Exceção para problemas de rede
class NetworkException extends AuthException {
  const NetworkException([super.message = 'Erro de conexão']);
}

// Exceção para usuário não encontrado
class UserNotFoundException extends AuthException {
  const UserNotFoundException([super.message = 'Usuário não encontrado']);
}

// Exceção para token inválido
class InvalidTokenException extends AuthException {
  const InvalidTokenException([super.message = 'Token inválido']);
}

// Exceção para usuário não autenticado
class UnauthorizedException extends AuthException {
  const UnauthorizedException([super.message = 'Usuário não autenticado']);
} 