import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'analytics_service.dart';

/// Integração com Firebase Analytics para o sistema LITIG-1
/// 
/// Este serviço complementa o AnalyticsService local com tracking
/// no Firebase para análises mais profundas e dashboards automáticos.
class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();

  late final FirebaseAnalytics _analytics;
  late final FirebaseAnalyticsObserver _observer;
  bool _isInitialized = false;
  
  /// Observer para navegação automática
  FirebaseAnalyticsObserver get observer => _observer;

  /// Inicialização do Firebase Analytics
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics);
      
      // Configurações iniciais
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.setSessionTimeoutDuration(const Duration(minutes: 30));
      
      _isInitialized = true;
      print('Firebase Analytics inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar Firebase Analytics: $e');
      // Não lança exceção para não quebrar o app se Firebase não estiver configurado
    }
  }

  /// Define propriedades do usuário
  Future<void> setUserProperties({
    required String userId,
    String? userType, // 'client', 'lawyer', 'admin'
    String? planType, // 'free', 'premium', 'enterprise'
    String? firmSize, // 'small', 'medium', 'large'
  }) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.setUserId(id: userId);
      
      if (userType != null) {
        await _analytics.setUserProperty(name: 'user_type', value: userType);
      }
      if (planType != null) {
        await _analytics.setUserProperty(name: 'plan_type', value: planType);
      }
      if (firmSize != null) {
        await _analytics.setUserProperty(name: 'firm_size', value: firmSize);
      }
    } catch (e) {
      print('Erro ao definir propriedades do usuário: $e');
    }
  }

  /// Tracking de visualização de perfil de advogado
  Future<void> trackLawyerProfileView(String lawyerId, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'lawyer_profile_view',
        parameters: {
          'lawyer_id': lawyerId,
          'content_type': 'lawyer_profile',
          'content_id': lawyerId,
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar visualização de perfil do advogado: $e');
    }
  }

  /// Tracking de visualização de perfil de escritório
  Future<void> trackFirmProfileView(String firmId, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'firm_profile_view',
        parameters: {
          'firm_id': firmId,
          'content_type': 'firm_profile',
          'content_id': firmId,
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar visualização de perfil do escritório: $e');
    }
  }

  /// Tracking de navegação entre abas
  Future<void> trackTabNavigation(String profileType, String tabName, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'tab_navigation',
        parameters: {
          'profile_type': profileType,
          'tab_name': tabName,
          'navigation_type': 'tab_switch',
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar navegação de aba: $e');
    }
  }

  /// Tracking de uso de filtros
  Future<void> trackFilterUsage(String screen, Map<String, String> filters, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'filter_applied',
        parameters: {
          'screen_name': screen,
          'filter_count': filters.length,
          'filters_applied': filters.keys.join(','),
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar uso de filtros: $e');
    }
  }

  /// Tracking de refresh de dados
  Future<void> trackDataRefresh(String profileType, String profileId, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'data_refresh',
        parameters: {
          'profile_type': profileType,
          'profile_id': profileId,
          'action_type': 'user_initiated_refresh',
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar refresh de dados: $e');
    }
  }

  /// Tracking de compartilhamento
  Future<void> trackProfileShare(String profileType, String profileId, String shareMethod, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'share',
        parameters: {
          'content_type': '${profileType}_profile',
          'content_id': profileId,
          'method': shareMethod,
          'item_id': profileId,
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar compartilhamento: $e');
    }
  }

  /// Tracking de explicação do algoritmo
  Future<void> trackAlgorithmExplanationView(String profileType, String profileId, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'algorithm_explanation_view',
        parameters: {
          'profile_type': profileType,
          'profile_id': profileId,
          'feature_type': 'algorithm_transparency',
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar visualização de explicação do algoritmo: $e');
    }
  }

  /// Tracking de download de currículo
  Future<void> trackCurriculumDownload(String lawyerId, String format, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'file_download',
        parameters: {
          'file_type': 'curriculum',
          'file_format': format,
          'lawyer_id': lawyerId,
          'content_id': lawyerId,
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar download de currículo: $e');
    }
  }

  /// Tracking de tempo de carregamento (Performance)
  Future<void> trackLoadingTime(String screen, Duration loadingTime, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'screen_load_time',
        parameters: {
          'screen_name': screen,
          'load_time_ms': loadingTime.inMilliseconds,
          'performance_metric': 'loading_time',
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar tempo de carregamento: $e');
    }
  }

  /// Tracking de erros
  Future<void> trackError(String errorType, String message, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'error_message': message.length > 100 ? message.substring(0, 100) : message,
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar erro no Firebase: $e');
    }
  }

  /// Tracking de busca
  Future<void> trackSearch(String query, String screen, int resultsCount, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'search',
        parameters: {
          'search_term': query.length > 100 ? query.substring(0, 100) : query,
          'screen_name': screen,
          'results_count': resultsCount,
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar busca: $e');
    }
  }

  /// Tracking de interação com UI
  Future<void> trackUIInteraction(String element, String action, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'ui_interaction',
        parameters: {
          'element_name': element,
          'action_type': action,
          'interaction_type': 'user_action',
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar interação de UI: $e');
    }
  }

  /// Tracking de conversão (contratação)
  Future<void> trackConversion(String conversionType, String profileId, double value, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'conversion',
        parameters: {
          'conversion_type': conversionType,
          'profile_id': profileId,
          'value': value,
          'currency': 'BRL',
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar conversão: $e');
    }
  }

  /// Tracking de retenção de usuário
  Future<void> trackUserRetention(String sessionId, Duration sessionDuration, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'session_end',
        parameters: {
          'session_id': sessionId,
          'session_duration_ms': sessionDuration.inMilliseconds,
          'engagement_time_msec': sessionDuration.inMilliseconds,
          'timestamp': DateTime.now().toIso8601String(),
          ...?_sanitizeParameters(metadata),
        },
      );
    } catch (e) {
      print('Erro ao registrar retenção do usuário: $e');
    }
  }

  /// Define um evento customizado
  Future<void> logCustomEvent(String eventName, Map<String, dynamic> parameters) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: _sanitizeParameters(parameters),
      );
    } catch (e) {
      print('Erro ao registrar evento customizado: $e');
    }
  }

  /// Sanitiza parâmetros para o Firebase (remove valores nulos e limita strings)
  Map<String, dynamic> _sanitizeParameters(Map<String, dynamic>? parameters) {
    if (parameters == null) return {};
    
    final sanitized = <String, dynamic>{};
    
    parameters.forEach((key, value) {
      if (value != null) {
        if (value is String) {
          // Firebase tem limite de 100 caracteres para strings
          sanitized[key] = value.length > 100 ? value.substring(0, 100) : value;
        } else if (value is num || value is bool) {
          sanitized[key] = value;
        } else {
          // Converte outros tipos para string
          final stringValue = value.toString();
          sanitized[key] = stringValue.length > 100 ? stringValue.substring(0, 100) : stringValue;
        }
      }
    });
    
    return sanitized;
  }

  /// Força o envio de eventos pendentes
  Future<void> flush() async {
    if (!_isInitialized) return;
    
    try {
      // O Firebase Android/iOS gerencia automaticamente o envio
      // Este método está aqui para compatibilidade com outras plataformas
      print('Firebase Analytics: eventos enviados');
    } catch (e) {
      print('Erro ao enviar eventos do Firebase: $e');
    }
  }

  /// Desabilita o Firebase Analytics (para compliance com LGPD)
  Future<void> disable() async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.setAnalyticsCollectionEnabled(false);
      print('Firebase Analytics desabilitado');
    } catch (e) {
      print('Erro ao desabilitar Firebase Analytics: $e');
    }
  }

  /// Habilita o Firebase Analytics
  Future<void> enable() async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      print('Firebase Analytics habilitado');
    } catch (e) {
      print('Erro ao habilitar Firebase Analytics: $e');
    }
  }
}

