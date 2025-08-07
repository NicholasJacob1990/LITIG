part of 'cases_bloc.dart';

abstract class CasesEvent {
  const CasesEvent();
}

class FetchCases extends CasesEvent {}

class FilterCases extends CasesEvent {
  final String filter;
  const FilterCases(this.filter);
}

class SearchCases extends CasesEvent {
  final CaseSearchFilters filters;
  const SearchCases(this.filters);
}

class ClearCaseSearch extends CasesEvent {}

class CaseSearchFilters {
  final String? searchQuery;
  final String? clientName;
  final String? lawyerName;
  final String? status;
  final String? category;
  final String? priority;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? minValue;
  final double? maxValue;

  const CaseSearchFilters({
    this.searchQuery,
    this.clientName,
    this.lawyerName,
    this.status,
    this.category,
    this.priority,
    this.dateFrom,
    this.dateTo,
    this.minValue,
    this.maxValue,
  });

  bool get hasActiveFilters {
    return searchQuery != null ||
           clientName != null ||
           lawyerName != null ||
           status != null ||
           category != null ||
           priority != null ||
           dateFrom != null ||
           dateTo != null ||
           minValue != null ||
           maxValue != null;
  }

  Map<String, dynamic> toJson() {
    return {
      'searchQuery': searchQuery,
      'clientName': clientName,
      'lawyerName': lawyerName,
      'status': status,
      'category': category,
      'priority': priority,
      'dateFrom': dateFrom?.toIso8601String(),
      'dateTo': dateTo?.toIso8601String(),
      'minValue': minValue,
      'maxValue': maxValue,
    };
  }
} 