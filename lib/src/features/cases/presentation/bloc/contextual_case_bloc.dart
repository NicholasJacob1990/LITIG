import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/contextual_case_data.dart';
import '../../domain/entities/allocation_type.dart';
import '../../../../core/utils/logger.dart';

part 'contextual_case_event.dart';
part 'contextual_case_state.dart';

/// BLoC para gerenciar dados contextuais dos casos
/// Implementa o sistema de Contextual Case View conforme ARQUITETURA_GERAL_DO_SISTEMA.md
class ContextualCaseBloc extends Bloc<ContextualCaseEvent, ContextualCaseState> {
  ContextualCaseBloc() : super(ContextualCaseInitial()) {
    on<FetchContextualCaseData>(_onFetchContextualCaseData);
    on<FetchContextualKPIs>(_onFetchContextualKPIs);
    on<FetchContextualActions>(_onFetchContextualActions);
    on<SetAllocationTypeEvent>(_onSetAllocationType);
    on<FetchCasesByAllocation>(_onFetchCasesByAllocation);
    on<ExecuteContextualAction>(_onExecuteContextualAction);
  }

  /// Handler para buscar dados contextuais completos de um caso
  Future<void> _onFetchContextualCaseData(
    FetchContextualCaseData event,
    Emitter<ContextualCaseState> emit,
  ) async {
    AppLogger.info('Fetching contextual data for case ${event.caseId}');
    emit(ContextualCaseLoading());

    try {
      // Mock data para desenvolvimento
      final mockContextualData = ContextualCaseData(
        allocationType: AllocationType.platformMatchDirect,
        partnerId: null,
        delegatedBy: null,
        matchScore: 0.95,
        responseDeadline: DateTime.now().add(const Duration(hours: 24)),
        contextMetadata: {'source': 'algorithm', 'priority': 'high'},
      );

      final mockKPIs = [
        ContextualKPI(
          id: 'conversion_rate',
          label: 'Taxa de Conversão',
          value: '85%',
          trend: 'up',
          description: 'Matches aceitos vs oferecidos',
        ),
        ContextualKPI(
          id: 'response_time',
          label: 'Tempo de Resposta',
          value: '2h',
          trend: 'stable',
          description: 'Tempo médio de resposta',
        ),
      ];

      final mockActions = ContextualActions(
        primary: [
          ContextualAction(id: 'accept', label: 'Aceitar Caso', icon: 'check'),
          ContextualAction(id: 'negotiate', label: 'Negociar', icon: 'chat'),
        ],
        secondary: [
          ContextualAction(id: 'delegate', label: 'Delegar', icon: 'person_add'),
          ContextualAction(id: 'reject', label: 'Rejeitar', icon: 'close'),
        ],
      );

      final mockHighlight = ContextualHighlight(
        text: 'Match Direto - Algoritmo IA',
        color: 'blue',
        priority: 'high',
      );

      emit(ContextualCaseDataLoaded(
        contextualData: mockContextualData,
        kpis: mockKPIs,
        actions: mockActions,
        highlight: mockHighlight,
      ));

      AppLogger.success('Contextual data loaded successfully for case ${event.caseId}');
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching contextual data: $e', error: e, stackTrace: stackTrace);
      emit(ContextualCaseError(message: 'Erro ao carregar dados contextuais: $e'));
    }
  }

  /// Handler para buscar KPIs contextuais
  Future<void> _onFetchContextualKPIs(
    FetchContextualKPIs event,
    Emitter<ContextualCaseState> emit,
  ) async {
    AppLogger.info('Fetching contextual KPIs for case ${event.caseId}');
    emit(ContextualCaseLoading());

    try {
      final mockKPIs = [
        ContextualKPI(
          id: 'success_rate',
          label: 'Taxa de Sucesso',
          value: '92%',
          trend: 'up',
          description: 'Casos ganhos vs total',
        ),
      ];

      emit(ContextualKPIsLoaded(caseId: event.caseId, kpis: mockKPIs));
      AppLogger.success('KPIs loaded for case ${event.caseId}');
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching KPIs: $e', error: e, stackTrace: stackTrace);
      emit(ContextualCaseError(message: 'Erro ao carregar KPIs: $e'));
    }
  }

