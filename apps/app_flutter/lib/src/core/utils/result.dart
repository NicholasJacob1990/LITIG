import '../error/failures.dart';
import 'package:equatable/equatable.dart';

/// Classe para representar o resultado de uma operação que pode falhar
/// 
/// Similar ao Either do dartz, mas mais simples e sem dependências externas.
/// Pode conter um valor de sucesso [T] ou uma falha [Failure].
sealed class Result<T> {
  const Result();

  /// Cria um resultado de sucesso
  const factory Result.success(T value) = Success<T>;

  /// Cria um resultado de falha
  const factory Result.failure(Failure failure) = ResultFailure<T>;

  /// Verifica se o resultado é um sucesso
  bool get isSuccess => this is Success<T>;

  /// Verifica se o resultado é uma falha
  bool get isFailure => this is ResultFailure<T>;

  /// Obtém o valor de sucesso ou lança uma exceção se for falha
  T get value {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    throw StateError('Tentativa de acessar valor em um resultado de falha');
  }

  /// Obtém a falha ou lança uma exceção se for sucesso
  Failure get failure {
    if (this is ResultFailure<T>) {
      return (this as ResultFailure<T>).failure;
    }
    throw StateError('Tentativa de acessar falha em um resultado de sucesso');
  }

  /// Obtém o valor de sucesso ou null se for falha
  T? get valueOrNull {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    return null;
  }

  /// Obtém a falha ou null se for sucesso
  Failure? get failureOrNull {
    if (this is ResultFailure<T>) {
      return (this as ResultFailure<T>).failure;
    }
    return null;
  }

  /// Executa uma função se o resultado for sucesso
  Result<U> map<U>(U Function(T value) mapper) {
    if (this is Success<T>) {
      try {
        return Result.success(mapper((this as Success<T>).value));
      } catch (e) {
        return Result.failure(GenericFailure(message: e.toString()));
      }
    }
    return Result.failure((this as ResultFailure<T>).failure);
  }

  /// Executa uma função se o resultado for sucesso, permitindo retornar outro Result
  Result<U> flatMap<U>(Result<U> Function(T value) mapper) {
    if (this is Success<T>) {
      try {
        return mapper((this as Success<T>).value);
      } catch (e) {
        return Result.failure(GenericFailure(message: e.toString()));
      }
    }
    return Result.failure((this as ResultFailure<T>).failure);
  }

  /// Métodos de conveniência para criar falhas específicas
  static Result<T> connectionFailure<T>(String message, [String? code]) {
    return Result.failure(ConnectionFailure(message: message, code: code));
  }

  static Result<T> validationFailure<T>(String message, [String? code]) {
    return Result.failure(ValidationFailure(message: message, code: code));
  }

  static Result<T> genericFailure<T>(String message, [String? code]) {
    return Result.failure(GenericFailure(message: message, code: code));
  }

  static Result<T> serverFailure<T>(String message, [String? code]) {
    return Result.failure(ServerFailure(message: message, code: code));
  }

  static Result<T> authFailure<T>(String message, [String? code]) {
    return Result.failure(AuthenticationFailure(message: message, code: code));
  }

  static Result<T> notFoundFailure<T>(String message, [String? code]) {
    return Result.failure(NotFoundFailure(message: message, code: code));
  }

  static Result<T> timeoutFailure<T>(String message, [String? code]) {
    return Result.failure(TimeoutFailure(message: message, code: code));
  }

  /// Executa uma função com base no resultado
  U fold<U>(
    U Function(Failure failure) onFailure,
    U Function(T value) onSuccess,
  ) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).value);
    }
    return onFailure((this as ResultFailure<T>).failure);
  }
}

/// Implementação concreta para resultado de sucesso
final class Success<T> extends Result<T> with EquatableMixin {
  const Success(this.value);

  @override
  final T value;

  @override
  String toString() => 'Success($value)';

  @override
  List<Object?> get props => [value];
}

/// Implementação concreta para resultado de falha
final class ResultFailure<T> extends Result<T> with EquatableMixin {
  const ResultFailure(this.failure);

  @override
  final Failure failure;

  @override
  String toString() => 'ResultFailure($failure)';

  @override
  List<Object?> get props => [failure];
} 