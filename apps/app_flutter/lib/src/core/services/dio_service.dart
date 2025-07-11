import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DioService {
  static Dio? _dio;

  static Dio get dio {
    if (_dio == null) {
      _dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:8000/api',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ));

      // Adicionar interceptor de autenticação
      _dio!.interceptors.add(AuthInterceptor());

      // Adicionar interceptor de logging (apenas em debug)
      _dio!.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => print('DIO: $object'),
      ));
    }
    return _dio!;
  }
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Adicionar token de autenticação automaticamente
    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;
    
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    
    print('DEBUG: Request ${options.method} ${options.uri}');
    print('DEBUG: Headers: ${options.headers}');
    
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('DEBUG: Response ${response.statusCode} from ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('DEBUG: Error ${err.response?.statusCode} from ${err.requestOptions.uri}');
    print('DEBUG: Error message: ${err.message}');
    
    // Tratar erros de autenticação
    if (err.response?.statusCode == 401) {
      // Token expirado ou inválido
      print('DEBUG: Token inválido ou expirado');
      // Aqui poderia implementar refresh token ou logout automático
    }
    
    handler.next(err);
  }
} 