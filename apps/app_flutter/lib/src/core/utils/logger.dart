import 'dart:developer' as developer;

/// Sistema de logging centralizado para o aplicativo
/// 
/// Substitui os prints por um sistema mais robusto e configurável
class AppLogger {
  static const String _appName = 'LITIG';
  
  /// Log de informação
  static void info(String message, {String? tag}) {
    _log(message, tag: tag, level: 800);
  }
  
  /// Log de sucesso
  static void success(String message, {String? tag}) {
    _log('✅ $message', tag: tag, level: 800);
  }
  
  /// Log de warning
  static void warning(String message, {String? tag}) {
    _log('⚠️  $message', tag: tag, level: 900);
  }
  
  /// Log de erro
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('❌ $message', tag: tag, level: 1000, error: error, stackTrace: stackTrace);
  }
  
  /// Log de debug (apenas em modo debug)
  static void debug(String message, {String? tag}) {
    assert(() {
      _log('🐛 $message', tag: tag, level: 700);
      return true;
    }());
  }
  
  /// Log de inicialização
  static void init(String message, {String? tag}) {
    _log('🚀 $message', tag: tag, level: 800);
  }
  
  /// Log interno
  static void _log(
    String message, {
    String? tag,
    int level = 800,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final String logTag = tag ?? _appName;
    
    developer.log(
      message,
      name: logTag,
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Extension para facilitar o uso do logger
extension LoggerExtension on String {
  void logInfo({String? tag}) => AppLogger.info(this, tag: tag);
  void logSuccess({String? tag}) => AppLogger.success(this, tag: tag);
  void logWarning({String? tag}) => AppLogger.warning(this, tag: tag);
  void logError({String? tag, Object? error, StackTrace? stackTrace}) => 
      AppLogger.error(this, tag: tag, error: error, stackTrace: stackTrace);
  void logDebug({String? tag}) => AppLogger.debug(this, tag: tag);
} 