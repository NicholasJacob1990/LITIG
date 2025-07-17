import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_settings_entity.dart';
import '../value_objects/sla_timeframe.dart';

class ValidateSlaSettings implements UseCase<SlaValidationResult, ValidateSlaSettingsParams> {
  ValidateSlaSettings();

  @override
  Future<Either<Failure, SlaValidationResult>> call(ValidateSlaSettingsParams params) async {
    try {
      final violations = <SlaValidationViolation>[];
      final warnings = <SlaValidationWarning>[];

      // Validação de timeframes básicos
      _validateBasicTimeframes(params.settings, violations);

      // Validação de horários comerciais
      _validateBusinessHours(params.settings, violations, warnings);

      // Validação de escalações
      _validateEscalationSettings(params.settings, violations, warnings);

      // Validação de overrides
      _validateOverrideSettings(params.settings, violations, warnings);

      // Validação de regras de negócio
      _validateBusinessRules(params.settings, violations, warnings);

      // Validação de compatibilidade entre settings
      _validateSettingsCompatibility(params.settings, violations, warnings);

      final result = SlaValidationResult(
        isValid: violations.isEmpty,
        violations: violations,
        warnings: warnings,
        score: _calculateValidationScore(violations, warnings),
        recommendations: _generateRecommendations(violations, warnings),
      );

      return Right(result);
    } catch (e) {
      return Left(ValidationFailure('Erro durante validação: ${e.toString()}'));
    }
  }

  void _validateBasicTimeframes(SlaSettingsEntity settings, List<SlaValidationViolation> violations) {
    // Timeframes não podem ser negativos ou zero
    if (settings.normalTimeframe.hours <= 0) {
      violations.add(SlaValidationViolation(
        field: 'normalTimeframe',
        message: 'Timeframe normal deve ser maior que zero',
        severity: SlaValidationSeverity.error,
      ));
    }

    if (settings.urgentTimeframe.hours <= 0) {
      violations.add(SlaValidationViolation(
        field: 'urgentTimeframe',
        message: 'Timeframe urgente deve ser maior que zero',
        severity: SlaValidationSeverity.error,
      ));
    }

    if (settings.emergencyTimeframe.hours <= 0) {
      violations.add(SlaValidationViolation(
        field: 'emergencyTimeframe',
        message: 'Timeframe emergência deve ser maior que zero',
        severity: SlaValidationSeverity.error,
      ));
    }

    // Ordem lógica: emergency < urgent < normal
    if (settings.emergencyTimeframe.hours >= settings.urgentTimeframe.hours) {
      violations.add(SlaValidationViolation(
        field: 'timeframeOrder',
        message: 'Timeframe de emergência deve ser menor que urgente',
        severity: SlaValidationSeverity.error,
      ));
    }

    if (settings.urgentTimeframe.hours >= settings.normalTimeframe.hours) {
      violations.add(SlaValidationViolation(
        field: 'timeframeOrder',
        message: 'Timeframe urgente deve ser menor que normal',
        severity: SlaValidationSeverity.error,
      ));
    }
  }

  void _validateBusinessHours(
    SlaSettingsEntity settings,
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    // Horários comerciais devem ser válidos
    if (settings.businessStartHour < 0 || settings.businessStartHour > 23) {
      violations.add(SlaValidationViolation(
        field: 'businessStartHour',
        message: 'Hora de início deve estar entre 0 e 23',
        severity: SlaValidationSeverity.error,
      ));
    }

    if (settings.businessEndHour < 0 || settings.businessEndHour > 23) {
      violations.add(SlaValidationViolation(
        field: 'businessEndHour',
        message: 'Hora de fim deve estar entre 0 e 23',
        severity: SlaValidationSeverity.error,
      ));
    }

    // Hora de fim deve ser maior que hora de início
    if (settings.businessEndHour <= settings.businessStartHour) {
      violations.add(SlaValidationViolation(
        field: 'businessHours',
        message: 'Hora de fim deve ser maior que hora de início',
        severity: SlaValidationSeverity.error,
      ));
    }

    // Avisos para horários não convencionais
    if (settings.businessStartHour < 6 || settings.businessStartHour > 10) {
      warnings.add(SlaValidationWarning(
        field: 'businessStartHour',
        message: 'Horário de início não convencional (recomendado: 6h-10h)',
        suggestion: 'Considere ajustar para um horário mais convencional',
      ));
    }

    if (settings.businessEndHour < 16 || settings.businessEndHour > 22) {
      warnings.add(SlaValidationWarning(
        field: 'businessEndHour',
        message: 'Horário de fim não convencional (recomendado: 16h-22h)',
        suggestion: 'Considere ajustar para um horário mais convencional',
      ));
    }
  }

