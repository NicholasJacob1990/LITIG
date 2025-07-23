import 'dart:math';
import 'package:dio/dio.dart';

/// Mock API Interceptor that simulates API responses without needing a real server
class MockApiInterceptor extends Interceptor {
  final Map<String, MockEndpoint> _endpoints = {};
  final bool isEnabled;
  
  MockApiInterceptor({this.isEnabled = true}) {
    if (isEnabled) {
      _setupDefaultEndpoints();
    }
  }
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!isEnabled) {
      handler.next(options);
      return;
    }
    
    final path = options.path;
    final method = options.method;
    final key = '$method:$path';
    
    print('🔄 Mock API Request: $method $path');
    
    final endpoint = _endpoints[key];
    if (endpoint != null) {
      // Simulate network delay
      Future.delayed(endpoint.delay ?? const Duration(milliseconds: 300), () {
        final response = Response(
          requestOptions: options,
          statusCode: endpoint.statusCode,
          data: endpoint.response,
        );
        
        print('✅ Mock API Response: ${response.statusCode} - $path');
        handler.resolve(response);
      });
    } else {
      // Pass through if no mock endpoint found
      handler.next(options);
    }
  }
  
  void addEndpoint(MockEndpoint endpoint) {
    final key = '${endpoint.method}:${endpoint.path}';
    _endpoints[key] = endpoint;
    print('📍 Mock endpoint added: ${endpoint.method} ${endpoint.path}');
  }
  
  void removeEndpoint(String method, String path) {
    final key = '$method:$path';
    _endpoints.remove(key);
    print('🗑️ Mock endpoint removed: $method $path');
  }
  
  void _setupDefaultEndpoints() {
    // Auth endpoints
    addEndpoint(MockEndpoint(
      path: '/api/auth/login',
      method: 'POST',
      response: {
        'success': true,
        'data': {
          'token': 'mock_jwt_token_${Random().nextInt(10000)}',
          'user': {
            'id': 'user_123',
            'email': 'user@example.com',
            'name': 'Mock User',
            'role': 'lawyer_individual',
          }
        }
      },
      delay: const Duration(milliseconds: 800),
    ));
    
    // Cases endpoints
    addEndpoint(MockEndpoint(
      path: '/api/cases',
      method: 'GET',
      response: {
        'success': true,
        'data': List.generate(10, (index) => {
          'id': 'case_$index',
          'title': 'Caso de Exemplo #${index + 1}',
          'description': 'Descrição detalhada do caso #${index + 1}',
          'status': ['open', 'in_progress', 'closed'][Random().nextInt(3)],
          'priority': ['high', 'medium', 'low'][Random().nextInt(3)],
          'created_at': DateTime.now().subtract(Duration(days: Random().nextInt(30))).toIso8601String(),
          'updated_at': DateTime.now().subtract(Duration(hours: Random().nextInt(24))).toIso8601String(),
        })
      },
    ));
    
    // Messaging endpoints
    addEndpoint(MockEndpoint(
      path: '/api/messaging/accounts',
      method: 'GET',
      response: {
        'success': true,
        'data': [
          {
            'id': 'acc_linkedin',
            'provider': 'linkedin',
            'account_name': 'João Silva - LinkedIn',
            'is_connected': true,
            'last_sync': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
          },
          {
            'id': 'acc_whatsapp',
            'provider': 'whatsapp',
            'account_name': '+55 11 99999-9999',
            'is_connected': false,
            'last_sync': null,
          }
        ]
      },
    ));
    
    addEndpoint(MockEndpoint(
      path: '/api/messaging/chats',
      method: 'GET',
      response: {
        'success': true,
        'data': List.generate(8, (index) => {
          'id': 'chat_$index',
          'provider': ['linkedin', 'whatsapp', 'gmail'][Random().nextInt(3)],
          'name': 'Chat ${index + 1}',
          'last_message': 'Última mensagem do chat ${index + 1}',
          'unread_count': Random().nextInt(5),
          'updated_at': DateTime.now().subtract(Duration(hours: Random().nextInt(48))).toIso8601String(),
        })
      },
    ));
    
    // SLA endpoints
    addEndpoint(MockEndpoint(
      path: '/api/sla/metrics',
      method: 'GET',
      response: {
        'success': true,
        'data': {
          'response_time': {
            'average': Random().nextInt(2) + 1.5,
            'target': 2.0,
            'status': 'good',
          },
          'resolution_time': {
            'average': Random().nextInt(5) + 8.5,
            'target': 12.0,
            'status': 'good',
          },
          'satisfaction': {
            'score': Random().nextDouble() * 2 + 8.0,
            'target': 8.5,
            'status': 'excellent',
          }
        }
      },
    ));
    
    // Analytics endpoints
    addEndpoint(MockEndpoint(
      path: '/api/analytics/events',
      method: 'POST',
      response: {
        'success': true,
        'message': 'Events received successfully',
        'processed': 1,
      },
      delay: const Duration(milliseconds: 300),
    ));
    
    // File upload endpoint
    addEndpoint(MockEndpoint(
      path: '/api/files/upload',
      method: 'POST',
      response: {
        'success': true,
        'data': {
          'file_id': 'file_${Random().nextInt(10000)}',
          'url': 'https://mock-storage.example.com/files/mock-file.pdf',
          'name': 'uploaded-file.pdf',
          'size': Random().nextInt(1000000) + 100000,
        }
      },
      delay: const Duration(seconds: 2),
    ));
    
    // Error simulation endpoint
    addEndpoint(MockEndpoint(
      path: '/api/test/error',
      method: 'GET',
      statusCode: 500,
      response: {
        'success': false,
        'error': 'Internal Server Error',
        'message': 'Erro simulado para testes',
      },
    ));
    
    // Slow response endpoint
    addEndpoint(MockEndpoint(
      path: '/api/test/slow',
      method: 'GET',
      response: {
        'success': true,
        'message': 'Resposta lenta simulada',
        'timestamp': DateTime.now().toIso8601String(),
      },
      delay: const Duration(seconds: 5),
    ));
    
    print('🚀 Mock API Interceptor initialized with default endpoints');
  }
  
  // Convenience method to create a Dio instance with mock interceptor
  static Dio createMockDio({bool enableMock = true}) {
    final dio = Dio();
    
    if (enableMock) {
      dio.interceptors.add(MockApiInterceptor(isEnabled: true));
    }
    
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    
    return dio;
  }
}

class MockEndpoint {
  final String path;
  final String method;
  final Map<String, dynamic> response;
  final int statusCode;
  final Duration? delay;
  
  MockEndpoint({
    required this.path,
    required this.method,
    required this.response,
    this.statusCode = 200,
    this.delay,
  });
}