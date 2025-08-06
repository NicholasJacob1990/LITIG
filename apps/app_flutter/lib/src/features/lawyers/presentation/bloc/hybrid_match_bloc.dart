import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/matched_lawyer.dart';
import '../../../firms/domain/entities/law_firm.dart';
import '../../domain/repositories/lawyers_repository.dart';
import '../../../firms/domain/repositories/firm_repository.dart';

// Events
abstract class HybridMatchEvent extends Equatable {
  const HybridMatchEvent();

  @override
  List<Object?> get props => [];
}

class FetchHybridMatches extends HybridMatchEvent {
  final String caseId;
  final bool includeFirms;
  final String preset;

  const FetchHybridMatches({
    required this.caseId,
    this.includeFirms = true,
    this.preset = 'balanced',
  });

  @override
  List<Object?> get props => [caseId, includeFirms, preset];
}

class SearchHybridMatches extends HybridMatchEvent {
  final String query;
  final bool includeFirms;

  const SearchHybridMatches({
    required this.query,
    this.includeFirms = true,
  });

  @override
  List<Object?> get props => [query, includeFirms];
}

class ApplyHybridFilters extends HybridMatchEvent {
  final String caseId;
  final bool includeLawyers;
  final bool includeFirms;
  final String preset;
  final bool mixedRendering;

  const ApplyHybridFilters({
    required this.caseId,
    required this.includeLawyers,
    required this.includeFirms,
    required this.preset,
    this.mixedRendering = false,
  });

  @override
  List<Object?> get props => [caseId, includeLawyers, includeFirms, preset, mixedRendering];
}

class RefreshHybridMatches extends HybridMatchEvent {
  final String caseId;
  final bool includeFirms;
  final String preset;

  const RefreshHybridMatches({
    required this.caseId,
    this.includeFirms = true,
    this.preset = 'balanced',
  });

  @override
  List<Object?> get props => [caseId, includeFirms, preset];
}

class ToggleHybridSearch extends HybridMatchEvent {
  final bool enableHybridSearch;

  const ToggleHybridSearch({required this.enableHybridSearch});

  @override
  List<Object?> get props => [enableHybridSearch];
}

// States
abstract class HybridMatchState extends Equatable {
  const HybridMatchState();

  @override
  List<Object?> get props => [];
}

class HybridMatchInitial extends HybridMatchState {}

class HybridMatchLoading extends HybridMatchState {}

class HybridMatchLoaded extends HybridMatchState {
  final List<MatchedLawyer> lawyers;
  final List<LawFirm> firms;
  final bool mixedRendering;
  final bool isHybridSearchEnabled;

  const HybridMatchLoaded({
    required this.lawyers,
    required this.firms,
    this.mixedRendering = false,
    this.isHybridSearchEnabled = false,
  });

  // Getter para compatibilidade
  List<MatchedLawyer> get matches => lawyers;

  @override
  List<Object?> get props => [lawyers, firms, mixedRendering, isHybridSearchEnabled];
}

class HybridMatchError extends HybridMatchState {
  final String message;

