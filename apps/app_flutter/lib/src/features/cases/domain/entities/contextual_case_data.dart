import 'package:equatable/equatable.dart';
import 'allocation_type.dart';

/// Dados contextuais específicos por tipo de alocação
class ContextualCaseData extends Equatable {
  const ContextualCaseData({
    required this.allocationType,
    this.matchScore,
    this.responseDeadline,
    this.partnerId,
    this.delegatedBy,
    this.contextMetadata = const {},
    this.partnerName,
    this.partnerSpecialization,
    this.partnerRating,
    this.yourShare,
    this.partnerShare,
    this.collaborationArea,
    this.responseTimeLeft,
    this.distance,
    this.estimatedValue,
    this.initiatorName,
    this.slaHours,
    this.conversionRate,
    this.complexityScore,
    this.hoursBudgeted,
    this.hourlyRate,
    this.delegatedByName,
    this.deadlineDays,
    this.aiSuccessRate,
    this.aiReason,
  });

  final AllocationType allocationType;
  final double? matchScore;
  final DateTime? responseDeadline;
  final String? partnerId;
  final String? delegatedBy;
  final Map<String, dynamic> contextMetadata;
  
  // Dados específicos por contexto
  final String? partnerName;
  final String? partnerSpecialization;
  final double? partnerRating;
  final int? yourShare;
  final int? partnerShare;
  final String? collaborationArea;
  final String? responseTimeLeft;
  final double? distance;
  final double? estimatedValue;
  final String? initiatorName;
  final int? slaHours;
  final double? conversionRate;
  final int? complexityScore;
  final int? hoursBudgeted;
  final double? hourlyRate;
  final String? delegatedByName;
  final int? deadlineDays;
  final double? aiSuccessRate;
  final String? aiReason;

  @override
  List<Object?> get props => [
    allocationType,
    matchScore,
    responseDeadline,
    partnerId,
    delegatedBy,
    contextMetadata,
    partnerName,
    partnerSpecialization,
    partnerRating,
    yourShare,
    partnerShare,
    collaborationArea,
    responseTimeLeft,
    distance,
    estimatedValue,
    initiatorName,
    slaHours,
    conversionRate,
    complexityScore,
    hoursBudgeted,
    hourlyRate,
    delegatedByName,
    deadlineDays,
    aiSuccessRate,
    aiReason,
  ];

  ContextualCaseData copyWith({
    AllocationType? allocationType,
    double? matchScore,
    DateTime? responseDeadline,
    String? partnerId,
    String? delegatedBy,
    Map<String, dynamic>? contextMetadata,
    String? partnerName,
    String? partnerSpecialization,
    double? partnerRating,
    int? yourShare,
    int? partnerShare,
    String? collaborationArea,
    String? responseTimeLeft,
    double? distance,
    double? estimatedValue,
    String? initiatorName,
    int? slaHours,
    double? conversionRate,
    int? complexityScore,
    int? hoursBudgeted,
    double? hourlyRate,
    String? delegatedByName,
    int? deadlineDays,
    double? aiSuccessRate,
    String? aiReason,
  }) {
    return ContextualCaseData(
      allocationType: allocationType ?? this.allocationType,
      matchScore: matchScore ?? this.matchScore,
      responseDeadline: responseDeadline ?? this.responseDeadline,
      partnerId: partnerId ?? this.partnerId,
      delegatedBy: delegatedBy ?? this.delegatedBy,
      contextMetadata: contextMetadata ?? this.contextMetadata,
      partnerName: partnerName ?? this.partnerName,
      partnerSpecialization: partnerSpecialization ?? this.partnerSpecialization,
      partnerRating: partnerRating ?? this.partnerRating,
      yourShare: yourShare ?? this.yourShare,
      partnerShare: partnerShare ?? this.partnerShare,
      collaborationArea: collaborationArea ?? this.collaborationArea,
      responseTimeLeft: responseTimeLeft ?? this.responseTimeLeft,
      distance: distance ?? this.distance,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      initiatorName: initiatorName ?? this.initiatorName,
      slaHours: slaHours ?? this.slaHours,
      conversionRate: conversionRate ?? this.conversionRate,
      complexityScore: complexityScore ?? this.complexityScore,
      hoursBudgeted: hoursBudgeted ?? this.hoursBudgeted,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      delegatedByName: delegatedByName ?? this.delegatedByName,
      deadlineDays: deadlineDays ?? this.deadlineDays,
      aiSuccessRate: aiSuccessRate ?? this.aiSuccessRate,
      aiReason: aiReason ?? this.aiReason,
    );
  }
}

/// KPI específico para contexto
class ContextualKPI extends Equatable {
  const ContextualKPI({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  List<Object?> get props => [icon, label, value];

  factory ContextualKPI.fromMap(Map<String, dynamic> map) {
    return ContextualKPI(
      icon: map['icon'] ?? '',
      label: map['label'] ?? '',
      value: map['value'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'icon': icon,
      'label': label,
      'value': value,
    };
  }
}

/// Ação contextual disponível
class ContextualAction extends Equatable {
  const ContextualAction({
    required this.label,
    required this.action,
  });

  final String label;
  final String action;

  @override
  List<Object?> get props => [label, action];

  factory ContextualAction.fromMap(Map<String, dynamic> map) {
    return ContextualAction(
      label: map['label'] ?? '',
      action: map['action'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'action': action,
    };
  }
}

/// Conjunto de ações contextuais
class ContextualActions extends Equatable {
  const ContextualActions({
    required this.primaryAction,
    required this.secondaryActions,
  });

  final ContextualAction primaryAction;
  final List<ContextualAction> secondaryActions;

  @override
  List<Object?> get props => [primaryAction, secondaryActions];

  factory ContextualActions.fromMap(Map<String, dynamic> map) {
    return ContextualActions(
      primaryAction: ContextualAction.fromMap(map['primary_action'] ?? {}),
      secondaryActions: (map['secondary_actions'] as List<dynamic>?)
          ?.map((action) => ContextualAction.fromMap(action))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primary_action': primaryAction.toMap(),
      'secondary_actions': secondaryActions.map((action) => action.toMap()).toList(),
    };
  }
}

/// Destaque contextual
class ContextualHighlight extends Equatable {
  const ContextualHighlight({
    required this.text,
    required this.color,
  });

  final String text;
  final String color;

  @override
  List<Object?> get props => [text, color];

  factory ContextualHighlight.fromMap(Map<String, dynamic> map) {
    return ContextualHighlight(
      text: map['text'] ?? '',
      color: map['color'] ?? 'gray',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'color': color,
    };
  }
} 