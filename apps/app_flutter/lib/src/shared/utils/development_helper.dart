import 'package:flutter/foundation.dart';
import '../services/mock_api_interceptor.dart';
import '../services/analytics_service.dart';
import '../services/metrics_service.dart';
import 'package:dio/dio.dart';

class DevelopmentHelper {
  static Dio? _mockDio;
  static bool _isInitialized = false;
  
  static bool get isDevelopment => kDebugMode;
  static bool get isMockEnabled => _mockDio != null;
  static Dio? get mockDio => _mockDio;
  
  static Future<void> initializeForDevelopment() async {
    if (_isInitialized || !isDevelopment) return;
    
    print('🛠️ Inicializando ambiente de desenvolvimento...');
    
    try {
      // Initialize mock API
      _initializeMockApi();
      
      // Initialize analytics with development mode
      await _initializeDevelopmentAnalytics();
      
      // Setup development helpers
      await _setupDevelopmentHelpers();
      
      _isInitialized = true;
      print('✅ Ambiente de desenvolvimento inicializado com sucesso!');
      
    } catch (e) {
      print('❌ Erro ao inicializar ambiente de desenvolvimento: $e');
    }
  }
  
  static void _initializeMockApi() {
    _mockDio = MockApiInterceptor.createMockDio(enableMock: true);
    
    print('🎯 APIs mock disponíveis:');
    print('  📋 Casos: GET /api/cases');
    print('  🔐 Auth: POST /api/auth/login');
    print('  💬 Mensagens: GET /api/messaging/chats');
    print('  📊 SLA: GET /api/sla/metrics');
    print('  📈 Analytics: POST /api/analytics/events');
    print('  📁 Upload: POST /api/files/upload');
    print('  ⚠️ Erro: GET /api/test/error');
    print('  🐌 Lento: GET /api/test/slow');
  }
  
  static void disableMockApi() {
    _mockDio = null;
    print('🔌 Mock API desabilitada');
  }
  
  static Future<void> _initializeDevelopmentAnalytics() async {
    final analytics = await AnalyticsService.getInstance();
    
    // Track development session
    await analytics.trackEvent('development_session_start', properties: {
      'platform': defaultTargetPlatform.name,
      'mock_api_enabled': isMockEnabled,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  static Future<void> _setupDevelopmentHelpers() async {
    // Add development-specific configurations
    if (isDevelopment) {
      // Setup crash reporting for development
      FlutterError.onError = (FlutterErrorDetails details) {
        _handleDevelopmentError(details);
      };
      
      // Track development metrics
      final metrics = await MetricsService.getInstance();
      await metrics.trackFeatureAdoption('development_mode');
    }
  }
  
  static void _handleDevelopmentError(FlutterErrorDetails details) async {
    // Log detailed error information for development
    print('💥 DESENVOLVIMENTO - ERRO CAPTURADO:');
    print('Exception: ${details.exception}');
    print('Stack trace:');
    print(details.stack);
    
    // Track error in development
    try {
      final metrics = await MetricsService.getInstance();
      await metrics.trackError(
        'development_flutter_error',
        details.exception.toString(),
        stackTrace: details.stack.toString(),
        context: {
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
    } catch (e) {
      print('Erro ao registrar erro de desenvolvimento: $e');
    }
  }
  
  // Helper methods for testing
  static void simulateSlowNetwork() {
    if (_mockDio != null) {
      final interceptor = _mockDio!.interceptors.whereType<MockApiInterceptor>().firstOrNull;
      if (interceptor != null) {
        interceptor.addEndpoint(MockEndpoint(
          path: '/api/test/network-slow',
          method: 'GET',
          response: {
            'success': true,
            'message': 'Simulação de rede lenta',
            'network_simulation': 'slow',
          },
          delay: const Duration(seconds: 8),
        ));
        
        print('🐌 Simulação de rede lenta ativada');
      }
    }
  }
  
  static void simulateNetworkError() {
    if (_mockDio != null) {
      final interceptor = _mockDio!.interceptors.whereType<MockApiInterceptor>().firstOrNull;
      if (interceptor != null) {
        interceptor.addEndpoint(MockEndpoint(
          path: '/api/test/network-error',
          method: 'GET',
          statusCode: 503,
          response: {
            'success': false,
            'error': 'Service Unavailable',
            'message': 'Simulação de erro de rede',
            'network_simulation': 'error',
          },
        ));
        
        print('❌ Simulação de erro de rede ativada');
      }
    }
  }
  
  static void resetMockApi() {
    disableMockApi();
    _initializeMockApi();
    print('🔄 Mock API reiniciada');
  }
  
  static Future<Map<String, dynamic>> getDevelopmentStatus() async {
    final analytics = await AnalyticsService.getInstance();
    final metrics = await MetricsService.getInstance();
    
    return {
      'development_mode': isDevelopment,
      'mock_api': {
        'enabled': isMockEnabled,
        'interceptor': 'MockApiInterceptor',
      },
      'analytics': await analytics.getStats(),
      'metrics': await metrics.getMetricsReport(),
      'initialized': _isInitialized,
    };
  }
  
  static void logDevelopmentInfo(String message) {
    if (isDevelopment) {
      print('🛠️ DEV: $message');
    }
  }
  
  static Future<void> cleanup() async {
    if (isDevelopment) {
      print('🧹 Limpando ambiente de desenvolvimento...');
      
      disableMockApi();
      
      // Track cleanup
      try {
        final analytics = await AnalyticsService.getInstance();
        await analytics.trackEvent('development_session_end');
        await analytics.flushEvents();
      } catch (e) {
        print('Erro ao fazer flush dos eventos: $e');
      }
      
      _isInitialized = false;
      print('✅ Ambiente de desenvolvimento limpo');
    }
  }
}