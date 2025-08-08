import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/contextual_case_data.dart';
import '../../domain/entities/allocation_type.dart';
import '../../domain/entities/case_detail.dart';
import '../../domain/usecases/get_contextual_case_data_usecase.dart';
import '../../domain/usecases/get_contextual_kpis_usecase.dart';
import '../../domain/usecases/get_contextual_actions_usecase.dart';
import '../../domain/usecases/update_case_allocation.dart';
import '../../../../core/utils/logger.dart';
import 'contextual_case_bloc_helpers.dart';

// Events
abstract class ContextualCaseEvent extends Equatable {
  const ContextualCaseEvent();

  @override
  List<Object?> get props => [];
}

class LoadContextualCaseData extends ContextualCaseEvent {
  final String caseId;
  final String userId;

  const LoadContextualCaseData({
    required this.caseId,
    required this.userId,
  });

  @override
  List<Object?> get props => [caseId, userId];
}

class RefreshContextualData extends ContextualCaseEvent {
  final String caseId;
  final String userId;

  const RefreshContextualData({
    required this.caseId,
    required this.userId,
  });

  @override
  List<Object?> get props => [caseId, userId];
}

class UpdateAllocation extends ContextualCaseEvent {
  final String caseId;
  final AllocationType allocationType;
  final Map<String, dynamic> metadata;

  const UpdateAllocation({
    required this.caseId,
    required this.allocationType,
    required this.metadata,
  });

  @override
  List<Object?> get props => [caseId, allocationType, metadata];
}

// States
abstract class ContextualCaseState extends Equatable {
  const ContextualCaseState();

  @override
  List<Object?> get props => [];
}

class ContextualCaseInitial extends ContextualCaseState {}

class ContextualCaseLoading extends ContextualCaseState {}

class ContextualCaseLoaded extends ContextualCaseState {
  final CaseDetail caseDetail;
  final ContextualCaseData contextualData;
  final List<ContextualKPI> kpis;
  final ContextualActions actions;
  final ContextualHighlight highlight;

  const ContextualCaseLoaded({
    required this.caseDetail,
    required this.contextualData,
    required this.kpis,
    required this.actions,
    required this.highlight,
  });

  @override
  List<Object?> get props => [
    caseDetail,
    contextualData,
    kpis,
    actions,
    highlight,
  ];

  ContextualCaseLoaded copyWith({
    CaseDetail? caseDetail,
    ContextualCaseData? contextualData,
    List<ContextualKPI>? kpis,
    ContextualActions? actions,
    ContextualHighlight? highlight,
  }) {
    return ContextualCaseLoaded(
      caseDetail: caseDetail ?? this.caseDetail,
      contextualData: contextualData ?? this.contextualData,
      kpis: kpis ?? this.kpis,
      actions: actions ?? this.actions,
      highlight: highlight ?? this.highlight,
    );
  }
}

class ContextualCaseError extends ContextualCaseState {
  final String message;
  final String? details;

  const ContextualCaseError({
    required this.message,
    this.details,
  });

  @override
  List<Object?> get props => [message, details];
}

class ContextualCaseAllocationUpdated extends ContextualCaseState {
  final String caseId;
  final AllocationType newAllocationType;

  const ContextualCaseAllocationUpdated({
    required this.caseId,
    required this.newAllocationType,
  });

  @override
  List<Object?> get props => [caseId, newAllocationType];
}

/// Cache simples em memória para dados contextuais
class ContextualDataCache {
  static const int maxCacheSize = 50;
  static const Duration cacheExpiration = Duration(minutes: 10);
  
  final Map<String, _CacheEntry> _cache = {};
  
  void put(String key, ContextualCaseData data) {
    // Remove entradas antigas se cache estiver cheio
    if (_cache.length >= maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    
    _cache[key] = _CacheEntry(data, DateTime.now());
    AppLogger.debug('Cached contextual data for key: $key');
  }
  
  ContextualCaseData? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    // Verificar se não expirou
    if (DateTime.now().difference(entry.timestamp) > cacheExpiration) {
      _cache.remove(key);
      AppLogger.debug('Cache expired for key: $key');
      return null;
    }
    
    AppLogger.debug('Cache hit for key: $key');
    return entry.data;
  }
  
  void clear() {
    _cache.clear();
    AppLogger.debug('Contextual data cache cleared');
  }
  
  void remove(String key) {
    _cache.remove(key);
    AppLogger.debug('Removed from cache: $key');
  }
}

