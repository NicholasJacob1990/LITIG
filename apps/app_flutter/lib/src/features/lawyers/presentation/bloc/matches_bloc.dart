import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/domain/usecases/find_matches_usecase.dart';
import 'package:meu_app/src/core/enums/legal_areas.dart';

part 'matches_event.dart';
part 'matches_state.dart';

class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  final FindMatchesUseCase findMatchesUseCase;

  MatchesBloc({required this.findMatchesUseCase}) : super(MatchesInitial()) {
    on<FetchMatches>(_onFetchMatches);
    on<SearchLawyers>(_onSearchLawyers);
  }

  Future<void> _onFetchMatches(
    FetchMatches event,
    Emitter<MatchesState> emit,
  ) async {
    emit(MatchesLoading());
    try {
      final lawyers = await findMatchesUseCase(caseId: event.caseId);
      emit(MatchesLoaded(lawyers));
    } catch (e) {
      emit(MatchesError(e.toString()));
    }
  }

  Future<void> _onSearchLawyers(
    SearchLawyers event,
    Emitter<MatchesState> emit,
  ) async {
    emit(MatchesLoading());
    try {
      // Por enquanto, simula uma busca básica
      // TODO: Implementar busca completa com os parâmetros
      final lawyers = await findMatchesUseCase(caseId: null);
      emit(MatchesLoaded(lawyers));
    } catch (e) {
      emit(MatchesError(e.toString()));
    }
  }
}