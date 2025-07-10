part of 'cases_bloc.dart';

abstract class CasesEvent {
  const CasesEvent();
}

class FetchCases extends CasesEvent {}

class FilterCases extends CasesEvent {
  final String filter;
  const FilterCases(this.filter);
} 