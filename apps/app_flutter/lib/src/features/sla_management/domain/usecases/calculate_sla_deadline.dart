import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import '../entities/sla_settings_entity.dart';
import '../value_objects/sla_timeframe.dart';
import '../repositories/sla_settings_repository.dart';

/// Use case para cálculo de deadline SLA
/// 
/// Responsável por calcular prazos considerando todas as regras
/// de negócio: prioridade, horários comerciais, feriados, overrides
class CalculateSlaDeadlineUseCase {
  final SlaSettingsRepository repository;

  const CalculateSlaDeadlineUseCase(this.repository);

  /// Calcula deadline SLA para um caso
  Future<Either<Failure, DeadlineResult>> call({
    required String firmId,
    required DateTime startTime,
    required String priority,
    String? caseType,
    Map<String, dynamic>? overrides,
    bool includeBusinessRules = true,
  }) async {
    try {
      // Obtém configurações SLA da firma
      final settingsResult = await repository.getSettings(firmId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) => Right(_calculateDeadline(
          settings: settings,
          startTime: startTime,
          priority: priority,
          caseType: caseType,
          overrides: overrides,
          includeBusinessRules: includeBusinessRules,
        )),
      );
    } catch (e) {
      return Left(ServerFailure('Erro ao calcular deadline SLA: ${e.toString()}'));
    }
  }

  /// Calcula múltiplos deadlines para diferentes prioridades
  Future<Either<Failure, Map<String, DeadlineResult>>> calculateMultiple({
    required String firmId,
    required DateTime startTime,
    required List<String> priorities,
    String? caseType,
    Map<String, dynamic>? overrides,
  }) async {
    try {
      final settingsResult = await repository.getSettings(firmId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          final results = <String, DeadlineResult>{};
          
          for (final priority in priorities) {
            results[priority] = _calculateDeadline(
              settings: settings,
              startTime: startTime,
              priority: priority,
              caseType: caseType,
              overrides: overrides,
            );
          }
          
          return Right(results);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Erro ao calcular múltiplos deadlines: ${e.toString()}'));
    }
  }

  /// Calcula deadline com override personalizado
  Future<Either<Failure, DeadlineResult>> calculateWithOverride({
    required String firmId,
    required DateTime startTime,
    required String priority,
    required int overrideHours,
    String? justification,
    String? caseType,
  }) async {
    try {
      final settingsResult = await repository.getSettings(firmId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          final timeframe = _getTimeframeForPriority(settings, priority);
          
          // Valida override
          final validation = timeframe.validateOverride(overrideHours);
          if (!validation.isValid) {
            return Left(ValidationFailure(validation.message));
          }
          
          final overriddenTimeframe = timeframe.withOverride(overrideHours);
          
          return Right(_calculateWithTimeframe(
            timeframe: overriddenTimeframe,
            settings: settings,
            startTime: startTime,
            isOverridden: true,
            overrideJustification: justification,
          ));
        },
      );
    } catch (e) {
      return Left(ServerFailure('Erro ao calcular deadline com override: ${e.toString()}'));
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
      final settingsResult = await repository.getSettings(firmId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          var timeframe = _getTimeframeForPriority(settings, priority);
          
          // Aplica fator de complexidade
          final complexityMultiplier = _getComplexityMultiplier(complexityLevel);
          final adjustedHours = (timeframe.hours * complexityMultiplier).round();
          
          timeframe = timeframe.copyWith(
            hours: adjustedHours,
            description: '${timeframe.description} (ajustado para complexidade $complexityLevel)',
          );
          
          return Right(_calculateWithTimeframe(
            timeframe: timeframe,
            settings: settings,
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
      return Left(ServerFailure('Erro ao calcular deadline para caso complexo: ${e.toString()}'));
    }
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
      final deadlineResult = await call(
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
      return Left(ServerFailure('Erro ao avaliar risco de deadline: ${e.toString()}'));
    }
  }

  DeadlineResult _calculateDeadline({
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
}

/// Resultado do cálculo de deadline
class DeadlineResult {
  final DateTime deadline;
  final SlaTimeframe timeframe;
  final List<DeadlineMilestone> milestones;
  final DateTime? nextNotification;
  final bool isOverridden;
  final String? overrideJustification;
  final DateTime calculatedAt;
  final Map<String, dynamic> metadata;

  const DeadlineResult({
    required this.deadline,
    required this.timeframe,
    required this.milestones,
    this.nextNotification,
    this.isOverridden = false,
    this.overrideJustification,
    required this.calculatedAt,
    this.metadata = const {},
  });

  /// Tempo restante até o deadline
  Duration get timeRemaining => deadline.difference(DateTime.now());

  /// Se o deadline já foi violado
  bool get isViolated => DateTime.now().isAfter(deadline);

  /// Se está próximo do deadline (menos de 24h)
  bool get isApproaching => timeRemaining.inHours <= 24 && timeRemaining.inHours > 0;

  /// Próximo marco a ser atingido
  DeadlineMilestone? get nextMilestone {
    final now = DateTime.now();
    return milestones.where((m) => m.deadline.isAfter(now)).firstOrNull;
  }
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
import '../../../core/error/failure.dart';
import '../entities/sla_settings_entity.dart';
import '../value_objects/sla_timeframe.dart';
import '../repositories/sla_settings_repository.dart';

/// Use case para cálculo de deadline SLA
/// 
/// Responsável por calcular prazos considerando todas as regras
/// de negócio: prioridade, horários comerciais, feriados, overrides
class CalculateSlaDeadlineUseCase {
  final SlaSettingsRepository repository;

  const CalculateSlaDeadlineUseCase(this.repository);

  /// Calcula deadline SLA para um caso
  Future<Either<Failure, DeadlineResult>> call({
    required String firmId,
    required DateTime startTime,
    required String priority,
    String? caseType,
    Map<String, dynamic>? overrides,
    bool includeBusinessRules = true,
  }) async {
    try {
      // Obtém configurações SLA da firma
      final settingsResult = await repository.getSettings(firmId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) => Right(_calculateDeadline(
          settings: settings,
          startTime: startTime,
          priority: priority,
          caseType: caseType,
          overrides: overrides,
          includeBusinessRules: includeBusinessRules,
        )),
      );
    } catch (e) {
      return Left(ServerFailure('Erro ao calcular deadline SLA: ${e.toString()}'));
    }
  }

  /// Calcula múltiplos deadlines para diferentes prioridades
  Future<Either<Failure, Map<String, DeadlineResult>>> calculateMultiple({
    required String firmId,
    required DateTime startTime,
    required List<String> priorities,
    String? caseType,
    Map<String, dynamic>? overrides,
  }) async {
    try {
      final settingsResult = await repository.getSettings(firmId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          final results = <String, DeadlineResult>{};
          
          for (final priority in priorities) {
            results[priority] = _calculateDeadline(
              settings: settings,
              startTime: startTime,
              priority: priority,
              caseType: caseType,
              overrides: overrides,
            );
          }
          
          return Right(results);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Erro ao calcular múltiplos deadlines: ${e.toString()}'));
    }
  }

  /// Calcula deadline com override personalizado
  Future<Either<Failure, DeadlineResult>> calculateWithOverride({
    required String firmId,
    required DateTime startTime,
    required String priority,
    required int overrideHours,
    String? justification,
    String? caseType,
  }) async {
    try {
      final settingsResult = await repository.getSettings(firmId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          final timeframe = _getTimeframeForPriority(settings, priority);
          
          // Valida override
          final validation = timeframe.validateOverride(overrideHours);
          if (!validation.isValid) {
            return Left(ValidationFailure(validation.message));
          }
          
          final overriddenTimeframe = timeframe.withOverride(overrideHours);
          
          return Right(_calculateWithTimeframe(
            timeframe: overriddenTimeframe,
            settings: settings,
            startTime: startTime,
            isOverridden: true,
            overrideJustification: justification,
          ));
        },
      );
    } catch (e) {
      return Left(ServerFailure('Erro ao calcular deadline com override: ${e.toString()}'));
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
      final settingsResult = await repository.getSettings(firmId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          var timeframe = _getTimeframeForPriority(settings, priority);
          
          // Aplica fator de complexidade
          final complexityMultiplier = _getComplexityMultiplier(complexityLevel);
          final adjustedHours = (timeframe.hours * complexityMultiplier).round();
          
          timeframe = timeframe.copyWith(
            hours: adjustedHours,
            description: '${timeframe.description} (ajustado para complexidade $complexityLevel)',
          );
          
          return Right(_calculateWithTimeframe(
            timeframe: timeframe,
            settings: settings,
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
      return Left(ServerFailure('Erro ao calcular deadline para caso complexo: ${e.toString()}'));
    }
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
      final deadlineResult = await call(
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
      return Left(ServerFailure('Erro ao avaliar risco de deadline: ${e.toString()}'));
    }
  }

  DeadlineResult _calculateDeadline({
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
}

/// Resultado do cálculo de deadline
class DeadlineResult {
  final DateTime deadline;
  final SlaTimeframe timeframe;
  final List<DeadlineMilestone> milestones;
  final DateTime? nextNotification;
  final bool isOverridden;
  final String? overrideJustification;
  final DateTime calculatedAt;
  final Map<String, dynamic> metadata;

  const DeadlineResult({
    required this.deadline,
    required this.timeframe,
    required this.milestones,
    this.nextNotification,
    this.isOverridden = false,
    this.overrideJustification,
    required this.calculatedAt,
    this.metadata = const {},
  });

  /// Tempo restante até o deadline
  Duration get timeRemaining => deadline.difference(DateTime.now());

  /// Se o deadline já foi violado
  bool get isViolated => DateTime.now().isAfter(deadline);

  /// Se está próximo do deadline (menos de 24h)
  bool get isApproaching => timeRemaining.inHours <= 24 && timeRemaining.inHours > 0;

  /// Próximo marco a ser atingido
  DeadlineMilestone? get nextMilestone {
    final now = DateTime.now();
    return milestones.where((m) => m.deadline.isAfter(now)).firstOrNull;
  }
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