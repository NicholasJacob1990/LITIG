import 'dart:async';
import 'dart:collection';
import '../presentation/bloc/vip_status_bloc.dart';

/// Sistema de Debouncing para Verificações VIP
///
/// ⚡ OTIMIZAÇÕES IMPLEMENTADAS:
/// - Agrupa múltiplas verificações VIP em batch requests
/// - Evita spam de requests durante navegação rápida
/// - Cache inteligente para evitar verificações repetidas
/// - Priorização de requests VIP vs requests normais
/// - Cancelamento automático de requests obsoletos
class VipStatusDebouncer {
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const Duration _batchDelay = Duration(milliseconds: 150);
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // Timers para debouncing
  static Timer? _debounceTimer;
  static Timer? _batchTimer;
  
  // Filas de requests
  static final Queue<_VipRequest> _pendingRequests = Queue();
  static final Set<String> _processingUserIds = <String>{};
  
  // Cache de resultados recentes
  static final Map<String, _CachedResult> _cache = {};
  
  // Estatísticas para monitoring
  static int _totalRequests = 0;
  static int _cacheHits = 0;
  static int _batchedRequests = 0;

  /// Solicita verificação VIP para um usuário
  /// Usa debouncing para evitar múltiplas chamadas simultâneas
  static void requestVipCheck({
    required String userId,
    required String userType,
    required VipStatusBloc bloc,
    VipRequestPriority priority = VipRequestPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    _totalRequests++;
    
    // 🎯 Verifica cache primeiro
    final cached = _getCachedResult(userId);
    if (cached != null) {
      _cacheHits++;
      _emitCachedResult(cached, bloc);
      return;
    }

    // 🚫 Evita requests duplicados em processamento
    if (_processingUserIds.contains(userId)) {
      return;
    }

    // 📝 Adiciona à fila de pending
    final request = _VipRequest(
      userId: userId,
      userType: userType,
      bloc: bloc,
      priority: priority,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _addToQueue(request);
    _scheduleProcessing();
  }

  /// Adiciona request à fila com ordenação por prioridade
  static void _addToQueue(_VipRequest request) {
    // Remove requests antigos para o mesmo usuário
    _pendingRequests.removeWhere((r) => r.userId == request.userId);
    
    // Insere na posição correta baseado na prioridade
    if (request.priority == VipRequestPriority.high || 
        _pendingRequests.isEmpty) {
      _pendingRequests.addFirst(request);
    } else {
      // Procura posição baseada na prioridade
      int insertIndex = 0;
      for (int i = 0; i < _pendingRequests.length; i++) {
        final existingRequest = _pendingRequests.elementAt(i);
        if (existingRequest.priority.index >= request.priority.index) {
          insertIndex = i;
          break;
        }
        insertIndex = i + 1;
      }
      
      final list = _pendingRequests.toList();
      list.insert(insertIndex, request);
      _pendingRequests.clear();
      _pendingRequests.addAll(list);
    }
  }

  /// Agenda processamento com debouncing
  static void _scheduleProcessing() {
    // Cancela timer anterior
    _debounceTimer?.cancel();
    
    // Processa imediatamente se for high priority
    final hasHighPriority = _pendingRequests.any(
      (r) => r.priority == VipRequestPriority.high
    );
    
    if (hasHighPriority) {
      _processImmediately();
      return;
    }

    // Agenda processamento com debounce
    _debounceTimer = Timer(_debounceDelay, () {
      _processBatch();
    });
  }

  /// Processa requests de alta prioridade imediatamente
  static void _processImmediately() {
    final highPriorityRequests = _pendingRequests
        .where((r) => r.priority == VipRequestPriority.high)
        .toList();
    
    // Remove da fila principal
    _pendingRequests.removeWhere(
      (r) => r.priority == VipRequestPriority.high
    );

    for (final request in highPriorityRequests) {
      _processRequest(request);
    }

    // Reagenda processamento do restante se necessário
    if (_pendingRequests.isNotEmpty) {
      _scheduleProcessing();
    }
  }

  /// Processa requests em batch para melhor performance
  static void _processBatch() {
    if (_pendingRequests.isEmpty) return;

    final batch = <_VipRequest>[];
    
    // Limita tamanho do batch para evitar sobrecarga
    const maxBatchSize = 5;
    while (_pendingRequests.isNotEmpty && batch.length < maxBatchSize) {
      batch.add(_pendingRequests.removeFirst());
    }

    _batchedRequests += batch.length;

    // Processa cada request do batch
    for (final request in batch) {
      _processRequest(request);
    }

    // Se ainda há requests pendentes, agenda próximo batch
    if (_pendingRequests.isNotEmpty) {
      _batchTimer = Timer(_batchDelay, () {
        _processBatch();
      });
    }
  }

  /// Processa um request individual
  static void _processRequest(_VipRequest request) {
    _processingUserIds.add(request.userId);

    // Adiciona à context do BLoC
    request.bloc.add(CheckVipStatus(
      userId: request.userId,
      userType: request.userType,
    ));

    // Remove do processamento após delay
    Timer(const Duration(seconds: 2), () {
      _processingUserIds.remove(request.userId);
    });
  }

  /// Verifica cache para resultado existente
  static _CachedResult? _getCachedResult(String userId) {
    final cached = _cache[userId];
    if (cached == null) return null;

    final isExpired = DateTime.now().difference(cached.timestamp) > _cacheExpiry;
    if (isExpired) {
      _cache.remove(userId);
      return null;
    }

    return cached;
  }

  /// Emite resultado do cache para o BLoC
  static void _emitCachedResult(_CachedResult cached, VipStatusBloc bloc) {
    // Simula emissão do estado cached
    // Na implementação real, seria feito através do BLoC
    print('🎯 Cache hit for user ${cached.userId} - Plan: ${cached.plan}');
  }

  /// Armazena resultado no cache
  static void cacheResult({
    required String userId,
    required String plan,
    required bool isVip,
    required List<String> benefits,
  }) {
    _cache[userId] = _CachedResult(
      userId: userId,
      plan: plan,
      isVip: isVip,
      benefits: benefits,
      timestamp: DateTime.now(),
    );
  }

  /// Limpa cache expirado
  static void cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _cache.entries
        .where((entry) => now.difference(entry.value.timestamp) > _cacheExpiry)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// Cancela todos os requests pendentes
  static void cancelAllRequests() {
    _debounceTimer?.cancel();
    _batchTimer?.cancel();
    _pendingRequests.clear();
    _processingUserIds.clear();
  }

  /// Cancela requests para usuário específico
  static void cancelUserRequests(String userId) {
    _pendingRequests.removeWhere((r) => r.userId == userId);
    _processingUserIds.remove(userId);
  }

  /// Força verificação VIP (bypass debouncing)
  static void forceVipCheck({
    required String userId,
    required String userType,
    required VipStatusBloc bloc,
  }) {
    _cache.remove(userId); // Remove cache
    _processRequest(_VipRequest(
      userId: userId,
      userType: userType,
      bloc: bloc,
      priority: VipRequestPriority.high,
      timestamp: DateTime.now(),
      metadata: {'forced': true},
    ));
  }

  /// Estatísticas de performance
  static VipDebouncerStats getStats() {
    return VipDebouncerStats(
      totalRequests: _totalRequests,
      cacheHits: _cacheHits,
      batchedRequests: _batchedRequests,
      pendingRequests: _pendingRequests.length,
      cacheSize: _cache.length,
      cacheHitRate: _totalRequests > 0 ? _cacheHits / _totalRequests : 0.0,
    );
  }

  /// Reseta estatísticas
  static void resetStats() {
    _totalRequests = 0;
    _cacheHits = 0;
    _batchedRequests = 0;
  }

  /// Limpa todos os dados (usar com cuidado)
  static void clearAll() {
    cancelAllRequests();
    _cache.clear();
    resetStats();
  }
}

/// Enum para prioridade de requests VIP
enum VipRequestPriority {
  low,      // Verificações em background
  normal,   // Verificações padrão
  high,     // Verificações críticas (login, upgrade)
}

/// Classe interna para representar um request VIP
class _VipRequest {
  final String userId;
  final String userType;
  final VipStatusBloc bloc;
  final VipRequestPriority priority;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const _VipRequest({
    required this.userId,
    required this.userType,
    required this.bloc,
    required this.priority,
    required this.timestamp,
    required this.metadata,
  });

  @override
  String toString() {
    return 'VipRequest(userId: $userId, priority: $priority, timestamp: $timestamp)';
  }
}

/// Classe para resultado em cache
class _CachedResult {
  final String userId;
  final String plan;
  final bool isVip;
  final List<String> benefits;
  final DateTime timestamp;

  const _CachedResult({
    required this.userId,
    required this.plan,
    required this.isVip,
    required this.benefits,
    required this.timestamp,
  });
}

/// Estatísticas do sistema de debouncing
class VipDebouncerStats {
  final int totalRequests;
  final int cacheHits;
  final int batchedRequests;
  final int pendingRequests;
  final int cacheSize;
  final double cacheHitRate;

  const VipDebouncerStats({
    required this.totalRequests,
    required this.cacheHits,
    required this.batchedRequests,
    required this.pendingRequests,
    required this.cacheSize,
    required this.cacheHitRate,
  });

  @override
  String toString() {
    return '''
VipDebouncerStats:
  Total Requests: $totalRequests
  Cache Hits: $cacheHits (${(cacheHitRate * 100).toStringAsFixed(1)}%)
  Batched Requests: $batchedRequests
  Pending Requests: $pendingRequests
  Cache Size: $cacheSize
''';
  }
}

/// Extension para facilitar uso do debouncer
extension VipStatusBlocExtension on VipStatusBloc {
  /// Versão debounced do CheckVipStatus
  void checkVipStatusDebounced({
    required String userId,
    required String userType,
    VipRequestPriority priority = VipRequestPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    VipStatusDebouncer.requestVipCheck(
      userId: userId,
      userType: userType,
      bloc: this,
      priority: priority,
      metadata: metadata,
    );
  }

  /// Versão forçada (sem debouncing)
  void forceVipStatusCheck({
    required String userId,
    required String userType,
  }) {
    VipStatusDebouncer.forceVipCheck(
      userId: userId,
      userType: userType,
      bloc: this,
    );
  }
} 