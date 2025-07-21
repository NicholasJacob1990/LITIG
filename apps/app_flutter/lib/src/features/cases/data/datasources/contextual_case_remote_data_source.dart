import 'package:dio/dio.dart';
import '../../domain/entities/contextual_case_data.dart';
import '../../domain/entities/allocation_type.dart';
import '../../../../core/utils/logger.dart';

/// Interface para o data source contextual de casos
abstract class ContextualCaseRemoteDataSource {
  /// Busca dados contextuais completos de um caso
  Future<Map<String, dynamic>> getContextualCaseData({
    required String caseId,
    required String userId,
  });

  /// Busca apenas os KPIs contextuais de um caso
  Future<List<ContextualKPI>> getContextualKPIs({
    required String caseId,
    required String userId,
  });

  /// Busca ações contextuais disponíveis para um caso
  Future<ContextualActions> getContextualActions({
    required String caseId,
    required String userId,
  });

  /// Define o tipo de alocação de um caso
  Future<void> setCaseAllocation({
    required String caseId,
    required AllocationType allocationType,
    required Map<String, dynamic> metadata,
  });

  /// Busca casos agrupados por tipo de alocação
  Future<Map<String, List<Map<String, dynamic>>>> getCasesByAllocation({
    required String userId,
  });
}

/// Implementação do data source contextual usando API REST
class ContextualCaseRemoteDataSourceImpl implements ContextualCaseRemoteDataSource {
  final Dio dio;

  ContextualCaseRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> getContextualCaseData({
    required String caseId,
    required String userId,
  }) async {
    AppLogger.info('Fetching contextual data for case: $caseId, user: $userId');

    try {
      final response = await dio.get('/contextual-cases/$caseId');
      
      if (response.statusCode == 200 && response.data != null) {
        AppLogger.info('Contextual data fetched successfully');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Invalid response: ${response.statusCode}');
      }

    } on DioException catch (e) {
      AppLogger.warning('API error, falling back to mock data: ${e.message}');
      
      // Fallback para dados mock quando a API não está disponível
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.response?.statusCode == 404) {
        
        AppLogger.info('Using mock contextual data as fallback');
        return _getMockContextualData(caseId, userId);
      }
      
      // Para outros erros, re-throw
      if (e.response != null) {
        throw Exception('HTTP ${e.response!.statusCode}: ${e.response!.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }

    } catch (e) {
      AppLogger.error('Unexpected error, using mock fallback', error: e);
      return _getMockContextualData(caseId, userId);
    }
  }

  @override
  Future<List<ContextualKPI>> getContextualKPIs({
    required String caseId,
    required String userId,
  }) async {
    AppLogger.info('Fetching contextual KPIs for case: $caseId');

    try {
      final response = await dio.get('/contextual-cases/$caseId/kpis');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final kpisData = data['kpis'] as List<dynamic>? ?? [];
        
        return kpisData
            .map((kpi) => ContextualKPI.fromMap(kpi as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Invalid KPIs response: ${response.statusCode}');
      }

    } on DioException catch (e) {
      AppLogger.warning('KPIs API error, using mock data: ${e.message}');
      return _getMockKPIs(caseId);

    } catch (e) {
      AppLogger.error('Unexpected KPIs error, using mock', error: e);
      return _getMockKPIs(caseId);
    }
  }

  @override
  Future<ContextualActions> getContextualActions({
    required String caseId,
    required String userId,
  }) async {
    AppLogger.info('Fetching contextual actions for case: $caseId');

    try {
      final response = await dio.get('/contextual-cases/$caseId/actions');
      
      if (response.statusCode == 200 && response.data != null) {
        return ContextualActions.fromMap(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Invalid actions response: ${response.statusCode}');
      }

    } on DioException catch (e) {
      AppLogger.warning('Actions API error, using mock data: ${e.message}');
      return _getMockActions(caseId);

    } catch (e) {
      AppLogger.error('Unexpected actions error, using mock', error: e);
      return _getMockActions(caseId);
    }
  }

  @override
  Future<void> setCaseAllocation({
    required String caseId,
    required AllocationType allocationType,
    required Map<String, dynamic> metadata,
  }) async {
    AppLogger.info('Setting allocation for case: $caseId to $allocationType');

    try {
      final response = await dio.post(
        '/contextual-cases/$caseId/allocation',
        data: {
          'allocation_type': allocationType.value,
          'metadata': metadata,
        },
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('Allocation set successfully');
      } else {
        throw Exception('Failed to set allocation: ${response.statusCode}');
      }

    } on DioException catch (e) {
      AppLogger.error('Failed to set allocation', error: e);
      
      if (e.response != null) {
        throw Exception('HTTP ${e.response!.statusCode}: ${e.response!.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }

    } catch (e) {
      AppLogger.error('Unexpected allocation error', error: e);
      rethrow;
    }
  }

  @override
  Future<Map<String, List<Map<String, dynamic>>>> getCasesByAllocation({
    required String userId,
  }) async {
    AppLogger.info('Fetching cases by allocation for user: $userId');

    try {
      final response = await dio.get('/contextual-cases/user/cases-by-allocation');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        // Convert to proper format
        final result = <String, List<Map<String, dynamic>>>{};
        for (final entry in data.entries) {
          final key = entry.key;
          final value = entry.value as List<dynamic>? ?? [];
          result[key] = value.cast<Map<String, dynamic>>();
        }
        
        return result;
      } else {
        throw Exception('Invalid cases by allocation response: ${response.statusCode}');
      }

    } on DioException catch (e) {
      AppLogger.warning('Cases by allocation API error, using mock: ${e.message}');
      return _getMockCasesByAllocation(userId);

    } catch (e) {
      AppLogger.error('Unexpected cases by allocation error, using mock', error: e);
      return _getMockCasesByAllocation(userId);
    }
  }

  // ==================== MOCK DATA METHODS ====================

  /// Mock data que simula a resposta da API `/contextual-cases/{case_id}`
  Map<String, dynamic> _getMockContextualData(String caseId, String userId) {
    final allocationType = _getMockAllocationType(caseId);
    
    return {
      'case_detail': _getMockCaseDetail(caseId),
      'contextual_data': _getMockContextualCaseData(allocationType),
      'kpis': _getMockKPIsData(allocationType),
      'actions': _getMockActionsData(allocationType),
      'highlight': _getMockHighlightData(allocationType),
    };
  }

  AllocationType _getMockAllocationType(String caseId) {
    final hash = caseId.hashCode;
    const types = AllocationType.values;
    return types[hash.abs() % types.length];
  }

  Map<String, dynamic> _getMockCaseDetail(String caseId) {
    return {
      'id': caseId,
      'title': 'Caso Mock - Disputa Contratual',
      'description': 'Descrição mock do caso para desenvolvimento',
      'status': 'Em Andamento',
      'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'assigned_lawyer': {
        'id': 'lawyer-1',
        'name': 'Dr. João Silva',
        'specialty': 'Direito Empresarial',
        'avatar_url': 'https://via.placeholder.com/150',
        'unread_messages': 2,
        'created_date': '2024-01-15',
      },
      'consultation': {
        'date': '16/01/2024',
        'duration': '45 minutos',
        'modality': 'Vídeo',
        'plan': 'Plano por Ato',
      },
      'pre_analysis': {
        'ai_generated': true,
        'estimated_days': 15,
        'urgency_level': 8,
        'documents': ['Contrato', 'Carta de Demissão'],
        'costs': {'consulta': 350.0, 'representacao': 2500.0},
        'risk_assessment': 'Risco baixo. Documentação sólida.',
      },
      'next_steps': [
        {
          'title': 'Enviar documentos',
          'description': 'Contrato de trabalho, carta de demissão',
          'deadline': '24/01/2024',
          'priority': 'high',
          'status': 'pending',
        },
      ],
      'documents': [],
      'process_status': {
        'current_phase': 'Em Andamento',
        'description': 'Processo em fase de coleta de provas',
        'progress_percentage': 45.0,
        'phases': [],
      },
    };
  }

  Map<String, dynamic> _getMockContextualCaseData(AllocationType allocationType) {
    switch (allocationType) {
      case AllocationType.internalDelegation:
        return {
          'allocation_type': allocationType.value,
          'delegated_by_name': 'Dr. Carlos Mendes',
          'hours_budgeted': 40,
          'hourly_rate': 150.0,
          'deadline_days': 15,
        };
      
      case AllocationType.platformMatchDirect:
        return {
          'allocation_type': allocationType.value,
          'match_score': 0.94,
          'estimated_value': 8500.0,
          'complexity_score': 7,
          'conversion_rate': 85.0,
          'sla_hours': 2,
          'ai_reason': 'Match baseado em especialização e proximidade',
        };
      
      case AllocationType.partnershipProactiveSearch:
        return {
          'allocation_type': allocationType.value,
          'partner_name': 'Advocacia Silva & Santos',
          'your_share': 70,
          'partner_share': 30,
          'partner_rating': 4.8,
        };
      
      default:
        return {
          'allocation_type': allocationType.value,
        };
    }
  }

  List<Map<String, dynamic>> _getMockKPIsData(AllocationType allocationType) {
    switch (allocationType) {
      case AllocationType.internalDelegation:
        return [
          {'icon': '⏰', 'label': 'Prazo', 'value': '15 dias'},
          {'icon': '📈', 'label': 'Horas', 'value': '40h'},
          {'icon': '💼', 'label': 'Valor/h', 'value': 'R\$ 150'},
        ];
      
      case AllocationType.platformMatchDirect:
        return [
          {'icon': '🎯', 'label': 'Match', 'value': '94%'},
          {'icon': '💰', 'label': 'Valor', 'value': 'R\$ 8.5k'},
          {'icon': '📊', 'label': 'Complexidade', 'value': '7/10'},
        ];
      
      case AllocationType.partnershipProactiveSearch:
        return [
          {'icon': '🤝', 'label': 'Parceiro', 'value': 'Silva & Santos'},
          {'icon': '📋', 'label': 'Divisão', 'value': '70/30%'},
          {'icon': '⭐', 'label': 'Rating', 'value': '4.8'},
        ];
      
      default:
        return [
          {'icon': '📊', 'label': 'Status', 'value': 'Ativo'},
          {'icon': '📅', 'label': 'Criado', 'value': '5 dias'},
          {'icon': '🔄', 'label': 'Atualizado', 'value': 'Hoje'},
        ];
    }
  }

  Map<String, dynamic> _getMockActionsData(AllocationType allocationType) {
    switch (allocationType) {
      case AllocationType.internalDelegation:
        return {
          'primary_action': {'label': 'Registrar Horas', 'action': 'log_hours'},
          'secondary_actions': [
            {'label': 'Atualizar Status', 'action': 'update_status'},
            {'label': 'Contatar Delegador', 'action': 'contact_delegator'},
          ],
        };
      
      case AllocationType.platformMatchDirect:
        return {
          'primary_action': {'label': 'Aceitar Caso', 'action': 'accept_case'},
          'secondary_actions': [
            {'label': 'Ver Perfil', 'action': 'view_client_profile'},
            {'label': 'Solicitar Info', 'action': 'request_info'},
          ],
        };
      
      case AllocationType.partnershipProactiveSearch:
        return {
          'primary_action': {'label': 'Alinhar Estratégia', 'action': 'align_strategy'},
          'secondary_actions': [
            {'label': 'Contatar Parceiro', 'action': 'contact_partner'},
            {'label': 'Ver Contrato', 'action': 'view_contract'},
          ],
        };
      
      default:
        return {
          'primary_action': {'label': 'Ver Detalhes', 'action': 'view_details'},
          'secondary_actions': [
            {'label': 'Editar', 'action': 'edit'},
          ],
        };
    }
  }

  Map<String, dynamic> _getMockHighlightData(AllocationType allocationType) {
    switch (allocationType) {
      case AllocationType.internalDelegation:
        return {'text': '👨‍💼 Delegado internamente', 'color': 'orange'};
      
      case AllocationType.platformMatchDirect:
        return {'text': '🎯 Match direto para você', 'color': 'blue'};
      
      case AllocationType.partnershipProactiveSearch:
        return {'text': '🤝 Caso captado via parceria', 'color': 'green'};
      
      default:
        return {'text': '📋 Caso padrão', 'color': 'grey'};
    }
  }

  List<ContextualKPI> _getMockKPIs(String caseId) {
    final allocationType = _getMockAllocationType(caseId);
    final kpisData = _getMockKPIsData(allocationType);
    return kpisData.map((kpi) => ContextualKPI.fromMap(kpi)).toList();
  }

  ContextualActions _getMockActions(String caseId) {
    final allocationType = _getMockAllocationType(caseId);
    final actionsData = _getMockActionsData(allocationType);
    return ContextualActions.fromMap(actionsData);
  }

  Map<String, List<Map<String, dynamic>>> _getMockCasesByAllocation(String userId) {
    return {
      'internal_delegation': [
        {
          'id': 'case-1',
          'status': 'Em Andamento',
          'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'allocation_type': 'internal_delegation',
        },
      ],
      'platform_match_direct': [
        {
          'id': 'case-2',
          'status': 'Aguardando Aceite',
          'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'allocation_type': 'platform_match_direct',
        },
      ],
      'partnership_proactive_search': [
        {
          'id': 'case-3',
          'status': 'Em Negociação',
          'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'allocation_type': 'partnership_proactive_search',
        },
      ],
    };
  }
} 
