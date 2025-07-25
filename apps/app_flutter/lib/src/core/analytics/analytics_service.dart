import 'dart:async';

/// Serviço de analytics para tracking de uso das funcionalidades
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final StreamController<AnalyticsEvent> _eventController = StreamController<AnalyticsEvent>.broadcast();
  
  /// Stream de eventos de analytics
  Stream<AnalyticsEvent> get events => _eventController.stream;

  /// Lista de eventos registrados para debugging
  final List<AnalyticsEvent> _events = [];
  List<AnalyticsEvent> get recentEvents => List.unmodifiable(_events);

  /// Registra um evento de visualização de perfil de advogado
  void trackLawyerProfileView(String lawyerId, {Map<String, dynamic>? metadata}) {
    final event = AnalyticsEvent(
      type: AnalyticsEventType.lawyerProfileView,
      timestamp: DateTime.now(),
      data: {
        'lawyer_id': lawyerId,
        ...?metadata,
      },
    );
    _trackEvent(event);
  }

  /// Registra um evento de visualização de perfil de escritório
  void trackFirmProfileView(String firmId, {Map<String, dynamic>? metadata}) {
    final event = AnalyticsEvent(
      type: AnalyticsEventType.firmProfileView,
      timestamp: DateTime.now(),
      data: {
        'firm_id': firmId,
        ...?metadata,
      },
    );
    _trackEvent(event);
  }

  /// Registra um evento de navegação entre abas
  void trackTabNavigation(String profileType, String tabName, {Map<String, dynamic>? metadata}) {
    final event = AnalyticsEvent(
      type: AnalyticsEventType.tabNavigation,
      timestamp: DateTime.now(),
      data: {
        'profile_type': profileType, // 'lawyer' or 'firm'
        'tab_name': tabName,
        ...?metadata,
      },
    );
    _trackEvent(event);
  }

  /// Registra um evento de aplicação de filtros
  void trackFilterUsage(String screen, Map<String, String> filters, {Map<String, dynamic>? metadata}) {
    final event = AnalyticsEvent(
      type: AnalyticsEventType.filterUsage,
      timestamp: DateTime.now(),
      data: {
        'screen': screen,
        'filters': filters,
        ...?metadata,
      },
    );
    _trackEvent(event);
  }

  /// Registra um evento de atualização/refresh de dados
  void trackDataRefresh(String profileType, String profileId, {Map<String, dynamic>? metadata}) {
    final event = AnalyticsEvent(
      type: AnalyticsEventType.dataRefresh,
      timestamp: DateTime.now(),
      data: {
        'profile_type': profileType,
        'profile_id': profileId,
        ...?metadata,
      },
    );
    _trackEvent(event);
  }

  /// Registra um evento de compartilhamento de perfil
  void trackProfileShare(String profileType, String profileId, String shareMethod, {Map<String, dynamic>? metadata}) {
    final event = AnalyticsEvent(
      type: AnalyticsEventType.profileShare,
      timestamp: DateTime.now(),
      data: {
        'profile_type': profileType,
        'profile_id': profileId,
        'share_method': shareMethod,
        ...?metadata,
      },
    );
    _trackEvent(event);
  }

  /// Registra um evento de visualização de explicação do algoritmo
  void trackAlgorithmExplanationView(String profileType, String profileId, {Map<String, dynamic>? metadata}) {
    final event = AnalyticsEvent(
      type: AnalyticsEventType.algorithmExplanation,
      timestamp: DateTime.now(),
      data: {
        'profile_type': profileType,
        'profile_id': profileId,
        ...?metadata,
      },
    );
    _trackEvent(event);
  }

  /// Registra um evento de erro
  void trackError(String errorType, String message, {Map<String, dynamic>? metadata}) {
    final event = AnalyticsEvent(
      type: AnalyticsEventType.error,
      timestamp: DateTime.now(),
      data: {
        'error_type': errorType,
        'message': message,
        ...?metadata,
      },
    );
    _trackEvent(event);
  }

  /// Registra um evento de tempo de carregamento
  void trackLoadingTime(String screen, Duration loadingTime, {Map<String, dynamic>? metadata}) {
    final event = AnalyticsEvent(
      type: AnalyticsEventType.performance,
      timestamp: DateTime.now(),
      data: {
        'screen': screen,
        'loading_time_ms': loadingTime.inMilliseconds,
        ...?metadata,
      },
    );
    _trackEvent(event);
  }

  /// Registra um evento de busca
  void trackSearch(String query, String screen, int resultsCount, {Map<String, dynamic>? metadata}) {
    final event = AnalyticsEvent(
      type: AnalyticsEventType.search,
      timestamp: DateTime.now(),
      data: {
        'query': query,
        'screen': screen,
        'results_count': resultsCount,
        ...?metadata,
      },
    );
    _trackEvent(event);
  }

  /// Registra um evento de download de currículo
  void trackCurriculumDownload(String lawyerId, String format, {Map<String, dynamic>? metadata}) {
    final event = AnalyticsEvent(
      type: AnalyticsEventType.curriculumDownload,
      timestamp: DateTime.now(),
      data: {
        'lawyer_id': lawyerId,
        'format': format,
        ...?metadata,
      },
    );
    _trackEvent(event);
  }

  /// Registra um evento genérico de interação com UI
  void trackUIInteraction(String element, String action, {Map<String, dynamic>? metadata}) {
    final event = AnalyticsEvent(
      type: AnalyticsEventType.uiInteraction,
      timestamp: DateTime.now(),
      data: {
        'element': element,
        'action': action,
        ...?metadata,
      },
    );
    _trackEvent(event);
  }

  /// Gera relatório de métricas de uso
  AnalyticsReport generateReport({DateTime? startDate, DateTime? endDate}) {
    final filteredEvents = _events.where((event) {
      if (startDate != null && event.timestamp.isBefore(startDate)) return false;
      if (endDate != null && event.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList();

    return AnalyticsReport(
      totalEvents: filteredEvents.length,
      eventsByType: _groupEventsByType(filteredEvents),
      profileViews: _countProfileViews(filteredEvents),
      mostUsedTabs: _getMostUsedTabs(filteredEvents),
      averageLoadingTime: _calculateAverageLoadingTime(filteredEvents),
      errorRate: _calculateErrorRate(filteredEvents),
      period: DateRange(
        start: startDate ?? (filteredEvents.isNotEmpty ? filteredEvents.first.timestamp : DateTime.now()),
        end: endDate ?? (filteredEvents.isNotEmpty ? filteredEvents.last.timestamp : DateTime.now()),
      ),
    );
  }

  /// Limpa eventos antigos (manter apenas os últimos 1000)
  void _cleanupOldEvents() {
    if (_events.length > 1000) {
      _events.removeRange(0, _events.length - 1000);
    }
  }

  void _trackEvent(AnalyticsEvent event) {
    _events.add(event);
    _eventController.add(event);
    _cleanupOldEvents();
    
    // TODO: Integrar com serviços externos (Firebase, Mixpanel, etc.)
    print('Analytics Event: ${event.type.name} - ${event.data}');
  }

  Map<AnalyticsEventType, int> _groupEventsByType(List<AnalyticsEvent> events) {
    final Map<AnalyticsEventType, int> grouped = {};
    for (final event in events) {
      grouped[event.type] = (grouped[event.type] ?? 0) + 1;
    }
    return grouped;
  }

  Map<String, int> _countProfileViews(List<AnalyticsEvent> events) {
    final profileViews = events.where((e) => 
      e.type == AnalyticsEventType.lawyerProfileView || 
      e.type == AnalyticsEventType.firmProfileView
    );
    
    return {
      'lawyer_profiles': profileViews.where((e) => e.type == AnalyticsEventType.lawyerProfileView).length,
      'firm_profiles': profileViews.where((e) => e.type == AnalyticsEventType.firmProfileView).length,
    };
  }

  Map<String, int> _getMostUsedTabs(List<AnalyticsEvent> events) {
    final tabEvents = events.where((e) => e.type == AnalyticsEventType.tabNavigation);
    final Map<String, int> tabCounts = {};
    
    for (final event in tabEvents) {
      final tabName = event.data['tab_name'] as String?;
      if (tabName != null) {
        tabCounts[tabName] = (tabCounts[tabName] ?? 0) + 1;
      }
    }
    
    return tabCounts;
  }

  double _calculateAverageLoadingTime(List<AnalyticsEvent> events) {
    final performanceEvents = events.where((e) => e.type == AnalyticsEventType.performance);
    if (performanceEvents.isEmpty) return 0.0;
    
    final totalTime = performanceEvents.fold<int>(0, (sum, event) {
      return sum + (event.data['loading_time_ms'] as int? ?? 0);
    });
    
    return totalTime / performanceEvents.length;
  }

  double _calculateErrorRate(List<AnalyticsEvent> events) {
    if (events.isEmpty) return 0.0;
    final errorCount = events.where((e) => e.type == AnalyticsEventType.error).length;
    return errorCount / events.length;
  }

  void dispose() {
    _eventController.close();
  }
}

/// Tipos de eventos de analytics
enum AnalyticsEventType {
  lawyerProfileView,
  firmProfileView,
  tabNavigation,
  filterUsage,
  dataRefresh,
  profileShare,
  algorithmExplanation,
  error,
  performance,
  search,
  curriculumDownload,
  uiInteraction,
}

/// Evento de analytics
class AnalyticsEvent {
  final AnalyticsEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const AnalyticsEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  @override
  String toString() {
    return 'AnalyticsEvent(type: $type, timestamp: $timestamp, data: $data)';
  }
}

/// Relatório de analytics
class AnalyticsReport {
  final int totalEvents;
  final Map<AnalyticsEventType, int> eventsByType;
  final Map<String, int> profileViews;
  final Map<String, int> mostUsedTabs;
  final double averageLoadingTime;
  final double errorRate;
  final DateRange period;

  const AnalyticsReport({
    required this.totalEvents,
    required this.eventsByType,
    required this.profileViews,
    required this.mostUsedTabs,
    required this.averageLoadingTime,
    required this.errorRate,
    required this.period,
  });

  @override
  String toString() {
    return '''
Analytics Report (${period.start} - ${period.end}):
- Total Events: $totalEvents
- Profile Views: $profileViews
- Most Used Tabs: $mostUsedTabs
- Average Loading Time: ${averageLoadingTime.toStringAsFixed(2)}ms
- Error Rate: ${(errorRate * 100).toStringAsFixed(2)}%
- Events by Type: $eventsByType
''';
  }
}

/// Range de datas
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  @override
  String toString() => '$start to $end';
} 