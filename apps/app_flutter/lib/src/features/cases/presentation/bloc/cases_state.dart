part of 'cases_bloc.dart';

abstract class CasesState {
  const CasesState();
}

class CasesInitial extends CasesState {}

class CasesLoading extends CasesState {}

class CasesLoaded extends CasesState {
  final List<Case> allCases;
  final List<Case> filteredCases;
  final String activeFilter;
  final CaseSearchFilters? searchFilters;
  final bool isSearchMode;

  const CasesLoaded({
    required this.allCases,
    required this.filteredCases,
    required this.activeFilter,
    this.searchFilters,
    this.isSearchMode = false,
  });

  CasesLoaded copyWith({
    List<Case>? allCases,
    List<Case>? filteredCases,
    String? activeFilter,
    CaseSearchFilters? searchFilters,
    bool? isSearchMode,
  }) {
    return CasesLoaded(
      allCases: allCases ?? this.allCases,
      filteredCases: filteredCases ?? this.filteredCases,
      activeFilter: activeFilter ?? this.activeFilter,
      searchFilters: searchFilters ?? this.searchFilters,
      isSearchMode: isSearchMode ?? this.isSearchMode,
    );
  }
}

class CasesError extends CasesState {
  final String message;
  const CasesError(this.message);
} 