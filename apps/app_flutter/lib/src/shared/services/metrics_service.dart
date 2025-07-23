import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'analytics_service.dart';

class MetricsService {
  static const String _metricsKey = 'app_metrics';
  
  final SharedPreferences _prefs;
  final AnalyticsService _analytics;
  late final DeviceInfo _deviceInfo;
  late final PackageInfo _packageInfo;
  
  static MetricsService? _instance;
  
  MetricsService._({
    required SharedPreferences prefs,
    required AnalyticsService analytics,
  }) : _prefs = prefs, _analytics = analytics;
  
  static Future<MetricsService> getInstance() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      final analytics = await AnalyticsService.getInstance();
      _instance = MetricsService._(prefs: prefs, analytics: analytics);
      await _instance!._initialize();
    }
    return _instance!;
  }
  
  Future<void> _initialize() async {
    _deviceInfo = await _getDeviceInfo();
    _packageInfo = await PackageInfo.fromPlatform();
  }
  
  Future<DeviceInfo> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return DeviceInfo(
        platform: 'Android',
        version: androidInfo.version.release,
        model: androidInfo.model,
        manufacturer: androidInfo.manufacturer,
        identifier: androidInfo.id,
      );
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      return DeviceInfo(
        platform: 'iOS',
        version: iosInfo.systemVersion,
        model: iosInfo.model,
        manufacturer: 'Apple',
        identifier: iosInfo.identifierForVendor ?? 'unknown',
      );
    } else {
      return const DeviceInfo(
        platform: 'Unknown',
        version: 'Unknown',
        model: 'Unknown',
        manufacturer: 'Unknown',
        identifier: 'unknown',
      );
    }
  }
  
  // Performance Metrics
  Future<void> trackAppLaunch() async {
    final metrics = await _getMetrics();
    metrics.appLaunches++;
    metrics.lastLaunchTime = DateTime.now();
    await _saveMetrics(metrics);
    
    await _analytics.trackEvent('app_launch', properties: {
      'launch_count': metrics.appLaunches,
      'device': _deviceInfo.toJson(),
      'app_version': _packageInfo.version,
    });
  }
  
  Future<void> trackScreenTime(String screenName, Duration timeSpent) async {
    final metrics = await _getMetrics();
    metrics.screenTimeData[screenName] = (metrics.screenTimeData[screenName] ?? Duration.zero) + timeSpent;
    await _saveMetrics(metrics);
    
    await _analytics.trackPerformance('screen_time', timeSpent, properties: {
      'screen_name': screenName,
      'total_time_on_screen': metrics.screenTimeData[screenName]!.inSeconds,
    });
  }
  
  Future<void> trackAPICall(String endpoint, Duration responseTime, bool success, {String? errorMessage}) async {
    final metrics = await _getMetrics();
    
    if (success) {
      metrics.apiCallsSuccess++;
    } else {
      metrics.apiCallsFailed++;
    }
    
    metrics.apiResponseTimes[endpoint] = responseTime;
    await _saveMetrics(metrics);
    
    await _analytics.trackPerformance('api_call', responseTime, properties: {
      'endpoint': endpoint,
      'success': success,
      'error_message': errorMessage,
      'total_success': metrics.apiCallsSuccess,
      'total_failed': metrics.apiCallsFailed,
    });
  }
  
  Future<void> trackMemoryUsage(int memoryMB) async {
    final metrics = await _getMetrics();
    metrics.peakMemoryUsage = memoryMB > metrics.peakMemoryUsage ? memoryMB : metrics.peakMemoryUsage;
    await _saveMetrics(metrics);
    
    await _analytics.trackBusinessMetric('memory_usage', memoryMB, properties: {
      'peak_memory': metrics.peakMemoryUsage,
    });
  }
  
  // Business Metrics
  Future<void> trackFeatureAdoption(String featureName) async {
    final metrics = await _getMetrics();
    metrics.featureUsage[featureName] = (metrics.featureUsage[featureName] ?? 0) + 1;
    await _saveMetrics(metrics);
    
    await _analytics.trackFeatureUsage(featureName, properties: {
      'usage_count': metrics.featureUsage[featureName],
    });
  }
  
  Future<void> trackUserFlow(String flowName, String stepName, {Map<String, dynamic>? additionalData}) async {
    final metrics = await _getMetrics();
    
    final flowKey = '${flowName}_$stepName';
    metrics.userFlowSteps[flowKey] = (metrics.userFlowSteps[flowKey] ?? 0) + 1;
    await _saveMetrics(metrics);
    
    await _analytics.trackUserAction('user_flow_step', properties: {
      'flow_name': flowName,
      'step_name': stepName,
      'step_count': metrics.userFlowSteps[flowKey],
      ...?additionalData,
    });
  }
  
  Future<void> trackConversion(String conversionType, String fromState, String toState, {Map<String, dynamic>? metadata}) async {
    final metrics = await _getMetrics();
    metrics.conversions[conversionType] = (metrics.conversions[conversionType] ?? 0) + 1;
    await _saveMetrics(metrics);
    
    await _analytics.trackBusinessMetric('conversion', 1, properties: {
      'conversion_type': conversionType,
      'from_state': fromState,
      'to_state': toState,
      'total_conversions': metrics.conversions[conversionType],
      ...?metadata,
    });
  }
  
  // Error Tracking
  Future<void> trackCrash(String crashReason, String stackTrace, {Map<String, dynamic>? context}) async {
    final metrics = await _getMetrics();
    metrics.crashCount++;
    metrics.lastCrashTime = DateTime.now();
    await _saveMetrics(metrics);
    
    await _analytics.trackError('app_crash', stackTrace: stackTrace, properties: {
      'crash_reason': crashReason,
      'total_crashes': metrics.crashCount,
      'device': _deviceInfo.toJson(),
      ...?context,
    });
  }
  
  Future<void> trackError(String errorType, String errorMessage, {String? stackTrace, Map<String, dynamic>? context}) async {
    final metrics = await _getMetrics();
    metrics.errorCount++;
    await _saveMetrics(metrics);
    
    await _analytics.trackError(errorMessage, stackTrace: stackTrace, properties: {
      'error_type': errorType,
      'total_errors': metrics.errorCount,
      ...?context,
    });
  }
  
  // User Engagement
  Future<void> trackSessionLength(Duration sessionLength) async {
    final metrics = await _getMetrics();
    metrics.sessionCount++;
    metrics.totalSessionTime += sessionLength;
    metrics.averageSessionLength = Duration(
      milliseconds: metrics.totalSessionTime.inMilliseconds ~/ metrics.sessionCount,
    );
    await _saveMetrics(metrics);
    
    await _analytics.trackBusinessMetric('session_length', sessionLength.inMinutes, properties: {
      'session_count': metrics.sessionCount,
      'average_session_minutes': metrics.averageSessionLength.inMinutes,
    });
  }
  
  Future<void> trackRetention(int daysSinceInstall) async {
    await _analytics.trackBusinessMetric('user_retention', daysSinceInstall, properties: {
      'days_since_install': daysSinceInstall,
      'device': _deviceInfo.toJson(),
    });
  }
  
  // Data Management
  Future<AppMetrics> _getMetrics() async {
    final metricsJson = _prefs.getString(_metricsKey);
    if (metricsJson == null) {
      return AppMetrics();
    }
    
    try {
      return AppMetrics.fromJson(jsonDecode(metricsJson));
    } catch (e) {
      return AppMetrics();
    }
  }
  
  Future<void> _saveMetrics(AppMetrics metrics) async {
    await _prefs.setString(_metricsKey, jsonEncode(metrics.toJson()));
  }
  
  Future<AppMetrics> getMetrics() async {
    return await _getMetrics();
  }
  
  Future<Map<String, dynamic>> getMetricsReport() async {
    final metrics = await _getMetrics();
    
    return {
      'device_info': _deviceInfo.toJson(),
      'app_info': {
        'version': _packageInfo.version,
        'build_number': _packageInfo.buildNumber,
        'package_name': _packageInfo.packageName,
      },
      'performance': {
        'app_launches': metrics.appLaunches,
        'session_count': metrics.sessionCount,
        'average_session_minutes': metrics.averageSessionLength.inMinutes,
        'peak_memory_mb': metrics.peakMemoryUsage,
        'api_success_rate': metrics.apiCallsSuccess / (metrics.apiCallsSuccess + metrics.apiCallsFailed) * 100,
      },
      'engagement': {
        'feature_usage': metrics.featureUsage,
        'screen_time': metrics.screenTimeData.map((k, v) => MapEntry(k, v.inMinutes)),
        'user_flow_completions': metrics.userFlowSteps,
      },
      'reliability': {
        'crash_count': metrics.crashCount,
        'error_count': metrics.errorCount,
        'last_crash': metrics.lastCrashTime?.toIso8601String(),
      },
      'business': {
        'conversions': metrics.conversions,
        'conversion_rate': _calculateOverallConversionRate(metrics),
      },
    };
  }
  
  double _calculateOverallConversionRate(AppMetrics metrics) {
    if (metrics.appLaunches == 0) return 0.0;
    
    final totalConversions = metrics.conversions.values.fold(0, (sum, count) => sum + count);
    return totalConversions / metrics.appLaunches * 100;
  }
  
  Future<void> clearMetrics() async {
    await _prefs.remove(_metricsKey);
  }
}

