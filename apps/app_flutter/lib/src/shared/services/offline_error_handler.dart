import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'logger_service.dart';
import 'analytics_service.dart';

enum ErrorSeverity { low, medium, high, critical }

enum ErrorCategory { 
  network, 
  authentication, 
  validation, 
  permission, 
  storage, 
  business, 
  unknown 
}

class OfflineErrorHandler {
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  
  final LoggerService _logger;
  final AnalyticsService _analytics;
  final Connectivity _connectivity;
  
  final StreamController<AppError> _errorStreamController = StreamController<AppError>.broadcast();
  final List<PendingOperation> _pendingOperations = [];
  final Map<String, int> _retryCount = {};
  
  static OfflineErrorHandler? _instance;
  
  OfflineErrorHandler._({
    required LoggerService logger,
    required AnalyticsService analytics,
    required Connectivity connectivity,
  }) : _logger = logger, _analytics = analytics, _connectivity = connectivity {
    _initializeConnectivityListener();
  }
  
  static Future<OfflineErrorHandler> getInstance() async {
    if (_instance == null) {
      final logger = await LoggerService.getInstance();
      final analytics = await AnalyticsService.getInstance();
      final connectivity = Connectivity();
      _instance = OfflineErrorHandler._(
        logger: logger, 
        analytics: analytics, 
        connectivity: connectivity,
      );
    }
    return _instance!;
  }
  
  Stream<AppError> get errorStream => _errorStreamController.stream;
  
  void _initializeConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isConnected = !results.contains(ConnectivityResult.none);
      
