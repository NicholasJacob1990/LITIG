import 'package:dio/dio.dart';
import 'package:meu_app/src/core/utils/logger.dart';
import 'package:meu_app/src/features/billing/domain/entities/billing_record.dart';

abstract class BillingRemoteDataSource {
  Future<List<Map<String, dynamic>>> getAvailablePlans(String entityType);
  Future<Map<String, dynamic>?> getCurrentPlan(String entityType, String entityId);
  Future<Map<String, dynamic>> createCheckoutSession({
    required String targetPlan,
    required String entityType,
    required String entityId,
    required String successUrl,
    required String cancelUrl,
  });
  Future<List<BillingRecord>> getBillingHistory(String entityType, String entityId);
  Future<List<Map<String, dynamic>>> getPlanHistory(String entityType, String entityId);
}

class BillingRemoteDataSourceImpl implements BillingRemoteDataSource {
  final Dio dio;

  BillingRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<Map<String, dynamic>>> getAvailablePlans(String entityType) async {
    try {
      AppLogger.info('Fetching available plans for entity type: $entityType');
      
      final response = await dio.get('/billing/plans/$entityType');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final plans = data['plans'] as List<dynamic>;
        
        AppLogger.info('Successfully fetched ${plans.length} plans');
        return plans.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Invalid response: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.warning('API error, falling back to mock data: ${e.message}');
      
      // Fallback para dados mock se API não disponível
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout ||
          e.response?.statusCode == 404) {
        return _getMockPlansForEntityType(entityType);
      }
      
      if (e.response != null) {
        throw Exception('HTTP ${e.response!.statusCode}: ${e.response!.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      AppLogger.error('Unexpected error, using mock fallback', error: e);
      return _getMockPlansForEntityType(entityType);
    }
  }

  @override
  Future<Map<String, dynamic>?> getCurrentPlan(String entityType, String entityId) async {
    try {
      AppLogger.info('Fetching current plan for $entityType: $entityId');
      
      final response = await dio.get('/billing/current-plan/$entityType/$entityId');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        AppLogger.info('Successfully fetched current plan: ${data['current_plan']}');
        
        // Retornar dados do plano atual
        return {
          'id': data['current_plan'],
          'name': _getPlanDisplayName(data['current_plan']),
          'price_monthly': _getPlanPrice(data['current_plan']),
          'features': data['plan_features'] ?? [],
          'description': _getPlanDescription(data['current_plan'])
        };
      } else {
        throw Exception('Invalid response: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.warning('API error, using mock current plan: ${e.message}');
      
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout ||
          e.response?.statusCode == 404) {
        return _getMockCurrentPlan(entityType);
      }
      
      if (e.response != null) {
        throw Exception('HTTP ${e.response!.statusCode}: ${e.response!.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      AppLogger.error('Unexpected error, using mock fallback', error: e);
      return _getMockCurrentPlan(entityType);
    }
  }

  @override
  Future<Map<String, dynamic>> createCheckoutSession({
    required String targetPlan,
    required String entityType,
    required String entityId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      AppLogger.info('Creating checkout session for plan: $targetPlan');
      
      final requestData = {
        'target_plan': targetPlan,
        'entity_type': entityType,
        'entity_id': entityId,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
      };
      
      final response = await dio.post('/billing/create-checkout', data: requestData);
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        AppLogger.info('Checkout session created successfully');
        return data;
      } else {
        throw Exception('Invalid response: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error('Error creating checkout session', error: e);
      
      if (e.response != null) {
        throw Exception('HTTP ${e.response!.statusCode}: ${e.response!.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      AppLogger.error('Unexpected error creating checkout', error: e);
      throw Exception('Error creating checkout: $e');
    }
  }

  @override
  Future<List<BillingRecord>> getBillingHistory(String entityType, String entityId) async {
    try {
      AppLogger.info('Fetching billing history for $entityType: $entityId');
      
      final response = await dio.get('/billing/billing-history/$entityType/$entityId');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final records = data['billing_records'] as List<dynamic>;
        
        AppLogger.info('Successfully fetched ${records.length} billing records');
        return records.map((json) => BillingRecord.fromJson(json)).toList();
      } else {
        throw Exception('Invalid response: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.warning('API error, returning empty billing history: ${e.message}');
      
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout ||
          e.response?.statusCode == 404) {
        return [];
      }
      
      if (e.response != null) {
        throw Exception('HTTP ${e.response!.statusCode}: ${e.response!.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      AppLogger.error('Unexpected error, returning empty history', error: e);
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPlanHistory(String entityType, String entityId) async {
    try {
      AppLogger.info('Fetching plan history for $entityType: $entityId');
      
      final response = await dio.get('/billing/billing-history/$entityType/$entityId');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final history = data['plan_history'] as List<dynamic>;
        
        AppLogger.info('Successfully fetched ${history.length} plan history records');
        return history.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Invalid response: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.warning('API error, returning empty plan history: ${e.message}');
      
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout ||
          e.response?.statusCode == 404) {
        return [];
      }
      
      if (e.response != null) {
        throw Exception('HTTP ${e.response!.statusCode}: ${e.response!.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      AppLogger.error('Unexpected error, returning empty history', error: e);
      return [];
    }
  }

  // Mock data methods for fallback
  List<Map<String, dynamic>> _getMockPlansForEntityType(String entityType) {
    switch (entityType) {
      case 'client':
        return [
          {
            'id': 'FREE',
            'name': 'Gratuito',
            'price_monthly': 0.0,
            'features': [
              'Até 2 casos por mês',
              'Suporte por email',
              'Advogados verificados'
            ],
            'description': 'Plano básico para explorar a plataforma'
          },
          {
            'id': 'VIP',
            'name': 'VIP',
            'price_monthly': 99.90,
            'features': [
              'Casos ilimitados',
              'Prioridade no matching',
              'Advogados PRO exclusivos',
              'Suporte prioritário',
              'Manager dedicado'
            ],
            'description': 'Serviço concierge e priorização'
          },
          {
            'id': 'ENTERPRISE',
            'name': 'Enterprise',
            'price_monthly': 299.90,
            'features': [
              'Tudo do VIP',
              'SLA de 1 hora',
              'Integração via API',
              'Relatórios customizados',
              'Suporte 24/7',
              'Account manager executivo'
            ],
            'description': 'SLA corporativo e suporte dedicado'
          }
        ];

      case 'lawyer':
        return [
          {
            'id': 'FREE',
            'name': 'Gratuito',
            'price_monthly': 0.0,
            'features': [
              'Perfil básico',
              'Até 5 casos por mês',
              'Comissão padrão: 15%'
            ],
            'description': 'Plano básico para começar'
          },
          {
            'id': 'PRO',
            'name': 'PRO',
            'price_monthly': 149.90,
            'features': [
              'Perfil destacado',
              'Casos premium exclusivos',
              'Comissão reduzida: 10%',
              'Prioridade no matching',
              'Analytics avançado',
              'Suporte prioritário'
            ],
            'description': 'Para advogados que querem destaque e casos premium'
          }
        ];

      case 'firm':
        return [
          {
            'id': 'FREE',
            'name': 'Gratuito',
            'price_monthly': 0.0,
            'features': [
              'Perfil básico do escritório',
              'Até 3 advogados',
              'Comissão padrão: 15%'
            ],
            'description': 'Plano básico para escritórios pequenos'
          },
          {
            'id': 'PARTNER',
            'name': 'Partner',
            'price_monthly': 499.90,
            'features': [
              'Perfil destacado',
              'Até 20 advogados',
              'Comissão reduzida: 12%',
              'Dashboard administrativo',
              'Relatórios de performance',
              'API de integração'
            ],
            'description': 'Para escritórios que buscam crescimento'
          },
          {
            'id': 'PREMIUM',
            'name': 'Premium',
            'price_monthly': 999.90,
            'features': [
              'Tudo do Partner',
              'Advogados ilimitados',
              'Comissão reduzida: 8%',
              'White-label disponível',
              'SLA corporativo',
              'Account manager dedicado',
              'Integração ERP customizada'
            ],
            'description': 'Máxima visibilidade e recursos empresariais'
          }
        ];

      default:
        return [];
    }
  }

  Map<String, dynamic>? _getMockCurrentPlan(String entityType) {
    final plans = _getMockPlansForEntityType(entityType);
    return plans.isNotEmpty ? plans.first : null; // Return FREE plan as current
  }

  String _getPlanDisplayName(String planId) {
    const names = {
      'FREE': 'Gratuito',
      'VIP': 'VIP',
      'ENTERPRISE': 'Enterprise',
      'PRO': 'PRO',
      'PARTNER': 'Partner',
      'PREMIUM': 'Premium',
    };
    return names[planId] ?? planId;
  }

  double _getPlanPrice(String planId) {
    const prices = {
      'FREE': 0.0,
      'VIP': 99.90,
      'ENTERPRISE': 299.90,
      'PRO': 149.90,
      'PARTNER': 499.90,
      'PREMIUM': 999.90,
    };
    return prices[planId] ?? 0.0;
  }

  String _getPlanDescription(String planId) {
    const descriptions = {
      'FREE': 'Plano básico gratuito',
      'VIP': 'Serviço concierge e priorização',
      'ENTERPRISE': 'SLA corporativo e suporte dedicado',
      'PRO': 'Para advogados que querem destaque',
      'PARTNER': 'Para escritórios que buscam crescimento',
      'PREMIUM': 'Máxima visibilidade e recursos empresariais',
    };
    return descriptions[planId] ?? 'Plano personalizado';
  }
} 