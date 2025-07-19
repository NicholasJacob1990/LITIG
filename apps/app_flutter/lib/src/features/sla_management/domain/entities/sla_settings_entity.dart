import 'package:equatable/equatable.dart';
import '../value_objects/sla_timeframe.dart';

/// Entidade principal de configurações SLA
/// 
/// Representa as configurações de Service Level Agreement (SLA) de uma firma,
/// incluindo timeframes, regras de negócio, e configurações avançadas
class SlaSettingsEntity extends Equatable {
  const SlaSettingsEntity({
    required this.id,
    required this.firmId,
    required this.normalTimeframe,
    required this.urgentTimeframe,
    required this.emergencyTimeframe,
    required this.complexTimeframe,
    required this.enableBusinessHoursOnly,
    required this.includeWeekends,
    required this.allowOverrides,
    required this.enableAutoEscalation,
    required this.overrideSettings,
    required this.lastModified,
    required this.lastModifiedBy,
    this.businessHours,
    this.escalationRules,
    this.notificationSettings,
    this.holidays,
    this.customRules,
    this.metadata,
  });

  /// ID único das configurações
  final String id;

  /// ID da firma
  final String firmId;

  /// Timeframe para casos normais
  final SlaTimeframe normalTimeframe;

  /// Timeframe para casos urgentes
  final SlaTimeframe urgentTimeframe;

  /// Timeframe para casos de emergência
  final SlaTimeframe emergencyTimeframe;

  /// Timeframe para casos complexos
  final SlaTimeframe complexTimeframe;

  /// Se deve considerar apenas horário comercial
  final bool enableBusinessHoursOnly;

  /// Se inclui finais de semana no cálculo
  final bool includeWeekends;

  /// Se permite overrides
  final bool allowOverrides;

  /// Se escalação automática está habilitada
  final bool enableAutoEscalation;

  /// Configurações de override
  final Map<String, dynamic> overrideSettings;

  /// Data da última modificação
  final DateTime lastModified;

  /// Usuário que fez a última modificação
  final String lastModifiedBy;

  /// Horários comerciais
  final Map<String, dynamic>? businessHours;

  /// Regras de escalação
  final Map<String, dynamic>? escalationRules;

  /// Configurações de notificação
  final Map<String, dynamic>? notificationSettings;

  /// Lista de feriados
  final List<Map<String, dynamic>>? holidays;

  /// Regras customizadas
  final Map<String, dynamic>? customRules;

