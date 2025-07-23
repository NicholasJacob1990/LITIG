import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'analytics_service.dart';

enum LogLevel { debug, info, warning, error, critical }

class LoggerService {
  static const String _logQueueKey = 'logger_queue';
  static const int _maxLocalLogs = 1000;
  static const int _maxLogFileSize = 5 * 1024 * 1024; // 5MB
  
  final SharedPreferences _prefs;
  final AnalyticsService _analytics;
  late final File _logFile;
  
  static LoggerService? _instance;
  
  LoggerService._({
    required SharedPreferences prefs,
    required AnalyticsService analytics,
  }) : _prefs = prefs, _analytics = analytics;
  
  static Future<LoggerService> getInstance() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      final analytics = await AnalyticsService.getInstance();
      _instance = LoggerService._(prefs: prefs, analytics: analytics);
      await _instance!._initializeLogFile();
    }
    return _instance!;
  }
  
  Future<void> _initializeLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final logDir = Directory('${directory.path}/logs');
    
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    
    final logFileName = 'app_${DateTime.now().toIso8601String().split('T')[0]}.log';
    _logFile = File('${logDir.path}/$logFileName');
    
    // Rotate log files if current one is too large
    await _rotateLogFileIfNeeded();
  }
  
  Future<void> _rotateLogFileIfNeeded() async {
    if (await _logFile.exists()) {
      final size = await _logFile.length();
      if (size > _maxLogFileSize) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final backupFile = File('${_logFile.path}.$timestamp.bak');
        await _logFile.rename(backupFile.path);
        
        // Clean old backup files (keep only last 5)
        await _cleanOldLogFiles();
      }
    }
  }
  
  Future<void> _cleanOldLogFiles() async {
    final logDir = _logFile.parent;
    final files = await logDir.list().where((entity) => 
      entity is File && entity.path.endsWith('.bak')
    ).cast<File>().toList();
    
    if (files.length > 5) {
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      for (int i = 0; i < files.length - 5; i++) {
        await files[i].delete();
      }
    }
  }
  
  // Main logging methods
  Future<void> debug(String message, {Map<String, dynamic>? context}) async {
    await _log(LogLevel.debug, message, context: context);
  }
  
  Future<void> info(String message, {Map<String, dynamic>? context}) async {
    await _log(LogLevel.info, message, context: context);
  }
  
  Future<void> warning(String message, {Map<String, dynamic>? context, String? stackTrace}) async {
    await _log(LogLevel.warning, message, context: context, stackTrace: stackTrace);
  }
  
  Future<void> error(String message, {dynamic error, String? stackTrace, Map<String, dynamic>? context}) async {
    final contextWithError = {
      ...?context,
      if (error != null) 'error_object': error.toString(),
    };
    
    await _log(LogLevel.error, message, context: contextWithError, stackTrace: stackTrace);
    
    // Also track in analytics for error monitoring
    await _analytics.trackError(message, stackTrace: stackTrace, properties: contextWithError);
  }
  
  Future<void> critical(String message, {dynamic error, String? stackTrace, Map<String, dynamic>? context}) async {
    final contextWithError = {
      ...?context,
      if (error != null) 'error_object': error.toString(),
    };
    
    await _log(LogLevel.critical, message, context: contextWithError, stackTrace: stackTrace);
    
    // Critical errors should be tracked immediately
    await _analytics.trackError('CRITICAL: $message', stackTrace: stackTrace, properties: contextWithError);
  }
  
  // Structured logging methods
  Future<void> logApiCall(String endpoint, String method, int statusCode, Duration duration, {Map<String, dynamic>? context}) async {
    await info('API Call', context: {
      'endpoint': endpoint,
      'method': method,
      'status_code': statusCode,
      'duration_ms': duration.inMilliseconds,
      'success': statusCode >= 200 && statusCode < 300,
      ...?context,
    });
  }
  
  Future<void> logUserAction(String action, String screen, {Map<String, dynamic>? context}) async {
    await info('User Action', context: {
      'action': action,
      'screen': screen,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    });
  }
  
  Future<void> logPerformance(String operation, Duration duration, {Map<String, dynamic>? context}) async {
    await info('Performance Metric', context: {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'duration_readable': _formatDuration(duration),
      ...?context,
    });
  }
  
  Future<void> logBusinessEvent(String eventType, Map<String, dynamic> data) async {
    await info('Business Event', context: {
      'event_type': eventType,
      'event_data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> logNavigation(String from, String to, {Map<String, dynamic>? context}) async {
    await debug('Navigation', context: {
      'from': from,
      'to': to,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    });
  }
  
  Future<void> logCacheOperation(String operation, String key, bool hit, {Map<String, dynamic>? context}) async {
    await debug('Cache Operation', context: {
      'operation': operation,
      'key': key,
      'cache_hit': hit,
      ...?context,
    });
  }
  
  Future<void> logDatabaseOperation(String operation, String table, Duration duration, {Map<String, dynamic>? context}) async {
    await debug('Database Operation', context: {
      'operation': operation,
      'table': table,
      'duration_ms': duration.inMilliseconds,
      ...?context,
    });
  }
  
  // Core logging implementation
  Future<void> _log(LogLevel level, String message, {Map<String, dynamic>? context, String? stackTrace}) async {
    final logEntry = LogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
      context: context ?? {},
      stackTrace: stackTrace,
    );
    
    // Console logging in debug mode
    if (kDebugMode) {
      _printToConsole(logEntry);
    }
    
    // Write to file
    await _writeToFile(logEntry);
    
    // Queue for remote sending (for warnings and above)
    if (level.index >= LogLevel.warning.index) {
      await _queueForRemote(logEntry);
    }
  }
  
  void _printToConsole(LogEntry entry) {
    final prefix = _getLevelEmoji(entry.level);
    final timestamp = entry.timestamp.toIso8601String();
    final contextStr = entry.context.isNotEmpty ? '\n  Context: ${jsonEncode(entry.context)}' : '';
    final stackStr = entry.stackTrace != null ? '\n  Stack: ${entry.stackTrace}' : '';
    
    print('$prefix [$timestamp] ${entry.message}$contextStr$stackStr');
  }
  
  String _getLevelEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return '🐛';
      case LogLevel.info: return 'ℹ️';
      case LogLevel.warning: return '⚠️';
      case LogLevel.error: return '❌';
      case LogLevel.critical: return '🚨';
    }
  }
  
  Future<void> _writeToFile(LogEntry entry) async {
    try {
      final logLine = '${entry.timestamp.toIso8601String()} [${entry.level.name.toUpperCase()}] ${entry.message}';
      final contextLine = entry.context.isNotEmpty ? '\n  Context: ${jsonEncode(entry.context)}' : '';
      final stackLine = entry.stackTrace != null ? '\n  Stack: ${entry.stackTrace}' : '';
      
      await _logFile.writeAsString('$logLine$contextLine$stackLine\n', mode: FileMode.append);
      
      // Rotate if needed
      await _rotateLogFileIfNeeded();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao escrever log no arquivo: $e');
      }
    }
  }
  
  Future<void> _queueForRemote(LogEntry entry) async {
    try {
      final queue = await _getLogQueue();
      queue.add(entry);
      
      // Limit queue size
      if (queue.length > _maxLocalLogs) {
        queue.removeRange(0, queue.length - _maxLocalLogs);
      }
      
      await _saveLogQueue(queue);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao adicionar log à fila: $e');
      }
    }
  }
  
  Future<List<LogEntry>> _getLogQueue() async {
    final queueJson = _prefs.getStringList(_logQueueKey) ?? [];
    return queueJson.map((entryJson) => LogEntry.fromJson(jsonDecode(entryJson))).toList();
  }
  
  Future<void> _saveLogQueue(List<LogEntry> queue) async {
    final queueJson = queue.map((entry) => jsonEncode(entry.toJson())).toList();
    await _prefs.setStringList(_logQueueKey, queueJson);
  }
  
  // Utility methods
  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }
  
  // Log management
  Future<List<LogEntry>> getRecentLogs({int limit = 100, LogLevel? minLevel}) async {
    final queue = await _getLogQueue();
    
    var filteredLogs = queue;
    if (minLevel != null) {
      filteredLogs = queue.where((log) => log.level.index >= minLevel.index).toList();
    }
    
    return filteredLogs.reversed.take(limit).toList();
  }
  
  Future<String> getLogsAsString({int limit = 100, LogLevel? minLevel}) async {
    final logs = await getRecentLogs(limit: limit, minLevel: minLevel);
    return logs.map((log) => 
      '${log.timestamp.toIso8601String()} [${log.level.name.toUpperCase()}] ${log.message}'
    ).join('\n');
  }
  
  Future<File> exportLogsToFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportFile = File('${directory.path}/exported_logs_${DateTime.now().millisecondsSinceEpoch}.log');
    
    final logs = await getRecentLogs(limit: _maxLocalLogs);
    final content = logs.map((log) {
      final contextStr = log.context.isNotEmpty ? '\n  Context: ${jsonEncode(log.context)}' : '';
      final stackStr = log.stackTrace != null ? '\n  Stack: ${log.stackTrace}' : '';
      return '${log.timestamp.toIso8601String()} [${log.level.name.toUpperCase()}] ${log.message}$contextStr$stackStr';
    }).join('\n');
    
    await exportFile.writeAsString(content);
    return exportFile;
  }
  
  Future<void> clearLogs() async {
    await _prefs.remove(_logQueueKey);
    
    if (await _logFile.exists()) {
      await _logFile.delete();
    }
  }
  
  Future<LogStats> getStats() async {
    final queue = await _getLogQueue();
    final levelCounts = <LogLevel, int>{};
    
    for (final entry in queue) {
      levelCounts[entry.level] = (levelCounts[entry.level] ?? 0) + 1;
    }
    
    return LogStats(
      totalLogs: queue.length,
      levelCounts: levelCounts,
      logFileSize: await _logFile.exists() ? await _logFile.length() : 0,
    );
  }
}

class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final String? stackTrace;
  
  const LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    required this.context,
    this.stackTrace,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'stack_trace': stackTrace,
    };
  }
  
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      context: Map<String, dynamic>.from(json['context'] ?? {}),
      stackTrace: json['stack_trace'],
    );
  }
}

class LogStats {
  final int totalLogs;
  final Map<LogLevel, int> levelCounts;
  final int logFileSize;
  
  const LogStats({
    required this.totalLogs,
    required this.levelCounts,
    required this.logFileSize,
  });
}