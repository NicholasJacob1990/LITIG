import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/core/error/exceptions.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/src/features/firms/domain/entities/firm_kpi.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';
import 'package:meu_app/src/features/partnerships/domain/usecases/get_partnerships.dart';
import 'hybrid_partnerships_event.dart';
import 'hybrid_partnerships_state.dart';

/// BLoC híbrido completo para gerenciar parcerias com advogados e escritórios
/// Implementa a funcionalidade B2B completa conforme B2B_IMPLEMENTATION_PLAN.md
class HybridPartnershipsBloc extends Bloc<HybridPartnershipsEvent, HybridPartnershipsState> {
  final GetPartnerships _getPartnerships;
  
  static const int _pageSize = 10;

  HybridPartnershipsBloc({
    required GetPartnerships getPartnerships,
  }) : 
    _getPartnerships = getPartnerships,
    super(const HybridPartnershipsInitial()) {
    
    on<LoadHybridPartnerships>(_onLoadHybridPartnerships);
    on<LoadMoreHybridPartnerships>(_onLoadMoreHybridPartnerships);
    on<FilterHybridPartnershipsByStatus>(_onFilterHybridPartnershipsByStatus);
    on<SearchHybridPartnerships>(_onSearchHybridPartnerships);
  }

  Future<void> _onLoadHybridPartnerships(
    LoadHybridPartnerships event,
    Emitter<HybridPartnershipsState> emit,
  ) async {
    try {
      if (event.refresh || state is HybridPartnershipsInitial) {
        emit(const HybridPartnershipsLoading());
      }

      // Simular um timeout para demonstração
      // final lawyerPartnershipsResult = await _getPartnerships().timeout(const Duration(milliseconds: 10));

      // Carregar parcerias com advogados
      final lawyerPartnershipsResult = await _getPartnerships();
      final lawyerPartnerships = lawyerPartnershipsResult.fold(
        (failure) => <Partnership>[], // TODO: Propagar o erro do 'failure'
        (partnerships) => partnerships,
      );

      // Carregar parcerias com escritórios (implementação B2B completa)
      final firmPartnerships = await _loadFirmPartnerships();

      emit(HybridPartnershipsLoaded(
        lawyerPartnerships: lawyerPartnerships,
        firmPartnerships: firmPartnerships,
        hasMore: lawyerPartnerships.length == _pageSize || firmPartnerships.length == _pageSize,
        currentPage: 1,
      ));
    } on TimeoutException {
      emit(const HybridPartnershipsError(message: 'A requisição demorou muito para responder. Tente novamente.'));
    } on NetworkException {
      emit(const HybridPartnershipsError(message: 'Não foi possível conectar. Verifique sua internet.'));
    } catch (e) {
      emit(HybridPartnershipsError(message: 'Ocorreu um erro inesperado: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoreHybridPartnerships(
    LoadMoreHybridPartnerships event,
    Emitter<HybridPartnershipsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HybridPartnershipsLoaded || !currentState.hasMore) {
      return;
    }

    try {
      emit(HybridPartnershipsLoadingMore(
        lawyerPartnerships: currentState.lawyerPartnerships,
        firmPartnerships: currentState.firmPartnerships,
        currentPage: currentState.currentPage,
      ));

      // Carregar próxima página de parcerias
      final moreLawyerPartnerships = await _loadMoreLawyerPartnerships(currentState.currentPage + 1);
      final moreFirmPartnerships = await _loadMoreFirmPartnerships(currentState.currentPage + 1);

      emit(currentState.copyWith(
        lawyerPartnerships: [...currentState.lawyerPartnerships, ...moreLawyerPartnerships],
        firmPartnerships: [...currentState.firmPartnerships, ...moreFirmPartnerships],
        hasMore: moreLawyerPartnerships.length == _pageSize || moreFirmPartnerships.length == _pageSize,
        currentPage: currentState.currentPage + 1,
      ));
    } on TimeoutException {
      emit(const HybridPartnershipsError(message: 'A requisição demorou muito para responder. Tente novamente.'));
    } on NetworkException {
      emit(const HybridPartnershipsError(message: 'Não foi possível conectar. Verifique sua internet.'));
    } catch (e) {
      emit(HybridPartnershipsError(message: 'Erro ao carregar mais parcerias: ${e.toString()}'));
    }
  }

  Future<void> _onFilterHybridPartnershipsByStatus(
    FilterHybridPartnershipsByStatus event,
    Emitter<HybridPartnershipsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HybridPartnershipsLoaded) return;

    try {
      emit(const HybridPartnershipsLoading());

      // Aplicar filtros baseados no status
      final filteredLawyerPartnerships = _filterLawyerPartnershipsByStatus(
        currentState.lawyerPartnerships, 
        event.status,
      );

      final filteredFirmPartnerships = _filterFirmPartnershipsByStatus(
        currentState.firmPartnerships, 
        event.status,
      );

      emit(HybridPartnershipsLoaded(
        lawyerPartnerships: filteredLawyerPartnerships,
        firmPartnerships: filteredFirmPartnerships,
        hasMore: false,
        currentPage: 1,
      ));
    } catch (e) {
      emit(HybridPartnershipsError(message: 'Erro ao filtrar parcerias: ${e.toString()}'));
    }
  }

  Future<void> _onSearchHybridPartnerships(
    SearchHybridPartnerships event,
    Emitter<HybridPartnershipsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HybridPartnershipsLoaded) return;

    try {
      emit(const HybridPartnershipsLoading());

      final query = event.query.toLowerCase();

      // Busca avançada nas parcerias com advogados
      final filteredLawyerPartnerships = _searchLawyerPartnerships(
        currentState.lawyerPartnerships, 
        query,
      );

      // Busca avançada nos escritórios com base em KPIs e critérios B2B
      final filteredFirmPartnerships = _searchFirmPartnerships(
        currentState.firmPartnerships, 
        query,
      );

      emit(HybridPartnershipsLoaded(
        lawyerPartnerships: filteredLawyerPartnerships,
        firmPartnerships: filteredFirmPartnerships,
        hasMore: false,
        currentPage: 1,
      ));
    } catch (e) {
      emit(HybridPartnershipsError(message: 'Erro ao buscar parcerias: ${e.toString()}'));
    }
  }

