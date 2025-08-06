import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Comprehensive Analytics Service for Data Flywheel Implementation
/// Captures ALL significant user interactions for continuous platform improvement
class AnalyticsService {
  static const String _eventQueueKey = 'analytics_event_queue';
  static const String _userSessionKey = 'user_session_id';
  static const String _appInstallKey = 'app_install_id';
  // Keys for future use in user flow tracking
  // static const String _userFlowKey = 'user_flow_session';
  // static const String _interactionContextKey = 'interaction_context';
  
  final SharedPreferences _prefs;
  final Connectivity _connectivity;
  late final String _sessionId;
  late final String _installId;
  late final UserFlowSession _currentFlow;
  
  // Event batching for performance
  final List<AnalyticsEvent> _eventBatch = [];
  Timer? _batchTimer;
  static const int _batchSize = 50;
  static const Duration _batchInterval = Duration(seconds: 30);
  
  static AnalyticsService? _instance;
  
  AnalyticsService._({
    required SharedPreferences prefs,
    required Connectivity connectivity,
  }) : _prefs = prefs, _connectivity = connectivity {
    _initializeSession();
    _initializeInstallId();
    _initializeUserFlow();
    _startBatchTimer();
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
  
  void _initializeUserFlow() {
    _currentFlow = UserFlowSession(
      sessionId: _sessionId,
      startTime: DateTime.now(),
    );
  }
  
  void _startBatchTimer() {
    _batchTimer = Timer.periodic(_batchInterval, (_) {
      _flushEventBatch();
    });
  }
  
  void _stopBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = null;
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

  // ========================================================================================
  // DATA FLYWHEEL: COMPREHENSIVE USER INTERACTION TRACKING
  // ========================================================================================

  /// Tracks every significant click/tap interaction
  Future<void> trackUserClick(String elementId, String context, {
    Map<String, dynamic>? additionalData,
    Duration? timeSinceLastAction,
  }) async {
    await _trackInteractionEvent('user_click', {
      'element_id': elementId,
      'context': context,
      'time_since_last_action_ms': timeSinceLastAction?.inMilliseconds,
      'flow_step': _currentFlow.currentStep,
      'session_duration_ms': DateTime.now().difference(_currentFlow.startTime).inMilliseconds,
      ...?additionalData,
    });
    
    _currentFlow.addInteraction('click', elementId, context);
  }

  /// Tracks profile views with detailed context
  Future<void> trackProfileView(String profileId, String profileType, {
    required String sourceContext, // 'search_results', 'recommendation', 'invitation', etc.
    Duration? viewDuration,
    String? searchQuery,
    double? searchRank,
    Map<String, dynamic>? searchFilters,
    String? caseContext,
  }) async {
    await _trackInteractionEvent('profile_view', {
      'profile_id': profileId,
      'profile_type': profileType, // 'lawyer', 'firm', 'case'
      'source_context': sourceContext,
      'view_duration_ms': viewDuration?.inMilliseconds,
      'search_query': searchQuery,
      'search_rank': searchRank,
      'search_filters': searchFilters,
      'case_context': caseContext,
      'viewing_user_type': _getCurrentUserType(),
      'timestamp_in_session': DateTime.now().difference(_currentFlow.startTime).inMilliseconds,
    });
    
    _currentFlow.addProfileView(profileId, profileType, sourceContext);
  }

  /// Tracks invitations sent (critical for network effects)
  Future<void> trackInvitationSent(String invitationType, String recipientId, {
    required String context, // 'case_search', 'partnership', 'direct'
    String? caseId,
    String? message,
    double? matchScore,
    String? recipientType,
    List<String>? selectedCriteria,
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackInteractionEvent('invitation_sent', {
      'invitation_type': invitationType,
      'recipient_id': recipientId,
      'recipient_type': recipientType,
      'context': context,
      'case_id': caseId,
      'message_length': message?.length,
      'match_score': matchScore,
      'selected_criteria': selectedCriteria,
      'sender_type': _getCurrentUserType(),
      'flow_context': _currentFlow.getFlowContext(),
      ...?additionalData,
    });
    
    _currentFlow.addInvitation(invitationType, recipientId, context);
  }

  /// Tracks proposal submissions
  Future<void> trackProposalSubmitted(String proposalType, String targetId, {
    required Map<String, dynamic> proposalData,
    String? caseId,
    double? proposedFee,
    Duration? timeToComplete,
    String? methodology,
  }) async {
    await _trackInteractionEvent('proposal_submitted', {
      'proposal_type': proposalType,
      'target_id': targetId,
      'case_id': caseId,
      'proposed_fee': proposedFee,
      'time_to_complete_hours': timeToComplete?.inHours,
      'methodology': methodology,
      'proposal_complexity': _calculateProposalComplexity(proposalData),
      'user_experience_level': await _getUserExperienceLevel(),
      'submission_time_in_flow': DateTime.now().difference(_currentFlow.startTime).inMilliseconds,
    });
  }

  /// Tracks message exchanges (critical for engagement)
  Future<void> trackMessageExchange(String conversationId, String messageType, {
    required String participantId,
    int? messageLength,
    bool? hasAttachment,
    String? messageCategory, // 'question', 'proposal', 'negotiation', 'update'
    Duration? responseTime,
    String? caseContext,
  }) async {
    await _trackInteractionEvent('message_exchange', {
      'conversation_id': conversationId,
      'message_type': messageType,
      'participant_id': participantId,
      'message_length': messageLength,
      'has_attachment': hasAttachment,
      'message_category': messageCategory,
      'response_time_ms': responseTime?.inMilliseconds,
      'case_context': caseContext,
      'conversation_stage': await _getConversationStage(conversationId),
      'user_engagement_score': _currentFlow.getEngagementScore(),
    });
  }

  /// Tracks transaction completions (the ultimate conversion)
  Future<void> trackTransactionCompleted(String transactionType, String transactionId, {
    required double amount,
    required String currency,
    String? caseId,
    String? partnerId,
    Duration? timeFromFirstContact,
    Map<String, dynamic>? serviceSummary,
    double? clientSatisfaction,
    double? providerSatisfaction,
  }) async {
    await _trackInteractionEvent('transaction_completed', {
      'transaction_type': transactionType,
      'transaction_id': transactionId,
      'amount': amount,
      'currency': currency,
      'case_id': caseId,
      'partner_id': partnerId,
      'time_from_first_contact_hours': timeFromFirstContact?.inHours,
      'service_summary': serviceSummary,
      'client_satisfaction': clientSatisfaction,
      'provider_satisfaction': providerSatisfaction,
      'conversion_funnel': _currentFlow.getConversionFunnel(),
      'total_interactions': _currentFlow.totalInteractions,
      'session_value': amount, // For LTV calculations
    });
    
    _currentFlow.addTransaction(transactionType, amount);
  }

  /// Tracks search behavior (input for recommendation improvement)
  Future<void> trackSearch(String searchType, String query, {
    required List<String> results,
    Map<String, dynamic>? appliedFilters,
    String? searchContext,
    Duration? searchDuration,
    int? resultClicks,
    String? selectedResultId,
  }) async {
    await _trackInteractionEvent('search_performed', {
      'search_type': searchType,
      'query': query,
      'query_length': query.length,
      'results_count': results.length,
      'applied_filters': appliedFilters,
      'search_context': searchContext,
      'search_duration_ms': searchDuration?.inMilliseconds,
      'result_clicks': resultClicks,
      'selected_result_id': selectedResultId,
      'search_success': selectedResultId != null,
      'user_intent': _inferUserIntent(searchType, query, appliedFilters),
    });
  }

  /// Tracks feedback and ratings (critical for quality improvement)
  Future<void> trackFeedback(String feedbackType, String targetId, {
    required double rating,
    String? comment,
    List<String>? tags,
    String? caseId,
    String? improvement_suggestions,
  }) async {
    await _trackInteractionEvent('feedback_submitted', {
      'feedback_type': feedbackType,
      'target_id': targetId,
      'rating': rating,
      'comment_length': comment?.length,
      'tags': tags,
      'case_id': caseId,
      'improvement_suggestions': improvement_suggestions,
      'feedback_timing': await _getFeedbackTiming(targetId),
      'user_satisfaction_trend': await _getUserSatisfactionTrend(),
    });
  }

  /// Tracks content engagement (documents, guides, etc.)
  Future<void> trackContentEngagement(String contentId, String contentType, {
    required String action, // 'view', 'download', 'share', 'bookmark'
    Duration? engagementTime,
    double? scrollPercentage,
    String? sourceContext,
  }) async {
    await _trackInteractionEvent('content_engagement', {
      'content_id': contentId,
      'content_type': contentType,
      'action': action,
      'engagement_time_ms': engagementTime?.inMilliseconds,
      'scroll_percentage': scrollPercentage,
      'source_context': sourceContext,
      'content_value_score': await _getContentValueScore(contentId, action),
    });
  }

  /// Tracks onboarding progress (critical for user activation)
  Future<void> trackOnboardingStep(String stepId, String stepName, {
    required bool completed,
    Duration? timeSpent,
    int? attemptNumber,
    String? dropOffReason,
    Map<String, dynamic>? stepData,
  }) async {
    await _trackInteractionEvent('onboarding_step', {
      'step_id': stepId,
      'step_name': stepName,
      'completed': completed,
      'time_spent_ms': timeSpent?.inMilliseconds,
      'attempt_number': attemptNumber,
      'drop_off_reason': dropOffReason,
      'step_data': stepData,
      'onboarding_progress': await _getOnboardingProgress(),
      'user_activation_score': _calculateActivationScore(),
    });
  }

  // ========================================================================================
  // ADVANCED TRACKING METHODS
  // ========================================================================================

  Future<void> _trackInteractionEvent(String eventName, Map<String, dynamic> properties) async {
    final enhancedProperties = {
      ...properties,
      'session_id': _sessionId,
      'install_id': _installId,
      'user_flow_context': _currentFlow.toJson(),
      'device_info': await _getDeviceInfo(),
      'app_version': await _getAppVersion(),
      'network_quality': await _getNetworkQuality(),
      'timestamp_iso': DateTime.now().toIso8601String(),
    };

    final event = AnalyticsEvent(
      name: eventName,
      properties: enhancedProperties,
      timestamp: DateTime.now(),
      sessionId: _sessionId,
      installId: _installId,
    );

    await _addToBatch(event);
  }

  Future<void> _addToBatch(AnalyticsEvent event) async {
    _eventBatch.add(event);
    
    // Flush batch if it reaches max size
    if (_eventBatch.length >= _batchSize) {
      await _flushEventBatch();
    }
  }

  Future<void> _flushEventBatch() async {
    if (_eventBatch.isEmpty) return;
    
    try {
      final events = List<AnalyticsEvent>.from(_eventBatch);
      _eventBatch.clear();
      
      await _sendEventBatch(events);
    } catch (e) {
      print('📊 ERROR: Failed to flush event batch: $e');
      // Re-add events to queue for retry
      await _queueEvents(_eventBatch);
    }
  }

  Future<void> _sendEventBatch(List<AnalyticsEvent> events) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    
    if (connectivityResult.contains(ConnectivityResult.none)) {
      await _queueEvents(events);
      return;
    }

    try {
      // Send to backend analytics endpoint
      final response = await http.post(
        Uri.parse('${_getBackendUrl()}/api/analytics/events/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'events': events.map((e) => e.toJson()).toList(),
          'session_meta': {
            'session_id': _sessionId,
            'install_id': _installId,
            'batch_timestamp': DateTime.now().toIso8601String(),
          }
        }),
      );

      if (response.statusCode == 200) {
        print('📊 SUCCESS: Sent ${events.length} events to analytics service');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('📊 ERROR: Failed to send events to backend: $e');
      await _queueEvents(events);
    }
  }

  // ========================================================================================
  // HELPER METHODS FOR CONTEXT ENRICHMENT
  // ========================================================================================

  String _getCurrentUserType() {
    // TODO: Implement based on current user context
    return 'unknown';
  }

  double _calculateProposalComplexity(Map<String, dynamic> proposalData) {
    // Simple complexity scoring based on data richness
    int score = 0;
    score += proposalData.keys.length * 10;
    score += proposalData.toString().length ~/ 100;
    return (score / 100.0).clamp(0.0, 1.0);
  }

  Future<String> _getUserExperienceLevel() async {
    // TODO: Implement based on user profile data
    return 'intermediate';
  }

  Future<String> _getConversationStage(String conversationId) async {
    // TODO: Implement conversation stage detection
    return 'active';
  }

  String _inferUserIntent(String searchType, String query, Map<String, dynamic>? filters) {
    // Simple intent inference - can be made more sophisticated
    if (query.toLowerCase().contains('urgent')) return 'urgent_need';
    if (filters?.isNotEmpty == true) return 'specific_criteria';
    if (searchType == 'lawyer') return 'find_representation';
    return 'exploration';
  }

  Future<String> _getFeedbackTiming(String targetId) async {
    // TODO: Implement timing analysis
    return 'post_interaction';
  }

  Future<double> _getUserSatisfactionTrend() async {
    // TODO: Implement satisfaction trend analysis
    return 0.8;
  }

  Future<double> _getContentValueScore(String contentId, String action) async {
    // TODO: Implement content value scoring
    return 0.7;
  }

  Future<double> _getOnboardingProgress() async {
    // TODO: Implement onboarding progress tracking
    return 0.5;
  }

  double _calculateActivationScore() {
    // Simple activation score based on interactions
    return (_currentFlow.totalInteractions / 10.0).clamp(0.0, 1.0);
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // TODO: Implement device info collection
    return {'platform': 'flutter', 'type': 'mobile'};
  }

  Future<String> _getAppVersion() async {
    // TODO: Implement app version detection
    return '1.0.0';
  }

  Future<String> _getNetworkQuality() async {
    // TODO: Implement network quality assessment
    return 'good';
  }

  String _getBackendUrl() {
    // TODO: Get from environment configuration
    return 'http://localhost:8000';
  }

  Future<void> _queueEvents(List<AnalyticsEvent> events) async {
    final existingQueue = await _getEventQueue();
    existingQueue.addAll(events);
    await _saveEventQueue(existingQueue);
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
    _stopBatchTimer();
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

// ========================================================================================
// USER FLOW TRACKING CLASSES
// ========================================================================================

class UserFlowSession {
  final String sessionId;
  final DateTime startTime;
  String currentStep = 'app_start';
  int totalInteractions = 0;
  double sessionValue = 0.0;
  
  final List<UserInteraction> _interactions = [];
  final List<ProfileView> _profileViews = [];
  final List<InvitationEvent> _invitations = [];
  final List<TransactionEvent> _transactions = [];
  
  UserFlowSession({
    required this.sessionId,
    required this.startTime,
  });
  
  void addInteraction(String type, String elementId, String context) {
    _interactions.add(UserInteraction(
      type: type,
      elementId: elementId,
      context: context,
      timestamp: DateTime.now(),
    ));
    totalInteractions++;
  }
  
  void addProfileView(String profileId, String profileType, String source) {
    _profileViews.add(ProfileView(
      profileId: profileId,
      profileType: profileType,
      source: source,
      timestamp: DateTime.now(),
    ));
  }
  
  void addInvitation(String type, String recipientId, String context) {
    _invitations.add(InvitationEvent(
      type: type,
      recipientId: recipientId,
      context: context,
      timestamp: DateTime.now(),
    ));
  }
  
  void addTransaction(String type, double amount) {
    _transactions.add(TransactionEvent(
      type: type,
      amount: amount,
      timestamp: DateTime.now(),
    ));
    sessionValue += amount;
  }
  
  Map<String, dynamic> getFlowContext() {
    return {
      'current_step': currentStep,
      'total_interactions': totalInteractions,
      'session_duration_ms': DateTime.now().difference(startTime).inMilliseconds,
      'profile_views_count': _profileViews.length,
      'invitations_sent': _invitations.length,
      'transactions_count': _transactions.length,
      'session_value': sessionValue,
    };
  }
  
  double getEngagementScore() {
    final duration = DateTime.now().difference(startTime);
    final engagementRate = totalInteractions / (duration.inMinutes + 1);
    return (engagementRate / 5.0).clamp(0.0, 1.0); // Normalize to 0-1
  }
  
  List<String> getConversionFunnel() {
    List<String> funnel = ['app_start'];
    
    if (_profileViews.isNotEmpty) funnel.add('profile_view');
    if (_invitations.isNotEmpty) funnel.add('invitation_sent');
    if (_transactions.isNotEmpty) funnel.add('transaction_completed');
    
    return funnel;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'start_time': startTime.toIso8601String(),
      'current_step': currentStep,
      'total_interactions': totalInteractions,
      'session_value': sessionValue,
      'interactions': _interactions.map((i) => i.toJson()).toList(),
      'profile_views': _profileViews.map((p) => p.toJson()).toList(),
      'invitations': _invitations.map((i) => i.toJson()).toList(),
      'transactions': _transactions.map((t) => t.toJson()).toList(),
    };
  }
}

class UserInteraction {
  final String type;
  final String elementId;
  final String context;
  final DateTime timestamp;
  
  UserInteraction({
    required this.type,
    required this.elementId,
    required this.context,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'element_id': elementId,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ProfileView {
  final String profileId;
  final String profileType;
  final String source;
  final DateTime timestamp;
  
  ProfileView({
    required this.profileId,
    required this.profileType,
    required this.source,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'profile_type': profileType,
      'source': source,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class InvitationEvent {
  final String type;
  final String recipientId;
  final String context;
  final DateTime timestamp;
  
  InvitationEvent({
    required this.type,
    required this.recipientId,
    required this.context,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'recipient_id': recipientId,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class TransactionEvent {
  final String type;
  final double amount;
  final DateTime timestamp;
  
  TransactionEvent({
    required this.type,
    required this.amount,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}