/// Wrapper que integra o AnalyticsService local com Firebase
class IntegratedAnalyticsService {
  final AnalyticsService _localAnalytics = AnalyticsService();
  final FirebaseAnalyticsService _firebaseAnalytics = FirebaseAnalyticsService();
  
  static final IntegratedAnalyticsService _instance = IntegratedAnalyticsService._internal();
  factory IntegratedAnalyticsService() => _instance;
  IntegratedAnalyticsService._internal();

  /// Inicialização completa
  Future<void> initialize() async {
    await _firebaseAnalytics.initialize();
  }

  /// Wrapper para todos os métodos de tracking
  Future<void> trackLawyerProfileView(String lawyerId, {Map<String, dynamic>? metadata}) async {
    // Local tracking (sempre ativo)
    _localAnalytics.trackLawyerProfileView(lawyerId, metadata: metadata);
    
    // Firebase tracking (se disponível)
    await _firebaseAnalytics.trackLawyerProfileView(lawyerId, metadata: metadata);
  }

  Future<void> trackFirmProfileView(String firmId, {Map<String, dynamic>? metadata}) async {
    _localAnalytics.trackFirmProfileView(firmId, metadata: metadata);
    await _firebaseAnalytics.trackFirmProfileView(firmId, metadata: metadata);
  }

