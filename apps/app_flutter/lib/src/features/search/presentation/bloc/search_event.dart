import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/search/domain/entities/search_params.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchRequested extends SearchEvent {
  final SearchParams params;

  const SearchRequested(this.params);

  @override
  List<Object?> get props => [params];
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
} 
 