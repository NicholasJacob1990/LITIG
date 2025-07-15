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

  const HybridMatchLoaded({
    required this.lawyers,
    required this.firms,
    this.mixedRendering = false,
  });

  @override
  List<Object?> get props => [lawyers, firms, mixedRendering];
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

  HybridMatchBloc({
    required this.lawyersRepository,
    required this.firmsRepository,
  }) : super(HybridMatchInitial()) {
    on<FetchHybridMatches>(_onFetchHybridMatches);
    on<SearchHybridMatches>(_onSearchHybridMatches);
    on<RefreshHybridMatches>(_onRefreshHybridMatches);
    on<ApplyHybridFilters>(_onApplyHybridFilters);
  }

  Future<void> _onFetchHybridMatches(
    FetchHybridMatches event,
    Emitter<HybridMatchState> emit,
  ) async {
    emit(HybridMatchLoading());

    try {
      // Buscar advogados
      final lawyers = await lawyersRepository.findMatches(
        caseId: event.caseId,
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
          (firmsList) => firms = firmsList,
        );
      }

      emit(HybridMatchLoaded(lawyers: lawyers, firms: firms));
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

      emit(HybridMatchLoaded(lawyers: lawyers, firms: firms));
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
      // Buscar advogados se solicitado
      List<MatchedLawyer> lawyers = [];
      if (event.includeLawyers) {
        lawyers = await lawyersRepository.findMatches(
          caseId: event.caseId,
        );
      }

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
          (firmsList) => firms = firmsList,
        );
      }

      emit(HybridMatchLoaded(
        lawyers: lawyers, 
        firms: firms,
        mixedRendering: event.mixedRendering,
      ));
    } catch (e) {
      emit(HybridMatchError(message: 'Erro ao aplicar filtros: ${e.toString()}'));
    }
  }
} 