      if (isConnected) {
        _logger.info('Conectividade restaurada, processando operações pendentes');
        _processPendingOperations();
      } else {
        _logger.warning('Conectividade perdida, entrando em modo offline');
      }
    });
  }
  
  // Main error handling method
  Future<AppError> handleError(
    dynamic error, {
    String? context,
    Map<String, dynamic>? metadata,
    String? operationId,
    bool allowRetry = true,
  }) async {
    final appError = await _classifyError(error, context: context, metadata: metadata);
    
    // Log error
    await _logger.error(
      appError.message,
      error: error,
      stackTrace: appError.stackTrace,
      context: {
        'error_code': appError.code,
        'category': appError.category.name,
        'severity': appError.severity.name,
        'context': context,
        'operation_id': operationId,
        ...?metadata,
      },
    );
    
    // Track error in analytics
    await _analytics.trackError(
      appError.message,
      properties: {
        'error_category': appError.category.name,
        'error_severity': appError.severity.name,
        'is_recoverable': appError.isRecoverable,
        'retry_count': _retryCount[operationId] ?? 0,
        ...?metadata,
      },
    );
    
    // Emit error to stream
    _errorStreamController.add(appError);
    
    // Handle retry if applicable
    if (allowRetry && appError.isRecoverable && operationId != null) {
      await _scheduleRetry(operationId, appError, metadata);
    }
    
    return appError;
  }
  
  Future<AppError> _classifyError(dynamic error, {String? context, Map<String, dynamic>? metadata}) async {
    if (error is DioException) {
      return _handleDioError(error, context: context);
    }
    
    if (error is TimeoutException) {
      return AppError(
        code: 'TIMEOUT',
        message: 'Operação expirou. Verifique sua conexão.',
        category: ErrorCategory.network,
        severity: ErrorSeverity.medium,
        isRecoverable: true,
        suggestedActions: ['Tente novamente', 'Verifique sua conexão'],
      );
    }
    
    if (error is FormatException) {
      return AppError(
        code: 'INVALID_FORMAT',
        message: 'Formato de dados inválido',
        category: ErrorCategory.validation,
        severity: ErrorSeverity.medium,
        isRecoverable: false,
        suggestedActions: ['Verifique os dados inseridos'],
      );
    }
    
    // Generic error
    return AppError(
      code: 'UNKNOWN_ERROR',
      message: error.toString(),
      category: ErrorCategory.unknown,
      severity: ErrorSeverity.high,
      isRecoverable: false,
      originalError: error,
    );
  }
  
  AppError _handleDioError(DioException error, {String? context}) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return AppError(
          code: 'NETWORK_TIMEOUT',
          message: 'Timeout na conexão. Tente novamente.',
          category: ErrorCategory.network,
          severity: ErrorSeverity.medium,
          isRecoverable: true,
          suggestedActions: ['Tente novamente', 'Verifique sua conexão'],
          originalError: error,
        );
        
      case DioExceptionType.connectionError:
        return AppError(
          code: 'CONNECTION_ERROR',
          message: 'Erro de conexão. Verifique sua internet.',
          category: ErrorCategory.network,
          severity: ErrorSeverity.high,
          isRecoverable: true,
          suggestedActions: ['Verifique sua conexão', 'Tente mais tarde'],
          originalError: error,
        );
        
      case DioExceptionType.badResponse:
        return _handleHttpError(error);
        
      case DioExceptionType.cancel:
        return AppError(
          code: 'REQUEST_CANCELLED',
          message: 'Operação cancelada',
          category: ErrorCategory.business,
          severity: ErrorSeverity.low,
          isRecoverable: false,
          originalError: error,
        );
        
      default:
        return AppError(
          code: 'NETWORK_ERROR',
          message: 'Erro de rede: ${error.message}',
          category: ErrorCategory.network,
          severity: ErrorSeverity.medium,
          isRecoverable: true,
          originalError: error,
        );
    }
  }
  
  AppError _handleHttpError(DioException error) {
    final statusCode = error.response?.statusCode;
    
    switch (statusCode) {
      case 401:
        return AppError(
          code: 'UNAUTHORIZED',
          message: 'Sessão expirada. Faça login novamente.',
          category: ErrorCategory.authentication,
          severity: ErrorSeverity.high,
          isRecoverable: false,
          suggestedActions: ['Fazer login novamente'],
          originalError: error,
        );
        
      case 403:
        return AppError(
          code: 'FORBIDDEN',
          message: 'Você não tem permissão para esta operação.',
          category: ErrorCategory.permission,
          severity: ErrorSeverity.high,
          isRecoverable: false,
          suggestedActions: ['Contate o suporte'],
          originalError: error,
        );
        
      case 404:
        return AppError(
          code: 'NOT_FOUND',
          message: 'Recurso não encontrado.',
          category: ErrorCategory.business,
          severity: ErrorSeverity.medium,
          isRecoverable: false,
          suggestedActions: ['Verifique os dados', 'Tente atualizar a página'],
          originalError: error,
        );
        
      case 422:
        return AppError(
          code: 'VALIDATION_ERROR',
          message: 'Dados inválidos. Verifique as informações.',
          category: ErrorCategory.validation,
          severity: ErrorSeverity.medium,
          isRecoverable: true,
          suggestedActions: ['Corrija os dados e tente novamente'],
          originalError: error,
        );
        
      case 429:
        return AppError(
          code: 'RATE_LIMIT',
          message: 'Muitas tentativas. Aguarde um momento.',
          category: ErrorCategory.business,
          severity: ErrorSeverity.medium,
          isRecoverable: true,
          suggestedActions: ['Aguarde e tente novamente'],
          originalError: error,
        );
        
      case 500:
      case 502:
      case 503:
      case 504:
        return AppError(
          code: 'SERVER_ERROR',
          message: 'Erro no servidor. Tente mais tarde.',
          category: ErrorCategory.network,
          severity: ErrorSeverity.high,
          isRecoverable: true,
          suggestedActions: ['Tente mais tarde', 'Contate o suporte se persistir'],
          originalError: error,
        );
        
      default:
        return AppError(
          code: 'HTTP_ERROR_$statusCode',
          message: 'Erro HTTP $statusCode',
          category: ErrorCategory.network,
          severity: ErrorSeverity.medium,
          isRecoverable: true,
          originalError: error,
        );
    }
  }
  
  Future<void> _scheduleRetry(String operationId, AppError error, Map<String, dynamic>? metadata) async {
    final retryCount = _retryCount[operationId] ?? 0;
    
    if (retryCount >= _maxRetries) {
      await _logger.warning('Máximo de tentativas excedido para operação: $operationId');
      return;
    }
    
    _retryCount[operationId] = retryCount + 1;
    
    // Exponential backoff
    final delay = Duration(milliseconds: _baseRetryDelay.inMilliseconds * (1 << retryCount));
    
    await _logger.info('Agendando retry #${retryCount + 1} para $operationId em ${delay.inSeconds}s');
    
    Timer(delay, () async {
      await _processRetry(operationId, error, metadata);
    });
  }
  
  Future<void> _processRetry(String operationId, AppError error, Map<String, dynamic>? metadata) async {
    // Check connectivity
    final connectivityResults = await _connectivity.checkConnectivity();
    final isConnected = !connectivityResults.contains(ConnectivityResult.none);
    
    if (!isConnected) {
      // Queue for later when connectivity is restored
      _pendingOperations.add(PendingOperation(
        id: operationId,
        error: error,
        metadata: metadata,
        scheduledAt: DateTime.now(),
      ));
      
      await _logger.info('Operação $operationId adicionada à fila offline');
      return;
    }
    
    await _logger.info('Processando retry para operação: $operationId');
    
    // Here you would implement the actual retry logic
    // This depends on how operations are structured in your app
  }
  
  Future<void> _processPendingOperations() async {
    if (_pendingOperations.isEmpty) return;
    
    final operations = List<PendingOperation>.from(_pendingOperations);
    _pendingOperations.clear();
    
    for (final operation in operations) {
      await _logger.info('Processando operação pendente: ${operation.id}');
      
      try {
        // Process the pending operation
        // Implementation depends on your app's operation structure
        await _processOperation(operation);
        
        // Remove from retry count if successful
        _retryCount.remove(operation.id);
        
      } catch (e) {
        await handleError(
          e,
          context: 'Retry de operação pendente',
          operationId: operation.id,
          metadata: operation.metadata,
        );
      }
    }
  }
  
  Future<void> _processOperation(PendingOperation operation) async {
    // Placeholder - implement based on your app's needs
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  // Helper methods for UI integration
  String getUserFriendlyMessage(AppError error) {
    switch (error.category) {
      case ErrorCategory.network:
        return 'Problema de conexão. Verifique sua internet e tente novamente.';
      case ErrorCategory.authentication:
        return 'Sessão expirada. Você será redirecionado para fazer login.';
      case ErrorCategory.validation:
        return 'Verifique os dados inseridos e tente novamente.';
      case ErrorCategory.permission:
        return 'Você não tem permissão para esta operação.';
      case ErrorCategory.storage:
        return 'Erro ao acessar dados locais.';
      case ErrorCategory.business:
        return error.message;
      case ErrorCategory.unknown:
        return 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }
  
  List<String> getSuggestedActions(AppError error) {
    return error.suggestedActions ?? ['Tente novamente'];
  }
  
  bool shouldShowRetryButton(AppError error) {
    return error.isRecoverable && error.category != ErrorCategory.authentication;
  }
  
  // Management methods
  Future<void> clearRetryHistory() async {
    _retryCount.clear();
    _pendingOperations.clear();
    await _logger.info('Histórico de retry limpo');
  }
  
  Future<Map<String, dynamic>> getErrorStats() async {
    return {
      'pending_operations': _pendingOperations.length,
      'retry_counts': Map.from(_retryCount),
      'connectivity': await _connectivity.checkConnectivity(),
    };
  }
  
  void dispose() {
    _errorStreamController.close();
  }
}

class AppError {
  final String code;
  final String message;
  final ErrorCategory category;
  final ErrorSeverity severity;
  final bool isRecoverable;
  final List<String>? suggestedActions;
  final String? stackTrace;
  final dynamic originalError;
  final DateTime timestamp;
  
  AppError({
    required this.code,
    required this.message,
    required this.category,
    required this.severity,
    required this.isRecoverable,
    this.suggestedActions,
    this.stackTrace,
    this.originalError,
  }) : timestamp = DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'category': category.name,
      'severity': severity.name,
      'is_recoverable': isRecoverable,
      'suggested_actions': suggestedActions,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'AppError{code: $code, message: $message, category: ${category.name}, severity: ${severity.name}}';
  }
}

class PendingOperation {
  final String id;
  final AppError error;
  final Map<String, dynamic>? metadata;
  final DateTime scheduledAt;
  
  PendingOperation({
    required this.id,
    required this.error,
    this.metadata,
    required this.scheduledAt,
  });
}