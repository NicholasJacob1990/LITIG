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

  const CasesLoaded({
    required this.allCases,
    required this.filteredCases,
    required this.activeFilter,
  });
}

class CasesError extends CasesState {
  final String message;
  const CasesError(this.message);
} 