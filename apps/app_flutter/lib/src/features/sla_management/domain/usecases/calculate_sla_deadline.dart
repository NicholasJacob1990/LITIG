import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sla_settings_entity.dart';
import '../entities/sla_preset_entity.dart';
import '../value_objects/sla_timeframe.dart';
import '../repositories/sla_settings_repository.dart';
// import '../value_objects/business_hours.dart' as bh; // Usando BusinessHours de sla_timeframe.dart

/// Use case para cálculo de deadline SLA
/// 
/// Responsável por calcular prazos considerando todas as regras
/// de negócio: prioridade, horários comerciais, feriados, overrides
class CalculateSlaDeadlineUseCase {
  final SlaSettingsRepository repository;

  const CalculateSlaDeadlineUseCase(this.repository);

  /// Calcula deadline SLA para um caso específico
  Future<Either<Failure, DeadlineResult>> calculate({
    required String firmId,
    required DateTime startTime,
    required String priority,
    String? caseType,
    Map<String, dynamic>? overrides,
    bool includeBusinessRules = true,
  }) async {
    try {
      // Buscar configurações SLA do escritório
      final settingsResult = await repository.getSettings(firmId: firmId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) async {
          // Aplicar regras de negócio se solicitado
          final effectiveSettings = includeBusinessRules 
            ? _applyBusinessRules(settings, overrides)
            : settings;

          // Calcular deadline baseado nas configurações
          final deadline = _calculateDeadlineInternal(
            startTime: startTime,
            priority: priority,
            caseType: caseType,
            settings: effectiveSettings,
          );

          return Right(DeadlineResult(
            deadline: deadline,
            settings: effectiveSettings,
            calculationDate: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      return Left(Failure(
        message: 'Erro ao calcular deadline SLA: ${e.toString()}',
        errorCode: 'CALCULATION_ERROR',
      ));
    }
  }

  /// Calcula deadlines para múltiplos casos
  Future<Either<Failure, List<DeadlineResult>>> calculateMultiple({
    required String firmId,
    required List<Map<String, dynamic>> cases,
    bool includeBusinessRules = true,
  }) async {
    try {
      // Buscar configurações SLA do escritório
      final settingsResult = await repository.getSettings(firmId: firmId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) async {
          final results = <DeadlineResult>[];
          
          for (final caseParams in cases) {
            final effectiveSettings = includeBusinessRules 
              ? _applyBusinessRules(settings, caseParams['overrides'])
              : settings;

            final deadline = _calculateDeadlineInternal(
              startTime: caseParams['startTime'] as DateTime,
              priority: caseParams['priority'] as String,
              caseType: caseParams['caseType'] as String?,
              settings: effectiveSettings,
            );

            results.add(DeadlineResult(
              deadline: deadline,
              settings: effectiveSettings,
              calculationDate: DateTime.now(),
            ));
          }

          return Right(results);
        },
      );
    } catch (e) {
      return Left(Failure(
        message: 'Erro ao calcular deadlines múltiplos: ${e.toString()}',
        errorCode: 'MULTIPLE_CALCULATION_ERROR',
      ));
    }
  }

  /// Calcula deadline com override de configurações
  Future<Either<Failure, DeadlineResult>> calculateWithOverride({
    required String firmId,
    required DateTime startTime,
    required String priority,
    String? caseType,
    required Map<String, dynamic> overrides,
  }) async {
    try {
      // Buscar configurações SLA do escritório
      final settingsResult = await repository.getSettings(firmId: firmId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) async {
          // Aplicar overrides às configurações
          final overriddenSettings = _applyOverrides(settings, overrides);

          // Calcular deadline com configurações modificadas
          final deadline = _calculateDeadlineInternal(
            startTime: startTime,
            priority: priority,
            caseType: caseType,
            settings: overriddenSettings,
          );

          return Right(DeadlineResult(
            deadline: deadline,
            settings: overriddenSettings,
            calculationDate: DateTime.now(),
            overridesApplied: overrides,
          ));
        },
      );
    } catch (e) {
      return Left(Failure(
        message: 'Erro ao calcular deadline com override: ${e.toString()}',
        errorCode: 'OVERRIDE_CALCULATION_ERROR',
      ));
    }
  }

  /// Calcula deadline considerando complexidade do caso
  Future<Either<Failure, DeadlineResult>> calculateForComplexCase({
    required String firmId,
    required DateTime startTime,
    required String priority,
    required String complexityLevel, // low, medium, high, very_high
    Map<String, dynamic>? additionalFactors,
  }) async {
    try {
      final settingsResult = await repository.getSettings();
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          final settingsEntity = _convertPresetToSettings(settings);
          var timeframe = _getTimeframeForPriority(settingsEntity, priority);
          
          // Aplica fator de complexidade
          final complexityMultiplier = _getComplexityMultiplier(complexityLevel);
          final adjustedHours = (timeframe.hours * complexityMultiplier).round();
          
          timeframe = timeframe.copyWith(
            hours: adjustedHours,
            description: '${timeframe.description} (ajustado para complexidade $complexityLevel)',
          );
          
          return Right(_calculateWithTimeframe(
            timeframe: timeframe,
            settings: settingsEntity,
            startTime: startTime,
            metadata: {
              'complexity_level': complexityLevel,
              'complexity_multiplier': complexityMultiplier,
              'original_hours': timeframe.hours,
              'adjusted_hours': adjustedHours,
              'additional_factors': additionalFactors,
            },
          ));
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao calcular deadline para caso complexo: ${e.toString()}'));
    }
  }

  /// Converte SlaPresetEntity para SlaSettingsEntity
  SlaSettingsEntity _convertPresetToSettings(SlaPresetEntity preset) {
    return SlaSettingsEntity(
      id: preset.id,
      firmId: preset.firmId ?? '',
      normalTimeframe: SlaTimeframe.normal.copyWith(hours: preset.defaultSlaHours),
      urgentTimeframe: SlaTimeframe.urgent.copyWith(hours: preset.urgentSlaHours),
      emergencyTimeframe: SlaTimeframe.emergency.copyWith(hours: preset.emergencySlaHours),
      complexTimeframe: SlaTimeframe.complex.copyWith(hours: preset.complexCaseSlaHours),
      enableBusinessHoursOnly: true, // preset não tem essa propriedade, usando padrão
      includeWeekends: preset.includeWeekends,
      allowOverrides: true, // usando padrão
      enableAutoEscalation: preset.escalationRules.isNotEmpty,
      overrideSettings: preset.overrideSettings,
      lastModified: preset.updatedAt,
      lastModifiedBy: preset.createdBy ?? 'system',
      businessHours: {
        'start': preset.businessHoursStart,
        'end': preset.businessHoursEnd,
      },
      escalationRules: preset.escalationRules,
      notificationSettings: {
        'timings': preset.notificationTimings,
      },
      holidays: [], // preset não tem essa propriedade
      customRules: {}, // preset não tem essa propriedade
      metadata: preset.metadata,
      businessHoursStart: preset.businessHoursStart,
      businessHoursEnd: preset.businessHoursEnd,
      urgentSlaHours: preset.urgentSlaHours,
      emergencySlaHours: preset.emergencySlaHours,
      complexCaseSlaHours: preset.complexCaseSlaHours,
      defaultSlaHours: preset.defaultSlaHours,
    );
  }

  /// Verifica se um deadline está em risco de violação
  Future<Either<Failure, RiskAssessment>> assessDeadlineRisk({
    required String firmId,
    required DateTime startTime,
    required DateTime currentTime,
    required String priority,
    String? caseType,
  }) async {
    try {
      final deadlineResult = await calculate(
        firmId: firmId,
        startTime: startTime,
        priority: priority,
        caseType: caseType,
      );
      
      return deadlineResult.fold(
        (failure) => Left(failure),
        (result) {
          final timeToDeadline = result.deadline.difference(currentTime);
          final totalTime = result.deadline.difference(startTime);
          
          return Right(_assessRisk(
            timeToDeadline: timeToDeadline,
            totalTime: totalTime,
            priority: priority,
            result: result,
          ));
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao avaliar risco de deadline: ${e.toString()}'));
    }
  }

  DeadlineResult _calculateDeadlineInternal({
    required SlaSettingsEntity settings,
    required DateTime startTime,
    required String priority,
    String? caseType,
    Map<String, dynamic>? overrides,
    bool includeBusinessRules = true,
  }) {
    final timeframe = _getTimeframeForPriority(settings, priority);
    
    return _calculateWithTimeframe(
      timeframe: timeframe,
      settings: settings,
      startTime: startTime,
      includeBusinessRules: includeBusinessRules,
      overrides: overrides,
    );
  }

  DeadlineResult _calculateWithTimeframe({
    required SlaTimeframe timeframe,
    required SlaSettingsEntity settings,
    required DateTime startTime,
    bool includeBusinessRules = true,
    bool isOverridden = false,
    String? overrideJustification,
    Map<String, dynamic>? overrides,
    Map<String, dynamic>? metadata,
  }) {
    // Calcula deadline base
    DateTime deadline;
    
    if (includeBusinessRules && timeframe.isBusinessHoursOnly) {
      final businessHours = BusinessHours(
        startHour: int.parse(settings.businessHoursStart.split(':')[0]),
        endHour: int.parse(settings.businessHoursEnd.split(':')[0]),
        workDays: settings.includeWeekends ? [1, 2, 3, 4, 5, 6, 7] : [1, 2, 3, 4, 5],
      );
      
      deadline = timeframe.calculateDeadline(
        startTime: startTime,
        businessHours: businessHours,
        holidays: _getHolidays(settings),
      );
    } else {
      deadline = timeframe.calculateDeadline(startTime: startTime);
    }
    
    // Calcula marcos intermediários
    final milestones = _calculateMilestones(startTime, deadline, timeframe);
    
    // Determina próxima notificação
    final nextNotification = _getNextNotification(deadline, timeframe);
    
    return DeadlineResult(
      deadline: deadline,
      timeframe: timeframe,
      milestones: milestones,
      nextNotification: nextNotification,
      isOverridden: isOverridden,
      overrideJustification: overrideJustification,
      calculatedAt: DateTime.now(),
      metadata: {
        'start_time': startTime.toIso8601String(),
        'business_hours_applied': includeBusinessRules && timeframe.isBusinessHoursOnly,
        'weekends_included': timeframe.includeWeekends,
        ...?overrides,
        ...?metadata,
      },
    );
  }

  SlaTimeframe _getTimeframeForPriority(SlaSettingsEntity settings, String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return SlaTimeframe.urgent.copyWith(hours: settings.urgentSlaHours);
      case 'emergency':
        return SlaTimeframe.emergency.copyWith(hours: settings.emergencySlaHours);
      case 'complex':
        return SlaTimeframe.complex.copyWith(hours: settings.complexCaseSlaHours ?? 72);
      default:
        return SlaTimeframe.normal.copyWith(hours: settings.defaultSlaHours);
    }
  }

  double _getComplexityMultiplier(String complexityLevel) {
    switch (complexityLevel.toLowerCase()) {
      case 'low':
        return 1.0;
      case 'medium':
        return 1.3;
      case 'high':
        return 1.6;
      case 'very_high':
        return 2.0;
      default:
        return 1.0;
    }
  }

  List<DateTime> _getHolidays(SlaSettingsEntity settings) {
    // Em implementação real, obteria de um serviço de feriados
    // Por ora, retorna lista vazia
    return [];
  }

  List<DeadlineMilestone> _calculateMilestones(
    DateTime startTime,
    DateTime deadline,
    SlaTimeframe timeframe,
  ) {
    final totalDuration = deadline.difference(startTime);
    final milestones = <DeadlineMilestone>[];
    
    // Marco de 25% do tempo
    milestones.add(DeadlineMilestone(
      name: 'Primeira revisão',
      deadline: startTime.add(Duration(milliseconds: (totalDuration.inMilliseconds * 0.25).round())),
      description: '25% do prazo utilizado',
      isWarning: false,
    ));
    
    // Marco de 50% do tempo
    milestones.add(DeadlineMilestone(
      name: 'Revisão intermediária',
      deadline: startTime.add(Duration(milliseconds: (totalDuration.inMilliseconds * 0.5).round())),
      description: '50% do prazo utilizado',
      isWarning: false,
    ));
    
    // Marco de 75% do tempo (aviso)
    milestones.add(DeadlineMilestone(
      name: 'Aviso de prazo',
      deadline: startTime.add(Duration(milliseconds: (totalDuration.inMilliseconds * 0.75).round())),
      description: 'Atenção: 75% do prazo utilizado',
      isWarning: true,
    ));
    
    // Marco de 90% do tempo (crítico)
    milestones.add(DeadlineMilestone(
      name: 'Prazo crítico',
      deadline: startTime.add(Duration(milliseconds: (totalDuration.inMilliseconds * 0.9).round())),
      description: 'CRÍTICO: 90% do prazo utilizado',
      isWarning: true,
    ));
    
    return milestones;
  }

  DateTime? _getNextNotification(DateTime deadline, SlaTimeframe timeframe) {
    final now = DateTime.now();
    
    // Notificação 24h antes
    final notification24h = deadline.subtract(const Duration(hours: 24));
    if (notification24h.isAfter(now)) return notification24h;
    
    // Notificação 6h antes
    final notification6h = deadline.subtract(const Duration(hours: 6));
    if (notification6h.isAfter(now)) return notification6h;
    
    // Notificação 1h antes
    final notification1h = deadline.subtract(const Duration(hours: 1));
    if (notification1h.isAfter(now)) return notification1h;
    
    // No deadline
    if (deadline.isAfter(now)) return deadline;
    
    return null; // Prazo já vencido
  }

  RiskAssessment _assessRisk({
    required Duration timeToDeadline,
    required Duration totalTime,
    required String priority,
    required DeadlineResult result,
  }) {
    final progressPercentage = 1 - (timeToDeadline.inMilliseconds / totalTime.inMilliseconds);
    
    DeadlineRisk risk;
    String message;
    List<String> recommendations = [];
    
    if (timeToDeadline.isNegative) {
      risk = DeadlineRisk.violated;
      message = 'Prazo violado';
      recommendations.addAll([
        'Notificar cliente imediatamente',
        'Documentar motivo do atraso',
        'Implementar ações corretivas',
        'Considerar escalação',
      ]);
    } else if (progressPercentage >= 0.9) {
      risk = DeadlineRisk.critical;
      message = 'Risco crítico - 90% do prazo utilizado';
      recommendations.addAll([
        'Priorizar caso imediatamente',
        'Alocar recursos adicionais',
        'Considerar override se necessário',
        'Preparar comunicação proativa',
      ]);
    } else if (progressPercentage >= 0.75) {
      risk = DeadlineRisk.high;
      message = 'Risco alto - 75% do prazo utilizado';
      recommendations.addAll([
        'Revisar progresso do caso',
        'Acelerar atividades pendentes',
        'Verificar disponibilidade de recursos',
      ]);
    } else if (progressPercentage >= 0.5) {
      risk = DeadlineRisk.medium;
      message = 'Risco médio - 50% do prazo utilizado';
      recommendations.addAll([
        'Monitorar progresso regularmente',
        'Planejar atividades restantes',
      ]);
    } else {
      risk = DeadlineRisk.low;
      message = 'Risco baixo - dentro do prazo';
      recommendations.add('Manter ritmo atual de trabalho');
    }
    
    return RiskAssessment(
      risk: risk,
      message: message,
      progressPercentage: progressPercentage,
      timeRemaining: timeToDeadline,
      recommendations: recommendations,
      calculatedAt: DateTime.now(),
    );
  }

  /// Aplica regras de negócio às configurações SLA
  SlaSettingsEntity _applyBusinessRules(
    SlaSettingsEntity settings,
    Map<String, dynamic>? overrides,
  ) {
    if (overrides == null || overrides.isEmpty) {
      return settings;
    }

    // Aplicar overrides específicos
    return settings.copyWith(
      businessHours: overrides['businessHours'] ?? settings.businessHours,
      timeframes: overrides['timeframes'] ?? settings.timeframes,
      escalationSettings: overrides['escalationSettings'] ?? settings.escalationSettings,
    );
  }

  /// Aplica overrides às configurações
  SlaSettingsEntity _applyOverrides(
    SlaSettingsEntity settings,
    Map<String, dynamic> overrides,
  ) {
    return settings.copyWith(
      businessHours: overrides['businessHours'] ?? settings.businessHours,
      timeframes: overrides['timeframes'] ?? settings.timeframes,
      escalationSettings: overrides['escalationSettings'] ?? settings.escalationSettings,
      notificationSettings: overrides['notificationSettings'] ?? settings.notificationSettings,
    );
  }

  /// Ajusta o deadline para horário comercial
  DateTime _adjustToBusinessHours(
    DateTime deadline,
    dynamic businessHours,
  ) {
    // Implementação simplificada - ajustar para próximo horário comercial
    final now = DateTime.now();
    final businessStart = DateTime(
      now.year,
      now.month,
      now.day,
      9, // 9:00 AM
      0,
    );
    
    final businessEnd = DateTime(
      now.year,
      now.month,
      now.day,
      18, // 6:00 PM
      0,
    );
    
    if (deadline.isBefore(businessStart)) {
      return businessStart;
    } else if (deadline.isAfter(businessEnd)) {
      return businessEnd;
    }
    
    return deadline;
  }
}

/// Resultado do cálculo de deadline
class DeadlineResult {
  final DateTime deadline;
  final SlaSettingsEntity? settings;
  final DateTime calculationDate;
  final Map<String, dynamic>? overridesApplied;

  const DeadlineResult({
    required this.deadline,
    this.settings,
    required this.calculationDate,
    this.overridesApplied,
  });

  /// Tempo restante até o deadline
  Duration get timeRemaining => deadline.difference(DateTime.now());

  /// Se o deadline já foi violado
  bool get isViolated => DateTime.now().isAfter(deadline);

  /// Se está próximo do deadline (menos de 24h)
  bool get isNearDeadline => timeRemaining.inHours < 24;

  /// Se está em risco (menos de 2h)
  bool get isAtRisk => timeRemaining.inHours < 2;
}

/// Marco de deadline
class DeadlineMilestone {
  final String name;
  final DateTime deadline;
  final String description;
  final bool isWarning;

  const DeadlineMilestone({
    required this.name,
    required this.deadline,
    required this.description,
    this.isWarning = false,
  });
}

/// Avaliação de risco
class RiskAssessment {
  final DeadlineRisk risk;
  final String message;
  final double progressPercentage;
  final Duration timeRemaining;
  final List<String> recommendations;
  final DateTime calculatedAt;

  const RiskAssessment({
    required this.risk,
    required this.message,
    required this.progressPercentage,
    required this.timeRemaining,
    required this.recommendations,
    required this.calculatedAt,
  });
}

/// Níveis de risco do deadline
enum DeadlineRisk {
  low,
  medium,
  high,
  critical,
  violated,
}

/// Extensão para lista
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
} 
