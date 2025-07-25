import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meu_app/src/core/utils/logger.dart';

/// Serviço de analytics para tracking de eventos
/// Especialmente focado em conversão de billing
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  
  AnalyticsService._();

  final Dio _dio = Dio();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isInitialized = false;
  String? _userId;
  Map<String, dynamic> _userProperties = {};

  /// Inicializa o serviço de analytics
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Obter usuário atual
      final session = _supabase.auth.currentSession;
      _userId = session?.user.id;
      
      if (_userId != null) {
        await _loadUserProperties();
      }
      
      _isInitialized = true;
      AppLogger.init('AnalyticsService inicializado');
      
      // Identificar usuário se logado
      if (_userId != null) {
        await identifyUser(_userId!, _userProperties);
      }
      
    } catch (e) {
      AppLogger.error('Erro ao inicializar AnalyticsService', error: e);
    }
  }

  /// Carrega propriedades do usuário
  Future<void> _loadUserProperties() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('user_type, role, plan, created_at')
          .eq('user_id', _userId!)
          .single();
      
      _userProperties = {
        'user_type': response['user_type'],
        'role': response['role'],
        'current_plan': response['plan'],
        'account_age_days': _calculateAccountAge(response['created_at']),
      };
      
    } catch (e) {
      AppLogger.warning('Erro ao carregar propriedades do usuário: $e');
      _userProperties = {};
    }
  }

  /// Calcula idade da conta em dias
  int _calculateAccountAge(String? createdAt) {
    if (createdAt == null) return 0;
    
    try {
      final created = DateTime.parse(createdAt);
      return DateTime.now().difference(created).inDays;
    } catch (e) {
      return 0;
    }
  }

  /// Identifica um usuário no sistema de analytics
  Future<void> identifyUser(String userId, Map<String, dynamic> properties) async {
    if (!_isInitialized) await initialize();

    try {
      _userId = userId;
      _userProperties.addAll(properties);
      
      AppLogger.info('Usuário identificado no analytics: $userId');
      
      // Enviar para backend se necessário
      await _trackEvent('user_identified', {
        'user_id': userId,
        'properties': properties,
      });
      
    } catch (e) {
      AppLogger.error('Erro ao identificar usuário', error: e);
    }
  }

  /// Rastreia uma visualização de página
  Future<void> trackPageView(String pageName, {Map<String, dynamic>? properties}) async {
    await _trackEvent('page_view', {
      'page_name': pageName,
      'timestamp': DateTime.now().toIso8601String(),
      ...?properties,
    });
  }

  /// Rastreia eventos específicos de billing
  Future<void> trackBillingEvent(
    String eventName, {
    String? entityType,
    String? entityId,
    String? currentPlan,
    String? targetPlan,
    double? amount,
    String? currency = 'BRL',
    Map<String, dynamic>? additionalProperties,
  }) async {
    final properties = {
      'entity_type': entityType,
      'entity_id': entityId,
      'current_plan': currentPlan,
      'target_plan': targetPlan,
      'amount': amount,
      'currency': currency,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalProperties,
    };

    await _trackEvent('billing_$eventName', properties);
  }

  /// Eventos específicos de conversão de billing
  
  /// Visualização da página de planos
  Future<void> trackBillingPageView(String entityType) async {
    await trackBillingEvent('page_view', 
      entityType: entityType,
      additionalProperties: {
        'source': 'profile_menu',
        'user_plan': _userProperties['current_plan'],
      }
    );
  }

  /// Seleção de um plano
  Future<void> trackPlanSelected(String entityType, String planId, double amount) async {
    await trackBillingEvent('plan_selected',
      entityType: entityType,
      targetPlan: planId,
      amount: amount,
      additionalProperties: {
        'selection_time': DateTime.now().toIso8601String(),
      }
    );
  }

  /// Início do checkout
  Future<void> trackCheckoutStarted(String entityType, String planId, double amount) async {
    await trackBillingEvent('checkout_started',
      entityType: entityType,
      targetPlan: planId,
      amount: amount,
      additionalProperties: {
        'checkout_method': 'stripe',
        'funnel_step': 'checkout_initiated',
      }
    );
  }

  /// Checkout bem-sucedido
  Future<void> trackCheckoutCompleted(
    String entityType, 
    String planId, 
    double amount,
    String sessionId
  ) async {
    await trackBillingEvent('checkout_completed',
      entityType: entityType,
      targetPlan: planId,
      amount: amount,
      additionalProperties: {
        'session_id': sessionId,
        'payment_method': 'stripe',
        'success': true,
        'funnel_step': 'conversion_complete',
      }
    );
  }

  /// Checkout cancelado
  Future<void> trackCheckoutCancelled(
    String entityType, 
    String planId, 
    String reason
  ) async {
    await trackBillingEvent('checkout_cancelled',
      entityType: entityType,
      targetPlan: planId,
      additionalProperties: {
        'cancellation_reason': reason,
        'funnel_step': 'checkout_abandoned',
      }
    );
  }

  /// Upgrade de plano bem-sucedido
  Future<void> trackPlanUpgraded(
    String entityType, 
    String oldPlan, 
    String newPlan,
    double amount
  ) async {
    await trackBillingEvent('plan_upgraded',
      entityType: entityType,
      currentPlan: oldPlan,
      targetPlan: newPlan,
      amount: amount,
      additionalProperties: {
        'upgrade_type': _calculateUpgradeType(oldPlan, newPlan),
        'upgrade_value': amount,
      }
    );
  }

  /// Calcula tipo de upgrade
  String _calculateUpgradeType(String oldPlan, String newPlan) {
    final planOrder = ['FREE', 'VIP', 'PRO', 'PARTNER', 'PREMIUM', 'ENTERPRISE'];
    final oldIndex = planOrder.indexOf(oldPlan);
    final newIndex = planOrder.indexOf(newPlan);
    
    if (newIndex > oldIndex) return 'upgrade';
    if (newIndex < oldIndex) return 'downgrade';
    return 'same_tier';
  }

  /// Rastreia erro de billing
  Future<void> trackBillingError(String errorType, String errorMessage, {
    String? entityType,
    String? planId,
    Map<String, dynamic>? context,
  }) async {
    await trackBillingEvent('error',
      entityType: entityType,
      targetPlan: planId,
      additionalProperties: {
        'error_type': errorType,
        'error_message': errorMessage,
        'error_context': context,
        'timestamp': DateTime.now().toIso8601String(),
      }
    );
  }

  /// Eventos de onboarding e engajamento
  
  /// Primeiro acesso após registro
  Future<void> trackFirstAppOpen() async {
    await _trackEvent('first_app_open', {
      'user_type': _userProperties['user_type'],
      'registration_date': _userProperties['created_at'],
    });
  }

  /// Feature discovery
  Future<void> trackFeatureDiscovered(String featureName, String location) async {
    await _trackEvent('feature_discovered', {
      'feature_name': featureName,
      'discovery_location': location,
      'user_plan': _userProperties['current_plan'],
    });
  }

  /// Eventos de retenção
  Future<void> trackDailyActive() async {
    await _trackEvent('daily_active', {
      'session_start': DateTime.now().toIso8601String(),
      'user_plan': _userProperties['current_plan'],
      'account_age_days': _userProperties['account_age_days'],
    });
  }

  /// Tracking genérico de eventos
  Future<void> _trackEvent(String eventName, Map<String, dynamic> properties) async {
    if (!_isInitialized) {
      AppLogger.warning('Analytics não inicializado, evento ignorado: $eventName');
      return;
    }

    try {
      // Adicionar propriedades do usuário
      final enrichedProperties = {
        'user_id': _userId,
        'platform': _getPlatform(),
        'app_version': await _getAppVersion(),
        'timestamp': DateTime.now().toIso8601String(),
        ...properties,
        ..._userProperties,
      };

      // Enviar para backend
      await _sendToBackend(eventName, enrichedProperties);
      
      // Log local em debug
      if (kDebugMode) {
        AppLogger.debug('📊 Analytics: $eventName - $enrichedProperties');
      }
      
    } catch (e) {
      AppLogger.error('Erro ao rastrear evento $eventName', error: e);
    }
  }

  /// Envia evento para o backend
  Future<void> _sendToBackend(String eventName, Map<String, dynamic> properties) async {
    try {
      // Tentar via API primeiro
      await _dio.post('/analytics/events', data: {
        'event_name': eventName,
        'properties': properties,
      });
      
    } catch (e) {
      // Fallback para Supabase direto
      try {
        await _supabase.from('billing_analytics').insert({
          'user_id': _userId,
          'event_name': eventName,
          'properties': properties,
        });
      } catch (supabaseError) {
        AppLogger.warning('Erro ao enviar analytics via Supabase: $supabaseError');
      }
    }
  }

  /// Obtém plataforma atual
  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'unknown';
  }

  /// Obtém versão do app
  Future<String> _getAppVersion() async {
    try {
      // TODO: Implementar com package_info_plus
      return '1.0.0';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Limpa dados do usuário (logout)
  Future<void> reset() async {
    _userId = null;
    _userProperties.clear();
    
    await _trackEvent('user_logged_out', {
      'session_end': DateTime.now().toIso8601String(),
    });
    
    AppLogger.info('Analytics resetado');
  }

  /// Força sincronização de eventos pendentes
  Future<void> flush() async {
    // TODO: Implementar queue local e sincronização
    AppLogger.debug('Analytics flush chamado');
  }

  /// Obtém métricas de conversão (para dashboards)
  Future<Map<String, dynamic>> getConversionMetrics({
    int days = 30,
    String? entityType,
  }) async {
    try {
      final response = await _dio.get('/analytics/conversion-metrics', 
        queryParameters: {
          'days': days,
          if (entityType != null) 'entity_type': entityType,
        }
      );
      
      return response.data;
    } catch (e) {
      AppLogger.error('Erro ao obter métricas de conversão', error: e);
      return {};
    }
  }
} 