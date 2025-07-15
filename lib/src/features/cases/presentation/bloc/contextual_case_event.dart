part of 'contextual_case_bloc.dart';

abstract class ContextualCaseEvent extends Equatable {
  const ContextualCaseEvent();

  @override
  List<Object> get props => [];
}

/// Evento para buscar dados contextuais de um caso específico
class FetchContextualCaseData extends ContextualCaseEvent {
  final String caseId;
  final String userId;

  const FetchContextualCaseData({
    required this.caseId,
    required this.userId,
  });

  @override
  List<Object> get props => [caseId, userId];
}

/// Evento para buscar KPIs contextuais de um caso
class FetchContextualKPIs extends ContextualCaseEvent {
  final String caseId;
  final String userId;

  const FetchContextualKPIs({
    required this.caseId,
    required this.userId,
  });

  @override
  List<Object> get props => [caseId, userId];
}

/// Evento para buscar ações contextuais de um caso
class FetchContextualActions extends ContextualCaseEvent {
  final String caseId;
  final String userId;

  const FetchContextualActions({
    required this.caseId,
    required this.userId,
  });

  @override
  List<Object> get props => [caseId, userId];
}

/// Evento para definir tipo de alocação de um caso
class SetAllocationTypeEvent extends ContextualCaseEvent {
  final String caseId;
  final AllocationType allocationType;
  final Map<String, dynamic>? metadata;

  const SetAllocationTypeEvent({
    required this.caseId,
    required this.allocationType,
    this.metadata,
  });

  @override
  List<Object> get props => [caseId, allocationType, metadata ?? {}];
}

/// Evento para buscar casos agrupados por tipo de alocação
class FetchCasesByAllocation extends ContextualCaseEvent {
  final String userId;

  const FetchCasesByAllocation({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// Evento para executar ação contextual
class ExecuteContextualAction extends ContextualCaseEvent {
  final String caseId;
  final String actionId;
  final Map<String, dynamic>? parameters;

  const ExecuteContextualAction({
    required this.caseId,
    required this.actionId,
    this.parameters,
  });

  @override
  List<Object> get props => [caseId, actionId, parameters ?? {}];
} 