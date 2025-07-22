import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sla_preset_entity.dart';
import '../value_objects/sla_timeframe.dart';
import '../repositories/sla_settings_repository.dart';

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
        (preset) async {
          // Aplicar regras de negócio se solicitado
          final effectivePreset = includeBusinessRules 
            ? _applyBusinessRules(preset, overrides)
            : preset;

          // Calcular deadline baseado nas configurações
          final deadline = _calculateDeadlineInternal(
            startTime: startTime,
            priority: priority,
            caseType: caseType,
            preset: effectivePreset,
          );

          return Right(DeadlineResult(
            deadline: deadline,
            preset: effectivePreset,
            calculationDate: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      return Left(ServerFailure(
        message: 'Erro ao calcular deadline SLA: ${e.toString()}',
        code: 'CALCULATION_ERROR',
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
        (preset) async {
          final results = <DeadlineResult>[];
          
          for (final caseParams in cases) {
            final effectivePreset = includeBusinessRules 
              ? _applyBusinessRules(preset, caseParams['overrides'])
              : preset;

            final deadline = _calculateDeadlineInternal(
              startTime: caseParams['startTime'] as DateTime,
              priority: caseParams['priority'] as String,
              caseType: caseParams['caseType'] as String?,
              preset: effectivePreset,
            );

            results.add(DeadlineResult(
              deadline: deadline,
              preset: effectivePreset,
              calculationDate: DateTime.now(),
            ));
          }
          
          return Right(results);
        },
      );
    } catch (e) {
      return Left(ServerFailure(
        message: 'Erro ao calcular deadlines múltiplos: ${e.toString()}',
        code: 'MULTIPLE_CALCULATION_ERROR',
      ));
    }
  }

  /// Calcula deadline com override específico
  Future<Either<Failure, DeadlineResult>> calculateWithOverride({
    required String firmId,
    required DateTime startTime,
    required String priority,
    required Map<String, dynamic> overrides,
    String? caseType,
  }) async {
    try {
      // Buscar configurações SLA do escritório
      final settingsResult = await repository.getSettings(firmId: firmId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (preset) async {
          // Aplicar overrides específicos
          final overriddenPreset = _applyOverrides(preset, overrides);

          // Calcular deadline com configurações modificadas
          final deadline = _calculateDeadlineInternal(
            startTime: startTime,
            priority: priority,
            caseType: caseType,
            preset: overriddenPreset,
          );

          return Right(DeadlineResult(
            deadline: deadline,
            preset: overriddenPreset,
            calculationDate: DateTime.now(),
            overridesApplied: overrides,
          ));
        },
      );
    } catch (e) {
      return Left(ServerFailure(
        message: 'Erro ao calcular deadline com override: ${e.toString()}',
        code: 'OVERRIDE_CALCULATION_ERROR',
      ));
    }
  }

  /// Avalia risco de violação de SLA
  Future<Either<Failure, SlaRiskAssessment>> assessRisk({
    required String firmId,
    required DateTime startTime,
    required String priority,
    required DateTime currentTime,
    String? caseType,
  }) async {
    try {
      final settingsResult = await repository.getSettings(firmId: firmId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (preset) async {
          final result = await calculate(
        firmId: firmId,
        startTime: startTime,
        priority: priority,
        caseType: caseType,
      );
      
          return result.fold(
        (failure) => Left(failure),
            (deadlineResult) {
              final timeToDeadline = deadlineResult.deadline.difference(currentTime);
              final totalTime = deadlineResult.deadline.difference(startTime);
          
          return Right(_assessRisk(
            timeToDeadline: timeToDeadline,
            totalTime: totalTime,
            priority: priority,
                result: deadlineResult,
          ));
            },
          );
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao avaliar risco de deadline: ${e.toString()}'));
    }
  }

  /// Calcula o deadline baseado nas configurações
  DateTime _calculateDeadlineInternal({
    required DateTime startTime,
    required String priority,
    String? caseType,
    required SlaPresetEntity preset,
  }) {
    // Obter timeframe para a prioridade
    final timeframe = _getTimeframeForPriorityInternal(preset, priority);
    
    // Calcular deadline baseado no timeframe
    final deadline = startTime.add(Duration(hours: timeframe.hours));
    
    // Aplicar regras de horário comercial se necessário
    if (preset.isSystemPreset) {
      return _adjustToBusinessHours(deadline, preset);
    }
    
    return deadline;
  }

  /// Obtém o timeframe para uma prioridade específica
  SlaTimeframe _getTimeframeForPriorityInternal(
    SlaPresetEntity preset,
    String priority,
  ) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return SlaTimeframe.urgent.copyWith(hours: preset.urgentSlaHours);
      case 'emergency':
        return SlaTimeframe.emergency.copyWith(hours: preset.emergencySlaHours);
      case 'complex':
        return SlaTimeframe.complex.copyWith(hours: preset.complexCaseSlaHours);
      default:
        return SlaTimeframe.normal.copyWith(hours: preset.defaultSlaHours);
    }
  }

  /// Aplica regras de negócio às configurações
  SlaPresetEntity _applyBusinessRules(
    SlaPresetEntity preset,
    Map<String, dynamic>? overrides,
  ) {
    if (overrides == null) return preset;
    
    // Aplicar overrides específicos se fornecidos
    return preset.copyWith(
      businessHoursStart: overrides['businessHoursStart'] ?? preset.businessHoursStart,
      businessHoursEnd: overrides['businessHoursEnd'] ?? preset.businessHoursEnd,
      urgentSlaHours: overrides['urgentSlaHours'] ?? preset.urgentSlaHours,
      emergencySlaHours: overrides['emergencySlaHours'] ?? preset.emergencySlaHours,
      complexCaseSlaHours: overrides['complexCaseSlaHours'] ?? preset.complexCaseSlaHours,
      defaultSlaHours: overrides['defaultSlaHours'] ?? preset.defaultSlaHours,
    );
    }

  /// Aplica overrides específicos
  SlaPresetEntity _applyOverrides(
    SlaPresetEntity preset,
    Map<String, dynamic> overrides,
  ) {
    return preset.copyWith(
      businessHoursStart: overrides['businessHoursStart'] ?? preset.businessHoursStart,
      businessHoursEnd: overrides['businessHoursEnd'] ?? preset.businessHoursEnd,
      urgentSlaHours: overrides['urgentSlaHours'] ?? preset.urgentSlaHours,
      emergencySlaHours: overrides['emergencySlaHours'] ?? preset.emergencySlaHours,
      complexCaseSlaHours: overrides['complexCaseSlaHours'] ?? preset.complexCaseSlaHours,
      defaultSlaHours: overrides['defaultSlaHours'] ?? preset.defaultSlaHours,
    );
  }

  /// Ajusta o deadline para horário comercial
  DateTime _adjustToBusinessHours(
    DateTime deadline,
    SlaPresetEntity preset,
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

  /// Avalia o risco de violação de SLA
  SlaRiskAssessment _assessRisk({
    required Duration timeToDeadline,
    required Duration totalTime,
    required String priority,
    required DeadlineResult result,
  }) {
    final riskLevel = _calculateRiskLevel(timeToDeadline, totalTime, priority);
    final recommendations = _generateRecommendations(riskLevel, timeToDeadline);
    
    return SlaRiskAssessment(
      riskLevel: riskLevel,
      timeRemaining: timeToDeadline,
      totalTime: totalTime,
      recommendations: recommendations,
      deadline: result.deadline,
      priority: priority,
    );
  }

  /// Calcula o nível de risco
  String _calculateRiskLevel(Duration timeToDeadline, Duration totalTime, String priority) {
    final percentageRemaining = timeToDeadline.inHours / totalTime.inHours;
    
    if (timeToDeadline.isNegative) return 'CRITICAL';
    if (percentageRemaining < 0.1) return 'HIGH';
    if (percentageRemaining < 0.3) return 'MEDIUM';
    return 'LOW';
  }

  /// Gera recomendações baseadas no risco
  List<String> _generateRecommendations(String riskLevel, Duration timeRemaining) {
    switch (riskLevel) {
      case 'CRITICAL':
        return [
          'SLA já violado - ação imediata necessária',
          'Notificar stakeholders',
          'Revisar processo de trabalho',
        ];
      case 'HIGH':
        return [
          'Ação urgente necessária',
          'Considerar escalação',
          'Revisar prioridades',
        ];
      case 'MEDIUM':
        return [
          'Monitorar progresso',
          'Verificar recursos disponíveis',
        ];
      case 'LOW':
        return [
          'Manter ritmo atual',
          'Monitorar regularmente',
        ];
      default:
        return ['Monitorar situação'];
    }
  }
}

/// Resultado do cálculo de deadline
class DeadlineResult {
  final DateTime deadline;
  final SlaPresetEntity? preset;
  final DateTime calculationDate;
  final Map<String, dynamic>? overridesApplied;

  const DeadlineResult({
    required this.deadline,
    this.preset,
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

/// Avaliação de risco de SLA
class SlaRiskAssessment {
  final String riskLevel;
  final Duration timeRemaining;
  final Duration totalTime;
  final List<String> recommendations;
  final DateTime deadline;
  final String priority;

  const SlaRiskAssessment({
    required this.riskLevel,
    required this.timeRemaining,
    required this.totalTime,
    required this.recommendations,
    required this.deadline,
    required this.priority,
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