class AppMetrics {
  int appLaunches;
  int sessionCount;
  Duration totalSessionTime;
  Duration averageSessionLength;
  DateTime? lastLaunchTime;
  
  Map<String, Duration> screenTimeData;
  Map<String, int> featureUsage;
  Map<String, int> userFlowSteps;
  Map<String, int> conversions;
  
  int apiCallsSuccess;
  int apiCallsFailed;
  Map<String, Duration> apiResponseTimes;
  
  int peakMemoryUsage;
  int crashCount;
  int errorCount;
  DateTime? lastCrashTime;
  
  AppMetrics({
    this.appLaunches = 0,
    this.sessionCount = 0,
    this.totalSessionTime = Duration.zero,
    this.averageSessionLength = Duration.zero,
    this.lastLaunchTime,
    Map<String, Duration>? screenTimeData,
    Map<String, int>? featureUsage,
    Map<String, int>? userFlowSteps,
    Map<String, int>? conversions,
    this.apiCallsSuccess = 0,
    this.apiCallsFailed = 0,
    Map<String, Duration>? apiResponseTimes,
    this.peakMemoryUsage = 0,
    this.crashCount = 0,
    this.errorCount = 0,
    this.lastCrashTime,
  }) : screenTimeData = screenTimeData ?? {},
       featureUsage = featureUsage ?? {},
       userFlowSteps = userFlowSteps ?? {},
       conversions = conversions ?? {},
       apiResponseTimes = apiResponseTimes ?? {};
  
