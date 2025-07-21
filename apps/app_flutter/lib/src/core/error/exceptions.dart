import 'package:dio/dio.dart';

/// Representa uma exceção genérica relacionada a erros do servidor.
class ServerException implements Exception {
  final String message;

  ServerException({required this.message});

  factory ServerException.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.cancel:
        return ServerException(message: "Request to API server was cancelled");
      case DioExceptionType.connectionTimeout:
        return ServerException(message: "Connection timeout with API server");
      case DioExceptionType.receiveTimeout:
        return ServerException(message: "Receive timeout in connection with API server");
      case DioExceptionType.badResponse:
        return ServerException(
          message: _handleError(dioError.response?.statusCode, dioError.response?.data),
        );
      case DioExceptionType.sendTimeout:
        return ServerException(message: "Send timeout in connection with API server");
      default:
        return ServerException(message: "Something went wrong");
    }
  }

  static String _handleError(int? statusCode, dynamic error) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 404:
        return error['message'];
      case 500:
        return 'Internal server error';
      default:
        return 'Oops something went wrong';
    }
  }
}

/// Representa uma exceção para recursos não encontrados (HTTP 404).
class NotFoundException implements Exception {
  final String resource;

  NotFoundException({required this.resource});

  @override
  String toString() => 'NotFoundException: Recurso não encontrado - $resource';
}

/// Exceção de rede para problemas de conectividade
class NetworkException implements Exception {
  NetworkException();

  @override
  String toString() => 'NetworkException: Erro de conectividade de rede';
}

/// Representa uma exceção para falhas de autenticação (HTTP 401).
class AuthenticationException implements Exception {
  final String message;

  AuthenticationException({this.message = 'Sessão inválida ou expirada.'});
   
  @override
  String toString() => 'AuthenticationException: $message';
}

/// Representa uma exceção para erros de permissão (HTTP 403).
class PermissionException implements Exception {
  final String message;

  PermissionException({this.message = 'Você não tem permissão para realizar esta ação.'});
   
  @override
  String toString() => 'PermissionException: $message';
}

/// Representa uma exceção para falhas de conexão de rede.
class ConnectionException implements Exception {
  final String message;

  ConnectionException({this.message = 'Falha na conexão. Verifique sua internet.'});

  @override
  String toString() => 'ConnectionException: $message';
} 

/// Exceção para erros de comunicação com a API

/// Exceção para quando o cache falha
class CacheException implements Exception {} 