import 'package:bloc/bloc.dart';
import 'package:meu_app/src/features/search/domain/usecases/perform_search.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_event.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final PerformSearch performSearch;

  SearchBloc({required this.performSearch}) : super(const SearchInitial()) {
    on<SearchRequested>(_onSearchRequested);
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

  void _onSearchCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) {
    emit(const SearchInitial());
  }
} 
 