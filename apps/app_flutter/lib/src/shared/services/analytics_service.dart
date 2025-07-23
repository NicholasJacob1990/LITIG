import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AnalyticsService {
  static const String _eventQueueKey = 'analytics_event_queue';
  static const String _userSessionKey = 'user_session_id';
  static const String _appInstallKey = 'app_install_id';
  
  final SharedPreferences _prefs;
  final Connectivity _connectivity;
  late final String _sessionId;
  late final String _installId;
  
  static AnalyticsService? _instance;
  
  AnalyticsService._({
    required SharedPreferences prefs,
    required Connectivity connectivity,
  }) : _prefs = prefs, _connectivity = connectivity {
    _initializeSession();
    _initializeInstallId();
  }
  
  static Future<AnalyticsService> getInstance() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      final connectivity = Connectivity();
      _instance = AnalyticsService._(prefs: prefs, connectivity: connectivity);
    }
    return _instance!;
  }
  
  void _initializeSession() {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _prefs.setString(_userSessionKey, _sessionId);
  }
  
  void _initializeInstallId() {
    String? existingId = _prefs.getString(_appInstallKey);
    if (existingId == null) {
      _installId = 'install_${DateTime.now().millisecondsSinceEpoch}';
      _prefs.setString(_appInstallKey, _installId);
    } else {
      _installId = existingId;
    }
  }
  
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? properties}) async {
    final event = AnalyticsEvent(
      name: eventName,
      properties: properties ?? {},
      timestamp: DateTime.now(),
      sessionId: _sessionId,
      installId: _installId,
    );
    
    await _queueEvent(event);
    await _attemptToSendEvents();
  }
  
  Future<void> trackScreenView(String screenName, {Map<String, dynamic>? properties}) async {
    await trackEvent('screen_view', properties: {
      'screen_name': screenName,
      ...?properties,
    });
  }
  
  Future<void> trackUserAction(String action, {Map<String, dynamic>? properties}) async {
    await trackEvent('user_action', properties: {
      'action': action,
      ...?properties,
    });
  }
  
  Future<void> trackError(String error, {String? stackTrace, Map<String, dynamic>? properties}) async {
    await trackEvent('error_occurred', properties: {
      'error_message': error,
      'stack_trace': stackTrace,
      ...?properties,
    });
  }
  
  Future<void> trackFeatureUsage(String feature, {Map<String, dynamic>? properties}) async {
    await trackEvent('feature_used', properties: {
      'feature_name': feature,
      ...?properties,
    });
  }
  
  Future<void> trackPerformance(String operation, Duration duration, {Map<String, dynamic>? properties}) async {
    await trackEvent('performance_metric', properties: {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'duration_readable': duration.toString(),
      ...?properties,
    });
  }
  
  Future<void> trackBusinessMetric(String metricName, dynamic value, {Map<String, dynamic>? properties}) async {
    await trackEvent('business_metric', properties: {
      'metric_name': metricName,
      'metric_value': value,
      ...?properties,
    });
  }
  
  Future<void> _queueEvent(AnalyticsEvent event) async {
    final queue = await _getEventQueue();
    queue.add(event);
    await _saveEventQueue(queue);
  }
  
  Future<List<AnalyticsEvent>> _getEventQueue() async {
    final queueJson = _prefs.getStringList(_eventQueueKey) ?? [];
    return queueJson.map((eventJson) => AnalyticsEvent.fromJson(jsonDecode(eventJson))).toList();
  }
  
  Future<void> _saveEventQueue(List<AnalyticsEvent> queue) async {
    final queueJson = queue.map((event) => jsonEncode(event.toJson())).toList();
    await _prefs.setStringList(_eventQueueKey, queueJson);
  }
  
  Future<void> _attemptToSendEvents() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return;
    }
    
    final queue = await _getEventQueue();
    if (queue.isEmpty) return;
    
    try {
      await _sendEventsToBackend(queue);
      await _clearEventQueue();
    } catch (e) {
      // Keep events in queue for retry
      await trackError('Failed to send analytics events', properties: {'error': e.toString()});
    }
  }
  
  Future<void> _sendEventsToBackend(List<AnalyticsEvent> events) async {
    // Mock implementation - in real app, send to analytics service
    await Future.delayed(const Duration(milliseconds: 500));
    
    print('📊 ANALYTICS: Sending ${events.length} events to backend');
    for (final event in events) {
      print('  - ${event.name}: ${event.properties}');
    }
  }
  
  Future<void> _clearEventQueue() async {
    await _prefs.remove(_eventQueueKey);
  }
  
  Future<void> flushEvents() async {
    await _attemptToSendEvents();
  }
  
  Future<AnalyticsStats> getStats() async {
    final queue = await _getEventQueue();
    final sentEvents = _prefs.getInt('analytics_sent_events') ?? 0;
    
    return AnalyticsStats(
      queuedEvents: queue.length,
      sentEvents: sentEvents,
      sessionId: _sessionId,
      installId: _installId,
    );
  }
  
  Future<void> clearAllData() async {
    await _prefs.remove(_eventQueueKey);
    await _prefs.remove(_userSessionKey);
    await _prefs.remove(_appInstallKey);
  }
}

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String sessionId;
  final String installId;
  
  const AnalyticsEvent({
    required this.name,
    required this.properties,
    required this.timestamp,
    required this.sessionId,
    required this.installId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'properties': properties,
      'timestamp': timestamp.toIso8601String(),
      'session_id': sessionId,
      'install_id': installId,
    };
  }
  
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      name: json['name'],
      properties: Map<String, dynamic>.from(json['properties']),
      timestamp: DateTime.parse(json['timestamp']),
      sessionId: json['session_id'],
      installId: json['install_id'],
    );
  }
}

class AnalyticsStats {
  final int queuedEvents;
  final int sentEvents;
  final String sessionId;
  final String installId;
  
  const AnalyticsStats({
    required this.queuedEvents,
    required this.sentEvents,
    required this.sessionId,
    required this.installId,
  });
}