  /// Metadados adicionais
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        firmId,
        normalTimeframe,
        urgentTimeframe,
        emergencyTimeframe,
        complexTimeframe,
        enableBusinessHoursOnly,
        includeWeekends,
        allowOverrides,
        enableAutoEscalation,
        overrideSettings,
        lastModified,
        lastModifiedBy,
        businessHours,
        escalationRules,
        notificationSettings,
        holidays,
        customRules,
        metadata,
      ];

  /// Cria configurações padrão para uma firma
  factory SlaSettingsEntity.createDefault({
    required String firmId,
    required String createdBy,
  }) {
    final now = DateTime.now();
    return SlaSettingsEntity(
      id: 'sla_${firmId}_${now.millisecondsSinceEpoch}',
      firmId: firmId,
      normalTimeframe: SlaTimeframe.normal,
      urgentTimeframe: SlaTimeframe.urgent,
      emergencyTimeframe: SlaTimeframe.emergency,
      complexTimeframe: SlaTimeframe.complex,
      enableBusinessHoursOnly: true,
      includeWeekends: false,
      allowOverrides: true,
      enableAutoEscalation: true,
      overrideSettings: const {
        'maxPerMonth': 5,
        'requireApproval': true,
        'auditTrail': true,
        'limitByRole': true,
      },
      lastModified: now,
      lastModifiedBy: createdBy,
      businessHours: const {
        'monday': const {'start': '09:00', 'end': '18:00'},
        'tuesday': const {'start': '09:00', 'end': '18:00'},
        'wednesday': const {'start': '09:00', 'end': '18:00'},
        'thursday': const {'start': '09:00', 'end': '18:00'},
        'friday': const {'start': '09:00', 'end': '18:00'},
        'saturday': const {'start': '09:00', 'end': '13:00'},
        'sunday': const {'start': null, 'end': null},
      },
      escalationRules: const {
        'enabled': true,
        'levels': const [
          {'minutes': 30, 'target': 'supervisor'},
          {'minutes': 120, 'target': 'partner'},
          {'minutes': 240, 'target': 'admin'},
        ],
      },
      notificationSettings: const {
        'enabled': true,
        'channels': const ['email', 'push'],
        'timing': const {
          'beforeDeadline': const [60, 30, 15], // minutos antes
          'atDeadline': true,
          'afterViolation': const [15, 60, 240], // minutos depois
        },
      },
      holidays: const [],
      customRules: const {},
      metadata: {
        'version': '1.0',
        'createdAt': now.toIso8601String(),
        'source': 'default_template',
      },
    );
  }

  /// Cria uma cópia com alterações
  SlaSettingsEntity copyWith({
    String? id,
    String? firmId,
    SlaTimeframe? normalTimeframe,
    SlaTimeframe? urgentTimeframe,
    SlaTimeframe? emergencyTimeframe,
    SlaTimeframe? complexTimeframe,
    bool? enableBusinessHoursOnly,
    bool? includeWeekends,
    bool? allowOverrides,
    bool? enableAutoEscalation,
    Map<String, dynamic>? overrideSettings,
    DateTime? lastModified,
    String? lastModifiedBy,
    Map<String, dynamic>? businessHours,
    Map<String, dynamic>? escalationRules,
    Map<String, dynamic>? notificationSettings,
    List<Map<String, dynamic>>? holidays,
    Map<String, dynamic>? customRules,
    Map<String, dynamic>? metadata,
  }) {
    return SlaSettingsEntity(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      normalTimeframe: normalTimeframe ?? this.normalTimeframe,
      urgentTimeframe: urgentTimeframe ?? this.urgentTimeframe,
      emergencyTimeframe: emergencyTimeframe ?? this.emergencyTimeframe,
      complexTimeframe: complexTimeframe ?? this.complexTimeframe,
      enableBusinessHoursOnly: enableBusinessHoursOnly ?? this.enableBusinessHoursOnly,
      includeWeekends: includeWeekends ?? this.includeWeekends,
      allowOverrides: allowOverrides ?? this.allowOverrides,
      enableAutoEscalation: enableAutoEscalation ?? this.enableAutoEscalation,
      overrideSettings: overrideSettings ?? this.overrideSettings,
      lastModified: lastModified ?? this.lastModified,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      businessHours: businessHours ?? this.businessHours,
      escalationRules: escalationRules ?? this.escalationRules,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      holidays: holidays ?? this.holidays,
      customRules: customRules ?? this.customRules,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Valida se as configurações são válidas
  bool get isValid {
    return id.isNotEmpty &&
           firmId.isNotEmpty &&
           normalTimeframe.hours > 0 &&
           urgentTimeframe.hours > 0 &&
           emergencyTimeframe.hours > 0 &&
           complexTimeframe.hours > 0 &&
           lastModifiedBy.isNotEmpty;
  }

  /// Verifica se está usando configurações padrão
  bool get isDefaultConfiguration {
    return normalTimeframe.hours == 48 &&
           urgentTimeframe.hours == 24 &&
           emergencyTimeframe.hours == 6 &&
           complexTimeframe.hours == 72;
  }

  /// Obtém o timeframe baseado no tipo de caso
  SlaTimeframe getTimeframeForCaseType(String caseType) {
    switch (caseType.toLowerCase()) {
      case 'urgent':
        return urgentTimeframe;
      case 'emergency':
        return emergencyTimeframe;
      case 'complex':
        return complexTimeframe;
      default:
        return normalTimeframe;
    }
  }

  /// Calcula o deadline para um caso
  DateTime calculateDeadline({
    required DateTime createdAt,
    required String caseType,
    String? priority,
  }) {
    final timeframe = getTimeframeForCaseType(caseType);
    var deadline = createdAt.add(Duration(hours: timeframe.hours));

    // Ajusta para horário comercial se necessário
    if (enableBusinessHoursOnly) {
      deadline = _adjustForBusinessHours(deadline);
    }

    // Remove finais de semana se necessário
    if (!includeWeekends) {
      deadline = _adjustForWeekends(deadline);
    }

    return deadline;
  }

  /// Ajusta deadline para horário comercial
  DateTime _adjustForBusinessHours(DateTime deadline) {
    // Implementação simplificada - seria mais complexa na prática
    final weekday = deadline.weekday;
    
    if (weekday == 6) { // Sábado
      if (deadline.hour > 13) {
        return DateTime(deadline.year, deadline.month, deadline.day + 2, 9);
      }
    } else if (weekday == 7) { // Domingo
      return DateTime(deadline.year, deadline.month, deadline.day + 1, 9);
    } else { // Dias úteis
      if (deadline.hour < 9) {
        return DateTime(deadline.year, deadline.month, deadline.day, 9);
      } else if (deadline.hour > 18) {
        return DateTime(deadline.year, deadline.month, deadline.day + 1, 9);
      }
    }

    return deadline;
  }

  /// Ajusta deadline removendo finais de semana
  DateTime _adjustForWeekends(DateTime deadline) {
    while (deadline.weekday == 6 || deadline.weekday == 7) {
      deadline = deadline.add(const Duration(days: 1));
    }
    return deadline;
  }

  @override
  String toString() {
    return 'SlaSettingsEntity('
        'id: $id, '
        'firmId: $firmId, '
        'normal: ${normalTimeframe.hours}h, '
        'urgent: ${urgentTimeframe.hours}h, '
        'emergency: ${emergencyTimeframe.hours}h, '
        'complex: ${complexTimeframe.hours}h, '
        'businessHours: $enableBusinessHoursOnly, '
        'weekends: $includeWeekends, '
        'overrides: $allowOverrides, '
        'escalation: $enableAutoEscalation'
        ')';
  }
} 
 