  Future<void> trackTabNavigation(String profileType, String tabName, {Map<String, dynamic>? metadata}) async {
    _localAnalytics.trackTabNavigation(profileType, tabName, metadata: metadata);
    await _firebaseAnalytics.trackTabNavigation(profileType, tabName, metadata: metadata);
  }

  Future<void> trackFilterUsage(String screen, Map<String, String> filters, {Map<String, dynamic>? metadata}) async {
    _localAnalytics.trackFilterUsage(screen, filters, metadata: metadata);
    await _firebaseAnalytics.trackFilterUsage(screen, filters, metadata: metadata);
  }

  Future<void> trackDataRefresh(String profileType, String profileId, {Map<String, dynamic>? metadata}) async {
    _localAnalytics.trackDataRefresh(profileType, profileId, metadata: metadata);
    await _firebaseAnalytics.trackDataRefresh(profileType, profileId, metadata: metadata);
  }

  Future<void> trackProfileShare(String profileType, String profileId, String shareMethod, {Map<String, dynamic>? metadata}) async {
    _localAnalytics.trackProfileShare(profileType, profileId, shareMethod, metadata: metadata);
    await _firebaseAnalytics.trackProfileShare(profileType, profileId, shareMethod, metadata: metadata);
  }

  Future<void> trackAlgorithmExplanationView(String profileType, String profileId, {Map<String, dynamic>? metadata}) async {
    _localAnalytics.trackAlgorithmExplanationView(profileType, profileId, metadata: metadata);
    await _firebaseAnalytics.trackAlgorithmExplanationView(profileType, profileId, metadata: metadata);
  }

  Future<void> trackCurriculumDownload(String lawyerId, String format, {Map<String, dynamic>? metadata}) async {
    _localAnalytics.trackCurriculumDownload(lawyerId, format, metadata: metadata);
    await _firebaseAnalytics.trackCurriculumDownload(lawyerId, format, metadata: metadata);
  }

  Future<void> trackLoadingTime(String screen, Duration loadingTime, {Map<String, dynamic>? metadata}) async {
    _localAnalytics.trackLoadingTime(screen, loadingTime, metadata: metadata);
    await _firebaseAnalytics.trackLoadingTime(screen, loadingTime, metadata: metadata);
  }

  Future<void> trackError(String errorType, String message, {Map<String, dynamic>? metadata}) async {
    _localAnalytics.trackError(errorType, message, metadata: metadata);
    await _firebaseAnalytics.trackError(errorType, message, metadata: metadata);
  }

  Future<void> trackSearch(String query, String screen, int resultsCount, {Map<String, dynamic>? metadata}) async {
    _localAnalytics.trackSearch(query, screen, resultsCount, metadata: metadata);
    await _firebaseAnalytics.trackSearch(query, screen, resultsCount, metadata: metadata);
  }

  Future<void> trackUIInteraction(String element, String action, {Map<String, dynamic>? metadata}) async {
    _localAnalytics.trackUIInteraction(element, action, metadata: metadata);
    await _firebaseAnalytics.trackUIInteraction(element, action, metadata: metadata);
  }

  /// Métodos específicos do Firebase
  Future<void> setUserProperties({
    required String userId,
    String? userType,
    String? planType,
    String? firmSize,
  }) async {
    await _firebaseAnalytics.setUserProperties(
      userId: userId,
      userType: userType,
      planType: planType,
      firmSize: firmSize,
    );
  }

  Future<void> trackConversion(String conversionType, String profileId, double value, {Map<String, dynamic>? metadata}) async {
    await _firebaseAnalytics.trackConversion(conversionType, profileId, value, metadata: metadata);
  }

  /// Relatórios locais
  AnalyticsReport generateLocalReport({DateTime? startDate, DateTime? endDate}) {
    return _localAnalytics.generateReport(startDate: startDate, endDate: endDate);
  }

  /// Compliance com LGPD
  Future<void> disableTracking() async {
    await _firebaseAnalytics.disable();
  }

  Future<void> enableTracking() async {
    await _firebaseAnalytics.enable();
  }
} 