class _CacheEntry {
  final ContextualCaseData data;
  final DateTime timestamp;
  
  _CacheEntry(this.data, this.timestamp);
}

/// BLoC otimizado com cache e lazy loading
class ContextualCaseBloc extends Bloc<ContextualCaseEvent, ContextualCaseState> with ContextualCaseBlocHelpers {
  final GetContextualCaseDataUseCase getContextualCaseData;
  final GetContextualKPIsUseCase getContextualKPIs;
  final GetContextualActionsUseCase getContextualActions;
  final UpdateCaseAllocation updateCaseAllocation;
  
  // Cache de dados contextuais
  final ContextualDataCache _cache = ContextualDataCache();
  
  // Controle de carregamento simultâneo
  final Set<String> _loadingKeys = <String>{};
  
  ContextualCaseBloc({
    required this.getContextualCaseData,
    required this.getContextualKPIs,
    required this.getContextualActions,
    required this.updateCaseAllocation,
  }) : super(ContextualCaseInitial()) {
    on<LoadContextualCaseData>(_onLoadContextualCaseData);
    on<RefreshContextualData>(_onRefreshContextualData);
    on<UpdateAllocation>(_onUpdateAllocation);
    on<ClearContextualCache>(_onClearContextualCache);
  }

  Future<void> _onLoadContextualCaseData(
    LoadContextualCaseData event,
    Emitter<ContextualCaseState> emit,
  ) async {
    final cacheKey = '${event.caseId}_${event.userId}';
    
    // Verificar se já está carregando
    if (_loadingKeys.contains(cacheKey)) {
      AppLogger.debug('Already loading contextual data for: $cacheKey');
      return;
    }
    
    // Verificar cache primeiro
    final cachedData = _cache.get(cacheKey);
    if (cachedData != null) {
      AppLogger.info('Using cached contextual data for case ${event.caseId}');
      // Mesmo com cache, manter a UI consistente buscando entidades tipadas via UseCase
      try {
        final result = await getContextualCaseData.call(caseId: event.caseId, userId: event.userId);
        emit(ContextualCaseLoaded(
          caseDetail: result.caseDetail,
          contextualData: result.contextualData,
          kpis: result.kpis,
          actions: result.actions,
          highlight: result.highlight,
        ));
        return;
      } catch (e) {
        // Se falhar, cai no fluxo normal com cache mínimo
        emit(ContextualCaseLoaded(
          caseDetail: createDummyCaseDetail(event.caseId),
          contextualData: cachedData,
          kpis: const [],
          actions: _getDefaultActions(cachedData.allocationType),
          highlight: _getDefaultHighlight(cachedData.allocationType),
        ));
        _loadKPIsInBackground(event.caseId, event.userId, emit);
        return;
      }
    }

    _loadingKeys.add(cacheKey);
    emit(ContextualCaseLoading());

    try {
      AppLogger.info('Loading contextual data for case ${event.caseId}');
      
      // Buscar do backend via UseCase unificado (retorna entidades tipadas completas)
      final result = await getContextualCaseData.call(caseId: event.caseId, userId: event.userId);

      // Cache apenas o bloco contextual, pois o CaseDetail será reobtido no próximo load se necessário
      _cache.put(cacheKey, result.contextualData);

      emit(ContextualCaseLoaded(
        caseDetail: result.caseDetail,
        contextualData: result.contextualData,
        kpis: result.kpis,
        actions: result.actions,
        highlight: result.highlight,
      ));

      AppLogger.success('Contextual data loaded successfully for case ${event.caseId}');
    } catch (e) {
      AppLogger.error('Failed to load contextual data for case ${event.caseId}', error: e);
      emit(ContextualCaseError(message: 'Erro ao carregar dados contextuais: ${e.toString()}'));
    } finally {
      _loadingKeys.remove(cacheKey);
    }
  }

  Future<void> _onRefreshContextualData(
    RefreshContextualData event,
    Emitter<ContextualCaseState> emit,
  ) async {
    final cacheKey = '${event.caseId}_${event.userId}';
    
    // Limpar cache para forçar reload
    _cache.remove(cacheKey);
    
    // Recarregar dados
    add(LoadContextualCaseData(
      caseId: event.caseId,
      userId: event.userId,
    ));
  }

