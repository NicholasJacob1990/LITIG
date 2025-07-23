import 'dart:developer' as developer;

class AppLogger {
  static void debug(String message, [Map<String, dynamic>? context]) {
    developer.log(
      message,
      name: 'DEBUG',
      level: 500,
      time: DateTime.now(),
      sequenceNumber: DateTime.now().millisecondsSinceEpoch,
    );
    if (context != null && context.isNotEmpty) {
      developer.log(
        'Context: $context',
        name: 'DEBUG',
        level: 500,
        time: DateTime.now(),
      );
    }
  }

  static void info(String message, [Map<String, dynamic>? context]) {
    developer.log(
      message,
      name: 'INFO',
      level: 800,
      time: DateTime.now(),
      sequenceNumber: DateTime.now().millisecondsSinceEpoch,
    );
    if (context != null && context.isNotEmpty) {
      developer.log(
        'Context: $context',
        name: 'INFO',
        level: 800,
        time: DateTime.now(),
      );
    }
  }

  static void warning(String message, [Map<String, dynamic>? context]) {
    developer.log(
      message,
      name: 'WARNING',
      level: 900,
      time: DateTime.now(),
      sequenceNumber: DateTime.now().millisecondsSinceEpoch,
    );
    if (context != null && context.isNotEmpty) {
      developer.log(
        'Context: $context',
        name: 'WARNING',
        level: 900,
        time: DateTime.now(),
      );
    }
  }

  static void error(String message, [Map<String, dynamic>? context]) {
    developer.log(
      message,
      name: 'ERROR',
      level: 1000,
      time: DateTime.now(),
      sequenceNumber: DateTime.now().millisecondsSinceEpoch,
    );
    if (context != null && context.isNotEmpty) {
      developer.log(
        'Context: $context',
        name: 'ERROR',
        level: 1000,
        time: DateTime.now(),
      );
    }
  }

  static void fatal(String message, [Map<String, dynamic>? context]) {
    developer.log(
      message,
      name: 'FATAL',
      level: 1200,
      time: DateTime.now(),
      sequenceNumber: DateTime.now().millisecondsSinceEpoch,
    );
    if (context != null && context.isNotEmpty) {
      developer.log(
        'Context: $context',
        name: 'FATAL',
        level: 1200,
        time: DateTime.now(),
      );
    }
  }
} 