  void _validateEscalationSettings(
    SlaSettingsEntity settings,
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    // Validar se há pelo menos uma escalação configurada
    if (!settings.enableEscalation) {
      warnings.add(SlaValidationWarning(
        field: 'enableEscalation',
        message: 'Escalação desabilitada',
        suggestion: 'Considere habilitar escalação para melhor gestão de SLA',
      ));
    }

    // Validar percentuais de escalação
    if (settings.escalationPercentages.isEmpty && settings.enableEscalation) {
      violations.add(SlaValidationViolation(
        field: 'escalationPercentages',
        message: 'Percentuais de escalação não configurados',
        severity: SlaValidationSeverity.error,
      ));
    }

    for (final percentage in settings.escalationPercentages) {
      if (percentage <= 0 || percentage > 100) {
        violations.add(SlaValidationViolation(
          field: 'escalationPercentages',
          message: 'Percentual de escalação deve estar entre 1 e 100',
          severity: SlaValidationSeverity.error,
        ));
      }
    }
  }

  void _validateOverrideSettings(
    SlaSettingsEntity settings,
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    // Validar limites de override
    if (settings.maxOverrideHours < 0) {
      violations.add(SlaValidationViolation(
        field: 'maxOverrideHours',
        message: 'Limite de override não pode ser negativo',
        severity: SlaValidationSeverity.error,
      ));
    }

    if (settings.maxOverrideHours > 168) { // 1 semana
      warnings.add(SlaValidationWarning(
        field: 'maxOverrideHours',
        message: 'Limite de override muito alto (>1 semana)',
        suggestion: 'Considere reduzir o limite para evitar abusos',
      ));
    }

    // Validar permissões de override
    if (settings.allowOverride && settings.overrideRequiredRoles.isEmpty) {
      violations.add(SlaValidationViolation(
        field: 'overrideRequiredRoles',
        message: 'Roles obrigatórios não definidos para override',
        severity: SlaValidationSeverity.error,
      ));
    }
  }

  void _validateBusinessRules(
    SlaSettingsEntity settings,
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    // Validar dias úteis
    if (settings.businessDays.isEmpty) {
      violations.add(SlaValidationViolation(
        field: 'businessDays',
        message: 'Pelo menos um dia útil deve ser configurado',
        severity: SlaValidationSeverity.error,
      ));
    }

    // Avisar sobre fins de semana incluídos
    if (settings.businessDays.contains(6) || settings.businessDays.contains(7)) {
      warnings.add(SlaValidationWarning(
        field: 'businessDays',
        message: 'Fins de semana incluídos como dias úteis',
        suggestion: 'Verifique se é necessário incluir sábado/domingo',
      ));
    }

    // Validar timezone
    if (settings.timezone.isEmpty) {
      violations.add(SlaValidationViolation(
        field: 'timezone',
        message: 'Timezone deve ser especificado',
        severity: SlaValidationSeverity.error,
      ));
    }
  }

  void _validateSettingsCompatibility(
    SlaSettingsEntity settings,
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    // Verificar compatibilidade entre override e timeframes
    if (settings.allowOverride && settings.maxOverrideHours > settings.normalTimeframe.hours * 2) {
      warnings.add(SlaValidationWarning(
        field: 'overrideCompatibility',
        message: 'Limite de override muito alto comparado aos timeframes',
        suggestion: 'Considere reduzir o limite de override',
      ));
    }

    // Verificar se horários comerciais são realistas
    final businessHours = settings.businessEndHour - settings.businessStartHour;
    if (businessHours < 4) {
      warnings.add(SlaValidationWarning(
        field: 'businessHoursRealistic',
        message: 'Poucas horas comerciais por dia (<4h)',
        suggestion: 'Considere expandir o horário comercial',
      ));
    }

    if (businessHours > 16) {
      warnings.add(SlaValidationWarning(
        field: 'businessHoursRealistic',
        message: 'Muitas horas comerciais por dia (>16h)',
        suggestion: 'Considere reduzir o horário comercial',
      ));
    }
  }

  int _calculateValidationScore(
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    int score = 100;
    
    // Penalizar por violações
    for (final violation in violations) {
      switch (violation.severity) {
        case SlaValidationSeverity.error:
          score -= 15;
          break;
        case SlaValidationSeverity.warning:
          score -= 5;
          break;
      }
    }

    // Penalizar por avisos
    score -= warnings.length * 2;

    return score.clamp(0, 100);
  }