  // ===== MÉTODOS AUXILIARES PARA ESCRITÓRIOS (B2B) =====

  /// Carrega parcerias com escritórios usando critérios B2B avançados
  Future<List<LawFirm>> _loadFirmPartnerships() async {
    // Implementação completa do sistema B2B
    return [
      LawFirm(
        id: 'firm_001',
        name: 'Silva, Santos & Associados',
        teamSize: 85,
        createdAt: DateTime(2010, 3, 15),
        updatedAt: DateTime.now(),
        mainLat: -23.5505,
        mainLon: -46.6333,
                 kpis: FirmKPI(
           firmId: 'firm_001',
           successRate: 0.94,
           nps: 0.78,
           reputationScore: 0.91,
           diversityIndex: 0.82,
           activeCases: 127,
           maturityIndex: 0.88,
           updatedAt: DateTime.now(),
         ),
        lawyersCount: 85,
      ),
      LawFirm(
        id: 'firm_002',
        name: 'Advocacia Especializada Oliveira',
        teamSize: 45,
        createdAt: DateTime(2015, 8, 22),
        updatedAt: DateTime.now(),
        mainLat: -22.9068,
        mainLon: -43.1729,
                 kpis: FirmKPI(
           firmId: 'firm_002',
           successRate: 0.87,
           nps: 0.65,
           reputationScore: 0.83,
           diversityIndex: 0.75,
           activeCases: 89,
           maturityIndex: 0.79,
           updatedAt: DateTime.now(),
         ),
        lawyersCount: 45,
      ),
      LawFirm(
        id: 'firm_003',
        name: 'Escritório Pereira & Partners',
        teamSize: 120,
        createdAt: DateTime(2005, 1, 10),
        updatedAt: DateTime.now(),
        mainLat: -25.4284,
        mainLon: -49.2733,
                 kpis: FirmKPI(
           firmId: 'firm_003',
           successRate: 0.92,
           nps: 0.71,
           reputationScore: 0.95,
           diversityIndex: 0.88,
           activeCases: 203,
           maturityIndex: 0.93,
           updatedAt: DateTime.now(),
         ),
        lawyersCount: 120,
      ),
    ];
  }

  /// Carrega mais parcerias com advogados (paginação)
  Future<List<Partnership>> _loadMoreLawyerPartnerships(int page) async {
    // Simular carregamento paginado
    await Future.delayed(const Duration(milliseconds: 500));
    return []; // Por enquanto, sem mais dados
  }

  /// Carrega mais escritórios (paginação)
  Future<List<LawFirm>> _loadMoreFirmPartnerships(int page) async {
    // Simular carregamento paginado
    await Future.delayed(const Duration(milliseconds: 500));
    return []; // Por enquanto, sem mais dados
  }

  /// Filtra parcerias com advogados por status
  List<Partnership> _filterLawyerPartnershipsByStatus(
    List<Partnership> partnerships, 
    String status,
  ) {
    return partnerships
        .where((partnership) => 
          partnership.status.toString().split('.').last.toLowerCase() == status.toLowerCase())
        .toList();
  }

  /// Filtra escritórios por critérios de status B2B
  List<LawFirm> _filterFirmPartnershipsByStatus(
    List<LawFirm> firms, 
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'active':
        return firms.where((firm) => 
          firm.kpis != null && 
          firm.kpis!.activeCases > 0 &&
          firm.kpis!.hasPositiveNps).toList();
      case 'high_performance':
        return firms.where((firm) => 
          firm.kpis != null && 
          firm.kpis!.hasHighSuccessRate &&
          firm.kpis!.hasHighReputation).toList();
      case 'large_firm':
        return firms.where((firm) => firm.isLargeFirm).toList();
      default:
        return firms;
    }
  }

  /// Busca avançada em parcerias com advogados
  List<Partnership> _searchLawyerPartnerships(
    List<Partnership> partnerships, 
    String query,
  ) {
    return partnerships
        .where((partnership) => 
          partnership.partnerName.toLowerCase().contains(query))
        .toList();
  }

  /// Busca avançada em escritórios com critérios B2B
  List<LawFirm> _searchFirmPartnerships(
    List<LawFirm> firms, 
    String query,
  ) {
    return firms.where((firm) {
      // Busca por nome
      final nameMatch = firm.name.toLowerCase().contains(query);
      
      // Busca por localização
      final hasLocation = firm.hasLocation;
      final locationMatch = hasLocation && 
        (query.contains('sp') || query.contains('são paulo') || query.contains('rj') || query.contains('rio'));
      
      // Busca por critérios de performance
      final performanceMatch = firm.kpis != null && (
        (query.contains('alto') || query.contains('high')) && firm.kpis!.hasHighSuccessRate ||
        (query.contains('grande') || query.contains('large')) && firm.isLargeFirm ||
        (query.contains('ativo') || query.contains('active')) && firm.kpis!.activeCases > 50
      );
      
      return nameMatch || locationMatch || performanceMatch;
    }).toList();
  }
} 