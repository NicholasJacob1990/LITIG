import 'package:bloc/bloc.dart';
import 'package:meu_app/src/features/search/domain/usecases/perform_search.dart';
import 'package:meu_app/src/features/search/domain/usecases/perform_semantic_firm_search.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_event.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final PerformSearch performSearch;
  final PerformSemanticFirmSearch performSemanticFirmSearch;

  SearchBloc({
    required this.performSearch,
    required this.performSemanticFirmSearch,
  }) : super(const SearchInitial()) {
    on<SearchRequested>(_onSearchRequested);
    on<SemanticFirmSearchRequested>(_onSemanticFirmSearchRequested); // NOVO
    on<SearchCleared>(_onSearchCleared);
  }

  Future<void> _onSearchRequested(
    SearchRequested event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchLoading());

    final result = await performSearch(event.params);

    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (results) => emit(SearchLoaded(
        results: results,
        appliedPreset: event.params.preset,
      )),
    );
  }

  Future<void> _onSemanticFirmSearchRequested(
    SemanticFirmSearchRequested event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchLoading());

    final result = await performSemanticFirmSearch(event.params);

    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (results) => emit(SearchLoaded(
        results: results,
        appliedPreset: event.params.preset,
      )),
    );
  }

  void _onSearchCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) {
    emit(const SearchInitial());
  }
} 
 