  List<String> _generateRecommendations(
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    final recommendations = <String>[];

    if (violations.isNotEmpty) {
      recommendations.add('Corrija os erros de validação antes de salvar as configurações');
    }

    if (warnings.isNotEmpty) {
      recommendations.add('Revise os avisos para otimizar as configurações');
    }

    // Recomendações específicas baseadas em padrões
    final hasBusinessDaysWarning = warnings.any((w) => w.field == 'businessDays');
    if (hasBusinessDaysWarning) {
      recommendations.add('Considere excluir fins de semana dos dias úteis para SLAs mais realistas');
    }

    final hasTimeframeWarning = violations.any((v) => v.field.contains('timeframe'));
    if (hasTimeframeWarning) {
      recommendations.add('Revise a ordem dos timeframes: emergência < urgente < normal');
    }

    return recommendations;
  }
}

class ValidateSlaSettingsParams {
  final SlaSettingsEntity settings;

  ValidateSlaSettingsParams({required this.settings});
}

class SlaValidationResult {
  final bool isValid;
  final List<SlaValidationViolation> violations;
  final List<SlaValidationWarning> warnings;
  final int score; // 0-100
  final List<String> recommendations;

  SlaValidationResult({
    required this.isValid,
    required this.violations,
    required this.warnings,
    required this.score,
    required this.recommendations,
  });

  Map<String, dynamic> toMap() {
    return {
      'isValid': isValid,
      'violations': violations.map((v) => v.toMap()).toList(),
      'warnings': warnings.map((w) => w.toMap()).toList(),
      'score': score,
      'recommendations': recommendations,
    };
  }
}

class SlaValidationViolation {
  final String field;
  final String message;
  final SlaValidationSeverity severity;

  SlaValidationViolation({
    required this.field,
    required this.message,
    required this.severity,
  });

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'message': message,
      'severity': severity.toString(),
    };
  }
}

class SlaValidationWarning {
  final String field;
  final String message;
  final String suggestion;

  SlaValidationWarning({
    required this.field,
    required this.message,
    required this.suggestion,
  });

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'message': message,
      'suggestion': suggestion,
    };
  }
}

enum SlaValidationSeverity { error, warning }

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
} 
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_settings_entity.dart';
import '../value_objects/sla_timeframe.dart';

class ValidateSlaSettings implements UseCase<SlaValidationResult, ValidateSlaSettingsParams> {
  ValidateSlaSettings();

  @override
  Future<Either<Failure, SlaValidationResult>> call(ValidateSlaSettingsParams params) async {
    try {
      final violations = <SlaValidationViolation>[];
      final warnings = <SlaValidationWarning>[];

      // Validação de timeframes básicos
      _validateBasicTimeframes(params.settings, violations);

      // Validação de horários comerciais
      _validateBusinessHours(params.settings, violations, warnings);

      // Validação de escalações
      _validateEscalationSettings(params.settings, violations, warnings);

      // Validação de overrides
      _validateOverrideSettings(params.settings, violations, warnings);

      // Validação de regras de negócio
      _validateBusinessRules(params.settings, violations, warnings);

      // Validação de compatibilidade entre settings
      _validateSettingsCompatibility(params.settings, violations, warnings);

      final result = SlaValidationResult(
        isValid: violations.isEmpty,
        violations: violations,
        warnings: warnings,
        score: _calculateValidationScore(violations, warnings),
        recommendations: _generateRecommendations(violations, warnings),
      );

      return Right(result);
    } catch (e) {
      return Left(ValidationFailure('Erro durante validação: ${e.toString()}'));
    }
  }

  void _validateBasicTimeframes(SlaSettingsEntity settings, List<SlaValidationViolation> violations) {
    // Timeframes não podem ser negativos ou zero
    if (settings.normalTimeframe.hours <= 0) {
      violations.add(SlaValidationViolation(
        field: 'normalTimeframe',
        message: 'Timeframe normal deve ser maior que zero',
        severity: SlaValidationSeverity.error,
      ));
    }

    if (settings.urgentTimeframe.hours <= 0) {
      violations.add(SlaValidationViolation(
        field: 'urgentTimeframe',
        message: 'Timeframe urgente deve ser maior que zero',
        severity: SlaValidationSeverity.error,
      ));
    }

    if (settings.emergencyTimeframe.hours <= 0) {
      violations.add(SlaValidationViolation(
        field: 'emergencyTimeframe',
        message: 'Timeframe emergência deve ser maior que zero',
        severity: SlaValidationSeverity.error,
      ));
    }

    // Ordem lógica: emergency < urgent < normal
    if (settings.emergencyTimeframe.hours >= settings.urgentTimeframe.hours) {
      violations.add(SlaValidationViolation(
        field: 'timeframeOrder',
        message: 'Timeframe de emergência deve ser menor que urgente',
        severity: SlaValidationSeverity.error,
      ));
    }

    if (settings.urgentTimeframe.hours >= settings.normalTimeframe.hours) {
      violations.add(SlaValidationViolation(
        field: 'timeframeOrder',
        message: 'Timeframe urgente deve ser menor que normal',
        severity: SlaValidationSeverity.error,
      ));
    }
  }

