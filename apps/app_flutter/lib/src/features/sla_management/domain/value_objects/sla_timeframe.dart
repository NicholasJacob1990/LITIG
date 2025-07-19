import 'package:equatable/equatable.dart';

/// Value Object que representa um período de tempo para SLA
/// 
/// Encapsula regras de negócio para cálculo de prazos,
/// considerando horários comerciais, feriados e prioridades
class SlaTimeframe extends Equatable {
  const SlaTimeframe({
    required this.hours,
    required this.priority,
    this.description,
    this.isBusinessHoursOnly = true,
    this.includeWeekends = false,
    this.allowOverride = true,
    this.maxOverrideHours,
    this.metadata,
  });

  /// Número de horas do timeframe
  final int hours;

  /// Prioridade associada
  final String priority;

  /// Descrição do timeframe
  final String? description;

  /// Se considera apenas horários comerciais
  final bool isBusinessHoursOnly;

  /// Se inclui finais de semana
  final bool includeWeekends;

  /// Se permite override
  final bool allowOverride;

  /// Máximo de horas para override
  final int? maxOverrideHours;

  /// Metadados adicionais
  final Map<String, dynamic>? metadata;

  /// Timeframes padrão do sistema
  static const SlaTimeframe normal = SlaTimeframe(
    hours: 48,
    priority: 'normal',
    description: 'Prazo padrão para casos normais',
    isBusinessHoursOnly: true,
    includeWeekends: false,
    allowOverride: true,
    maxOverrideHours: 24,
  );

  static const SlaTimeframe urgent = SlaTimeframe(
    hours: 24,
    priority: 'urgent',
    description: 'Prazo para casos urgentes',
    isBusinessHoursOnly: true,
    includeWeekends: false,
    allowOverride: true,
    maxOverrideHours: 12,
  );

  static const SlaTimeframe emergency = SlaTimeframe(
    hours: 6,
    priority: 'emergency',
    description: 'Prazo para emergências',
    isBusinessHoursOnly: false,
    includeWeekends: true,
    allowOverride: true,
    maxOverrideHours: 3,
  );

  static const SlaTimeframe complex = SlaTimeframe(
    hours: 72,
    priority: 'complex',
    description: 'Prazo para casos complexos',
    isBusinessHoursOnly: true,
    includeWeekends: false,
    allowOverride: true,
    maxOverrideHours: 48,
  );

  /// Valida se o timeframe é válido
  bool get isValid {
    return hours > 0 &&
           hours <= 8760 && // Max 1 ano
           priority.isNotEmpty &&
           (maxOverrideHours == null || maxOverrideHours! >= 0) &&
           (maxOverrideHours == null || maxOverrideHours! <= hours);
  }

  /// Converte para Duration
  Duration get duration => Duration(hours: hours);

  /// Obtém descrição formatada
  String get formattedDescription {
    if (description != null) return description!;
    
    String base = '$hours horas';
    if (isBusinessHoursOnly) base += ' (horário comercial)';
    if (includeWeekends) base += ' (incluindo fins de semana)';
    return base;
  }

  /// Calcula deadline a partir de uma data
  DateTime calculateDeadline({
    required DateTime startTime,
    BusinessHours? businessHours,
    List<DateTime>? holidays,
  }) {
    if (!isBusinessHoursOnly) {
      // Cálculo simples sem considerar horário comercial
      return startTime.add(duration);
    }

    // Cálculo considerando horário comercial
    return _calculateBusinessDeadline(
      startTime: startTime,
      businessHours: businessHours ?? BusinessHours.standard(),
      holidays: holidays ?? [],
    );
  }

  /// Calcula prazo considerando horários comerciais
  DateTime _calculateBusinessDeadline({
    required DateTime startTime,
    required BusinessHours businessHours,
    required List<DateTime> holidays,
  }) {
    int remainingHours = hours;
    DateTime currentTime = startTime;

    while (remainingHours > 0) {
      // Pula para o próximo dia útil se necessário
      currentTime = _skipToNextBusinessDay(currentTime, businessHours, holidays);

      // Calcula horas disponíveis no dia atual
      final hoursInDay = _calculateAvailableHoursInDay(
        currentTime,
        businessHours,
      );

      if (remainingHours <= hoursInDay) {
        // Termina no dia atual
        return currentTime.add(Duration(hours: remainingHours));
      } else {
        // Consome o dia todo e vai para o próximo
        remainingHours -= hoursInDay;
        currentTime = _getNextBusinessDay(currentTime, businessHours, holidays);
      }
    }

    return currentTime;
  }

  /// Pula para o próximo dia útil
  DateTime _skipToNextBusinessDay(
    DateTime dateTime,
    BusinessHours businessHours,
    List<DateTime> holidays,
  ) {
    DateTime current = dateTime;

    while (!_isBusinessDay(current, holidays) ||
           current.hour >= businessHours.endHour) {
      if (current.hour >= businessHours.endHour) {
        // Vai para o início do próximo dia
        current = DateTime(
          current.year,
          current.month,
          current.day + 1,
          businessHours.startHour,
        );
      } else {
        current = current.add(const Duration(days: 1));
      }
    }

    return current;
  }

  /// Calcula horas disponíveis em um dia
  int _calculateAvailableHoursInDay(
    DateTime dateTime,
    BusinessHours businessHours,
  ) {
    final startHour = dateTime.hour < businessHours.startHour
        ? businessHours.startHour
        : dateTime.hour;

    final endHour = businessHours.endHour;

    return endHour - startHour;
  }

