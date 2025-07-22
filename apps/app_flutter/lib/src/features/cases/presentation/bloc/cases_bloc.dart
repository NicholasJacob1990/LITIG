import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_my_cases_usecase.dart';
import 'package:meu_app/src/core/utils/logger.dart';

part 'cases_event.dart';
part 'cases_state.dart';

class CasesBloc extends Bloc<CasesEvent, CasesState> {
  final GetMyCasesUseCase getMyCasesUseCase;

  CasesBloc({required this.getMyCasesUseCase}) : super(CasesInitial()) {
    on<FetchCases>(_onFetchCases);
    on<FilterCases>(_onFilterCases);
  }

  Future<void> _onFetchCases(FetchCases event, Emitter<CasesState> emit) async {
    AppLogger.info('CasesBloc: Iniciando busca de casos');
    emit(CasesLoading());
    try {
      final cases = await getMyCasesUseCase();
      AppLogger.info('CasesBloc: ${cases.length} casos carregados');
      emit(CasesLoaded(
        allCases: cases,
        filteredCases: cases,
        activeFilter: 'Todos',
      ));
    } catch (e) {
      AppLogger.error('CasesBloc: Erro ao carregar casos', error: e);
      emit(CasesError(e.toString()));
    }
  }

  void _onFilterCases(FilterCases event, Emitter<CasesState> emit) {
    if (state is CasesLoaded) {
      final currentState = state as CasesLoaded;
      final filteredList = event.filter == 'Todos'
          ? currentState.allCases
          : currentState.allCases.where((c) => c.status == event.filter).toList();
      
      emit(CasesLoaded(
        allCases: currentState.allCases,
        filteredCases: filteredList,
        activeFilter: event.filter,
      ));
    }
  }
} 