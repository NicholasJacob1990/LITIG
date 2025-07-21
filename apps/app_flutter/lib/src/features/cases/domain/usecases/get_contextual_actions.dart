import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

/// UseCase para obter ações contextuais
/// 
/// Fornece ações específicas baseadas no contexto do usuário,
/// tipo de caso e estado atual do processo
class GetContextualActionsUseCase implements UseCase<List<Map<String, dynamic>>, GetContextualActionsParams> {
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetContextualActionsParams params) async {
    try {
      final actions = _generateContextualActions(params.userRole, params.caseStatus, params.caseType);
      return Right(actions);
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao obter ações contextuais: $e'));
    }
  }

  List<Map<String, dynamic>> _generateContextualActions(String userRole, String caseStatus, String caseType) {
    final baseActions = _getBaseActions(userRole);
    final statusSpecificActions = _getStatusSpecificActions(caseStatus, userRole);
    final typeSpecificActions = _getTypeSpecificActions(caseType, userRole);

    // Combinar e priorizar ações
    final allActions = <Map<String, dynamic>>[
      ...baseActions,
      ...statusSpecificActions,
      ...typeSpecificActions,
    ];

    // Remover duplicatas e ordenar por prioridade
    final uniqueActions = _removeDuplicatesAndSort(allActions);
    
    return uniqueActions;
  }

  List<Map<String, dynamic>> _getBaseActions(String userRole) {
    switch (userRole) {
      case 'lawyer_individual':
        return [
          {
            'id': 'view_case_details',
            'title': 'Ver Detalhes do Caso',
            'description': 'Visualizar informações completas do caso',
            'icon': 'info',
            'color': 'blue',
            'priority': 'medium',
            'category': 'navigation',
            'enabled': true,
          },
          {
            'id': 'update_case_status',
            'title': 'Atualizar Status',
            'description': 'Modificar o status atual do caso',
            'icon': 'edit',
            'color': 'orange',
            'priority': 'high',
            'category': 'management',
            'enabled': true,
          },
          {
            'id': 'add_case_note',
            'title': 'Adicionar Nota',
            'description': 'Registrar observações sobre o caso',
            'icon': 'note_add',
            'color': 'green',
            'priority': 'medium',
            'category': 'documentation',
            'enabled': true,
          },
        ];

      case 'lawyer_office':
        return [
          {
            'id': 'delegate_task',
            'title': 'Delegar Tarefa',
            'description': 'Atribuir responsabilidades para a equipe',
            'icon': 'assignment_ind',
            'color': 'purple',
            'priority': 'high',
            'category': 'management',
            'enabled': true,
          },
          {
            'id': 'generate_report',
            'title': 'Gerar Relatório',
            'description': 'Criar relatório de progresso para o cliente',
            'icon': 'assessment',
            'color': 'blue',
            'priority': 'medium',
            'category': 'reporting',
            'enabled': true,
          },
          {
            'id': 'review_billing',
            'title': 'Revisar Faturamento',
            'description': 'Verificar horas e custos do caso',
            'icon': 'receipt',
            'color': 'green',
            'priority': 'high',
            'category': 'financial',
            'enabled': true,
          },
        ];

      case 'lawyer_associated':
        return [
          {
            'id': 'complete_assigned_task',
            'title': 'Completar Tarefa',
            'description': 'Finalizar tarefa delegada pelo responsável',
            'icon': 'task_alt',
            'color': 'green',
            'priority': 'high',
            'category': 'execution',
            'enabled': true,
          },
          {
            'id': 'request_guidance',
            'title': 'Solicitar Orientação',
            'description': 'Pedir ajuda ao advogado responsável',
            'icon': 'help',
            'color': 'orange',
            'priority': 'medium',
            'category': 'support',
            'enabled': true,
          },
        ];

      case 'client':
        return [
          {
            'id': 'view_progress',
            'title': 'Ver Progresso',
            'description': 'Acompanhar o andamento do seu caso',
            'icon': 'timeline',
            'color': 'blue',
            'priority': 'high',
            'category': 'information',
            'enabled': true,
          },
          {
            'id': 'send_message',
            'title': 'Enviar Mensagem',
            'description': 'Comunicar-se com seu advogado',
            'icon': 'message',
            'color': 'green',
            'priority': 'medium',
            'category': 'communication',
            'enabled': true,
          },
          {
            'id': 'upload_document',
            'title': 'Enviar Documento',
            'description': 'Fazer upload de documentos necessários',
            'icon': 'upload_file',
            'color': 'orange',
            'priority': 'medium',
            'category': 'documentation',
            'enabled': true,
          },
        ];

      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _getStatusSpecificActions(String caseStatus, String userRole) {
    switch (caseStatus) {
      case 'iniciado':
        return [
          {
            'id': 'collect_initial_documents',
            'title': 'Coletar Documentos',
            'description': 'Reunir documentação inicial necessária',
            'icon': 'folder_open',
            'color': 'orange',
            'priority': 'urgent',
            'category': 'preparation',
            'enabled': true,
          },
          {
            'id': 'define_strategy',
            'title': 'Definir Estratégia',
            'description': 'Estabelecer abordagem legal para o caso',
            'icon': 'strategy',
            'color': 'purple',
            'priority': 'high',
            'category': 'planning',
            'enabled': userRole.contains('lawyer'),
          },
        ];

      case 'em_andamento':
        return [
          {
            'id': 'track_deadlines',
            'title': 'Acompanhar Prazos',
            'description': 'Monitorar prazos processuais importantes',
            'icon': 'schedule',
            'color': 'red',
            'priority': 'urgent',
            'category': 'monitoring',
            'enabled': true,
          },
          {
            'id': 'prepare_next_phase',
            'title': 'Preparar Próxima Fase',
            'description': 'Planejar próximos passos do processo',
            'icon': 'next_plan',
            'color': 'blue',
            'priority': 'high',
            'category': 'planning',
            'enabled': userRole.contains('lawyer'),
          },
        ];

      case 'aguardando_documentos':
        return [
          {
            'id': 'request_pending_documents',
            'title': 'Solicitar Documentos',
            'description': 'Cobrar documentos pendentes',
            'icon': 'request_page',
            'color': 'orange',
            'priority': 'urgent',
            'category': 'documentation',
            'enabled': true,
          },
        ];

      case 'concluido':
        return [
          {
            'id': 'generate_final_report',
            'title': 'Relatório Final',
            'description': 'Gerar resumo final do caso',
            'icon': 'summarize',
            'color': 'green',
            'priority': 'medium',
            'category': 'reporting',
            'enabled': userRole.contains('lawyer'),
          },
          {
            'id': 'client_satisfaction_survey',
            'title': 'Pesquisa de Satisfação',
            'description': 'Coletar feedback do cliente',
            'icon': 'feedback',
            'color': 'blue',
            'priority': 'medium',
            'category': 'feedback',
            'enabled': true,
          },
        ];

      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _getTypeSpecificActions(String caseType, String userRole) {
    switch (caseType) {
      case 'trabalhista':
        return [
          {
            'id': 'calculate_labor_rights',
            'title': 'Calcular Direitos',
            'description': 'Computar valores trabalhistas',
            'icon': 'calculate',
            'color': 'green',
            'priority': 'high',
            'category': 'calculation',
            'enabled': userRole.contains('lawyer'),
          },
          {
            'id': 'schedule_conciliation',
            'title': 'Agendar Conciliação',
            'description': 'Marcar audiência de conciliação',
            'icon': 'event',
            'color': 'blue',
            'priority': 'medium',
            'category': 'scheduling',
            'enabled': userRole.contains('lawyer'),
          },
        ];

      case 'civil':
        return [
          {
            'id': 'draft_petition',
            'title': 'Redigir Petição',
            'description': 'Elaborar petição inicial ou contestação',
            'icon': 'edit_document',
            'color': 'purple',
            'priority': 'high',
            'category': 'documentation',
            'enabled': userRole.contains('lawyer'),
          },
          {
            'id': 'research_jurisprudence',
            'title': 'Pesquisar Jurisprudência',
            'description': 'Buscar precedentes jurídicos relevantes',
            'icon': 'search',
            'color': 'orange',
            'priority': 'medium',
            'category': 'research',
            'enabled': userRole.contains('lawyer'),
          },
        ];

      case 'criminal':
        return [
          {
            'id': 'prepare_defense',
            'title': 'Preparar Defesa',
            'description': 'Elaborar estratégia de defesa',
            'icon': 'shield',
            'color': 'red',
            'priority': 'urgent',
            'category': 'preparation',
            'enabled': userRole.contains('lawyer'),
          },
          {
            'id': 'contact_witnesses',
            'title': 'Contatar Testemunhas',
            'description': 'Organizar depoimentos de testemunhas',
            'icon': 'people',
            'color': 'blue',
            'priority': 'high',
            'category': 'preparation',
            'enabled': userRole.contains('lawyer'),
          },
        ];

      case 'familia':
        return [
          {
            'id': 'mediation_session',
            'title': 'Sessão de Mediação',
            'description': 'Agendar ou participar de mediação',
            'icon': 'handshake',
            'color': 'green',
            'priority': 'high',
            'category': 'resolution',
            'enabled': true,
          },
          {
            'id': 'custody_arrangement',
            'title': 'Acordo de Guarda',
            'description': 'Estabelecer arranjos de guarda',
            'icon': 'family_restroom',
            'color': 'orange',
            'priority': 'high',
            'category': 'arrangement',
            'enabled': userRole.contains('lawyer'),
          },
        ];

      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _removeDuplicatesAndSort(List<Map<String, dynamic>> actions) {
    // Remover duplicatas baseado no ID
    final seen = <String>{};
    final uniqueActions = actions.where((action) {
      final id = action['id'] as String;
      if (seen.contains(id)) {
        return false;
      }
      seen.add(id);
      return true;
    }).toList();

    // Ordenar por prioridade
    final priorityOrder = {'urgent': 4, 'high': 3, 'medium': 2, 'low': 1};
    
    uniqueActions.sort((a, b) {
      final aPriority = priorityOrder[a['priority']] ?? 0;
      final bPriority = priorityOrder[b['priority']] ?? 0;
      return bPriority.compareTo(aPriority);
    });

    return uniqueActions;
  }
}

class GetContextualActionsParams {
  final String userRole;
  final String caseStatus;
  final String caseType;
  final String? caseId;

  GetContextualActionsParams({
    required this.userRole,
    required this.caseStatus,
    required this.caseType,
    this.caseId,
  });
}