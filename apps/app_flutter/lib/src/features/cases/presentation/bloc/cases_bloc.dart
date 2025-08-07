import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_my_cases_usecase.dart';
import 'package:meu_app/src/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:meu_app/src/core/utils/logger.dart';

part 'cases_event.dart';
part 'cases_state.dart';

class CasesBloc extends Bloc<CasesEvent, CasesState> {
  final GetMyCasesUseCase getMyCasesUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  CasesBloc({
    required this.getMyCasesUseCase,
    required this.getCurrentUserUseCase,
  }) : super(CasesInitial()) {
    on<FetchCases>(_onFetchCases);
    on<FilterCases>(_onFilterCases);
    on<SearchCases>(_onSearchCases);
    on<ClearCaseSearch>(_onClearCaseSearch);
  }

  Future<void> _onFetchCases(FetchCases event, Emitter<CasesState> emit) async {
    AppLogger.info('CasesBloc: Iniciando busca de casos');
    emit(CasesLoading());
    try {
      // Obter informações do usuário atual para filtragem
      final currentUser = await getCurrentUserUseCase();
      final userId = currentUser?.id;
      final userRole = currentUser?.effectiveUserRole;
      
      AppLogger.info('CasesBloc: Buscando casos para usuário $userId com role $userRole');
      
      final cases = await getMyCasesUseCase(userId: userId, userRole: userRole);
      AppLogger.info('CasesBloc: ${cases.length} casos carregados para $userRole');
      
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

  void _onSearchCases(SearchCases event, Emitter<CasesState> emit) {
    if (state is CasesLoaded) {
      final currentState = state as CasesLoaded;
      final searchResults = _performCaseSearch(currentState.allCases, event.filters);
      
      AppLogger.info('CasesBloc: Busca aplicada. ${searchResults.length} casos encontrados');
      
      emit(currentState.copyWith(
        filteredCases: searchResults,
        searchFilters: event.filters,
        isSearchMode: true,
        activeFilter: 'Busca',
      ));
    }
  }

  void _onClearCaseSearch(ClearCaseSearch event, Emitter<CasesState> emit) {
    if (state is CasesLoaded) {
      final currentState = state as CasesLoaded;
      
      AppLogger.info('CasesBloc: Limpando busca');
      
      emit(currentState.copyWith(
        filteredCases: currentState.allCases,
        searchFilters: null,
        isSearchMode: false,
        activeFilter: 'Todos',
      ));
    }
  }

  List<Case> _performCaseSearch(List<Case> cases, CaseSearchFilters filters) {
    var results = cases.toList();

    // Filtro por texto geral
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final query = filters.searchQuery!.toLowerCase();
      results = results.where((caseItem) {
        return caseItem.title.toLowerCase().contains(query) ||
               caseItem.id.toLowerCase().contains(query);
      }).toList();
    }

    // Filtro por status
    if (filters.status != null && filters.status != 'Todos') {
      results = results.where((caseItem) => caseItem.status == filters.status).toList();
    }

    // Filtro por data
    if (filters.dateFrom != null) {
      results = results.where((caseItem) {
        return caseItem.createdAt.isAfter(filters.dateFrom!) || 
               caseItem.createdAt.isAtSameMomentAs(filters.dateFrom!);
      }).toList();
    }

    if (filters.dateTo != null) {
      final endOfDay = DateTime(filters.dateTo!.year, filters.dateTo!.month, filters.dateTo!.day + 1);
      results = results.where((caseItem) {
        return caseItem.createdAt.isBefore(endOfDay);
      }).toList();
    }

    return results;
  }
} 