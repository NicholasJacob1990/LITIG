import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

/// UseCase para obter dados contextuais de casos
/// 
/// Responsável por buscar informações contextuais específicas
/// baseadas no perfil do usuário e tipo de caso
class GetContextualCaseDataUseCase implements UseCase<Map<String, dynamic>, GetContextualCaseDataParams> {
  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GetContextualCaseDataParams params) async {
    try {
      // Mock implementation - em produção seria conectado ao repositório
      final contextualData = {
        'caseId': params.caseId,
        'userRole': params.userRole,
        'contextType': params.contextType,
        'data': _getContextualDataForType(params.contextType, params.userRole),
        'timestamp': DateTime.now().toIso8601String(),
      };

      return Right(contextualData);
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao obter dados contextuais: $e'));
    }
  }

  /// Retorna dados contextuais baseados no tipo e papel do usuário
  Map<String, dynamic> _getContextualDataForType(String contextType, String userRole) {
    switch (contextType) {
      case 'case_overview':
        return _getCaseOverviewData(userRole);
      case 'case_metrics':
        return _getCaseMetricsData(userRole);
      case 'case_actions':
        return _getCaseActionsData(userRole);
      case 'case_timeline':
        return _getCaseTimelineData(userRole);
      default:
        return {'message': 'Tipo de contexto não encontrado'};
    }
  }

  Map<String, dynamic> _getCaseOverviewData(String userRole) {
    final baseData = {
      'status': 'Em Andamento',
      'progress': 0.65,
      'priority': 'Alta',
      'category': 'Cível',
    };

    switch (userRole) {
      case 'lawyer_individual':
        return {
          ...baseData,
          'nextAction': 'Revisar petição inicial',
          'deadline': '2024-02-15',
          'workload': 'Moderada',
        };
      case 'lawyer_office':
        return {
          ...baseData,
          'assignedLawyers': ['Dr. Silva', 'Dra. Santos'],
          'billing': {'hours': 45.5, 'rate': 350.0},
          'clientSatisfaction': 4.2,
        };
      case 'client':
        return {
          ...baseData,
          'lawyer': 'Dr. Silva',
          'lastUpdate': '2024-01-28',
          'nextHearing': '2024-02-20',
        };
      default:
        return baseData;
    }
  }

  Map<String, dynamic> _getCaseMetricsData(String userRole) {
    final baseMetrics = {
      'completion': 0.65,
      'timeSpent': 45.5,
      'documentsProcessed': 12,
    };

    switch (userRole) {
      case 'lawyer_individual':
        return {
          ...baseMetrics,
          'billableHours': 45.5,
          'efficiency': 0.85,
          'deadlineCompliance': 0.92,
        };
      case 'lawyer_office':
        return {
          ...baseMetrics,
          'revenue': 15925.0,
          'profitMargin': 0.68,
          'teamUtilization': 0.78,
          'clientRetention': 0.91,
        };
      case 'client':
        return {
          ...baseMetrics,
          'satisfaction': 4.2,
          'responseTime': '2.3 horas',
          'communicationFrequency': 'Semanal',
        };
      default:
        return baseMetrics;
    }
  }

  Map<String, dynamic> _getCaseActionsData(String userRole) {
    switch (userRole) {
      case 'lawyer_individual':
        return {
          'availableActions': [
            'Redigir petição',
            'Agendar reunião',
            'Solicitar documentos',
            'Atualizar status',
          ],
          'urgentActions': [
            'Revisar prazo processual',
          ],
          'suggestedActions': [
            'Preparar defesa',
            'Contatar testemunhas',
          ],
        };
      case 'lawyer_office':
        return {
          'availableActions': [
            'Delegar tarefa',
            'Revisar faturamento',
            'Gerar relatório',
            'Agendar equipe',
          ],
          'managementActions': [
            'Avaliar performance',
            'Otimizar recursos',
          ],
          'clientActions': [
            'Enviar update',
            'Agendar call',
          ],
        };
      case 'client':
        return {
          'availableActions': [
            'Visualizar progresso',
            'Enviar mensagem',
            'Agendar reunião',
            'Fazer pagamento',
          ],
          'documents': [
            'Baixar relatório',
            'Enviar documento',
          ],
        };
      default:
        return {'availableActions': []};
    }
  }

  Map<String, dynamic> _getCaseTimelineData(String userRole) {
    final baseTimeline = [
      {
        'date': '2024-01-15',
        'event': 'Caso iniciado',
        'type': 'milestone',
      },
      {
        'date': '2024-01-20',
        'event': 'Documentos coletados',
        'type': 'action',
      },
      {
        'date': '2024-01-25',
        'event': 'Petição inicial redigida',
        'type': 'document',
      },
    ];

    switch (userRole) {
      case 'lawyer_individual':
        return {
          'timeline': baseTimeline,
          'upcomingDeadlines': [
            {'date': '2024-02-15', 'description': 'Protocolar petição'},
            {'date': '2024-02-20', 'description': 'Audiência preliminar'},
          ],
          'workHours': [
            {'date': '2024-01-20', 'hours': 4.5},
            {'date': '2024-01-25', 'hours': 6.0},
          ],
        };
      case 'lawyer_office':
        return {
          'timeline': baseTimeline,
          'teamActivities': [
            {'lawyer': 'Dr. Silva', 'activity': 'Revisão de documentos'},
            {'lawyer': 'Dra. Santos', 'activity': 'Pesquisa jurisprudencial'},
          ],
          'billing': [
            {'date': '2024-01-20', 'amount': 1575.0},
            {'date': '2024-01-25', 'amount': 2100.0},
          ],
        };
      case 'client':
        return {
          'timeline': baseTimeline,
          'communications': [
            {'date': '2024-01-22', 'type': 'email', 'subject': 'Update do caso'},
            {'date': '2024-01-26', 'type': 'call', 'duration': '30 min'},
          ],
          'payments': [
            {'date': '2024-01-15', 'amount': 5000.0, 'status': 'pago'},
          ],
        };
      default:
        return {'timeline': baseTimeline};
    }
  }
}

class GetContextualCaseDataParams {
  final String caseId;
  final String userRole;
  final String contextType;

  GetContextualCaseDataParams({
    required this.caseId,
    required this.userRole,
    required this.contextType,
  });
}