  void _validateBusinessHours(
    SlaSettingsEntity settings,
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    // Horários comerciais devem ser válidos
    if (settings.businessStartHour < 0 || settings.businessStartHour > 23) {
      violations.add(SlaValidationViolation(
        field: 'businessStartHour',
        message: 'Hora de início deve estar entre 0 e 23',
        severity: SlaValidationSeverity.error,
      ));
    }

    if (settings.businessEndHour < 0 || settings.businessEndHour > 23) {
      violations.add(SlaValidationViolation(
        field: 'businessEndHour',
        message: 'Hora de fim deve estar entre 0 e 23',
        severity: SlaValidationSeverity.error,
      ));
    }

    // Hora de fim deve ser maior que hora de início
    if (settings.businessEndHour <= settings.businessStartHour) {
      violations.add(SlaValidationViolation(
        field: 'businessHours',
        message: 'Hora de fim deve ser maior que hora de início',
        severity: SlaValidationSeverity.error,
      ));
    }

    // Avisos para horários não convencionais
    if (settings.businessStartHour < 6 || settings.businessStartHour > 10) {
      warnings.add(SlaValidationWarning(
        field: 'businessStartHour',
        message: 'Horário de início não convencional (recomendado: 6h-10h)',
        suggestion: 'Considere ajustar para um horário mais convencional',
      ));
    }

    if (settings.businessEndHour < 16 || settings.businessEndHour > 22) {
      warnings.add(SlaValidationWarning(
        field: 'businessEndHour',
        message: 'Horário de fim não convencional (recomendado: 16h-22h)',
        suggestion: 'Considere ajustar para um horário mais convencional',
      ));
    }
  }

  void _validateEscalationSettings(
    SlaSettingsEntity settings,
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    // Validar se há pelo menos uma escalação configurada
    if (!settings.enableEscalation) {
      warnings.add(SlaValidationWarning(
        field: 'enableEscalation',
        message: 'Escalação desabilitada',
        suggestion: 'Considere habilitar escalação para melhor gestão de SLA',
      ));
    }

    // Validar percentuais de escalação
    if (settings.escalationPercentages.isEmpty && settings.enableEscalation) {
      violations.add(SlaValidationViolation(
        field: 'escalationPercentages',
        message: 'Percentuais de escalação não configurados',
        severity: SlaValidationSeverity.error,
      ));
    }

    for (final percentage in settings.escalationPercentages) {
      if (percentage <= 0 || percentage > 100) {
        violations.add(SlaValidationViolation(
          field: 'escalationPercentages',
          message: 'Percentual de escalação deve estar entre 1 e 100',
          severity: SlaValidationSeverity.error,
        ));
      }
    }
  }

  void _validateOverrideSettings(
    SlaSettingsEntity settings,
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    // Validar limites de override
    if (settings.maxOverrideHours < 0) {
      violations.add(SlaValidationViolation(
        field: 'maxOverrideHours',
        message: 'Limite de override não pode ser negativo',
        severity: SlaValidationSeverity.error,
      ));
    }

    if (settings.maxOverrideHours > 168) { // 1 semana
      warnings.add(SlaValidationWarning(
        field: 'maxOverrideHours',
        message: 'Limite de override muito alto (>1 semana)',
        suggestion: 'Considere reduzir o limite para evitar abusos',
      ));
    }

    // Validar permissões de override
    if (settings.allowOverride && settings.overrideRequiredRoles.isEmpty) {
      violations.add(SlaValidationViolation(
        field: 'overrideRequiredRoles',
        message: 'Roles obrigatórios não definidos para override',
        severity: SlaValidationSeverity.error,
      ));
    }
  }