  Map<String, dynamic> toJson() {
    return {
      'app_launches': appLaunches,
      'session_count': sessionCount,
      'total_session_time_ms': totalSessionTime.inMilliseconds,
      'average_session_length_ms': averageSessionLength.inMilliseconds,
      'last_launch_time': lastLaunchTime?.toIso8601String(),
      'screen_time_data': screenTimeData.map((k, v) => MapEntry(k, v.inMilliseconds)),
      'feature_usage': featureUsage,
      'user_flow_steps': userFlowSteps,
      'conversions': conversions,
      'api_calls_success': apiCallsSuccess,
      'api_calls_failed': apiCallsFailed,
      'api_response_times': apiResponseTimes.map((k, v) => MapEntry(k, v.inMilliseconds)),
      'peak_memory_usage': peakMemoryUsage,
      'crash_count': crashCount,
      'error_count': errorCount,
      'last_crash_time': lastCrashTime?.toIso8601String(),
    };
  }
  
  factory AppMetrics.fromJson(Map<String, dynamic> json) {
    return AppMetrics(
      appLaunches: json['app_launches'] ?? 0,
      sessionCount: json['session_count'] ?? 0,
      totalSessionTime: Duration(milliseconds: json['total_session_time_ms'] ?? 0),
      averageSessionLength: Duration(milliseconds: json['average_session_length_ms'] ?? 0),
      lastLaunchTime: json['last_launch_time'] != null ? DateTime.parse(json['last_launch_time']) : null,
      screenTimeData: (json['screen_time_data'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, Duration(milliseconds: v)),
      ) ?? {},
      featureUsage: Map<String, int>.from(json['feature_usage'] ?? {}),
      userFlowSteps: Map<String, int>.from(json['user_flow_steps'] ?? {}),
      conversions: Map<String, int>.from(json['conversions'] ?? {}),
      apiCallsSuccess: json['api_calls_success'] ?? 0,
      apiCallsFailed: json['api_calls_failed'] ?? 0,
      apiResponseTimes: (json['api_response_times'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, Duration(milliseconds: v)),
      ) ?? {},
      peakMemoryUsage: json['peak_memory_usage'] ?? 0,
      crashCount: json['crash_count'] ?? 0,
      errorCount: json['error_count'] ?? 0,
      lastCrashTime: json['last_crash_time'] != null ? DateTime.parse(json['last_crash_time']) : null,
    );
  }
}

class DeviceInfo {
  final String platform;
  final String version;
  final String model;
  final String manufacturer;
  final String identifier;
  
  const DeviceInfo({
    required this.platform,
    required this.version,
    required this.model,
    required this.manufacturer,
    required this.identifier,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'version': version,
      'model': model,
      'manufacturer': manufacturer,
      'identifier': identifier,
    };
  }
}