  /// Obtém próximo dia útil
  DateTime _getNextBusinessDay(
    DateTime dateTime,
    BusinessHours businessHours,
    List<DateTime> holidays,
  ) {
    DateTime nextDay = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day + 1,
      businessHours.startHour,
    );

    while (!_isBusinessDay(nextDay, holidays)) {
      nextDay = nextDay.add(const Duration(days: 1));
    }

    return nextDay;
  }

  /// Verifica se é dia útil
  bool _isBusinessDay(DateTime dateTime, List<DateTime> holidays) {
    // Verifica fim de semana
    if (!includeWeekends) {
      if (dateTime.weekday == DateTime.saturday ||
          dateTime.weekday == DateTime.sunday) {
        return false;
      }
    }

    // Verifica feriados
    return !holidays.any((holiday) =>
        holiday.year == dateTime.year &&
        holiday.month == dateTime.month &&
        holiday.day == dateTime.day);
  }

  /// Valida se um override é permitido
  ValidationResult validateOverride(int overrideHours) {
    if (!allowOverride) {
      return const ValidationResult(
        isValid: false,
        message: 'Override não permitido para esta prioridade',
      );
    }

    if (maxOverrideHours != null && overrideHours > maxOverrideHours!) {
      return ValidationResult(
        isValid: false,
        message: 'Override máximo é de ${maxOverrideHours!} horas',
      );
    }

    if (overrideHours < 0) {
      return const ValidationResult(
        isValid: false,
        message: 'Override não pode ser negativo',
      );
    }

    return const ValidationResult(
      isValid: true,
      message: 'Override válido',
    );
  }

  /// Cria timeframe com override
  SlaTimeframe withOverride(int overrideHours) {
    final validation = validateOverride(overrideHours);
    if (!validation.isValid) {
      throw ArgumentError(validation.message);
    }

    return SlaTimeframe(
      hours: hours + overrideHours,
      priority: priority,
      description: '$description (com override de ${overrideHours}h)',
      isBusinessHoursOnly: isBusinessHoursOnly,
      includeWeekends: includeWeekends,
      allowOverride: allowOverride,
      maxOverrideHours: maxOverrideHours,
      metadata: {
        ...?metadata,
        'original_hours': hours,
        'override_hours': overrideHours,
        'override_applied_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Compara com outro timeframe
  int compareTo(SlaTimeframe other) {
    return hours.compareTo(other.hours);
  }

  /// Verifica se é mais restritivo que outro
  bool isMoreRestrictiveThan(SlaTimeframe other) {
    return hours < other.hours;
  }

  /// Cria uma cópia com modificações
  SlaTimeframe copyWith({
    int? hours,
    String? priority,
    String? description,
    bool? isBusinessHoursOnly,
    bool? includeWeekends,
    bool? allowOverride,
    int? maxOverrideHours,
    Map<String, dynamic>? metadata,
  }) {
    return SlaTimeframe(
      hours: hours ?? this.hours,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      isBusinessHoursOnly: isBusinessHoursOnly ?? this.isBusinessHoursOnly,
      includeWeekends: includeWeekends ?? this.includeWeekends,
      allowOverride: allowOverride ?? this.allowOverride,
      maxOverrideHours: maxOverrideHours ?? this.maxOverrideHours,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        hours,
        priority,
        description,
        isBusinessHoursOnly,
        includeWeekends,
        allowOverride,
        maxOverrideHours,
        metadata,
      ];

  @override
  String toString() {
    return 'SlaTimeframe('
        'hours: $hours, '
        'priority: $priority, '
        'businessHoursOnly: $isBusinessHoursOnly, '
        'includeWeekends: $includeWeekends'
        ')';
  }
}

/// Horários comerciais
class BusinessHours extends Equatable {
  const BusinessHours({
    required this.startHour,
    required this.endHour,
    this.workDays = const [1, 2, 3, 4, 5], // Segunda a sexta
    this.timezone = 'America/Sao_Paulo',
  });

  /// Hora de início (0-23)
  final int startHour;

  /// Hora de fim (0-23)
  final int endHour;

  /// Dias úteis (1=segunda, 7=domingo)
  final List<int> workDays;

  /// Timezone
  final String timezone;

  /// Horário comercial padrão brasileiro
  factory BusinessHours.standard() {
    return const BusinessHours(
      startHour: 9,
      endHour: 18,
    );
  }

  /// Horário comercial estendido
  factory BusinessHours.extended() {
    return const BusinessHours(
      startHour: 8,
      endHour: 20,
    );
  }

  /// Plantão 24h
  factory BusinessHours.fullTime() {
    return const BusinessHours(
      startHour: 0,
      endHour: 24,
      workDays: [1, 2, 3, 4, 5, 6, 7],
    );
  }

  /// Calcula duração em horas por dia
  int get hoursPerDay => endHour - startHour;

  /// Verifica se um horário está dentro do expediente
  bool isWithinBusinessHours(DateTime dateTime) {
    return dateTime.hour >= startHour && 
           dateTime.hour < endHour &&
           workDays.contains(dateTime.weekday);
  }

  @override
  List<Object?> get props => [startHour, endHour, workDays, timezone];

  @override
  String toString() {
    return 'BusinessHours(${startHour}h-${endHour}h, days: $workDays)';
  }
}

/// Resultado de validação
class ValidationResult extends Equatable {
  const ValidationResult({
    required this.isValid,
    required this.message,
    this.details,
  });

  /// Se é válido
  final bool isValid;

  /// Mensagem de validação
  final String message;

  /// Detalhes adicionais
  final Map<String, dynamic>? details;

  @override
  List<Object?> get props => [isValid, message, details];

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, message: $message)';
  }
}