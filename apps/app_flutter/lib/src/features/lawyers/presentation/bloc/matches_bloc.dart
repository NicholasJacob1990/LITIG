import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/domain/usecases/find_matches_usecase.dart';

part 'matches_event.dart';
part 'matches_state.dart';

class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  final FindMatchesUseCase findMatchesUseCase;

  MatchesBloc({required this.findMatchesUseCase}) : super(MatchesInitial()) {
    on<FetchMatches>(_onFetchMatches);
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
}