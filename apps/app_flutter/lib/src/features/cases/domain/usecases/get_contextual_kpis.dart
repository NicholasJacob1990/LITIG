import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

/// UseCase para obter KPIs contextuais
/// 
/// Fornece indicadores de performance específicos
/// baseados no contexto do usuário e caso
class GetContextualKpisUseCase implements UseCase<List<Map<String, dynamic>>, GetContextualKpisParams> {
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetContextualKpisParams params) async {
    try {
      final kpis = _generateContextualKpis(params.userRole, params.caseId, params.timeframe);
      return Right(kpis);
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao obter KPIs contextuais: $e'));
    }
  }

  List<Map<String, dynamic>> _generateContextualKpis(String userRole, String caseId, String timeframe) {
    switch (userRole) {
      case 'lawyer_individual':
        return _getLawyerIndividualKpis(timeframe);
      case 'lawyer_office':
        return _getLawyerOfficeKpis(timeframe);
      case 'lawyer_firm_member':  // Atualizado de lawyer_associated
        return _getLawyerAssociatedKpis(timeframe);
      case 'client':
        return _getClientKpis(timeframe);
      default:
        return _getDefaultKpis();
    }
  }

  List<Map<String, dynamic>> _getLawyerIndividualKpis(String timeframe) {
    return [
      {
        'id': 'billable_hours',
        'title': 'Horas Faturáveis',
        'value': 45.5,
        'unit': 'h',
        'trend': 0.12, // +12%
        'target': 50.0,
        'icon': 'clock',
        'color': 'blue',
        'description': 'Horas trabalhadas que podem ser faturadas ao cliente',
      },
      {
        'id': 'case_efficiency',
        'title': 'Eficiência do Caso',
        'value': 0.85,
        'unit': '%',
        'trend': 0.08,
        'target': 0.90,
        'icon': 'trending_up',
        'color': 'green',
        'description': 'Percentual de tarefas concluídas dentro do prazo',
      },
      {
        'id': 'client_satisfaction',
        'title': 'Satisfação do Cliente',
        'value': 4.2,
        'unit': '/5',
        'trend': 0.05,
        'target': 4.5,
        'icon': 'star',
        'color': 'orange',
        'description': 'Avaliação média dos clientes no período',
      },
      {
        'id': 'deadline_compliance',
        'title': 'Cumprimento de Prazos',
        'value': 0.92,
        'unit': '%',
        'trend': -0.03,
        'target': 0.95,
        'icon': 'schedule',
        'color': 'purple',
        'description': 'Percentual de prazos cumpridos no prazo',
      },
    ];
  }

  List<Map<String, dynamic>> _getLawyerOfficeKpis(String timeframe) {
    return [
      {
        'id': 'revenue',
        'title': 'Receita do Escritório',
        'value': 125750.0,
        'unit': 'R\$',
        'trend': 0.18,
        'target': 150000.0,
        'icon': 'attach_money',
        'color': 'green',
        'description': 'Receita total gerada no período',
      },
      {
        'id': 'profit_margin',
        'title': 'Margem de Lucro',
        'value': 0.68,
        'unit': '%',
        'trend': 0.05,
        'target': 0.75,
        'icon': 'trending_up',
        'color': 'blue',
        'description': 'Margem de lucro líquido do escritório',
      },
      {
        'id': 'team_utilization',
        'title': 'Utilização da Equipe',
        'value': 0.78,
        'unit': '%',
        'trend': 0.12,
        'target': 0.85,
        'icon': 'people',
        'color': 'orange',
        'description': 'Percentual de capacidade da equipe sendo utilizada',
      },
      {
        'id': 'client_retention',
        'title': 'Retenção de Clientes',
        'value': 0.91,
        'unit': '%',
        'trend': 0.08,
        'target': 0.95,
        'icon': 'favorite',
        'color': 'red',
        'description': 'Percentual de clientes que permanecem ativos',
      },
      {
        'id': 'case_success_rate',
        'title': 'Taxa de Sucesso',
        'value': 0.87,
        'unit': '%',
        'trend': 0.15,
        'target': 0.90,
        'icon': 'check_circle',
        'color': 'green',
        'description': 'Percentual de casos ganhos ou resolvidos favoravelmente',
      },
      {
        'id': 'sla_compliance',
        'title': 'Conformidade SLA',
        'value': 0.94,
        'unit': '%',
        'trend': 0.07,
        'target': 0.98,
        'icon': 'verified',
        'color': 'purple',
        'description': 'Cumprimento dos acordos de nível de serviço',
      },
    ];
  }

  List<Map<String, dynamic>> _getLawyerAssociatedKpis(String timeframe) {
    return [
      {
        'id': 'delegation_efficiency',
        'title': 'Eficiência de Delegação',
        'value': 0.76,
        'unit': '%',
        'trend': 0.09,
        'target': 0.85,
        'icon': 'assignment',
        'color': 'blue',
        'description': 'Eficiência na execução de tarefas delegadas',
      },
      {
        'id': 'learning_progress',
        'title': 'Progresso de Aprendizado',
        'value': 0.84,
        'unit': '%',
        'trend': 0.22,
        'target': 0.90,
        'icon': 'school',
        'color': 'green',
        'description': 'Progresso em cursos e capacitações',
      },
      {
        'id': 'mentor_rating',
        'title': 'Avaliação do Mentor',
        'value': 4.1,
        'unit': '/5',
        'trend': 0.15,
        'target': 4.5,
        'icon': 'person',
        'color': 'orange',
        'description': 'Avaliação recebida do advogado responsável',
      },
      {
        'id': 'case_contribution',
        'title': 'Contribuição nos Casos',
        'value': 0.72,
        'unit': '%',
        'trend': 0.18,
        'target': 0.80,
        'icon': 'handshake',
        'color': 'purple',
        'description': 'Nível de contribuição nos casos do escritório',
      },
    ];
  }

  List<Map<String, dynamic>> _getClientKpis(String timeframe) {
    return [
      {
        'id': 'case_progress',
        'title': 'Progresso do Caso',
        'value': 0.65,
        'unit': '%',
        'trend': 0.12,
        'target': 1.0,
        'icon': 'timeline',
        'color': 'blue',
        'description': 'Percentual de conclusão do seu caso',
      },
      {
        'id': 'communication_frequency',
        'title': 'Frequência de Comunicação',
        'value': 2.3,
        'unit': '/semana',
        'trend': 0.08,
        'target': 3.0,
        'icon': 'chat',
        'color': 'green',
        'description': 'Número médio de interações por semana',
      },
      {
        'id': 'response_time',
        'title': 'Tempo de Resposta',
        'value': 2.1,
        'unit': 'h',
        'trend': -0.15, // Melhoria - menor tempo
        'target': 2.0,
        'icon': 'schedule',
        'color': 'orange',
        'description': 'Tempo médio de resposta do advogado',
      },
      {
        'id': 'cost_efficiency',
        'title': 'Eficiência de Custo',
        'value': 0.89,
        'unit': '%',
        'trend': 0.05,
        'target': 0.95,
        'icon': 'savings',
        'color': 'purple',
        'description': 'Relação custo-benefício do serviço jurídico',
      },
    ];
  }

  List<Map<String, dynamic>> _getDefaultKpis() {
    return [
      {
        'id': 'general_performance',
        'title': 'Performance Geral',
        'value': 0.75,
        'unit': '%',
        'trend': 0.10,
        'target': 0.85,
        'icon': 'bar_chart',
        'color': 'blue',
        'description': 'Indicador geral de performance',
      },
    ];
  }
}

class GetContextualKpisParams {
  final String userRole;
  final String caseId;
  final String timeframe;

  GetContextualKpisParams({
    required this.userRole,
    required this.caseId,
    this.timeframe = 'monthly',
  });
}