  const HybridMatchError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class HybridMatchBloc extends Bloc<HybridMatchEvent, HybridMatchState> {
  final LawyersRepository lawyersRepository;
  final FirmRepository firmsRepository;
  bool _isHybridSearchEnabled = false;

  HybridMatchBloc({
    required this.lawyersRepository,
    required this.firmsRepository,
  }) : super(HybridMatchInitial()) {
    on<FetchHybridMatches>(_onFetchHybridMatches);
    on<SearchHybridMatches>(_onSearchHybridMatches);
    on<RefreshHybridMatches>(_onRefreshHybridMatches);
    on<ApplyHybridFilters>(_onApplyHybridFilters);
    on<ToggleHybridSearch>(_onToggleHybridSearch);
  }

  Future<void> _onToggleHybridSearch(
    ToggleHybridSearch event,
    Emitter<HybridMatchState> emit,
  ) async {
    _isHybridSearchEnabled = event.enableHybridSearch;
    
    // Se temos um estado carregado, atualizar com o novo status
    if (state is HybridMatchLoaded) {
      final currentState = state as HybridMatchLoaded;
      emit(HybridMatchLoaded(
        lawyers: currentState.lawyers,
        firms: currentState.firms,
        mixedRendering: currentState.mixedRendering,
        isHybridSearchEnabled: _isHybridSearchEnabled,
      ));
    }
  }

  Future<void> _onFetchHybridMatches(
    FetchHybridMatches event,
    Emitter<HybridMatchState> emit,
  ) async {
    emit(HybridMatchLoading());

    try {
      // Usar busca híbrida se habilitada
      final matchResult = await lawyersRepository.findMatchesWithFirms(
        caseId: event.caseId,
        expandSearch: _isHybridSearchEnabled,
      );

      // Se includeFirms for false, filtrar escritórios
      final firms = event.includeFirms ? matchResult.firms : <LawFirm>[];

      emit(HybridMatchLoaded(
        lawyers: matchResult.lawyers, 
        firms: firms,
        isHybridSearchEnabled: _isHybridSearchEnabled,
      ));
    } catch (e) {
      emit(HybridMatchError(message: 'Erro ao buscar matches: ${e.toString()}'));
    }
  }

  Future<void> _onSearchHybridMatches(
    SearchHybridMatches event,
    Emitter<HybridMatchState> emit,
  ) async {
    emit(HybridMatchLoading());

    try {
      // Para busca, usar findMatches com mock case ID
      final lawyers = await lawyersRepository.findMatches(
        caseId: 'search_case_id',
      );

      // Buscar escritórios se solicitado
      List<LawFirm> firms = [];
      if (event.includeFirms) {
        final firmsResult = await firmsRepository.getFirms(
          limit: 20,
          offset: 0,
          includeKpis: true,
          includeLawyersCount: true,
        );

        firmsResult.fold(
          (failure) => {}, // Ignorar erro de escritórios
          (allFirms) {
            // Filtrar escritórios por query (busca simples por nome)
            firms = allFirms
                .where((firm) =>
                    firm.name.toLowerCase().contains(event.query.toLowerCase()))
                .toList();
          },
        );
      }

      emit(HybridMatchLoaded(
        lawyers: lawyers, 
        firms: firms,
        isHybridSearchEnabled: _isHybridSearchEnabled,
      ));
    } catch (e) {
      emit(HybridMatchError(message: 'Erro na busca: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshHybridMatches(
    RefreshHybridMatches event,
    Emitter<HybridMatchState> emit,
  ) async {
    // Usa a mesma lógica do fetch
    add(FetchHybridMatches(
      caseId: event.caseId,
      includeFirms: event.includeFirms,
      preset: event.preset,
    ));
  }

  Future<void> _onApplyHybridFilters(
    ApplyHybridFilters event,
    Emitter<HybridMatchState> emit,
  ) async {
    emit(HybridMatchLoading());

    try {
      if (event.includeLawyers) {
        // Usar busca híbrida se habilitada
        final matchResult = await lawyersRepository.findMatchesWithFirms(
          caseId: event.caseId,
          expandSearch: _isHybridSearchEnabled,
        );

        // Aplicar filtros baseado nas preferências
        final lawyers = event.includeLawyers ? matchResult.lawyers : <MatchedLawyer>[];
        final firms = event.includeFirms ? matchResult.firms : <LawFirm>[];

        emit(HybridMatchLoaded(
          lawyers: lawyers, 
          firms: firms,
          mixedRendering: event.mixedRendering,
          isHybridSearchEnabled: _isHybridSearchEnabled,
        ));
      } else {
        // Se não incluir advogados, retornar listas vazias
        emit(HybridMatchLoaded(
          lawyers: const [], 
          firms: const [],
          mixedRendering: event.mixedRendering,
          isHybridSearchEnabled: _isHybridSearchEnabled,
        ));
      }
    } catch (e) {
      emit(HybridMatchError(message: 'Erro ao aplicar filtros: ${e.toString()}'));
    }
  }
} 