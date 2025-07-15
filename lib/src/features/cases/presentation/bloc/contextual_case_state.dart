part of 'contextual_case_bloc.dart';

abstract class ContextualCaseState extends Equatable {
  const ContextualCaseState();

  @override
  List<Object> get props => [];
}

/// Estado inicial do BLoC contextual
class ContextualCaseInitial extends ContextualCaseState {}

/// Estado de carregamento
class ContextualCaseLoading extends ContextualCaseState {}

/// Estado de dados contextuais carregados
class ContextualCaseDataLoaded extends ContextualCaseState {
  final ContextualCaseData contextualData;
  final List<ContextualKPI> kpis;
  final ContextualActions actions;
  final ContextualHighlight highlight;

  const ContextualCaseDataLoaded({
    required this.contextualData,
    required this.kpis,
    required this.actions,
    required this.highlight,
  });

  @override
  List<Object> get props => [contextualData, kpis, actions, highlight];
}

/// Estado de KPIs contextuais carregados
class ContextualKPIsLoaded extends ContextualCaseState {
  final String caseId;
  final List<ContextualKPI> kpis;

  const ContextualKPIsLoaded({
    required this.caseId,
    required this.kpis,
  });

  @override
  List<Object> get props => [caseId, kpis];
}

/// Estado de ações contextuais carregadas
class ContextualActionsLoaded extends ContextualCaseState {
  final String caseId;
  final ContextualActions actions;

  const ContextualActionsLoaded({
    required this.caseId,
    required this.actions,
  });

  @override
  List<Object> get props => [caseId, actions];
}

/// Estado de casos agrupados por alocação
class CasesByAllocationLoaded extends ContextualCaseState {
  final Map<AllocationType, List<Case>> casesByAllocation;

  const CasesByAllocationLoaded({
    required this.casesByAllocation,
  });

  @override
  List<Object> get props => [casesByAllocation];
}

/// Estado de tipo de alocação definido
class AllocationTypeSet extends ContextualCaseState {
  final String caseId;
  final AllocationType allocationType;
  final String message;

  const AllocationTypeSet({
    required this.caseId,
    required this.allocationType,
    required this.message,
  });

  @override
  List<Object> get props => [caseId, allocationType, message];
}

/// Estado de ação contextual executada
class ContextualActionExecuted extends ContextualCaseState {
  final String caseId;
  final String actionId;
  final String message;
  final Map<String, dynamic>? result;

  const ContextualActionExecuted({
    required this.caseId,
    required this.actionId,
    required this.message,
    this.result,
  });

  @override
  List<Object> get props => [caseId, actionId, message, result ?? {}];
}

/// Estado de erro
class ContextualCaseError extends ContextualCaseState {
  final String message;
  final String? errorCode;

  const ContextualCaseError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object> get props => [message, errorCode ?? ''];
} 