  /// Handler para buscar ações contextuais
  Future<void> _onFetchContextualActions(
    FetchContextualActions event,
    Emitter<ContextualCaseState> emit,
  ) async {
    AppLogger.info('Fetching contextual actions for case ${event.caseId}');
    emit(ContextualCaseLoading());

    try {
      final mockActions = ContextualActions(
        primary: [
          ContextualAction(id: 'view_details', label: 'Ver Detalhes', icon: 'info'),
        ],
        secondary: [
          ContextualAction(id: 'share', label: 'Compartilhar', icon: 'share'),
        ],
      );

      emit(ContextualActionsLoaded(caseId: event.caseId, actions: mockActions));
      AppLogger.success('Actions loaded for case ${event.caseId}');
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching actions: $e', error: e, stackTrace: stackTrace);
      emit(ContextualCaseError(message: 'Erro ao carregar ações: $e'));
    }
  }

  /// Handler para definir tipo de alocação
  Future<void> _onSetAllocationType(
    SetAllocationTypeEvent event,
    Emitter<ContextualCaseState> emit,
  ) async {
    AppLogger.info('Setting allocation type ${event.allocationType} for case ${event.caseId}');
    emit(ContextualCaseLoading());

    try {
      emit(AllocationTypeSet(
        caseId: event.caseId,
        allocationType: event.allocationType,
        message: 'Tipo de alocação definido com sucesso',
      ));
      AppLogger.success('Allocation type set for case ${event.caseId}');
    } catch (e, stackTrace) {
      AppLogger.error('Error setting allocation type: $e', error: e, stackTrace: stackTrace);
      emit(ContextualCaseError(message: 'Erro ao definir tipo de alocação: $e'));
    }
  }

  /// Handler para buscar casos por alocação
  Future<void> _onFetchCasesByAllocation(
    FetchCasesByAllocation event,
    Emitter<ContextualCaseState> emit,
  ) async {
    AppLogger.info('Fetching cases by allocation for user ${event.userId}');
    emit(ContextualCaseLoading());

    try {
      final mockCasesByAllocation = <AllocationType, List<Case>>{
        AllocationType.platformMatchDirect: [],
        AllocationType.platformMatchPartnership: [],
        AllocationType.partnershipProactiveSearch: [],
        AllocationType.partnershipPlatformSuggestion: [],
        AllocationType.internalDelegation: [],
      };

      emit(CasesByAllocationLoaded(casesByAllocation: mockCasesByAllocation));
      AppLogger.success('Cases by allocation loaded for user ${event.userId}');
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching cases by allocation: $e', error: e, stackTrace: stackTrace);
      emit(ContextualCaseError(message: 'Erro ao carregar casos por alocação: $e'));
    }
  }

  /// Handler para executar ação contextual
  Future<void> _onExecuteContextualAction(
    ExecuteContextualAction event,
    Emitter<ContextualCaseState> emit,
  ) async {
    AppLogger.info('Executing contextual action ${event.actionId} for case ${event.caseId}');
    emit(ContextualCaseLoading());

    try {
      emit(ContextualActionExecuted(
        caseId: event.caseId,
        actionId: event.actionId,
        message: 'Ação executada com sucesso',
        result: {'status': 'success'},
      ));
      AppLogger.success('Action ${event.actionId} executed for case ${event.caseId}');
    } catch (e, stackTrace) {
      AppLogger.error('Error executing action: $e', error: e, stackTrace: stackTrace);
      emit(ContextualCaseError(message: 'Erro ao executar ação: $e'));
    }
  }
} 