  Future<void> _onUpdateAllocation(
    UpdateAllocation event,
    Emitter<ContextualCaseState> emit,
  ) async {
    try {
      emit(ContextualCaseLoading());
      
      await updateCaseAllocation.call(UpdateCaseAllocationParams(
        caseId: event.caseId,
        allocationType: event.allocationType,
        targetLawyerId: event.metadata['newAssigneeId'] as String?,
        reason: event.metadata['reason'] as String?,
        metadata: event.metadata,
      ));
      
      // Limpar cache pois dados mudaram
      final userId = event.metadata['userId'] as String? ?? 'unknown_user';
      final cacheKey = '${event.caseId}_$userId';
      _cache.remove(cacheKey);
      
      emit(ContextualCaseAllocationUpdated(
        caseId: event.caseId,
        newAllocationType: event.allocationType,
      ));
      
      // Recarregar dados atualizados
      add(LoadContextualCaseData(
        caseId: event.caseId,
        userId: userId,
      ));
      
    } catch (e) {
      AppLogger.error('Failed to update allocation for case ${event.caseId}', error: e);
      emit(ContextualCaseError(message: 'Erro ao atualizar alocação: ${e.toString()}'));
    }
  }

  Future<void> _onClearContextualCache(
    ClearContextualCache event,
    Emitter<ContextualCaseState> emit,
  ) async {
    _cache.clear();
    AppLogger.info('Contextual cache cleared');
  }

  // Métodos auxiliares otimizados

  Future<void> _loadKPIsInBackground(
    String caseId,
    String userId,
    Emitter<ContextualCaseState> emit,
  ) async {
    try {
      final kpis = await getContextualKPIs.call(caseId: caseId, userId: userId);
      
      if (state is ContextualCaseLoaded) {
        final currentState = state as ContextualCaseLoaded;
        emit(ContextualCaseLoaded(
          caseDetail: currentState.caseDetail,
          contextualData: currentState.contextualData,
          kpis: kpis,
          actions: currentState.actions,
          highlight: currentState.highlight,
        ));
      }
    } catch (e) {
      AppLogger.warning('Failed to load KPIs in background: ${e.toString()}');
      // Não emitir erro para não quebrar a experiência
    }
  }

  // Removidos helpers não utilizados (otimização)

  ContextualActions _getDefaultActions(AllocationType allocationType) {
    switch (allocationType) {
      case AllocationType.internalDelegation:
        return const ContextualActions(
          primaryAction: ContextualAction(action: 'log_hours', label: 'Registrar Horas'),
          secondaryActions: [
            ContextualAction(action: 'update_status', label: 'Atualizar Status'),
            ContextualAction(action: 'request_help', label: 'Solicitar Ajuda'),
          ],
        );
      case AllocationType.platformMatchDirect:
        return const ContextualActions(
          primaryAction: ContextualAction(action: 'accept_case', label: 'Aceitar Caso'),
          secondaryActions: [
            ContextualAction(action: 'view_client_profile', label: 'Ver Perfil'),
            ContextualAction(action: 'request_info', label: 'Solicitar Info'),
          ],
        );
      case AllocationType.partnershipProactiveSearch:
        return const ContextualActions(
          primaryAction: ContextualAction(action: 'contact_partner', label: 'Contatar Parceiro'),
          secondaryActions: [
            ContextualAction(action: 'align_strategy', label: 'Alinhar Estratégia'),
            ContextualAction(action: 'share_documents', label: 'Compartilhar Docs'),
          ],
        );
      default:
        return const ContextualActions(
          primaryAction: ContextualAction(action: 'view_details', label: 'Ver Detalhes'),
          secondaryActions: [],
        );
    }
  }

  ContextualHighlight _getDefaultHighlight(AllocationType allocationType) {
    switch (allocationType) {
      case AllocationType.internalDelegation:
        return const ContextualHighlight(text: 'Delegação Interna', color: 'orange');
      case AllocationType.platformMatchDirect:
        return const ContextualHighlight(text: 'Match Direto', color: 'blue');
      case AllocationType.partnershipProactiveSearch:
        return const ContextualHighlight(text: 'Parceria', color: 'green');
      default:
        return const ContextualHighlight(text: 'Caso Padrão', color: 'grey');
    }
  }

  @override
  Future<void> close() {
    _cache.clear();
    _loadingKeys.clear();
    return super.close();
  }
}

// Novos eventos para otimização

class ClearContextualCache extends ContextualCaseEvent {
  @override
  List<Object?> get props => [];
}