  void _validateBusinessRules(
    SlaSettingsEntity settings,
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    // Validar dias úteis
    if (settings.businessDays.isEmpty) {
      violations.add(SlaValidationViolation(
        field: 'businessDays',
        message: 'Pelo menos um dia útil deve ser configurado',
        severity: SlaValidationSeverity.error,
      ));
    }

    // Avisar sobre fins de semana incluídos
    if (settings.businessDays.contains(6) || settings.businessDays.contains(7)) {
      warnings.add(SlaValidationWarning(
        field: 'businessDays',
        message: 'Fins de semana incluídos como dias úteis',
        suggestion: 'Verifique se é necessário incluir sábado/domingo',
      ));
    }

    // Validar timezone
    if (settings.timezone.isEmpty) {
      violations.add(SlaValidationViolation(
        field: 'timezone',
        message: 'Timezone deve ser especificado',
        severity: SlaValidationSeverity.error,
      ));
    }
  }

  void _validateSettingsCompatibility(
    SlaSettingsEntity settings,
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    // Verificar compatibilidade entre override e timeframes
    if (settings.allowOverride && settings.maxOverrideHours > settings.normalTimeframe.hours * 2) {
      warnings.add(SlaValidationWarning(
        field: 'overrideCompatibility',
        message: 'Limite de override muito alto comparado aos timeframes',
        suggestion: 'Considere reduzir o limite de override',
      ));
    }

    // Verificar se horários comerciais são realistas
    final businessHours = settings.businessEndHour - settings.businessStartHour;
    if (businessHours < 4) {
      warnings.add(SlaValidationWarning(
        field: 'businessHoursRealistic',
        message: 'Poucas horas comerciais por dia (<4h)',
        suggestion: 'Considere expandir o horário comercial',
      ));
    }

    if (businessHours > 16) {
      warnings.add(SlaValidationWarning(
        field: 'businessHoursRealistic',
        message: 'Muitas horas comerciais por dia (>16h)',
        suggestion: 'Considere reduzir o horário comercial',
      ));
    }
  }

  int _calculateValidationScore(
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    int score = 100;
    
    // Penalizar por violações
    for (final violation in violations) {
      switch (violation.severity) {
        case SlaValidationSeverity.error:
          score -= 15;
          break;
        case SlaValidationSeverity.warning:
          score -= 5;
          break;
      }
    }

    // Penalizar por avisos
    score -= warnings.length * 2;

    return score.clamp(0, 100);
  }

  List<String> _generateRecommendations(
    List<SlaValidationViolation> violations,
    List<SlaValidationWarning> warnings,
  ) {
    final recommendations = <String>[];

    if (violations.isNotEmpty) {
      recommendations.add('Corrija os erros de validação antes de salvar as configurações');
    }

    if (warnings.isNotEmpty) {
      recommendations.add('Revise os avisos para otimizar as configurações');
    }

    // Recomendações específicas baseadas em padrões
    final hasBusinessDaysWarning = warnings.any((w) => w.field == 'businessDays');
    if (hasBusinessDaysWarning) {
      recommendations.add('Considere excluir fins de semana dos dias úteis para SLAs mais realistas');
    }

    final hasTimeframeWarning = violations.any((v) => v.field.contains('timeframe'));
    if (hasTimeframeWarning) {
      recommendations.add('Revise a ordem dos timeframes: emergência < urgente < normal');
    }

    return recommendations;
  }
}

class ValidateSlaSettingsParams {
  final SlaSettingsEntity settings;

  ValidateSlaSettingsParams({required this.settings});
}

class SlaValidationResult {
  final bool isValid;
  final List<SlaValidationViolation> violations;
  final List<SlaValidationWarning> warnings;
  final int score; // 0-100
  final List<String> recommendations;

  SlaValidationResult({
    required this.isValid,
    required this.violations,
    required this.warnings,
    required this.score,
    required this.recommendations,
  });

  Map<String, dynamic> toMap() {
    return {
      'isValid': isValid,
      'violations': violations.map((v) => v.toMap()).toList(),
      'warnings': warnings.map((w) => w.toMap()).toList(),
      'score': score,
      'recommendations': recommendations,
    };
  }
}

class SlaValidationViolation {
  final String field;
  final String message;
  final SlaValidationSeverity severity;

  SlaValidationViolation({
    required this.field,
    required this.message,
    required this.severity,
  });

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'message': message,
      'severity': severity.toString(),
    };
  }
}

class SlaValidationWarning {
  final String field;
  final String message;
  final String suggestion;

  SlaValidationWarning({
    required this.field,
    required this.message,
    required this.suggestion,
  });

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'message': message,
      'suggestion': suggestion,
    };
  }
}

enum SlaValidationSeverity { error, warning }

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
} 